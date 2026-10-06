# Démo Flutter : recherche de voiture (Connexion, OnBoarding, Feed)

Date : 2026-10-06

## Objectif

Application de démonstration Flutter (web, mobile-first) déployée sur GitHub Pages. Trois écrans : Connexion/Inscription, OnBoarding (formulaire de recherche) et Feed (fiche véhicule). Les données sont fictives.

## Décisions validées

- Comptes gérés par Firebase Auth (email / mot de passe), sans base de données.
- Vérification email par code à 6 chiffres **simulée** : le code est généré côté client et affiché dans un bandeau « Mode démo ». Aucun email n'est envoyé.
- Firebase Auth n'envoie pas de code à 6 chiffres, seulement un lien. GitHub Pages est statique. Un code côté client n'est pas sécurisé. La version production demanderait une Cloud Function (plan Blaze).
- Pas de projet Firebase existant : un guide de création est fourni, la config est à renseigner.
- Architecture : `go_router`, `provider` (`ChangeNotifier`), interface `AuthRepository` avec implémentations Firebase et mock.

## Structure

```
lib/
  main.dart, app.dart, router.dart
  core/        theme, validators, widgets communs (logo)
  auth/        auth_repository.dart, firebase_auth_repository.dart,
               mock_auth_repository.dart, verification_code_service.dart,
               login_page, signup_page, verify_code_page
  onboarding/  search_criteria.dart, onboarding_page, brand_button, crit_air_section
  feed/        vehicle.dart, feed_page, photo_carousel
assets/        logos de marques (SVG dessinés), photos du véhicule
.github/workflows/deploy.yml
```

## Authentification

- **Inscription** : email, mot de passe, confirmation. Règles : au moins 8 caractères, 1 majuscule, 1 caractère spécial, avec retour visuel en direct. Appel à `createUserWithEmailAndPassword`, génération du code, passage à l'écran de vérification.
- **Code simulé** : conservé en mémoire et dans `localStorage`, avec l'état « vérifié » par utilisateur. La page précise que ce n'est pas sécurisé.
- **Connexion** : si l'email n'est pas vérifié, redirection vers la saisie du code. Après validation, redirection vers l'OnBoarding.
- **Garde de routes** : redirection vers `/login` si l'utilisateur n'est pas connecté.

## OnBoarding

- Logo.
- Achat / Location : `SegmentedButton`.
- Lieu : « Autour de moi » (géolocalisation simulée) ou liste de villes (Paris, Lyon, Marseille, Lille, Toulouse, Bordeaux).
- Motorisation : chips Essence, Diesel, Hybride, Électrique.
- Puissance : `RangeSlider` de 60 à 1000 ch.
- Marques : 4 boutons (Peugeot, Renault, Audi, BMW), logo à gauche du libellé.
- Crit'Air : case à cocher, au clic un texte explicatif apparaît (« De quelle vignette ai-je besoin pour circuler dans ma ville ? »).
- « Valider » enregistre les critères et ouvre `/feed`. Aucune recherche réelle.

## Feed

- Carte véhicule avec carousel de 3 photos (indicateurs en points, balayage).
- Caractéristiques fictives : marque, modèle, prix, kilométrage, année, motorisation, puissance, Crit'Air, ville, et une description.
- Icône filtre : retour à `/onboarding`, critères conservés.
- Bouton « Je souhaite être contacté » : sans action.
- Bouton « Retour à l'accueil » : vers `/onboarding`.

## Déploiement

- `flutter build web --release --base-href /<repo>/`.
- Workflow GitHub Actions publiant sur GitHub Pages.
- `HashUrlStrategy` (pas de routes profondes sur Pages).
- Config Firebase injectée via `--dart-define`. Le domaine `*.github.io` doit être autorisé dans Firebase Auth.
- Le dépôt GitHub public n'est créé qu'avec l'accord explicite de l'utilisateur.

## Tests

- Unitaires : validateur de mot de passe, service de code.
- Widgets : formulaire OnBoarding, navigation.
- Aucun test Firebase réel, tout passe par le mock.

## Hypothèses à confirmer

- Photos libres de droits embarquées dans les assets, et logos de marques dessinés (placeholders).
- Nom de l'app : « Autoscope », ou un autre nom neutre au choix.
