workspace "Document Archief" "Deployment Diagram" {
    model {
        system = softwareSystem "Document Archief Systeem" {
            webApp = container "Web Applicatie"
            metadataService = container "Metadata Management Service"
            database = container "PostgreSQL Database"
        }

        deploymentEnvironment "Productie / Test Cluster" {
            deploymentNode "User Computer" "Windows / macOS / Linux" "Client" {
                deploymentNode "Web Browser" "Chrome / Firefox / Edge" "Browser" {
                    containerInstance webApp
                }
            }

            deploymentNode "Docker Swarm Cluster" "Debian Linux" {
                deploymentNode "Manager Node" "Control & Compute plane" {
                    containerInstance metadataService
                    containerInstance database
                }
            }
        }
    }

    views {
        deployment system "Productie / Test Cluster" "Deployment" {
            include *
            autoLayout
        }

        styles {
            element "Client" {
                background #999999
            }
            element "Browser" {
                background #ffffff
            }
        }
    }
}