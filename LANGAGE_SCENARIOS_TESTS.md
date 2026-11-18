# Langage simple de description des scénarios de tests (LSS)

Version : **1.0**

Le LSS permet de décrire un scénario fonctionnel en français, ligne par ligne, sans
écrire de code. L'éditeur web (`npm run web:dev`) valide la syntaxe, propose les
mots-clés et génère le code Playwright pour les actions reconnues.

## 1. Structure d'un fichier

Un scénario est un fichier `scenario.md` placé dans :

```
tests-proj/<projet>/<scenario>/scenario.md
```

Chaque ligne significative commence par un **mot-clé de structure** ou décrit une
**action**. Les lignes vides et les lignes commençant par `#` sont ignorées.

```text
SCÉNARIO test_004 — Création d’un client
RÔLE responsable_soc
ÉTANT DONNÉ le resp_demo1 est connecté
QUAND il ouvre la page Clients
ET il ajoute un client avec name="Client test_004"
ALORS le client est visible dans la liste
ET le statut est ACTIVE
```

## 2. Mots-clés de structure

| Mot-clé | Rôle | Exemple |
|---|---|---|
| `SCÉNARIO` | Titre du scénario (recommandé) | `SCÉNARIO test_004 — Création d’un client` |
| `RÔLE` | Rôle qui exécute le scénario | `RÔLE responsable_soc` |
| `ÉTANT DONNÉ` | Contexte / prérequis | `ÉTANT DONNÉ le client “Acme” existe` |
| `QUAND` | Déclencheur / première action | `QUAND il ouvre la page Clients` |
| `ET` | Action ou vérification supplémentaire | `ET il ajoute un client` |
| `ALORS` | Résultat attendu | `ALORS le client est visible dans la liste` |
| `MAIS` | Exception / cas négatif | `MAIS un message d’erreur est affiché` |

Rôles autorisés : `admin`, `responsable_soc`, `responsable`, `manager`, `consultant`.

## 3. Directives

| Directive | Effet |
|---|---|
| `ignore_if_exist` | Réutilise les objets existants au lieu d'en recréer. |
| `get liste collaborateurs : <variable>` | Charge la liste des collaborateurs. |
| `check if user manager is in <variable> ?` | Vérifie la présence d'un manager. |
| `if no : create it. with manager = user <rôle>` | Crée le compte manquant. |
| `if yes : test connexion` | Teste la connexion du compte existant. |

## 4. Actions reconnues

Les actions sont des phrases naturelles. Les verbes et concepts suivants sont
reconnus par le validateur et, pour beaucoup, par le générateur de code :

- **Connexion** : `se connecte`, `connexion`, `login`.
- **Création / modification** : `ajoute`, `crée`, `saisit`, `enregistre`, `modifie`,
  `supprime`, `active`, `désactive`.
- **Portefeuille** : `prospect`, `client`, `fournisseur`, `projet`, `type_activite`,
  `activité`, `collaborateur`, `utilisateur`.
- **CRA** : `ajoute un cra`, `remplit le cra`, `enregistre`, `soumet`, `valide`,
  `rejette`, `exporte`.
- **Absences / congés** : `indisponibilité`, `congé`, `solde`, `absence`.
- **Notes de frais** : `note de frais`, `ligne de dépense`, `justificatif`,
  `téléverse`, `marque payée`.
- **Documents** : `document`, `partage`, `télécharge`, `téléverse`.
- **Facturation** : `devis`, `facture`, `TVA`, `envoie`, `génère`.
- **Consultation** : `ouvre`, `va sur`, `clique`, `recherche`, `filtre`, `vérifie`,
  `consulte`.
- **Assertions** : `est visible`, `apparaît`, `statut est`, `la liste contient`,
  `le total est`, `la TVA est`, `un message … est affiché`.

## 5. Attributs

Une action peut porter des attributs `clé=valeur`. Les valeurs peuvent être entre
guillemets doubles ou simples, ou sans espace.

```text
il ajoute un client avec name="Client test_004"
il ajoute un projet avec name=Projet_test_008 client="Client test_008"
il ajoute un cra avec mois=11/2026
```

Attributs usuels : `name`, `role`, `manager`, `managerId`, `type`, `projet`,
`client`, `consultant`, `mois` (`MM/AAAA`), `periode`.

## 6. Règles de validation

Le validateur (`web/src/scenarioLanguage.js`) signale :

1. **Erreur** : ligne non reconnue (aucun mot-clé, action ou observation).
2. **Erreur** : rôle inconnu.
3. **Erreur** : guillemets doubles non fermés.
4. **Erreur** : mois invalide dans `mois=MM/AAAA`.
5. **Erreur** : aucun action reconnue dans le scénario.
6. **Avertissement** : pas d'en-tête `SCÉNARIO`.
7. **Avertissement** : titre sans séparateur (`—`, `-` ou `:`).

Une ligne d'**observation** commence par un déterminant (`le`, `la`, `les`, `un`,
`une`, `des`, `l'`, `ce`, `cette`, `ces`) : elle est acceptée comme assertion.

## 7. Suggestions et autocomplétion

L'éditeur affiche en permanence :

- l'état de la syntaxe (nombre d'erreurs) ;
- la liste des erreurs et avertissements avec le numéro de ligne ;
- des **suggestions de mots-clés** filtrées sur la dernière ligne saisie.

Cliquer sur une suggestion insère le mot-clé au curseur. Le raccourci
**Ctrl+Espace** insère la première suggestion.

## 8. Génération Playwright

Le bouton « Implémenter le test » génère un fichier `<scenario>.spec.ts` à partir
des actions reconnues par `web/src/scenarioCode.js`. Il est désactivé si la
syntaxe est invalide ou si une action n'est pas encore prise en charge par le
générateur. Les scénarios purement descriptifs restent enregistrables.

## 9. Exemple complet

```text
SCÉNARIO test_012 — CRA : saisie, soumission et validation
RÔLE consultant
ÉTANT DONNÉ le consultant test_012 est connecté
QUAND il ajoute un cra avec mois=11/2026
ET il remplit le cra par l’activité "Mission test_012"
ET il enregistre
ET il soumet
ET le manager valide
ALORS le statut est VALIDATED
```

## 10. Bonnes pratiques

- Un scénario = un objectif vérifiable.
- Utiliser un suffixe unique (`test_XXX`) dans les noms de données.
- Préférer `ignore_if_exist` pour les environnements partagés.
- Toujours terminer par une assertion (`ALORS` / `ET`).
- Ne jamais mettre de données personnelles réelles dans les scénarios.
- Nettoyer les données créées lorsque le scénario s'exécute sur un environnement
  partagé.
