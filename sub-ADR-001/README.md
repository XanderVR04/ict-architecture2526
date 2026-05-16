# Gebruik van een Message Queue voor ontkoppeling van upload en verwerking

## Projectbeschrijving

Dit project is een Proof of Concept (POC) voor de ICT Architecture projectopdracht. Het toont hoe uploads van historische documenten asynchroon ontkoppeld worden van de OCR-verwerking via een Message Queue.

Grote hoeveelheden historische documenten worden geüpload en verwerkt via OCR. Deze verwerking is computationeel intensief en kan aanzienlijk meer tijd in beslag nemen dan het uploaden zelf. Door gebruik te maken van een Message Queue (RabbitMQ) kunnen uploads en verwerking onafhankelijk van elkaar schalen, waardoor gebruikers niet hoeven te wachten op het resultaat.

De Proof of Concept staat in [poc/](poc/).

---

## Architectuuroverzicht

De architectuur bestaat uit vijf containers die samenwerken:

```
Researcher / Archivist  -->  Web Application             uploadt documenten
Web Application         -->  Backend API                 vraagt status, stuurt upload door
Backend API             -->  Message Queue (RabbitMQ)    plaatst verwerkingstaak in queue
Backend API             -->  Database                    slaat metadata en job status op
Message Queue           -->  Processing Service          levert taken aan workers
Processing Service      -->  Database                    slaat resultaten op
```

---

## C4 Diagrammen

De onderstaande diagrammen zijn opgesteld volgens het **C4-model** en opgebouwd met **Structurizr DSL**. De afzonderlijke bronbestanden staan in [c4-model/](c4-model/).

### Systeemcontextdiagram

![Systeemcontextdiagram](c4-model/system-context.png)

```structurizr
workspace {

    model {
        researcher = person "Researcher"
        archivist = person "Archivist"


        system = softwareSystem "Document Digitalization System" {
            description "Systeem voor het digitaliseren en verwerken van documenten met OCR"
        }

        archivist -> system "Uploadt en beheert documenten, metadata toevoegen en beheren"
        researcher -> system "Vraagt documenten, bekijkt resultaten en maakt annotaties"
    }

    views {
        systemContext system {
            include *
            autolayout lr
        }

        theme default
    }
}
```

### Containerdiagram

![Containerdiagram](c4-model/container.png)

```structurizr
workspace {

    model {
        user = person "Researcher / Archivist"

        system = softwareSystem "Document Digitalization System" {

            webapp = container "Web Application" {
                description "Frontend voor gebruikers"
                technology "Web App"
            }

            api = container "Backend API" {
                description "Verwerkt requests, beheert jobs en communiceert met queue"
                technology "REST API"
            }

            queue = container "Message Queue" {
                description "Queue voor asynchrone verwerking"
                technology "RabbitMQ"
            }

            processing = container "Processing Service" {
                description "Voert OCR en document verwerking uit"
                technology "Worker service"
            }

            db = container "Database" {
                description "Opslag van documenten, metadata en job status"
                technology "PostgreSQL / MongoDB"
            }
        }

        user -> webapp "Gebruikt"

        webapp -> api "Uploadt documenten / vraagt status"

        api -> db "Slaat metadata en job status op"
        api -> queue "Plaats verwerkingstaak"

        queue -> processing "Levert taken"
        processing -> queue "Ack / status (optioneel)"

        processing -> db "Slaat resultaten en updates status"

        webapp -> api "Pollt voor status/resultaat"
        api -> db "Leest resultaten"
    }

    views {
        container system {
            include *
            autolayout lr
        }

        theme default
    }
}
```

### Deploymentdiagram

![Deploymentdiagram](c4-model/deployment.png)

```structurizr
workspace {

    model {
        system = softwareSystem "Document Digitalization System" {

            webapp = container "Web Application"
            api = container "Backend API"
            queue = container "Message Queue"
            processing = container "Processing Service"
            db = container "Database"

            // Relaties (essentieel voor layout)
            webapp -> api "HTTP requests"
            api -> queue "Sends processing tasks"
            processing -> queue "Consumes tasks"
            processing -> db "Stores results"
            api -> db "Reads/Writes metadata"
        }

        deploymentEnvironment "Production" {

            deploymentNode "Docker Swarm Cluster" {

                deploymentNode "Manager Node" {
                    containerInstance webapp
                    containerInstance api
                }

                deploymentNode "Worker Node 1" {
                    containerInstance processing
                }

                deploymentNode "Worker Node 2" {
                    containerInstance processing
                }

                deploymentNode "Queue Node" {
                    containerInstance queue
                }

                deploymentNode "Database Node" {
                    containerInstance db
                }
            }
        }
    }

    views {
        deployment system "Production" {
            include *
            autolayout lr 300 200
        }

        theme default
    }
}
```

---

## Technologiestack

| Technologie          | Rol                                                           |
|----------------------|---------------------------------------------------------------|
| Web App              | Frontend voor gebruikers                                      |
| REST API             | Verwerkt requests en beheert jobs                             |
| RabbitMQ             | Message broker voor asynchrone verwerking                     |
| Worker service       | Voert OCR en documentverwerking uit                           |
| PostgreSQL / MongoDB | Opslag van documenten, metadata en job status                 |
| Docker Swarm         | Orkestratie van containers via een stack                      |

---

## Mappenstructuur

```
sub-ADR-001/
├── README.md                              # Dit bestand (overzicht en ADR documentatie)
├── c4-model/
│   ├── system-context.dsl                 # C4 systeemcontextdiagram (Structurizr DSL)
│   ├── system-context.png                 # Visueel systeemcontextdiagram
│   ├── container.dsl                      # C4 containerdiagram (Structurizr DSL)
│   ├── container.png                      # Visueel containerdiagram
│   ├── deployment.dsl                     # C4 deploymentdiagram (Structurizr DSL)
│   └── deployment.png                     # Visueel deploymentdiagram
└── poc/
    ├── poc.yaml                           # Docker Swarm stack definitie
    ├── configs/
    │   ├── rabbitmq.conf                  # RabbitMQ configuratie
    │   └── rabbitmq_host.txt              # Hostnaam voor RabbitMQ verbinding
    ├── processor/
    │   ├── Dockerfile                     # Container definitie voor de processor
    │   ├── processor.py                   # OCR verwerkingslogica
    │   └── requirements.txt               # Python dependencies
    ├── secrets/
    │   ├── rabbitmq_pass.txt              # RabbitMQ wachtwoord (Docker Secret)
    │   └── rabbitmq_user.txt              # RabbitMQ gebruikersnaam (Docker Secret)
    ├── uploader/
    │   ├── Dockerfile                     # Container definitie voor de uploader
    │   ├── uploader.py                    # Upload logica
    │   └── requirements.txt               # Python dependencies
    └── README.md                          # Opstartinstructies voor de POC
```

---

## POC

Alle instructies voor opstarten, testen en stoppen staan in [poc/README.md](poc/README.md).

---

## Documentatie

| Document | Beschrijving |
|---|---|
| [ADR-001](README.md) | Architectuurbeslissing: Message Queue voor asynchrone verwerking |
| [Systeemcontextdiagram (DSL)](c4-model/system-context.dsl) | C4 systeemcontextdiagram in Structurizr DSL |
| [Systeemcontextdiagram (PNG)](c4-model/system-context.png) | Visuele weergave van de systeemcontext |
| [Containerdiagram (DSL)](c4-model/container.dsl) | C4 containerdiagram in Structurizr DSL |
| [Containerdiagram (PNG)](c4-model/container.png) | Visuele weergave van de containerarchitectuur |
| [Deploymentdiagram (DSL)](c4-model/deployment.dsl) | C4 deploymentdiagram in Structurizr DSL |
| [Deploymentdiagram (PNG)](c4-model/deployment.png) | Visuele weergave van de deploymentarchitectuur |

### Kernbeslissing

**[ADR-001](README.md)** beschrijft de keuze voor een Message Queue (RabbitMQ) als patroon voor het ontkoppelen van uploads en OCR-verwerking. De voornaamste redenen zijn:

- **Scalability:** OCR-verwerking is resource-intensief en moet onafhankelijk kunnen schalen van het uploadproces.
- **Loose coupling:** door taken in een wachtrij te plaatsen, zijn de ingestion en processingcomponenten volledig ontkoppeld.
- **Fouttolerantie:** ingebouwde retry en queuemechanismen zorgen voor robuuste verwerking bij piekbelasting.

---

# ADR-001: Gebruik van een Message Queue voor ontkoppeling van upload en verwerking

> Dit ADR volgt het **Michael Nygard-formaat** (het originele ADR-formaat uit 2011).
> Referentie: <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>

**Status:** Accepted  
**Datum:** 04/05/2026

---

## Context

De applicatie moet grote hoeveelheden historische documenten verwerken.  
Een belangrijk onderdeel van de workflow is het uitvoeren van OCR op geüploade documenten. Deze verwerking is computationeel intensief en kan aanzienlijk meer tijd in beslag nemen dan het uploaden zelf.

Een van de belangrijkste architecturale karakteristieken is:

- **Scalability**: het systeem moet grote hoeveelheden documenten kunnen verwerken en flexibel kunnen schalen afhankelijk van de belasting.

Zonder extra maatregelen zou een synchrone verwerking (waarbij OCR direct na upload gebeurt) leiden tot:

- Lange wachttijden voor gebruikers  
- Slechte gebruikerservaring  
- Beperkte schaalbaarheid

---

## Decision

We kiezen ervoor om een **Message Queue** te gebruiken om uploads los te koppelen van de OCR-verwerking.

Concreet wordt **RabbitMQ** gebruikt als message broker om berichten (taken) in een wachtrij te plaatsen, die vervolgens asynchroon verwerkt worden door aparte processing componenten.

---

## Consequences

**Positief:**
- Verbeterde schaalbaarheid van verwerking  
- Betere gebruikerservaring (snelle uploads, verwerking op de achtergrond)  
- Mogelijkheid tot horizontale schaalvergroting van processing componenten  

**Negatief:**
- Complexere architectuur  
- Nood aan monitoring van queues en workers  
- Eventuele vertraging tussen upload en beschikbaarheid van resultaten  
