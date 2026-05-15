### ADR 3: Zoektechnologie voor de Search Component

**Status:** Geaccepteerd  
**Datum:** Mei 2026  
**Auteur:** Iben  

#### Context
De klant (een onderzoeksafdeling geschiedenis) wil antieke documenten digitaliseren, archiveren en doorzoekbaar maken. Een van de belangrijkste drijvende karakteristieken voor ons systeem is **Searchability & Performance**. 
Antieke documenten worden vaak via OCR (Optical Character Recognition) ingelezen. Dit levert vaak tekst op met herkenningsfouten. Bovendien bevatten historische documenten verouderde spellingen en variaties op namen. Gebruikers moeten snel door miljoenen pagina's tekst kunnen zoeken. 
Een traditionele relationele database met SQL `LIKE '%zoekterm%'` queries schiet hier tekort: het vereist een full-table scan (wat zeer traag is bij grote datasets) en het biedt geen ondersteuning voor "fuzzy matching" (zoeken met typefouten) of relevantiescores (ranking).

#### Beslissing
We kiezen voor **Elasticsearch** (een gedistribueerde, RESTful zoek- en analytics engine gebaseerd op Apache Lucene) als de dedicated zoekindex voor onze Search Component. 
De gedigitaliseerde teksten en metadata van de archiefstukken zullen vanuit de hoofd-database asynchroon (bijv. via een event bus of log-shipping) naar Elasticsearch worden gesynchroniseerd.

#### Gevolgen
*   **Positief:** 
    *   Zeer hoge zoekprestaties over miljoenen documenten dankzij de *inverted index* structuur.
    *   Ondersteuning voor *fuzzy search* (fouttolerantie), wat cruciaal is voor teksten met OCR-fouten en oude spellingen.
    *   Mogelijkheid om zoekresultaten te rangschikken op relevantie (scoring).
    *   Horizontaal schaalbaar: we kunnen nodes toevoegen naarmate het archief groeit.
*   **Negatief:**
    *   Verhoogde complexiteit: we moeten een extra component (het Elasticsearch cluster) beheren en monitoren.
    *   Data duplicatie: data leeft in de brondatabase én in de zoekindex. Er moet een mechanisme komen om deze data *eventually consistent* te houden (bijv. het bijwerken van de index als een document wordt aangepast).

#### Alternatieven overwogen
1.  **PostgreSQL Full-Text Search (FTS):** 
    *   *Waarom niet gekozen?* Hoewel Postgres ingebouwde full-text search heeft die goed werkt voor middelgrote datasets, mist het de geavanceerde out-of-the-box text-analysis, geavanceerde fuzzy search en vlotte horizontale schaalbaarheid voor gigantische archieven in vergelijking met Elasticsearch.
    *   *Budget/Team opmerking:* **Als ons team kleiner was of we hadden een sterk beperkt budget en krappe deadline**, zou PostgreSQL FTS onze tweede en preferabele keuze zijn. Het bespaart de overhead van het opzetten en synchroniseren van een apart systeem, aangezien we Postgres waarschijnlijk al als relationele database gebruiken.
2.  **Standaard SQL `LIKE` of Regex:**
    *   *Waarom niet gekozen?* Onwerkbaar traag op grote schaal (O(n) complexiteit) en biedt nul intelligentie qua relevantie of spellingsfouten.