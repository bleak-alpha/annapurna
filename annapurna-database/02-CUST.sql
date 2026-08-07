--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - CUST MODULE (Customer Master)
-- Run order: 01_foo -> 02_cust -> 03_om -> 04_billing -> 05_audit -> 06_procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: sequences
--------------------------------------------------------------------------------
CREATE SEQUENCE CUST_PERSON_ACC_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;


--------------------------------------------------------------------------------
-- 2: tables
-- DEPENDS ON- 1: sequences
--------------------------------------------------------------------------------
-- CUST_PERSON_ACC: Customer Master
CREATE TABLE CUST_PERSON_ACC_TBL (
    customer_id      NUMBER(10)     DEFAULT CUST_PERSON_ACC_SEQ.NEXTVAL PRIMARY KEY,
    customer_number  VARCHAR2(50)   NOT NULL,
    name             VARCHAR2(255)  NOT NULL,
    phone            VARCHAR2(20),
    email            VARCHAR2(255),                       -- NEW: optional contact channel
    creation_date    TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    created_by       VARCHAR2(100)  DEFAULT 'SYSTEM',
    updated_date     TIMESTAMP,
    updated_by       VARCHAR2(100),
    is_active        NUMBER(1)      DEFAULT 1 NOT NULL,
    total_due        NUMBER(10,2)   DEFAULT 0.00 NOT NULL,
    loyalty_points   NUMBER(10)     DEFAULT 0 NOT NULL,    -- NEW: future loyalty module
    version_no       NUMBER(10)     DEFAULT 0 NOT NULL,
    CONSTRAINT uq_customer_number  UNIQUE (customer_number),
    CONSTRAINT chk_customer_active CHECK (is_active IN (0,1))
);

--------------------------------------------------------------------------------
-- 3: triggers
-- DEPENDS ON- 2: tables
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER CUST_PREVENT_MANUAL_CUSTOMER_ID_TRG
    BEFORE INSERT ON CUST_PERSON_ACC_TBL
    FOR EACH ROW
BEGIN
	IF :NEW.CUSTOMER_ID IS NULL AND :NEW.CUSTOMER_ID != CUST_PERSON_ACC_SEQ.CURRVAL THEN
		RAISE_APPLICATION_ERROR(-20003, 'Cannot manually set customer_id. It must be automatically generated.');
	END IF;
EXCEPTION
	WHEN OTHERS THEN
	IF SQLCODE = -8002 THEN --CURRVAL NOT DEFINED IN SESSION
		NULL;
	ELSE
		RAISE;
	END IF;
END;
/
--------------------------------------------------------------------------------
-- 4: views
-- DEPENDS ON- 2: tables
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW CUST_CUSTOMER_DUES_V AS
SELECT customer_id, customer_number, name, phone, total_due
  FROM CUST_PERSON_ACC_TBL
 WHERE is_active = 1 AND total_due > 0
 ORDER BY total_due DESC;

CREATE OR REPLACE VIEW CUST_ACTIVE_CUSTOMERS_V AS
SELECT customer_id, customer_number, name, phone, email
  FROM CUST_PERSON_ACC_TBL
 WHERE is_active = 1
 ORDER BY name;


--------------------------------------------------------------------------------
-- 5: sample data
-- DEPENDS ON- 2: tables
--------------------------------------------------------------------------------

INSERT INTO CUST_PERSON_ACC_TBL (customer_number, name, phone) VALUES ('CUST001', 'Rajesh Kumar', '9876543210');
INSERT INTO CUST_PERSON_ACC_TBL (customer_number, name, phone) VALUES ('CUST002', 'Priya Sharma', '9876543211');
INSERT INTO CUST_PERSON_ACC_TBL (customer_number, name, phone) VALUES ('CUST003', 'Amit Singh', '9876543212');

COMMIT;