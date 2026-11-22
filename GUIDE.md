# Comprendre et présenter Dindo

Ce guide sert à préparer l'oral. Il explique le rôle de chaque fichier, le chemin d'une donnée
dans l'app, les notions Swift utilisées et les questions que le prof peut poser.

## Sommaire

1. [L'app en une minute](#1-lapp-en-une-minute)
2. [L'organisation du code](#2-lorganisation-du-code)
3. [La carte des fichiers](#3-la-carte-des-fichiers)
4. [Ce qui se passe au lancement](#4-ce-qui-se-passe-au-lancement)
5. [Le chemin d'une saisie du jour](#5-le-chemin-dune-saisie-du-jour)
6. [Firebase : connexion et Firestore](#6-firebase--connexion-et-firestore)
7. [L'API REST : la météo](#7-lapi-rest--la-météo)
8. [Les formulaires et leur validation](#8-les-formulaires-et-leur-validation)
9. [Thème et langue](#9-thème-et-langue)
10. [Chargement, erreurs, états vides](#10-chargement-erreurs-états-vides)
11. [Les animations](#11-les-animations)
12. [Les publicités](#12-les-publicités)
13. [Les bonus : hors ligne et carte](#13-les-bonus--hors-ligne-et-carte)
14. [Les notions Swift à citer](#14-les-notions-swift-à-citer)
15. [Questions possibles à l'oral](#15-questions-possibles-à-loral)
16. [Démo conseillée (5 minutes)](#16-démo-conseillée-5-minutes)

---

## 1. L'app en une minute

> « Dindo aide un éleveur de dindes à suivre son élevage **bande par bande**. Une bande est un lot de
> dindonneaux arrivés le même jour. Chaque jour, l'éleveur note les morts, l'aliment, l'eau et le poids moyen.
> L'app calcule la mortalité, l'effectif vivant et l'indice de consommation. Elle rappelle les vaccins par
> notification, suit les ventes et les dépenses, et affiche la météo de la ferme pour prévenir des coups de
> chaleur ou de froid. »

Technologies : **SwiftUI**, **Firebase Auth** (e-mail + Google), **Cloud Firestore**, **API Open-Meteo**,
**Swift Charts** (courbe de poids), **MapKit** (carte), **Google Mobile Ads** (bannière + interstitielle).

---

## 2. L'organisation du code

Chaque dossier a **un seul rôle** :

| Dossier | Rôle | Exemple |
|---|---|---|
| `Models/` | Les données (ce qu'est une bande, un vaccin…) et les règles de validation | `Flock.swift` |
| `Services/` | Parler à l'extérieur : Firebase, l'API météo, les pubs, les notifications | `FlockService.swift` |
| `Views/` | Les écrans : ils **affichent** et **réagissent** aux actions | `DashboardView.swift` |
| `Resources/` | Les textes traduits, les couleurs, l'icône | `fr.lproj/Localizable.strings` |

Phrase à dire : « Les vues ne parlent jamais directement à Firebase. Elles passent par un **service**.
Le service publie ses données avec `@Published`, et SwiftUI redessine l'écran tout seul quand elles changent. »

---

## 3. La carte des fichiers

### Point d'entrée
- **`DindoApp.swift`** : démarre Firebase et les pubs, crée les 3 services partagés (`AuthService`,
  `FlockService`, `WeatherService`) et les donne à tous les écrans avec `.environmentObject`. Il applique
  aussi le thème et la langue.

### Models/
- **`Flock.swift`** : une bande. Elle calcule elle-même `alive` (vivantes = départ − morts − vendues),
  `ageInDays` et `mortalityRate`.
- **`FlockEntries.swift`** : ce qu'il y a dans une bande : `DailyRecord` (saisie du jour), `Vaccine`, `MoneyEntry` (vente ou dépense).
- **`Weather.swift`** : la forme de la réponse JSON d'Open-Meteo, plus le conseil (chaud / froid / OK) et l'icône météo.
- **`Validation.swift`** : toutes les règles des formulaires. Chaque fonction renvoie la clé du message d'erreur, ou `nil` si c'est bon.
- **`AppSettings.swift`** : les enums `AppTheme` et `AppLanguage`, et l'extension `.localized` qui traduit un texte.

### Services/
- **`AuthService.swift`** : connexion, inscription, mot de passe oublié, Google, déconnexion. Il traduit aussi les erreurs Firebase en messages clairs.
- **`FlockService.swift`** : la liste des bandes, écoutée en temps réel. Il ajoute, modifie et supprime une bande.
- **`FlockDataService.swift`** : le contenu **d'une** bande (saisies, vaccins, argent). Il est créé quand on ouvre la fiche de la bande.
- **`WeatherService.swift`** : appelle l'API météo et garde la dernière réponse pour le mode hors ligne.
- **`NotificationService.swift`** : programme et annule les rappels de vaccins.
- **`Ads.swift`** : la bannière et l'interstitielle (identifiants de test Google).

### Views/
- **`RootView.swift`** : l'aiguillage. Personne n'est connecté → `LoginView`. Sinon → `MainTabView`.
- **`MainTabView.swift`** : les 4 onglets (Accueil, Bandes, Ma ferme, Réglages).
- **`Components.swift`** : petites vues réutilisées : chargement, erreur, champ de formulaire, message d'erreur, carte de chiffre (`StatCard`).
- `Auth/` : connexion, inscription, mot de passe oublié.
- `DashboardView.swift`, `FarmView.swift`, `SettingsView.swift` : un écran par onglet.
- `Flocks/` : la liste, la fiche, les formulaires, l'historique, les vaccins et les finances d'une bande.

---

## 4. Ce qui se passe au lancement

1. `DindoApp.init()` démarre Firebase (`FirebaseApp.configure()`) puis le SDK des pubs.
2. `AuthService` s'abonne à Firebase avec `addStateDidChangeListener`. Firebase le prévient à chaque connexion ou déconnexion, et `user` change.
3. `RootView` regarde `auth.user` :
   - `nil` → écran de connexion ;
   - sinon → `MainTabView`.
4. `MainTabView.onAppear` lance `flocks.startListening()` : les bandes arrivent de Firestore.
5. `DashboardView.task` charge la météo si elle n'est pas encore là.
6. L'app demande l'autorisation des notifications et précharge une pub plein écran.

---

## 5. Le chemin d'une saisie du jour

C'est **l'exemple à raconter** à l'oral, parce qu'il traverse toute l'architecture.

1. Dans `FlockDetailView`, je touche **« Saisie du jour »** → `showRecordForm = true` → une feuille (`sheet`) affiche `RecordFormView`.
2. Je tape les morts, l'aliment et l'eau, puis je touche **Enregistrer** → `save()`.
3. `save()` met `showErrors = true` et vérifie chaque champ avec `Validation`. Si un champ est faux, le message rouge apparaît et on s'arrête (`guard … else { return }`).
4. Si tout est bon, la vue crée un `DailyRecord` et appelle `data.addRecord(record)`.
5. `FlockDataService.addRecord` :
   - écrit le document dans `users/{uid}/flocks/{id}/records` (`addDocument(from:)`, grâce à `Codable`) ;
   - ajoute les morts au compteur de la bande : `FieldValue.increment`.
6. Firestore prévient **tout seul** les écouteurs (`addSnapshotListener`) :
   - `FlockDataService.records` change → l'historique se met à jour ;
   - `FlockService.flocks` change (compteur `deaths`) → la mortalité de la fiche **et** du tableau de bord se met à jour.
7. La feuille se ferme (`dismiss()`). Toutes les 3 saisies, une pub interstitielle s'affiche.

Phrase à dire : « Je n'ai jamais besoin de recharger un écran à la main : Firestore pousse les changements,
le service les publie avec `@Published`, et SwiftUI redessine. »

---

## 6. Firebase : connexion et Firestore

### Connexion e-mail / mot de passe
- `Auth.auth().signIn(withEmail:password:)` et `createUser(withEmail:password:)`.
- À l'inscription, on enregistre le nom (`createProfileChangeRequest`) et un profil dans `users/{uid}`.
- Les erreurs Firebase (mauvais mot de passe, e-mail déjà utilisé…) sont transformées en messages clairs par `AuthService.messageKey(for:)`.

### Connexion Google
1. `GIDSignIn` ouvre la fenêtre Google.
2. On récupère un `idToken` et un `accessToken`.
3. On les donne à Firebase : `GoogleAuthProvider.credential(...)` puis `Auth.auth().signIn(with:)`.
4. Le retour dans l'app passe par l'URL `REVERSED_CLIENT_ID` (Info.plist) et `.onOpenURL`.

### Les données dans Firestore
```
users/{uid}
users/{uid}/flocks/{idBande}
   ├── records/{id}
   ├── vaccines/{id}
   └── money/{id}
```
- Tout est rangé **sous l'utilisateur**. Les règles (`firestore.rules`) n'autorisent chacun qu'à lire et écrire **ses** données.
- **Temps réel** : `addSnapshotListener` appelle notre code à chaque changement.
- **Codable + `@DocumentID`** : Firestore transforme le document en `struct` Swift (`data(as: Flock.self)`) et inversement. `@DocumentID` remplit l'`id` avec l'identifiant du document.
- **Compteurs** : `deaths` et `sold` sont gardés dans la bande et mis à jour avec `FieldValue.increment`. Sans eux, il faudrait relire toutes les saisies de toutes les bandes pour afficher l'accueil.
- **Suppression d'une bande** : Firestore ne supprime pas les sous-collections tout seul. `FlockService.delete` supprime donc d'abord les saisies, les vaccins et les ventes.

---

## 7. L'API REST : la météo

- API **Open-Meteo**, gratuite et **sans clé**.
- URL appelée (`WeatherService.load`) : `https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=…&daily=…`
- Étapes :
  1. `URLSession.shared.data(from: url)` avec `await` (la requête ne bloque pas l'écran) ;
  2. on vérifie le code HTTP 200 ;
  3. `JSONDecoder().decode(Weather.self, from: data)` transforme le JSON en `struct` ;
  4. `@Published var weather` change → l'accueil et « Ma ferme » s'affichent.
- `CodingKeys` : les noms du JSON (`temperature_2m`) sont différents des noms Swift (`temperature`).
- **Le lien avec l'élevage** : au-dessus de 30 °C, alerte chaleur (aérer, eau fraîche) ; en dessous de 10 °C, alerte froid (chauffer les dindonneaux). L'icône pulse en cas d'alerte.

---

## 8. Les formulaires et leur validation

7 formulaires : connexion, inscription, mot de passe oublié, bande, saisie du jour, vaccin, vente/dépense.

Le principe est **le même partout** :
1. chaque champ est un `@State` ;
2. `showErrors` vaut `false` au début, pour ne pas afficher d'erreurs avant le premier essai ;
3. sous chaque champ : `ErrorText(key: showErrors ? Validation.xxx(champ) : nil)` ;
4. `save()` met `showErrors = true`, puis `guard` vérifie toutes les règles avant d'enregistrer.

Exemples de règles propres à l'élevage :
- les morts du jour ne peuvent pas dépasser les dindes vivantes (`Validation.birds`) ;
- l'effectif de départ ne peut pas devenir plus petit que les dindes déjà mortes ou vendues (`Validation.flockSize`) ;
- le poids est facultatif, mais 40 kg maximum ;
- « 4,5 » et « 4.5 » sont acceptés tous les deux (`Validation.number`) ;
- les dates : pas dans le futur, pas avant l'arrivée de la bande (plage du `DatePicker`).

---

## 9. Thème et langue

- **Thème** : `@AppStorage(AppTheme.storageKey)` est lu dans `DindoApp` et modifié dans `SettingsView`. Comme c'est la même clé, changer le thème met toute l'app à jour : `.preferredColorScheme(theme.colorScheme)`, et `nil` veut dire « suivre le téléphone ».
- **Langue** : 3 fichiers `Localizable.strings` avec les mêmes 158 clés. `"tab.flocks".localized` va chercher le texte dans la langue choisie.
  - `RootView` met `.id(language)` sur `MainTabView` : quand la langue change, l'interface est reconstruite et tout est retraduit.
  - Pour l'arabe : `.environment(\.layoutDirection, .rightToLeft)` inverse toute la mise en page.
  - Les textes avec une valeur utilisent `String(format:)`, par exemple `"flock.day" = "J%d"` → « J23 ».

---

## 10. Chargement, erreurs, états vides

| Situation | Ce qu'on voit | Où |
|---|---|---|
| Chargement | `LoadingStateView` (dinde qui pulse + `ProgressView`) | liste des bandes, historique, vaccins |
| Erreur réseau météo | Message + bouton « Réessayer » (`ErrorStateView`) | Ma ferme, accueil |
| Erreur Firestore | Alerte « Oups ! » (`showError`) | `MainTabView`, `FlockDetailView` |
| Liste vide | `ContentUnavailableView` avec un message utile (et parfois un bouton) | toutes les listes |

Chaque service a `isLoading` (vrai tant que Firestore n'a pas répondu) et `showError`.

---

## 11. Les animations

| Animation | Fichier |
|---|---|
| Logo de connexion qui arrive en rebondissant (`spring`, échelle + rotation) | `LoginView` |
| Cartes de chiffres qui apparaissent l'une après l'autre (`delay`) | `StatCard` dans `Components` |
| Chiffres qui défilent quand ils changent (`.contentTransition(.numericText())`) | `StatCard`, `FinanceView` |
| Icône météo qui pulse en cas d'alerte (`.symbolEffect(.pulse)`) | `DashboardView` |
| Courbe de poids qui monte depuis zéro | `HistoryView` |
| Coche d'un vaccin qui rebondit (`.symbolEffect(.bounce)`) | `VaccinesView` |
| Messages d'erreur qui glissent (`.transition`) | `ErrorText` |
| Carte qui rétrécit au toucher | `PressableButtonStyle` |
| Bandeau « Hors ligne », listes, champ « dindes vendues » qui apparaît | plusieurs écrans |

---

## 12. Les publicités

- **Identifiants de test** Google uniquement (`AdUnitID` dans `Ads.swift`, `GADApplicationIdentifier` dans `Info.plist`).
- **Bannière** : `BannerAdView` est une vue UIKit (`BannerView`) affichée dans SwiftUI grâce à `UIViewRepresentable`. Elle est en bas de l'accueil.
- **Interstitielle** : `InterstitialAdService` en charge une à l'avance. Il l'affiche **toutes les 3 saisies du jour**, après la fermeture du formulaire, puis il recharge la suivante.

---

## 13. Les bonus : hors ligne et carte

### Hors ligne
- Firestore garde une **copie des données sur le téléphone**. Sans réseau, les listes s'affichent quand même, et les nouvelles saisies sont envoyées dès le retour du réseau.
- `addSnapshotListener(includeMetadataChanges: true)` + `snapshot.metadata.isFromCache` → l'accueil affiche le bandeau orange « Hors ligne ».
- La météo : chaque réponse est gardée dans `UserDefaults`. Sans réseau, on affiche la dernière avec la mention « dernière météo enregistrée ».
- **Démo** : mettre le simulateur ou l'iPhone en mode avion, faire une saisie, puis remettre le réseau.

### Carte (MapKit)
- `FarmView` : `Map` avec un `Marker` « Ma ferme ».
- `MapReader` + `proxy.convert(point, from: .local)` transforme le point touché en latitude/longitude.
- La position est gardée avec `@AppStorage`, et la météo est rechargée pour ce nouvel endroit.

---

## 14. Les notions Swift à citer

| Notion | Exemple dans Dindo |
|---|---|
| `struct` (valeur) / `class` (référence) | `Flock` est une struct ; `FlockService` est une class (partagée entre écrans) |
| Optionnels `?`, `if let`, `guard let`, `??` | `averageWeightKg: Double?` (pas de pesée = `nil`) |
| `enum` avec `rawValue` | `AppTheme`, `AppLanguage`, `MoneyEntry.Kind` |
| Propriétés calculées | `alive`, `mortalityRate`, `profit` |
| `extension` | `String.localized`, `Double.dinars` |
| Closures | `addSnapshotListener { snapshot, error in … }` |
| `[weak self]` | Dans les closures des services, pour que le service puisse être libéré de la mémoire |
| `async` / `await`, `Task` | Connexion Firebase, appel météo |
| `do` / `try` / `catch` | `AuthService`, `WeatherService` |
| `Codable` | `Weather` (JSON), `Flock` (Firestore) |
| `ObservableObject` + `@Published` | Tous les services |
| `@State` | Les champs des formulaires |
| `@StateObject` | `FlockDetailView` crée et garde son `FlockDataService` |
| `@ObservedObject` | Les écrans enfants reçoivent ce même service (`HistoryView(data: data)`) |
| `@EnvironmentObject` | `auth`, `flocks`, `weather` partagés par toute l'app |
| `@AppStorage` | Thème, langue, position de la ferme, onglet choisi |
| Générique `<T: Decodable>` | `FlockDataService.listen` : la même fonction écoute les trois sous-collections |

---

## 15. Questions possibles à l'oral

**Pourquoi un service et pas Firebase directement dans la vue ?**
Chaque fichier garde un seul rôle. Si on change de base de données, seuls les services changent, pas les écrans.

**Différence entre `@StateObject` et `@ObservedObject` ?**
`@StateObject` **crée** l'objet et le garde en vie tant que la vue existe (`FlockDetailView`).
`@ObservedObject` **reçoit** un objet créé ailleurs (`HistoryView`, `VaccinesView`…).

**Pourquoi `@EnvironmentObject` ?**
Pour donner `auth`, `flocks` et `weather` à tous les écrans sans les passer de vue en vue.

**Comment l'écran se met à jour après une saisie ?**
Firestore prévient l'écouteur (`addSnapshotListener`), le service change sa propriété `@Published`, et SwiftUI redessine. Voir la partie 5.

**Pourquoi des compteurs `deaths` / `sold` dans la bande ?**
Pour afficher l'accueil sans télécharger toutes les saisies. `FieldValue.increment` ajoute la valeur côté serveur, sans risque d'écraser un autre changement.

**Comment l'app sait si quelqu'un est connecté ?**
`Auth.auth().addStateDidChangeListener` met `user` à jour, et `RootView` affiche la connexion ou l'app.

**Comment sont protégées les données ?**
Par les règles Firestore : `request.auth.uid == userId`. Un éleveur ne peut lire que ses propres bandes.

**Que se passe-t-il sans Internet ?**
Les données Firestore sont dans le cache, le bandeau « Hors ligne » s'affiche, les saisies partent au retour du réseau, et la dernière météo reste visible.

**Comment fonctionne la traduction en arabe ?**
Fichier `ar.lproj`, `.localized`, et `layoutDirection = .rightToLeft` pour inverser la mise en page.

**Pourquoi `[weak self]` ?**
La closure de l'écouteur est gardée par Firestore. Sans `weak`, le service et la closure se retiendraient l'un l'autre, et le service ne serait jamais libéré (fuite de mémoire).

**C'est quoi l'indice de consommation ?**
Les kilos d'aliment consommés pour produire 1 kg de dinde : aliment total ÷ (poids moyen × dindes vivantes). Plus il est bas, mieux c'est.

**Pourquoi les identifiants de pub de test ?**
C'est exigé par le sujet. Les vrais identifiants en développement sont interdits par Google, et le compte peut être bloqué.

---

## 16. Démo conseillée (5 minutes)

1. **Inscription** avec une erreur volontaire (mots de passe différents) → message rouge → correction.
2. **Accueil** : météo + conseil, cartes animées, bannière pub.
3. **Bandes** → « + » → créer « Bande Printemps », 500 dindonneaux. Essayer d'abord 0 pour montrer l'erreur.
4. Ouvrir la bande → **Saisie du jour** : 3 morts, 40 kg d'aliment, poids 1,2. Essayer d'abord 9999 morts pour montrer l'erreur.
5. Montrer la mortalité qui change partout. Faire 2 autres saisies → **pub interstitielle**.
6. **Historique** : courbe de poids animée.
7. **Vaccins** : ajouter « Maladie de Newcastle » avec rappel, puis le cocher (rebond).
8. **Ventes** : vente de 50 dindes → le bénéfice et l'effectif vivant changent.
9. **Ma ferme** : toucher la carte ailleurs → la météo change.
10. **Réglages** : thème sombre, puis l'arabe (tout s'inverse), puis retour au français.
11. **Bonus** : mode avion → bandeau « Hors ligne » → saisie → réseau rétabli.
