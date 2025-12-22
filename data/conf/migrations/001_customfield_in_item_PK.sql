BEGIN TRANSACTION;

CREATE TABLE migration (
    version INTEGER NOT NULL
);

INSERT INTO migration VALUES (0);

CREATE TABLE item_new (
    item_id     INTEGER NOT NULL,
    char_id     INTEGER NOT NULL,
    count       INTEGER NOT NULL,
    storage     INTEGER NOT NULL CHECK(storage IN (0, 1)),
    customfield TEXT NOT NULL,
    PRIMARY KEY (char_id, item_id, storage, customfield),
    FOREIGN KEY (char_id) REFERENCES character(char_id)
);

INSERT INTO item_new (item_id, char_id, count, storage, customfield)
SELECT item_id, char_id, count, storage, customfield
FROM item;

DROP TABLE item;

ALTER TABLE item_new RENAME TO item;

COMMIT;