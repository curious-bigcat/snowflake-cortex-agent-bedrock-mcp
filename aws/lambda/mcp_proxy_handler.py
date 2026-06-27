"""
MCP Proxy Lambda Handler
==========================
Exposes a Bedrock Knowledge Base as MCP tools (tools/list + tools/call).
Receives OAuth-authenticated requests from Snowflake via API Gateway,
then calls bedrock-agent-runtime Retrieve API directly.

Environment Variables:
  KNOWLEDGE_BASE_ID: The Bedrock Knowledge Base ID
  AWS_REGION_NAME: AWS region (us-east-1)
"""

import json
import os
import boto3

KB_ID = os.environ.get("KNOWLEDGE_BASE_ID", "")
REGION = os.environ.get("AWS_REGION_NAME", "us-east-1")

bedrock_runtime = boto3.client("bedrock-agent-runtime", region_name=REGION)


# MCP Tool definitions exposed to Snowflake
TOOLS = [
    {
        "name": "retrieve_logistics_docs",
        "description": "Search the supply chain logistics knowledge base for information about freight costs, shipping rates, customer returns, warranty claims, compliance documents, ISO certifications, customs duties, and material safety data. Use this tool when asked about logistics costs, shipping, returns, or regulatory compliance.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Natural language query to search the logistics knowledge base"
                },
                "numberOfResults": {
                    "type": "integer",
                    "description": "Number of results to return (1-10, default 5)"
                }
            },
            "required": ["query"]
        }
    }
]


def handle_tools_list():
    """Handle MCP tools/list request."""
    return {
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "tools": TOOLS
        }
    }


def handle_tools_call(params):
    """Handle MCP tools/call request by calling Bedrock KB Retrieve."""
    tool_name = params.get("name", "")
    arguments = params.get("arguments", {})

    if tool_name != "retrieve_logistics_docs":
        return {
            "jsonrpc": "2.0",
            "id": 2,
            "error": {
                "code": -32602,
                "message": f"Unknown tool: {tool_name}"
            }
        }

    query = arguments.get("query", "")
    num_results = min(arguments.get("numberOfResults", 5), 10)

    if not query:
        return {
            "jsonrpc": "2.0",
            "id": 2,
            "error": {
                "code": -32602,
                "message": "Missing required parameter: query"
            }
        }

    try:
        # Call Bedrock KB Retrieve API (Managed KB uses managedSearchConfiguration)
        try:
            response = bedrock_runtime.retrieve(
                knowledgeBaseId=KB_ID,
                retrievalQuery={"text": query},
                retrievalConfiguration={
                    "managedSearchConfiguration": {
                        "numberOfResults": num_results
                    }
                }
            )
        except bedrock_runtime.exceptions.ValidationException:
            # Fallback to vector search for customer-managed KBs
            response = bedrock_runtime.retrieve(
                knowledgeBaseId=KB_ID,
                retrievalQuery={"text": query},
                retrievalConfiguration={
                    "vectorSearchConfiguration": {
                        "numberOfResults": num_results
                    }
                }
            )

        # Format results as MCP tool response
        results = []
        for i, result in enumerate(response.get("retrievalResults", [])):
            content = result.get("content", {}).get("text", "")
            source = result.get("location", {}).get("s3Location", {}).get("uri", "unknown")
            score = result.get("score", 0)
            results.append(f"[Result {i+1}] (score: {score:.3f}, source: {source})\n{content}")

        response_text = "\n\n---\n\n".join(results) if results else "No relevant documents found."

        return {
            "jsonrpc": "2.0",
            "id": 2,
            "result": {
                "content": [
                    {
                        "type": "text",
                        "text": response_text
                    }
                ]
            }
        }

    except Exception as e:
        return {
            "jsonrpc": "2.0",
            "id": 2,
            "error": {
                "code": -32000,
                "message": f"Knowledge base query failed: {str(e)}"
            }
        }


def handle_initialize():
    """Handle MCP initialize request."""
    return {
        "jsonrpc": "2.0",
        "id": 0,
        "result": {
            "protocolVersion": "2024-11-05",
            "serverInfo": {
                "name": "aws-logistics-kb",
                "version": "1.0.0"
            },
            "capabilities": {
                "tools": {"listChanged": False}
            }
        }
    }


def lambda_handler(event, context):
    """Lambda handler - MCP JSON-RPC server backed by Bedrock KB."""
    try:
        # Extract body
        body = event.get("body", "")
        if event.get("isBase64Encoded"):
            import base64
            body = base64.b64decode(body).decode("utf-8")

        # Handle GET requests (health check / discovery)
        http_method = event.get("requestContext", {}).get("http", {}).get("method", "POST")
        if http_method == "GET" or not body:
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(handle_initialize()),
            }

        # Parse JSON-RPC request
        request = json.loads(body)
        method = request.get("method", "")
        params = request.get("params", {})
        request_id = request.get("id", 1)

        # Route to handler
        if method == "initialize":
            result = handle_initialize()
        elif method == "tools/list":
            result = handle_tools_list()
        elif method == "tools/call":
            result = handle_tools_call(params)
        elif method == "notifications/initialized":
            # Client notification, acknowledge
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": "",
            }
        else:
            result = {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {
                    "code": -32601,
                    "message": f"Method not found: {method}"
                }
            }

        # Set correct id from request
        if "id" in request:
            result["id"] = request["id"]

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps(result),
        }

    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32603, "message": f"Internal error: {str(e)}"}
            }),
        }
