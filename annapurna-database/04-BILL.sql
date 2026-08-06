--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - BILLING MODULE (Payments & Order History)
-- Run order: 01_foo -> 02_cust -> 03_om -> 04_billing -> 05_audit -> 06_procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: sequences
--------------------------------------------------------------------------------
CREATE SEQUENCE CUST_PAYMENT_HIST_SEQ
    START WITH 100000
    INCREMENT BY 1
    MINVALUE 100000
    MAXVALUE 999999999999
    NOCYCLE
    CACHE 20;

CREATE SEQUENCE CUST_ORDER_HIST_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;


--------------------------------------------------------------------------------
-- 2: tables
-- DEPENDS ON: 1 sequences, CUST module (CUST_PERSON_ACC), OM module (OM_ORDER_LINES)
--------------------------------------------------------------------------------

-- CUST_PAYMENT_HIST: Payment History
CREATE TABLE CUST_PAYMENT_HIST (
    payment_id     NUMBER(12)    DEFAULT CUST_PAYMENT_HIST_SEQ.NEXTVAL PRIMARY KEY,
    customer_id    NUMBER(10)    NOT NULL,
    creation_date  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    payment_date   TIMESTAMP,
    payment_mode   VARCHAR2(20),
    amount_paid    NUMBER(10,2)  NOT NULL,
    reference_no   VARCHAR2(100),                          -- NEW: UPI/card txn ref
    CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES CUST_PERSON_ACC(customer_id),
    CONSTRAINT chk_payment_mode CHECK (payment_mode IN ('CASH','ONLINE','UPI','CARD','WALLET')),
    CONSTRAINT chk_amount_paid  CHECK (amount_paid > 0)
);

-- CUST_ORDER_HIST: Links customers to order lines for deferred/credit tracking
CREATE TABLE CUST_ORDER_HIST (
    hist_id        NUMBER(10)  DEFAULT CUST_ORDER_HIST_SEQ.NEXTVAL PRIMARY KEY,
    customer_id    NUMBER(10)  NOT NULL,
    line_id        NUMBER(10)  NOT NULL,
    is_paid_now    NUMBER(1)   DEFAULT 0,
    payment_id     NUMBER(12),
    creation_date  TIMESTAMP   DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_cust_hist_customer FOREIGN KEY (customer_id) REFERENCES CUST_PERSON_ACC(customer_id),
    CONSTRAINT fk_cust_hist_line     FOREIGN KEY (line_id) REFERENCES OM_ORDER_LINES(line_id),
    CONSTRAINT fk_cust_hist_payment  FOREIGN KEY (payment_id) REFERENCES CUST_PAYMENT_HIST(payment_id),
    CONSTRAINT uq_customer_line      UNIQUE (customer_id, line_id),
    CONSTRAINT chk_hist_paid_now     CHECK (is_paid_now IN (0,1))
);
--------------------------------------------------------------------------------
-- 3: triggers
-- DEPENDS ON- 2: tables
--------------------------------------------------------------------------------

-- Prevent manual payment_id insertion (sequence-only)
CREATE OR REPLACE TRIGGER CUST_PREVENT_MANUAL_PAYMENT_ID_TRG
    BEFORE INSERT ON CUST_PAYMENT_HIST
    FOR EACH ROW
BEGIN
    IF :NEW.payment_id IS NOT NULL
       AND :NEW.payment_id != CUST_PAYMENT_HIST_SEQ.CURRVAL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Cannot manually set payment_id. It must be auto-generated.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -8002 THEN -- CURRVAL not yet defined in session (first call), allow
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/

-- On payment insert: mark related order history + order lines as paid,
-- then reduce the customer's outstanding due.
CREATE OR REPLACE TRIGGER CUST_UPDATE_ORDER_HIST_ON_PAYMENT_TRG
    AFTER INSERT ON CUST_PAYMENT_HIST
    FOR EACH ROW
BEGIN
    UPDATE CUST_ORDER_HIST
       SET payment_id = :NEW.payment_id,
           is_paid_now = 1
     WHERE customer_id = :NEW.customer_id
       AND is_paid_now = 0;

    UPDATE OM_ORDER_LINES ol
       SET is_paid = 1
     WHERE ol.line_id IN (
        SELECT coh.line_id
          FROM CUST_ORDER_HIST coh
         WHERE coh.customer_id = :NEW.customer_id
           AND coh.payment_id = :NEW.payment_id
     );

    UPDATE CUST_PERSON_ACC
       SET total_due = GREATEST(total_due - :NEW.amount_paid, 0)
     WHERE customer_id = :NEW.customer_id;
END;
/
--------------------------------------------------------------------------------
-- 4: views
-- DEPENDS ON- 2: tables.sql, CUST modulE, OM module
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW CUST_UNPAID_ORDER_LINES_V AS
SELECT coh.hist_id, c.customer_id, c.name AS customer_name,
       ol.line_id, oh.order_number, ol.creation_date,
       fm.item_description, ol.quantity, ol.total_cost
  FROM CUST_ORDER_HIST coh, CUST_PERSON_ACC c, OM_ORDER_LINES ol, OM_ORDER_HEADERS oh, FOO_FOOD_MST fm
   WHERE ol.item_id = fm.item_id
   AND ol.header_id = oh.header_id
   AND coh.line_id = ol.line_id
   AND coh.customer_id = c.customer_id
   AND coh.is_paid_now = 0;

CREATE OR REPLACE VIEW CUST_PAYMENT_HISTORY_V AS
SELECT cph.payment_id, c.customer_id, c.name AS customer_name,
       cph.amount_paid, cph.payment_mode, cph.payment_date, cph.reference_no
  FROM CUST_PAYMENT_HIST cph, CUST_PERSON_ACC c
  WHERE cph.customer_id = c.customer_id
 ORDER BY cph.payment_date DESC;


--------------------------------------------------------------------------------
-- 5: sample data
-- DEPENDS ON: 2: tables, 3: triggers, CUST + OM sample data loaded
--------------------------------------------------------------------------------

-- Register the deferred line (created in OM sample data) into customer credit history
INSERT INTO CUST_ORDER_HIST (customer_id, line_id, is_paid_now)
SELECT c.customer_id, ol.line_id, 0
  FROM CUST_PERSON_ACC c
  JOIN OM_ORDER_HEADERS oh ON oh.customer_id = c.customer_id
  JOIN OM_ORDER_LINES ol   ON ol.header_id = oh.header_id
 WHERE c.customer_number = 'CUST001'
   AND oh.is_deferred = 1;

-- Reflect the same amount as an outstanding due on the customer record
UPDATE CUST_PERSON_ACC
   SET total_due = 180.00
 WHERE customer_number = 'CUST001';

COMMIT;

-- Example payment that will auto-clear the above due via TRG_UPDATE_ORDER_HIST_ON_PAYMENT
-- (left commented so sample-data load doesn't silently zero out the demo due; run manually to test)
-- INSERT INTO CUST_PAYMENT_HIST (customer_id, payment_date, payment_mode, amount_paid)
-- SELECT customer_id, SYSTIMESTAMP, 'CASH', 180.00 FROM CUST_PERSON_ACC WHERE customer_number = 'CUST001';
-- COMMIT;