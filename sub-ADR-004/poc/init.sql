-- Document registry (current state cache)
CREATE TABLE documents (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255),
    document_type VARCHAR(100),
    classification VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- The append-only event store (immutable audit trail)
CREATE TABLE document_events (
    id SERIAL PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES documents(id),
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient queries
CREATE INDEX idx_document_events_document_id ON document_events(document_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_classification ON documents(classification);
CREATE INDEX idx_documents_title ON documents(title);