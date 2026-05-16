workspace {
    model {
        # Systeem en containers definiëren voor de instanties
        searchSystem = softwareSystem "Search Service System" {
            searchApp   = container "Search Service (Flask)" "Verwerkt API-requests en logica." "Python 3.9"
            searchIndex = container "Search Index" "Slaat data op en voert fuzzy search uit." "Elasticsearch" "Database"
        }

        deploymentEnvironment "Live (School Server)" {
            swarmCluster = deploymentNode "Docker Swarm Cluster" "Beheert de status en orchestration van de actieve containers." "Docker Engine (Swarm mode)" "10.164.10.30" {
                stackNode = deploymentNode "poc_stack" "De actieve microservice stack gedeployed via de swarm manager." "Docker Stack" {
                    searchAppInstance   = containerInstance searchApp
                    searchIndexInstance = containerInstance searchIndex
                }
            }
        }
    }

    views {
        deployment searchSystem "Live (School Server)" "Deployment" {
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
            element "Database" {
                shape     Cylinder
                background #28a745
                color      #ffffff
            }
            element "Infrastructure Node" {
                background #ffffff
            }
        }
    }
}