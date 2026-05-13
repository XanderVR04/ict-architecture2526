const express = require('express');
const { Client } = require('pg');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(express.json());
app.use(express.static('public'));

const client = new Client({
    user: 'user',
    host: 'db',
    database: 'eventstore',
    password: 'password',
    port: 5432,
});

async function initDB() {
    let retries = 5;
    while (retries > 0) {
        try {
            await client.connect();
            console.log("✅ Connected to PostgreSQL");
            break;
        } catch (err) {
            console.log("⏳ Waiting for database...");
            retries -= 1;
            await new Promise(res => setTimeout(res, 2000));
        }
    }

    // Create sample documents if none exist
    try {
        const res = await client.query('SELECT count(*) FROM documents');
        if (parseInt(res.rows[0].count) === 0) {
            const sampleDocs = [
                { title: 'Magna Carta', author: 'Onbekend', document_type: 'Historisch', classification: 'Nationaal' },
                { title: 'Grondwet Koninkrijk der Nederlanden', author: 'Staten-Generaal', document_type: 'Wetgeving', classification: 'Grondwet' },
                { title: 'Treaty of Westphalia', author: 'Verschillende vorsten', document_type: 'Verdrag', classification: 'Internationaal' }
            ];

            for (const doc of sampleDocs) {
                const docId = uuidv4();
                await client.query(`
                    INSERT INTO documents (id, title, author, document_type, classification, status)
                    VALUES ($1, $2, $3, $4, $5, 'active')
                `, [docId, doc.title, doc.author, doc.document_type, doc.classification]);

                await client.query(`
                    INSERT INTO document_events (document_id, event_type, payload)
                    VALUES ($1, $2, $3)
                `, [docId, 'DocumentCreated', JSON.stringify({ title: doc.title, author: doc.author, document_type: doc.document_type, classification: doc.classification })]);
            }
            console.log("=> Sample documents created.");
        }
    } catch (e) {
        console.error("Failed to initialize documents:", e);
    }
}

initDB();

// Get all documents with optional filters
app.get('/api/documents', async (req, res) => {
    try {
        const { search, type, classification, status } = req.query;
        let query = 'SELECT * FROM documents WHERE 1=1';
        const params = [];

        if (search) {
            params.push(`%${search}%`);
            query += ` AND (title ILIKE $${params.length} OR author ILIKE $${params.length})`;
        }
        if (type) {
            params.push(type);
            query += ` AND document_type = $${params.length}`;
        }
        if (classification) {
            params.push(classification);
            query += ` AND classification = $${params.length}`;
        }
        if (status) {
            params.push(status);
            query += ` AND status = $${params.length}`;
        }

        query += ' ORDER BY created_at DESC';
        const result = await client.query(query, params);
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get document types and classifications for filters
app.get('/api/filters', async (req, res) => {
    try {
        const types = await client.query('SELECT DISTINCT document_type FROM documents WHERE document_type IS NOT NULL');
        const classifications = await client.query('SELECT DISTINCT classification FROM documents WHERE classification IS NOT NULL');
        res.json({
            types: types.rows.map(r => r.document_type),
            classifications: classifications.rows.map(r => r.classification)
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Create new document
app.post('/api/documents', async (req, res) => {
    try {
        const { title, author, document_type, classification } = req.body;
        const docId = uuidv4();

        await client.query(`
            INSERT INTO documents (id, title, author, document_type, classification, status)
            VALUES ($1, $2, $3, $4, $5, 'active')
        `, [docId, title, author || 'Onbekend', document_type, classification]);

        await client.query(`
            INSERT INTO document_events (document_id, event_type, payload)
            VALUES ($1, $2, $3)
        `, [docId, 'DocumentCreated', JSON.stringify({ title, author, document_type, classification })]);

        res.json({ id: docId, success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Reconstruct single document by applying all events
app.get('/api/documents/:id', async (req, res) => {
    try {
        const { id } = req.params;

        // Get current state from documents table
        const docResult = await client.query('SELECT * FROM documents WHERE id = $1', [id]);
        if (docResult.rows.length === 0) {
            return res.status(404).json({ error: 'Document not found' });
        }

        const doc = docResult.rows[0];

        // Get all events for this document
        const eventsResult = await client.query(`
            SELECT event_type, payload, created_at 
            FROM document_events 
            WHERE document_id = $1 
            ORDER BY id ASC
        `, [id]);

        // Build current state from events
        let documentState = {
            id: doc.id,
            title: doc.title,
            author: doc.author,
            document_type: doc.document_type,
            classification: doc.classification,
            status: doc.status,
            annotations: [],
            history: eventsResult.rows
        };

        eventsResult.rows.forEach(row => {
            if (row.event_type === 'AnnotationAdded') {
                documentState.annotations.push(row.payload);
            }
            if (row.event_type === 'MetadataUpdated') {
                documentState = { ...documentState, ...row.payload };
            }
        });

        res.json(documentState);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get audit trail for a document
app.get('/api/documents/:id/history', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await client.query(`
            SELECT id, event_type, payload, created_at 
            FROM document_events 
            WHERE document_id = $1 
            ORDER BY id DESC
        `, [id]);
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Add event to a document
app.post('/api/documents/:id/events', async (req, res) => {
    try {
        const { id } = req.params;
        const { event_type, payload } = req.body;

        await client.query(`
            INSERT INTO document_events (document_id, event_type, payload)
            VALUES ($1, $2, $3)
        `, [id, event_type, payload]);

        // Update document status if deleted
        if (event_type === 'DocumentDeleted') {
            await client.query('UPDATE documents SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2', ['archived', id]);
        }

        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Update document metadata
app.put('/api/documents/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { title, author, document_type, classification } = req.body;

        const updates = [];
        const params = [];
        let paramIndex = 1;

        if (title) { updates.push(`title = $${paramIndex++}`); params.push(title); }
        if (author) { updates.push(`author = $${paramIndex++}`); params.push(author); }
        if (document_type) { updates.push(`document_type = $${paramIndex++}`); params.push(document_type); }
        if (classification) { updates.push(`classification = $${paramIndex++}`); params.push(classification); }

        if (updates.length > 0) {
            updates.push(`updated_at = CURRENT_TIMESTAMP`);
            params.push(id);
            await client.query(`UPDATE documents SET ${updates.join(', ')} WHERE id = $${paramIndex}`, params);

            await client.query(`
                INSERT INTO document_events (document_id, event_type, payload)
                VALUES ($1, $2, $3)
            `, [id, 'MetadataUpdated', JSON.stringify({ title, author, document_type, classification })]);
        }

        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.listen(3000, () => {
    console.log('🚀 National Archive running on http://localhost:3000');
});