## Introductie
Deze Proof of Concept bewijst dat Elasticsearch in staat is om documenten te vinden, zelfs wanneer de zoekterm een typfout bevat (bijv. door een OCR-fout).

## Installatie
1. Navigeer naar deze map in de terminal.
2. Voer het volgende commando uit om de stack te starten:
   ```bash
   docker stack deploy -c poc.yaml poc-3