-- init.sql - Complete Database Schema for Canteen Management System
-- This file will be automatically executed when PostgreSQL container starts

-- Enable UUID extension for better ID generation (optional)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CORE TABLES
-- =====================================================

-- FOO_FOOD_MST: Menu Items Master
CREATE TABLE FOO_FOOD_MST (
    item_id SERIAL PRIMARY KEY,
    item_code VARCHAR(20) UNIQUE NOT NULL, -- Numeric code for quick entry
    item_description VARCHAR(255) NOT NULL,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    in_use BOOLEAN DEFAULT TRUE
);

-- FOO_COST_SHEET: Item Pricing Information
CREATE TABLE FOO_COST_SHEET (
    item_id INTEGER PRIMARY KEY REFERENCES FOO_FOOD_MST(item_id),
    cost DECIMAL(10,2) NOT NULL CHECK (cost > 0),
    is_active BOOLEAN DEFAULT TRUE,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inactive_date TIMESTAMP NULL
);

-- CUST_PERSON_ACC: Customer Master
CREATE TABLE CUST_PERSON_ACC (
    customer_id SERIAL PRIMARY KEY,
    customer_number VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- OM_ORDER_HEADERS: Main Order Table
CREATE TABLE OM_ORDER_HEADERS (
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
CREATE TABLE OM_ORDER_LINES (
    line_id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES OM_ORDER_HEADERS(header_id) ON DELETE CASCADE,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    item_id INTEGER NOT NULL REFERENCES FOO_FOOD_MST(item_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    cost_per_item DECIMAL(10,2) NOT NULL CHECK (cost_per_item > 0),
    total_cost DECIMAL(10,2) GENERATED ALWAYS AS (quantity * cost_per_item) STORED,
    is_served BOOLEAN DEFAULT FALSE,
    served_at TIMESTAMP NULL,
    served_by VARCHAR(255) NULL
);

-- CUST_ORDER_HIST: Customer Order History (for tracking recurring customers)
CREATE TABLE CUST_ORDER_HIST (
    customer_id INTEGER NOT NULL REFERENCES CUST_PERSON_ACC(customer_id),
    payment_id INTEGER, -- Will reference CUST_PAYMENT_HIST
    header_id INTEGER NOT NULL REFERENCES OM_ORDER_HEADERS(header_id),
    line_id INTEGER NOT NULL REFERENCES OM_ORDER_LINES(line_id),
    item_id INTEGER NOT NULL REFERENCES FOO_FOOD_MST(item_id),
    quantity INTEGER NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (customer_id, header_id, line_id)
);

-- CUST_PAYMENT_HIST: Payment Tracking
CREATE TABLE CUST_PAYMENT_HIST (
    payment_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES CUST_PERSON_ACC(customer_id),
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_paid BOOLEAN DEFAULT FALSE,
    payment_date TIMESTAMP NULL,
    payment_amount DECIMAL(10,2) NOT NULL CHECK (payment_amount > 0),
    notes TEXT
);

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE
-- =====================================================

-- Fast lookup by item code (for quick entry)
CREATE INDEX idx_food_mst_item_code ON FOO_FOOD_MST(item_code);
CREATE INDEX idx_food_mst_in_use ON FOO_FOOD_MST(in_use);

-- Customer lookups
CREATE INDEX idx_customer_phone ON CUST_PERSON_ACC(phone);
CREATE INDEX idx_customer_active ON CUST_PERSON_ACC(is_active);

-- Order performance indexes
CREATE INDEX idx_order_headers_date ON OM_ORDER_HEADERS(creation_date);
CREATE INDEX idx_order_headers_customer ON OM_ORDER_HEADERS(customer_id);
CREATE INDEX idx_order_headers_unpaid ON OM_ORDER_HEADERS(is_paid) WHERE is_paid = FALSE;

-- Order lines performance
CREATE INDEX idx_order_lines_header ON OM_ORDER_LINES(header_id);
CREATE INDEX idx_order_lines_unserved ON OM_ORDER_LINES(is_served) WHERE is_served = FALSE;
CREATE INDEX idx_order_lines_item ON OM_ORDER_LINES(item_id);

-- Payment tracking
CREATE INDEX idx_payment_customer ON CUST_PAYMENT_HIST(customer_id);
CREATE INDEX idx_payment_unpaid ON CUST_PAYMENT_HIST(is_paid) WHERE is_paid = FALSE;

-- =====================================================
-- 3. TRIGGERS FOR AUTOMATIC CALCULATIONS
-- =====================================================

-- Function to update order header total when line items change
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the total_due in OM_ORDER_HEADERS
    UPDATE OM_ORDER_HEADERS 
    SET total_due = (
        SELECT COALESCE(SUM(total_cost), 0)
        FROM OM_ORDER_LINES 
        WHERE header_id = COALESCE(NEW.header_id, OLD.header_id)
    )
    WHERE header_id = COALESCE(NEW.header_id, OLD.header_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update order totals
CREATE TRIGGER trigger_update_order_total
    AFTER INSERT OR UPDATE OR DELETE ON OM_ORDER_LINES
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

-- Function to update customer due amount
CREATE OR REPLACE FUNCTION update_customer_due()
RETURNS TRIGGER AS $$
BEGIN
    -- Update customer's total due amount
    IF NEW.customer_id IS NOT NULL THEN
        UPDATE CUST_PERSON_ACC 
        SET total_due = (
            SELECT COALESCE(SUM(total_due), 0)
            FROM OM_ORDER_HEADERS 
            WHERE customer_id = NEW.customer_id 
            AND is_paid = FALSE
        )
        WHERE customer_id = NEW.customer_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add total_due column to CUST_PERSON_ACC if not exists
ALTER TABLE CUST_PERSON_ACC ADD COLUMN IF NOT EXISTS total_due DECIMAL(10,2) DEFAULT 0.00;

-- Trigger to update customer due amounts
CREATE TRIGGER trigger_update_customer_due
    AFTER INSERT OR UPDATE ON OM_ORDER_HEADERS
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_due();

-- Function to populate customer order history
CREATE OR REPLACE FUNCTION populate_customer_history()
RETURNS TRIGGER AS $$
BEGIN
    -- Only populate if it's a known customer
    IF NEW.is_known_customer = TRUE AND NEW.customer_id IS NOT NULL THEN
        INSERT INTO CUST_ORDER_HIST (customer_id, header_id, line_id, item_id, quantity, total_cost)
        SELECT NEW.customer_id, NEW.header_id, ol.line_id, ol.item_id, ol.quantity, ol.total_cost
        FROM OM_ORDER_LINES ol
        WHERE ol.header_id = NEW.header_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to populate customer history
CREATE TRIGGER trigger_populate_customer_history
    AFTER INSERT ON OM_ORDER_HEADERS
    FOR EACH ROW
    EXECUTE FUNCTION populate_customer_history();

-- =====================================================
-- 4. STORED PROCEDURES FOR COMPLEX OPERATIONS
-- =====================================================

-- Create a new order with multiple items
CREATE OR REPLACE FUNCTION create_order_with_items(
    p_customer_id INTEGER DEFAULT NULL,
    p_who_gave_order VARCHAR(255) DEFAULT NULL,
    p_is_deferred BOOLEAN DEFAULT FALSE,
    p_order_items JSONB DEFAULT '[]'::JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_header_id INTEGER;
    v_item JSONB;
    v_cost_per_item DECIMAL(10,2);
BEGIN
    -- Insert order header
    INSERT INTO OM_ORDER_HEADERS (
        customer_id, 
        who_gave_order, 
        is_deferred, 
        is_known_customer
    )
    VALUES (
        p_customer_id,
        p_who_gave_order,
        p_is_deferred,
        (p_customer_id IS NOT NULL)
    )
    RETURNING header_id INTO v_header_id;
    
    -- Insert order lines
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        -- Get current cost for the item
        SELECT cost INTO v_cost_per_item
        FROM FOO_COST_SHEET cs
        JOIN FOO_FOOD_MST fm ON cs.item_id = fm.item_id
        WHERE fm.item_code = (v_item->>'item_code')
        AND cs.is_active = TRUE
        AND fm.in_use = TRUE;
        
        IF v_cost_per_item IS NULL THEN
            RAISE EXCEPTION 'Item with code % not found or inactive', (v_item->>'item_code');
        END IF;
        
        -- Insert order line
        INSERT INTO OM_ORDER_LINES (header_id, item_id, quantity, cost_per_item)
        SELECT v_header_id, fm.item_id, (v_item->>'quantity')::INTEGER, v_cost_per_item
        FROM FOO_FOOD_MST fm
        WHERE fm.item_code = (v_item->>'item_code');
    END LOOP;
    
    RETURN v_header_id;
END;
$$ LANGUAGE plpgsql;

-- Mark order items as served
CREATE OR REPLACE FUNCTION mark_items_served(
    p_line_ids INTEGER[],
    p_served_by VARCHAR(255) DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE OM_ORDER_LINES 
    SET 
        is_served = TRUE,
        served_at = CURRENT_TIMESTAMP,
        served_by = p_served_by
    WHERE line_id = ANY(p_line_ids)
    AND is_served = FALSE;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Process payment for customer
CREATE OR REPLACE FUNCTION process_customer_payment(
    p_customer_id INTEGER,
    p_payment_amount DECIMAL(10,2),
    p_order_ids INTEGER[] DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_payment_id INTEGER;
    v_remaining_amount DECIMAL(10,2) := p_payment_amount;
    v_order_id INTEGER;
BEGIN
    -- Insert payment record
    INSERT INTO CUST_PAYMENT_HIST (customer_id, payment_amount, payment_date, is_paid)
    VALUES (p_customer_id, p_payment_amount, CURRENT_TIMESTAMP, TRUE)
    RETURNING payment_id INTO v_payment_id;
    
    -- If specific orders mentioned, mark them as paid
    IF p_order_ids IS NOT NULL THEN
        FOR v_order_id IN SELECT unnest(p_order_ids)
        LOOP
            UPDATE OM_ORDER_HEADERS 
            SET is_paid = TRUE 
            WHERE header_id = v_order_id 
            AND customer_id = p_customer_id
            AND is_paid = FALSE;
        END LOOP;
    ELSE
        -- Auto-pay oldest unpaid orders
        FOR v_order_id IN 
            SELECT header_id 
            FROM OM_ORDER_HEADERS 
            WHERE customer_id = p_customer_id 
            AND is_paid = FALSE 
            ORDER BY creation_date ASC
        LOOP
            EXIT WHEN v_remaining_amount <= 0;
            
            UPDATE OM_ORDER_HEADERS 
            SET is_paid = TRUE 
            WHERE header_id = v_order_id;
            
            v_remaining_amount := v_remaining_amount - (
                SELECT total_due FROM OM_ORDER_HEADERS WHERE header_id = v_order_id
            );
        END LOOP;
    END IF;
    
    RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. VIEWS FOR COMMON QUERIES
-- =====================================================

-- Active menu with current prices
CREATE VIEW v_active_menu AS
SELECT 
    fm.item_id,
    fm.item_code,
    fm.item_description,
    cs.cost,
    fm.creation_date
FROM FOO_FOOD_MST fm
JOIN FOO_COST_SHEET cs ON fm.item_id = cs.item_id
WHERE fm.in_use = TRUE AND cs.is_active = TRUE;

-- Pending orders (unserved items)
CREATE VIEW v_pending_orders AS
SELECT 
    oh.header_id,
    oh.creation_date,
    oh.who_gave_order,
    oh.customer_id,
    c.name AS customer_name,
    ol.line_id,
    fm.item_code,
    fm.item_description,
    ol.quantity,
    ol.cost_per_item,
    ol.total_cost,
    oh.is_paid
FROM OM_ORDER_HEADERS oh
JOIN OM_ORDER_LINES ol ON oh.header_id = ol.header_id
JOIN FOO_FOOD_MST fm ON ol.item_id = fm.item_id
LEFT JOIN CUST_PERSON_ACC c ON oh.customer_id = c.customer_id
WHERE ol.is_served = FALSE
ORDER BY oh.creation_date ASC, ol.line_id ASC;

-- Customer dues summary
CREATE VIEW v_customer_dues AS
SELECT 
    c.customer_id,
    c.customer_number,
    c.name,
    c.phone,
    COUNT(oh.header_id) AS unpaid_orders,
    COALESCE(SUM(oh.total_due), 0) AS total_due_amount
FROM CUST_PERSON_ACC c
LEFT JOIN OM_ORDER_HEADERS oh ON c.customer_id = oh.customer_id AND oh.is_paid = FALSE
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.customer_number, c.name, c.phone
HAVING COUNT(oh.header_id) > 0 OR COALESCE(SUM(oh.total_due), 0) > 0;

-- =====================================================
-- 6. SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert sample menu items
INSERT INTO FOO_FOOD_MST (item_code, item_description) VALUES
('1', 'Tea'),
('2', 'Coffee'),
('3', 'Samosa'),
('4', 'Sandwich'),
('5', 'Biscuits'),
('6', 'Cold Drink'),
('7', 'Dal Rice'),
('8', 'Roti Sabji'),
('9', 'Paratha'),
('10', 'Lassi');

-- Insert pricing for menu items
INSERT INTO FOO_COST_SHEET (item_id, cost) VALUES
(1, 10.00),  -- Tea
(2, 15.00),  -- Coffee
(3, 20.00),  -- Samosa
(4, 35.00),  -- Sandwich
(5, 10.00),  -- Biscuits
(6, 25.00),  -- Cold Drink
(7, 60.00),  -- Dal Rice
(8, 50.00),  -- Roti Sabji
(9, 25.00),  -- Paratha
(10, 30.00); -- Lassi

-- Insert sample customers
INSERT INTO CUST_PERSON_ACC (customer_number, name, phone) VALUES
('CUST001', 'Rajesh Kumar', '9876543210'),
('CUST002', 'Priya Sharma', '9876543211'),
('CUST003', 'Amit Singh', '9876543212');

-- =====================================================
-- 7. USEFUL QUERY FUNCTIONS
-- =====================================================

-- Get unserved orders for display screen
CREATE OR REPLACE FUNCTION get_unserved_orders()
RETURNS TABLE (
    header_id INTEGER,
    order_time TIMESTAMP,
    customer_name VARCHAR(255),
    item_code VARCHAR(20),
    item_name VARCHAR(255),
    quantity INTEGER,
    line_id INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oh.header_id,
        oh.creation_date,
        COALESCE(c.name, 'Walk-in Customer'),
        fm.item_code,
        fm.item_description,
        ol.quantity,
        ol.line_id
    FROM OM_ORDER_HEADERS oh
    JOIN OM_ORDER_LINES ol ON oh.header_id = ol.header_id
    JOIN FOO_FOOD_MST fm ON ol.item_id = fm.item_id
    LEFT JOIN CUST_PERSON_ACC c ON oh.customer_id = c.customer_id
    WHERE ol.is_served = FALSE
    ORDER BY oh.creation_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Get customer order summary
CREATE OR REPLACE FUNCTION get_customer_summary(p_customer_id INTEGER)
RETURNS TABLE (
    total_orders BIGINT,
    total_amount DECIMAL(10,2),
    pending_amount DECIMAL(10,2),
    last_order_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(oh.total_due), 0) as total_amount,
        COALESCE(SUM(CASE WHEN oh.is_paid = FALSE THEN oh.total_due ELSE 0 END), 0) as pending_amount,
        MAX(oh.creation_date) as last_order_date
    FROM OM_ORDER_HEADERS oh
    WHERE oh.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (adjust as needed for your setup)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO apps;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO apps;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO apps;