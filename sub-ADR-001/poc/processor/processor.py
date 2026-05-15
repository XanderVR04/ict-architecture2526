import os
import time

import pika

def read_file_value(path, fallback):
    try:
        with open(path, "r", encoding="utf-8") as file:
            return file.read().strip() or fallback
    except OSError:
        return fallback

# Voor flexibiliteit worden de RabbitMQ-verbinding parameters uit omgevingsvariabelen gehaald,
# met fallback naar Swarm configs/secrets.
host = os.getenv("RABBITMQ_HOST") or read_file_value("/run/configs/rabbitmq_host", "rabbitmq")
user = os.getenv("RABBITMQ_USER") or read_file_value("/run/secrets/rabbitmq_user", "user")
password = os.getenv("RABBITMQ_PASS") or read_file_value("/run/secrets/rabbitmq_pass", "pass")

# De credentials en connection parameters worden ingesteld voor het verbinden met RabbitMQ.
# De credentials zijn bedoeld als authenticatie, en de heartbeat helpt bij 
# het detecteren van dode verbindingen en houdt de connectie actief.
creds = pika.PlainCredentials(user, password)
params = pika.ConnectionParameters(host=host, credentials=creds, heartbeat=30)

# Toegevoegd voor het geval dat de processor eerder start dan de uploader, 
# zodat er een retry mechanisme is om te verbinden met RabbitMQ.
while True:
    try:
        conn = pika.BlockingConnection(params)
        ch = conn.channel()
        ch.queue_declare(queue="ocr_jobs", durable=True)
        break
    except Exception:
        time.sleep(2)

def handle(ch, method, properties, body):
    print("processing", body.decode(), flush=True)
    time.sleep(5)
    ch.basic_ack(delivery_tag=method.delivery_tag)

# prefetch_count=1 zorgt ervoor dat de processor slechts één bericht tegelijk verwerkt,
# wat helpt bij het eerlijk verdelen van werk als er meerdere processors zijn.
ch.basic_qos(prefetch_count=1)
ch.basic_consume(queue="ocr_jobs", on_message_callback=handle)
print("processor ready", flush=True)
ch.start_consuming()
