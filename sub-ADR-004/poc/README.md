# Proof of Concept: Data-integriteit & Versioning (Sub-ADR 4)

Deze directory bevat de Proof of Concept (POC) voor Sub-ADR 4: **Aanpak voor Data-integriteit en Versioning**. 

In deze POC demonstreren we het **Event Sourcing** patroon. We gebruiken PostgreSQL als een "Append-Only Event Store" in combinatie met een simpele web interface (via Express.js). 

Hierdoor is het onmogelijk om per ongeluk data te verliezen of te overschrijven: elke wijziging (zelfs een verwijdering) is slechts een nieuw *event* dat in het grootboek (audit trail) wordt genoteerd. De applicatie projecteert deze events om de huidige staat van het document te bepalen.

## Hoe deze POC uit te voeren in Docker Swarm

1. **Ga naar deze directory** in je terminal:
   ```bash
   cd poc_data_integrity
   ```

2. **Start de stack** via Docker Swarm:
   ```bash
   docker stack deploy -f poc.yaml poc-4
   ```

3. **Bezoek de Web Applicatie:**
   Open je browser en ga naar:  
   **http://localhost:3000**
   
   *(Geef het systeem enkele seconden om de container te starten en de npm packages te installeren)*

## Wat kun je doen in de applicatie?

- **Huidige Status bekijken:** Je ziet aan de linkerkant het document zoals het *nu* is (de projectie).
- **Metadata Updaten:** Verander de titel van het document. Dit voert geen `UPDATE` query uit, maar schrijft een `MetadataUpdated` event weg.
- **Annotaties Toevoegen:** Voeg een notitie toe als archivaris (`AnnotationAdded` event).
- **Document Verwijderen:** Dit haalt het document links uit beeld, maar als je in de Audit Trail (rechts) kijkt, zie je dat de data en de geschiedenis nog intact zijn en er enkel een `DocumentDeleted` event is toegevoegd!

## Opruimen
Om de POC af te sluiten en te verwijderen uit je swarm:
```bash
docker stack rm poc-4
```