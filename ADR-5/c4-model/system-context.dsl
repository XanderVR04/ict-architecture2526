workspace {
    model {
        onderzoeker = person "Onderzoeker / Archivaris" "Medewerker die documenten uploadt, bewerkt en OCR-processen aanstuur."
        publiek     = person "Publiek" "Externe bezoeker die enkel vrijgegeven documenten mag inzien."

        archief = softwareSystem "Digitaal Archiefsysteem" "Centraliseert authenticatie en autorisatie voor een digitaal historisch documentenarchief via Keycloak (OAuth2/OIDC) en een Python REST API."

        ldap = softwareSystem "LDAP / Active Directory" "Optionele bedrijfsdirectory voor gebruikerssynchronisatie met Keycloak." "External"

        onderzoeker -> archief "Logt in en beheert documenten" "HTTPS"
        publiek     -> archief "Bekijkt vrijgegeven documenten" "HTTPS"
        archief     -> ldap    "Synchroniseert gebruikers (optioneel)" "LDAP"
    }

    views {
        systemContext archief "SystemContext" {
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
            element "Software System" {
                background #1168bd
                color      #ffffff
            }
            element "External" {
                background #999999
                color      #ffffff
            }
        }
    }
}
