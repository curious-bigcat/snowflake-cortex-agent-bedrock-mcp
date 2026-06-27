-- =============================================================================
-- CORTEX SEARCH SERVICES
-- Creates search services for unstructured data (supplier comms + quality reports)
-- =============================================================================

USE DATABASE SUPPLY_CHAIN_MFG_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE DEMO_WH;

-- 1. Cortex Search Service for Supplier Communications
CREATE OR REPLACE CORTEX SEARCH SERVICE SUPPLIER_COMMS_CSS
  ON EMAIL_BODY
  ATTRIBUTES SUPPLIER_NAME, SUBJECT, PRIORITY, DATE_SENT, CATEGORY
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT
      EMAIL_BODY,
      SUPPLIER_NAME,
      SUBJECT,
      PRIORITY,
      DATE_SENT::VARCHAR AS DATE_SENT,
      CATEGORY
    FROM SUPPLIER_COMMUNICATIONS
  );

-- 2. Cortex Search Service for Quality Audit Reports
CREATE OR REPLACE CORTEX SEARCH SERVICE QUALITY_REPORTS_CSS
  ON REPORT_TEXT
  ATTRIBUTES PLANT_NAME, AUDIT_DATE, AUDITOR, SEVERITY, CATEGORY, STATUS
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT
      REPORT_TEXT,
      PLANT_NAME,
      AUDIT_DATE::VARCHAR AS AUDIT_DATE,
      AUDITOR,
      SEVERITY,
      CATEGORY,
      STATUS
    FROM QUALITY_AUDIT_REPORTS
  );

-- Verify search services are created
SHOW CORTEX SEARCH SERVICES IN SCHEMA SUPPLY_CHAIN_MFG_DEMO.PUBLIC;
