# Document Archief Systeem - Data-integriteit en Versioning

## Projectbeschrijving

Dit project is een Proof of Concept (POC) voor de ICT Architecture projectopdracht. Het toont een **Document Archief Systeem** voor het digitaliseren en beheren van historische documenten, waarin de onschendbaarheid van historische data voorop staat.

Het systeem richt zich op onderzoekers en archivarissen die metadata bewerken, documenten raadplegen en annotaties toevoegen. De POC demonstreert het architectuurpatroon uit [ADR-004](README.md#adr-004-aanpak-voor-data-integriteit-en-versioning): Event Sourcing (Append-Only Log) met PostgreSQL.

---

## Architectuuroverzicht

De architectuur bestaat uit drie containers die samenwerken:

```
Gebruiker  -->  Web Applicatie        toegang tot interface (HTML5 / Vanilla JS)
Gebruiker  -->  Metadata Service       REST API voor events en projecties (Node.js / Express)
Metadata Service  -->  PostgreSQL       Append-Only Event Store + Read Model (PostgreSQL)
```

---

## C4 Diagrammen

De onderstaande diagrammen zijn opgesteld volgens het **C4-model** en opgebouwd met **Structurizr DSL**.

### Systeemcontextdiagram

![Systeemcontextdiagram](c4-model/system-context.png)

```structurizr
workspace "Document Archief" "Systeemcontext" {
    model {
        user = person "Onderzoeker / Archivaris" "Beheert metadata, annotaties en raadpleegt historische documenten."
        system = softwareSystem "Document Archief Systeem" "Digitaliseert en beheert historische documenten met volledige audit-integriteit."

        user -> system "Gebruikt voor beheer en onderzoek"
    }

    views {
        systemContext system "SystemContext" {
            include *
            autoLayout
        }
    }
}
```

### Containerdiagram

![Containerdiagram](c4-model/container.png)

```structurizr
workspace "Document Archief" "Container Diagram" {
    model {
        user = person "Onderzoeker / Archivaris" "Beheert metadata, annotaties en raadpleegt historische documenten."
        
        system = softwareSystem "Document Archief Systeem" {
            webApp = container "Web Applicatie" "Biedt de interface voor het bewerken van metadata en bekijken van documenten." "Vanilla JS / HTML5"
            metadataService = container "Metadata Management Service" "Verwerkt business logica, genereert events en bouwt projecties op." "Node.js / Express"
            database = container "PostgreSQL Database" "Fungeert als Event Store (append-only) en bevat het Read Model (huidige document status)." "PostgreSQL" "Database"
        }

        user -> webApp "Gebruikt"
        webApp -> metadataService "Verstuurt requests (HTTP/REST)"
        metadataService -> database "Schrijft events & Leest/Updatet Projecties"
    }

    views {
        container system "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Database" {
                shape Cylinder
                background #1565C0
                color #ffffff
            }
        }
    }
}
```

### Deployment diagram

![Deployment diagram](c4-model/deployment.png)

```structurizr
workspace "Document Archief" "Deployment Diagram" {
    model {
        system = softwareSystem "Document Archief Systeem" {
            webApp = container "Web Applicatie"
            metadataService = container "Metadata Management Service"
            database = container "PostgreSQL Database"
        }

        deploymentEnvironment "Productie / Test Cluster" {
            deploymentNode "User Computer" "Windows / macOS / Linux" "Client" {
                deploymentNode "Web Browser" "Chrome / Firefox / Edge" "Browser" {
                    containerInstance webApp
                }
            }

            deploymentNode "Docker Swarm Cluster" "Debian Linux" {
                deploymentNode "Manager Node" "Control & Compute plane" {
                    containerInstance metadataService
                    containerInstance database
                }
            }
        }
    }

    views {
        deployment system "Productie / Test Cluster" "Deployment" {
            include *
            autoLayout
        }

        styles {
            element "Client" {
                background #999999
            }
            element "Browser" {
                background #ffffff
            }
        }
    }
}
```

---

## Technologiestack

| Technologie          | Rol                                                   |
|---------------------|-------------------------------------------------------|
| Vanilla JS / HTML5  | Frontend webinterface                                 |
| Node.js / Express   | Metadata Management Service (REST API)                |
| PostgreSQL          | Event Store (append-only) + Read Model               |
| Docker Swarm        | Orkestratie van containers via een stack             |

---

## Mappenstructuur

```
sub-ADR-004/
├── README.md                                 # Dit bestand (overzicht en documentatie)
├── c4-model/                                 # C4-diagrammen (Structurizr DSL + afbeeldingen)
│   ├── system-context.dsl                    # Structurizr DSL - systeemcontextdiagram
│   ├── system-context.png                    # Visueel systeemcontextdiagram
│   ├── container.dsl                         # Structurizr DSL - containerdiagram
│   ├── container.png                         # Visueel containerdiagram
│   ├── deployment.dsl                        # Structurizr DSL - deploymentdiagram
│   └── deployment.png                        # Visueel deploymentdiagram
└── poc/                                      # Proof of Concept implementatie
    ├── server.js                             # Node.js backend met Event Sourcing logica
    ├── init.sql                              # Database schema voor de Event Store
    ├── poc.yaml                              # Docker Swarm stack definitie
    ├── package.json                          # Node.js dependencies
    ├── .env.example                          # Voorbeeld omgevingsvariabelen
    ├── public/
    │   └── index.html                        # Frontend interface voor de POC
    └── README.md                             # Opstartinstructies voor de POC
```

---

## POC

Alle instructies voor opstarten, testen en stoppen staan in [poc/README.md](poc/README.md).

---

## Documentatie

| Document                      | Beschrijving                                                    |
|-------------------------------|-----------------------------------------------------------------|
| [ADR-004](README.md)          | Architectuurbeslissing: Event Sourcing met PostgreSQL (MADR)   |

### Kernbeslissing

**[ADR-004](README.md)** beschrijft de keuze voor het Event Sourcing patroon om data-integriteit te waarborgen. De voornaamste redenen zijn:

- **Data-integriteit:** Elke wijziging wordt als immutable event opgeslagen; destructieve operaties zijn onmogelijk.
- **Auditability:** Volledige historie van elk document (van upload tot correcties) is te herleiden.
- **Versioning:** Out-of-the-box versiegeschiedenis van metadata en annotaties.

---

# ADR-004: Aanpak voor Data-integriteit en Versioning

> Dit ADR volgt het **MADR-formaat** (Markdown Architectural Decision Records, v3.0.0).
> Referentie: <https://adr.github.io/madr/>

**Status:** Accepted
**Datum:** 2026-05-07

---

## Context en Probleemstelling

Historische documenten zijn onvervangbaar en kritisch. Binnen het systeem moet te allen tijde worden vermeden dat data per ongeluk overschreven of verwijderd wordt ("geen dataverlies"). Tegelijk vereisen onderzoekers en archivarissen een volledige audit trail (wie heeft wat wanneer aangepast) en de mogelijkheid tot versioning van zowel metadata als annotaties.

In **ADR-002** (Gescheiden Opslagstrategie) is reeds de keuze gemaakt om een relationele database (PostgreSQL) in te zetten voor de verwerking van metadata. Om de data-integriteit binnen deze component te waarborgen zonder de complexiteit van de technologie-stack onnodig te vergroten, is een strategie nodig voor de manier waarop data wordt opgeslagen.

**Beslissingsvraag:** Hoe waarborgen we data-integriteit en versioning binnen PostgreSQL zonder onnodige complexiteit?

---

## Overwogen Opties

1. Klassieke CRUD (Create, Read, Update, Delete) met Audit Table
2. **Event Sourcing met PostgreSQL (Append-Only)** *(gekozen)*
3. Dedicated Event Store (bijv. EventStoreDB of Kafka)

---

## Beslissingsresultaat

**Gekozen optie: Event Sourcing met PostgreSQL (Append-Only)**

We kiezen ervoor om het **Event Sourcing (Append-Only Log) patroon** toe te passen binnen PostgreSQL voor het beheer van de metadata en document-wijzigingen.

In plaats van tabellen destructief aan te passen (`UPDATE` of `DELETE`), wordt elke wijziging in de levenscyclus van een document (bijv. `DocumentCreated`, `MetadataUpdated`, `AnnotationAdded`) opgeslagen als een onveranderlijk (immutable) nieuw "event" in een append-only tabel.

### Positieve gevolgen

- Strikte databeveiliging en integriteit; elke wijziging is traceerbaar
- Volledig inzicht in de levensloop van documenten (audit trail)
- Naadloze integratie met bestaande Node.js/PostgreSQL stack
- Out-of-the-box versioning van metadata en annotaties

### Negatieve gevolgen

- Complexiteit bij het bevragen van data (Projection Engine nodig)
- Noodzaak voor een gesynchroniseerd Read-model (CQRS)
- 'Eventual consistency' in de UI kan optreden

---

## Vergelijking van Opties

### Optie 1: Klassieke CRUD met Audit Table

| | |
|---|---|
| **Voordeel** | Eenvoudig op te zetten; queries voor de huidige staat zijn zeer performant |
| **Nadeel** | Data overschrijving op de hoofdtabel riskeert dataverlies; audit logs zijn vaak geen 'source of truth' |

### Optie 2: Event Sourcing met PostgreSQL (Append-Only) ✓

| | |
|---|---|
| **Voordeel** | 100% data-integriteit; events zijn immutable; out-of-the-box audit log en perfecte versioning; gebruikt bestaande PostgreSQL technologie |
| **Nadeel** | Bevragen van huidige staat vereist complexere code (Projection Engine) |

### Optie 3: Dedicated Event Store

| | |
|---|---|
| **Voordeel** | Afgestemd op extreem hoge writes en event-streams |
| **Nadeel** | Introduceert een nieuwe technologie en operationele overhead; niet gerechtvaardigd voor metadata volume |

---

## Rationale (link met driving characteristics)

De keuze voor Event Sourcing ondersteunt de kernkwaliteiten van het systeem:

- **Data-integriteit:** De onvervangbaarheid van historische documenten weegt het zwaarst. Het Event Sourcing patroon geeft de garantie dat elke tussenstap van een document (van eerste upload, door de OCR, tot de correcties van de archivaris) exact kan worden herleid.
- **Auditability:** Events zijn immutable en vormen de single source of truth.
- **Extensibility:** Omdat we reeds gekozen hebben voor PostgreSQL, kunnen we gebruik maken van krachtige `JSONB` ondersteuning om variërende payloads van events flexibel op te slaan.

---

## Gevolgen

- **Architecturaal:** PostgreSQL fungeert als Event Store (append-only tabel) en bevat tegelijk het Read Model (huidige document status).
- **Ontwikkeling:** Elke wijziging wordt als INSERT naar de events-tabel geschreven; een Projection Engine berekent de huidige staat.
- **Infrastructuur:** Geen nieuwe technologie nodig; volledig gebaseerd op bestaande PostgreSQL-instantie uit ADR-002.