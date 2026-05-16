workspace {

    model {
        onderzoeker = person "Onderzoeker" "Een historicus die zoekt naar documenten."
        ocrService = softwareSystem "OCR Service" "Levert gedigitaliseerde tekst aan via JSON."

        searchSystem = softwareSystem "Search Service System" "Maakt historische documenten doorzoekbaar."

        # Relaties op Systeemniveau
        onderzoeker -> searchSystem "Zoekt naar documenten in"
        ocrService -> searchSystem "Levert tekstdata aan bij"
    }

    views {
        systemContext searchSystem "SystemContext" {
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
        }
    }
}