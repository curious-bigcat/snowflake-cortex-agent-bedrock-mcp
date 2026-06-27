# Technical Architecture: Snowflake Cortex Agent + AWS Bedrock KB via MCP

This document details how Snowflake Cortex Agents connect to AWS Bedrock Knowledge Bases using the Model Context Protocol (MCP), bridging OAuth2 (Snowflake) and IAM/SigV4 (AWS) authentication systems through a Lambda-based MCP server.

The supply chain manufacturing scenario is used as example data — the integration pattern is domain-agnostic and can be applied to any Bedrock Knowledge Base.

---

## Integration Pattern Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  SNOWFLAKE                              AWS                                  │
│                                                                              │
│  ┌─────────────┐                        ┌──────────────────────────────┐    │
│  │ Cortex Agent│  ──── MCP/OAuth2 ────> │ API Gateway + Cognito        │    │
│  │ (orchestr.) │                        │        │                     │    │
│  │             │                        │ Lambda (MCP Server)          │    │
│  │ Tools:      │                        │        │                     │    │
│  │ - Analyst   │                        │ Bedrock KB (Retrieve API)    │    │
│  │ - Search x2 │                        │        │                     │    │
│  │ - MCP (ext) │                        │ S3 (documents)               │    │
│  └─────────────┘                        └──────────────────────────────┘    │
│                                                                              │
│  Auth: Snowflake RBAC                   Auth: IAM Role (Lambda)             │
│  Protocol: MCP JSON-RPC                  Protocol: AWS SDK (boto3)           │
│  Identity: OAuth2 Bearer token          Identity: SigV4 (automatic)         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## The Auth Bridge Problem

| Platform | Auth Method | How It Works |
|----------|-------------|-------------|
| Snowflake External MCP | OAuth2 only | User logs in, gets token, attaches `Authorization: Bearer <token>` |
| AWS Bedrock | IAM/SigV4 only | Every request is cryptographically signed with AWS access keys |

These are incompatible. Snowflake cannot hold AWS IAM credentials, and AWS services don't accept OAuth2 tokens.

**Solution:** A Lambda function acts as an identity translator:
- Accepts OAuth2 tokens (validated by API Gateway + Cognito JWT authorizer)
- Calls AWS services using its IAM execution role (boto3 handles SigV4 automatically)
- Implements the MCP protocol so Snowflake sees it as a standard MCP server

---

## Component Architecture

### 1. Snowflake Cortex Agent (Orchestrator)

The agent receives natural language questions and plans which tool(s) to invoke:

```
User Question
    │
    ├─ Orchestrator LLM analyzes intent
    ├─ Selects tool(s): Analyst? Search? MCP? Multiple?
    ├─ Executes tools (parallel where possible)
    ├─ Synthesizes results from all tools
    └─ Returns unified response with source citations
```

**Configuration:**
- Model: `auto` (Snowflake selects best available)
- Budget: 60 seconds / 20,000 tokens
- Tools: 3 native (Analyst, 2x Search) + 1 external (MCP)

### 2. Cortex Analyst Tool (Text-to-SQL)

Converts natural language to SQL using a Semantic View that describes the data schema:

```
Question → Semantic View metadata → SQL generation → Execution → Results
```

The Semantic View defines:
- Logical tables with primary keys and relationships
- Facts (numeric measures)
- Dimensions (categorical attributes)
- Metrics (pre-defined aggregations)
- Verified queries (pre-validated SQL for common questions)

### 3. Cortex Search Tools (RAG)

Retrieves relevant documents using vector similarity search:

```
Question → Embedding → Vector similarity search → Top-K results
```

- Embedding model: snowflake-arctic-embed-m-v1.5
- Supports attribute filtering (category, priority, severity, etc.)
- Auto-refreshes when source data changes (1-hour target lag)

### 4. External MCP Server (AWS Bridge)

```
Snowflake Agent
    │
    │ POST /mcp (MCP JSON-RPC, Bearer token in header)
    ▼
API Gateway (us-east-1)
    │
    │ JWT Authorizer validates Cognito token
    ▼
Lambda (scm-mcp-proxy-handler)
    │
    │ method: "tools/list" → returns tool definitions
    │ method: "tools/call" → calls Bedrock KB
    ▼
bedrock-agent-runtime.retrieve()
    │
    │ managedSearchConfiguration (hybrid semantic + keyword)
    ▼
Bedrock Managed Knowledge Base → S3 documents
```

---

## MCP Protocol Details

The Lambda implements a minimal MCP server with these methods:

### tools/list Response
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [{
      "name": "retrieve_logistics_docs",
      "description": "Search the knowledge base for...",
      "inputSchema": {
        "type": "object",
        "properties": {
          "query": {"type": "string"},
          "numberOfResults": {"type": "integer"}
        },
        "required": ["query"]
      }
    }]
  }
}
```

### tools/call Request
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "retrieve_logistics_docs",
    "arguments": {
      "query": "ocean freight rates Shanghai to LA",
      "numberOfResults": 5
    }
  }
}
```

### tools/call Response
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "content": [{
      "type": "text",
      "text": "[Result 1] (score: 0.762, source: s3://bucket/documents/freight_costs/ocean_rates.md)\n..."
    }]
  }
}
```

---

## OAuth2 Authentication Flow

```
┌──────────┐       ┌───────────┐       ┌────────────┐       ┌────────┐
│ Snowflake│       │ Cognito   │       │ API Gateway│       │ Lambda │
│ CoWork   │       │           │       │            │       │        │
└────┬─────┘       └─────┬─────┘       └──────┬─────┘       └────┬───┘
     │                    │                     │                   │
     │ 1. Connect         │                     │                   │
     │──────────────────> │                     │                   │
     │                    │                     │                   │
     │ 2. Login page      │                     │                   │
     │ <──────────────────│                     │                   │
     │                    │                     │                   │
     │ 3. Credentials     │                     │                   │
     │──────────────────> │                     │                   │
     │                    │                     │                   │
     │ 4. Auth code       │                     │                   │
     │ <──────────────────│                     │                   │
     │                    │                     │                   │
     │ 5. Exchange for tokens                   │                   │
     │──────────────────> │                     │                   │
     │                    │                     │                   │
     │ 6. Access token    │                     │                   │
     │ <──────────────────│                     │                   │
     │                    │                     │                   │
     │ 7. MCP request + Bearer token            │                   │
     │─────────────────────────────────────────>│                   │
     │                    │                     │                   │
     │                    │  8. Validate JWT     │                   │
     │                    │ <───────────────────│                   │
     │                    │                     │                   │
     │                    │                     │ 9. Invoke Lambda  │
     │                    │                     │──────────────────>│
     │                    │                     │                   │
     │                    │                     │ 10. KB results    │
     │                    │                     │ <─────────────────│
     │                    │                     │                   │
     │ 11. MCP response (tool results)          │                   │
     │ <────────────────────────────────────────│                   │
```

---

## Security Model

| Layer | Mechanism | Controls |
|-------|-----------|----------|
| Snowflake Agent access | RBAC (role grants) | Who can invoke the agent |
| Semantic View | SELECT privilege | Who can query structured data |
| Cortex Search | USAGE privilege | Who can search documents |
| External MCP Server | USAGE + INTEGRATION grants | Who can use MCP tools |
| API Gateway | Cognito JWT Authorizer | Validates every request has valid token |
| Cognito | User Pool + App Client | Issues tokens only to authenticated users |
| Lambda | IAM Execution Role | Least-privilege: only `bedrock:Retrieve` |
| Bedrock KB | KB service role | Only reads from specific S3 prefix |

---

## Cross-Platform Query Flow (Example)

**Question:** *"For suppliers with low quality ratings, what are the freight costs from their regions?"*

```
Step 1: Agent routes to TWO tools (parallel execution)

  ┌─ Cortex Analyst ──────────────────────────────────────────┐
  │  SQL: SELECT SUPPLIER_NAME, REGION, QUALITY_RATING        │
  │       FROM SUPPLIERS_DIM WHERE QUALITY_RATING < 3.5       │
  │  Result: 6 suppliers from China, Vietnam, Brazil          │
  └───────────────────────────────────────────────────────────┘

  ┌─ MCP Tool (Bedrock KB) ──────────────────────────────────┐
  │  Query: "freight costs shipping from China, Vietnam"      │
  │  Flow: API GW → Lambda → Bedrock Retrieve                │
  │  Result: Ocean rates $2,850-$3,200/container, 14-21 days  │
  └───────────────────────────────────────────────────────────┘

Step 2: Agent synthesizes both results into one coherent answer
```

---

## Latency Characteristics

| Component | Typical Latency |
|-----------|----------------|
| Agent orchestration (LLM planning) | 2-5s |
| Cortex Analyst (SQL gen + execution) | 1-3s |
| Cortex Search (vector search) | 200-500ms |
| MCP round-trip (Snowflake → AWS → KB) | 3-8s |
| Total (single tool) | 3-8s |
| Total (multi-tool, parallel) | 5-12s |
| Budget limit | 60s max |

---

## Adapting This Pattern

To connect a different AWS data source via MCP:

1. **Change the Lambda handler** — replace `bedrock-agent-runtime:Retrieve` with any AWS API call (DynamoDB, OpenSearch, Athena, SageMaker, etc.)
2. **Update the tool definition** — change `name`, `description`, and `inputSchema` in the Lambda
3. **Update IAM permissions** — grant the Lambda role access to your target service
4. **Keep everything else** — API Gateway, Cognito, Snowflake External MCP Server config remain the same

The infrastructure pattern (OAuth2 → API Gateway → Lambda → AWS service) works for any AWS resource you want to expose as an MCP tool to Snowflake.
