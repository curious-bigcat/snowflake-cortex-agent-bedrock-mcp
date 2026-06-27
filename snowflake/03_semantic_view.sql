-- =============================================================================
-- SEMANTIC VIEW - Manufacturing Operations
-- Enables Cortex Analyst for structured data queries
-- =============================================================================

USE DATABASE SUPPLY_CHAIN_MFG_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE DEMO_WH;

CREATE OR REPLACE SEMANTIC VIEW MFG_OPERATIONS_SV

  TABLES (
    suppliers AS SUPPLY_CHAIN_MFG_DEMO.PUBLIC.SUPPLIERS_DIM
      PRIMARY KEY (SUPPLIER_ID)
      COMMENT = 'Supplier master data with quality ratings, certifications, lead times, and contract details',
    materials AS SUPPLY_CHAIN_MFG_DEMO.PUBLIC.RAW_MATERIALS
      PRIMARY KEY (MATERIAL_ID)
      COMMENT = 'Bill of materials with costs, stock levels, and supplier relationships',
    production AS SUPPLY_CHAIN_MFG_DEMO.PUBLIC.PRODUCTION_ORDERS
      PRIMARY KEY (ORDER_ID)
      COMMENT = 'Manufacturing production orders with yield, defects, costs, and delivery tracking',
    plants AS SUPPLY_CHAIN_MFG_DEMO.PUBLIC.PLANT_LOCATIONS
      PRIMARY KEY (PLANT_ID)
      COMMENT = 'Manufacturing plant locations with capacity information'
  )

  RELATIONSHIPS (
    materials (SUPPLIER_ID) REFERENCES suppliers,
    production (PLANT_ID) REFERENCES plants,
    production (PRIMARY_MATERIAL_ID) REFERENCES materials (MATERIAL_ID)
  )

  FACTS (
    suppliers.lead_time_days AS LEAD_TIME_DAYS,
    suppliers.quality_rating AS QUALITY_RATING,
    materials.unit_cost AS UNIT_COST,
    materials.current_stock AS CURRENT_STOCK,
    materials.min_stock_level AS MIN_STOCK_LEVEL,
    materials.reorder_qty AS REORDER_QTY,
    production.quantity_ordered AS QUANTITY_ORDERED,
    production.quantity_produced AS QUANTITY_PRODUCED,
    production.yield_pct AS YIELD_PCT,
    production.defect_count AS DEFECT_COUNT,
    production.unit_production_cost AS UNIT_PRODUCTION_COST,
    production.total_cost AS TOTAL_COST,
    plants.capacity_units_per_day AS CAPACITY_UNITS_PER_DAY
  )

  DIMENSIONS (
    suppliers.supplier_name AS SUPPLIER_NAME
      WITH SYNONYMS = ('vendor', 'vendor name', 'supplier')
      COMMENT = 'Supplier company name',
    suppliers.country AS COUNTRY
      COMMENT = 'Country where supplier is headquartered',
    suppliers.region AS REGION
      COMMENT = 'Geographic region: North America, Europe, Asia Pacific, South America, Middle East',
    suppliers.certification AS CERTIFICATION
      COMMENT = 'Quality certifications held (ISO 9001, ISO 14001, IATF 16949, AS9100)',
    suppliers.payment_terms AS PAYMENT_TERMS
      COMMENT = 'Payment terms: Net 30, Net 45, or Net 60',
    suppliers.is_preferred AS IS_PREFERRED
      COMMENT = 'TRUE if this is a preferred/strategic supplier',
    suppliers.contract_start AS CONTRACT_START
      COMMENT = 'Contract start date',
    suppliers.contract_end AS CONTRACT_END
      COMMENT = 'Contract end date',

    materials.material_name AS MATERIAL_NAME
      WITH SYNONYMS = ('part', 'component', 'material')
      COMMENT = 'Descriptive name of the raw material',
    materials.material_category AS CATEGORY
      COMMENT = 'Material category: Metals, Composites, Chemicals, Polymers, Electronics, Mechanical, Ceramics, Hardware, Optics',
    materials.material_subcategory AS SUBCATEGORY
      COMMENT = 'Material subcategory',
    materials.is_critical AS IS_CRITICAL
      COMMENT = 'TRUE if this is a critical material (single-source or long lead time)',

    production.product_name AS PRODUCT_NAME
      WITH SYNONYMS = ('product', 'part name')
      COMMENT = 'Name of the product being manufactured',
    production.product_category AS PRODUCT_CATEGORY
      COMMENT = 'Product category: Automotive, Electronics, Aerospace, Industrial, Medical, Consumer, Telecom, Energy, Construction, Optics',
    production.order_status AS STATUS
      COMMENT = 'Order status: Completed, In Progress, Pending',
    production.priority AS PRIORITY
      COMMENT = 'Priority level: Critical, High, Medium, Low',
    production.order_date AS ORDER_DATE
      COMMENT = 'Date the production order was created',
    production.start_date AS START_DATE
      COMMENT = 'Date production started',
    production.target_completion AS TARGET_COMPLETION
      COMMENT = 'Target completion date',
    production.actual_completion AS ACTUAL_COMPLETION
      COMMENT = 'Actual completion date (NULL if not complete)',

    plants.plant_name AS PLANT_NAME
      WITH SYNONYMS = ('factory', 'facility', 'plant', 'site')
      COMMENT = 'Name of the manufacturing plant',
    plants.plant_city AS CITY
      COMMENT = 'City where the plant is located',
    plants.plant_country AS COUNTRY
      COMMENT = 'Country where the plant is located',
    plants.plant_region AS REGION
      COMMENT = 'Geographic region of the plant',
    plants.plant_type AS PLANT_TYPE
      COMMENT = 'Type of manufacturing: Assembly, Fabrication, Electronics'
  )

  METRICS (
    suppliers.avg_quality_rating AS AVG(QUALITY_RATING)
      COMMENT = 'Average supplier quality rating (1-5 scale)',
    suppliers.avg_lead_time AS AVG(LEAD_TIME_DAYS)
      COMMENT = 'Average supplier lead time in days',
    suppliers.supplier_count AS COUNT(SUPPLIER_ID)
      COMMENT = 'Total number of suppliers',
    materials.total_inventory_value AS SUM(materials.current_stock * materials.unit_cost)
      COMMENT = 'Total value of current inventory in USD',
    materials.materials_below_min AS SUM(CASE WHEN materials.current_stock < materials.min_stock_level THEN 1 ELSE 0 END)
      COMMENT = 'Count of materials below minimum stock level',
    production.avg_yield AS AVG(production.yield_pct)
      COMMENT = 'Average production yield percentage',
    production.total_defects AS SUM(production.defect_count)
      COMMENT = 'Total defects across all orders',
    production.total_production_cost AS SUM(production.total_cost)
      COMMENT = 'Total production cost in USD',
    production.total_units_produced AS SUM(production.quantity_produced)
      COMMENT = 'Total units produced',
    production.order_count AS COUNT(ORDER_ID)
      COMMENT = 'Total number of production orders',
    plants.total_capacity AS SUM(plants.capacity_units_per_day)
      COMMENT = 'Total daily capacity across all plants'
  )

  COMMENT = 'Manufacturing operations semantic view covering suppliers, materials, production orders, and plants. Use for quantitative analytics on production yield, costs, defects, supplier performance, and capacity.'

  AI_SQL_GENERATION 'When querying production yield, note that yield_pct below 94% is concerning. Quality_rating below 3.5 is considered poor for suppliers. Always include relevant context columns like plant_name or supplier_name when aggregating metrics.'

  AI_VERIFIED_QUERIES (
    low_quality_suppliers AS (
      QUESTION 'Which suppliers have the lowest quality ratings?'
      VERIFIED_AT 1741500000
      ONBOARDING_QUESTION TRUE
      VERIFIED_BY '(STEWARD = bsuresh)'
      SQL 'SELECT SUPPLIER_NAME, COUNTRY, REGION, QUALITY_RATING, LEAD_TIME_DAYS, CERTIFICATION, IS_PREFERRED FROM SUPPLY_CHAIN_MFG_DEMO.PUBLIC.SUPPLIERS_DIM WHERE QUALITY_RATING < 3.5 ORDER BY QUALITY_RATING ASC'
    ),
    yield_by_plant AS (
      QUESTION 'What is the average production yield by plant?'
      VERIFIED_AT 1741500000
      ONBOARDING_QUESTION TRUE
      VERIFIED_BY '(STEWARD = bsuresh)'
      SQL 'SELECT p.PLANT_NAME, p.COUNTRY, p.PLANT_TYPE, ROUND(AVG(po.YIELD_PCT), 1) AS avg_yield_pct, SUM(po.DEFECT_COUNT) AS total_defects, COUNT(po.ORDER_ID) AS total_orders FROM SUPPLY_CHAIN_MFG_DEMO.PUBLIC.PRODUCTION_ORDERS po JOIN SUPPLY_CHAIN_MFG_DEMO.PUBLIC.PLANT_LOCATIONS p ON po.PLANT_ID = p.PLANT_ID WHERE po.STATUS = ''Completed'' GROUP BY p.PLANT_NAME, p.COUNTRY, p.PLANT_TYPE ORDER BY avg_yield_pct ASC'
    ),
    high_defect_orders AS (
      QUESTION 'Show production orders with more than 50 defects'
      VERIFIED_AT 1741500000
      ONBOARDING_QUESTION TRUE
      VERIFIED_BY '(STEWARD = bsuresh)'
      SQL 'SELECT po.ORDER_ID, po.PRODUCT_NAME, po.PRODUCT_CATEGORY, pl.PLANT_NAME, po.QUANTITY_ORDERED, po.DEFECT_COUNT, po.YIELD_PCT, po.TOTAL_COST FROM SUPPLY_CHAIN_MFG_DEMO.PUBLIC.PRODUCTION_ORDERS po JOIN SUPPLY_CHAIN_MFG_DEMO.PUBLIC.PLANT_LOCATIONS pl ON po.PLANT_ID = pl.PLANT_ID WHERE po.DEFECT_COUNT > 50 ORDER BY po.DEFECT_COUNT DESC'
    )
  );

-- Verify semantic view
DESCRIBE SEMANTIC VIEW MFG_OPERATIONS_SV;
