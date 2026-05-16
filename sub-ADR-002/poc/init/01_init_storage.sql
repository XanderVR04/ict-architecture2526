-- init/01_init_storage.sql
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    role_id INTEGER DEFAULT 1, -- Toegevoegd voor RBAC (1=Publiek, 2=Onderzoeker, 3=Archivaris)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_versions (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    minio_key VARCHAR(512) NOT NULL,
    version_number INTEGER NOT NULL,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64) -- Groot genoeg voor SHA-256 hashes
);

CREATE TABLE IF NOT EXISTS audit_trail (
    id SERIAL PRIMARY KEY,
    action VARCHAR(50),
    document_id INTEGER,
    user_id VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);