workspace {

    model {
        researcher = person "Researcher"
        archivist = person "Archivist"


        system = softwareSystem "Document Digitalization System" {
            description "Systeem voor het digitaliseren en verwerken van documenten met OCR"
        }

        archivist -> system "Uploadt en beheert documenten, metadata toevoegen en beheren"
        researcher -> system "Vraagt documenten, bekijkt resultaten en maakt annotaties"
    }

    views {
        systemContext system {
            include *
            autolayout lr
        }

        theme default
    }
}