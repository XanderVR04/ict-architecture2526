workspace "Search Service PoC" "Architectuuroverzicht van de Historische Zoekmachine" {

    model {
        # Niveau 1: Mensen en Externe Systemen
        onderzoeker = person "Onderzoeker" "Een historicus die zoekt naar documenten."
        ocrService = softwareSystem "OCR Service" "Levert gedigitaliseerde tekst aan via JSON."

        # Jouw Systeem
        searchSystem = softwareSystem "Search Service System" "Maakt historische documenten doorzoekbaar." {
            
            # Niveau 2: Containers
            searchApp = container "Search Service (Flask)" "Verwerkt API-requests en logica." "Python 3.9" {
                
                # Niveau 3: Componenten
                ingestController = component "Ingest Controller" "Handelt binnenkomende JSON data af." "Python/Flask"
                searchController = component "Search Controller" "Vertaalt zoekopdrachten naar ES queries." "Python/Flask"
                esClient = component "Elasticsearch Client" "Beheert de verbinding met de database." "Python Library"
            }

            searchIndex = container "Search Index" "Slaat data op en voert fuzzy search uit." "Elasticsearch" "Database"
        }

        # Relaties op Systeemniveau
        onderzoeker -> searchSystem "Zoekt naar documenten in"
        ocrService -> searchSystem "Levert tekstdata aan bij"

        # Relaties op Container/Component niveau
        onderzoeker -> searchController "Verstuur zoekopdracht" "HTTPS/JSON"
        ocrService -> ingestController "Stuurt JSON data" "HTTPS/JSON"
        ingestController -> esClient "Gebruikt voor indexering"
        searchController -> esClient "Gebruikt voor zoekopdrachten"
        esClient -> searchIndex "Leest en schrijft data" "Elasticsearch API"
    }

    views {
        # VIEW 1: SYSTEM CONTEXT
        systemContext searchSystem "SystemContext" {
            include *
            autoLayout lr
        }

        # VIEW 2: CONTAINER DIAGRAM
        container searchSystem "Containers" {
            include *
            autoLayout lr
        }

        # VIEW 3: COMPONENT DIAGRAM
        component searchApp "Components" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Database" {
                shape Cylinder
                background #28a745
                color #ffffff
            }
        }
    }
}