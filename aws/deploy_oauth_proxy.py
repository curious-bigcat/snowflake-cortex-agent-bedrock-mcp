"""
MCP Server Deployment - Lambda + API Gateway + Cognito
=======================================================
Deploys a Lambda-based MCP server that exposes a Bedrock Knowledge Base
as an MCP tool. Snowflake Cortex Agent connects to this via External MCP Server.

Flow: Snowflake → OAuth2 (Cognito) → API Gateway → Lambda → Bedrock KB Retrieve API

Prerequisites:
- AWS CLI configured
- boto3 installed
- Knowledge Base ID from setup_knowledge_base.py

Usage:
  python deploy_oauth_proxy.py --kb-id Q4NYYBGB2C
"""

import boto3
import json
import time
import zipfile
import io
import argparse
import os

AWS_REGION = "us-east-1"
STACK_PREFIX = "scm-mcp-proxy"

# Clients
iam = boto3.client("iam", region_name=AWS_REGION)
lambda_client = boto3.client("lambda", region_name=AWS_REGION)
apigw = boto3.client("apigatewayv2", region_name=AWS_REGION)
cognito = boto3.client("cognito-idp", region_name=AWS_REGION)


def create_cognito_user_pool():
    """Create Cognito User Pool for OAuth authentication."""
    pool_name = f"{STACK_PREFIX}-user-pool"
    print(f"\n[1/5] Creating Cognito User Pool: {pool_name}")

    response = cognito.create_user_pool(
        PoolName=pool_name,
        AutoVerifiedAttributes=["email"],
        Schema=[
            {"Name": "email", "Required": True, "Mutable": True},
        ],
    )
    pool_id = response["UserPool"]["Id"]
    print(f"  ✓ User Pool ID: {pool_id}")

    # Create domain for OAuth endpoints
    domain_prefix = f"{STACK_PREFIX}-{pool_id.split('_')[1][:8].lower()}"
    try:
        cognito.create_user_pool_domain(Domain=domain_prefix, UserPoolId=pool_id)
        print(f"  ✓ Domain: https://{domain_prefix}.auth.{AWS_REGION}.amazoncognito.com")
    except Exception as e:
        print(f"  ! Domain: {e}")

    # Create resource server (scope)
    try:
        cognito.create_resource_server(
            UserPoolId=pool_id,
            Identifier="mcp-proxy",
            Name="MCP Proxy",
            Scopes=[{"ScopeName": "invoke", "ScopeDescription": "Invoke MCP tools"}],
        )
    except Exception:
        pass

    # Create app client
    client_response = cognito.create_user_pool_client(
        UserPoolId=pool_id,
        ClientName=f"{STACK_PREFIX}-client",
        GenerateSecret=True,
        ExplicitAuthFlows=["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"],
        AllowedOAuthFlows=["code", "implicit"],
        AllowedOAuthScopes=["openid", "mcp-proxy/invoke"],
        AllowedOAuthFlowsUserPoolClient=True,
        CallbackURLs=["https://identity.snowflake.com/oauth2/callback"],
        SupportedIdentityProviders=["COGNITO"],
    )
    client_id = client_response["UserPoolClient"]["ClientId"]
    client_secret = client_response["UserPoolClient"]["ClientSecret"]

    print(f"  ✓ Client ID: {client_id}")
    print(f"  ✓ Client Secret: {client_secret[:8]}...")

    # Create a test user
    try:
        cognito.admin_create_user(
            UserPoolId=pool_id,
            Username="snowflake-mcp-user",
            UserAttributes=[{"Name": "email", "Value": "mcp-proxy@example.com"}],
            TemporaryPassword="TempPass123!",
            MessageAction="SUPPRESS",
        )
        cognito.admin_set_user_password(
            UserPoolId=pool_id,
            Username="snowflake-mcp-user",
            Password="SnowflakeMCP2025!",
            Permanent=True,
        )
        print("  ✓ Test user created: snowflake-mcp-user")
    except Exception:
        pass

    return {
        "pool_id": pool_id,
        "domain": f"https://{domain_prefix}.auth.{AWS_REGION}.amazoncognito.com",
        "client_id": client_id,
        "client_secret": client_secret,
    }


def create_lambda_role():
    """Create IAM role for the proxy Lambda."""
    role_name = f"{STACK_PREFIX}-lambda-role"
    print(f"\n[2/5] Creating Lambda IAM role: {role_name}")

    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": "lambda.amazonaws.com"},
                "Action": "sts:AssumeRole",
            }
        ],
    }

    try:
        response = iam.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description="Lambda role for MCP server backed by Bedrock KB",
        )
        role_arn = response["Role"]["Arn"]
    except iam.exceptions.EntityAlreadyExistsException:
        role_arn = iam.get_role(RoleName=role_name)["Role"]["Arn"]

    # Attach policies
    policies = {
        "LambdaBasic": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                    ],
                    "Resource": "arn:aws:logs:*:*:*",
                }
            ],
        },
        "BedrockAccess": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "bedrock:Retrieve",
                        "bedrock:RetrieveAndGenerate",
                    ],
                    "Resource": "*",
                }
            ],
        },
    }

    for name, doc in policies.items():
        iam.put_role_policy(
            RoleName=role_name, PolicyName=name, PolicyDocument=json.dumps(doc)
        )

    print(f"  ✓ Role ARN: {role_arn}")
    time.sleep(10)
    return role_arn


def create_lambda_function(role_arn, kb_id):
    """Create and deploy the MCP proxy Lambda."""
    function_name = f"{STACK_PREFIX}-handler"
    print(f"\n[3/5] Creating Lambda function: {function_name}")

    # Read the Lambda handler source
    handler_path = os.path.join(os.path.dirname(__file__), "lambda", "mcp_proxy_handler.py")
    with open(handler_path, "r") as f:
        handler_code = f.read()

    # Create deployment package
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("mcp_proxy_handler.py", handler_code)
    zip_buffer.seek(0)

    try:
        response = lambda_client.create_function(
            FunctionName=function_name,
            Runtime="python3.12",
            Role=role_arn,
            Handler="mcp_proxy_handler.lambda_handler",
            Code={"ZipFile": zip_buffer.read()},
            Description="MCP server backed by Bedrock KB for Snowflake Cortex Agent",
            Timeout=60,
            MemorySize=256,
            Environment={
                "Variables": {
                    "KNOWLEDGE_BASE_ID": kb_id,
                    "AWS_REGION_NAME": AWS_REGION,
                }
            },
        )
        function_arn = response["FunctionArn"]
        print(f"  ✓ Lambda ARN: {function_arn}")
    except lambda_client.exceptions.ResourceConflictException:
        # Update existing function - wait for any in-progress updates first
        print(f"  Function exists, updating...")
        
        # Wait for function to be ready
        import time as _time
        for _ in range(12):
            try:
                status = lambda_client.get_function(FunctionName=function_name)
                state = status["Configuration"].get("LastUpdateStatus", "Successful")
                if state == "Successful":
                    break
            except Exception:
                pass
            _time.sleep(5)
        
        # Update config
        lambda_client.update_function_configuration(
            FunctionName=function_name,
            Environment={
                "Variables": {
                    "KNOWLEDGE_BASE_ID": kb_id,
                    "AWS_REGION_NAME": AWS_REGION,
                }
            },
        )
        
        # Wait for config update to finish
        _time.sleep(10)
        
        # Update code
        zip_buffer.seek(0)
        lambda_client.update_function_code(
            FunctionName=function_name, ZipFile=zip_buffer.read()
        )
        response = lambda_client.get_function(FunctionName=function_name)
        function_arn = response["Configuration"]["FunctionArn"]
        print(f"  ✓ Lambda updated: {function_arn}")

    return function_arn


def create_api_gateway(lambda_arn, cognito_config):
    """Create HTTP API Gateway with Cognito authorizer."""
    api_name = f"{STACK_PREFIX}-api"
    print(f"\n[4/5] Creating API Gateway: {api_name}")

    # Create HTTP API
    api_response = apigw.create_api(
        Name=api_name,
        ProtocolType="HTTP",
        Description="MCP server for Snowflake Cortex Agent (Bedrock KB backend)",
        CorsConfiguration={
            "AllowOrigins": ["*"],
            "AllowMethods": ["POST", "GET", "OPTIONS"],
            "AllowHeaders": ["*"],
        },
    )
    api_id = api_response["ApiId"]

    # Create Cognito authorizer
    authorizer_response = apigw.create_authorizer(
        ApiId=api_id,
        AuthorizerType="JWT",
        IdentitySource=["$request.header.Authorization"],
        Name="cognito-auth",
        JwtConfiguration={
            "Audience": [cognito_config["client_id"]],
            "Issuer": f"https://cognito-idp.{AWS_REGION}.amazonaws.com/{cognito_config['pool_id']}",
        },
    )
    authorizer_id = authorizer_response["AuthorizerId"]

    # Create Lambda integration
    account_id = boto3.client("sts").get_caller_identity()["Account"]
    integration_response = apigw.create_integration(
        ApiId=api_id,
        IntegrationType="AWS_PROXY",
        IntegrationUri=lambda_arn,
        PayloadFormatVersion="2.0",
    )
    integration_id = integration_response["IntegrationId"]

    # Create route: POST /prod/mcp
    apigw.create_route(
        ApiId=api_id,
        RouteKey="POST /prod/mcp",
        Target=f"integrations/{integration_id}",
        AuthorizationType="JWT",
        AuthorizerId=authorizer_id,
    )

    # Also create without auth for tools/list discovery
    apigw.create_route(
        ApiId=api_id,
        RouteKey="GET /prod/mcp",
        Target=f"integrations/{integration_id}",
    )

    # Create stage
    apigw.create_stage(ApiId=api_id, StageName="prod", AutoDeploy=True)

    # Grant API GW permission to invoke Lambda
    lambda_client.add_permission(
        FunctionName=lambda_arn.split(":")[-1],
        StatementId=f"apigw-invoke-{api_id}",
        Action="lambda:InvokeFunction",
        Principal="apigateway.amazonaws.com",
        SourceArn=f"arn:aws:execute-api:{AWS_REGION}:{account_id}:{api_id}/*/*",
    )

    api_url = f"https://{api_id}.execute-api.{AWS_REGION}.amazonaws.com"
    print(f"  ✓ API Gateway URL: {api_url}")
    print(f"  ✓ MCP Endpoint: {api_url}/prod/mcp")
    return api_url


def print_snowflake_config(api_url, cognito_config):
    """Print the Snowflake SQL configuration."""
    print(f"\n{'='*60}")
    print("SNOWFLAKE CONFIGURATION")
    print(f"{'='*60}")
    print(f"""
Replace placeholders in snowflake/05_mcp_connection.sql with:

  API_ALLOWED_PREFIXES = ('{api_url}')
  OAUTH_CLIENT_ID = '{cognito_config["client_id"]}'
  OAUTH_CLIENT_SECRET = '{cognito_config["client_secret"]}'
  OAUTH_TOKEN_ENDPOINT = '{cognito_config["domain"]}/oauth2/token'
  OAUTH_AUTHORIZATION_ENDPOINT = '{cognito_config["domain"]}/oauth2/authorize'
  
  External MCP Server URL = '{api_url}/prod/mcp'
""")


def main():
    parser = argparse.ArgumentParser(description="Deploy MCP server (Lambda + API GW + Cognito) for Bedrock KB")
    parser.add_argument("--kb-id", required=True, help="Bedrock Knowledge Base ID (e.g., Q4NYYBGB2C)")
    args = parser.parse_args()

    print("=" * 60)
    print("MCP SERVER DEPLOYMENT (Lambda + API Gateway + Cognito)")
    print("=" * 60)
    print(f"Knowledge Base ID: {args.kb_id}")

    # Step 1: Cognito
    cognito_config = create_cognito_user_pool()

    # Step 2: Lambda Role
    role_arn = create_lambda_role()

    # Step 3: Lambda
    lambda_arn = create_lambda_function(role_arn, args.kb_id)

    # Step 4: API Gateway
    api_url = create_api_gateway(lambda_arn, cognito_config)

    # Step 5: Print config
    print_snowflake_config(api_url, cognito_config)

    print(f"\n{'='*60}")
    print("DEPLOYMENT COMPLETE")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
