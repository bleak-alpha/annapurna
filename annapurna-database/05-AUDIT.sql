--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - AUDIT MODULE (Dashboard/Order-Sheet Log)
-- Run order: 01_foo -> 02_cust -> 03_om -> 04_billing -> 05_audit -> 06_procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: sequences
--------------------------------------------------------------------------------

CREATE SEQUENCE INA_CANTEEN_AUDIT_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
--------------------------------------------------------------------------------
-- 2: tables
-- DEPENDS ON- 1 sequences
-- Backs InaAuditTable entity used by OrderDashboardService / orderSheet.jsx.
-- Independent table, no FKs to other modules (stores denormalized snapshot JSON).
--------------------------------------------------------------------------------

CREATE TABLE INA_CANTEEN_AUDIT (
    id              NUMBER(12)    DEFAULT INA_CANTEEN_AUDIT_SEQ.NEXTVAL PRIMARY KEY,
    customer_name   VARCHAR2(255),
    customer_id     VARCHAR2(50),
    table_no        VARCHAR2(50),
    order_details   CLOB,
    total_payment   NUMBER(10,2),
    payment_method  VARCHAR2(20),
    due_amount      VARCHAR2(50),
    order_status    VARCHAR2(20),
    created_date    TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE INDEX IDX_AUDIT_CREATED_DATE ON INA_CANTEEN_AUDIT(created_date);
--------------------------------------------------------------------------------
-- MODULE: AUDIT (Order-Sheet / Dashboard Audit Log)
-- FILE:   03_sample_data.sql
-- DEPENDS ON: 02_tables.sql
--------------------------------------------------------------------------------

INSERT INTO INA_CANTEEN_AUDIT (customer_name, customer_id, table_no, order_details, total_payment, payment_method, due_amount, order_status)
VALUES ('Walk-in Guest', 'TEMP-1001', 'Table 2',
        '[{"itemDescription":"Dosa","qty":2,"served":true,"cost":40.0}]',
        80.00, 'CASH', '0', 'COMPLETED');

COMMIT;