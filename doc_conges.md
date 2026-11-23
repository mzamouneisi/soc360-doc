# Congés — compréhension du calcul du solde CP

## Règle observée
- Type : CP
- Date d'effet : 01/01/2024
- Acquisition : 1 j — Mensuelle (Début de période)
- Période de référence : Année civile
- Expiration : Après 12 mois
- Report : Max 0 j (échéance 12 mois)
- Anticipation : 0 j
- Statut : Actif

## Résultat pour une simulation au 31/12/2026
- Solde CP : 12
- Droits acquis : 36
- Absences déduites : 0
- Droits expirés : 24
- Ajustements : 0

## Pourquoi 12 et non 24
- Droits acquis : 1 j/mois crédité le 1er de chaque mois, de 01/2024 à 12/2026
  = 36 mois × 1 j = **36 j**.
- Expiration « Après 12 mois » : chaque lot mensuel expire 12 mois après sa date de crédit.
  - Lots de 2024 (12) expirent en 2025 → expirés.
  - Lots de 2025 (12) expirent en 2026 → expirés (échéance ≤ 31/12/2026).
  - Soit **24 j expirés**.
- Reste : seuls les lots de 2026 (12) expirent en 2027 → **solde = 36 − 24 = 12**.

Avec « Après 12 mois », un droit de l'année N disparaît en N+1 : au 31/12 on ne garde donc
que l'année en cours, pas N‑1.

## Comment obtenir 24 (année courante + année précédente)
- **Recommandé** : Expiration = « Après une durée » → **24 mois**.
  Au 31/12/2026 : lots 2025 + 2026 valides = **24 j**, expirés = 2024 (12 j).
- « Mois de la période suivante = 12 » : attention, le moteur expire les lots dont la date
  d'expiration est `<=` la date de simulation. Un lot de 2025 expirant le 31/12/2026 est donc
  déjà expiré **le 31/12/2026** → on retombe sur 12. Pour « utilisable jusqu'au 31/12 inclus »,
  viser une échéance au **01/01/N+2**.
- Le champ Report « Max 0 j » ne restaure aucun jour : `carryoverMax = 0` ⇒ report désactivé.

## Notes d'implémentation (moteur)
- Lots d'acquisition distincts par période ; consommation FEFO (échéance la plus proche d'abord).
- `after duration` : `expirationDate = dateCredit + expirationMonths`.
- `end of reference period` : fin de la période de référence contenant la date de crédit.
- `month of following period` : fin du mois M de la période de référence suivante.
- Expiration déclenchée pour `expirationDate <= dateSimulation`.
