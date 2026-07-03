---
description: Traite les PRD Relay en attente (.ticket/) — implémente, commit, PR draft, callback.
argument-hint: "[ref d'un PRD précis, optionnel]"
---

Tu livres des PRD produits par Relay. La source de vérité est le dossier
`.ticket/` à la racine de CE repo. Ton abonnement Claude Code fait le travail —
il n'y a aucun agent côté serveur Relay.

## 1. Charger la file

- Lis `.ticket/config.json` (`relayUrl`, `projectId`) et `.ticket/index.json`.
- Si l'un manque, arrête-toi et dis à l'utilisateur que ce repo n'est pas
  connecté à Relay (le dossier `.ticket/` est créé par Relay au moment de
  « Lancer la livraison »).
- Sélectionne les PRD à traiter :
  - si un argument `$ARGUMENTS` est fourni, ne prends que le PRD dont l'`id`
    correspond ;
  - sinon, prends toutes les entrées `prds[]` dont `status` vaut `pending`.
- S'il n'y a rien à traiter, dis-le clairement (« Aucun PRD en attente ») et
  arrête-toi. Ne réimplémente jamais un PRD déjà `done`.

## 2. Traiter chaque PRD, un par un

Annonce le plan (liste des PRD retenus) puis, **pour chaque PRD**, demande une
confirmation avant de commencer. Une PR par PRD, jamais un commit fourre-tout.

Pour un PRD `{ id, title, file }` :

1. Lis le fichier `.ticket/<file>` (ex. `.ticket/prd/prd_ab12.md`). Le
   front-matter donne le contexte ; le corps décrit le périmètre, le hors-périmètre
   et les critères d'acceptation par cluster.
2. Crée une branche dédiée : `git switch -c relay/<id>` (si elle existe déjà,
   c'est que le PRD est en cours — demande à l'utilisateur avant de continuer).
3. **Implémente** les changements décrits. Respecte les critères d'acceptation.
   Reste dans le périmètre (`Dans le périmètre`), évite le hors-périmètre.
4. Vérifie : lance le build / les tests du projet s'ils existent (`package.json`
   scripts `build` / `test` / `typecheck`, etc.). Corrige ce que tu casses.
5. Mets à jour `.ticket/index.json` : passe l'entrée de ce PRD à
   `status: "done"`, renseigne `commit` (tu le rempliras juste après le commit)
   et `deliveredAt` (ISO 8601). Garde le reste du fichier intact.
6. Commit sur la branche : `git add -A` puis un commit clair
   (`git commit -m "feat: <title> (Relay <id>)"`). Récupère le SHA
   (`git rev-parse HEAD`), réécris-le dans `commit` de `index.json`, et
   amende le commit pour inclure ce dernier ajustement.
7. Push : `git push -u origin relay/<id>`.
8. Ouvre une **PR draft** si `gh` est disponible :
   `gh pr create --draft --title "<title>" --body "Livraison du PRD Relay <id>."`.
   Sinon, indique l'URL de comparaison à l'utilisateur.
9. **Notifie Relay** : exécute
   `bash "${CLAUDE_PLUGIN_ROOT}/bin/relay-callback.sh" <id> <sha>`.
   En cas d'échec du callback, ne bloque pas — signale-le, le statut pourra être
   renvoyé plus tard avec le même script.

## 3. Résumé

À la fin, récapitule : PRD traités, branches/PR créées, commits, et tout PRD
laissé de côté (et pourquoi). Si un PRD a échoué, laisse son entrée `index.json`
en `pending` ou passe-la à `failed`, et lance le callback avec le statut
`failed` : `bash "${CLAUDE_PLUGIN_ROOT}/bin/relay-callback.sh" <id> <sha> failed`.

Règles Relay : jamais d'auto-merge (la PR reste en draft, un humain valide),
reste dans le périmètre du PRD, et ne touche pas aux fichiers hors sujet.
