# POC: Centraal Authenticatie- en Autorisatiebeheer (Keycloak + Flask)

## Wat demonstreert deze POC?

Deze POC toont het architectuurpatroon uit [ADR-005](../README.md): een centrale Identity Provider (**Keycloak**) die via OAuth2/OIDC communiceert met een Python/Flask REST API, waarbij Role-Based Access Control (RBAC) wordt afgedwongen.

De auth-flow bestaat uit drie stappen:

```
1. Client        →  Keycloak      logt in via Resource Owner Password flow, ontvangt JWT
2. Client        →  Flask API     stuurt verzoek met Bearer-token in Authorization-header
3. Flask API                      valideert JWT lokaal via gecachte JWKS-publieke sleutel van Keycloak
```

De Flask API valideert de JWT **volledig lokaal** na de eerste JWKS-fetch: handtekening, issuer en verlooptijd worden geverifieerd. Vervolgens controleert de API of de realm-rol `researcher` aanwezig is in `realm_access.roles`.

---

## Bestandsstructuur

```
poc/
├── app.py                       # Flask API met echte JWT-validatie via Keycloak JWKS
├── requirements.txt             # Python dependencies (flask, PyJWT[crypto], requests)
├── Dockerfile                   # Alternatief voor lokale builds buiten Swarm
├── poc.yaml                     # Docker Swarm stack definitie
├── keycloak/
│   └── realm-export.json        # Automatisch geconfigureerde Keycloak-realm
└── README.md                    # Deze file
```

---

## Vereisten

- Docker met actieve Swarm-modus

Swarm eenmalig initialiseren indien nog niet gedaan:

```
docker swarm init
```

---

## Opstarten

Navigeer naar de `poc/`-directory en deploy de stack:

```
docker stack deploy --compose-file poc.yaml poc-5
```

Dit start twee services:

| Service        | Poort  | Beschrijving                                                              |
|----------------|--------|---------------------------------------------------------------------------|
| `poc_keycloak` | `8080` | Keycloak Identity Provider (admin: `admin` / zie [`.env.example`](../.env.example))      |
| `poc_api`      | `5000` | Flask REST API met JWT-validatie en webinterface                          |

Keycloak importeert bij het opstarten automatisch de realm `archief-realm` uit [keycloak/realm-export.json](keycloak/realm-export.json). Dit duurt **60–90 seconden**. De API herstart automatisch via het restart-beleid totdat Keycloak bereikbaar is.

### Geconfigureerde testgebruikers

| Gebruikersnaam | Wachtwoord      | Rol          |
|----------------|-----------------|--------------|
| `researcher1`  | `wachtwoord123` | `researcher` |
| `viewer1`      | `wachtwoord123` | `viewer`     |

---

## Testen

Open `http://localhost:5000` in een browser zodra Keycloak volledig opgestart is.

De interface toont drie knoppen, één per scenario. Klik op een knop om de volledige auth-flow te starten: de backend haalt automatisch een JWT op bij Keycloak, valideert de handtekening en rol, en toont het resultaat direct in de interface.

| Scenario   | Gebruiker     | Rol          | Verwacht resultaat                    |
|------------|---------------|--------------|---------------------------------------|
| Scenario 1 | `researcher1` | `researcher` | HTTP 201 — toegang verleend           |
| Scenario 2 | `viewer1`     | `viewer`     | HTTP 403 — onvoldoende rol            |
| Scenario 3 | geen          | —            | HTTP 401 — niet geauthenticeerd       |

> **Opmerking over sessies:** bij scenario 2 wordt wel degelijk een Keycloak-sessie aangemaakt voor `viewer1`. Dit is correct gedrag: Keycloak verzorgt de **authenticatie** (wie ben je?) en slaagt voor beide gebruikers. De **autorisatie** (wat mag je?) wordt afgedwongen door de Flask API op basis van de rol in het JWT.

---

## Stoppen

```
docker stack rm poc-5
```

> **Let op bij herdeployen:** Docker Swarm configs zijn onveranderlijk. Als je [app.py](app.py) of [keycloak/realm-export.json](keycloak/realm-export.json) aanpast, verwijder dan eerst de oude stack (`docker stack rm poc-5`) en herstart daarna pas.
