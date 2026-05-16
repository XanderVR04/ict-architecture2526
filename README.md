# ICT Architecture Group Project

## Overview

This repository contains the group project for the ICT Architecture course. The project concerns the architecture for a system that digitizes, archives, and makes searchable the historical documents of a history research department.

## Team Members

- Xander Van Raemdonck
- Nick Reul
- Iben Sap
- Jesse Bracque
- Aron Bauwens

---

## Architecturale Karakteristieken

### Driving (bepalend voor de architectuurkeuzes)

| Karakteristiek | Omschrijving |
|---|---|
| **Scalability** | Grote hoeveelheden documenten verwerken: batch processing van duizenden documenten, groeiende opslag (terabytes mogelijk) en veel gelijktijdige zoekopdrachten. Rechtvaardigt message queues en distributed processing via Docker Swarm. |
| **Searchability & Performance** | De kern van de applicatie: gebruikers moeten snel documenten vinden via full-text search op OCR-output, filters (datum, auteur, type) en lage query-latency. Vereist een dedicated zoekindex en cachingstrategieen. |
| **Data Integrity & Preservation** | Historische documenten zijn onvervangbaar. Vereist: geen dataverlies, audit trails (wie heeft wat aangepast), versioning van documenten en immutability van opgeslagen data. Beinvloedt storage design, backups en redundancy. |
| **Extensibility** | Onderzoek evolueert: nieuwe analysetools (AI, NLP), nieuwe documenttypes en integraties met andere archieven moeten eenvoudig toe te voegen zijn. Leidt tot een modulaire architectuur en event-driven design. |

### Non-driving (belangrijk, maar minder bepalend voor de core architectuur)

| Karakteristiek | Omschrijving |
|---|---|
| **Security** | Niet alles is publiek toegankelijk. Authenticatie (onderzoekers vs. publiek) en autorisatie (rollen) zijn nodig, maar sturen de core architectuur minder sterk dan schaalbaarheid. |
| **Usability** | Historici zijn vaak geen technische gebruikers. Een intuïtieve zoekinterface en goede UX voor annotaties zijn vereist. Dit zit meer in frontend en design dan in infrastructuur. |
| **Deployability** | Docker-gebaseerde deployments moeten reproduceerbaar en eenvoudig rollback-baar zijn, met de mogelijkheid tot continuous deployment. Docker Swarm komt hier concreet in beeld. |

---

## Logische Componenten

### Actoren

| Actor | Rol |
|---|---|
| Onderzoeker | Zoekt en raadpleegt historische documenten, maakt annotaties |
| Archivaris | Uploadt documenten, beheert metadata en versies |
| Publieke gebruiker | Bekijkt enkel vrijgegeven en gevalideerde documenten |

### Workflows

**Workflow 1: Digitaliseren**

```
Document uploaden  -->  OCR uitvoeren  -->  Metadata toevoegen  -->  Opslaan
```

**Workflow 2: Zoeken**

```
Zoekopdracht ingeven  -->  Index raadplegen  -->  Resultaten tonen
```

**Workflow 3: Beheer**

```
Document aanpassen  -->  Annotaties toevoegen  -->  Versies beheren
```

### Componenten

| Component | Verantwoordelijkheid |
|---|---|
| Ingestion Component | Upload verwerken, bestandsvalidatie, doorsturen naar verwerking |
| Processing Component | OCR uitvoeren, tekst extraheren, data structureren |
| Metadata Management Component | Metadata opslaan en beheren, tags, auteur, datum, validatie |
| Storage Component | Documenten bewaren, versies beheren, data integrity garanderen |
| Search Component | Documenten indexeren, zoekopdrachten uitvoeren, ranking en filtering |
| Access & Security Component | Authenticatie, autorisatie, toegangscontrole per rol |
| User Interaction Component | Input van gebruikers verwerken, resultaten presenteren, interactieflows beheren |

---

## Sub-ADR's

De volgende architectuurbeslissingen bouwen voort op de keuze voor microservices en specificeren concrete implementatiebeslissingen per component:

| ADR | Onderwerp | Status |
|-----|-----------|--------|
| [ADR-001](sub-ADR-001/README.md) | Gebruik van een message queue voor asynchrone ontkoppeling van document upload en OCR-verwerking (RabbitMQ) | Accepted |
| [ADR-002](sub-ADR-002/README.md) | Gescheiden opslagstrategie voor metadata en documenten (PostgreSQL + MinIO) | In progress |
| [ADR-003](sub-ADR-003/README.md) | Zoektechnologie voor de Search Component (Elasticsearch) | Accepted |
| [ADR-004](sub-ADR-004/README.md) | Data-integriteit en versioning via Event Sourcing met PostgreSQL | Accepted |
| [ADR-005](sub-ADR-005/README.md) | Centraal beheer van authenticatie en autorisatie (Keycloak) | Accepted |

---

# ADR: Keuze van Architecturale Stijl

> Dit ADR volgt het **MADR-formaat** (Markdown Architectural Decision Records, v3.0.0).
> Referentie: <https://adr.github.io/madr/>

**Status:** Accepted  
**Datum:** 01/05/2026

---

## Context en Probleemstelling

De applicatie ondersteunt het digitaliseren, archiveren en doorzoeken van historische documenten voor een onderzoeksafdeling geschiedenis.

De voornaamste architecturale karakteristieken die deze beslissing sturen zijn:

- **Scalability**: het systeem moet grote hoeveelheden documenten en rekenintensieve taken zoals OCR kunnen verwerken, waarbij individuele componenten onafhankelijk kunnen schalen op basis van hun specifieke belasting.
- **Searchability & Performance**: gebruikers moeten snel en nauwkeurig kunnen zoeken in grote datasets met teksten die fouten kunnen bevatten door OCR-verwerking of verouderde spelling.
- **Data Integrity & Preservation**: historische data is onvervangbaar en moet betrouwbaar worden opgeslagen met volledige audit trails en versioning.
- **Extensibility**: het systeem moet eenvoudig uitbreidbaar zijn met nieuwe analyse- of verwerkingsstappen, zoals aanvullende AI-modellen of nieuwe services.

Minder dominante maar relevante eisen zijn Security, Usability en Deployability.

**Beslissingsvraag:** Welke architecturale stijl biedt de beste basis voor dit systeem?

---

## Overwogen Opties

1. Monolithische architectuur
2. Layered architecture
3. **Microservices architectuur** *(gekozen)*

---

## Beslissingsresultaat

**Gekozen optie: Microservices architectuur**

Microservices bieden de beste balans tussen schaalbaarheid, uitbreidbaarheid en separation of concerns voor een systeem dat rekenintensieve, heterogene verwerkingsstappen combineert met hoge zoekvereisten.

### Positieve gevolgen

- Flexibele schaalbaarheid per component op basis van specifieke resourcebehoeften
- Betere ondersteuning voor toekomstige uitbreidingen en nieuwe services
- Mogelijkheid tot gespecialiseerde infrastructuur per service (bijv. zwaardere processing voor OCR)

### Negatieve gevolgen

- Complexere deployment waarbij service-orkestratie vereist is
- Nood aan monitoring en observability over alle services heen
- Potentiele consistentieproblemen inherent aan gedistribueerde systemen

---

## Vergelijking van Opties

### Optie 1: Monolithische architectuur

| | |
|---|---|
| **Voordeel** | Eenvoudig te ontwikkelen en deployen; minder operationele complexiteit |
| **Nadeel** | Moeilijk schaalbaar per afzonderlijk component; sterke koppeling bemoeilijkt uitbreiding; beperkte flexibiliteit voor het toevoegen van nieuwe verwerkingsstappen |

### Optie 2: Layered architecture

| | |
|---|---|
| **Voordeel** | Duidelijke en goed begrijpbare structuur |
| **Nadeel** | Schaalbaarheid blijft globaal en niet per individuele functie; minder geschikt voor rekenintensieve pipelines zoals OCR-verwerking |

### Optie 3: Microservices architectuur ✓

| | |
|---|---|
| **Voordeel** | Onafhankelijke schaalbaarheid per component (OCR vs. zoekfunctionaliteit); losse koppeling bevordert uitbreidbaarheid; geschikt voor event-driven en asynchrone verwerking van grote documentenstromen |
| **Nadeel** | Hogere operationele complexiteit; netwerkcommunicatie tussen services introduceert latency; moeilijker te testen en debuggen dan een monoliet |

---

## Rationale (link met driving characteristics)

De keuze voor microservices wordt gedreven door de architecturale karakteristieken van het systeem:

- **Scalability:** OCR-verwerking heeft fundamenteel andere resourcebehoeften dan componenten zoals zoekfunctionaliteit. Door het systeem op te splitsen in onafhankelijke services kan elk component afzonderlijk worden geschaald op basis van zijn specifieke belasting, zonder andere onderdelen te beinvloeden.
- **Extensibility:** Nieuwe analysemethoden (bijv. AI-modellen of NLP-tools) kunnen als aparte services worden toegevoegd zonder impact op de bestaande functionaliteit.
- **Separation of concerns:** De geidentificeerde logische componenten (ingestion, processing, search, metadata management, access & security) kunnen als onafhankelijke eenheden worden ontworpen en geimplementeerd.
- **Asynchrone verwerking:** Bulkverwerking van documenten vereist een event-driven aanpak waarbij taken worden gebufferd en asynchroon worden afgewerkt. Dit sluit goed aan bij het microservices model en laat toe piekbelasting op te vangen zonder het systeem te blokkeren.

---

## Gevolgen

- **Architecturaal:** Elke logische component wordt een onafhankelijke microservice met een eigen verantwoordelijkheid en schaalbaarheid.
- **Ontwikkeling:** Services communiceren via gedefinieerde interfaces (REST, message queue). Teams kunnen services onafhankelijk van elkaar ontwikkelen en deployen.
- **Infrastructuur:** Service-orkestratie via Docker Swarm. Monitoring en observability zijn vereist over alle services heen.
