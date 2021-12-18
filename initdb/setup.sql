CREATE TABLE mail(
    id SERIAL,
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    body TEXT NOT NULL,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY(id)
);