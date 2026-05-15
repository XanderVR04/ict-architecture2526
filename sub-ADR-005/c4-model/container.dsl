workspace {
    model {
        onderzoeker = person "Onderzoeker / Archivaris" "Medewerker die documenten uploadt, bewerkt en OCR-processen aanstuur."
        publiek     = person "Publiek" "Externe bezoeker die enkel vrijgegeven documenten mag inzien."

        archief = softwareSystem "Digitaal Archiefsysteem" {
            keycloak  = container "Keycloak" "Centrale Identity Provider. Beheert gebruikers en rollen, geeft JWT-tokens uit via OAuth2/OIDC." "Keycloak 26 · Docker" "Security"
            pythonApi = container "Python API" "REST API die RBAC afdwingt. Controleert het Bearer-token en geeft of weigert toegang." "Python 3 · Flask"
        }

        onderzoeker -> keycloak  "1. Logt in, ontvangt JWT" "HTTPS / OIDC"
        publiek     -> keycloak  "1. Logt in, ontvangt JWT" "HTTPS / OIDC"
        onderzoeker -> pythonApi "2. Stuurt verzoek met Bearer-token" "HTTP :5000"
        publiek     -> pythonApi "2. Stuurt verzoek met Bearer-token" "HTTP :5000"
        pythonApi   -> keycloak  "3. Haalt JWKS-publieke sleutel op (eenmalig, gecached)" "HTTP :8080"
    }

    views {
        container archief "Containers" {
            include *
            autoLayout lr
        }

        styles {
            element "Element" {
                metadata    false
                description true
            }
            element "Person" {
                shape      Person
                background #1168bd
                color      #ffffff
            }
            element "Container" {
                background #438dd5
                color      #ffffff
            }
            element "Security" {
                background #d43f3a
                color      #ffffff
            }
        }
    }
}
