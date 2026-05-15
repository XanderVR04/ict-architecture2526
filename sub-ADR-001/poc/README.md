# RabbitMQ POC - Upload ontkoppeld van OCR

Deze POC toont asynchrone verwerking via een message queue.
De uploader plaatst jobs in RabbitMQ, de processor verwerkt die met vertraging.
De OCR wordt gesimuleerd door `time.sleep(5)` in [sub-ADR-001/poc/processor/processor.py](sub-ADR-001/poc/processor/processor.py).

## Run (externe swarm)

Voer dit uit op een swarm **manager**. Zorg dat je in [sub-ADR-001/poc](sub-ADR-001/poc) staat.

1) echo "user" > ./secrets/rabbitmq_user.txt
2) echo "pass" > ./secrets/rabbitmq_pass.txt
3) echo "poc_rabbitmq." > ./configs/rabbitmq_host.txt
4) printf "default_user = user\ndefault_pass = pass\n" > ./configs/rabbitmq.conf

Let op: de waarden in [sub-ADR-001/poc/configs/rabbitmq.conf](sub-ADR-001/poc/configs/rabbitmq.conf) moeten overeenkomen met de secrets.
Tip: zet in [sub-ADR-001/poc/configs/rabbitmq_host.txt](sub-ADR-001/poc/configs/rabbitmq_host.txt) `poc_rabbitmq.` (met punt) om het zoekdomein te omzeilen.

Voer dan deze uit (telkens opnieuw wanneer je de POC start):

1) docker stack deploy -c poc.yaml poc
2) docker service ls
3) docker service ps poc_rabbitmq --no-trunc
4) docker service ps poc_uploader --no-trunc
5) docker service ps poc_processor --no-trunc

Logs bekijk je op de node waar de service draait:

1) docker service logs -f poc_uploader
2) docker service logs -f poc_processor

## Validatie
- Uploader stuurt elke 2s een job.
- Processor verwerkt elke 5s een job.
- De queue buffert de rest.

## Schalen
- docker service scale poc_processor=2

## Opruimen
- docker stack rm poc
