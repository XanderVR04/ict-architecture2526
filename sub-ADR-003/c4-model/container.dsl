workspace {

    model {
        onderzoeker = person "Onderzoeker" "Een historicus die zoekt naar documenten."
        ocrService = softwareSystem "OCR Service" "Levert gedigitaliseerde tekst aan via JSON."

        searchSystem = softwareSystem "Search Service System" "Maakt historische documenten doorzoekbaar." {
            searchApp = container "Search Service (Flask)" "Verwerkt API-requests en logica." "Python 3.9"
            searchIndex = container "Search Index" "Slaat data op en voert fuzzy search uit." "Elasticsearch" "Database"
        }

        # Relaties op Containerniveau (gericht aan de containers zelf)
        onderzoeker -> searchApp "Verstuur zoekopdracht" "HTTPS/JSON"
        ocrService -> searchApp "Stuurt JSON data" "HTTPS/JSON"
        searchApp -> searchIndex "Leest en schrijft data" "Elasticsearch API"
    }

    views {
        container searchSystem "Containers" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #28a745
                color #ffffff
            }
        }
    }
}