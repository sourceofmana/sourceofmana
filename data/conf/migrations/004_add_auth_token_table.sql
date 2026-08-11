CREATE TABLE IF NOT EXISTS auth_token (
	token_hash TEXT NOT NULL,
	account_id INTEGER NOT NULL,
	ip_address TEXT NOT NULL,
	created_timestamp INTEGER NOT NULL DEFAULT 0,
	expires_timestamp INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY (account_id) REFERENCES account(account_id)
);
