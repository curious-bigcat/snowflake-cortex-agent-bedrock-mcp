"""
Test MCP Server - Verify the Lambda MCP endpoint works
=======================================================
Tests the deployed Lambda MCP server via API Gateway.

Usage:
  export API_GATEWAY_URL="https://718ip72cs0.execute-api.us-east-1.amazonaws.com/prod/mcp"
  python test_gateway.py

  Or test with auth:
  python test_gateway.py --with-auth
"""

import json
import os
import argparse
import requests

API_URL = os.environ.get("API_GATEWAY_URL", "https://718ip72cs0.execute-api.us-east-1.amazonaws.com/prod/mcp")


def test_tools_list_no_auth():
    """Test tools/list without auth (GET endpoint)."""
    print("Testing tools/list (GET, no auth)...")
    try:
        resp = requests.get(API_URL, timeout=15)
        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            print(f"  Response: {json.dumps(resp.json(), indent=2)[:500]}")
            return True
        else:
            print(f"  Body: {resp.text[:300]}")
            return False
    except Exception as e:
        print(f"  Error: {e}")
        return False


def test_tools_list_with_auth():
    """Test tools/list with Cognito JWT auth."""
    print("\nTesting tools/list (POST, with auth)...")
    try:
        import boto3
        import hmac
        import hashlib
        import base64

        # Get token from Cognito
        cognito = boto3.client("cognito-idp", region_name="us-east-1")
        
        # These values come from deploy_oauth_proxy.py output
        pool_id = os.environ.get("COGNITO_POOL_ID", "us-east-1_DGWsRxtII")
        client_id = os.environ.get("COGNITO_CLIENT_ID", "3rmrphe2g9n209m613p6qo9uu0")
        client_secret = os.environ.get("COGNITO_CLIENT_SECRET", "1mbbktv2v392j9ldhaolm4oqndr36ebq5343h4mvv12spdgi5b0")
        username = "snowflake-mcp-user"
        password = "SnowflakeMCP2025!"

        secret_hash = base64.b64encode(
            hmac.new(client_secret.encode(), (username + client_id).encode(), hashlib.sha256).digest()
        ).decode()

        response = cognito.admin_initiate_auth(
            UserPoolId=pool_id,
            ClientId=client_id,
            AuthFlow="ADMIN_USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": username,
                "PASSWORD": password,
                "SECRET_HASH": secret_hash,
            },
        )
        id_token = response["AuthenticationResult"]["IdToken"]
        print(f"  Got Cognito token")

        # Call API with token
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {id_token}",
        }
        payload = {"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}

        resp = requests.post(API_URL, json=payload, headers=headers, timeout=15)
        print(f"  Status: {resp.status_code}")
        print(f"  Response: {json.dumps(resp.json(), indent=2)[:500]}")
        return resp.status_code == 200

    except Exception as e:
        print(f"  Error: {e}")
        return False


def test_tools_call_with_auth(query="ocean freight rates Shanghai to Los Angeles"):
    """Test tools/call - actually query the KB."""
    print(f"\nTesting tools/call: '{query}'")
    try:
        import boto3
        import hmac
        import hashlib
        import base64

        cognito = boto3.client("cognito-idp", region_name="us-east-1")
        pool_id = os.environ.get("COGNITO_POOL_ID", "us-east-1_DGWsRxtII")
        client_id = os.environ.get("COGNITO_CLIENT_ID", "3rmrphe2g9n209m613p6qo9uu0")
        client_secret = os.environ.get("COGNITO_CLIENT_SECRET", "1mbbktv2v392j9ldhaolm4oqndr36ebq5343h4mvv12spdgi5b0")
        username = "snowflake-mcp-user"

        secret_hash = base64.b64encode(
            hmac.new(client_secret.encode(), (username + client_id).encode(), hashlib.sha256).digest()
        ).decode()

        response = cognito.admin_initiate_auth(
            UserPoolId=pool_id, ClientId=client_id,
            AuthFlow="ADMIN_USER_PASSWORD_AUTH",
            AuthParameters={"USERNAME": username, "PASSWORD": "SnowflakeMCP2025!", "SECRET_HASH": secret_hash},
        )
        id_token = response["AuthenticationResult"]["IdToken"]

        headers = {"Content-Type": "application/json", "Authorization": f"Bearer {id_token}"}
        payload = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "retrieve_logistics_docs",
                "arguments": {"query": query, "numberOfResults": 3},
            },
        }

        resp = requests.post(API_URL, json=payload, headers=headers, timeout=30)
        print(f"  Status: {resp.status_code}")
        result = resp.json()
        if "error" in result:
            print(f"  Error: {result['error']['message']}")
            return False
        else:
            text = result.get("result", {}).get("content", [{}])[0].get("text", "")
            print(f"  SUCCESS ({len(text)} chars)")
            print(f"  Preview: {text[:400]}")
            return True

    except Exception as e:
        print(f"  Error: {e}")
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test the deployed MCP server")
    parser.add_argument("--with-auth", action="store_true", help="Test with Cognito auth (requires boto3)")
    parser.add_argument("--query", default="ocean freight rates Shanghai to Los Angeles", help="Query to test")
    args = parser.parse_args()

    print("=" * 60)
    print("MCP SERVER TEST")
    print("=" * 60)
    print(f"Endpoint: {API_URL}")
    print()

    test_tools_list_no_auth()

    if args.with_auth:
        test_tools_list_with_auth()
        test_tools_call_with_auth(args.query)

    print("\n" + "=" * 60)
    print("TEST COMPLETE")
    print("=" * 60)
