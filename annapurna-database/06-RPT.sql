--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - RPT MODULE (Cross-Module Reporting)
-- MODULE CODE: RPT   (derived from file name 06-RPT.sql; replaces 06-PROC.sql,
--                     since PROC is an object type rather than a module)
-- Run order: 01-FOO -> 02-CUST -> 03-OM -> 04-BILL -> 05-AUDIT -> 06-RPT
--
-- NAMING: <MODULE>_<NAME>_<TYPE>   TBL SEQ TRG V PRC FUNC IDX
-- JOINS : WHERE-clause only. ANSI JOIN syntax is never used.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: functions
-- DEPENDS ON- CUST module, BILL module
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION RPT_GET_CUSTOMER_BALANCE_FUNC (
    p_customer_id IN NUMBER
) RETURN NUMBER IS
    v_balance NUMBER(10,2);
BEGIN
    SELECT NVL(total_due, 0)
      INTO v_balance
      FROM CUST_PERSON_ACC_TBL
     WHERE customer_id = p_customer_id;

    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END RPT_GET_CUSTOMER_BALANCE_FUNC;
/

CREATE OR REPLACE FUNCTION RPT_GET_DAY_REVENUE_FUNC (
    p_date IN DATE
) RETURN NUMBER IS
    v_revenue NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(ol.total_cost), 0)
      INTO v_revenue
      FROM OM_ORDER_LINES_TBL ol, OM_ORDER_HEADERS_TBL oh
     WHERE ol.header_id = oh.header_id
       AND TRUNC(oh.creation_date) = TRUNC(p_date)
       AND oh.order_status != 'CANCELLED';

    RETURN v_revenue;
END RPT_GET_DAY_REVENUE_FUNC;
/


--------------------------------------------------------------------------------
-- 2: reporting procedures
-- DEPENDS ON- 1: functions, CUST module, OM module, BILL module, FOO module
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RPT_GET_DAILY_PAYMENTS_PRC (
    p_date   IN  DATE,
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT bph.payment_id, cpa.name AS customer_name, bph.payment_mode,
               bph.amount_paid, bph.payment_date, bph.reference_no
          FROM BILL_PAYMENT_HIST_TBL bph, CUST_PERSON_ACC_TBL cpa
         WHERE bph.customer_id = cpa.customer_id
           AND TRUNC(bph.payment_date) = TRUNC(p_date)
         ORDER BY bph.payment_date;
END RPT_GET_DAILY_PAYMENTS_PRC;
/

CREATE OR REPLACE PROCEDURE RPT_GET_CUSTOMER_STMT_PRC (
    p_customer_id IN  NUMBER,
    p_cursor      OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ol.creation_date, fm.item_description, ol.quantity,
               ol.total_cost, boh.is_paid_now
          FROM BILL_ORDER_HIST_TBL boh, OM_ORDER_LINES_TBL ol, FOO_FOOD_MST_TBL fm
         WHERE boh.line_id = ol.line_id
           AND ol.item_id = fm.item_id
           AND boh.customer_id = p_customer_id
         ORDER BY ol.creation_date DESC;
END RPT_GET_CUSTOMER_STMT_PRC;
/

CREATE OR REPLACE PROCEDURE RPT_GET_POPULAR_ITEMS_PRC (
    p_from_date IN  DATE,
    p_to_date   IN  DATE,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT fm.item_code, fm.item_description, fm.category_code,
               SUM(ol.quantity)   AS total_quantity,
               SUM(ol.total_cost) AS total_revenue
          FROM OM_ORDER_LINES_TBL ol, OM_ORDER_HEADERS_TBL oh, FOO_FOOD_MST_TBL fm
         WHERE ol.header_id = oh.header_id
           AND ol.item_id = fm.item_id
           AND oh.order_status != 'CANCELLED'
           AND TRUNC(oh.creation_date) BETWEEN TRUNC(p_from_date) AND TRUNC(p_to_date)
         GROUP BY fm.item_code, fm.item_description, fm.category_code
         ORDER BY total_quantity DESC;
END RPT_GET_POPULAR_ITEMS_PRC;
/

CREATE OR REPLACE PROCEDURE RPT_GET_SALES_SUMMARY_PRC (
    p_from_date IN  DATE,
    p_to_date   IN  DATE,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT TRUNC(oh.creation_date)        AS sales_date,
               COUNT(DISTINCT oh.header_id)   AS order_count,
               SUM(ol.total_cost)             AS gross_sales,
               SUM(CASE WHEN oh.is_paid_full = 1 THEN ol.total_cost ELSE 0 END) AS collected,
               SUM(CASE WHEN oh.is_deferred  = 1 THEN ol.total_cost ELSE 0 END) AS on_credit
          FROM OM_ORDER_LINES_TBL ol, OM_ORDER_HEADERS_TBL oh
         WHERE ol.header_id = oh.header_id
           AND oh.order_status != 'CANCELLED'
           AND TRUNC(oh.creation_date) BETWEEN TRUNC(p_from_date) AND TRUNC(p_to_date)
         GROUP BY TRUNC(oh.creation_date)
         ORDER BY sales_date DESC;
END RPT_GET_SALES_SUMMARY_PRC;
/

CREATE OR REPLACE PROCEDURE RPT_GET_CASHIER_CLOSING_PRC (
    p_date   IN  DATE,
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT bph.payment_mode,
               COUNT(*)               AS txn_count,
               SUM(bph.amount_paid)   AS total_amount
          FROM BILL_PAYMENT_HIST_TBL bph
         WHERE TRUNC(bph.payment_date) = TRUNC(p_date)
           AND bph.is_active = 1
         GROUP BY bph.payment_mode
         ORDER BY bph.payment_mode;
END RPT_GET_CASHIER_CLOSING_PRC;
/


--------------------------------------------------------------------------------
-- 3: views
-- DEPENDS ON- OM module, FOO module
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW RPT_DAILY_REVENUE_V AS
SELECT TRUNC(oh.creation_date)      AS sales_date,
       COUNT(DISTINCT oh.header_id) AS order_count,
       SUM(ol.total_cost)           AS gross_sales
  FROM OM_ORDER_LINES_TBL ol, OM_ORDER_HEADERS_TBL oh
 WHERE ol.header_id = oh.header_id
   AND oh.order_status != 'CANCELLED'
 GROUP BY TRUNC(oh.creation_date)
 ORDER BY sales_date DESC;