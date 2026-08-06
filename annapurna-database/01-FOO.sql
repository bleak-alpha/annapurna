--------------------------------------------------------------------------------
-- ANNAPURNA CANTEEN DB - FOO MODULE (Menu / Food Master)
-- Run order: 01_foo -> 02_cust -> 03_om -> 04_billing -> 05_audit -> 06_procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1: Sequences
--------------------------------------------------------------------------------
CREATE SEQUENCE FOO_FOOD_MST_SEQ   START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;
CREATE SEQUENCE FOO_COST_SHEET_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 20;


--------------------------------------------------------------------------------
-- 2: Tables
-- DEPENDS ON- 1: Sequences
--------------------------------------------------------------------------------

-- FOO_FOOD_MST: Menu Items Master
CREATE TABLE FOO_FOOD_MST (
    item_id           NUMBER(10)      DEFAULT FOO_FOOD_MST_SEQ.NEXTVAL PRIMARY KEY,
    item_code         VARCHAR2(20)    NOT NULL,
    item_number       NUMBER(4)       NOT NULL,
    item_description  VARCHAR2(255)   NOT NULL,
    category_code     VARCHAR2(20),                     -- NEW: replaces magic-digit parsing of item_number
    creation_date     TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    created_by        VARCHAR2(100)   DEFAULT 'SYSTEM',
    updated_date      TIMESTAMP,
    updated_by        VARCHAR2(100),
    in_use            NUMBER(1)       DEFAULT 1 NOT NULL,
    version_no        NUMBER(10)      DEFAULT 0 NOT NULL,
    CONSTRAINT uq_food_mst_code   UNIQUE (item_code),
    CONSTRAINT uq_food_mst_number UNIQUE (item_number),
    CONSTRAINT chk_food_in_use    CHECK (in_use IN (0,1)),
    CONSTRAINT chk_item_number    CHECK (item_number BETWEEN 1000 AND 5999)
);

COMMENT ON COLUMN FOO_FOOD_MST.item_number IS '4-digit code: 1st=category(1-5), 2nd=type(1-2), 3rd-4th=item(00-99)';

-- FOO_COST_SHEET: Item Pricing with History
CREATE TABLE FOO_COST_SHEET (
    cost_id         NUMBER(10)    DEFAULT FOO_COST_SHEET_SEQ.NEXTVAL PRIMARY KEY,
    item_id         NUMBER(10)    NOT NULL,
    cost            NUMBER(10,2)  NOT NULL,
    is_active       NUMBER(1)     DEFAULT 1 NOT NULL,
    creation_date   TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    inactive_date   TIMESTAMP,
    created_by      VARCHAR2(100) DEFAULT 'SYSTEM',
    -- virtual column emulates PG's partial unique index (WHERE is_active = TRUE)
    active_item_id  NUMBER(10) GENERATED ALWAYS AS (CASE WHEN is_active = 1 THEN item_id END) VIRTUAL,
    CONSTRAINT fk_cost_sheet_item FOREIGN KEY (item_id) REFERENCES FOO_FOOD_MST(item_id),
    CONSTRAINT chk_cost_positive  CHECK (cost > 0),
    CONSTRAINT chk_cost_active    CHECK (is_active IN (0,1))
);

CREATE UNIQUE INDEX UQ_ACTIVE_COST_PER_ITEM ON FOO_COST_SHEET (active_item_id);


--------------------------------------------------------------------------------
-- 3: Triggers
-- DEPENDS ON- 2: Tables
--------------------------------------------------------------------------------

-- Auto-deactivate old cost sheets when a new active one is inserted/updated
CREATE OR REPLACE TRIGGER FOO_DEACTIVATE_OLD_COST_TRG
    BEFORE INSERT OR UPDATE ON FOO_COST_SHEET
    FOR EACH ROW
    WHEN (NEW.is_active = 1)
BEGIN
    UPDATE FOO_COST_SHEET
       SET is_active = 0,
           inactive_date = SYSTIMESTAMP
     WHERE item_id = :NEW.item_id
       AND is_active = 1
       AND cost_id != NVL(:NEW.cost_id, -1);
END;
/



--------------------------------------------------------------------------------
-- 4: Views
-- DEPENDS ON- 2: Tables
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW FOO_ACTIVE_MENU_V AS
SELECT f.item_id, f.item_code, f.item_number, f.item_description, f.category_code, c.cost
  FROM FOO_FOOD_MST f, FOO_COST_SHEET c 
 WHERE f.item_id = c.item_id AND c.is_active = 1
 AND f.in_use = 1;

CREATE OR REPLACE VIEW FOO_COST_HISTORY_V AS
SELECT c.cost_id, f.item_code, f.item_description, c.cost, c.is_active,
       c.creation_date, c.inactive_date
  FROM FOO_COST_SHEET c, FOO_FOOD_MST f
  WHERE f.item_id = c.item_id
 ORDER BY f.item_code, c.creation_date DESC;
--------------------------------------------------------------------------------
-- MODULE: FOO (Menu / Food Master)
-- FILE:   05_sample_data.sql
-- DEPENDS ON: 02_tables.sql, 03_triggers.sql
--------------------------------------------------------------------------------

INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('B01', 1101, 'Idli', 'BREAKFAST');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('B02', 1102, 'Dosa', 'BREAKFAST');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('B03', 1103, 'Poha', 'BREAKFAST');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('B04', 1104, 'Upma', 'BREAKFAST');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('B05', 1105, 'Paratha', 'BREAKFAST');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('B06', 1201, 'Egg Omelette', 'BREAKFAST');

INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L01', 2101, 'Dal Rice', 'LUNCH');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L02', 2102, 'Roti Sabji', 'LUNCH');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L03', 2103, 'Chole Bhature', 'LUNCH');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L04', 2104, 'Paneer Curry', 'LUNCH');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L05', 2201, 'Chicken Biryani', 'LUNCH');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L06', 2202, 'Chicken Tikka', 'LUNCH');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('L07', 2203, 'Fish Curry', 'LUNCH');

INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('S01', 3101, 'Samosa', 'SNACKS');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('S02', 3102, 'Sandwich', 'SNACKS');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('S03', 3103, 'Pakora', 'SNACKS');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('S04', 3104, 'Biscuits', 'SNACKS');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('S05', 3201, 'Chicken Roll', 'SNACKS');

INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('BV01', 4101, 'Tea', 'BEVERAGES');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('BV02', 4102, 'Coffee', 'BEVERAGES');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('BV03', 4103, 'Cold Drink', 'BEVERAGES');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('BV04', 4104, 'Lassi', 'BEVERAGES');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('BV05', 4105, 'Juice', 'BEVERAGES');

INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('D01', 5101, 'Gulab Jamun', 'DESSERTS');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('D02', 5102, 'Ice Cream', 'DESSERTS');
INSERT INTO FOO_FOOD_MST (item_code, item_number, item_description, category_code) VALUES ('D03', 5103, 'Kheer', 'DESSERTS');

INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 30.00  FROM FOO_FOOD_MST WHERE item_code = 'B01';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 40.00  FROM FOO_FOOD_MST WHERE item_code = 'B02';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 35.00  FROM FOO_FOOD_MST WHERE item_code = 'B03';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 30.00  FROM FOO_FOOD_MST WHERE item_code = 'B04';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 40.00  FROM FOO_FOOD_MST WHERE item_code = 'B05';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 50.00  FROM FOO_FOOD_MST WHERE item_code = 'B06';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 60.00  FROM FOO_FOOD_MST WHERE item_code = 'L01';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 50.00  FROM FOO_FOOD_MST WHERE item_code = 'L02';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 80.00  FROM FOO_FOOD_MST WHERE item_code = 'L03';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 120.00 FROM FOO_FOOD_MST WHERE item_code = 'L04';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 180.00 FROM FOO_FOOD_MST WHERE item_code = 'L05';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 150.00 FROM FOO_FOOD_MST WHERE item_code = 'L06';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 140.00 FROM FOO_FOOD_MST WHERE item_code = 'L07';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 20.00  FROM FOO_FOOD_MST WHERE item_code = 'S01';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 40.00  FROM FOO_FOOD_MST WHERE item_code = 'S02';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 25.00  FROM FOO_FOOD_MST WHERE item_code = 'S03';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 10.00  FROM FOO_FOOD_MST WHERE item_code = 'S04';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 60.00  FROM FOO_FOOD_MST WHERE item_code = 'S05';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 10.00  FROM FOO_FOOD_MST WHERE item_code = 'BV01';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 15.00  FROM FOO_FOOD_MST WHERE item_code = 'BV02';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 25.00  FROM FOO_FOOD_MST WHERE item_code = 'BV03';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 30.00  FROM FOO_FOOD_MST WHERE item_code = 'BV04';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 35.00  FROM FOO_FOOD_MST WHERE item_code = 'BV05';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 40.00  FROM FOO_FOOD_MST WHERE item_code = 'D01';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 50.00  FROM FOO_FOOD_MST WHERE item_code = 'D02';
INSERT INTO FOO_COST_SHEET (item_id, cost) SELECT item_id, 45.00  FROM FOO_FOOD_MST WHERE item_code = 'D03';

COMMIT;