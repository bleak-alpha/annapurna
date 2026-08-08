--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - OM MODULE (Order Management)
-- MODULE CODE: OM   (derived from file name 03-OM.sql)
-- Run order: 01-FOO -> 02-CUST -> 03-OM -> 04-BILL -> 05-AUDIT -> 06-RPT
--
-- NAMING: <MODULE>_<NAME>_<TYPE>   TBL SEQ TRG V PRC FUNC IDX
-- JOINS : WHERE-clause only. ANSI JOIN syntax is never used.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: sequences
--------------------------------------------------------------------------------
-- Business order number (YYMMDD + 3-digit daily counter) is built by
-- OM_GENERATE_ORDER_NUMBER_TRG; this sequence backs only the surrogate header_id.
CREATE SEQUENCE OM_ORDER_HEADERS_SEQ
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    MAXVALUE 9999999999
    NOCYCLE
    CACHE 20;

CREATE SEQUENCE OM_ORDER_LINES_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;


--------------------------------------------------------------------------------
-- 2: tables
-- DEPENDS ON- 1: sequences, FOO module (FOO_FOOD_MST_TBL), CUST module (CUST_PERSON_ACC_TBL)
--------------------------------------------------------------------------------

CREATE TABLE OM_ORDER_HEADERS_TBL (
    header_id          NUMBER(10)     DEFAULT OM_ORDER_HEADERS_SEQ.NEXTVAL PRIMARY KEY,
    order_number       NUMBER(18),
    creation_date      TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    who_gave_order     VARCHAR2(255),
    when_ordered       TIMESTAMP      DEFAULT SYSTIMESTAMP,
    is_paid_full       NUMBER(1)      DEFAULT 0,
    is_deferred        NUMBER(1)      DEFAULT NULL,
    is_known_customer  NUMBER(1)      DEFAULT 0,
    customer_id        NUMBER(10),
    total_due          NUMBER(10,2)   DEFAULT 0.00,
    order_status       VARCHAR2(20)   DEFAULT 'PENDING',
    table_no           VARCHAR2(20),
    created_by         VARCHAR2(100)  DEFAULT 'SYSTEM',
    updated_date       TIMESTAMP,
    updated_by         VARCHAR2(100),
    is_active          NUMBER(1)      DEFAULT 1 NOT NULL,
    version_no         NUMBER(10)     DEFAULT 0 NOT NULL,
    CONSTRAINT uq_order_number UNIQUE (order_number),
    CONSTRAINT fk_order_header_customer FOREIGN KEY (customer_id) REFERENCES CUST_PERSON_ACC_TBL(customer_id),
    CONSTRAINT chk_paid_full     CHECK (is_paid_full IN (0,1)),
    CONSTRAINT chk_deferred      CHECK (is_deferred IN (0,1)),
    CONSTRAINT chk_known_cust    CHECK (is_known_customer IN (0,1)),
    CONSTRAINT chk_header_active CHECK (is_active IN (0,1)),
    CONSTRAINT chk_order_status  CHECK (order_status IN ('PENDING','PREPARING','READY','DELIVERED','COMPLETED','CANCELLED','HELD')),
    CONSTRAINT chk_payment_deferred CHECK (
        (is_paid_full = 1 AND is_deferred = 0) OR
        (is_paid_full = 0 AND is_deferred = 1) OR
        (is_paid_full IS NULL OR is_deferred IS NULL)
    ),
    CONSTRAINT chk_walk_in_payment CHECK (
        (customer_id IS NULL AND is_known_customer = 0 AND
         (is_deferred IS NULL OR is_deferred = 0) AND is_paid_full = 1) OR
        (customer_id IS NOT NULL)
    )
);

COMMENT ON COLUMN OM_ORDER_HEADERS_TBL.order_number IS 'Format: YYMMDD + 3-digit daily sequence (e.g. 251006001)';

CREATE TABLE OM_ORDER_LINES_TBL (
    line_id        NUMBER(10)     DEFAULT OM_ORDER_LINES_SEQ.NEXTVAL PRIMARY KEY,
    header_id      NUMBER(10)     NOT NULL,
    line_number    NUMBER(4),
    creation_date  TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    item_id        NUMBER(10)     NOT NULL,
    quantity       NUMBER(6)      NOT NULL,
    cost_per_item  NUMBER(10,2)   NOT NULL,
    total_cost     NUMBER(10,2)   DEFAULT 0.00,
    is_paid        NUMBER(1)      DEFAULT 0,
    is_served      NUMBER(1)      DEFAULT 0,
    served_at      TIMESTAMP,
    served_by      VARCHAR2(255),
    kitchen_notes  VARCHAR2(500),
    created_by     VARCHAR2(100)  DEFAULT 'SYSTEM',
    updated_date   TIMESTAMP,
    updated_by     VARCHAR2(100),
    is_active      NUMBER(1)      DEFAULT 1 NOT NULL,
    version_no     NUMBER(10)     DEFAULT 0 NOT NULL,
    CONSTRAINT fk_order_line_header FOREIGN KEY (header_id) REFERENCES OM_ORDER_HEADERS_TBL(header_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_line_item   FOREIGN KEY (item_id)   REFERENCES FOO_FOOD_MST_TBL(item_id),
    CONSTRAINT uq_header_line       UNIQUE (header_id, line_number),
    CONSTRAINT chk_line_quantity    CHECK (quantity > 0),
    CONSTRAINT chk_line_cost        CHECK (cost_per_item > 0),
    CONSTRAINT chk_line_paid        CHECK (is_paid IN (0,1)),
    CONSTRAINT chk_line_served      CHECK (is_served IN (0,1)),
    CONSTRAINT chk_line_active      CHECK (is_active IN (0,1))
);


--------------------------------------------------------------------------------
-- 3: indexes
-- DEPENDS ON- 2: tables
--------------------------------------------------------------------------------
CREATE INDEX OM_ORDER_HEADERS_CUSTOMER_IDX ON OM_ORDER_HEADERS_TBL (customer_id);
CREATE INDEX OM_ORDER_HEADERS_CRE_DATE_IDX ON OM_ORDER_HEADERS_TBL (creation_date);
CREATE INDEX OM_ORDER_HEADERS_STATUS_IDX   ON OM_ORDER_HEADERS_TBL (order_status);
CREATE INDEX OM_ORDER_HEADERS_PAID_IDX     ON OM_ORDER_HEADERS_TBL (is_paid_full);
CREATE INDEX OM_ORDER_LINES_HEADER_IDX     ON OM_ORDER_LINES_TBL (header_id);
CREATE INDEX OM_ORDER_LINES_ITEM_IDX       ON OM_ORDER_LINES_TBL (item_id);
CREATE INDEX OM_ORDER_LINES_SERVED_IDX     ON OM_ORDER_LINES_TBL (is_served);


--------------------------------------------------------------------------------
-- 4: triggers
-- DEPENDS ON- 1: sequences, 2: tables
--------------------------------------------------------------------------------

-- Prevent manual header_id insertion (sequence-only)
CREATE OR REPLACE TRIGGER OM_PREVENT_MANUAL_HEADER_ID_TRG
    BEFORE INSERT ON OM_ORDER_HEADERS_TBL
    FOR EACH ROW
DECLARE
    v_currval NUMBER;
BEGIN
    IF :NEW.header_id IS NOT NULL THEN
        BEGIN
            v_currval := OM_ORDER_HEADERS_SEQ.CURRVAL;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -8002 THEN
                    RETURN;
                END IF;
                RAISE;
        END;

        IF :NEW.header_id != v_currval THEN
            RAISE_APPLICATION_ERROR(-20301,
                'Cannot manually set header_id. It must be generated by OM_ORDER_HEADERS_SEQ.');
        END IF;
    END IF;
END;
/

-- Prevent manual line_id insertion (sequence-only)
CREATE OR REPLACE TRIGGER OM_PREVENT_MANUAL_LINE_ID_TRG
    BEFORE INSERT ON OM_ORDER_LINES_TBL
    FOR EACH ROW
DECLARE
    v_currval NUMBER;
BEGIN
    IF :NEW.line_id IS NOT NULL THEN
        BEGIN
            v_currval := OM_ORDER_LINES_SEQ.CURRVAL;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -8002 THEN
                    RETURN;
                END IF;
                RAISE;
        END;

        IF :NEW.line_id != v_currval THEN
            RAISE_APPLICATION_ERROR(-20302,
                'Cannot manually set line_id. It must be generated by OM_ORDER_LINES_SEQ.');
        END IF;
    END IF;
END;
/

-- Generate business order number: YYMMDD + 3-digit daily counter
CREATE OR REPLACE TRIGGER OM_GENERATE_ORDER_NUMBER_TRG
    BEFORE INSERT ON OM_ORDER_HEADERS_TBL
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL)
DECLARE
    v_date_prefix  VARCHAR2(6);
    v_sequence_num NUMBER;
    v_new_order_no NUMBER;
BEGIN
    v_date_prefix := TO_CHAR(SYSDATE, 'YYMMDD');

    SELECT NVL(MAX(TO_NUMBER(SUBSTR(TO_CHAR(order_number), 7, 3))), 0) + 1
      INTO v_sequence_num
      FROM OM_ORDER_HEADERS_TBL
     WHERE SUBSTR(TO_CHAR(order_number), 1, 6) = v_date_prefix;

    IF v_sequence_num > 999 THEN
        RAISE_APPLICATION_ERROR(-20303,
            'Daily order limit (999) exceeded for date ' || v_date_prefix);
    END IF;

    v_new_order_no := TO_NUMBER(v_date_prefix || LPAD(v_sequence_num, 3, '0'));
    :NEW.order_number := v_new_order_no;
END;
/

-- Auto-increment line_number within a header
CREATE OR REPLACE TRIGGER OM_GENERATE_LINE_NUMBER_TRG
    BEFORE INSERT ON OM_ORDER_LINES_TBL
    FOR EACH ROW
    WHEN (NEW.line_number IS NULL)
DECLARE
    v_next_line NUMBER;
BEGIN
    SELECT NVL(MAX(line_number), 0) + 1
      INTO v_next_line
      FROM OM_ORDER_LINES_TBL
     WHERE header_id = :NEW.header_id;

    :NEW.line_number := v_next_line;
END;
/

-- Derive line total
CREATE OR REPLACE TRIGGER OM_CALCULATE_LINE_TOTAL_TRG
    BEFORE INSERT OR UPDATE ON OM_ORDER_LINES_TBL
    FOR EACH ROW
BEGIN
    :NEW.total_cost := :NEW.quantity * :NEW.cost_per_item;
END;
/

-- An order may only be flagged fully paid once every line is paid
CREATE OR REPLACE TRIGGER OM_VALIDATE_ORDER_PAYMENT_TRG
    BEFORE UPDATE ON OM_ORDER_HEADERS_TBL
    FOR EACH ROW
    WHEN (NEW.is_paid_full = 1 AND OLD.is_paid_full = 0)
DECLARE
    v_unpaid_lines NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_unpaid_lines
      FROM OM_ORDER_LINES_TBL
     WHERE header_id = :NEW.header_id
       AND is_paid = 0;

    IF v_unpaid_lines > 0 THEN
        RAISE_APPLICATION_ERROR(-20304,
            'Cannot mark order as fully paid: ' || v_unpaid_lines || ' unpaid line(s) exist');
    END IF;
END;
/


--------------------------------------------------------------------------------
-- 5: views
-- DEPENDS ON- 2: tables, FOO module, CUST module
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW OM_PENDING_ORDERS_V AS
SELECT oh.header_id, oh.order_number, oh.creation_date, oh.table_no,
       NVL(c.name, 'WALK-IN CUSTOMER') AS customer_name,
       fm.item_code, fm.item_number, fm.item_description,
       ol.line_number, ol.quantity, ol.line_id, ol.total_cost,
       oh.is_paid_full, oh.is_deferred, oh.order_status
  FROM OM_ORDER_LINES_TBL ol, OM_ORDER_HEADERS_TBL oh,
       FOO_FOOD_MST_TBL fm, CUST_PERSON_ACC_TBL c
 WHERE ol.header_id = oh.header_id
   AND ol.item_id = fm.item_id
   AND oh.customer_id = c.customer_id (+)
   AND oh.order_status NOT IN ('COMPLETED','CANCELLED')
 ORDER BY oh.creation_date, ol.line_number;

CREATE OR REPLACE VIEW OM_KITCHEN_QUEUE_V AS
SELECT oh.header_id, oh.order_number, oh.table_no, oh.creation_date,
       ol.line_id, ol.line_number, fm.item_description, ol.quantity,
       ol.kitchen_notes, ol.is_served, oh.order_status
  FROM OM_ORDER_LINES_TBL ol, OM_ORDER_HEADERS_TBL oh, FOO_FOOD_MST_TBL fm
 WHERE ol.header_id = oh.header_id
   AND ol.item_id = fm.item_id
   AND ol.is_served = 0
   AND oh.order_status NOT IN ('COMPLETED','CANCELLED')
 ORDER BY oh.creation_date, ol.line_number;


--------------------------------------------------------------------------------
-- 6: sample data
-- DEPENDS ON- 2: tables, 4: triggers, FOO + CUST sample data loaded
--------------------------------------------------------------------------------

-- Walk-in, paid in full
INSERT INTO OM_ORDER_HEADERS_TBL (who_gave_order, is_paid_full, is_deferred, is_known_customer, table_no, order_status)
VALUES ('COUNTER', 1, 0, 0, 'TABLE 1', 'COMPLETED');

INSERT INTO OM_ORDER_LINES_TBL (header_id, item_id, quantity, cost_per_item, is_paid, is_served)
SELECT oh.header_id, fm.item_id, 2, cs.cost, 1, 1
  FROM OM_ORDER_HEADERS_TBL oh, FOO_FOOD_MST_TBL fm, FOO_COST_SHEET_TBL cs
 WHERE fm.item_id = cs.item_id
   AND cs.is_active = 1
   AND fm.item_code = 'B05'
   AND oh.who_gave_order = 'COUNTER'
   AND oh.table_no = 'TABLE 1';

-- Known customer, deferred (credit) order
INSERT INTO OM_ORDER_HEADERS_TBL (who_gave_order, is_paid_full, is_deferred, is_known_customer, customer_id, table_no, order_status, total_due)
SELECT 'WAITER', 0, 1, 1, c.customer_id, 'TABLE 3', 'PENDING', 180.00
  FROM CUST_PERSON_ACC_TBL c
 WHERE c.customer_number = 'CUST001';

INSERT INTO OM_ORDER_LINES_TBL (header_id, item_id, quantity, cost_per_item, is_paid, is_served)
SELECT oh.header_id, fm.item_id, 1, cs.cost, 0, 0
  FROM OM_ORDER_HEADERS_TBL oh, FOO_FOOD_MST_TBL fm, FOO_COST_SHEET_TBL cs
 WHERE fm.item_id = cs.item_id
   AND cs.is_active = 1
   AND fm.item_code = 'L05'
   AND oh.is_deferred = 1
   AND oh.table_no = 'TABLE 3';

COMMIT;