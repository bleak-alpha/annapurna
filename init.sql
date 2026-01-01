CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- SEQUENCES
-- =====================================================

-- Sequence for order headers (5-7 digits, starting at 10000)
CREATE SEQUENCE IF NOT EXISTS om_order_headers_seq
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    MAXVALUE 9999999
    NO CYCLE;

-- Sequence for payment history (6-9 digits, starting at 100000)
CREATE SEQUENCE IF NOT EXISTS cust_payment_hist_seq
    START WITH 100000
    INCREMENT BY 1
    MINVALUE 100000
    MAXVALUE 999999999
    NO CYCLE;

-- =====================================================
-- CORE TABLES
-- =====================================================

-- FOO_FOOD_MST: Menu Items Master
CREATE TABLE IF NOT EXISTS FOO_FOOD_MST (
    item_id SERIAL PRIMARY KEY,
    item_code VARCHAR(20) UNIQUE NOT NULL,
    item_number INTEGER UNIQUE NOT NULL,
    item_description VARCHAR(255) NOT NULL,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    in_use BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_item_number CHECK (item_number >= 1000 AND item_number <= 5999)
);

COMMENT ON COLUMN FOO_FOOD_MST.item_number IS '4-digit code: 1st=category(1-5), 2nd=type(1-2), 3rd-4th=item(00-99)';

-- FOO_COST_SHEET: Item Pricing with History
CREATE TABLE IF NOT EXISTS FOO_COST_SHEET (
    cost_id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES FOO_FOOD_MST(item_id),
    cost DECIMAL(10,2) NOT NULL CHECK (cost > 0),
    is_active BOOLEAN DEFAULT TRUE,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inactive_date TIMESTAMP NULL
);

-- Unique partial index: only one active cost per item
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_cost_per_item 
ON FOO_COST_SHEET (item_id) WHERE is_active = TRUE;

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

-- OM_ORDER_HEADERS: Order Headers
CREATE TABLE IF NOT EXISTS OM_ORDER_HEADERS (
    header_id INTEGER PRIMARY KEY DEFAULT nextval('om_order_headers_seq'),
    order_number BIGINT UNIQUE,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    who_gave_order VARCHAR(255),
    when_ordered TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_paid_full BOOLEAN DEFAULT FALSE,
    is_deferred BOOLEAN DEFAULT NULL,
    is_known_customer BOOLEAN DEFAULT FALSE,
    customer_id INTEGER REFERENCES CUST_PERSON_ACC(customer_id),
    total_due DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT chk_payment_deferred CHECK (
        (is_paid_full = TRUE AND is_deferred = FALSE) OR 
        (is_paid_full = FALSE AND is_deferred = TRUE) OR
        (is_paid_full IS NULL OR is_deferred IS NULL)
    ),
    CONSTRAINT chk_walk_in_payment CHECK (
        (customer_id IS NULL AND is_known_customer = FALSE AND 
         (is_deferred IS NULL OR is_deferred = FALSE) AND is_paid_full = TRUE) OR
        (customer_id IS NOT NULL)
    )
);

COMMENT ON COLUMN OM_ORDER_HEADERS.order_number IS 'Format: YYMMDD + 3-digit sequence (e.g., 251006001)';

-- OM_ORDER_LINES: Order Line Items
CREATE TABLE IF NOT EXISTS OM_ORDER_LINES (
    line_id SERIAL PRIMARY KEY,
    header_id INTEGER NOT NULL REFERENCES OM_ORDER_HEADERS(header_id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    item_id INTEGER NOT NULL REFERENCES FOO_FOOD_MST(item_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    cost_per_item DECIMAL(10,2) NOT NULL CHECK (cost_per_item > 0),
    total_cost DECIMAL(10,2) DEFAULT 0.00,
    is_paid BOOLEAN DEFAULT FALSE,
    is_served BOOLEAN DEFAULT FALSE,
    served_at TIMESTAMP NULL,
    served_by VARCHAR(255) NULL,
    CONSTRAINT uq_header_line UNIQUE (header_id, line_number)
);

-- CUST_PAYMENT_HIST: Payment History
CREATE TABLE IF NOT EXISTS CUST_PAYMENT_HIST (
    payment_id INTEGER PRIMARY KEY DEFAULT nextval('cust_payment_hist_seq'),
    customer_id INTEGER NOT NULL REFERENCES CUST_PERSON_ACC(customer_id),
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_date TIMESTAMP,
    payment_mode VARCHAR(20) CHECK (payment_mode IN ('CASH', 'ONLINE')),
    amount_paid DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0)
);

-- CUST_ORDER_HIST: Customer Order History (Links customers to order lines)
CREATE TABLE IF NOT EXISTS CUST_ORDER_HIST (
    hist_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES CUST_PERSON_ACC(customer_id),
    line_id INTEGER NOT NULL REFERENCES OM_ORDER_LINES(line_id),
    is_paid_now BOOLEAN DEFAULT FALSE,
    payment_id INTEGER REFERENCES CUST_PAYMENT_HIST(payment_id),
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_line UNIQUE (customer_id, line_id)
);

-- =====================================================
-- TRIGGERS AND FUNCTIONS
-- =====================================================

-- 1. Auto-deactivate old cost sheets when new one is added
CREATE OR REPLACE FUNCTION deactivate_old_cost_sheets()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_active = TRUE THEN
        UPDATE FOO_COST_SHEET
        SET is_active = FALSE,
            inactive_date = CURRENT_TIMESTAMP
        WHERE item_id = NEW.item_id 
          AND is_active = TRUE 
          AND cost_id != COALESCE(NEW.cost_id, -1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_deactivate_old_cost_sheets ON FOO_COST_SHEET;
CREATE TRIGGER trigger_deactivate_old_cost_sheets
    BEFORE INSERT OR UPDATE ON FOO_COST_SHEET
    FOR EACH ROW
    WHEN (NEW.is_active = TRUE)
    EXECUTE FUNCTION deactivate_old_cost_sheets();

-- 2. Generate order_number (YYMMDD + 3-digit sequence)
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    date_prefix VARCHAR(6);
    sequence_num INTEGER;
    new_order_number BIGINT;
BEGIN
    date_prefix := TO_CHAR(NEW.creation_date, 'YYMMDD');
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number::TEXT FROM 7) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM OM_ORDER_HEADERS
    WHERE TO_CHAR(creation_date, 'YYMMDD') = date_prefix;
    
    IF sequence_num > 999 THEN
        RAISE EXCEPTION 'Daily order limit (999) exceeded for date %', date_prefix;
    END IF;
    
    new_order_number := (date_prefix || LPAD(sequence_num::TEXT, 3, '0'))::BIGINT;
    NEW.order_number := new_order_number;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_order_number ON OM_ORDER_HEADERS;
CREATE TRIGGER trigger_generate_order_number
    BEFORE INSERT ON OM_ORDER_HEADERS
    FOR EACH ROW
    EXECUTE FUNCTION generate_order_number();

-- 3. Auto-increment line_number per header_id
CREATE OR REPLACE FUNCTION generate_line_number()
RETURNS TRIGGER AS $$
DECLARE
    next_line_num INTEGER;
BEGIN
    SELECT COALESCE(MAX(line_number), 0) + 1
    INTO next_line_num
    FROM OM_ORDER_LINES
    WHERE header_id = NEW.header_id;
    
    NEW.line_number := next_line_num;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_line_number ON OM_ORDER_LINES;
CREATE TRIGGER trigger_generate_line_number
    BEFORE INSERT ON OM_ORDER_LINES
    FOR EACH ROW
    WHEN (NEW.line_number IS NULL)
    EXECUTE FUNCTION generate_line_number();

-- 4. Calculate line total cost
CREATE OR REPLACE FUNCTION calculate_line_total()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_cost = NEW.quantity * NEW.cost_per_item;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_line_total ON OM_ORDER_LINES;
CREATE TRIGGER trigger_calculate_line_total
    BEFORE INSERT OR UPDATE ON OM_ORDER_LINES
    FOR EACH ROW
    EXECUTE FUNCTION calculate_line_total();

-- 5. Validate order can only be marked fully paid if all lines are paid
CREATE OR REPLACE FUNCTION validate_order_payment()
RETURNS TRIGGER AS $$
DECLARE
    unpaid_lines INTEGER;
BEGIN
    IF NEW.is_paid_full = TRUE THEN
        SELECT COUNT(*)
        INTO unpaid_lines
        FROM OM_ORDER_LINES
        WHERE header_id = NEW.header_id AND is_paid = FALSE;
        
        IF unpaid_lines > 0 THEN
            RAISE EXCEPTION 'Cannot mark order as fully paid: % unpaid line(s) exist', unpaid_lines;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_order_payment ON OM_ORDER_HEADERS;
CREATE TRIGGER trigger_validate_order_payment
    BEFORE UPDATE ON OM_ORDER_HEADERS
    FOR EACH ROW
    WHEN (NEW.is_paid_full = TRUE AND OLD.is_paid_full = FALSE)
    EXECUTE FUNCTION validate_order_payment();

-- 6. Prevent manual payment_id insertion
CREATE OR REPLACE FUNCTION prevent_manual_payment_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Payment_id should only come from sequence
    IF TG_OP = 'INSERT' AND NEW.payment_id IS NOT NULL THEN
        -- Check if it's from the sequence
        IF NEW.payment_id != currval('cust_payment_hist_seq') THEN
            RAISE EXCEPTION 'Cannot manually set payment_id. It must be auto-generated.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_prevent_manual_payment_id ON CUST_PAYMENT_HIST;
CREATE TRIGGER trigger_prevent_manual_payment_id
    BEFORE INSERT ON CUST_PAYMENT_HIST
    FOR EACH ROW
    EXECUTE FUNCTION prevent_manual_payment_id();

-- 7. Update order history and mark lines as paid when payment is recorded
CREATE OR REPLACE FUNCTION update_order_hist_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- Update CUST_ORDER_HIST with payment_id and mark as paid
    UPDATE CUST_ORDER_HIST
    SET payment_id = NEW.payment_id,
        is_paid_now = TRUE
    WHERE customer_id = NEW.customer_id 
      AND is_paid_now = FALSE;
    
    -- Mark corresponding order lines as paid
    UPDATE OM_ORDER_LINES ol
    SET is_paid = TRUE
    FROM OM_ORDER_HEADERS oh, CUST_ORDER_HIST coh
    WHERE ol.line_id = coh.line_id
      AND ol.header_id = oh.header_id
      AND coh.customer_id = NEW.customer_id
      AND coh.payment_id = NEW.payment_id;
    
    -- Update customer total due
    UPDATE CUST_PERSON_ACC
    SET total_due = GREATEST(total_due - NEW.amount_paid, 0)
    WHERE customer_id = NEW.customer_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_order_hist_on_payment ON CUST_PAYMENT_HIST;
CREATE TRIGGER trigger_update_order_hist_on_payment
    AFTER INSERT ON CUST_PAYMENT_HIST
    FOR EACH ROW
    EXECUTE FUNCTION update_order_hist_on_payment();

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_food_mst_item_code ON FOO_FOOD_MST(item_code);
CREATE INDEX IF NOT EXISTS idx_food_mst_item_number ON FOO_FOOD_MST(item_number);
CREATE INDEX IF NOT EXISTS idx_food_mst_in_use ON FOO_FOOD_MST(in_use) WHERE in_use = TRUE;

CREATE INDEX IF NOT EXISTS idx_cost_sheet_item ON FOO_COST_SHEET(item_id);
CREATE INDEX IF NOT EXISTS idx_cost_sheet_active ON FOO_COST_SHEET(is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_customer_phone ON CUST_PERSON_ACC(phone);
CREATE INDEX IF NOT EXISTS idx_customer_active ON CUST_PERSON_ACC(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_dues ON CUST_PERSON_ACC(total_due) WHERE total_due > 0;

CREATE INDEX IF NOT EXISTS idx_order_headers_date ON OM_ORDER_HEADERS(creation_date);
CREATE INDEX IF NOT EXISTS idx_order_headers_order_number ON OM_ORDER_HEADERS(order_number);
CREATE INDEX IF NOT EXISTS idx_order_headers_customer ON OM_ORDER_HEADERS(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_headers_unpaid ON OM_ORDER_HEADERS(is_paid_full) WHERE is_paid_full = FALSE;

CREATE INDEX IF NOT EXISTS idx_order_lines_header ON OM_ORDER_LINES(header_id);
CREATE INDEX IF NOT EXISTS idx_order_lines_unserved ON OM_ORDER_LINES(is_served) WHERE is_served = FALSE;
CREATE INDEX IF NOT EXISTS idx_order_lines_unpaid ON OM_ORDER_LINES(is_paid) WHERE is_paid = FALSE;
CREATE INDEX IF NOT EXISTS idx_order_lines_item ON OM_ORDER_LINES(item_id);

CREATE INDEX IF NOT EXISTS idx_cust_order_hist_customer ON CUST_ORDER_HIST(customer_id);
CREATE INDEX IF NOT EXISTS idx_cust_order_hist_line ON CUST_ORDER_HIST(line_id);
CREATE INDEX IF NOT EXISTS idx_cust_order_hist_payment ON CUST_ORDER_HIST(payment_id);
CREATE INDEX IF NOT EXISTS idx_cust_order_hist_unpaid ON CUST_ORDER_HIST(is_paid_now) WHERE is_paid_now = FALSE;

CREATE INDEX IF NOT EXISTS idx_cust_payment_hist_customer ON CUST_PAYMENT_HIST(customer_id);
CREATE INDEX IF NOT EXISTS idx_cust_payment_hist_date ON CUST_PAYMENT_HIST(creation_date);

-- =====================================================
-- SAMPLE DATA
-- =====================================================

INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description) 
SELECT * FROM (VALUES
    -- Breakfast (1xxx): Veg (11xx), Non-Veg (12xx)
    ('B01', 1101, 'Idli'),
    ('B02', 1102, 'Dosa'),
    ('B03', 1103, 'Poha'),
    ('B04', 1104, 'Upma'),
    ('B05', 1105, 'Paratha'),
    ('B06', 1201, 'Egg Omelette'),
    
    -- Lunch (2xxx): Veg (21xx), Non-Veg (22xx)
    ('L01', 2101, 'Dal Rice'),
    ('L02', 2102, 'Roti Sabji'),
    ('L03', 2103, 'Chole Bhature'),
    ('L04', 2104, 'Paneer Curry'),
    ('L05', 2201, 'Chicken Biryani'),
    ('L06', 2202, 'Chicken Tikka'),
    ('L07', 2203, 'Fish Curry'),
    
    -- Snacks (3xxx): Veg (31xx), Non-Veg (32xx)
    ('S01', 3101, 'Samosa'),
    ('S02', 3102, 'Sandwich'),
    ('S03', 3103, 'Pakora'),
    ('S04', 3104, 'Biscuits'),
    ('S05', 3201, 'Chicken Roll'),
    
    -- Beverages (4xxx): All Veg (41xx)
    ('BV01', 4101, 'Tea'),
    ('BV02', 4102, 'Coffee'),
    ('BV03', 4103, 'Cold Drink'),
    ('BV04', 4104, 'Lassi'),
    ('BV05', 4105, 'Juice'),
    
    -- Desserts (5xxx): All Veg (51xx)
    ('D01', 5101, 'Gulab Jamun'),
    ('D02', 5102, 'Ice Cream'),
    ('D03', 5103, 'Kheer')
) AS v(item_code, item_number, item_description)
WHERE NOT EXISTS (SELECT 1 FROM FOO_FOOD_MST);

INSERT INTO FOO_COST_SHEET (item_id, cost) 
SELECT fm.item_id, v.cost
FROM FOO_FOOD_MST fm
JOIN (VALUES
    ('B01', 30.00), ('B02', 40.00), ('B03', 35.00), ('B04', 30.00), ('B05', 40.00), ('B06', 50.00),
    ('L01', 60.00), ('L02', 50.00), ('L03', 80.00), ('L04', 120.00), 
    ('L05', 180.00), ('L06', 150.00), ('L07', 140.00),
    ('S01', 20.00), ('S02', 40.00), ('S03', 25.00), ('S04', 10.00), ('S05', 60.00),
    ('BV01', 10.00), ('BV02', 15.00), ('BV03', 25.00), ('BV04', 30.00), ('BV05', 35.00),
    ('D01', 40.00), ('D02', 50.00), ('D03', 45.00)
) AS v(item_code, cost) ON fm.item_code = v.item_code
WHERE NOT EXISTS (SELECT 1 FROM FOO_COST_SHEET WHERE FOO_COST_SHEET.item_id = fm.item_id);

INSERT INTO CUST_PERSON_ACC (customer_number, name, phone) 
SELECT * FROM (VALUES
    ('CUST001', 'Rajesh Kumar', '9876543210'),
    ('CUST002', 'Priya Sharma', '9876543211'),
    ('CUST003', 'Amit Singh', '9876543212')
) AS v(customer_number, name, phone)
WHERE NOT EXISTS (SELECT 1 FROM CUST_PERSON_ACC);

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;