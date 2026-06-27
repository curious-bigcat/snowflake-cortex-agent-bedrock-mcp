-- =============================================================================
-- SUPPLY CHAIN MANUFACTURING DEMO - Data Setup
-- Creates fresh database, tables, and synthetic data
-- =============================================================================

-- 1. Create Database
CREATE OR REPLACE DATABASE SUPPLY_CHAIN_MFG_DEMO;
USE DATABASE SUPPLY_CHAIN_MFG_DEMO;
USE SCHEMA PUBLIC;

-- 2. Create Warehouse (if not exists)
CREATE WAREHOUSE IF NOT EXISTS DEMO_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

USE WAREHOUSE DEMO_WH;

-- =============================================================================
-- STRUCTURED TABLES
-- =============================================================================

-- PLANT_LOCATIONS: Manufacturing facilities
CREATE OR REPLACE TABLE PLANT_LOCATIONS (
    PLANT_ID NUMBER PRIMARY KEY,
    PLANT_NAME VARCHAR(100),
    CITY VARCHAR(50),
    STATE_PROVINCE VARCHAR(50),
    COUNTRY VARCHAR(50),
    REGION VARCHAR(50),
    PLANT_TYPE VARCHAR(30),
    CAPACITY_UNITS_PER_DAY NUMBER,
    ESTABLISHED_DATE DATE,
    IS_ACTIVE BOOLEAN
);

INSERT INTO PLANT_LOCATIONS VALUES
(1, 'Austin Assembly Hub', 'Austin', 'Texas', 'USA', 'North America', 'Assembly', 5000, '2018-03-15', TRUE),
(2, 'Detroit Fabrication Center', 'Detroit', 'Michigan', 'USA', 'North America', 'Fabrication', 3500, '2015-07-01', TRUE),
(3, 'Pune Manufacturing Unit', 'Pune', 'Maharashtra', 'India', 'Asia Pacific', 'Assembly', 8000, '2019-11-20', TRUE),
(4, 'Stuttgart Precision Works', 'Stuttgart', 'Baden-Württemberg', 'Germany', 'Europe', 'Fabrication', 2800, '2016-04-10', TRUE),
(5, 'Shenzhen Electronics Plant', 'Shenzhen', 'Guangdong', 'China', 'Asia Pacific', 'Electronics', 12000, '2020-01-05', TRUE),
(6, 'Guadalajara Assembly', 'Guadalajara', 'Jalisco', 'Mexico', 'North America', 'Assembly', 4200, '2021-06-15', TRUE);

-- SUPPLIERS_DIM: Supplier master data
CREATE OR REPLACE TABLE SUPPLIERS_DIM (
    SUPPLIER_ID NUMBER PRIMARY KEY,
    SUPPLIER_NAME VARCHAR(100),
    CONTACT_NAME VARCHAR(100),
    CONTACT_EMAIL VARCHAR(150),
    COUNTRY VARCHAR(50),
    REGION VARCHAR(50),
    LEAD_TIME_DAYS NUMBER,
    QUALITY_RATING FLOAT,
    CERTIFICATION VARCHAR(100),
    CONTRACT_START DATE,
    CONTRACT_END DATE,
    PAYMENT_TERMS VARCHAR(30),
    IS_PREFERRED BOOLEAN
);

INSERT INTO SUPPLIERS_DIM VALUES
(1, 'Pacific Metals Corp', 'James Chen', 'j.chen@pacificmetals.com', 'USA', 'North America', 5, 4.5, 'ISO 9001, AS9100', '2023-01-01', '2027-12-31', 'Net 30', TRUE),
(2, 'Rhine Valley Precision', 'Klaus Mueller', 'k.mueller@rhineprecision.de', 'Germany', 'Europe', 12, 4.8, 'ISO 9001, ISO 14001', '2023-03-01', '2027-03-01', 'Net 45', TRUE),
(3, 'Tata Advanced Materials', 'Priya Sharma', 'p.sharma@tataadv.in', 'India', 'Asia Pacific', 10, 4.2, 'ISO 9001', '2023-02-15', '2026-08-15', 'Net 30', TRUE),
(4, 'Shenzhen QuickParts', 'Wei Zhang', 'w.zhang@quickparts.cn', 'China', 'Asia Pacific', 18, 2.8, 'ISO 9001', '2023-06-01', '2025-12-01', 'Net 60', FALSE),
(5, 'Great Lakes Composites', 'Sarah Johnson', 'sarah.j@greatlakescomp.com', 'USA', 'North America', 4, 4.7, 'ISO 9001, IATF 16949', '2023-01-15', '2028-01-15', 'Net 30', TRUE),
(6, 'Nippon Steel Solutions', 'Yuki Tanaka', 'y.tanaka@nipponsteelsol.jp', 'Japan', 'Asia Pacific', 14, 4.9, 'ISO 9001, ISO 14001, IATF 16949', '2022-04-01', '2027-04-01', 'Net 45', TRUE),
(7, 'EuroChemicals AG', 'Hans Weber', 'h.weber@eurochemicals.eu', 'Germany', 'Europe', 8, 4.1, 'ISO 9001, ISO 14001, REACH', '2023-09-01', '2026-09-01', 'Net 30', TRUE),
(8, 'Brazilian Rubber Co', 'Carlos Silva', 'c.silva@brazrubber.com.br', 'Brazil', 'South America', 21, 3.5, 'ISO 9001', '2024-01-01', '2026-12-31', 'Net 60', FALSE),
(9, 'Nordic Alloys AB', 'Erik Lindqvist', 'e.lindqvist@nordicalloys.se', 'Sweden', 'Europe', 10, 4.6, 'ISO 9001, ISO 14001', '2023-05-01', '2027-05-01', 'Net 30', TRUE),
(10, 'Dongguan Electronics', 'Li Ming', 'l.ming@dgelectronics.cn', 'China', 'Asia Pacific', 16, 3.1, 'ISO 9001', '2024-03-01', '2026-03-01', 'Net 45', FALSE),
(11, 'Texas Polymer Solutions', 'Mike Rodriguez', 'm.rodriguez@texaspolymer.com', 'USA', 'North America', 3, 4.4, 'ISO 9001, IATF 16949', '2023-07-01', '2027-07-01', 'Net 30', TRUE),
(12, 'Jiangsu Fasteners Ltd', 'Chen Wei', 'c.wei@jiangsufast.cn', 'China', 'Asia Pacific', 20, 2.5, 'ISO 9001', '2024-06-01', '2025-12-01', 'Net 60', FALSE),
(13, 'Midlands Castings UK', 'David Thompson', 'd.thompson@midlandscast.co.uk', 'UK', 'Europe', 9, 4.3, 'ISO 9001, AS9100', '2023-02-01', '2027-02-01', 'Net 30', TRUE),
(14, 'Korean Semiconductor Co', 'Park Ji-Sung', 'js.park@koreansemi.kr', 'South Korea', 'Asia Pacific', 11, 4.7, 'ISO 9001, IATF 16949', '2023-08-01', '2027-08-01', 'Net 45', TRUE),
(15, 'Atlas Mining & Minerals', 'Ahmed Hassan', 'a.hassan@atlasmining.ae', 'UAE', 'Middle East', 15, 3.8, 'ISO 9001', '2024-01-01', '2026-06-01', 'Net 60', FALSE),
(16, 'Monterrey Steel Works', 'Juan Hernandez', 'j.hernandez@montsteel.mx', 'Mexico', 'North America', 6, 4.0, 'ISO 9001', '2023-11-01', '2027-11-01', 'Net 30', TRUE),
(17, 'Vietnam Precision Mfg', 'Nguyen Thi', 'n.thi@vnprecision.vn', 'Vietnam', 'Asia Pacific', 19, 3.3, 'ISO 9001', '2024-04-01', '2026-04-01', 'Net 45', FALSE),
(18, 'Canadian Lumber & Composites', 'Robert Tremblay', 'r.tremblay@canlumber.ca', 'Canada', 'North America', 5, 4.5, 'ISO 9001, FSC', '2023-03-01', '2027-03-01', 'Net 30', TRUE),
(19, 'Shanghai Circuit Board', 'Zhao Yun', 'z.yun@shcircuit.cn', 'China', 'Asia Pacific', 17, 2.9, 'ISO 9001', '2024-02-01', '2025-08-01', 'Net 60', FALSE),
(20, 'Finnish Specialty Chemicals', 'Mika Virtanen', 'm.virtanen@finchemicals.fi', 'Finland', 'Europe', 11, 4.4, 'ISO 9001, ISO 14001, REACH', '2023-06-01', '2027-06-01', 'Net 30', TRUE),
(21, 'Sao Paulo Plastics', 'Ana Costa', 'a.costa@spplastics.com.br', 'Brazil', 'South America', 22, 3.2, 'ISO 9001', '2024-05-01', '2026-05-01', 'Net 60', FALSE),
(22, 'Czech Precision Tools', 'Tomas Novak', 't.novak@czechtools.cz', 'Czech Republic', 'Europe', 9, 4.5, 'ISO 9001, ISO 14001', '2023-04-01', '2027-04-01', 'Net 30', TRUE),
(23, 'Bangalore Tech Components', 'Rajesh Kumar', 'r.kumar@blrtech.in', 'India', 'Asia Pacific', 12, 3.9, 'ISO 9001', '2023-10-01', '2026-10-01', 'Net 45', FALSE),
(24, 'Ohio Industrial Bearings', 'Lisa Williams', 'l.williams@ohiobearings.com', 'USA', 'North America', 4, 4.6, 'ISO 9001, IATF 16949', '2023-01-01', '2027-12-31', 'Net 30', TRUE),
(25, 'Turkish Ceramics International', 'Mehmet Yilmaz', 'm.yilmaz@turkceramics.com.tr', 'Turkey', 'Middle East', 13, 3.7, 'ISO 9001', '2024-01-01', '2026-01-01', 'Net 45', FALSE);

-- RAW_MATERIALS: Bill of materials
CREATE OR REPLACE TABLE RAW_MATERIALS (
    MATERIAL_ID NUMBER PRIMARY KEY,
    MATERIAL_NAME VARCHAR(150),
    CATEGORY VARCHAR(50),
    SUBCATEGORY VARCHAR(50),
    UNIT_OF_MEASURE VARCHAR(20),
    UNIT_COST FLOAT,
    SUPPLIER_ID NUMBER REFERENCES SUPPLIERS_DIM(SUPPLIER_ID),
    MIN_STOCK_LEVEL NUMBER,
    CURRENT_STOCK NUMBER,
    REORDER_QTY NUMBER,
    IS_CRITICAL BOOLEAN,
    SHELF_LIFE_DAYS NUMBER
);

INSERT INTO RAW_MATERIALS VALUES
(101, 'Aluminum Sheet 4x8 (6061-T6)', 'Metals', 'Aluminum', 'Sheet', 85.50, 1, 500, 1200, 1000, TRUE, NULL),
(102, 'Stainless Steel Rod 12mm', 'Metals', 'Steel', 'Meter', 12.30, 6, 2000, 4500, 3000, TRUE, NULL),
(103, 'Carbon Fiber Panel 2mm', 'Composites', 'Carbon Fiber', 'Sheet', 220.00, 5, 200, 380, 500, TRUE, NULL),
(104, 'Copper Wire Spool 500m', 'Metals', 'Copper', 'Spool', 145.00, 9, 100, 85, 200, TRUE, NULL),
(105, 'Industrial Epoxy Resin (50L)', 'Chemicals', 'Adhesives', 'Drum', 320.00, 7, 50, 120, 100, FALSE, 365),
(106, 'Titanium Plate 3mm', 'Metals', 'Titanium', 'Sheet', 450.00, 2, 100, 95, 200, TRUE, NULL),
(107, 'Rubber Gasket Material (Roll)', 'Polymers', 'Rubber', 'Roll', 55.00, 8, 300, 180, 500, FALSE, 730),
(108, 'PCB Substrate FR-4', 'Electronics', 'Circuit Board', 'Panel', 18.50, 14, 5000, 12000, 8000, TRUE, NULL),
(109, 'LED Module Array (100pc)', 'Electronics', 'Lighting', 'Pack', 95.00, 10, 1000, 650, 2000, FALSE, NULL),
(110, 'Bearing Assembly (6205)', 'Mechanical', 'Bearings', 'Unit', 8.75, 24, 3000, 7500, 5000, TRUE, NULL),
(111, 'Hydraulic Fluid (20L)', 'Chemicals', 'Lubricants', 'Container', 78.00, 20, 200, 350, 300, FALSE, 545),
(112, 'Nylon 6/6 Pellets (25kg)', 'Polymers', 'Plastics', 'Bag', 42.00, 11, 800, 2200, 1500, FALSE, NULL),
(113, 'Ceramic Insulator Block', 'Ceramics', 'Insulators', 'Unit', 35.00, 25, 1500, 900, 2000, FALSE, NULL),
(114, 'Precision Fastener Kit M8', 'Hardware', 'Fasteners', 'Kit', 15.50, 12, 4000, 2800, 5000, FALSE, NULL),
(115, 'Thermal Paste (500g)', 'Chemicals', 'Thermal', 'Tube', 28.00, 7, 600, 450, 800, FALSE, 180),
(116, 'Wiring Harness Assembly', 'Electronics', 'Wiring', 'Unit', 65.00, 23, 800, 1100, 1000, TRUE, NULL),
(117, 'Machined Aluminum Block', 'Metals', 'Aluminum', 'Unit', 125.00, 1, 400, 520, 600, TRUE, NULL),
(118, 'Silicone Sealant (10L)', 'Chemicals', 'Sealants', 'Container', 56.00, 20, 150, 200, 250, FALSE, 365),
(119, 'Spring Steel Wire 2mm', 'Metals', 'Steel', 'Coil', 32.00, 22, 1000, 1800, 1500, FALSE, NULL),
(120, 'Injection Mold Plastic (ABS)', 'Polymers', 'Plastics', 'Bag', 38.00, 11, 1200, 3000, 2000, FALSE, NULL),
(121, 'Flex Circuit Assembly', 'Electronics', 'Circuit Board', 'Unit', 42.00, 19, 2000, 1500, 3000, TRUE, NULL),
(122, 'Hardwood Composite Panel', 'Composites', 'Wood', 'Sheet', 65.00, 18, 300, 450, 500, FALSE, NULL),
(123, 'Lithium Battery Cell 18650', 'Electronics', 'Power', 'Unit', 4.50, 14, 10000, 8500, 15000, TRUE, NULL),
(124, 'Anodizing Chemical Bath', 'Chemicals', 'Surface Treatment', 'Drum', 280.00, 7, 30, 42, 50, FALSE, 180),
(125, 'Precision Ground Glass Lens', 'Optics', 'Lenses', 'Unit', 185.00, 6, 200, 310, 300, TRUE, NULL),
(126, 'Heat Shrink Tubing (100m)', 'Electronics', 'Insulation', 'Roll', 22.00, 23, 500, 650, 800, FALSE, NULL),
(127, 'Magnesium Alloy Ingot', 'Metals', 'Magnesium', 'Ingot', 195.00, 15, 150, 120, 200, FALSE, NULL),
(128, 'Polyurethane Foam Sheet', 'Polymers', 'Foam', 'Sheet', 28.00, 21, 600, 400, 800, FALSE, 545),
(129, 'Tungsten Carbide Insert', 'Metals', 'Tooling', 'Unit', 55.00, 22, 500, 780, 600, TRUE, NULL),
(130, 'EMI Shielding Tape (50m)', 'Electronics', 'Shielding', 'Roll', 38.00, 10, 400, 290, 500, FALSE, NULL),
(131, 'Stainless Steel Welding Rod', 'Metals', 'Steel', 'Pack', 45.00, 16, 800, 1100, 1000, FALSE, NULL),
(132, 'Industrial Lubricant (5L)', 'Chemicals', 'Lubricants', 'Container', 42.00, 20, 400, 550, 500, FALSE, 365),
(133, 'Optical Fiber Cable (1km)', 'Electronics', 'Fiber Optics', 'Spool', 320.00, 14, 50, 65, 80, TRUE, NULL),
(134, 'Zinc Die Cast Housing', 'Metals', 'Zinc', 'Unit', 18.00, 4, 3000, 2100, 4000, FALSE, NULL),
(135, 'Aramid Fiber Sheet', 'Composites', 'Kevlar', 'Sheet', 175.00, 5, 150, 200, 250, TRUE, NULL),
(136, 'Semiconductor Chip (ARM)', 'Electronics', 'ICs', 'Unit', 8.50, 14, 8000, 6200, 10000, TRUE, NULL),
(137, 'Viton O-Ring Kit', 'Polymers', 'Seals', 'Kit', 24.00, 8, 2000, 3200, 3000, FALSE, 730),
(138, 'Powder Coating Material', 'Chemicals', 'Coatings', 'Bag', 65.00, 25, 200, 280, 300, FALSE, 365),
(139, 'Precision Ball Screw', 'Mechanical', 'Motion', 'Unit', 340.00, 6, 80, 55, 100, TRUE, NULL),
(140, 'Conformal Coating (5L)', 'Chemicals', 'Coatings', 'Container', 125.00, 20, 100, 130, 150, FALSE, 180);

-- PRODUCTION_ORDERS: Manufacturing work orders
CREATE OR REPLACE TABLE PRODUCTION_ORDERS (
    ORDER_ID NUMBER PRIMARY KEY,
    PRODUCT_NAME VARCHAR(150),
    PRODUCT_CATEGORY VARCHAR(50),
    PLANT_ID NUMBER REFERENCES PLANT_LOCATIONS(PLANT_ID),
    PRIMARY_MATERIAL_ID NUMBER REFERENCES RAW_MATERIALS(MATERIAL_ID),
    QUANTITY_ORDERED NUMBER,
    QUANTITY_PRODUCED NUMBER,
    ORDER_DATE DATE,
    START_DATE DATE,
    TARGET_COMPLETION DATE,
    ACTUAL_COMPLETION DATE,
    STATUS VARCHAR(30),
    YIELD_PCT FLOAT,
    DEFECT_COUNT NUMBER,
    UNIT_PRODUCTION_COST FLOAT,
    TOTAL_COST FLOAT,
    PRIORITY VARCHAR(20)
);

INSERT INTO PRODUCTION_ORDERS VALUES
(5001, 'Precision Motor Housing', 'Automotive', 2, 117, 2000, 1920, '2025-01-05', '2025-01-08', '2025-01-20', '2025-01-19', 'Completed', 96.0, 12, 45.50, 91000.00, 'High'),
(5002, 'Circuit Board Assembly X1', 'Electronics', 5, 108, 10000, 9850, '2025-01-06', '2025-01-09', '2025-01-15', '2025-01-14', 'Completed', 98.5, 45, 22.00, 220000.00, 'High'),
(5003, 'Carbon Fiber Drone Frame', 'Aerospace', 4, 103, 500, 485, '2025-01-08', '2025-01-12', '2025-01-25', '2025-01-27', 'Completed', 97.0, 3, 180.00, 90000.00, 'Medium'),
(5004, 'Hydraulic Valve Body', 'Industrial', 2, 102, 3000, 2850, '2025-01-10', '2025-01-13', '2025-01-22', '2025-01-24', 'Completed', 95.0, 28, 35.00, 105000.00, 'Medium'),
(5005, 'LED Panel Module', 'Electronics', 5, 109, 8000, 7680, '2025-01-12', '2025-01-14', '2025-01-20', '2025-01-20', 'Completed', 96.0, 120, 15.00, 120000.00, 'High'),
(5006, 'Titanium Surgical Implant', 'Medical', 4, 106, 200, 192, '2025-01-15', '2025-01-18', '2025-02-01', '2025-01-31', 'Completed', 96.0, 0, 890.00, 178000.00, 'Critical'),
(5007, 'Automotive Bearing Set', 'Automotive', 1, 110, 15000, 14250, '2025-01-18', '2025-01-20', '2025-01-28', '2025-01-29', 'Completed', 95.0, 85, 12.00, 180000.00, 'High'),
(5008, 'Industrial Robot Arm Joint', 'Industrial', 2, 139, 400, 380, '2025-01-20', '2025-01-23', '2025-02-05', '2025-02-08', 'Completed', 95.0, 5, 520.00, 208000.00, 'High'),
(5009, 'Flexible PCB Assembly', 'Electronics', 3, 121, 20000, 18800, '2025-01-22', '2025-01-25', '2025-02-03', '2025-02-02', 'Completed', 94.0, 380, 8.50, 170000.00, 'Medium'),
(5010, 'Composite Panel (Aircraft)', 'Aerospace', 4, 135, 100, 98, '2025-01-25', '2025-01-28', '2025-02-15', '2025-02-14', 'Completed', 98.0, 0, 1200.00, 120000.00, 'Critical'),
(5011, 'Battery Pack Module', 'Electronics', 5, 123, 5000, 4650, '2025-02-01', '2025-02-03', '2025-02-10', '2025-02-12', 'Completed', 93.0, 95, 48.00, 240000.00, 'High'),
(5012, 'Precision Optical Assembly', 'Optics', 4, 125, 300, 291, '2025-02-03', '2025-02-06', '2025-02-20', '2025-02-19', 'Completed', 97.0, 2, 450.00, 135000.00, 'High'),
(5013, 'Injection Molded Housing', 'Consumer', 3, 120, 25000, 24250, '2025-02-05', '2025-02-07', '2025-02-14', '2025-02-13', 'Completed', 97.0, 180, 3.80, 95000.00, 'Medium'),
(5014, 'Wiring Harness (EV)', 'Automotive', 1, 116, 3000, 2790, '2025-02-08', '2025-02-10', '2025-02-18', '2025-02-20', 'Completed', 93.0, 42, 85.00, 255000.00, 'High'),
(5015, 'Steel Frame Weldment', 'Industrial', 6, 131, 1500, 1455, '2025-02-10', '2025-02-12', '2025-02-22', '2025-02-21', 'Completed', 97.0, 8, 65.00, 97500.00, 'Medium'),
(5016, 'Semiconductor Module', 'Electronics', 5, 136, 50000, 46000, '2025-02-12', '2025-02-14', '2025-02-20', '2025-02-22', 'Completed', 92.0, 850, 5.20, 260000.00, 'Critical'),
(5017, 'Magnesium Laptop Shell', 'Consumer', 5, 127, 8000, 7760, '2025-02-15', '2025-02-17', '2025-02-25', '2025-02-24', 'Completed', 97.0, 55, 28.00, 224000.00, 'Medium'),
(5018, 'Ceramic Heat Shield', 'Aerospace', 4, 113, 150, 142, '2025-02-18', '2025-02-21', '2025-03-05', '2025-03-07', 'Completed', 94.7, 1, 780.00, 117000.00, 'Critical'),
(5019, 'Pneumatic Actuator', 'Industrial', 2, 107, 2500, 2400, '2025-02-20', '2025-02-22', '2025-03-02', '2025-03-01', 'Completed', 96.0, 15, 42.00, 105000.00, 'Medium'),
(5020, 'Power Distribution Board', 'Electronics', 3, 108, 12000, 11520, '2025-02-22', '2025-02-24', '2025-03-03', '2025-03-04', 'Completed', 96.0, 200, 18.00, 216000.00, 'High'),
(5021, 'Fiber Optic Connector', 'Telecom', 5, 133, 30000, 28200, '2025-02-25', '2025-02-27', '2025-03-05', '2025-03-06', 'Completed', 94.0, 520, 6.50, 195000.00, 'High'),
(5022, 'CNC Machined Turbine Blade', 'Aerospace', 4, 102, 80, 78, '2025-03-01', '2025-03-04', '2025-03-20', '2025-03-18', 'Completed', 97.5, 0, 2800.00, 224000.00, 'Critical'),
(5023, 'EV Motor Stator Assembly', 'Automotive', 1, 104, 1200, 1128, '2025-03-03', '2025-03-05', '2025-03-15', '2025-03-17', 'Completed', 94.0, 18, 195.00, 234000.00, 'High'),
(5024, 'Industrial Sensor Module', 'Industrial', 3, 130, 6000, 5820, '2025-03-05', '2025-03-07', '2025-03-14', '2025-03-13', 'Completed', 97.0, 65, 32.00, 192000.00, 'Medium'),
(5025, 'Aluminum Extrusion Profile', 'Construction', 6, 101, 5000, 4900, '2025-03-08', '2025-03-10', '2025-03-18', '2025-03-17', 'Completed', 98.0, 10, 22.00, 110000.00, 'Low'),
(5026, 'Medical Device Enclosure', 'Medical', 4, 112, 800, 776, '2025-03-10', '2025-03-13', '2025-03-25', '2025-03-24', 'Completed', 97.0, 3, 165.00, 132000.00, 'High'),
(5027, 'High-Freq Antenna Array', 'Telecom', 5, 108, 4000, 3720, '2025-03-12', '2025-03-14', '2025-03-21', '2025-03-23', 'Completed', 93.0, 110, 55.00, 220000.00, 'High'),
(5028, 'Rubber Seal Assembly', 'Automotive', 3, 137, 40000, 39200, '2025-03-15', '2025-03-17', '2025-03-24', '2025-03-23', 'Completed', 98.0, 150, 2.50, 100000.00, 'Medium'),
(5029, 'Precision Gear Set', 'Industrial', 2, 119, 1800, 1710, '2025-03-18', '2025-03-20', '2025-03-30', '2025-04-01', 'Completed', 95.0, 12, 78.00, 140400.00, 'High'),
(5030, 'Smart Display Module', 'Consumer', 5, 109, 15000, 14400, '2025-03-20', '2025-03-22', '2025-03-30', '2025-03-29', 'Completed', 96.0, 210, 35.00, 525000.00, 'Medium'),
(5031, 'Aerospace Hydraulic Fitting', 'Aerospace', 2, 106, 600, 582, '2025-03-22', '2025-03-25', '2025-04-05', '2025-04-04', 'Completed', 97.0, 2, 320.00, 192000.00, 'Critical'),
(5032, 'Solar Panel Frame', 'Energy', 6, 101, 3000, 2940, '2025-03-25', '2025-03-27', '2025-04-05', '2025-04-04', 'Completed', 98.0, 8, 45.00, 135000.00, 'Medium'),
(5033, 'Automotive ECU Board', 'Automotive', 5, 136, 20000, 18600, '2025-03-28', '2025-03-30', '2025-04-07', '2025-04-09', 'Completed', 93.0, 420, 28.00, 560000.00, 'High'),
(5034, 'Polymer Insulation Sheet', 'Industrial', 3, 128, 10000, 9800, '2025-04-01', '2025-04-03', '2025-04-10', '2025-04-09', 'Completed', 98.0, 30, 8.00, 80000.00, 'Low'),
(5035, 'Precision Linear Guide', 'Industrial', 4, 139, 500, 480, '2025-04-03', '2025-04-06', '2025-04-18', '2025-04-20', 'Completed', 96.0, 4, 280.00, 140000.00, 'High'),
(5036, 'Conformal Coated PCB', 'Electronics', 3, 140, 8000, 7680, '2025-04-05', '2025-04-07', '2025-04-14', '2025-04-15', 'Completed', 96.0, 95, 14.00, 112000.00, 'Medium'),
(5037, 'Titanium Hip Implant', 'Medical', 4, 106, 100, 98, '2025-04-08', '2025-04-11', '2025-04-28', '2025-04-27', 'Completed', 98.0, 0, 1850.00, 185000.00, 'Critical'),
(5038, 'Die Cast Motor Mount', 'Automotive', 6, 134, 8000, 7440, '2025-04-10', '2025-04-12', '2025-04-20', '2025-04-22', 'Completed', 93.0, 120, 12.00, 96000.00, 'Medium'),
(5039, 'Fiber Reinforced Panel', 'Construction', 1, 135, 2000, 1960, '2025-04-12', '2025-04-14', '2025-04-22', '2025-04-21', 'Completed', 98.0, 5, 95.00, 190000.00, 'Medium'),
(5040, '5G Antenna Module', 'Telecom', 5, 108, 25000, 23250, '2025-04-15', '2025-04-17', '2025-04-24', '2025-04-26', 'Completed', 93.0, 580, 18.00, 450000.00, 'High'),
(5041, 'Industrial Pump Impeller', 'Industrial', 2, 102, 1000, 970, '2025-04-18', '2025-04-21', '2025-04-30', '2025-04-29', 'Completed', 97.0, 8, 125.00, 125000.00, 'Medium'),
(5042, 'EV Battery Casing', 'Automotive', 1, 101, 4000, 3800, '2025-04-20', '2025-04-22', '2025-05-01', '2025-05-03', 'Completed', 95.0, 35, 68.00, 272000.00, 'High'),
(5043, 'Micro-LED Display Panel', 'Electronics', 5, 109, 6000, 5520, '2025-04-22', '2025-04-24', '2025-05-02', '2025-05-04', 'Completed', 92.0, 180, 82.00, 492000.00, 'High'),
(5044, 'Aerospace Fastener Kit', 'Aerospace', 4, 114, 5000, 4900, '2025-04-25', '2025-04-28', '2025-05-06', '2025-05-05', 'Completed', 98.0, 10, 28.00, 140000.00, 'Medium'),
(5045, 'Smart Thermostat Housing', 'Consumer', 3, 120, 20000, 19400, '2025-04-28', '2025-04-30', '2025-05-07', '2025-05-06', 'Completed', 97.0, 120, 4.50, 90000.00, 'Low'),
(5046, 'High-Voltage Connector', 'Automotive', 1, 104, 6000, 5580, '2025-05-01', '2025-05-03', '2025-05-12', '2025-05-14', 'Completed', 93.0, 78, 42.00, 252000.00, 'High'),
(5047, 'Surgical Robot Arm Link', 'Medical', 4, 106, 50, 49, '2025-05-03', '2025-05-07', '2025-05-25', '2025-05-23', 'Completed', 98.0, 0, 4500.00, 225000.00, 'Critical'),
(5048, 'Industrial Valve Actuator', 'Industrial', 2, 119, 2000, 1900, '2025-05-05', '2025-05-07', '2025-05-16', '2025-05-18', 'Completed', 95.0, 18, 55.00, 110000.00, 'Medium'),
(5049, 'Automotive Sensor Array', 'Automotive', 5, 136, 30000, 27900, '2025-05-08', '2025-05-10', '2025-05-18', '2025-05-20', 'Completed', 93.0, 650, 12.50, 375000.00, 'High'),
(5050, 'Composite Wind Blade Tip', 'Energy', 4, 103, 50, 48, '2025-05-10', '2025-05-14', '2025-06-01', '2025-05-30', 'Completed', 96.0, 1, 8500.00, 425000.00, 'Critical'),
-- In-progress and pending orders
(5051, 'Next-Gen Battery Module', 'Automotive', 1, 123, 8000, 5200, '2025-05-15', '2025-05-18', '2025-06-01', NULL, 'In Progress', NULL, NULL, 52.00, NULL, 'High'),
(5052, 'Quantum Sensor Assembly', 'Aerospace', 4, 125, 30, 0, '2025-05-20', '2025-05-25', '2025-06-20', NULL, 'In Progress', NULL, NULL, 12000.00, NULL, 'Critical'),
(5053, 'Industrial IoT Gateway', 'Electronics', 3, 108, 5000, 2800, '2025-05-22', '2025-05-24', '2025-06-05', NULL, 'In Progress', NULL, NULL, 45.00, NULL, 'Medium'),
(5054, 'EV Charging Connector', 'Automotive', 6, 104, 10000, 0, '2025-05-28', NULL, '2025-06-15', NULL, 'Pending', NULL, NULL, 35.00, NULL, 'High'),
(5055, 'Satellite Comm Module', 'Aerospace', 5, 133, 200, 0, '2025-06-01', NULL, '2025-06-25', NULL, 'Pending', NULL, NULL, 2200.00, NULL, 'Critical');

-- MACHINE_TELEMETRY: IoT sensor data (semi-structured VARIANT payload)
CREATE OR REPLACE TABLE MACHINE_TELEMETRY (
    TELEMETRY_ID NUMBER PRIMARY KEY,
    MACHINE_ID VARCHAR(20),
    MACHINE_NAME VARCHAR(100),
    PLANT_ID NUMBER REFERENCES PLANT_LOCATIONS(PLANT_ID),
    READING_TIMESTAMP TIMESTAMP_NTZ,
    SENSOR_PAYLOAD VARIANT
);

-- Generate telemetry data
INSERT INTO MACHINE_TELEMETRY
SELECT
    ROW_NUMBER() OVER (ORDER BY SEQ8()) AS TELEMETRY_ID,
    'MCH-' || LPAD(MOD(SEQ8(), 20) + 1, 3, '0') AS MACHINE_ID,
    CASE MOD(SEQ8(), 20)
        WHEN 0 THEN 'CNC Mill A1' WHEN 1 THEN 'CNC Mill A2' WHEN 2 THEN 'Lathe B1'
        WHEN 3 THEN 'Lathe B2' WHEN 4 THEN 'Press C1' WHEN 5 THEN 'Press C2'
        WHEN 6 THEN 'Robot Welder D1' WHEN 7 THEN 'Robot Welder D2' WHEN 8 THEN 'Injection Mold E1'
        WHEN 9 THEN 'Injection Mold E2' WHEN 10 THEN 'SMT Line F1' WHEN 11 THEN 'SMT Line F2'
        WHEN 12 THEN 'Heat Treat G1' WHEN 13 THEN 'Paint Booth H1' WHEN 14 THEN 'Assembly Line J1'
        WHEN 15 THEN 'Assembly Line J2' WHEN 16 THEN 'Packaging K1' WHEN 17 THEN 'Testing L1'
        WHEN 18 THEN 'Grinding M1' WHEN 19 THEN 'Cutting N1'
    END AS MACHINE_NAME,
    MOD(SEQ8(), 6) + 1 AS PLANT_ID,
    DATEADD('minute', -SEQ8() * 15, '2025-06-01 00:00:00'::TIMESTAMP) AS READING_TIMESTAMP,
    OBJECT_CONSTRUCT(
        'temperature_c', ROUND(UNIFORM(35, 95, RANDOM())::FLOAT, 1),
        'vibration_mm_s', ROUND(UNIFORM(0.1, 12.5, RANDOM())::FLOAT, 2),
        'rpm', UNIFORM(800, 5000, RANDOM()),
        'power_kw', ROUND(UNIFORM(2.0, 45.0, RANDOM())::FLOAT, 1),
        'status', CASE WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN 'normal'
                       WHEN UNIFORM(0, 100, RANDOM()) < 95 THEN 'warning'
                       ELSE 'critical' END,
        'alert', CASE WHEN UNIFORM(0, 100, RANDOM()) > 90 THEN TRUE ELSE FALSE END,
        'coolant_level_pct', UNIFORM(20, 100, RANDOM()),
        'cycle_time_sec', ROUND(UNIFORM(12.0, 180.0, RANDOM())::FLOAT, 1)
    ) AS SENSOR_PAYLOAD
FROM TABLE(GENERATOR(ROWCOUNT => 200));

-- =============================================================================
-- UNSTRUCTURED DATA TABLES
-- =============================================================================

-- SUPPLIER_COMMUNICATIONS: Email-style correspondence
CREATE OR REPLACE TABLE SUPPLIER_COMMUNICATIONS (
    COMM_ID NUMBER PRIMARY KEY,
    SUPPLIER_ID NUMBER REFERENCES SUPPLIERS_DIM(SUPPLIER_ID),
    SUPPLIER_NAME VARCHAR(100),
    SENDER VARCHAR(150),
    SUBJECT VARCHAR(200),
    EMAIL_BODY VARCHAR(5000),
    DATE_SENT DATE,
    PRIORITY VARCHAR(20),
    CATEGORY VARCHAR(50)
);

INSERT INTO SUPPLIER_COMMUNICATIONS VALUES
(1, 4, 'Shenzhen QuickParts', 'w.zhang@quickparts.cn', 'Urgent: Production Delay Notification', 'Dear Procurement Team, We regret to inform you that due to unexpected equipment failure at our Shenzhen facility, production of PCB substrate orders has been delayed by approximately 14 days. The issue affects batch numbers QP-2025-0456 through QP-2025-0462. We are expediting repairs and will provide updated delivery estimates by end of week. We sincerely apologize for any inconvenience. Best regards, Wei Zhang', '2025-03-15', 'High', 'Delay Notice'),
(2, 6, 'Nippon Steel Solutions', 'y.tanaka@nipponsteelsol.jp', 'Q2 Price Adjustment Notice', 'Dear Valued Customer, Please be advised that effective April 1, 2025, we will implement a 4.2% price adjustment across all stainless steel and specialty alloy product lines. This adjustment reflects increased raw material costs (nickel +8%, chromium +5%) and elevated energy prices in Japan. Existing purchase orders placed before March 15 will be honored at current pricing. We remain committed to maintaining our industry-leading quality standards. Please contact us to discuss volume commitments that may qualify for preferential pricing. Regards, Yuki Tanaka, Sales Director', '2025-02-28', 'Medium', 'Price Change'),
(3, 12, 'Jiangsu Fasteners Ltd', 'c.wei@jiangsufast.cn', 'Force Majeure: Flood Damage to Warehouse', 'URGENT NOTICE - To all customers of Jiangsu Fasteners Ltd. We are declaring force majeure due to severe flooding that has impacted our primary warehouse and secondary production facility in Jiangsu province. Estimated 40% of finished goods inventory has been damaged. All pending shipments are suspended until further notice. We are working with our insurance provider and expect to resume limited operations within 3-4 weeks. We will prioritize orders based on criticality. Please respond with urgency levels for your outstanding orders. Chen Wei, Operations Director', '2025-04-02', 'Critical', 'Force Majeure'),
(4, 2, 'Rhine Valley Precision', 'k.mueller@rhineprecision.de', 'ISO 14001 Recertification Completed', 'Dear Partners, We are pleased to inform you that Rhine Valley Precision has successfully completed our ISO 14001:2015 recertification audit. The audit, conducted by TUV Rheinland, confirmed our continued compliance with all environmental management standards. Additionally, we have achieved a 15% reduction in carbon emissions per unit produced compared to 2023 baseline. Updated certificates are available on our supplier portal. Best regards, Klaus Mueller', '2025-03-20', 'Low', 'Certification'),
(5, 8, 'Brazilian Rubber Co', 'c.silva@brazrubber.com.br', 'Raw Material Shortage - Natural Rubber', 'Dear Customer, Due to prolonged drought conditions affecting rubber plantations in Para state, we are experiencing a 30% reduction in raw natural rubber supply. This will impact our ability to fulfill orders at full capacity for the next 2-3 months. We are exploring alternative sourcing from Malaysia and Indonesia but expect a temporary 12% price increase on all natural rubber products. Synthetic rubber alternatives remain unaffected. Please let us know if you can accept synthetic substitutes for your current orders. Carlos Silva', '2025-02-10', 'High', 'Supply Shortage'),
(6, 1, 'Pacific Metals Corp', 'j.chen@pacificmetals.com', 'New Aluminum Alloy Grade Available', 'Hi Team, Excited to announce that we now offer 7075-T7 aluminum alloy in sheet and plate form. This grade provides superior fatigue resistance compared to 6061-T6, making it ideal for aerospace and high-stress automotive applications. Tensile strength: 505 MPa, Yield: 435 MPa. We have initial stock available for sampling. Lead time for production orders: 8-10 days. Let me know if you would like test samples or technical datasheets. Best, James Chen', '2025-04-05', 'Low', 'New Product'),
(7, 10, 'Dongguan Electronics', 'l.ming@dgelectronics.cn', 'Quality Issue - Batch Recall', 'IMPORTANT QUALITY NOTICE - Batch DGE-2025-1123 of LED Module Arrays shipped on March 1 has been found to contain a solder defect affecting approximately 8% of units. The defect may cause intermittent connection failure after 500+ hours of operation. We are issuing a voluntary recall for all units from this batch. Replacement units will be shipped at no cost within 5 business days. Please isolate any remaining inventory from this batch and provide your RMA requirements. Li Ming, Quality Manager', '2025-03-25', 'Critical', 'Quality Issue'),
(8, 5, 'Great Lakes Composites', 'sarah.j@greatlakescomp.com', 'Capacity Expansion Announcement', 'Dear Valued Partners, We are thrilled to announce a $45M investment in a new production facility in Grand Rapids, MI. This expansion will increase our carbon fiber and advanced composite production capacity by 60%. Expected operational date: Q4 2025. Benefits for existing customers include shorter lead times (targeting 3-day turnaround), dedicated production lines for high-volume orders, and enhanced R&D capabilities for custom formulations. We will maintain our current pricing structure through 2026. Sarah Johnson, VP Sales', '2025-01-15', 'Low', 'Capacity Update'),
(9, 19, 'Shanghai Circuit Board', 'z.yun@shcircuit.cn', 'Payment Terms Dispute', 'Dear Accounts Payable, We note that invoices SCB-2025-0891 and SCB-2025-0905 (total value $142,000) are now 45 days past due. Per our contract terms (Net 60), these are approaching critical overdue status. Our credit department has flagged your account for review. Please remit payment within 10 business days or contact us to discuss an arrangement. Failure to resolve may result in shipment holds on pending orders PO-7721 and PO-7734. Zhao Yun, Finance Department', '2025-04-20', 'High', 'Payment Issue'),
(10, 14, 'Korean Semiconductor Co', 'js.park@koreansemi.kr', 'Allocation Notice - Semiconductor Chips', 'Dear Customer, Due to unprecedented demand for ARM-based processing units and limited foundry capacity, we are implementing allocation controls effective immediately. Your quarterly allocation has been set at 85% of your average order volume from the past 4 quarters. Orders exceeding allocation will be placed on backorder with estimated lead time of 16-20 weeks. We recommend placing Q3 orders as early as possible to secure allocation. Priority allocation may be available for customers willing to commit to annual volume agreements. Park Ji-Sung', '2025-03-01', 'High', 'Allocation'),
(11, 15, 'Atlas Mining & Minerals', 'a.hassan@atlasmining.ae', 'Customs Clearance Delay - UAE Export', 'Dear Logistics Team, Shipment ATL-2025-0334 containing 15 pallets of magnesium alloy ingots is currently held at Jebel Ali port due to updated export documentation requirements from UAE customs authority. We need the following documents resubmitted: 1) Updated end-use certificate, 2) Material composition declaration with EU REACH compliance statement, 3) Insurance certificate with Incoterms 2020 references. Expected delay: 5-7 business days once documents are provided. Ahmed Hassan', '2025-04-12', 'Medium', 'Logistics'),
(12, 3, 'Tata Advanced Materials', 'p.sharma@tataadv.in', 'Partnership Renewal Discussion', 'Dear Procurement Director, As we approach the renewal date for our supply agreement (August 2026), I would like to schedule a strategic review meeting. Key discussion points: 1) Volume commitments for 2026-2028, 2) New materials in our pipeline (graphene composites, bio-based polymers), 3) Dedicated inventory program for your critical items, 4) Joint quality improvement initiatives. We value our partnership and are prepared to offer enhanced terms for multi-year commitments. Available for a call next week. Priya Sharma', '2025-05-01', 'Medium', 'Contract'),
(13, 4, 'Shenzhen QuickParts', 'w.zhang@quickparts.cn', 'Update: Production Resumption', 'Dear Customer, Follow-up to our March 15 delay notification. We have completed equipment repairs and resumed full production as of March 28. All delayed orders (QP-2025-0456 through QP-2025-0462) will ship by April 5. We have implemented additional preventive maintenance schedules to avoid recurrence. However, we are still experiencing 20% capacity reduction on our secondary line. New orders may see extended lead times of 22-25 days (vs normal 18 days) through end of April. Wei Zhang', '2025-03-29', 'Medium', 'Delay Update'),
(14, 9, 'Nordic Alloys AB', 'e.lindqvist@nordicalloys.se', 'Sustainability Report & Carbon Credits', 'Dear Partner, Attached is our 2024 Sustainability Report. Key highlights: We have achieved carbon neutrality for Scope 1 & 2 emissions. Our copper wire products now carry verified Environmental Product Declarations (EPDs). For customers tracking Scope 3 emissions, we can provide per-shipment carbon footprint data. Additionally, we offer carbon offset credits at preferential rates for long-term contract holders. This may be relevant for your ESG reporting requirements. Erik Lindqvist', '2025-02-20', 'Low', 'Sustainability'),
(15, 17, 'Vietnam Precision Mfg', 'n.thi@vnprecision.vn', 'Worker Strike - Partial Shutdown', 'NOTICE: Operations at our Ho Chi Minh City facility have been partially disrupted due to a labor dispute. Approximately 40% of our workforce is participating in a work stoppage. Production lines 3, 4, and 7 are currently idle. Lines 1, 2, 5, and 6 continue at reduced capacity. We expect resolution within 1-2 weeks pending negotiations with worker representatives. Orders with ship dates after May 15 should not be affected. Earlier commitments may slip 5-7 days. We will provide daily status updates. Nguyen Thi', '2025-04-28', 'High', 'Disruption'),
(16, 20, 'Finnish Specialty Chemicals', 'm.virtanen@finchemicals.fi', 'REACH Compliance Update', 'Dear Compliance Team, Per EU REACH regulation updates effective June 2025, we are reformulating our industrial lubricant and hydraulic fluid product lines to eliminate PFAS compounds. New formulations have passed all performance benchmarks in independent testing. Transition timeline: Current PFAS-containing inventory available through May 31. New PFAS-free products ship from June 1. No price change. Updated Safety Data Sheets (SDS) attached. Please update your internal compliance records. Mika Virtanen', '2025-04-15', 'Medium', 'Compliance'),
(17, 21, 'Sao Paulo Plastics', 'a.costa@spplastics.com.br', 'Shipping Container Shortage - Port Congestion', 'Dear Logistics Team, We are experiencing significant delays in container availability at Port of Santos. Current wait time for 40ft containers is 18-22 days (normally 5-7 days). This affects all pending shipments to North America and Europe. Alternative routing via Port of Paranagua adds $1,200 per container but reduces wait to 8-10 days. Please advise your preference for outstanding orders SP-4521 and SP-4523: 1) Wait for Santos availability, 2) Reroute via Paranagua at additional cost, 3) Air freight for urgent items (quote available). Ana Costa', '2025-03-10', 'High', 'Logistics'),
(18, 22, 'Czech Precision Tools', 't.novak@czechtools.cz', 'New Tungsten Carbide Grades', 'Dear Engineering Team, We have developed two new tungsten carbide grades optimized for your applications: Grade TC-450: 15% improved wear resistance for high-speed cutting (ideal for your aerospace machining operations). Grade TC-620: Enhanced thermal stability for continuous heavy-duty operations above 800C. Both grades are compatible with your existing tool holder systems. Trial quantities available immediately. Full production lead time: 9 days. Volume pricing starts at 1000+ units. Technical specifications and test data enclosed. Tomas Novak', '2025-05-10', 'Low', 'New Product'),
(19, 11, 'Texas Polymer Solutions', 'm.rodriguez@texaspolymer.com', 'Hurricane Season Preparedness Notice', 'Dear Customers, As we approach the 2025 Atlantic hurricane season, we want to assure you of our business continuity preparations. Our Houston facility has been fortified with: upgraded flood barriers, 72-hour backup power generation, redundant raw material supply from our Oklahoma warehouse, and pre-positioned emergency response teams. We recommend customers in hurricane-prone regions consider building 2-3 weeks additional safety stock during June-November. We can offer favorable extended storage terms. Mike Rodriguez', '2025-05-20', 'Low', 'Business Continuity'),
(20, 4, 'Shenzhen QuickParts', 'w.zhang@quickparts.cn', 'Price Increase Effective June 1', 'Dear Valued Customer, Due to rising copper and rare earth mineral costs (copper +15% YTD, neodymium +22% YTD), we must implement a price increase of 8% across all electronic component product lines effective June 1, 2025. PCB substrates, LED modules, and semiconductor packaging are affected. Orders confirmed before May 25 will honor current pricing for shipments through June 30. We understand this is unwelcome news and are available to discuss volume discount arrangements or alternative specifications that may reduce costs. Wei Zhang, Commercial Director', '2025-05-12', 'High', 'Price Change'),
(21, 13, 'Midlands Castings UK', 'd.thompson@midlandscast.co.uk', 'Brexit Customs Update - New Requirements', 'Dear Import Team, Please note updated UK customs requirements effective May 2025 for all exports to EU destinations: 1) Carbon Border Adjustment Mechanism (CBAM) declarations now required for steel and aluminum castings, 2) New digital customs forms (CDS system) replacing legacy CHIEF system, 3) Rules of Origin certificates required for preferential tariff treatment. Our logistics team can assist with documentation. Lead times for EU-bound shipments may increase by 2-3 days during transition. David Thompson', '2025-04-25', 'Medium', 'Compliance'),
(22, 7, 'EuroChemicals AG', 'h.weber@eurochemicals.eu', 'Product Discontinuation Notice', 'Dear Customer, Effective September 1, 2025, we will discontinue production of our EC-7700 series thermal paste due to regulatory restrictions on one of its key ingredients under SVHC (Substances of Very High Concern) classification. Recommended replacement: EC-8800 series - superior thermal conductivity (12.5 W/mK vs 9.8 W/mK), fully REACH compliant, same application method. Final orders for EC-7700 must be placed by July 15. Free samples of EC-8800 available for qualification testing. Hans Weber, Product Management', '2025-05-15', 'Medium', 'Product Change'),
(23, 6, 'Nippon Steel Solutions', 'y.tanaka@nipponsteelsol.jp', 'Earthquake Impact Assessment', 'URGENT UPDATE - Following the M6.2 earthquake in Ishikawa Prefecture on May 18, we are assessing impact to our Kanazawa secondary processing facility. Preliminary findings: Minor structural damage to Building C (grinding/polishing operations). No injuries reported. Primary Osaka facility is fully operational and unaffected. Products potentially impacted: precision ground rods and polished plates. Standard stainless steel products ship normally. We expect Building C to resume within 2 weeks. Yuki Tanaka', '2025-05-19', 'High', 'Disruption'),
(24, 16, 'Monterrey Steel Works', 'j.hernandez@montsteel.mx', 'USMCA Compliance Certification', 'Dear Trade Compliance Team, We have completed our annual USMCA (United States-Mexico-Canada Agreement) origin verification audit. All steel products manufactured at our Monterrey facility qualify for preferential duty treatment under USMCA rules of origin. Certificate of Origin numbers for 2025: MSW-USMCA-2025-001 through MSW-USMCA-2025-015. These cover all product categories currently shipped to your US and Canadian facilities. Please file with your customs broker. Juan Hernandez', '2025-03-05', 'Low', 'Compliance'),
(25, 10, 'Dongguan Electronics', 'l.ming@dgelectronics.cn', 'Corrective Action Report - LED Batch Issue', 'Dear Quality Team, Following our March 25 recall notice for batch DGE-2025-1123, we have completed root cause analysis. Findings: Solder paste viscosity was out of spec due to expired lot of flux activator used on March 1 production run. Corrective actions implemented: 1) Real-time viscosity monitoring on all paste dispensers, 2) Automated lot expiry tracking system, 3) Additional QC hold point before reflow. PPAP documents and updated control plans attached. Li Ming, Quality Director', '2025-04-08', 'Medium', 'Quality Issue');

-- Add more supplier communications (26-50)
INSERT INTO SUPPLIER_COMMUNICATIONS VALUES
(26, 23, 'Bangalore Tech Components', 'r.kumar@blrtech.in', 'Capacity Constraint - Wiring Harness', 'Dear Procurement, Our Bangalore facility is running at 95% capacity utilization on wiring harness lines. Current lead time has extended to 14 days (from standard 12). We recommend placing orders 3 weeks in advance for the remainder of Q2. Our Chennai satellite facility can absorb overflow orders but at 5% premium. Let us know if you want to split orders across facilities. Rajesh Kumar', '2025-04-18', 'Medium', 'Capacity'),
(27, 24, 'Ohio Industrial Bearings', 'l.williams@ohiobearings.com', 'Annual Price Lock Offer', 'Dear Purchasing Team, As a preferred customer, we are offering annual price lock agreements for 2025-2026. Lock in current pricing with minimum quarterly volume commitments of 5,000 units. This protects you from anticipated 6-8% market price increases expected in H2 2025 due to steel tariff uncertainties. Offer valid until June 15. Lisa Williams, Account Manager', '2025-05-25', 'Medium', 'Pricing'),
(28, 5, 'Great Lakes Composites', 'sarah.j@greatlakescomp.com', 'Technical Advisory - Carbon Fiber Storage', 'Dear Quality/Warehouse Teams, Important storage advisory for carbon fiber panels (product codes GLC-CF-2mm, GLC-CF-3mm, GLC-CF-5mm): Recent testing indicates that storage above 35C and 70% humidity for extended periods (>30 days) may cause micro-delamination not detectable by visual inspection. Please ensure climate-controlled storage. Affected inventory should undergo ultrasonic testing before use in aerospace applications. We can provide testing services at no charge. Sarah Johnson', '2025-03-08', 'High', 'Quality Advisory'),
(29, 14, 'Korean Semiconductor Co', 'js.park@koreansemi.kr', 'End-of-Life Notice - ARM Cortex-M4 Variant', 'Dear Product Engineering, This is advance notification that our KSC-ARM-M4-128 chip (ARM Cortex-M4, 128KB Flash) will reach End of Life on December 31, 2025. Last Time Buy deadline: September 30, 2025. Recommended migration: KSC-ARM-M7-256 (pin-compatible, 2x performance, same price point). Migration guide and reference designs available on our developer portal. We recommend qualifying the replacement in your next design cycle. Park Ji-Sung, Product Lifecycle', '2025-05-05', 'Medium', 'EOL Notice'),
(30, 2, 'Rhine Valley Precision', 'k.mueller@rhineprecision.de', 'Joint Innovation Project Proposal', 'Dear Engineering Director, Following our meeting at Hannover Messe, I would like to formally propose a joint development project for next-generation lightweight titanium-aluminum composite fasteners for your aerospace product line. Rhine Valley would invest in dedicated R&D resources and tooling. We estimate 25% weight reduction vs current titanium fasteners with comparable strength. Proposed timeline: 6-month development, 3-month qualification. IP would be jointly owned. Interested in scheduling a technical deep-dive? Klaus Mueller', '2025-04-30', 'Low', 'Innovation'),
(31, 12, 'Jiangsu Fasteners Ltd', 'c.wei@jiangsufast.cn', 'Flood Recovery Update', 'Dear Customers, Update on our force majeure situation: Water has receded and facility cleanup is 70% complete. Limited production resumed on April 20 on lines 1-3. Full capacity expected by May 10. Priority shipments for critical orders begin this week. Your orders JF-9921 and JF-9934 are scheduled for May 5 shipment. We appreciate your patience during this difficult period. New warehouse flood mitigation systems being installed. Chen Wei', '2025-04-22', 'Medium', 'Recovery Update'),
(32, 25, 'Turkish Ceramics International', 'm.yilmaz@turkceramics.com.tr', 'Currency Fluctuation Notice', 'Dear Finance Team, Due to significant Turkish Lira depreciation (18% against USD in Q1), we must revise our USD-denominated pricing. Effective May 1, a 6% surcharge applies to all new orders. This surcharge will be reviewed monthly and adjusted based on TRY/USD exchange rate. Orders with confirmed pricing and delivery dates prior to May 1 are not affected. We are exploring hedging instruments to provide more pricing stability going forward. Mehmet Yilmaz', '2025-04-10', 'Medium', 'Price Change'),
(33, 18, 'Canadian Lumber & Composites', 'r.tremblay@canlumber.ca', 'Wildfire Risk Advisory - Supply Continuity', 'Dear Partners, With the 2025 wildfire season approaching, we want to provide advance notice of our contingency plans. Our primary lumber sourcing regions in British Columbia are classified as moderate-to-high risk this year. Contingency measures: 1) 60-day safety stock built at our Ontario distribution center, 2) Alternative sourcing agreements with Scandinavian suppliers, 3) Real-time supply chain monitoring dashboard available to key accounts. Recommend building 30-day buffer stock for Q3. Robert Tremblay', '2025-05-08', 'Low', 'Risk Advisory'),
(34, 4, 'Shenzhen QuickParts', 'w.zhang@quickparts.cn', 'Quality Audit Findings - Corrective Action Required', 'Dear Quality Assurance, During your recent on-site audit (April 14-16), several non-conformances were identified at our Facility 2: 1) Traceability gaps in solder paste lot tracking (Major NC), 2) Calibration records for 3 AOI machines overdue by 2 weeks (Minor NC), 3) Cleanroom particle count exceeded spec in Zone B (Major NC). We have initiated corrective actions with target closure by May 15. Formal CAPA report will be submitted by May 1. We take these findings seriously. Wei Zhang, Quality Director', '2025-04-18', 'High', 'Quality Issue'),
(35, 9, 'Nordic Alloys AB', 'e.lindqvist@nordicalloys.se', 'New Production Line - Reduced Lead Times', 'Dear Customer, We are pleased to announce our new automated wire drawing line is now operational. Key improvements: Lead time for copper wire products reduced from 10 days to 7 days. Capacity increased by 40%. New capability: ultra-fine gauge wire down to 0.05mm diameter. Quality improvement: ±0.001mm diameter tolerance (previously ±0.003mm). Pricing remains unchanged. Please update your MRP system with new lead times. Erik Lindqvist', '2025-05-18', 'Low', 'Improvement');

-- QUALITY_AUDIT_REPORTS: Free-text quality/inspection reports
CREATE OR REPLACE TABLE QUALITY_AUDIT_REPORTS (
    REPORT_ID NUMBER PRIMARY KEY,
    PLANT_ID NUMBER REFERENCES PLANT_LOCATIONS(PLANT_ID),
    PLANT_NAME VARCHAR(100),
    AUDIT_DATE DATE,
    AUDITOR VARCHAR(100),
    REPORT_TEXT VARCHAR(8000),
    SEVERITY VARCHAR(20),
    CATEGORY VARCHAR(50),
    STATUS VARCHAR(30),
    CORRECTIVE_ACTION_DUE DATE
);

INSERT INTO QUALITY_AUDIT_REPORTS VALUES
(1, 1, 'Austin Assembly Hub', '2025-01-15', 'Maria Santos', 'QUALITY AUDIT REPORT - Austin Assembly Hub\nDate: January 15, 2025\nAuditor: Maria Santos, Lead Quality Engineer\n\nAUDIT SCOPE: Assembly Line J1 - EV Motor Components\n\nFINDINGS:\n1. MAJOR: Torque calibration on Station 7 found 8% above specification. 3 operators affected. Estimated 200 units assembled with over-torqued fasteners since last calibration (Jan 2). Risk: potential stress fractures in housing after thermal cycling.\n2. MINOR: Work instruction WI-J1-042 rev C not posted at Station 3. Operators using memorized procedure (correct) but documentation non-compliant.\n3. OBSERVATION: ESD wrist strap compliance at 92% during spot check (target 100%).\n\nIMMEDIATE ACTIONS:\n- Station 7 torque tools recalibrated and verified\n- Quarantine notice issued for batches B-5007-001 through B-5007-012\n- All 200 potentially affected units recalled for inspection\n\nROOT CAUSE: Calibration schedule gap during holiday shutdown period. Preventive maintenance task was not rescheduled after Christmas closure.\n\nCORRECTIVE ACTION: Implement automated calibration reminder system with escalation. Due: February 15, 2025.', 'Major', 'Calibration', 'Closed', '2025-02-15'),
(2, 5, 'Shenzhen Electronics Plant', '2025-01-22', 'Dr. Li Wei', 'QUALITY AUDIT REPORT - Shenzhen Electronics Plant\nDate: January 22, 2025\nAuditor: Dr. Li Wei, Senior Quality Director\n\nAUDIT SCOPE: SMT Line F1 - PCB Assembly Operations\n\nFINDINGS:\n1. CRITICAL: Solder paste inspection system (SPI) bypass switch found in ON position. Unknown duration. Boards proceeding to reflow without paste volume verification. Potential for open solder joints, bridges, and insufficient joints undetected until final test.\n2. MAJOR: Humidity in component storage room measured at 78% RH (spec max 60% RH). Moisture-sensitive components (MSL-3 and above) potentially compromised. Affects 12 part numbers.\n3. MAJOR: First Article Inspection records missing for 3 new product introductions started this month.\n\nIMMEDIATE ACTIONS:\n- SPI bypass switch locked out, key secured with shift supervisor\n- Component storage dehumidifier emergency repair ordered\n- All MSL-3+ components floor-life reset, baking initiated per J-STD-033\n- Production hold on 3 NPI products pending FAI completion\n\nROOT CAUSE: Night shift supervisor override to meet delivery target. Process discipline breakdown.\n\nSEVERITY ASSESSMENT: Customer escape risk HIGH. Recommend 100% final inspection for all boards produced Jan 20-22.', 'Critical', 'Process Control', 'Open', '2025-02-28'),
(3, 4, 'Stuttgart Precision Works', '2025-02-05', 'Hans Bergmann', 'QUALITY AUDIT REPORT - Stuttgart Precision Works\nDate: February 5, 2025\nAuditor: Hans Bergmann, External Auditor (TUV Rheinland)\n\nAUDIT TYPE: ISO 9001:2015 Surveillance Audit\n\nFINDINGS:\n1. MINOR: Management review minutes from Q4 2024 do not include analysis of customer complaint trends as required by clause 9.3.2(c).\n2. OBSERVATION: Supplier evaluation scoring for 2 suppliers not updated within 12-month cycle (15 months elapsed). Both are low-volume suppliers.\n3. POSITIVE: Excellent implementation of SPC (Statistical Process Control) on CNC operations. Cpk values consistently above 1.67 for critical dimensions.\n4. POSITIVE: Effective CAPA system with 95% on-time closure rate.\n\nCONCLUSION: ISO 9001:2015 certification maintained. No major nonconformances. Minor findings to be addressed within 90 days.\n\nNEXT AUDIT: August 2025 (surveillance), February 2026 (recertification).', 'Minor', 'ISO Audit', 'Closed', '2025-05-05'),
(4, 3, 'Pune Manufacturing Unit', '2025-02-18', 'Anand Krishnan', 'QUALITY AUDIT REPORT - Pune Manufacturing Unit\nDate: February 18, 2025\nAuditor: Anand Krishnan, Process Quality Manager\n\nAUDIT SCOPE: Injection Molding Operations - Lines E1, E2\n\nFINDINGS:\n1. MAJOR: Mold temperature variation on Line E2 exceeding ±3°C tolerance. Causing short shots and flash on 15% of parts. Reject rate at 6.2% (target <2%). Issue traced to failing thermocouple in Zone 3 of mold heater.\n2. MAJOR: Material drying time for Nylon 6/6 reduced from specified 4 hours to 2.5 hours to meet production schedule. Residual moisture causing splay marks and reduced mechanical properties.\n3. MINOR: Raw material certificates of conformance not filed for last 3 deliveries from Texas Polymer Solutions. Material used without formal incoming inspection approval.\n\nIMMEDIATE ACTIONS:\n- Line E2 shut down for thermocouple replacement (4-hour repair)\n- All nylon material currently in dryer extended to full 4-hour cycle\n- Retrospective CoC request sent to Texas Polymer Solutions\n\nIMPACT ASSESSMENT: 850 molded housings from past week require dimensional verification. 12 cartons shipped to Austin Assembly may contain non-conforming parts.\n\nCORRECTIVE ACTION: Install independent temperature monitoring with alarm system. Enforce material preparation SOP with operator sign-off. Due: March 15, 2025.', 'Major', 'Process Control', 'Closed', '2025-03-15'),
(5, 2, 'Detroit Fabrication Center', '2025-03-01', 'Robert Chang', 'QUALITY AUDIT REPORT - Detroit Fabrication Center\nDate: March 1, 2025\nAuditor: Robert Chang, Metallurgical Engineer\n\nAUDIT SCOPE: Welding Operations - Robot Welders D1, D2\n\nFINDINGS:\n1. CRITICAL: Weld porosity detected in 12 of 50 sampled hydraulic valve bodies (24% failure rate). Ultrasonic inspection reveals subsurface voids 2-4mm depth. Parts were marked as passed by visual inspection alone.\n2. MAJOR: Shielding gas flow rate on Robot D2 measured at 12 L/min (specification 15-18 L/min). Low flow allows atmospheric contamination of weld pool. Gas supply regulator found faulty.\n3. MAJOR: Welder D1 wire feed speed drifting ±5% during long production runs due to worn feed roller. Causing inconsistent weld bead profile.\n4. MINOR: Weld procedure specifications (WPS) for titanium welding not signed off by Level 3 weld inspector as required by customer contract.\n\nIMMEDIATE ACTIONS:\n- All hydraulic valve bodies from Feb 15 - Mar 1 quarantined (estimated 450 units)\n- 100% ultrasonic inspection initiated on quarantined batch\n- Gas regulator replaced on D2, wire feed rollers replaced on D1\n- Production halted pending process revalidation\n\nCUSTOMER IMPACT: 180 units already shipped to customer. Containment notification issued. Field inspection team dispatched.\n\nROOT CAUSE ANALYSIS: Preventive maintenance schedule not followed for welding robots. Maintenance backlog at 3 weeks due to staffing shortage.', 'Critical', 'Weld Quality', 'Open', '2025-04-01'),
(6, 6, 'Guadalajara Assembly', '2025-03-12', 'Isabella Reyes', 'QUALITY AUDIT REPORT - Guadalajara Assembly\nDate: March 12, 2025\nAuditor: Isabella Reyes, Quality Assurance Lead\n\nAUDIT SCOPE: Final Assembly & Packaging - Steel Frame Weldments\n\nFINDINGS:\n1. MINOR: 3 of 20 sampled shipping containers had insufficient dunnage, risking transit damage. Container weight within spec but internal packing below standard.\n2. MINOR: Label printer on Line 3 producing faded barcodes. 2 of 10 scanned labels failed verification on first attempt.\n3. OBSERVATION: New operators (hired January) demonstrate excellent workmanship. Training program effectiveness confirmed.\n4. POSITIVE: Zero customer complaints for Guadalajara products in past 90 days.\n5. POSITIVE: 5S audit score improved from 78% to 91% since last quarter.\n\nOVERALL ASSESSMENT: Facility performing well. Minor packaging issues identified for correction. No product quality concerns.\n\nCORRECTIVE ACTION: Update packaging SOP with photo references for dunnage placement. Replace label printer ribbon cartridge (immediate). Due: March 25, 2025.', 'Minor', 'Packaging', 'Closed', '2025-03-25'),
(7, 1, 'Austin Assembly Hub', '2025-03-25', 'Maria Santos', 'QUALITY AUDIT REPORT - Austin Assembly Hub\nDate: March 25, 2025\nAuditor: Maria Santos, Lead Quality Engineer\n\nAUDIT SCOPE: ESD Control Program Verification\n\nFINDINGS:\n1. MAJOR: ESD flooring resistance measurement in Assembly Area B exceeds 1x10^9 ohms (specification max 1x10^9). Floor wax buildup creating insulative layer. Static events possible when handling sensitive components.\n2. MINOR: 4 of 30 ESD wrist straps failed daily verification check. Straps showed physical wear (>6 months old). Operators continued to use failed straps.\n3. MINOR: Ionizer bar on conveyor section 12 not functioning. Last PM record shows service 8 months ago (schedule: quarterly).\n\nRISK ASSESSMENT: Products with static-sensitive components (semiconductor modules, flex circuits) assembled in Area B may have latent ESD damage. No immediate field failures reported but long-term reliability concern.\n\nIMMEDIATE ACTIONS:\n- Emergency floor treatment scheduled for weekend shutdown\n- All worn wrist straps replaced (50 units ordered)\n- Ionizer bar serviced and verified functional\n\nCORRECTIVE ACTION: Implement quarterly ESD program audit with scoring. Add floor resistance to monthly PM checklist. Due: April 15, 2025.', 'Major', 'ESD Control', 'Closed', '2025-04-15'),
(8, 5, 'Shenzhen Electronics Plant', '2025-04-02', 'Dr. Li Wei', 'QUALITY AUDIT REPORT - Shenzhen Electronics Plant\nDate: April 2, 2025\nAuditor: Dr. Li Wei, Senior Quality Director\n\nAUDIT TYPE: Follow-up Audit (ref: January 22 Critical Finding)\n\nVERIFICATION OF CORRECTIVE ACTIONS:\n1. SPI Bypass: VERIFIED EFFECTIVE. Physical lock installed. Key custody log maintained. Bypass requires QA manager approval and documented justification. No unauthorized bypasses since January.\n2. Humidity Control: VERIFIED EFFECTIVE. Dual redundant dehumidifier system installed. Real-time monitoring with SMS alerts at 55% RH (warning) and 58% RH (action). Current reading: 42% RH.\n3. First Article Inspection: PARTIALLY EFFECTIVE. 8 of 10 recent NPIs have complete FAI records. 2 missing final measurement reports (design validation pending from customer). Process improved but not yet 100%.\n\nNEW FINDINGS:\n1. MINOR: Component reel count verification not performed on 2 of 5 incoming deliveries checked. Risk of production line stoppage from short reels.\n\nOVERALL ASSESSMENT: Significant improvement. Critical issues from January resolved. Recommend removing enhanced monitoring after May audit confirms sustained compliance.', 'Minor', 'Follow-up Audit', 'Closed', '2025-04-30'),
(9, 2, 'Detroit Fabrication Center', '2025-04-15', 'Robert Chang', 'QUALITY AUDIT REPORT - Detroit Fabrication Center\nDate: April 15, 2025\nAuditor: Robert Chang, Metallurgical Engineer\n\nAUDIT SCOPE: CNC Machining Operations - Mills A1, A2\n\nFINDINGS:\n1. MAJOR: Tool wear monitoring system on Mill A1 not functioning correctly. Tool life alerts delayed, resulting in 3 instances of machining with worn tools this month. Affected parts: precision motor housings with surface finish Ra 3.2 (spec max Ra 1.6).\n2. MINOR: Coolant concentration on Mill A2 at 4.2% (specification 5-7%). Low concentration may cause reduced tool life and poor surface finish.\n3. OBSERVATION: Chip evacuation on deep pocket milling operations could be improved. Recommend adding through-spindle coolant capability.\n\nIMMEDIATE ACTIONS:\n- Tool wear sensor replacement ordered for Mill A1 (2-day lead time)\n- Coolant concentration adjusted to 6% on Mill A2\n- 45 motor housings from past week require surface finish verification\n\nPRODUCTION IMPACT: Line running at 70% capacity on precision parts until sensor restored. Standard tolerance parts unaffected.', 'Major', 'Tool Management', 'Open', '2025-05-15'),
(10, 3, 'Pune Manufacturing Unit', '2025-04-28', 'Anand Krishnan', 'QUALITY AUDIT REPORT - Pune Manufacturing Unit\nDate: April 28, 2025\nAuditor: Anand Krishnan, Process Quality Manager\n\nAUDIT SCOPE: Incoming Material Inspection\n\nFINDINGS:\n1. MAJOR: Batch of PCB substrates from Shanghai Circuit Board (lot SCB-2025-0412) failed incoming inspection. Dielectric constant measured at 4.8 (specification 4.2-4.6). 5,000 panels received, none usable. Supplier notified, replacement shipment requested.\n2. MINOR: Incoming inspection lab temperature recorded at 28°C on 3 days this month (specification 20-25°C for dimensional measurements). Air conditioning unit requires maintenance.\n3. OBSERVATION: Incoming inspection throughput improved 20% since implementation of automated visual inspection system in February.\n\nSUPPLIER ACTIONS:\n- Formal Supplier Corrective Action Request (SCAR) issued to Shanghai Circuit Board\n- This is 3rd quality escape from this supplier in 12 months\n- Recommendation: Escalate to supplier quality review board for potential disqualification\n\nIMPACT: Production order 5053 (Industrial IoT Gateway) delayed 2 weeks pending replacement material arrival.', 'Major', 'Incoming Inspection', 'Open', '2025-05-30');

-- =============================================================================
-- VERIFY DATA
-- =============================================================================
SELECT 'PLANT_LOCATIONS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM PLANT_LOCATIONS
UNION ALL SELECT 'SUPPLIERS_DIM', COUNT(*) FROM SUPPLIERS_DIM
UNION ALL SELECT 'RAW_MATERIALS', COUNT(*) FROM RAW_MATERIALS
UNION ALL SELECT 'PRODUCTION_ORDERS', COUNT(*) FROM PRODUCTION_ORDERS
UNION ALL SELECT 'MACHINE_TELEMETRY', COUNT(*) FROM MACHINE_TELEMETRY
UNION ALL SELECT 'SUPPLIER_COMMUNICATIONS', COUNT(*) FROM SUPPLIER_COMMUNICATIONS
UNION ALL SELECT 'QUALITY_AUDIT_REPORTS', COUNT(*) FROM QUALITY_AUDIT_REPORTS;
