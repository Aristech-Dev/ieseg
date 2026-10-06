# Autoscope : démo Flutter

Démo web mobile-first : Connexion/Inscription, OnBoarding (recherche de voiture), Feed (fiche véhicule). Données fictives.

## Lancer en local

```bash
flutter pub get
flutter run -d chrome   # sans config Firebase : mode démo (comptes en mémoire)
flutter test
```

## Vérification email (démo)

Firebase Auth n'envoie pas de code à 6 chiffres (seulement un lien) et GitHub Pages est statique. Le code à 6 chiffres est donc **généré et stocké côté client** (localStorage) puis **affiché dans un bandeau « Mode démo »**. Aucun email n'est envoyé et ce n'est **pas sécurisé**. En production : une Cloud Function (plan Blaze) générerait, enverrait et vérifierait le code.

## Configurer Firebase (4 étapes)

1. Console Firebase → **Ajouter un projet**.
2. **Authentication → Méthode de connexion** → activer **Adresse e-mail/Mot de passe**. Dans **Paramètres → Domaines autorisés**, ajouter `<utilisateur>.github.io`.
3. **Paramètres du projet → Vos applications → Web (`</>`)** → enregistrer l'app et copier la config (`apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`).
4. Dépôt GitHub → **Settings → Secrets and variables → Actions** : créer `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`.

En local avec Firebase :
```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=...
```

## Déploiement GitHub Pages

Dépôt GitHub → **Settings → Pages → Source : GitHub Actions**. Chaque push sur `main` lance `.github/workflows/deploy.yml` (analyse, tests, build, publication). Sans secrets, le site est publié en mode démo (comptes en mémoire).

## Remplacer les visuels

Les logos de marques (`assets/brands/`) et les visuels véhicule (`assets/photos/`) sont des illustrations SVG. Pour utiliser de vraies photos, déposer les fichiers dans `assets/photos/` et mettre à jour `Vehicle.demo.photos` dans `lib/feed/vehicle.dart`.

Formats supportés : **SVG, JPEG, PNG, WebP, GIF**. L'**AVIF n'est pas supporté** par le décodeur d'images de Flutter web (un repère « image cassée » s'affiche à la place). Conversion rapide en WebP : `magick photo.avif -quality 85 photo.webp`.
