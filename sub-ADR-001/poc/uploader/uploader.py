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


i = 1
while True:
    msg = f"job-{i}"
    ch.basic_publish(
        exchange="",
        routing_key="ocr_jobs",
        body=msg,
        # delivery_mode=2 zorgt ervoor dat het bericht persistent is, 
        # wat betekent dat het niet verloren gaat als RabbitMQ herstart.
        properties=pika.BasicProperties(delivery_mode=2),
    )
    print("uploaded", msg, flush=True)
    i += 1
    time.sleep(2)
