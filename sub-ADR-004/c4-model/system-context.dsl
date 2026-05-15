workspace "Document Archief" "Systeemcontext" {
    model {
        user = person "Onderzoeker / Archivaris" "Beheert metadata, annotaties en raadpleegt historische documenten."
        system = softwareSystem "Document Archief Systeem" "Digitaliseert en beheert historische documenten met volledige audit-integriteit."

        user -> system "Gebruikt voor beheer en onderzoek"
    }

    views {
        systemContext system "SystemContext" {
            include *
            autoLayout
        }
    }
}