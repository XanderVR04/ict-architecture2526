## Introductie

Deze Proof of Concept bewijst dat Elasticsearch in staat is om documenten te vinden, zelfs wanneer de zoekterm een typfout bevat (bijv. door een OCR-fout).

## Installatie

1. Navigeer naar de `poc/`-map van sub-ADR-003 in de terminal.
2. Kopieer het voorbeeldconfiguratiebestand:

   ```bash
   cp .env.example .env
   ```

3. Voer het volgende commando uit om de stack te starten:

   ```bash
   docker stack deploy -c poc.yaml poc-3
   ```

4. Geef de services even de tijd om op te starten (Elasticsearch heeft ~30 seconden nodig). Controleer de status:

   ```bash
   docker service ls
   ```

## Gebruik

Zodra alle services actief zijn, open je de webinterface in je browser:

```
http://localhost:5000
```

Via de interface kun je:

- **Documenten ingesten**: de POC laadt automatisch testdata uit [testdata.txt](testdata.txt) bij het opstarten.
- **Zoeken**: typ een zoekterm in het zoekveld. Elasticsearch past fuzzy matching toe, waardoor resultaten ook gevonden worden bij typfouten of OCR-fouten.

### Handmatige validatie

Gebruik de Elasticsearch API rechtstreeks om de werking te controleren:

```bash
# Controleer of de index aangemaakt is
curl http://localhost:9200/_cat/indices?v

# Voer een fuzzy zoekopdracht uit
curl -X GET "http://localhost:9200/documenten/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "tekst": {
        "query": "geschiednis",
        "fuzziness": "AUTO"
      }
    }
  }
}'
```

## Opruimen

```bash
docker stack rm poc-3
```
