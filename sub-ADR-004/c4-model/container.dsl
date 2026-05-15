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