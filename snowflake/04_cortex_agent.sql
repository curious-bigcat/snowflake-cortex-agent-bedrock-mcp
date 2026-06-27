-- =============================================================================
-- CORTEX AGENT - Manufacturing Operations
-- Creates the agent with Cortex Analyst + Cortex Search tools
-- (MCP connector added later via 05_mcp_connection.sql)
-- =============================================================================

USE DATABASE SUPPLY_CHAIN_MFG_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE DEMO_WH;

CREATE OR REPLACE AGENT MFG_OPERATIONS_AGENT
  COMMENT = 'Manufacturing operations intelligence agent with cross-platform orchestration to AWS Bedrock AgentCore'
  FROM SPECIFICATION
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
      
      Provide data-driven insights. When presenting numbers, include context (e.g., 
      whether a yield of 93% is concerning vs normal). Always cite which data source 
      provided the information. If a question spans multiple domains, synthesize insights 
      across sources.

    orchestration: |
      Route queries using these rules:
      - Production metrics, supplier performance, material costs, yield, defects, capacity → use MfgAnalyst
      - Supplier emails, negotiations, delay notices, price changes, force majeure → use SupplierCommsSearch
      - Quality audits, inspection findings, corrective actions, compliance → use QualityReportsSearch
      - For cross-domain questions, invoke multiple tools and synthesize
      - When asked about freight costs, shipping, customer returns, or compliance documents → these are in the AWS logistics system (AWSLogisticsKB MCP tool, added separately)
      
      Examples:
      - "Which suppliers have quality issues?" → MfgAnalyst (quality_rating) + SupplierCommsSearch (quality-related emails)
      - "What's our yield this quarter?" → MfgAnalyst only
      - "Any supplier delays?" → SupplierCommsSearch only
      - "Are there quality problems at our plants?" → QualityReportsSearch + MfgAnalyst (defect data)

    sample_questions:
      - question: "Which suppliers have quality ratings below 3.5 and what communications have they sent?"
      - question: "What is the average production yield by plant and are there related quality findings?"
      - question: "Show me critical material shortages and any supplier communications about supply issues"
      - question: "What corrective actions are still open across our plants?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "MfgAnalyst"
        description: "Queries structured manufacturing data including suppliers (quality ratings, lead times, certifications), raw materials (costs, stock levels, categories), production orders (yield, defects, costs, schedules), and plant locations (capacity, type). Use for any quantitative question about production performance, supplier metrics, costs, or inventory."
    - tool_spec:
        type: "cortex_search"
        name: "SupplierCommsSearch"
        description: "Searches supplier email communications. Contains messages about delivery delays, price changes, force majeure events, quality issues, capacity constraints, new product announcements, contract discussions, and logistics updates. Useful for understanding supplier relationship context and recent events."
    - tool_spec:
        type: "cortex_search"
        name: "QualityReportsSearch"
        description: "Searches quality audit and inspection reports from manufacturing plants. Contains findings about process control issues, equipment failures, calibration problems, contamination, weld defects, ESD concerns, and corrective action plans with severity levels (Critical, Major, Minor)."

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
          description: "Name of the supplier company that sent the email"
          type: "string"
          searchable: false
          filterable: true
        SUBJECT:
          description: "Email subject line"
          type: "string"
          searchable: true
          filterable: false
        PRIORITY:
          description: "Priority level: Critical, High, Medium, Low"
          type: "string"
          searchable: false
          filterable: true
        DATE_SENT:
          description: "Date the email was sent (YYYY-MM-DD format)"
          type: "string"
          searchable: false
          filterable: true
        CATEGORY:
          description: "Communication category: Delay Notice, Price Change, Force Majeure, Quality Issue, Certification, New Product, Capacity Update, Payment Issue, Allocation, Logistics, Contract, Sustainability, Disruption, Compliance, EOL Notice, Recovery Update, Risk Advisory, Innovation, Pricing, Quality Advisory, Product Change, Business Continuity, Capacity, Improvement"
          type: "string"
          searchable: false
          filterable: true
    QualityReportsSearch:
      name: "SUPPLY_CHAIN_MFG_DEMO.PUBLIC.QUALITY_REPORTS_CSS"
      max_results: "5"
      columns_and_descriptions:
        REPORT_TEXT:
          description: "Full quality audit report text including findings, root causes, and corrective actions"
          type: "string"
          searchable: true
          filterable: false
        PLANT_NAME:
          description: "Name of the manufacturing plant audited"
          type: "string"
          searchable: false
          filterable: true
        AUDIT_DATE:
          description: "Date of the audit (YYYY-MM-DD format)"
          type: "string"
          searchable: false
          filterable: true
        AUDITOR:
          description: "Name of the auditor who conducted the inspection"
          type: "string"
          searchable: false
          filterable: true
        SEVERITY:
          description: "Severity of findings: Critical, Major, Minor"
          type: "string"
          searchable: false
          filterable: true
        CATEGORY:
          description: "Audit category: Calibration, Process Control, ISO Audit, Weld Quality, Packaging, ESD Control, Follow-up Audit, Tool Management, Incoming Inspection"
          type: "string"
          searchable: false
          filterable: true
        STATUS:
          description: "Current status: Open, Closed"
          type: "string"
          searchable: false
          filterable: true
  $$;

-- Verify agent creation
SHOW AGENTS IN SCHEMA SUPPLY_CHAIN_MFG_DEMO.PUBLIC;
DESCRIBE AGENT MFG_OPERATIONS_AGENT;
