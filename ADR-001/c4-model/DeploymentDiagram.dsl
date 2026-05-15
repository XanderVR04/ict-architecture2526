workspace {

    model {
        system = softwareSystem "Document Digitalization System" {

            webapp = container "Web Application"
            api = container "Backend API"
            queue = container "Message Queue"
            processing = container "Processing Service"
            db = container "Database"

            // Relaties (essentieel voor layout)
            webapp -> api "HTTP requests"
            api -> queue "Sends processing tasks"
            processing -> queue "Consumes tasks"
            processing -> db "Stores results"
            api -> db "Reads/Writes metadata"
        }

        deploymentEnvironment "Production" {

            deploymentNode "Docker Swarm Cluster" {

                deploymentNode "Manager Node" {
                    containerInstance webapp
                    containerInstance api
                }

                deploymentNode "Worker Node 1" {
                    containerInstance processing
                }

                deploymentNode "Worker Node 2" {
                    containerInstance processing
                }

                deploymentNode "Queue Node" {
                    containerInstance queue
                }

                deploymentNode "Database Node" {
                    containerInstance db
                }
            }
        }
    }

    views {
        deployment system "Production" {
            include *
            autolayout lr 300 200
        }

        theme default
    }
}