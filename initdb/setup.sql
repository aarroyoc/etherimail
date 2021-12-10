CREATE TABLE person(
    id TEXT NOT NULL,
    access_key TEXT NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY(id)
);

CREATE TABLE mail(
    id SERIAL,
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    body TEXT NOT NULL,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY(id),
    FOREIGN KEY(to_address) REFERENCES person(id)
);