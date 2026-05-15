workspace {
    model {
        archief = softwareSystem "Digitaal Archiefsysteem" {
            keycloak  = container "Keycloak" "Centrale Identity Provider. Beheert gebruikers en rollen, geeft JWT-tokens uit via OAuth2/OIDC." "Keycloak 26 · Docker" "Security"
            pythonApi = container "Python API" "REST API die RBAC afdwingt. Controleert het Bearer-token en geeft of weigert toegang." "Python 3 · Flask"
        }

        deploymentEnvironment "Lokaal (Docker Swarm)" {
            developerMachine = deploymentNode "Developer Machine" "" "Windows 11 / macOS / Linux" {
                swarmManager = deploymentNode "Docker Swarm Manager" "" "Docker Engine (Swarm mode)" {
                    keycloakInstance = containerInstance keycloak
                    apiInstance      = containerInstance pythonApi
                }
            }
        }
    }

    views {
        deployment archief "Lokaal (Docker Swarm)" "Deployment" {
            include *
            autoLayout lr
        }

        styles {
            element "Element" {
                metadata    false
                description true
            }
            element "Container" {
                background #438dd5
                color      #ffffff
            }
            element "Security" {
                background #d43f3a
                color      #ffffff
            }
            element "Infrastructure Node" {
                background #ffffff
            }
        }
    }
}
