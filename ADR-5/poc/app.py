import os
import jwt
import requests as http
from jwt import PyJWKClient
from flask import Flask, request, jsonify, render_template

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), 'public'))

KEYCLOAK_URL   = os.environ.get("KEYCLOAK_URL",   "http://keycloak:8080")
KEYCLOAK_REALM = os.environ.get("KEYCLOAK_REALM", "archief-realm")
ISSUER    = f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}"
JWKS_URI  = f"{ISSUER}/protocol/openid-connect/certs"
TOKEN_URL = f"{ISSUER}/protocol/openid-connect/token"

jwks_client = PyJWKClient(JWKS_URI, cache_jwk_set=True, lifespan=360)


def _get_token(username, password):
    resp = http.post(TOKEN_URL, data={
        "client_id": "test-client",
        "grant_type": "password",
        "username": username,
        "password": password,
    }, timeout=5)
    resp.raise_for_status()
    return resp.json()["access_token"]


def _decode_token(token):
    try:
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            issuer=ISSUER,
            options={"verify_aud": False},
        )
        return payload, None
    except jwt.ExpiredSignatureError:
        return None, "Token verlopen"
    except jwt.InvalidIssuerError:
        return None, "Ongeldige issuer"
    except Exception as exc:
        return None, f"Token ongeldig: {exc}"


@app.route("/")
def index():
    return render_template('index.html')


@app.route("/demo")
def demo():
    username = request.args.get("username")
    password = request.args.get("password")

    if not username:
        return jsonify({"status": 401, "token_preview": None,
                        "api_response": {"error": "Geen Bearer-token meegestuurd"}})

    try:
        token = _get_token(username, password)
    except Exception as exc:
        return jsonify({"status": 503, "token_preview": None,
                        "api_response": {"error": f"Keycloak niet bereikbaar — wacht even en probeer opnieuw. ({exc})"}})

    token_preview = token[:50] + "..."
    payload, error = _decode_token(token)

    if error:
        return jsonify({"status": 401, "token_preview": token_preview,
                        "api_response": {"error": error}})

    roles = payload.get("realm_access", {}).get("roles", [])
    if "researcher" not in roles:
        return jsonify({"status": 403, "token_preview": token_preview,
                        "api_response": {"error": "Toegang geweigerd: rol 'researcher' vereist",
                                         "jouw_rollen": roles}})

    return jsonify({"status": 201, "token_preview": token_preview,
                    "api_response": {"msg": "Toegang verleend: Bestand geüpload",
                                     "gebruiker": payload.get("preferred_username"),
                                     "rollen": roles}})


@app.route("/upload", methods=["POST"])
def upload():
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return jsonify({"error": "Geen Bearer-token meegestuurd"}), 401

    token = auth.split(" ", 1)[1]
    payload, error = _decode_token(token)

    if error:
        return jsonify({"error": error}), 401

    roles = payload.get("realm_access", {}).get("roles", [])
    if "researcher" not in roles:
        return jsonify({"error": "Toegang geweigerd: rol 'researcher' vereist",
                        "jouw_rollen": roles}), 403

    return jsonify({"msg": "Toegang verleend: Bestand geüpload",
                    "gebruiker": payload.get("preferred_username"),
                    "rollen": roles}), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
