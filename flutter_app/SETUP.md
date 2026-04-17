# EXPERIMMO Flutter App

Application mobile Flutter de gestion immobilière multi-rôles (Admin, Propriétaire, Locataire, Gestionnaire) connectée à Supabase.

## Prérequis

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / VS Code avec extensions Flutter/Dart
- Émulateur Android ou appareil physique (Android)
- Xcode (pour iOS, macOS uniquement)

## Installation

1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd flutter_app
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configuration Supabase**
   - Copier le fichier `.env.example` vers `.env` (déjà fourni)
   - Mettre à jour les clés si nécessaire (URL et ANON KEY déjà configurés)

4. **Lancer l'application**
   ```bash
   flutter run
   ```

## Architecture

### Structure du projet

```
lib/
  app.dart                     # Point d'entrée MaterialApp
  main.dart                   # Initialisation Supabase + runApp
  core/
    constants/
      app_colors.dart         # Couleurs du branding
      app_strings.dart        # Textes (français)
      app_typography.dart      # Polices (Playfair Display + Inter)
    router/
      app_router.dart         # Routes GoRouter
    supabase/
      supabase_client.dart    # Client Supabase + providers
    theme/
      app_theme.dart          # ThemeData
  features/
    admin/
      data/                   # Repository admin
      providers/              # Riverpod providers
      presentation/           # Écrans
    auth/
      data/                   # Repository auth
      providers/              # AuthNotifier
      presentation/           # Login, Register, Forgot
    gestionnaire/
      data/                   # Repository gestionnaire
      providers/              # Providers
      presentation/           # Écrans
    locataire/
      data/                   # Repository locataire
      providers/              # Providers
      presentation/           # Écrans
    proprietaire/
      data/                   # Repository proprietaire
      providers/              # Providers
      presentation/           # Écrans
    splash/
      presentation/           # Splash screen
  shared/
    utils/
      helpers.dart            # Utilitaires (format, toast, etc.)
    widgets/
      app_button.dart         # Bouton réutilisable
      app_logo.dart           # Logo animé
      app_text_field.dart     # Champ texte réutilisable
      loading_widget.dart     # Loading / Error / Empty
      stat_card.dart          # Carte statistique
      status_badge.dart       # Badge statut
```

### Écrans par rôle

- **Admin** : Dashboard + gestion complète (propriétaires, locataires, propriétés, contrats, paiements, factures, opérations, statistiques, messages, paramètres)
- **Propriétaire** : Dashboard + ses biens, contrats, paiements, opérations, messagerie, documents, profil
- **Locataire** : Dashboard + contrat, paiements, factures, échéances, messagerie, documents, profil
- **Gestionnaire** : Dashboard + ses locataires, biens gérés, contrats, opérations, propriétaires, messages, documents

## Configuration Supabase

### Tables principales

- `profiles` : Profils utilisateurs (role, full_name, phone, etc.)
- `proprietaires`, `locataires`, `gestionnaires` : Tables spécifiques par rôle
- `proprietes` : Biens immobiliers
- `contrats` : Contrats de location
- `paiements` : Paiements échéances
- `factures` : Factures (eau, électricité)
- `operations` : Opérations d'entretien
- `messages` : Messagerie interne
- `documents` : Stockage de documents

### RLS (Row Level Security)

Toutes les tables doivent avoir des politiques RLS pour que chaque rôle ne voie que ses propres données.

### Fonctions RPC

- `update_derniere_connexion(p_user_id uuid)` : Met à jour la date de dernière connexion

### Storage

- Bucket `documents-identite` : Pièces d'identité uploadées lors de l'inscription

## Dépendances principales

- `supabase_flutter` : Client Supabase
- `flutter_riverpod` : State management
- `go_router` : Navigation
- `google_fonts` : Polices web
- `cached_network_image` : Images réseau
- `image_picker` : Choix de photos
- `intl` : Formatage dates/monnaie
- `flutter_dotenv` : Variables d'environnement
- `shimmer` : Effet shimmer
- `fl_chart` : Graphiques (optionnel)

## Build & Déploiement

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web (optionnel)

```bash
flutter build web --web-renderer canvaskit
```

## Notes importantes

- L'application utilise les couleurs et polices du branding EXPERIMMO (ruby #C41E3A, charcoal #2C2C2C, gold #c9a84c)
- Les textes sont en français
- Le routing est géré par GoRouter avec redirections selon le rôle après login
- Les données sont chargées via Riverpod providers avec auto-invalidation
- Les écrans sont optimisés pour mobile (bottom nav + AppBar)
- Les images des propriétés sont stockées via URLs dans Supabase Storage

## Dépannage

- **Erreur Supabase** : Vérifier les clés dans `.env` et les politiques RLS
- **Problème de build** : `flutter clean && flutter pub get`
- **Problème de route** : Vérifier `app_router.dart` et les chemins
- **Problème de thème** : Vérifier `app_theme.dart` et `app_colors.dart`

---

**EXPERIMMO** © 2026 - Plateforme de gestion immobilière premium
