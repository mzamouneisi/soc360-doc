# Documentation projet SOC360 (base pour les tests fonctionnels)

> Cette synthèse sert de base à la description des scénarios de tests fonctionnels
> (`LANGAGE_SCENARIOS_TESTS.md`) et à leur implémentation Playwright.

## 1. Objet

SOC360 est une application web de gestion de société de conseil / ESN :
collaborateurs, missions, clients, prospects, fournisseurs, CRA, congés et
indisponibilités, notes de frais, documents RH, devis/factures, fiches de paie,
messagerie et administration.

Deux applications :

| Élément | Technologie | Dépôt / URL |
|---|---|---|
| Frontend | React 19 + Vite + TypeScript + Tailwind | `soc360-front-react` |
| Backend | Spring Boot 3.4 / Java 17 / JPA / Flyway | `soc360-back-java` |
| Front public dev | GitHub Pages | `https://mzamouneisi.github.io/soc360-front-react/` |
| Front public prod | GitHub Pages | `https://mzamouneisi.github.io/soc360-front-react-prod/` |
| Backend dev | Azure Container Apps | `https://esn360-backend-v2-dev.whiteforest-96ad5fb7.francecentral.azurecontainerapps.io` |
| Backend prod | Azure Container Apps | `https://esn360-backend-v2-prod.whiteforest-96ad5fb7.francecentral.azurecontainerapps.io` |

## 2. Rôles et périmètres

| Rôle | Périmètre principal |
|---|---|
| `ADMIN` | Administration globale : sociétés, abonnements, paiements, logs, base, langues, paramètres de paiement. |
| `RESPONSIBLE_SOC` | Paramètres de sa société, collaborateurs, clients/prospects/fournisseurs, missions/activités, devis/factures, TVA, couleurs CRA, logo. |
| `MANAGER` | Suivi de son équipe : CRA, indisponibilités, notes de frais, documents, soldes de congés. |
| `CONSULTANT` | Saisie de ses CRA, indisponibilités, notes de frais, documents, consultation de ses soldes. |

Un compte possède **un seul rôle**. L'accès aux données est isolé par société :
le frontend envoie `X-SOC-Id` et le backend contrôle l'appartenance de l'utilisateur
à la société demandée.

## 3. Modules fonctionnels

### 3.1 Authentification et comptes

- Connexion par email ou identifiant + mot de passe (JWT Bearer).
- Inscription d'une société et de son responsable, vérification d'email.
- Mot de passe oublié / réinitialisation, changement de mot de passe.
- Connexion Google possible pour l'administrateur selon configuration.
- Gestion des collaborateurs : rôles, manager hiérarchique, date d'embauche,
  statut salarié ou non salarié, photo, activation/désactivation.
- Suppression d'un utilisateur avec contrôle des objets liés (CRA, notes de frais,
  documents, soldes, etc.) et confirmation.

### 3.2 Sociétés et abonnements

- Création / modification / suppression de société, logo, adresse, informations
  légales (SIRET, NAF, URSSAF).
- Abonnements, périodes d'essai, paiements, factures d'abonnement.
- Paramètres société : couleurs des jours CRA et week-end, TVA par défaut des
  devis/factures (20 % par défaut, 0 à 100).
- Multi-société : sélection de la société courante, société favorite, contrôle
  d'accès systématique.

### 3.3 Portefeuille commercial

- Prospects : création, notes datées, conversion en client ou fournisseur.
- Clients : coordonnées, contact, adresse, actif/inactif.
- Fournisseurs : coordonnées, contact, actif/inactif.
- Projets : rattachement à un client, devise, actif/inactif, localisation.
- Types d'activité : code, libellés FR/EN, couleur, actif/inactif.
- Activités / missions : tarif, type, projet, consultant, régie ou forfait,
  dates de début/fin, indicateur d'indisponibilité.

### 3.4 CRA (comptes rendus d'activité)

- Saisie mensuelle par le consultant : jours travaillés, heures, activités,
  commentaires, jours de congé/absence.
- Calcul des jours ouvrés et des jours fériés.
- Cycle de vie : brouillon → soumis → validé ou rejeté → resoumission.
- Validation/rejet par le manager avec commentaire et historique.
- Export PDF / CSV et génération de factures à partir des CRA validés (régie).

### 3.5 Indisponibilités et absences

- Types d'indisponibilité paramétrables (comptage ouvré, ouvrable ou calendaire,
  justificatif obligatoire ou non).
- Saisie d'une indisponibilité : date de début/fin, demi-journées, commentaire,
  document justificatif.
- Cycle soumission → validation/rejet/invalidation.
- Contrôles : dates non passées, date d'embauche, jours non comptés, chevauchements.

### 3.6 Congés, RTT et soldes

- Paramétrage des droits : quantité acquise, fréquence (mensuelle, trimestrielle,
  annuelle, unique), mois/jour de crédit, expiration (1 à 12 mois), seuil négatif.
- Génération des lots de droits à partir de la date d'embauche.
- Consommation FIFO/FEFO lors de la validation d'une absence, expirations,
  régularisations, ajustements manuels.
- Soldes datés (simulation à une date), historique des mouvements.
- Les collaborateurs non salariés n'ont ni solde ni acquisition de droits.

### 3.7 Notes de frais

- Saisie de notes et de lignes de dépense (date, type, quantité, prix, TVA).
- Justificatif image/PDF, prévisualisation et OCR éventuel.
- Cycle brouillon → soumis → validé/rejeté → payé.
- Export PDF et suivi par manager/responsable.

### 3.8 Documents et fiches de paie

- Dépôt de documents (formats bureautiques et images), aperçu, téléchargement.
- Partage avec un manager ou un collaborateur.
- Fiches de paie : dépôt, consultation, téléchargement PDF.

### 3.9 Devis et factures

- Devis et factures : lignes, quantité, prix unitaire, remise, TVA, totaux HT/TTC.
- Numérotation automatique, devis parent, facture au forfait ou en régie.
- Génération mensuelle des factures de régie à partir des CRA validés.
- TVA par défaut issue des paramètres de la société ; taux modifiable par document.
- Prévisualisation PDF, envoi par email au client, historique des envois.
- Statuts : brouillon, envoyé, payé, annulé.

### 3.10 Messagerie, support et notifications

- Messages entre utilisateurs, notifications, tickets de support.
- Notifications de soumission/validation selon les rôles.

### 3.11 Administration

- Gestion des sociétés, des utilisateurs, des logs, de la base de données.
- Gestion des langues et des traductions (FR/EN/AR).
- Paramètres de paiement (prestataire, secrets, PayPal, coordonnées bancaires).
- Paramètres d'apparence : thème, tailles, couleurs, onglets, modèles d'email.

## 4. Règles transverses à vérifier

1. **Isolation multi-société** : un utilisateur ne voit jamais les objets d'une
   autre société ; les API vérifient `X-SOC-Id`.
2. **Habilitations par rôle** : chaque page/action n'est accessible qu'aux rôles
   prévus ; les boutons et menus sont masqués ou désactivés sinon.
3. **Validation des formulaires** : champs obligatoires, bornes numériques,
   dates cohérentes, messages d'erreur explicites.
4. **Historisation** : CRA, congés, documents, devis/factures et paramètres
   conservent un historique exploitable.
5. **Traçabilité** : les actions sensibles sont journalisées (logs, audits).
6. **Internationalisation** : libellés FR/EN/AR et formats de date/montant.
7. **Accessibilité / IHM** : ids HTML stables, libellés traduits, messages d'état.
8. **Non-régression** : aucune erreur JavaScript bloquante, codes HTTP cohérents.

## 5. Périmètre des tests fonctionnels

Les scénarios du dossier `tests-proj/soc360/` couvrent :

- le parcours d'inscription et de connexion par rôle ;
- la création et la gestion des collaborateurs ;
- le portefeuille commercial (prospects, clients, fournisseurs) ;
- les projets, types d'activité et missions ;
- le cycle complet du CRA (saisie, soumission, rejet, validation) ;
- les indisponibilités et absences ;
- les congés, RTT et soldes ;
- les notes de frais et leurs statuts ;
- les documents et partages ;
- les devis/factures, la TVA et l'envoi client ;
- les paramètres (onglets, apparence, TVA, congés) ;
- l'administration et les contrôles d'accès.

## 6. Hors périmètre

- Paiement réel par carte ou PayPal (utiliser les endpoints de test).
- Envoi réel d'emails (sauf jeton de vérification fourni).
- Tests de charge et de performance.
- Tests multi-navigateurs complets (Chromium par défaut).
