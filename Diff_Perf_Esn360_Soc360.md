# Pourquoi Soc360 est plus rapide que Esn360

> Comparaison technique et mesurée des deux applications.
> Projets analysés :
> - **Esn360** : `eisiesn360srvjava_mza` (backend, Spring Boot 2.7.18) + `eisiesn360frtangular_mza` (front, Angular 12).
> - **Soc360** : `soc360-back-java` (Spring Boot 3.4.1) + `soc360-front-react` (React 19 / Vite 8).
>
> Date de l'analyse : 2026-10-06.

---

## 1. Synthèse en une phrase

Soc360 est plus rapide parce qu'il a été réécrit sur la génération d'outils suivante
(Spring Boot 3.4 / Hibernate 6.6 / React 19 / Vite 8 au lieu de Spring Boot 2.7 /
Hibernate 5.6 / Angular 12 / webpack), avec un **schéma maîtrisé (Flyway + index),
le lazy-loading par défaut, des DTO explicites, un bundle ~2× plus petit et une
détection de changement beaucoup moins coûteuse**. Esn360, à l'inverse, paie à chaque
requête plusieurs anti-patterns structurels : chargement EAGER, absence d'index,
absence de pagination et OSIV activé.

---

## 2. Mesures front (embarqué / téléchargé)

Builds de production réellement déployés (GitHub Pages).

| Indicateur | Esn360 (Angular 12) | Soc360 (React 19 / Vite 8) | Gain Soc360 |
|---|---|---|---|
| JS initial (raw) | `main.70fc8ba…js` = **2 398 726 o** (~2,29 Mio) + polyfills + runtime = **2 433 465 o** | `index-Cy8VHSLo.js` = **1 179 874 o** (~1,13 Mio) | **≈ 2,1×** |
| JS initial (gzip) | ≈ **608 Ko** | **313 Ko** | **≈ 1,9×** |
| CSS | `styles.3725c67…css` = **428 804 o** (~61 Ko gzip) | `index-BhEU92Rx.css` = **66 238 o** (~12 Ko) | **≈ 6,5×** |
| Total initial (JS+CSS) | ≈ **2,86 Mo** | ≈ **1,25 Mo** | **≈ 2,3×** |
| Nombre de bundles JS servis | 3 (`main` + `polyfills` + `runtime`), **+ 41 vieux `main.*.js` jamais purgés** dans `docs/` | 1 | — |
| Poids du dossier déployé | `docs/` = **108 Mo** (pollué par les anciens builds) | `docs/` = quelques fichiers | — |
| Budget de build | **dépassé** (`main` 2,29 Mio > `initial` max 2 Mo) | pas de budget, mais bandeau Vite OK | — |

Le temps de premier affichage (TTI) est directement proportionnel à ces octets :
Soc360 télécharge et parse environ **2× moins de JavaScript** et **6× moins de CSS**.

Composition du bundle :
- **Esn360** : tout est dans `main` (aucun `vendorChunk` en prod, **0 route lazy**,
  un seul `AppModule` avec **89 composants déclarés** et ~68 routes toutes eager),
  plus jQuery/Popper/Bootstrap chargés en CDN et **3 familles de date-pickers**,
  `highcharts`, `d3`, `jspdf`, `tesseract.js`.
- **Soc360** : un seul chunk (pas encore de code-splitting) **mais** plus petit ;
  React 19 + routeur + i18n + `d3` + `tesseract.js` + `react-datepicker` pèsent
  ~1,18 Mo au total. Le CSS Tailwind v4 est compilé à la demande (66 Ko contre 429 Ko).

---

## 3. Backend : les raisons de fond

### 3.1 Générations de framework

| | Esn360 | Soc360 |
|---|---|---|
| Spring Boot | **2.7.18** | **3.4.1** |
| Spring Framework | 5.3.39 | 6.2.x |
| Hibernate ORM | **5.6.15.Final** | **6.6.4.Final** |
| Java | 17 | 17 |
| Flyway | **désactivé** (`spring.flyway.enabled=false`) | **activé**, 109 migrations |
| Hibernate `ddl-auto` | **`update`** (+ `generate-ddl=true`) | **`validate`** |
| `open-in-view` | **absent → `true`** (OSIV actif en azure/prod) | **`false`** |
| `enable_lazy_load_no_trans` | **`true`** | non (n/a) |
| Requêtes paginées | **0** (`Pageable`/`Page`/`Slice` absents) | 5 repositories (users, messages, notifications, support, connexions) |
| Cache applicatif | **aucun** | aucun |
| Nez d'index SQL déclarés | **0 `CREATE INDEX`** | **28 `CREATE INDEX`** |
| Taille du code Java | **393 fichiers / 33 758 LOC** | **194 fichiers / 14 819 LOC** |

### 3.2 Chargement des associations (le facteur n°1)

**Esn360** cumule les pièges classiques d'Hibernate :
- `CraDay.craDayActivities` est en **`FetchType.EAGER`** : charger un seul CRA
  hydrate d'office toutes ses activités.
- Tous les `@ManyToOne` sans fetch explicite sont **EAGER** (`Cra.consultant`,
  `CraDayActivity.activity`, `Activity.project`, `NoteFrais.category`, …).
- Aucun `@EntityGraph`, aucun `JOIN FETCH`, aucun `@BatchSize` : les mappers
  faits main parcourent le graphe (`CraMapper.mapRelationsToDto`,
  `CraDayMapper`, `CraDayActivityMapper`) et déclenchent une requête par nœud
  → **explosion N+1**.
- `enable_lazy_load_no_trans=true` masque le problème et le fait payer à tous
  les appels, hors transaction.

**Soc360** prend le problème par l'autre bout :
- **48 associations en `FetchType.LAZY`, 0 EAGER** ; `open-in-view=false` force
  le chargement à l'intérieur de la transaction.
- Toutes les réponses passent par des **DTO records** (`*Dtos.java`), jamais par
  la sérialisation directe des entités.
- (À noter : Soc360 n'utilise pas encore `@EntityGraph`/`JOIN FETCH` — voir §5 —
  mais il ne paie ni l'EAGER forcé ni l'OSIV d'Esn360.)

### 3.3 Accès aux données et tri en mémoire

Esn360 charge des tables entières puis trie/filtre en Java :
- `CraDaoImpl` : `findAll()` puis `Collections.sort(...)` pour les listes filtrées.
- `ConsultantDaoImpl.findByFilter` : `findAll().stream().filter(...)`.
- Aucune pagination sur les endpoints de liste.

Soc360 pagine déjà les volumes élevés (utilisateurs, messages, notifications,
support) via Spring Data `Pageable`, et les écitures de masse passent par des
**`@Modifying` JPQL delete** (10 occurrences) plutôt que de charger les entités.

### 3.4 Schéma et index

- **Esn360** : le schéma est muté automatiquement à chaque démarrage
  (`ddl-auto=update`), ce qui coûte au boot et empêche toute optimisation
  d'index. **Aucun index explicite** n'est déclaré → scans complets probables
  sur `cra.cra_month`, `note_frais.date_nf`, les FK, etc.
- **Soc360** : schéma **géré uniquement par Flyway** (109 migrations, `validate`),
  avec **28 index ciblés** sur les tables chaudes (`idx_cra_consultant`,
  `idx_cra_esn_month (consultant_id, month_number, period_year)`,
  `idx_nf_esn_year`, `idx_msg_recipient`, `idx_unavailability_consultant_interval`,
  …). Les requêtes de filtrage mensuel/annuel sont couvertes par index.

### 3.5 Coût par requête HTTP (authentification)

Esn360 embarque les mappers génériques par **réflexion** :
`ABaseMapper` itère toutes les propriétés source × cible
(`Introspector.getBeanInfo`) → coût CPU **O(P²)** à chaque conversion
entité↔DTO, en plus du N+1.

Soc360 mappe manuellement et explicitement (pas de réflexion par ligne).
Son filtre JWT reste perfectible (~4 requêtes par requête authentifiée via
`CustomUserDetailsService`), mais ce coût est fixe et sans réflexion.

### 3.6 Logging et bruit en production

- **Esn360** : les profils azure/prod mettent `logging.level.root=DEBUG` et
  `com.eisi=TRACE`, avec des `logger.info(...)` par appel DAO/service et des
  `toString()` d'entités qui calculent la taille des collections lazy.
- **Soc360** : niveau INFO, `org.hibernate.SQL` visible seulement en local/test.

### 3.7 Démarrage et chargeur de classes

- **Esn360** : `spring.sql.init.mode=always` + `defer-datasource-initialization`
  + `ddl-auto=update` à chaque boot ; le jar embarque ~**80 Mo de données
  Tesseract** (traineddata + installeur exe). Jar plus lourd, boot plus lent.
- **Soc360** : Flyway ne joue que les migrations manquantes ; jar sans charge OCR
  embarquée (l'OCR est côté front).

---

## 4. Frontend : les raisons de fond

| | Esn360 (Angular 12.2.17) | Soc360 (React 19.2 / Vite 8) |
|---|---|---|
| Bundler | webpack legacy (`@angular-devkit/build-angular:browser` ~12.1.3) | **Vite 8 (Rolldown)**, ESBuild/Rust |
| Bootstrap d'app | `platformBrowserDynamic().bootstrapModule()` (JIT-ish) | `createRoot` + composants React |
| Découpage | **0 route lazy**, 0 module feature | 0 route lazy (tout eager) — mais bundle 2× plus petit |
| NgModule | 1 seul `AppModule`, **89 composants déclarés** | arborescence de composants/fonctions |
| Détection de changement | **zone.js Default** (seulement **2/97** composants en `OnPush`) | réconciliateur React + `useMemo` (44) / `useCallback` (32) |
| `async` pipe / désabo | **0 `async` pipe**, **303 `.subscribe(`, seulement 5 `ngOnDestroy`** | hook `useAsync` avec garde `cancelled`, nettoyage par `useEffect` |
| Virtualisation | aucune | aucune |
| Track/mémorisation des listes | `trackBy` dans seulement 6 fichiers, 0 pipe pur | pas de `React.memo` (0), mémorisation partielle |
| Poids CSS | 429 Ko (Material + Bootstrap + flag-icons + CDN) | 66 Ko (Tailwind v4, à la demande) |

Points clés :
- **zone.js** : dans Esn360, chaque événement DOM (scroll, clic, `setTimeout`)
  déclenche un cycle de détection complet sur tout l'arbre (39 `setTimeout/setInterval`
  identifiés). React ne recalculle que les composants dont l'état a changé.
- **Fuites d'abonnement** : 303 `subscribe()` pour seulement 5 `ngOnDestroy()`
  → abonnements non coupés, travail fantôme et mémoire qui monte.
- **Assets** : le dossier `docs/` d'Esn360 accumule 41 anciens `main.*.js` (108 Mo),
  516 SVG de drapeaux et 8,5 Mo d'assets ; Soc360 sert un dossier propre.
- **CDN** : Esn360 empile jQuery + Popper + Bootstrap 4 (CDN) **et** Bootstrap 5
  (npm), plusieurs bibliothèques de date-pickers et de multiselect : autant de
  code mort qui alourdit le bundle et le parse.

---

## 5. Honnêteté : ce que Soc360 ne fait pas encore

Soc360 est plus rapide, mais plusieurs axes restent à optimiser (et ne sont
pas la cause de sa vitesse actuelle) :

1. **Pas de code-splitting front** : `App.tsx` importe les 38 routes en eager ;
   pas de `manualChunks` dans `vite.config.ts`. Un `React.lazy` par page
   (surtout `Settings`, `Languages`, `Tables`) ferait chuter le bundle initial.
2. **Pas de cache données** : ni `@Cacheable` côté back, ni react-query/SWR côté
   front ; le filtre JWT refait ~4 requêtes par appel.
3. **Pas de `@EntityGraph`/`JOIN FETCH`** : `CraService.toDto` et les exports
   CSV/PDF parcourent les graphes lazy → N+1 résiduel sur ces flux.
4. **Listes non paginées** sur certains endpoints (CRA par année/soc/manager,
   indisponibilités, consultants, socs).
5. **Pas de batching JDBC** (`GenerationType.IDENTITY` l'empêche structurellement).
6. **Hikari et JVM non réglés** (`maximum-pool-size` par défaut, pas de `-Xmx`).
7. **Scheduler mono-thread** : l'export CRA mensuel et le backup DB tournent sur
   le même thread.

Ces points expliquent pourquoi Soc360 est *déjà* plus rapide, et indiquent où
gagner encore.

---

## 6. Conclusion

Soc360 est plus rapide qu'Esn360 pour trois familles de raisons, par ordre d'impact :

1. **Frontend ~2× plus léger** (1,18 Mo vs 2,43 Mo de JS, 66 Ko vs 429 Ko de CSS)
   grâce à Vite 8/React 19 et un CSS compilé à la demande, contre Angular 12/webpack,
   Material + Bootstrap CDN et un bundle surdimensionné.
2. **Backend sans les anti-patterns majeurs d'Esn360** : plus d'EAGER forcé,
   plus de `enable_lazy_load_no_trans`, plus d'OSIV, schéma validé par Flyway avec
   28 index (Esn360 : 0 index, `ddl-auto=update`).
3. **Runtime plus économe** : moins de code (14,8 k vs 33,8 k LOC), pas de mapping
   par réflexion O(P²), pagination sur les gros volumes, logs INFO au lieu de
   TRACE/DEBUG en prod.

Les optimisations listées au §5 (code-splitting, cache, `JOIN FETCH`, pagination
généralisée) permettraient d'accentuer encore l'écart.
