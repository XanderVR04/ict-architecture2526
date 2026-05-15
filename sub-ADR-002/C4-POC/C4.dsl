workspace "Digitaal Archief PoC" "Architectuur voor documentopslag en integriteit" {

    model {
        user = person "Archivaris" "Beheert en raadpleegt historische documenten."

        group "Onderzoeksafdeling Geschiedenis" {
            archiveSystem = softwareSystem "Digitaal Archief Systeem" "Systeem voor veilige opslag en metadata beheer van scans." {
                webInterface = container "pgAdmin / Admin Interface" "Beheerinterface voor database-operaties." "Browser-gebaseerd" "Web Browser"
                db = container "Metadata Store (PostgreSQL)" "Slaat metadata, rollen en checksums op." "PostgreSQL 15" "Database"
                objectStore = container "Object Store (MinIO)" "Slaat fysieke binaire bestanden (PDF/Images) op." "MinIO / S3" "Storage"
                apiServer = container "Backend API" "Verwerkt uploads, berekent SHA-256 hashes en beheert RBAC." "Python/Node.js" "Logic" {
                    integrityComponent = component "Integrity Checker" "Berekent en verifieert SHA-256 checksums." "Logic"
                    accessComponent = component "RBAC Manager" "Controleert role_id permissies." "Logic"
                    storageComponent = component "Storage Orchestrator" "Coördineert transacties tussen DB en MinIO." "Logic"
                }
            }
        }

        # Relaties
        user -> webInterface "Beheert metadata via"
        user -> apiServer "Uploadt documenten naar"
        webInterface -> db "Directe database queries"
        user -> storageComponent "Stuurt bestanden naar"
        storageComponent -> integrityComponent "Vraagt hash berekening aan"
        storageComponent -> objectStore "Streamt data naar" "S3 API"
        storageComponent -> db "Registreert metadata via" "SQL"
        storageComponent -> accessComponent "Valideert rechten via"

        # C4 Deployment: Fysieke weergave van je Swarm Cluster
        production = deploymentEnvironment "Production" {
            deploymentNode "Docker Swarm Cluster" "Manager & Worker Nodes" "Ubuntu Server" {
                deploymentNode "Manager Node (nick-reul)" "Primary node" "Docker Engine" {
                    containerInstance db
                    containerInstance webInterface
                }
                deploymentNode "Worker Node (aron-bauwens)" "Secondary node" "Docker Engine" {
                    containerInstance apiServer
                }
                deploymentNode "Worker Node (xander-vanraemdonck)" "Storage node" "Docker Engine" {
                    containerInstance objectStore
                }
            }
        }
    }

    views {
        systemContext archiveSystem "SystemContext" {
            include *
            autoLayout lr
        }

        container archiveSystem "Containers" {
            include *
            autoLayout lr
        }

        component apiServer "Components" {
            include *
            autoLayout lr
        }

        deployment archiveSystem "Production" "Deployment" {
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Deployment Node" {
                background #ffffff
                color #000000
            }
        }
    }
}