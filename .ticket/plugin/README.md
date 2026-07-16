# tikett-plugin

Marketplace + plugin Claude Code pour livrer les PRD produits par [Tikett](https://tikett.app).

Tikett écrit les PRD approuvés dans le dossier `.ticket/` de ton repo (via son
intégration GitHub). Ce plugin ajoute la commande **`/tikett-deliver`** qui, depuis
ton Claude Code (donc **sur ton abonnement, sans token API côté serveur**), lit les
PRD en attente, les implémente, ouvre une PR draft, et notifie Tikett.

## Installation

```bash
claude plugin marketplace add jdecampos/tikett-plugin
claude plugin install tikett-delivery@tikett-app
echo 'TIKETT_DELIVERY_KEY=rly_xxx' >> .env.local   # clé fournie par Tikett (Settings du projet)
```

`TIKETT_DELIVERY_KEY` ne doit jamais être committée. `tikettUrl` et `projectId`,
eux, vivent dans `.ticket/config.json` (non secret, committé par Tikett).

## Utilisation

Dans le repo connecté :

```
/tikett-deliver            # traite tous les PRD en attente
/tikett-deliver prd_ab12   # ne traite qu'un PRD précis
```

La commande travaille une branche `tikett/<id>` par PRD, ouvre une PR draft
(jamais d'auto-merge), met à jour `.ticket/index.json`, puis appelle
`bin/tikett-callback.sh` pour repasser le PRD à `done` côté Tikett avec le commit.

## Structure

```
tikett-plugin/
├── .claude-plugin/marketplace.json   # le repo est sa propre marketplace
└── tikett-delivery/
    ├── .claude-plugin/plugin.json
    ├── commands/tikett-deliver.md      # la commande /tikett-deliver
    └── bin/tikett-callback.sh          # POST authentifié vers Tikett
```

## Le dossier `.ticket/` (côté repo client)

```
.ticket/
├── index.json    # { projectId, tikettUrl, prds:[{ id,title,file,status,commit,deliveredAt }] }
├── config.json   # { tikettUrl, projectId }
└── prd/prd_<id>.md
```

Statuts d'un PRD : `pending → processing → done` (ou `failed`).
