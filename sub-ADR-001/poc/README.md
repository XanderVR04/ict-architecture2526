# RabbitMQ POC - Upload ontkoppeld van OCR

Deze POC toont asynchrone verwerking via een message queue.
De uploader plaatst jobs in RabbitMQ, de processor verwerkt die met vertraging.
De OCR wordt gesimuleerd door `time.sleep(5)` in [ADR-2/poc-rabbitmq/processor/processor.py](ADR-2/poc-rabbitmq/processor/processor.py).

## Run (lokale single-node swarm)

Open twee terminal windows. Type in het eerste eerst dit, waarbij de eerste twee commando's enkel eenmalig uitgevoerd moet worden:

1) copy .env.example .env
2) docker swarm init

Voer dan deze uit, want die moeten telkens maal opnieuw worden uitgevoerd als de POC gebruikt wordt:

1) docker build -t poc-uploader ./uploader
2) docker build -t poc-processor ./processor
3) docker stack deploy -c poc.yaml poc
4) docker service ls
5) docker service logs -f poc_uploader

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
