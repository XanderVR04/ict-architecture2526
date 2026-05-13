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