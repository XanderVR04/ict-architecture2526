import os
import jwt
import requests as http
from jwt import PyJWKClient
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

KEYCLOAK_URL   = os.environ.get("KEYCLOAK_URL",   "http://keycloak:8080")
KEYCLOAK_REALM = os.environ.get("KEYCLOAK_REALM", "archief-realm")
ISSUER    = f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}"
JWKS_URI  = f"{ISSUER}/protocol/openid-connect/certs"
TOKEN_URL = f"{ISSUER}/protocol/openid-connect/token"

jwks_client = PyJWKClient(JWKS_URI, cache_jwk_set=True, lifespan=360)

INDEX_HTML = """
<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8">
  <title>Keycloak RBAC POC</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 720px; margin: 40px auto; padding: 20px; background: #f5f5f5; }
    h1 { color: #333; }
    p.sub { color: #666; margin-top: -10px; }
    .card { background: white; border-radius: 8px; padding: 20px; margin: 16px 0; box-shadow: 0 1px 4px rgba(0,0,0,.1); }
    .card h3 { margin-top: 0; }
    button { padding: 10px 22px; margin: 6px 4px; cursor: pointer; border: none; border-radius: 5px; font-size: 14px; font-weight: bold; }
    .btn-green  { background: #28a745; color: white; }
    .btn-yellow { background: #e0a800; color: white; }
    .btn-red    { background: #dc3545; color: white; }
    .result { margin-top: 14px; padding: 12px 16px; border-radius: 6px; font-family: monospace; font-size: 13px; white-space: pre-wrap; display: none; }
    .ok   { background: #d4edda; border-left: 4px solid #28a745; }
    .warn { background: #fff3cd; border-left: 4px solid #e0a800; }
    .err  { background: #f8d7da; border-left: 4px solid #dc3545; }
    .badge { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: bold; margin-bottom: 8px; }
    .b201 { background: #28a745; color: white; }
    .b403 { background: #e0a800; color: white; }
    .b401 { background: #dc3545; color: white; }
    .b503 { background: #6c757d; color: white; }
  </style>
</head>
<body>
  <h1>Keycloak RBAC POC</h1>
  <p class="sub">Klik op een knop, de backend haalt een JWT op bij Keycloak en roept <code>POST /upload</code> aan.</p>

  <div class="card">
    <h3>Scenario 1 &mdash; Researcher (toegang verwacht)</h3>
    <p>Gebruiker: <strong>researcher1</strong> &nbsp;|&nbsp; Rol: <strong>researcher</strong> &nbsp;|&nbsp; Wachtwoord: <code>wachtwoord123</code></p>
    <button class="btn-green" onclick="run('researcher1','wachtwoord123','r1')">Test als Researcher</button>
    <div class="result" id="r1"></div>
  </div>

  <div class="card">
    <h3>Scenario 2 &mdash; Viewer (toegang geweigerd)</h3>
    <p>Gebruiker: <strong>viewer1</strong> &nbsp;|&nbsp; Rol: <strong>viewer</strong> &nbsp;|&nbsp; Wachtwoord: <code>wachtwoord123</code></p>
    <button class="btn-yellow" onclick="run('viewer1','wachtwoord123','v1')">Test als Viewer</button>
    <div class="result" id="v1"></div>
  </div>

  <div class="card">
    <h3>Scenario 3 &mdash; Geen token (niet geauthenticeerd)</h3>
    <p>Geen gebruiker &mdash; stuurt een verzoek zonder Authorization-header.</p>
    <button class="btn-red" onclick="run(null,null,'nt')">Test zonder token</button>
    <div class="result" id="nt"></div>
  </div>

  <script>
    async function run(user, pass, id) {
      const box = document.getElementById(id);
      box.style.display = 'block';
      box.className = 'result';
      box.textContent = 'Bezig...';

      const qs = user ? `?username=${user}&password=${pass}` : '';
      const resp = await fetch('/demo' + qs);
      const d = await resp.json();

      const cls = d.status === 201 ? 'ok' : (d.status === 403 ? 'warn' : 'err');
      const badgeCls = 'b' + d.status;

      box.className = 'result ' + cls;
      box.innerHTML =
        `<span class="badge ${badgeCls}">HTTP ${d.status}</span>\n` +
        (d.token_preview ? `<b>JWT (preview):</b> ${d.token_preview}\n\n` : '') +
        `<b>Antwoord /upload:</b>\n${JSON.stringify(d.api_response, null, 2)}`;
    }
  </script>
</body>
</html>
"""


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
    return render_template_string(INDEX_HTML)


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
