# Technische Handleiding: Inrichting PoC Archiefsysteem

Deze handleiding beschrijft de stappen die zijn ondernomen om de Proof of Concept (PoC) omgeving in te richten op het Docker Swarm cluster, de data te laden en de integriteit te verifiëren.

---

## 1. Infrastructuur Opstarten (Docker Swarm)

De gehele stack (PostgreSQL, MinIO en pgAdmin) wordt uitgerold als een Docker Stack. Dit garandeert dat de services binnen het overlay-netwerk (`adr2_default`) veilig met elkaar kunnen communiceren.

**Commando's:**

```bash
# Zorg dat je in de poc/-map van sub-ADR-002 staat
# Start de stack op het cluster
docker stack deploy -c poc.yml poc-2
```

---

## 2. Object Storage Inrichten (MinIO)

De fysieke bestanden (blobs) worden opgeslagen in MinIO. Dit ontlast de database en zorgt voor een schaalbaar systeem.

1. Navigeer naar de MinIO Console via: **http://10.164.10.29:9001**
2. Log in met de credentials: `admin` / `password123`.
3. Maak een nieuwe bucket aan met de naam: `archief-scans`.
4. Upload de test-PDF-bestanden naar deze bucket:
   - `001 - Inleiding Docker Swarm.pdf`
   - `002 - Vervolg Docker Swarm.pdf`
   - `003 - Software architectuur en message queues.pdf`
   - `004 - Software architectuur verantwoorden.pdf`
   - `005 - Gelaagde stijl en C4-model.pdf`

---

## 3. Database Initialisatie en Data Import (pgAdmin)

Navigeer naar pgAdmin via: **http://10.164.10.29:8080** (Login: `admin@test.com` / `password123`).

**Verbinding maken:**

- Voeg een nieuwe server toe.
- Hostnaam: `postgres` (gebruik de servicenaam, niet het IP, voor interne communicatie binnen het Docker netwerk).
- Gebruiker: `user` / Wachtwoord: `password123`.

Voer in de Query Tool het volgende SQL-script uit om de metadata te koppelen aan de bestanden in MinIO:

```sql
-- Stap 1: Tabellen opschonen voor een zuivere start
TRUNCATE audit_trail, document_versions, documents RESTART IDENTITY CASCADE;

-- Stap 2: Document metadata registreren (1=Publiek, 2=Onderzoeker, 3=Archivaris)
INSERT INTO documents (id, title, original_filename, role_id) VALUES
(1, 'Inleiding Docker Swarm', '001 - Inleiding Docker Swarm.pdf', 1),
(2, 'Vervolg Docker Swarm', '002 - Vervolg Docker Swarm.pdf', 1),
(3, 'Software architectuur en message queues', '003 - Software architectuur en message queues.pdf', 2),
(4, 'Software architectuur verantwoorden', '004 - Software architectuur verantwoorden.pdf', 2),
(5, 'Gelaagde stijl en C4-model', '005 - Gelaagde stijl en C4-model.pdf', 3);

-- Stap 3: Koppeling leggen naar de Blobs in MinIO inclusief SHA-256 Checksums
INSERT INTO document_versions (document_id, minio_key, version_number, checksum) VALUES
(1, 'archief-scans/001 - Inleiding Docker Swarm.pdf', 1, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
(2, 'archief-scans/002 - Vervolg Docker Swarm.pdf', 1, '8479373c7075e7a96409949d0ed977066620cd2c4dce45315357ef3632616084'),
(3, 'archief-scans/003 - Software architectuur en message queues.pdf', 1, '7d1a54127b222518f353e547c6e6191991732cd92372079017616cd2803023e3'),
(4, 'archief-scans/004 - Software architectuur verantwoorden.pdf', 1, '516f39e6a97127e530932230353c907149021e1494918e97491763914a191244'),
(5, 'archief-scans/005 - Gelaagde stijl en C4-model.pdf', 1, 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3');

-- Stap 4: Audit trail invullen voor onweerlegbaarheid
INSERT INTO audit_trail (action, document_id, user_id) VALUES
('INITIAL_UPLOAD', 1, 'NickTheArchivist'),
('INITIAL_UPLOAD', 2, 'NickTheArchivist'),
('INITIAL_UPLOAD', 3, 'NickTheArchivist'),
('INITIAL_UPLOAD', 4, 'NickTheArchivist'),
('INITIAL_UPLOAD', 5, 'NickTheArchivist');
```

---

## 4. Validatie en Demonstratie

Voer de volgende queries uit om de integratie aan te tonen:

**Overzicht van het archief (Metadata + Opslaglocatie + Integriteit):**

```sql
SELECT d.title, d.role_id, v.minio_key AS "opslag_pad", v.checksum
FROM documents d
JOIN document_versions v ON d.id = v.document_id;
```

**Controleren van het audit-logboek:**

```sql
SELECT action, document_id, timestamp, user_id
FROM audit_trail
ORDER BY timestamp DESC;
```

---

## 5. Ontwerpkeuzes in de PoC

- **Data Integriteit**: Gebruik van SHA-256 hashes om aan te tonen dat de bestanden in de Object Store niet ongemerkt gewijzigd kunnen worden.
- **Security**: Implementatie van een `role_id` op documentniveau als basis voor Role-Based Access Control.
- **Orchestratie**: Gebruik van Docker Swarm voor container management, wat de overstap naar een productie-omgeving vereenvoudigt.

---

## 6. Opruimen

```bash
docker stack rm poc-2
```
