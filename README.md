# relay-plugin

Marketplace + plugin Claude Code pour livrer les PRD produits par [Relay](https://relay.app).

Relay écrit les PRD approuvés dans le dossier `.ticket/` de ton repo (via son
intégration GitHub). Ce plugin ajoute la commande **`/relay-deliver`** qui, depuis
ton Claude Code (donc **sur ton abonnement, sans token API côté serveur**), lit les
PRD en attente, les implémente, ouvre une PR draft, et notifie Relay.

## Installation

```bash
claude plugin marketplace add jdecampos/relay-plugin
claude plugin install relay-delivery@relay-app
echo 'RELAY_DELIVERY_KEY=rly_xxx' >> .env.local   # clé fournie par Relay (Settings du projet)
```

`RELAY_DELIVERY_KEY` ne doit jamais être committée. `relayUrl` et `projectId`,
eux, vivent dans `.ticket/config.json` (non secret, committé par Relay).

## Utilisation

Dans le repo connecté :

```
/relay-deliver            # traite tous les PRD en attente
/relay-deliver prd_ab12   # ne traite qu'un PRD précis
```

La commande travaille une branche `relay/<id>` par PRD, ouvre une PR draft
(jamais d'auto-merge), met à jour `.ticket/index.json`, puis appelle
`bin/relay-callback.sh` pour repasser le PRD à `done` côté Relay avec le commit.

## Structure

```
relay-plugin/
├── .claude-plugin/marketplace.json   # le repo est sa propre marketplace
└── relay-delivery/
    ├── .claude-plugin/plugin.json
    ├── commands/relay-deliver.md      # la commande /relay-deliver
    └── bin/relay-callback.sh          # POST authentifié vers Relay
```

## Le dossier `.ticket/` (côté repo client)

```
.ticket/
├── index.json    # { projectId, relayUrl, prds:[{ id,title,file,status,commit,deliveredAt }] }
├── config.json   # { relayUrl, projectId }
└── prd/prd_<id>.md
```

Statuts d'un PRD : `pending → processing → done` (ou `failed`).
