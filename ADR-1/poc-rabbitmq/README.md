# RabbitMQ POC - Upload ontkoppeld van OCR

Deze POC toont asynchrone verwerking via een message queue.
De uploader plaatst jobs in RabbitMQ, de processor verwerkt die met vertraging.
De OCR wordt gesimuleerd door `time.sleep(5)` in [ADR-2/poc-rabbitmq/processor/processor.py](ADR-2/poc-rabbitmq/processor/processor.py).

## Run (lokale single-node swarm)

Open twee terminal windows. Type in het eerste eerst dit, waarbij het eerste commando enkel eenmalig uitgevoerd moet worden:
1) copy .env.example .env
2) docker swarm init
3) docker build -t poc-uploader ./uploader
4) docker build -t poc-processor ./processor
5) docker stack deploy -c poc.yaml poc
6) docker service ls
7) docker service logs -f poc_uploader

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
