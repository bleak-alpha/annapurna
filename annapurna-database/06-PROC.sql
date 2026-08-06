--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - CROSS-MODULE PROCEDURES
-- Run order: 01_foo -> 02_cust -> 03_om -> 04_billing -> 05_audit -> 06_procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: reporting procedures
-- DEPENDS ON- 2: cust module, 4: billing module
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE PRC_GET_DAILY_PAYMENTS (
    p_date       IN  DATE,
    p_cursor     OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT cph.payment_id, cpa.name AS customer_name, cph.payment_mode,
               cph.amount_paid, cph.payment_date
          FROM CUST_PAYMENT_HIST cph
          JOIN CUST_PERSON_ACC cpa ON cph.customer_id = cpa.customer_id
         WHERE TRUNC(cph.payment_date) = TRUNC(p_date)
         ORDER BY cph.payment_date;
END PRC_GET_DAILY_PAYMENTS;
/

CREATE OR REPLACE PROCEDURE PRC_GET_CUSTOMER_STATEMENT (
    p_customer_id IN  NUMBER,
    p_cursor      OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ol.creation_date, fm.item_description, ol.quantity, ol.total_cost,
               coh.is_paid_now
          FROM CUST_ORDER_HIST coh
          JOIN OM_ORDER_LINES ol ON coh.line_id = ol.line_id
          JOIN FOO_FOOD_MST fm   ON ol.item_id = fm.item_id
         WHERE coh.customer_id = p_customer_id
         ORDER BY ol.creation_date DESC;
END PRC_GET_CUSTOMER_STATEMENT;
/