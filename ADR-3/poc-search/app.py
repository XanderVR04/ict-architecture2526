from flask import Flask, render_template, request, jsonify
from elasticsearch import Elasticsearch
import sys
import os

app = Flask(__name__)

try:

    es_url = os.getenv('ES_URL', 'http://elasticsearch:9200')

    es = Elasticsearch(
        [es_url], 
        request_timeout=30,
        max_retries=10,
        retry_on_timeout=True
    )
    
    if not es.ping():
        print(f"WAARSCHUWING: Kan Elasticsearch op {es_url} niet pingen!", file=sys.stderr)
    else:
        print(f"Verbonden met Elasticsearch op: {es_url}")
        
except Exception as e:
    print(f"FOUT bij initialisatie: {e}", file=sys.stderr)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/ingest', methods=['POST'])
def ingest():
    try:
        data = request.get_json()
        if not data or 'tekst' not in data:
            return jsonify({"status": "error", "message": "Geen tekst gevonden"}), 400

        res = es.index(index="archief", document={
            "titel": data.get('titel', 'Onbekend'),
            "tekst": data['tekst']
        })
        return jsonify({"status": "succes", "id": res['_id']})
    except Exception as e:
        print(f"INGEST FOUT: {e}", file=sys.stderr)
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/search', methods=['GET'])
def search():
    try:
        query = request.args.get('q')
        body = {
            "query": {
                "match": {
                    "tekst": {
                        "query": query,
                        "fuzziness": "AUTO"
                    }
                }
            }
        }
        res = es.search(index="archief", body=body)
        return jsonify(res['hits']['hits'])
    except Exception as e:
        print(f"SEARCH FOUT: {e}", file=sys.stderr)
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)