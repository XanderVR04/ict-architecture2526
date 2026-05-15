# ICT Architecture Group Project

## Overview
This repository contains the group project for the ICT Architecture course.

## Team Members
- Xander Van Raemdonck
- Nick Reul
- Iben Sap
- Jesse Bracque
- Aron Bauwens

# ADR-001: Keuze van Architecturale Stijl

**Status:** Accepted  
**Datum:** 01/05/2026

---

## Context

De applicatie ondersteunt het digitaliseren, archiveren en doorzoeken van historische documenten voor een onderzoeksafdeling.

De architecturale karakteristieken die deze beslissing sturen zijn:

- **Scalability**: het systeem moet grote hoeveelheden documenten en rekenintensieve taken zoals OCR kunnen verwerken, waarbij individuele componenten onafhankelijk kunnen schalen op basis van hun specifieke belasting.
- **Searchability en performance**: gebruikers moeten snel en nauwkeurig kunnen zoeken in grote datasets met teksten die fouten kunnen bevatten door OCR-verwerking of verouderde spelling.
- **Data integrity**: historische data is onvervangbaar en moet betrouwbaar worden opgeslagen. Elke wijziging moet traceerbaar zijn.
- **Auditability**: de volledige levensloop van een document, van upload tot correcties, moet te allen tijde herleid kunnen worden.
- **Extensibility**: het systeem moet eenvoudig uitbreidbaar zijn met nieuwe analyse- of verwerkingsstappen, zoals aanvullende AI-modellen of nieuwe services.
- **Security**: toegang tot gevoelige historische documenten moet rolgebaseerd worden beheerd en centraal worden afgedwongen over alle services heen.

Deployability is een minder dominante maar relevante eis.

---

## Decision

We kiezen voor een microservices architectuurstijl.

---

## Considered Options

### 1. Monolithische architectuur

Alle functionaliteit is geïntegreerd in één enkele applicatie.

**Voordelen:**
- Eenvoudig te ontwikkelen en deployen
- Minder operationele complexiteit

**Nadelen:**
- Moeilijk schaalbaar per afzonderlijk component
- Sterke koppeling tussen onderdelen bemoeilijkt uitbreiding
- Beperkte flexibiliteit voor het toevoegen van nieuwe verwerkingsstappen

### 2. Layered architecture

Klassieke scheiding in lagen: presentatie, business logic en data.

**Voordelen:**
- Duidelijke en goed begrijpbare structuur

**Nadelen:**
- Schaalbaarheid blijft globaal en niet per individuele functie
- Minder geschikt voor rekenintensieve pipelines zoals OCR-verwerking

### 3. Microservices architectuur (gekozen)

Het systeem wordt opgesplitst in onafhankelijke services, elk georganiseerd rond een specifieke business capability.

**Voordelen:**
- Onafhankelijke schaalbaarheid per component, zodat OCR-verwerking en zoekfunctionaliteit elk afzonderlijk kunnen worden geschaald
- Losse koppeling tussen services bevordert uitbreidbaarheid en onderhoudbaarheid
- Geschikt voor event-driven en asynchrone verwerking van grote documentenstromen

**Nadelen:**
- Hogere operationele complexiteit
- Netwerkcommunicatie tussen services introduceert latency
- Moeilijker te testen en debuggen dan een monoliet

---

## Rationale

De keuze voor microservices wordt gedreven door de architecturale karakteristieken van het systeem.

**Scalability:** OCR-verwerking heeft fundamenteel andere resourcebehoeften dan componenten zoals zoekfunctionaliteit. Door het systeem op te splitsen in onafhankelijke services kan elk component afzonderlijk worden geschaald op basis van zijn specifieke belasting, zonder andere onderdelen te beïnvloeden.

**Extensibility:** Nieuwe analysemethoden, zoals aanvullende AI-modellen of extra verwerkingsstappen, kunnen als aparte services worden toegevoegd zonder impact op de bestaande functionaliteit. Nieuwe services koppelen eenvoudig aan de centrale authenticatieprovider zonder aanpassingen aan andere services.

**Separation of concerns:** De logische componenten van het systeem zijn duidelijk afgebakend: document ingestion, OCR-verwerking, zoekfunctionaliteit, metadata management en authenticatie. Microservices laten toe om elk van deze als een onafhankelijke eenheid te ontwerpen en te implementeren.

**Asynchrone verwerking:** Het bulkgewijs verwerken van documenten vereist een event-driven aanpak waarbij taken worden gebufferd en asynchroon worden afgewerkt. Dit sluit goed aan bij het microservices model en laat toe om piekbelasting op te vangen zonder het systeem te blokkeren.

---

## Consequences

**Positief:**
- Flexibele schaalbaarheid per component op basis van specifieke resourcebehoeften
- Betere ondersteuning voor toekomstige uitbreidingen en nieuwe services
- Mogelijkheid tot gespecialiseerde infrastructuur per service

**Negatief:**
- Complexere deployment waarbij service-orkestratie vereist is
- Nood aan monitoring en observability over alle services heen
- Potentiële consistentieproblemen inherent aan gedistribueerde systemen

---

## Sub-ADR's

De volgende architectuurbeslissingen bouwen voort op de keuze voor microservices en specificeren concrete implementatiebeslissingen per component:

| ADR | Onderwerp | Status |
|-----|-----------|--------|
| [ADR-001](ADR-001/README.md) | Gebruik van een message queue voor asynchrone ontkoppeling van document upload en OCR-verwerking (RabbitMQ) | Accepted |
| [ADR-002](ADR-002/README.md) | Gescheiden opslagstrategie voor metadata en documenten (PostgreSQL) | In progress |
| [ADR-003](ADR-003/README.md) | Zoektechnologie voor de Search Component (Elasticsearch) | Accepted |
| [ADR-004](ADR-004/README.md) | Data-integriteit en versioning via Event Sourcing met PostgreSQL | Accepted |
| [ADR-005](ADR-005/README.md) | Centraal beheer van authenticatie en autorisatie (Keycloak) | Accepted |