# ADR 1: Architectuur voor Documentopslag en Integriteit in PoC

## Context

Voor het digitale archiefsysteem (PoC) moet een schaalbare methode worden gevonden om binaire bestanden (scans) en bijbehorende metadata op te slaan. Er zijn eisen gesteld aan data-integriteit (bewijs dat bestanden ongewijzigd zijn) en role-based access control (RBAC).

De volgende uitdagingen zijn geïdentificeerd:

1. Database-bloat: Het opslaan van grote PDF's in PostgreSQL maakt back-ups en queries traag.
2. Integriteit: Hoe garanderen we dat een bestand na 10 jaar nog exact hetzelfde is?
3. Container Orchestration: Hoe zorgen we voor hoge beschikbaarheid en schaalbaarheid?

## Besluit

We hebben besloten om de volgende architectuur te hanteren:

1.  **Separation of Concerns (Opslag)**: Metadata wordt opgeslagen in een relationele database (**PostgreSQL**), terwijl de fysieke bestanden worden opgeslagen in een S3-compatibele Object Store (**MinIO**).
2.  **Bit-level Integrity**: Elke documentversie krijgt een verplichte **SHA-256 checksum** in de database.
3.  **Toegangscontrole**: Een `role_id` wordt op documentniveau toegevoegd aan de metadata-tabel om RBAC in de toekomst af te dwingen.
4.  **Container Orchestration**: Deployment via **Docker Swarm** voor hoge beschikbaarheid en replicatie.

## Onderbouwing

### Waarom Object Storage (MinIO) boven Database (BLOB)?

- **Schaalbaarheid**: MinIO kan eenvoudiger horizontaal schalen dan een SQL-database.
- **Performance**: De database blijft "lean". Queries op metadata zijn razendsnel omdat ze niet gehinderd worden door zware binaire data.
- **S3-compatibiliteit**: Standardoiseert de API voor toekomstige integraties.

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
