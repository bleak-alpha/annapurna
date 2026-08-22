--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - SCHEMA TEARDOWN
--
-- Drops every application object owned by the connected schema so that
-- 00-INIT.sql can be re-run from a clean state.
--
-- Only touches objects carrying a known module prefix, so anything else
-- living in the schema is left alone.
--
-- USAGE:
--   sqlplus -S apps/apps@//localhost:1521/XEPDB1 @99-DROP.sql
--
-- WARNING: this destroys data. Intended for development and for recovering
-- from a partial install, not for a populated production schema.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 200
SET PAGESIZE 0
SET DEFINE OFF

DECLARE
    v_dropped NUMBER := 0;
    v_failed  NUMBER := 0;

    -- Module prefixes recognised as application objects.
    TYPE t_prefixes IS TABLE OF VARCHAR2(10);
    v_prefixes t_prefixes := t_prefixes('FOO_','CUST_','OM_','BILL_','AUDIT_','RPT_','INIT_');

    FUNCTION is_app_object (p_name IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        FOR i IN 1 .. v_prefixes.COUNT LOOP
            IF p_name LIKE v_prefixes(i) || '%' THEN
                RETURN TRUE;
            END IF;
        END LOOP;
        RETURN FALSE;
    END is_app_object;

    PROCEDURE drop_object (p_type IN VARCHAR2, p_name IN VARCHAR2, p_extra IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        EXECUTE IMMEDIATE 'DROP ' || p_type || ' ' || p_name || ' ' || p_extra;
        v_dropped := v_dropped + 1;
        DBMS_OUTPUT.PUT_LINE('  dropped ' || RPAD(LOWER(p_type), 10) || p_name);
    EXCEPTION
        WHEN OTHERS THEN
            v_failed := v_failed + 1;
            DBMS_OUTPUT.PUT_LINE('  FAILED  ' || RPAD(LOWER(p_type), 10) || p_name ||
                                 ' -> ' || SQLERRM);
    END drop_object;

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE(' TEARDOWN - schema ' || SYS_CONTEXT('USERENV','CURRENT_USER'));
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    -- Views first: they depend on tables but nothing depends on them.
    FOR r IN (SELECT view_name FROM user_views ORDER BY view_name) LOOP
        IF is_app_object(r.view_name) THEN
            drop_object('VIEW', r.view_name);
        END IF;
    END LOOP;

    -- Procedures and functions.
    FOR r IN (SELECT object_name, object_type
                FROM user_objects
               WHERE object_type IN ('PROCEDURE','FUNCTION','PACKAGE')
               ORDER BY object_type, object_name) LOOP
        IF is_app_object(r.object_name) THEN
            drop_object(r.object_type, r.object_name);
        END IF;
    END LOOP;

    -- Tables, with CASCADE CONSTRAINTS so foreign-key order does not matter.
    -- Triggers and indexes belonging to a table go with it.
    FOR r IN (SELECT table_name FROM user_tables ORDER BY table_name) LOOP
        IF is_app_object(r.table_name) THEN
            drop_object('TABLE', r.table_name, 'CASCADE CONSTRAINTS PURGE');
        END IF;
    END LOOP;

    -- Any trigger not attached to a dropped table.
    FOR r IN (SELECT trigger_name FROM user_triggers ORDER BY trigger_name) LOOP
        IF is_app_object(r.trigger_name) THEN
            drop_object('TRIGGER', r.trigger_name);
        END IF;
    END LOOP;

    -- Sequences last: triggers referencing them are already gone.
    FOR r IN (SELECT sequence_name FROM user_sequences ORDER BY sequence_name) LOOP
        IF is_app_object(r.sequence_name) THEN
            drop_object('SEQUENCE', r.sequence_name);
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(' Dropped: ' || v_dropped || '   Failed: ' || v_failed);

    IF v_failed > 0 THEN
        DBMS_OUTPUT.PUT_LINE(' Some objects could not be dropped. Re-run; dependency order');
        DBMS_OUTPUT.PUT_LINE(' sometimes needs a second pass.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(' Schema is clean. 00-INIT.sql can now be run.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('================================================================================');
END;
/

EXIT SUCCESS