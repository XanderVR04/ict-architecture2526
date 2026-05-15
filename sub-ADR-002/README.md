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
