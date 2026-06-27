# Snowflake Cortex Agent + AWS Bedrock Knowledge Base via MCP

A reference architecture for **cross-platform AI agent orchestration** — connecting Snowflake Cortex Agents to AWS Bedrock Knowledge Bases using the Model Context Protocol (MCP).

This project demonstrates how to build a unified AI agent that queries data across both platforms in a single conversation, with the agent intelligently routing questions to the right data source.

## What This Demonstrates

| Integration Pattern | Implementation |
|---|---|
| Snowflake Cortex Agent as orchestrator | Routes queries across multiple tools using LLM-based planning |
| Cortex Analyst (text-to-SQL) | Structured data queries via Semantic View |
| Cortex Search (RAG) | Unstructured document retrieval via vector search |
| AWS Bedrock Knowledge Base as MCP tool | External data accessible via MCP protocol |
| OAuth2-to-IAM bridge | Lambda + API Gateway + Cognito translates between auth systems |
| Cross-platform orchestration | Single query triggers tools on both Snowflake and AWS |

## Architecture

```
         ┌─────────────────────────────────────────────────────────┐
         │        SNOWFLAKE CORTEX AGENT (Orchestrator)             │
         │        Model: auto | Budget: 60s                         │
         ├─────────────────────────────────────────────────────────┤
         │                                                         │
         │  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐ │
         │  │ Cortex       │ │ Cortex       │ │ External MCP   │ │
         │  │ Analyst      │ │ Search       │ │ Server         │ │
         │  │ (text-to-SQL)│ │ (RAG)        │ │ (AWS Bedrock)  │ │
         │  └──────┬───────┘ └──────┬───────┘ └───────┬────────┘ │
         └─────────┼────────────────┼──────────────────┼───────────┘
                   │                │                   │
                   ▼                ▼                   ▼
         ┌──────────────┐  ┌──────────────┐   ┌────────────────────┐
         │ Semantic View │  │ Cortex Search│   │ AWS API Gateway    │
         │ (structured  │  │ Service      │   │ + Cognito (OAuth2) │
         │  tables)     │  │ (unstructured│   │        │           │
         └──────────────┘  │  documents)  │   │  Lambda MCP Server │
                           └──────────────┘   │  (implements MCP)  │
                                              │        │           │
                                              │  Bedrock Managed   │
                                              │  Knowledge Base    │
                                              │        │           │
                                              │  S3 Documents      │
                                              └────────────────────┘
```

## The Integration Challenge

Snowflake External MCP Servers **only support OAuth2 authentication**. AWS Bedrock services use **IAM/SigV4 authentication**. These are fundamentally different auth systems:

- **OAuth2**: User-centric, token-based, cloud-agnostic standard
- **SigV4/IAM**: AWS-specific, request-signing, machine-to-machine

This project solves the gap with a Lambda function that:
1. Accepts OAuth2-authenticated requests (validated by API Gateway + Cognito)
2. Implements the MCP protocol (tools/list, tools/call)
3. Calls Bedrock KB Retrieve API using its IAM execution role
4. Returns results in MCP format back to Snowflake

## Example Use Case: Supply Chain Manufacturing

The included example uses a manufacturing supply chain scenario to demonstrate the integration with realistic data:

| Data Location | Data Type | What's There |
|---|---|---|
| Snowflake (structured) | Tables with Semantic View | Suppliers, materials, production orders, plant locations, IoT telemetry |
| Snowflake (unstructured) | Cortex Search services | Supplier email communications, quality audit reports |
| AWS S3 + Bedrock KB | Documents via MCP | Freight rates, customer returns/RMAs, compliance/ISO certifications |

The Cortex Agent orchestrates across all sources — a single question like *"For suppliers with quality issues, what are the freight costs from their regions and have customers complained?"* triggers the Analyst (structured query), Cortex Search (emails), AND the MCP tool (Bedrock KB) in one turn.

## Setup Steps

### Snowflake Side

```bash
# 1. Create database, tables, and synthetic data
snowsql -f snowflake/01_data_setup.sql

# 2. Create Cortex Search services (vector indexes for unstructured data)
snowsql -f snowflake/02_cortex_search.sql

# 3. Create Semantic View (schema for Cortex Analyst text-to-SQL)
snowsql -f snowflake/03_semantic_view.sql

# 4. Create Cortex Agent with Snowflake-native tools
snowsql -f snowflake/04_cortex_agent.sql
```

### AWS Side

```bash
cd aws
pip install -r requirements.txt

# 5. Upload documents to S3 and create Bedrock Managed Knowledge Base
python setup_knowledge_base.py

# 6. Deploy Lambda MCP server + API Gateway + Cognito
python deploy_oauth_proxy.py --kb-id <KB_ID>
```

### Connect the Platforms

```bash
# 7. Create External MCP Server in Snowflake pointing to Lambda
#    Edit 05_mcp_connection.sql with values from step 6, then:
snowsql -f snowflake/05_mcp_connection.sql

# 8. Authenticate in Snowflake CoWork
#    Go to agent > Connectors > Connect > Log in with Cognito credentials
```

## Key Components

### Snowflake Objects Created

| Object | Type | Purpose |
|---|---|---|
| `MFG_OPERATIONS_AGENT` | Cortex Agent | Orchestrator with 3 native tools + 1 MCP tool |
| `MFG_OPERATIONS_SV` | Semantic View | Enables text-to-SQL over structured tables |
| `SUPPLIER_COMMS_CSS` | Cortex Search Service | Vector search over supplier emails |
| `QUALITY_REPORTS_CSS` | Cortex Search Service | Vector search over quality reports |
| `AWS_LOGISTICS_MCP` | External MCP Server | Connects to AWS Lambda via OAuth2 |
| `aws_logistics_mcp_integration` | API Integration | OAuth2 config (Cognito endpoints) |

### AWS Resources Created

| Resource | Service | Purpose |
|---|---|---|
| S3 bucket + documents | S3 | Source data for Knowledge Base |
| Managed Knowledge Base | Bedrock | RAG retrieval over documents |
| Lambda function | Lambda | MCP server implementation (tools/list + tools/call) |
| HTTP API | API Gateway | HTTPS endpoint with JWT authorizer |
| User Pool + App Client | Cognito | OAuth2 token issuance for Snowflake |

### MCP Protocol Implementation

The Lambda implements these MCP methods:

| Method | What It Does |
|---|---|
| `tools/list` | Returns tool schema (`retrieve_logistics_docs` with query + numberOfResults params) |
| `tools/call` | Calls `bedrock-agent-runtime:Retrieve` and returns formatted results |
| `initialize` | Returns server capabilities |

## Sample Questions

See the full list of 35 sample questions in the [Sample Questions](#sample-questions-1) section below, organized by:
- **Category A** (15 questions): Snowflake-only — uses Cortex Analyst and/or Cortex Search
- **Category B** (10 questions): AWS-only — uses Bedrock KB via MCP
- **Category C** (10 questions): Cross-platform — orchestrates across both Snowflake and AWS

## File Structure

```
├── README.md                           ← You are here
├── snowflake/
│   ├── 01_data_setup.sql              ← Database + tables + synthetic data
│   ├── 02_cortex_search.sql           ← Cortex Search services
│   ├── 03_semantic_view.sql           ← Semantic View for Cortex Analyst
│   ├── 04_cortex_agent.sql            ← Agent with Snowflake-native tools
│   └── 05_mcp_connection.sql          ← External MCP Server + ALTER AGENT
├── aws/
│   ├── requirements.txt
│   ├── setup_knowledge_base.py        ← S3 upload + Bedrock KB creation guide
│   ├── deploy_oauth_proxy.py          ← Lambda + API Gateway + Cognito deployment
│   ├── test_gateway.py                ← End-to-end MCP server test
│   ├── lambda/
│   │   └── mcp_proxy_handler.py       ← MCP server implementation
│   └── sample_documents/              ← Documents for Bedrock KB
│       ├── freight_costs/
│       ├── customer_returns/
│       └── compliance/
├── demo/
│   ├── requirements.txt
│   └── run_demo.py                    ← Agent REST API demo client
└── diagrams/
    └── architecture.md                ← Detailed technical architecture
```

## Adapting to Your Use Case

This is a reference architecture. To adapt it to your domain:

1. **Replace the Snowflake data** — swap the supply chain tables with your own structured/unstructured data
2. **Replace the S3 documents** — upload your own documents to the Bedrock Knowledge Base
3. **Update the Semantic View** — model your tables' facts, dimensions, and metrics
4. **Update the Agent instructions** — change the orchestration routing rules for your tools
5. **Keep the MCP bridge unchanged** — the Lambda/API Gateway/Cognito infrastructure works for any Bedrock KB

The integration pattern (OAuth2 bridge between Snowflake and AWS) is domain-agnostic.

---

## Sample Questions

### Category A: Snowflake-Only (Cortex Analyst + Cortex Search)

| # | Question | Tools Used |
|---|----------|-----------|
| A1 | Which suppliers have quality ratings below 3.5 and what communications have they sent? | Analyst + SupplierCommsSearch |
| A2 | Show production orders with yield below 94% and any related quality audit findings | Analyst + QualityReportsSearch |
| A3 | What is the average production yield by plant and which plants have the most defects? | Analyst |
| A4 | Find all supplier communications about force majeure events or production disruptions | SupplierCommsSearch |
| A5 | What critical quality audit findings are still open across our plants? | QualityReportsSearch |
| A6 | What is the total inventory value of critical materials and which are below reorder point? | Analyst |
| A7 | Which suppliers from China have sent price increase notifications? | Analyst + SupplierCommsSearch |
| A8 | Show me production orders for Automotive category sorted by defect count | Analyst |
| A9 | What corrective actions were identified for the Shenzhen Electronics Plant? | QualityReportsSearch |
| A10 | Which materials are below minimum stock level and who are their suppliers? | Analyst |
| A11 | What is the on-time completion rate across all plants? | Analyst |
| A12 | Find communications about quality issues and correlate with supplier quality ratings | Analyst + SupplierCommsSearch |
| A13 | Show weld-related quality findings and which production orders were affected | QualityReportsSearch + Analyst |
| A14 | What are our highest cost production orders and which plants produced them? | Analyst |
| A15 | Are there any supplier communications about capacity constraints or lead time changes? | SupplierCommsSearch |

### Category B: AWS-Only (Bedrock Knowledge Base via MCP)

| # | Question | Tools Used |
|---|----------|-----------|
| B1 | What are the current ocean freight rates for shipping from Shanghai to Los Angeles? | MCP |
| B2 | What are air freight rates from Stuttgart to Austin, Texas? | MCP |
| B3 | Show me customer return complaints related to electronics or solder defects | MCP |
| B4 | What ISO certifications do our manufacturing plants hold and are any under surveillance? | MCP |
| B5 | What customs duties apply to aluminum imports from China with Section 232 tariffs? | MCP |
| B6 | Are there any warranty claims with potential regulatory impact? | MCP |
| B7 | What are ground freight rates for shipping from Monterrey Mexico to Austin? | MCP |
| B8 | Show me the material safety data sheet information for epoxy resin and hydraulic fluid | MCP |
| B9 | What USMCA preferential duty rates apply to our Mexico suppliers? | MCP |
| B10 | What is the financial impact of the hydraulic valve body customer returns? | MCP |

### Category C: Cross-Platform Orchestration (Snowflake + AWS)

| # | Question | Tools Used |
|---|----------|-----------|
| C1 | For suppliers with quality ratings below 3.5, what are the freight costs from their regions and have customers filed complaints about their products? | Analyst + MCP |
| C2 | Our Detroit Fabrication Center had weld quality issues — show me the production orders affected, the quality audit findings, AND any customer return complaints about those products | Analyst + QualityReportsSearch + MCP |
| C3 | Compare total landed cost (material cost + freight + customs duty) for our Asia Pacific vs North America suppliers | Analyst + MCP |
| C4 | Which production orders had high defect counts AND resulted in customer warranty claims? | Analyst + MCP |
| C5 | What is the complete risk profile for Shenzhen QuickParts — quality rating, communications about issues, quality audit findings at plants using their materials, AND customer returns? | Analyst + SupplierCommsSearch + QualityReportsSearch + MCP |
| C6 | For our Aerospace product category, what is the production yield, which quality audits are relevant, and what are the compliance certifications? | Analyst + QualityReportsSearch + MCP |
| C7 | What suppliers communicated about price increases, what is the freight cost from their regions, and how does this impact our total production costs? | SupplierCommsSearch + MCP + Analyst |
| C8 | Show me the end-to-end supply chain risk for EV battery production — material stock levels, supplier reliability, quality issues at Austin plant, freight costs from Asia, and any customer returns | Analyst + SupplierCommsSearch + QualityReportsSearch + MCP |
| C9 | What are the ocean freight rates from Japan and what is Nippon Steel's delivery performance and quality rating? | MCP + Analyst |
| C10 | For products with customer warranty claims, trace back to which plant produced them, what quality findings exist, and what the supplier communicated | MCP + QualityReportsSearch + SupplierCommsSearch + Analyst |
