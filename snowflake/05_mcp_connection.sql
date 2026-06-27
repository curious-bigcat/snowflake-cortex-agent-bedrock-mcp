-- =============================================================================
-- MCP CONNECTION - Connect AWS Bedrock KB (via Lambda MCP Server) to Cortex Agent
-- Run this AFTER deploying the AWS OAuth proxy (aws/deploy_oauth_proxy.py)
-- =============================================================================

USE DATABASE SUPPLY_CHAIN_MFG_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE DEMO_WH;

-- =============================================================================
-- STEP 1: Create API Integration with OAuth (backed by AWS Cognito)
-- Replace placeholders with your actual values from the AWS deployment
-- =============================================================================

CREATE OR REPLACE API INTEGRATION aws_logistics_mcp_integration
  API_PROVIDER = external_mcp
  API_ALLOWED_PREFIXES = ('https://<YOUR_API_GATEWAY_ID>.execute-api.us-east-1.amazonaws.com')
  API_USER_AUTHENTICATION = (
    TYPE = OAUTH2
    OAUTH_CLIENT_ID = '<YOUR_COGNITO_CLIENT_ID>'
    OAUTH_CLIENT_SECRET = '<YOUR_COGNITO_CLIENT_SECRET>'
    OAUTH_TOKEN_ENDPOINT = 'https://<YOUR_COGNITO_DOMAIN>.auth.us-east-1.amazoncognito.com/oauth2/token'
    OAUTH_AUTHORIZATION_ENDPOINT = 'https://<YOUR_COGNITO_DOMAIN>.auth.us-east-1.amazoncognito.com/oauth2/authorize'
    OAUTH_ALLOWED_SCOPES = ('openid')
    OAUTH_REFRESH_TOKEN_VALIDITY = 86400
  )
  ENABLED = TRUE;

-- =============================================================================
-- STEP 2: Create External MCP Server pointing to the OAuth proxy
-- =============================================================================

CREATE EXTERNAL MCP SERVER SUPPLY_CHAIN_MFG_DEMO.PUBLIC.AWS_LOGISTICS_MCP
  WITH DISPLAY_NAME = 'AWS Logistics & Compliance Knowledge Base'
  URL = 'https://<YOUR_API_GATEWAY_ID>.execute-api.us-east-1.amazonaws.com/prod/mcp'
  API_INTEGRATION = aws_logistics_mcp_integration;

-- Grant access
GRANT USAGE ON EXTERNAL MCP SERVER AWS_LOGISTICS_MCP TO ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION aws_logistics_mcp_integration TO ROLE ACCOUNTADMIN;

-- =============================================================================
-- STEP 3: Update the Agent to include the MCP server
-- NOTE: ALTER AGENT replaces the full specification, so include everything
-- =============================================================================

ALTER AGENT MFG_OPERATIONS_AGENT MODIFY LIVE VERSION SET SPECIFICATION =
$$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 60
    tokens: 20000

instructions:
  response: |
    You are a manufacturing operations intelligence assistant for a global manufacturer 
    with 6 plants across North America, Europe, and Asia Pacific. You have access to:
    - Structured production data (suppliers, materials, production orders, plants)
    - Supplier communications (emails about delays, price changes, quality issues)
    - Quality audit reports (inspection findings, corrective actions)
    - AWS Logistics knowledge base (freight costs, customer returns, compliance documents)
    
    Provide data-driven insights. When presenting numbers, include context.
    Always cite which data source provided the information. 
    For cross-platform questions, synthesize insights from both Snowflake and AWS sources.

  orchestration: |
    Route queries using these rules:
    - Production metrics, supplier performance, material costs, yield, defects, capacity → MfgAnalyst
    - Supplier emails, negotiations, delay notices, price changes, force majeure → SupplierCommsSearch
    - Quality audits, inspection findings, corrective actions → QualityReportsSearch
    - Freight costs, shipping rates, carrier contracts, customs duties → AWSLogisticsKB (MCP)
    - Customer returns, RMA records, warranty claims, product complaints → AWSLogisticsKB (MCP)
    - Regulatory compliance, ISO audits (external), MSDS, customs declarations → AWSLogisticsKB (MCP)
    - Cross-domain questions → invoke multiple tools and synthesize

  sample_questions:
    - question: "Which suppliers have quality ratings below 3.5 and what communications have they sent?"
    - question: "What is the average production yield by plant and are there related quality findings?"
    - question: "Compare freight costs for Asia Pacific vs North America suppliers"
    - question: "For products with high defect rates, are there customer return complaints?"

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "MfgAnalyst"
      description: "Queries structured manufacturing data including suppliers (quality ratings, lead times, certifications), raw materials (costs, stock levels, categories), production orders (yield, defects, costs, schedules), and plant locations (capacity, type). Use for any quantitative question about production performance, supplier metrics, costs, or inventory."
  - tool_spec:
      type: "cortex_search"
      name: "SupplierCommsSearch"
      description: "Searches supplier email communications. Contains messages about delivery delays, price changes, force majeure events, quality issues, capacity constraints, new product announcements, contract discussions, and logistics updates."
  - tool_spec:
      type: "cortex_search"
      name: "QualityReportsSearch"
      description: "Searches quality audit and inspection reports from manufacturing plants. Contains findings about process control issues, equipment failures, calibration problems, contamination, weld defects, ESD concerns, and corrective action plans."

tool_resources:
  MfgAnalyst:
    semantic_view: "SUPPLY_CHAIN_MFG_DEMO.PUBLIC.MFG_OPERATIONS_SV"
  SupplierCommsSearch:
    name: "SUPPLY_CHAIN_MFG_DEMO.PUBLIC.SUPPLIER_COMMS_CSS"
    max_results: "5"
    columns_and_descriptions:
      EMAIL_BODY:
        description: "Full email content from supplier communications"
        type: "string"
        searchable: true
        filterable: false
      SUPPLIER_NAME:
        description: "Name of the supplier company"
        type: "string"
        searchable: false
        filterable: true
      PRIORITY:
        description: "Priority level: Critical, High, Medium, Low"
        type: "string"
        searchable: false
        filterable: true
      CATEGORY:
        description: "Communication category: Delay Notice, Price Change, Force Majeure, Quality Issue, etc."
        type: "string"
        searchable: false
        filterable: true
  QualityReportsSearch:
    name: "SUPPLY_CHAIN_MFG_DEMO.PUBLIC.QUALITY_REPORTS_CSS"
    max_results: "5"
    columns_and_descriptions:
      REPORT_TEXT:
        description: "Full quality audit report text"
        type: "string"
        searchable: true
        filterable: false
      PLANT_NAME:
        description: "Plant name"
        type: "string"
        searchable: false
        filterable: true
      SEVERITY:
        description: "Finding severity: Critical, Major, Minor"
        type: "string"
        searchable: false
        filterable: true
      STATUS:
        description: "Status: Open, Closed"
        type: "string"
        searchable: false
        filterable: true

mcp_servers:
  - server_spec:
      name: "SUPPLY_CHAIN_MFG_DEMO.PUBLIC.AWS_LOGISTICS_MCP"
$$;

-- =============================================================================
-- VERIFY
-- =============================================================================
SHOW EXTERNAL MCP SERVERS IN SCHEMA SUPPLY_CHAIN_MFG_DEMO.PUBLIC;
DESCRIBE AGENT MFG_OPERATIONS_AGENT;
