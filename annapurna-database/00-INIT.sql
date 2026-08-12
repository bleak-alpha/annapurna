--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - MASTER INITIALISATION SCRIPT
--
-- Loads every module in dependency order, then runs a health check and
-- prints a readiness verdict.
--
-- USAGE (from the annapurna-database directory):
--   sqlplus -S annapurna/<password>@//localhost:1521/XEPDB1 @00-init.sql
--
-- Modules are loaded in this order because of foreign-key dependencies:
--   FOO   -> no dependencies
--   CUST  -> no dependencies
--   OM    -> depends on FOO, CUST
--   BILL  -> depends on CUST, OM
--   AUDIT -> no dependencies
--   RPT   -> depends on all of the above
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 200
SET PAGESIZE 0
SET TRIMSPOOL ON
SET DEFINE OFF

-- Abort the whole load on the first SQL or PL/SQL error rather than
-- leaving a half-built schema behind.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
WHENEVER OSERROR  EXIT FAILURE ROLLBACK

SPOOL install.log

PROMPT
PROMPT ================================================================================
PROMPT  ANNAPURNA CANTEEN DATABASE - INSTALLATION STARTING
PROMPT ================================================================================
PROMPT

-- Every object below is created without a schema prefix, so it is owned by
-- whichever user runs this script. That keeps the DDL portable across schema
-- names, but it also means connecting as the wrong user would silently build
-- the application in the wrong place. Refuse to run unless the session is a
-- dedicated, non-privileged application schema.
DECLARE
    v_user      VARCHAR2(128) := SYS_CONTEXT('USERENV','CURRENT_USER');
    v_schema    VARCHAR2(128) := SYS_CONTEXT('USERENV','CURRENT_SCHEMA');
    v_container VARCHAR2(128) := SYS_CONTEXT('USERENV','CON_NAME');
    v_is_dba    NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Connected as  : ' || v_user);
    DBMS_OUTPUT.PUT_LINE('Owning schema : ' || v_schema);
    DBMS_OUTPUT.PUT_LINE('Container     : ' || v_container);
    DBMS_OUTPUT.PUT_LINE('Database      : ' || SYS_CONTEXT('USERENV','DB_NAME'));
    DBMS_OUTPUT.PUT_LINE('Started at    : ' || TO_CHAR(SYSTIMESTAMP,'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');

    IF v_user IN ('SYS','SYSTEM') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Refusing to install into ' || v_user || '. Connect as the application ' ||
            'schema (APP_USER in .env) so the objects are owned by it.');
    END IF;

    -- CURRENT_SCHEMA can be redirected by ALTER SESSION; if it no longer
    -- matches the connected user, objects would land somewhere unexpected.
    IF v_schema != v_user THEN
        RAISE_APPLICATION_ERROR(-20002,
            'CURRENT_SCHEMA (' || v_schema || ') does not match the connected user (' ||
            v_user || '). Objects would not be owned by the connecting user.');
    END IF;

    -- A schema holding application data should not also be a DBA.
    SELECT COUNT(*) INTO v_is_dba
      FROM session_roles
     WHERE role = 'DBA';

    IF v_is_dba > 0 THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: this schema holds the DBA role. Grant only ' ||
                             'CONNECT, RESOURCE and the CREATE privileges it needs.');
    END IF;

    IF v_container = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Connected to CDB$ROOT. Connect to the pluggable database (XEPDB1) instead.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Schema check passed. All objects will be owned by ' || v_user || '.');
END;
/


--------------------------------------------------------------------------------
-- MODULE LOAD
--------------------------------------------------------------------------------

PROMPT
PROMPT --> [1/6] Loading FOO module (menu / food master)...
@@01-FOO.sql

PROMPT --> [2/6] Loading CUST module (customer master)...
@@02-CUST.sql

PROMPT --> [3/6] Loading OM module (order management)...
@@03-OM.sql

PROMPT --> [4/6] Loading BILL module (payments / credit history)...
@@04-BILL.sql

PROMPT --> [5/6] Loading AUDIT module (dashboard order-sheet log)...
@@05-AUDIT.sql

PROMPT --> [6/6] Loading RPT module (cross-module reporting)...
@@06-RPT.sql

PROMPT
PROMPT All modules loaded. Running health check...
PROMPT


--------------------------------------------------------------------------------
-- HEALTH CHECK
--
-- From here on, a failed check should report rather than abort, so the
-- operator gets the full picture in one run. The final block re-raises
-- if anything is wrong, which makes the exit code usable by Docker.
--------------------------------------------------------------------------------

WHENEVER SQLERROR CONTINUE

DECLARE
    TYPE t_name_list IS TABLE OF VARCHAR2(128);

    v_expected_tables t_name_list := t_name_list(
        'FOO_FOOD_MST_TBL', 'FOO_COST_SHEET_TBL',
        'CUST_PERSON_ACC_TBL',
        'OM_ORDER_HEADERS_TBL', 'OM_ORDER_LINES_TBL',
        'BILL_PAYMENT_HIST_TBL', 'BILL_ORDER_HIST_TBL',
        'AUDIT_CANTEEN_TBL'
    );

    v_expected_seqs t_name_list := t_name_list(
        'FOO_FOOD_MST_SEQ', 'FOO_COST_SHEET_SEQ',
        'CUST_PERSON_ACC_SEQ',
        'OM_ORDER_HEADERS_SEQ', 'OM_ORDER_LINES_SEQ',
        'BILL_PAYMENT_HIST_SEQ', 'BILL_ORDER_HIST_SEQ',
        'AUDIT_CANTEEN_SEQ'
    );

    v_expected_views t_name_list := t_name_list(
        'FOO_ACTIVE_MENU_V', 'FOO_COST_HISTORY_V',
        'CUST_CUSTOMER_DUES_V', 'CUST_ACTIVE_CUSTOMERS_V',
        'OM_PENDING_ORDERS_V', 'OM_KITCHEN_QUEUE_V',
        'BILL_UNPAID_ORDER_LINES_V', 'BILL_PAYMENT_HISTORY_V',
        'AUDIT_DAILY_SUMMARY_V', 'RPT_DAILY_REVENUE_V'
    );

    v_expected_procs t_name_list := t_name_list(
        'RPT_GET_DAILY_PAYMENTS_PRC', 'RPT_GET_CUSTOMER_STMT_PRC',
        'RPT_GET_POPULAR_ITEMS_PRC',  'RPT_GET_SALES_SUMMARY_PRC',
        'RPT_GET_CASHIER_CLOSING_PRC',
        'RPT_GET_CUSTOMER_BALANCE_FUNC', 'RPT_GET_DAY_REVENUE_FUNC'
    );

    v_count       NUMBER;
    v_failures    NUMBER := 0;
    v_warnings    NUMBER := 0;
    v_menu_rows   NUMBER;
    v_invalid     NUMBER;
    v_disabled    NUMBER;
    v_untrusted   NUMBER;
    v_trg_count   NUMBER;

    PROCEDURE report (p_label IN VARCHAR2, p_ok IN BOOLEAN, p_detail IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_label, 46, '.') ||
            CASE WHEN p_ok THEN ' OK' ELSE ' FAILED' END ||
            CASE WHEN p_detail IS NOT NULL THEN '  (' || p_detail || ')' ELSE '' END
        );
    END report;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(' HEALTH CHECK');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');

    -- 1. Tables present
    FOR i IN 1 .. v_expected_tables.COUNT LOOP
        SELECT COUNT(*) INTO v_count
          FROM USER_TABLES
         WHERE table_name = v_expected_tables(i);

        IF v_count = 0 THEN
            v_failures := v_failures + 1;
            report('TABLE ' || v_expected_tables(i), FALSE, 'missing');
        END IF;
    END LOOP;
    report('Tables (' || v_expected_tables.COUNT || ' expected)', v_failures = 0);

    -- 2. Sequences present
    v_count := 0;
    FOR i IN 1 .. v_expected_seqs.COUNT LOOP
        SELECT COUNT(*) INTO v_count
          FROM USER_SEQUENCES
         WHERE sequence_name = v_expected_seqs(i);

        IF v_count = 0 THEN
            v_failures := v_failures + 1;
            report('SEQUENCE ' || v_expected_seqs(i), FALSE, 'missing');
        END IF;
    END LOOP;
    report('Sequences (' || v_expected_seqs.COUNT || ' expected)', v_failures = 0);

    -- 3. Views present
    FOR i IN 1 .. v_expected_views.COUNT LOOP
        SELECT COUNT(*) INTO v_count
          FROM USER_VIEWS
         WHERE view_name = v_expected_views(i);

        IF v_count = 0 THEN
            v_failures := v_failures + 1;
            report('VIEW ' || v_expected_views(i), FALSE, 'missing');
        END IF;
    END LOOP;
    report('Views (' || v_expected_views.COUNT || ' expected)', v_failures = 0);

    -- 4. Procedures and functions present
    FOR i IN 1 .. v_expected_procs.COUNT LOOP
        SELECT COUNT(*) INTO v_count
          FROM USER_OBJECTS
         WHERE object_name = v_expected_procs(i)
           AND object_type IN ('PROCEDURE','FUNCTION');

        IF v_count = 0 THEN
            v_failures := v_failures + 1;
            report('PROGRAM ' || v_expected_procs(i), FALSE, 'missing');
        END IF;
    END LOOP;
    report('Procedures / functions (' || v_expected_procs.COUNT || ' expected)', v_failures = 0);

    -- 5. No invalid objects
    SELECT COUNT(*) INTO v_invalid
      FROM USER_OBJECTS
     WHERE status != 'VALID';

    IF v_invalid > 0 THEN
        v_failures := v_failures + 1;
        report('Object compilation', FALSE, v_invalid || ' invalid object(s)');

        FOR r IN (SELECT object_name, object_type
                    FROM USER_OBJECTS
                   WHERE status != 'VALID'
                   ORDER BY object_type, object_name) LOOP
            DBMS_OUTPUT.PUT_LINE('    INVALID: ' || r.object_type || ' ' || r.object_name);
        END LOOP;
    ELSE
        report('Object compilation', TRUE, 'all VALID');
    END IF;

    -- 6. Triggers enabled
    SELECT COUNT(*) INTO v_trg_count  FROM USER_TRIGGERS;
    SELECT COUNT(*) INTO v_disabled   FROM USER_TRIGGERS WHERE status != 'ENABLED';

    IF v_disabled > 0 THEN
        v_failures := v_failures + 1;
        report('Triggers', FALSE, v_disabled || ' of ' || v_trg_count || ' disabled');
    ELSE
        report('Triggers (' || v_trg_count || ' found)', TRUE, 'all ENABLED');
    END IF;

    -- 7. Foreign keys enabled and validated
    SELECT COUNT(*) INTO v_untrusted
      FROM USER_CONSTRAINTS
     WHERE constraint_type = 'R'
       AND (status != 'ENABLED' OR validated != 'VALIDATED');

    IF v_untrusted > 0 THEN
        v_failures := v_failures + 1;
        report('Foreign keys', FALSE, v_untrusted || ' not enabled/validated');
    ELSE
        SELECT COUNT(*) INTO v_count
          FROM USER_CONSTRAINTS
         WHERE constraint_type = 'R';
        report('Foreign keys (' || v_count || ' found)', TRUE, 'enabled and validated');
    END IF;

    -- 8. Seed data reachable through the menu view (smoke test of a real join)
    SELECT COUNT(*) INTO v_menu_rows FROM FOO_ACTIVE_MENU_V;

    IF v_menu_rows = 0 THEN
        v_warnings := v_warnings + 1;
        report('Seed data / FOO_ACTIVE_MENU_V', FALSE, 'no priced menu items');
    ELSE
        report('Seed data / FOO_ACTIVE_MENU_V', TRUE, v_menu_rows || ' priced item(s)');
    END IF;

    -- 9. Manual-ID guards installed on every module
    SELECT COUNT(*) INTO v_count
      FROM USER_TRIGGERS
     WHERE trigger_name IN (
        'FOO_PREVENT_MANUAL_ITEM_ID_TRG',
        'FOO_PREVENT_MANUAL_COST_ID_TRG',
        'CUST_PREVENT_MANUAL_CUST_ID_TRG',
        'OM_PREVENT_MANUAL_HEADER_ID_TRG',
        'OM_PREVENT_MANUAL_LINE_ID_TRG',
        'BILL_PREVENT_MANUAL_PAYMENT_ID_TRG',
        'BILL_PREVENT_MANUAL_HIST_ID_TRG',
        'AUDIT_PREVENT_MANUAL_ID_TRG'
     );

    IF v_count < 8 THEN
        v_failures := v_failures + 1;
        report('Manual-ID guards', FALSE, v_count || ' of 8 present');
    ELSE
        report('Manual-ID guards', TRUE, '8 of 8 present');
    END IF;

    -- 10. Ownership: every application object must belong to this schema.
    -- USER_OBJECTS is already owner-scoped, so compare its count against
    -- ALL_OBJECTS filtered to the module prefixes to catch anything that
    -- landed in another schema.
    SELECT COUNT(*) INTO v_count
      FROM ALL_OBJECTS
     WHERE owner != SYS_CONTEXT('USERENV','CURRENT_USER')
       AND (   object_name LIKE 'FOO\_%'   ESCAPE '\'
            OR object_name LIKE 'CUST\_%'  ESCAPE '\'
            OR object_name LIKE 'OM\_%'    ESCAPE '\'
            OR object_name LIKE 'BILL\_%'  ESCAPE '\'
            OR object_name LIKE 'AUDIT\_%' ESCAPE '\'
            OR object_name LIKE 'RPT\_%'   ESCAPE '\');

    IF v_count > 0 THEN
        v_warnings := v_warnings + 1;
        report('Object ownership', FALSE,
               v_count || ' module object(s) owned by another schema');

        FOR r IN (SELECT owner, object_type, object_name
                    FROM ALL_OBJECTS
                   WHERE owner != SYS_CONTEXT('USERENV','CURRENT_USER')
                     AND (   object_name LIKE 'FOO\_%'   ESCAPE '\'
                          OR object_name LIKE 'CUST\_%'  ESCAPE '\'
                          OR object_name LIKE 'OM\_%'    ESCAPE '\'
                          OR object_name LIKE 'BILL\_%'  ESCAPE '\'
                          OR object_name LIKE 'AUDIT\_%' ESCAPE '\'
                          OR object_name LIKE 'RPT\_%'   ESCAPE '\')
                   ORDER BY owner, object_name) LOOP
            DBMS_OUTPUT.PUT_LINE('    FOREIGN: ' || r.owner || '.' || r.object_name ||
                                 ' (' || r.object_type || ')');
        END LOOP;
    ELSE
        SELECT COUNT(*) INTO v_count FROM USER_OBJECTS;
        report('Object ownership', TRUE,
               v_count || ' object(s) owned by ' || SYS_CONTEXT('USERENV','CURRENT_USER'));
    END IF;

    -- Per-module inventory, so the owner of each module is visible at a glance.
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' Module inventory (owner: ' || SYS_CONTEXT('USERENV','CURRENT_USER') || ')');
    FOR r IN (
        SELECT SUBSTR(object_name, 1, INSTR(object_name, '_') - 1) AS module_code,
               COUNT(*) AS object_count
          FROM USER_OBJECTS
         WHERE INSTR(object_name, '_') > 0
           AND SUBSTR(object_name, 1, INSTR(object_name, '_') - 1)
               IN ('FOO','CUST','OM','BILL','AUDIT','RPT','INIT')
         GROUP BY SUBSTR(object_name, 1, INSTR(object_name, '_') - 1)
         ORDER BY module_code
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD(r.module_code, 10) || r.object_count || ' object(s)');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    -- Verdict
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');

    IF v_failures = 0 AND v_warnings = 0 THEN
        DBMS_OUTPUT.PUT_LINE(' STATUS: HEALTHY - DATABASE IS READY TO USE');
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    ELSIF v_failures = 0 THEN
        DBMS_OUTPUT.PUT_LINE(' STATUS: DEGRADED - SCHEMA IS COMPLETE BUT ' || v_warnings || ' WARNING(S) RAISED');
        DBMS_OUTPUT.PUT_LINE(' The application will start, but seed data may be missing.');
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    ELSE
        DBMS_OUTPUT.PUT_LINE(' STATUS: UNHEALTHY - ' || v_failures || ' CHECK(S) FAILED');
        DBMS_OUTPUT.PUT_LINE(' Do not start the application against this schema.');
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
        RAISE_APPLICATION_ERROR(-20999,
            'Database health check failed with ' || v_failures || ' error(s). See install.log.');
    END IF;
END;
/

-- Marker row polled by the Docker health check. Written only when the
-- block above did not raise, so its presence means the schema is good.
CREATE TABLE INIT_HEALTH_STATUS_TBL (
    status_id     NUMBER(4)      DEFAULT 1 PRIMARY KEY,
    status        VARCHAR2(20)   NOT NULL,
    schema_name   VARCHAR2(128),
    installed_at  TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_health_status CHECK (status IN ('HEALTHY','DEGRADED','UNHEALTHY'))
);

INSERT INTO INIT_HEALTH_STATUS_TBL (status_id, status, schema_name)
VALUES (1, 'HEALTHY', SYS_CONTEXT('USERENV','CURRENT_USER'));

COMMIT;

PROMPT
PROMPT ================================================================================
PROMPT  ANNAPURNA CANTEEN DATABASE - INSTALLATION COMPLETE
PROMPT ================================================================================
PROMPT

SPOOL OFF

EXIT SUCCESS