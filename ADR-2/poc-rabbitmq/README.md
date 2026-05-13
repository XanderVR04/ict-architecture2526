# RabbitMQ POC - Upload ontkoppeld van OCR

Deze POC toont asynchrone verwerking via een message queue.
De uploader plaatst jobs in RabbitMQ, de processor verwerkt die met vertraging.
De OCR wordt gesimuleerd door `time.sleep(5)` in [poc-rabbitmq/processor/processor.py](poc-rabbitmq/processor/processor.py).

## Run (lokale single-node swarm)

Open twee terminal windows. Type in het eerste eerst dit, waarbij het eerste commando enkel eenmalig uitgevoerd moet worden:
1) docker swarm init
2) docker build -t poc-uploader ./uploader
3) docker build -t poc-processor ./processor
4) docker stack deploy -c poc.yaml poc
5) docker service ls
6) docker service logs -f poc_uploader

En daarna in het tweede dit:
7) docker service logs -f poc_processor

## Validatie
- Uploader stuurt elke 2s een job.
- Processor verwerkt elke 5s een job.
- De queue buffert de rest.

## Schalen
- docker service scale poc_processor=2

## Opruimen
- docker stack rm poc
