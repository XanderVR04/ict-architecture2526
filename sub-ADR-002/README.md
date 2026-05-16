# Metadata Management en Object Storage PoC

Dit project dient als Proof of Concept (PoC) voor een schaalbaar archiefsysteem, ontwikkeld voor een onderzoeksafdeling geschiedenis. Het doel is om aan te tonen hoe metadata en fysieke bestanden (blobs) gescheiden kunnen worden opgeslagen om de prestaties en integriteit van het archief te waarborgen binnen een Docker Swarm cluster.

---

## 1. Architectuur & Design Beslissingen

De oplossing is gebaseerd op een gescheiden opslagstrategie waarbij data-integriteit en stabiliteit centraal staan.

- **PostgreSQL**: De Metadata Store voor documenteigenschappen, versienummers en SHA-256 integriteit-hashes.
- **MinIO**: De Object Store voor de daadwerkelijke scans en documenten (blobs).
- **pgAdmin**: Beheerinterface voor de PostgreSQL database.

### Belangrijke aanpassingen in de PoC-fase

Tijdens de ontwikkeling zijn de volgende keuzes gemaakt om de stabiliteit binnen de Docker Swarm-omgeving te garanderen:

1. **Named Volumes**: In plaats van bind mounts gebruiken we Docker-managed volumes (`minio_volume`, `postgres_volume`). Dit voorkomt permissie-fouten en "Rejected" states bij het deployen op verschillende cluster-nodes.
2. **Hardcoded Environment Variables**: Om initialisatie-fouten (zoals lege admin-credentials) te voorkomen, zijn de omgevingsvariabelen direct in de `stack.yml` gedefinieerd voor deze PoC.

Voor een gedetailleerde onderbouwing, zie de **[ADR.md](./ADR.md)**.

---

## 2. Gegevensstructuur

Het systeem gebruikt drie kern-tabellen in PostgreSQL om de data-integriteit en veiligheid te bewaken:

1. **documents**: Bevat de primaire metadata, de originele bestandsnaam en de `role_id` voor toegangscontrole.
2. **document_versions**: Beheert de koppeling naar de fysieke bestanden in MinIO via een unieke key en bevat de SHA-256 checksum voor integriteitscontrole.
3. **audit_trail**: Logt elke actie (zoals uploads en wijzigingen) voor volledige traceerbaarheid.

---

## 3. Deployment (Docker Swarm)

De omgeving draait op een Docker Swarm cluster. Voor de huidige stabiliteit is de stack gepind op de manager-node (`2526-ICT-arch-nick-reul`).

### De Stack opstarten

Gebruik de volgende commando's in de terminal:

```bash
# Eventuele oude stack verwijderen
docker stack rm adr2

# De stack deployen met de geoptimaliseerde configuratie
docker stack deploy -c stack.yml adr2
```

### Toegang tot de Services (Node: 10.164.10.29)

| Service           | URL                      | Credentials                         |
| ----------------- | ------------------------ | ----------------------------------- |
| **pgAdmin4**      | http://10.164.10.29:8080 | `admin@test.com` / `password123`    |
| **MinIO Console** | http://10.164.10.29:9001 | `admin` / `password123`             |
| **PostgreSQL**    | 10.164.10.29:5432        | `user` / `password123` (DB: `mydb`) |

> **Configuratie tip:** Gebruik in pgAdmin de hostnaam `postgres` (internal Docker DNS) om verbinding te maken met de database.

---

## 4. Visualisatie (C4-Model)

De structuur van dit project is inzichtelijk gemaakt via C4-diagrammen in Structurizr DSL:

- **[C4-POC/](./C4-POC/)**: Diagrammen van de huidige Docker Swarm-opzet.
- **[C4-POC-toekomstig/](./C4-POC-toekomstig/)**: Blauwdruk voor de volledige applicatie inclusief Frontend SPA en Backend API.

---

## 5. Technische Specificaties

- **Orchestration**: Docker Swarm
- **Images**: `postgres:15-alpine`, `minio/minio:latest`, `dpage/pgadmin4:latest`
- **Storage**: Named Volumes met de `local` driver.
- **Netwerk**: Overlay netwerk (`adr2_default`).





# ADR 1: Architectuur voor Documentopslag en Integriteit in PoC

## Context

Voor het digitale archiefsysteem (PoC) moet een schaalbare methode worden gevonden om binaire bestanden (scans) en bijbehorende metadata op te slaan. Er zijn eisen gesteld aan data-integriteit (bewijs dat bestanden ongewijzigd zijn) en role-based access control (RBAC).

De volgende uitdagingen zijn geïdentificeerd:

1. Database-bloat: Het opslaan van grote PDF's in PostgreSQL maakt back-ups en queries traag.
2. Integriteit: Hoe garanderen we dat een bestand na 10 jaar nog exact hetzelfde is?
3. Security: Hoe beperken we toegang tot specifieke documenten?
4. Container Orchestration: Hoe zorgen we voor hoge beschikbaarheid en schaalbaarheid?

## Besluit

We hebben besloten om de volgende architecturale beslissingen te hanteren:

1.  **Separation of Concerns (Opslag)**: Metadata wordt opgeslagen in een relationele database (**PostgreSQL**), terwijl de fysieke bestanden worden opgeslagen in een S3-compatibele Object Store (**MinIO**).
2.  **Bit-level Integrity**: Elke documentversie krijgt een verplichte **SHA-256 checksum** in de database.
3.  **Toegangscontrole**: Een `role_id` wordt op documentniveau toegevoegd aan de metadata-tabel om RBAC in de toekomst af te dwingen.
4.  **Container Orchestration**: Deployment via **Docker Swarm** voor hoge beschikbaarheid en replicatie.

## Onderbouwing

### Waarom Object Storage (MinIO) boven Database (BLOB)?

- **Schaalbaarheid**: MinIO kan eenvoudiger horizontaal schalen dan een SQL-database.
- **Performance**: De database blijft "lean". Queries op metadata zijn razendsnel omdat ze niet gehinderd worden door zware binaire data.
- **S3-compatibiliteit**: Standardiseert de API voor toekomstige integraties.

### Waarom SHA-256 Checksums?

- Voor een archief is "onweerlegbaarheid" cruciaal. Door een hash op te slaan bij de metadata, kan het systeem op elk moment verifiëren of de blob in MinIO nog integer is door een nieuwe hash-berekening te vergelijken met de opgeslagen waarde.
- SHA-256 biedt voldoende collision resistance voor archiefdoeleinden.

### Waarom Metadata-driven RBAC?

- Door de `role_id` direct in de `documents`-tabel op te nemen, leggen we het fundament voor beveiliging bij de bron. Dit voorkomt dat ongeautoriseerde gebruikers via de API/applicatie zelfs maar het bestaan of de locatie van een bestand kunnen opvragen.

### Waarom Docker Swarm?

- **Hoge Beschikbaarheid**: Services worden gerepliceerd over meerdere nodes.
- **Load Balancing**: Ingebouwde load balancing tussen replicas.
- **Rolling Updates**: Veilige updates zonder downtime.
- **Secret Management**: Externe secrets worden beheerd door Docker Swarm zelf.

## Implementatie Details

### Swarm Cluster Configuratie

- **Nodes**: 3 worker nodes (2526-ICT-arch-nick-reul, 2526-ICT-arch-aron-bauwens, 2526-ICT-arch-xander-vanraemdonck)
- **Manager**: 2526-ICT-arch-nick-reul
- **Network**: Overlay network `adr2_default` met driver `overlay`

### Services

| Service  | Image              | Replicas |
| -------- | ------------------ | -------- |
| minio    | minio/minio        | 1        |
| postgres | postgres:15-alpine | 1        |
| pgadmin  | dpage/pgadmin4     | 1        |

### Volumes

Gebruik van named volumes met `driver: local` voor persistente opslag:

- `adr2_minio_volume`: Object storage data
- `adr2_postgres_volume`: Database data
- `adr2_pgadmin_volume`: pgadmin data

## Gevolgen

### Positief

- Betere performance en schaalbaarheid.
- Bewijsbare integriteit van archiefstukken (essentieel voor juridische validiteit).
- Hoge beschikbaarheid via Swarm replicatie.
- Duidelijk fundament voor verdere ontwikkeling van een front-end/back-end.
- Veilige credentials management via secrets.

### Negatief/Aandachtspunten

- **Consistentie-risico**: Er bestaat een theoretische kans dat een record in de DB wordt aangemaakt maar de upload naar MinIO faalt (of andersom). In de productiefase moet dit worden afgevangen met transactie-management of een cleanup-service.
- **Complexiteit**: Er moeten twee systemen (DB en MinIO) worden geback-upt in plaats van één.
- **Node Failure**: Bij uitval van de PostgreSQL node kunnen writes tijdelijk niet beschikbaar zijn (single replica).
