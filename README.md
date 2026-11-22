# Dindo : gestion d'un élevage de dindes

Application iOS (SwiftUI + Firebase) pour suivre un élevage de dindes, **bande par bande**.
Une bande est un lot de dindonneaux arrivés le même jour dans un bâtiment.

## Fonctionnalités

- Connexion par e-mail/mot de passe et par Google, inscription, mot de passe oublié.
- Tableau de bord : dindes vivantes, mortalité, ventes, météo du jour avec un conseil pour les dindes.
- Bandes : création et modification, âge (J+), effectif vivant, mortalité, poids moyen, indice de consommation.
- Saisie du jour : morts, aliment, eau et poids moyen, puis historique et courbe de poids (Swift Charts).
- Vaccins : programme de la bande, rappel par notification le jour du vaccin à 8 h.
- Ventes et dépenses : bénéfice estimé de la bande.
- Ma ferme : carte MapKit (toucher pour placer la ferme) et prévisions météo sur 5 jours.
- Réglages : thème clair/sombre/système, langue français/anglais/arabe (de droite à gauche), déconnexion.

## Écrans (15)

| # | Écran | Fichier |
|---|---|---|
| 1 | Connexion | `Views/Auth/LoginView.swift` |
| 2 | Inscription | `Views/Auth/SignUpView.swift` |
| 3 | Mot de passe oublié | `Views/Auth/ForgotPasswordView.swift` |
| 4 | Tableau de bord | `Views/DashboardView.swift` |
| 5 | Liste des bandes | `Views/Flocks/FlockListView.swift` |
| 6 | Nouvelle bande / modifier | `Views/Flocks/FlockFormView.swift` |
| 7 | Fiche d'une bande | `Views/Flocks/FlockDetailView.swift` |
| 8 | Saisie du jour | `Views/Flocks/RecordFormView.swift` |
| 9 | Historique et courbe de poids | `Views/Flocks/HistoryView.swift` |
| 10 | Vaccins | `Views/Flocks/VaccinesView.swift` |
| 11 | Nouveau vaccin | `Views/Flocks/VaccineFormView.swift` |
| 12 | Ventes et dépenses | `Views/Flocks/FinanceView.swift` |
| 13 | Nouvelle opération | `Views/Flocks/MoneyFormView.swift` |
| 14 | Ma ferme (carte + météo) | `Views/FarmView.swift` |
| 15 | Réglages | `Views/SettingsView.swift` |

## Exigences du mini-projet

| Exigence | Où |
|---|---|
| SwiftUI | Toute l'app |
| Firebase Auth (e-mail + Google) | `Services/AuthService.swift` |
| Cloud Firestore | `Services/FlockService.swift`, `Services/FlockDataService.swift` |
| ≥ 9 interfaces + navigation | 15 écrans, `TabView` + `NavigationStack` + feuilles (`sheet`) |
| Formulaires validés | `Models/Validation.swift` + 6 formulaires (messages rouges sous les champs) |
| API REST | Open-Meteo : `Services/WeatherService.swift`, `Models/Weather.swift` |
| Animations | Logo de connexion, cartes du tableau de bord, chiffres qui défilent, icône météo qui pulse, courbe de poids, coche des vaccins, messages d'erreur, listes |
| Thème clair / sombre | `Models/AppSettings.swift` + Réglages |
| FR / EN / AR | `Resources/*.lproj/Localizable.strings` |
| Chargement, erreurs, états vides | `Views/Components.swift` + `ContentUnavailableView` sur chaque liste |
| Banner + Interstitial (ID de test) | `Services/Ads.swift` : bannière sur l'accueil, interstitielle toutes les 3 saisies |
| Bonus hors ligne | Cache Firestore (bandeau « Hors ligne ») + dernière météo gardée sur le téléphone |
| Bonus Maps | `Views/FarmView.swift` (MapKit) |

## Données Firestore

```
users/{uid}                      nom, e-mail
users/{uid}/flocks/{idBande}     nom, date d'arrivée, effectif, souche, bâtiment, morts, vendues
   ├── records/{id}              saisie du jour : date, morts, aliment, eau, poids moyen
   ├── vaccines/{id}             nom, date, fait ou non
   └── money/{id}                vente ou dépense : libellé, montant, dindes vendues, date
```

Les champs `deaths` et `sold` de la bande sont des compteurs. Ils sont mis à jour à chaque saisie et à chaque vente avec `FieldValue.increment`, ce qui évite de relire toutes les saisies pour afficher le tableau de bord.

## Installation (sur le Mac de l'école)

1. **Firebase** : déjà configuré, dans le projet Firebase **dindo** (`dindo-752c1`).
   - Authentication : E-mail/Mot de passe et Google activés.
   - Firestore (Europe, `eur3`) avec les règles de `firestore.rules`.
   - App iOS `com.dindo.app` : son `GoogleService-Info.plist` est dans `Dindo/Resources/` (il est aussi sur GitHub).
2. **Info.plist** (à la racine) : contient déjà le `REVERSED_CLIENT_ID`, nécessaire pour revenir dans l'app après la connexion Google.
3. Ouvrez `Dindo.xcodeproj` dans Xcode 16.2. Les paquets (Firebase 11, GoogleSignIn 8, Google Mobile Ads 12) se téléchargent tout seuls.
4. Choisissez un simulateur iPhone, puis Product → Run.

Cible : iOS 17. Le projet a le même réglage que Matbakhi, qui compile avec Xcode 16.2.
