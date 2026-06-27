"""
Demo Script - Cross-Platform Agent Orchestration
=================================================
Calls the Cortex Agent REST API with curated questions demonstrating:
  A) Snowflake-only queries (Analyst + Search tools)
  B) AWS-only queries (MCP tool to Bedrock KB)
  C) Cross-platform orchestration (Snowflake + AWS)

Prerequisites:
- Snowflake PAT token or OAuth token
- Agent created (snowflake/04_cortex_agent.sql)
- (Optional) MCP connection configured (snowflake/05_mcp_connection.sql)

Usage:
  export SNOWFLAKE_ACCOUNT_URL="https://SFSEAPAC-BSURESH.snowflakecomputing.com"
  export SNOWFLAKE_PAT="<your-pat-token>"
  python run_demo.py
"""

import os
import json
import requests
from typing import Generator

# Configuration
ACCOUNT_URL = os.environ.get("SNOWFLAKE_ACCOUNT_URL", "https://SFSEAPAC-BSURESH.snowflakecomputing.com")
PAT_TOKEN = os.environ.get("SNOWFLAKE_PAT", "")
DATABASE = "SUPPLY_CHAIN_MFG_DEMO"
SCHEMA = "PUBLIC"
AGENT_NAME = "MFG_OPERATIONS_AGENT"

AGENT_RUN_URL = f"{ACCOUNT_URL}/api/v2/databases/{DATABASE}/schemas/{SCHEMA}/agents/{AGENT_NAME}:run"


# === SAMPLE QUESTIONS ===

QUESTIONS = {
    # Category A: Snowflake-Only Queries
    "A1": {
        "category": "Snowflake Only - Analyst + Search",
        "question": "Which suppliers have quality ratings below 3.5 and what communications have they sent about delays or quality issues?",
        "expected_tools": ["MfgAnalyst", "SupplierCommsSearch"],
    },
    "A2": {
        "category": "Snowflake Only - Analyst + Search",
        "question": "Show me production orders with yield below 94% and any related quality audit findings from those plants.",
        "expected_tools": ["MfgAnalyst", "QualityReportsSearch"],
    },
    "A3": {
        "category": "Snowflake Only - Analyst",
        "question": "What is the average production yield by plant and which plants have the most defects?",
        "expected_tools": ["MfgAnalyst"],
    },
    "A4": {
        "category": "Snowflake Only - Search",
        "question": "Find any supplier communications about force majeure events or production disruptions.",
        "expected_tools": ["SupplierCommsSearch"],
    },
    "A5": {
        "category": "Snowflake Only - Search",
        "question": "What critical quality audit findings are still open and what plants are affected?",
        "expected_tools": ["QualityReportsSearch"],
    },

    # Category B: AWS-Only Queries (via MCP)
    "B1": {
        "category": "AWS Only - MCP (Freight)",
        "question": "What are the current ocean freight rates for shipping containers from Shanghai to Los Angeles?",
        "expected_tools": ["AWSLogisticsKB"],
    },
    "B2": {
        "category": "AWS Only - MCP (Returns)",
        "question": "Show me customer return complaints related to electronics and weld quality failures.",
        "expected_tools": ["AWSLogisticsKB"],
    },
    "B3": {
        "category": "AWS Only - MCP (Compliance)",
        "question": "What ISO certifications do our manufacturing plants hold and which ones are under enhanced surveillance?",
        "expected_tools": ["AWSLogisticsKB"],
    },

    # Category C: Cross-Platform Orchestration
    "C1": {
        "category": "Cross-Platform - Analyst + MCP",
        "question": "For suppliers in China with quality ratings below 3.5, what are the freight costs for shipping from Shenzhen to the US, and have there been any customer returns from their products?",
        "expected_tools": ["MfgAnalyst", "AWSLogisticsKB"],
    },
    "C2": {
        "category": "Cross-Platform - All Tools",
        "question": "Our Detroit Fabrication Center had weld quality issues. Show me: 1) the production orders affected and their defect counts, 2) what the quality audit found, and 3) whether customers have filed return complaints about those products.",
        "expected_tools": ["MfgAnalyst", "QualityReportsSearch", "AWSLogisticsKB"],
    },
}


def call_agent(question: str, thread_id: str = None) -> dict:
    """Call the Cortex Agent REST API."""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": f"Bearer {PAT_TOKEN}",
    }

    payload = {
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": question}],
            }
        ],
    }

    if thread_id:
        payload["thread_id"] = thread_id

    response = requests.post(AGENT_RUN_URL, headers=headers, json=payload, stream=True)

    if response.status_code != 200:
        return {"error": f"HTTP {response.status_code}: {response.text[:500]}"}

    # Parse streaming response
    full_response = {"tools_used": [], "text": "", "citations": []}
    for line in response.iter_lines():
        if line:
            try:
                event = json.loads(line.decode("utf-8").removeprefix("data: "))
                event_type = event.get("type", "")

                if event_type == "tool_use":
                    full_response["tools_used"].append(event.get("name", ""))
                elif event_type == "text":
                    full_response["text"] += event.get("text", "")
                elif event_type == "citation":
                    full_response["citations"].append(event.get("source", ""))
            except (json.JSONDecodeError, AttributeError):
                continue

    return full_response


def run_demo():
    """Run all demo questions and display results."""
    print("=" * 80)
    print("SUPPLY CHAIN MANUFACTURING - CROSS-PLATFORM AGENT DEMO")
    print("=" * 80)
    print(f"\nAgent: {DATABASE}.{SCHEMA}.{AGENT_NAME}")
    print(f"Account: {ACCOUNT_URL}")
    print()

    if not PAT_TOKEN:
        print("ERROR: Set SNOWFLAKE_PAT environment variable with your PAT token.")
        print("  export SNOWFLAKE_PAT='your-token-here'")
        print("\nTo generate a PAT:")
        print("  Snowsight > User Menu > Preferences > Programmatic Access Tokens > Generate")
        return

    for qid, qdata in QUESTIONS.items():
        print(f"\n{'─' * 80}")
        print(f"[{qid}] Category: {qdata['category']}")
        print(f"    Question: {qdata['question']}")
        print(f"    Expected tools: {qdata['expected_tools']}")
        print(f"{'─' * 80}")

        result = call_agent(qdata["question"])

        if "error" in result:
            print(f"    ERROR: {result['error']}")
        else:
            print(f"    Tools Used: {result['tools_used']}")
            print(f"    Response Preview: {result['text'][:500]}...")
            if result["citations"]:
                print(f"    Citations: {result['citations'][:3]}")

        print()
        input("    Press Enter to continue to next question...")


if __name__ == "__main__":
    run_demo()
