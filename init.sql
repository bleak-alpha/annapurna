-- init.sql - Complete Database Schema for Canteen Management System
-- This file will be automatically executed when PostgreSQL container starts

-- Enable UUID extension for better ID generation (optional)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CORE TABLES
-- =====================================================

-- FOO_FOOD_MST: Menu Items Master
CREATE TABLE IF NOT EXISTS FOO_FOOD_MST (
    item_id SERIAL PRIMARY KEY,
    item_code VARCHAR(20) UNIQUE NOT NULL, -- Numeric code for quick entry
    item_description VARCHAR(255) NOT NULL,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    in_use BOOLEAN DEFAULT TRUE
);

-- FOO_COST_SHEET: Item Pricing Information
CREATE TABLE IF NOT EXISTS FOO_COST_SHEET (
    item_id INTEGER PRIMARY KEY REFERENCES FOO_FOOD_MST(item_id),
    cost DECIMAL(10,2) NOT NULL CHECK (cost > 0),
    is_active BOOLEAN DEFAULT TRUE,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inactive_date TIMESTAMP NULL
);

-- CUST_PERSON_ACC: Customer Master
CREATE TABLE IF NOT EXISTS CUST_PERSON_ACC (
    customer_id SERIAL PRIMARY KEY,
    customer_number VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    total_due DECIMAL(10,2) DEFAULT 0.00
);

-- OM_ORDER_HEADERS: Main Order Table
CREATE TABLE IF NOT EXISTS OM_ORDER_HEADERS (
    header_id SERIAL PRIMARY KEY,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    who_gave_order VARCHAR(255), -- Staff member who took the order
    when_ordered TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_paid BOOLEAN DEFAULT FALSE,
    is_deferred BOOLEAN DEFAULT FALSE, -- Payment deferred flag
    is_known_customer BOOLEAN DEFAULT FALSE,
    customer_id INTEGER REFERENCES CUST_PERSON_ACC(customer_id),
    total_due DECIMAL(10,2) DEFAULT 0.00
);

-- OM_ORDER_LINES: Order Line Items
CREATE TABLE IF NOT EXISTS OM_ORDER_LINES (
    line_id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES OM_ORDER_HEADERS(header_id) ON DELETE CASCADE,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    item_id INTEGER NOT NULL REFERENCES FOO_FOOD_MST(item_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    cost_per_item DECIMAL(10,2) NOT NULL CHECK (cost_per_item > 0),
    total_cost DECIMAL(10,2) DEFAULT 0.00,
    is_served BOOLEAN DEFAULT FALSE,
    served_at TIMESTAMP NULL,
    served_by VARCHAR(255) NULL
);

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE (only create if not exists)
-- =====================================================

-- Fast lookup by item code (for quick entry)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_food_mst_item_code') THEN
        CREATE INDEX idx_food_mst_item_code ON FOO_FOOD_MST(item_code);
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_food_mst_in_use') THEN
        CREATE INDEX idx_food_mst_in_use ON FOO_FOOD_MST(in_use);
    END IF;
END $$;

-- Customer lookups
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_customer_phone') THEN
        CREATE INDEX idx_customer_phone ON CUST_PERSON_ACC(phone);
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_customer_active') THEN
        CREATE INDEX idx_customer_active ON CUST_PERSON_ACC(is_active);
    END IF;
END $$;

-- Order performance indexes
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_order_headers_date') THEN
        CREATE INDEX idx_order_headers_date ON OM_ORDER_HEADERS(creation_date);
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_order_headers_customer') THEN
        CREATE INDEX idx_order_headers_customer ON OM_ORDER_HEADERS(customer_id);
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_order_headers_unpaid') THEN
        CREATE INDEX idx_order_headers_unpaid ON OM_ORDER_HEADERS(is_paid) WHERE is_paid = FALSE;
    END IF;
END $$;

-- Order lines performance
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_order_lines_header') THEN
        CREATE INDEX idx_order_lines_header ON OM_ORDER_LINES(header_id);
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_order_lines_unserved') THEN
        CREATE INDEX idx_order_lines_unserved ON OM_ORDER_LINES(is_served) WHERE is_served = FALSE;
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_order_lines_item') THEN
        CREATE INDEX idx_order_lines_item ON OM_ORDER_LINES(item_id);
    END IF;
END $$;

-- =====================================================
-- 3. SAMPLE DATA FOR TESTING (only insert if not exists)
-- =====================================================

-- Insert sample menu items (only if table is empty)
INSERT INTO FOO_FOOD_MST (item_code, item_description) 
SELECT * FROM (VALUES
    ('1', 'Tea'),
    ('2', 'Coffee'),
    ('3', 'Samosa'),
    ('4', 'Sandwich'),
    ('5', 'Biscuits'),
    ('6', 'Cold Drink'),
    ('7', 'Dal Rice'),
    ('8', 'Roti Sabji'),
    ('9', 'Paratha'),
    ('10', 'Lassi')
) AS v(item_code, item_description)
WHERE NOT EXISTS (SELECT 1 FROM FOO_FOOD_MST);

-- Insert pricing for menu items (only if cost sheet is empty)
INSERT INTO FOO_COST_SHEET (item_id, cost) 
SELECT fm.item_id, v.cost
FROM FOO_FOOD_MST fm
JOIN (VALUES
    ('1', 10.00),  -- Tea
    ('2', 15.00),  -- Coffee
    ('3', 20.00),  -- Samosa
    ('4', 35.00),  -- Sandwich
    ('5', 10.00),  -- Biscuits
    ('6', 25.00),  -- Cold Drink
    ('7', 60.00),  -- Dal Rice
    ('8', 50.00),  -- Roti Sabji
    ('9', 25.00),  -- Paratha
    ('10', 30.00)  -- Lassi
) AS v(item_code, cost) ON fm.item_code = v.item_code
WHERE NOT EXISTS (SELECT 1 FROM FOO_COST_SHEET);

-- Insert sample customers (only if customer table is empty)
INSERT INTO CUST_PERSON_ACC (customer_number, name, phone) 
SELECT * FROM (VALUES
    ('CUST001', 'Rajesh Kumar', '9876543210'),
    ('CUST002', 'Priya Sharma', '9876543211'),
    ('CUST003', 'Amit Singh', '9876543212')
) AS v(customer_number, name, phone)
WHERE NOT EXISTS (SELECT 1 FROM CUST_PERSON_ACC);

-- Create a simple function to calculate total cost for order lines
CREATE OR REPLACE FUNCTION calculate_line_total()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_cost = NEW.quantity * NEW.cost_per_item;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for calculating line totals
DROP TRIGGER IF EXISTS trigger_calculate_line_total ON OM_ORDER_LINES;
CREATE TRIGGER trigger_calculate_line_total
    BEFORE INSERT OR UPDATE ON OM_ORDER_LINES
    FOR EACH ROW
    EXECUTE FUNCTION calculate_line_total();

-- Grant permissions (adjust as needed for your setup)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${DB_USER};