CREATE TABLE account (
    account_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    username             TEXT UNIQUE NOT NULL,
    password             TEXT NOT NULL,
    email                TEXT NOT NULL,
    created_timestamp    INTEGER NOT NULL,
    last_timestamp       INTEGER,
    banned_timestamp     INTEGER
);

CREATE TABLE character (
    char_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id           INTEGER NOT NULL,
    nickname             TEXT UNIQUE NOT NULL,
    created_timestamp    INTEGER NOT NULL,
    last_timestamp       INTEGER,
    total_time           INTEGER,
    pos_x                INTEGER,
    pos_y                INTEGER,
    pos_map              TEXT,
    respawn_x            INTEGER,
    respawn_y            INTEGER,
    respawn_map          TEXT,
    FOREIGN KEY (account_id) REFERENCES account(account_id)
);

CREATE TABLE trait (
    char_id              INTEGER PRIMARY KEY,
    hairstyle            INTEGER,
    haircolor            INTEGER,
    race                 INTEGER,
    skin                 INTEGER,
    gender               INTEGER,
    shape                TEXT,
    spirit               TEXT,
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE attribute (
    char_id              INTEGER PRIMARY KEY,
    strength             INTEGER,
    vitality             INTEGER,
    agility              INTEGER,
    endurance            INTEGER,
    concentration        INTEGER,
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE stat (
    char_id              INTEGER PRIMARY KEY,
    level                INTEGER,
    experience           INTEGER,
    gp                   INTEGER,
    health               INTEGER,
    mana                 INTEGER,
    stamina              INTEGER,
    karma                INTEGER,
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE equipment (
    char_id              INTEGER PRIMARY KEY,
    weapon               INTEGER,
    shield               INTEGER,
    ammunition           INTEGER,
    arms                 INTEGER,
    chest                INTEGER,
    face                 INTEGER,
    feet                 INTEGER,
    head                 INTEGER,
    legs                 INTEGER,
    accessory1           INTEGER,
    accessory2           INTEGER,
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE item (
    item_id              INTEGER NOT NULL,
    char_id              INTEGER NOT NULL,
    count                INTEGER NOT NULL,
	storage              INTEGER NOT NULL CHECK (storage IN (0, 1)),
    PRIMARY KEY (char_id, item_id, storage),
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE skill (
    char_id              INTEGER NOT NULL,
    skill_id             INTEGER NOT NULL,
    level                INTEGER,
    PRIMARY KEY (char_id, skill_id),
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE bestiary (
    char_id              INTEGER NOT NULL,
    mob_id               INTEGER NOT NULL,
    killed_count         INTEGER DEFAULT 0,
    PRIMARY KEY (char_id, mob_id),
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE TABLE quest (
    char_id              INTEGER NOT NULL,
    quest_id             INTEGER NOT NULL,
    state                INTEGER NOT NULL,
    PRIMARY KEY (char_id, quest_id),
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

CREATE INDEX idx_character_account ON character(account_id);
CREATE INDEX idx_storage_character ON storage(char_id);
CREATE INDEX idx_item_storage ON item(storage_id);

CREATE TRIGGER trg_account_delete
AFTER DELETE ON account
FOR EACH ROW
BEGIN
    DELETE FROM character WHERE account_id = OLD.account_id;
END;

CREATE TRIGGER trg_character_new
AFTER INSERT ON character
FOR EACH ROW
BEGIN
    INSERT INTO trait (char_id, hairstyle, haircolor, race, skin, gender, shape, spirit)
    VALUES (NEW.char_id, 0, 0, 0, 0, 0, 'Default Entity', 'Default Entity');

    INSERT INTO attribute (char_id, strength, vitality, agility, endurance, concentration)
    VALUES (NEW.char_id, 0, 0, 0, 0, 0);

    INSERT INTO stat (char_id, level, experience, gp, health, mana, stamina, karma)
    VALUES (NEW.char_id, 1, 0, 0, 1, 1, 1, 0);

    INSERT INTO equipment (char_id, weapon, shield, ammunition, arms, chest, face, feet, head, legs, accessory1, accessory2)
    VALUES (NEW.char_id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
END

CREATE TRIGGER trg_character_delete
AFTER DELETE ON character
FOR EACH ROW
BEGIN
    DELETE FROM trait WHERE char_id = OLD.char_id;
    DELETE FROM attribute WHERE char_id = OLD.char_id;
    DELETE FROM stat WHERE char_id = OLD.char_id;
    DELETE FROM equipment WHERE char_id = OLD.char_id;
END;