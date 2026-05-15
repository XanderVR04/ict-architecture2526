# RabbitMQ POC - Upload ontkoppeld van OCR

Deze POC toont asynchrone verwerking via een message queue.
De uploader plaatst jobs in RabbitMQ, de processor verwerkt die met vertraging.
De OCR wordt gesimuleerd door `time.sleep(5)` in [sub-ADR-001/poc/processor/processor.py](sub-ADR-001/poc/processor/processor.py).

## Run (lokale single-node swarm)

Open twee terminal windows. Type in het eerste eerst dit, waarbij de eerste drie commando's enkel eenmalig uitgevoerd moeten worden. Zie ook dat je in de juiste map bent genavigeerd:

1) docker swarm init
2) docker build -t poc-uploader ./uploader
3) docker build -t poc-processor ./processor
4) notepad .\secrets\rabbitmq_user.txt
5) notepad .\secrets\rabbitmq_pass.txt
6) notepad .\configs\rabbitmq_host.txt

Voer dan deze uit, want die moeten telkens maal opnieuw worden uitgevoerd als de POC gebruikt wordt:

1) docker stack deploy -c poc.yaml poc
2) docker service ls
3) docker service logs -f poc_uploader

En daarna in het tweede dit:
1) docker service logs -f poc_processor

## Validatie
- Uploader stuurt elke 2s een job.
- Processor verwerkt elke 5s een job.
- De queue buffert de rest.

## Schalen
- docker service scale poc_processor=2

## Opruimen
- docker stack rm poc
