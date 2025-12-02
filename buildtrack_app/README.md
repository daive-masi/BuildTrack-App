# 🏗️ BuildTrack - Application de Gestion de Chantiers

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.16.0-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub_Actions-2088FF?logo=github-actions)

**Application mobile moderne pour digitaliser la gestion des chantiers de construction**

</div>

## 🎯 Présentation du Projet

BuildTrack est une application mobile développée en **Flutter** permettant aux entreprises de construction de suivre en temps réel l'avancement des chantiers, la présence des employés et l'état des tâches en temps reel.

### 📱 Fonctionnalités Principales

| Module | Statut | Description |
|--------|---------|-------------|
| 🔐 Authentification | ✅ **Complet** | Email/MDP + Google OAuth |
| 👤 Profil Employé | ✅ **Complet** | Gestion informations personnelles |
| 📊 Dashboard | ✅ **Complet** | Vue d'ensemble des tâches |
| 🏗️ Gestion Tâches | ✅ **Complet** | Statuts, échéances, assignation |
| 📷 QR Codes | 🚧 **En cours** | Pointage chantiers |
| 👨‍💼 Dashboard Admin | 🔄 **Planifié** | Supervision globale |

## 🏗️ Architecture Technique

### 📱 Frontend Mobile
```yaml
Framework: Flutter 3.16.0 (Dart)
Architecture: Modulaire (Feature-First)
State Management: Provider
UI: Material Design 3
Multi-plateforme: Android & iOS
```

### ☁️ Backend & Services
```yaml
Base de données: Firebase Firestore (NoSQL temps réel)
Authentification: Firebase Auth
Stockage: Firebase Storage
Notifications: Firebase Cloud Messaging
Fonctions: Firebase Cloud Functions (Node.js)
```

### 🔄 CI/CD & DevOps
```yaml
Versioning: Git Flow
CI/CD: GitHub Actions
Environnements: Dev/Staging/Prod (Flavors)
Distribution: Firebase App Distribution
Monitoring: Firebase Analytics & Crashlytics
```

## 🚀 Installation & Démarrage

### Prérequis
- Flutter 3.16.0+
- Android Studio / VS Code
- Compte Firebase
- Compte GitHub

### 🛠️ Installation
```bash
# Cloner le repository
git clone https://github.com/daive-masi/BuildTrack-App.git
cd BuildTrack-App

# Installer les dépendances
flutter pub get

# Lancer en mode développement
flutter run --flavor dev
```

### 🏗️ Build Multi-Environnements
```bash
# Développement
flutter run --flavor dev

# Staging
flutter run --flavor staging

# Production
flutter build apk --flavor prod
```

## 📁 Structure du Projet

```
lib/
├── core/                    # Couche métier
│   ├── auth_wrapper.dart   # Gestion état authentification
│   ├── services/           # Services métier
│   └── config/             # Configuration
├── features/               # Modules fonctionnels
│   ├── auth/              # Authentification
│   ├── employee/          # Espace employé
│   ├── profile/           # Gestion profil
│   └── qr_scanner/        # Scanner QR codes
├── models/                 # Modèles de données
└── navigation/             # Gestion navigation
```

## 👥 Équipe de Développement

| Rôle | Membre | Responsabilités |
|------|---------|-----------------|
| 🏗️ Architecte Logiciel | **Daive** | Architecture, Firebase, CI/CD |
| 🎨 UX/UI Designer | **Benjamin** | Design, Expérience utilisateur |
| 💻 Développeur Mobile | **Amine** | Implémentation, Features, Tests |

## 🔄 Méthodologie de Développement

### 📋 Processus Agile
- **Méthodologie** : Scrum
- **Sprints** : 2 semaines
- **Revues** : Weekly meetings
- **Outils** : GitHub Projects, Confluence

### 🌿 Stratégie Git
```bash
# Branches principales
main 🛡️      # Production (protégée)
develop 🛡️   # Intégration (protégée)
feature/*    # Développement nouvelles features
hotfix/*     # Correctifs urgents
```

### ✅ Code Review
- Pull Requests obligatoires
- 2 approbations minimum pour `main`
- 1 approbation pour `develop`
- Templates PR standardisés

## 📊 Métriques de Qualité

| Métrique | Cible | Actuel |
|----------|-------|---------|
| 🧪 Couverture tests | > 80% | 🚧 En cours |
| 📏 Code Analysis | 0 erreurs | ✅ **0 erreurs** |
| 🚀 Performance | 60fps stable | ✅ **Stable** |
| 📱 Taille APK | < 50MB | ✅ **68MB** |
| 🔄 Build Time | < 10min | ✅ **5-7min** |

## 🎯 Fonctionnalités Détaillées

### 🔐 Module d'Authentification
- ✅ Connexion email/mot de passe
- ✅ OAuth Google
- ✅ Gestion sessions persistantes
- ✅ Inscription employés
- ✅ Messages d'erreur en français

### 👤 Espace Employé
- ✅ Dashboard personnalisé
- ✅ Liste des tâches avec statuts
- ✅ Cartes tâches interactives
- ✅ Profil éditable
- ✅ Statistiques personnelles

### 🏗️ Gestion des Tâches
```dart
enum TaskStatus {
  pending,     // ⏳ En attente
  inProgress,  // 🎯 En cours  
  completed,   // ✅ Terminé
  blocked,     // 🚨 Bloqué
}
```

## 🔧 Configuration Technique Avancée

### 🏷️ Flavors & Environnements
```gradle
// android/app/build.gradle
flavorDimensions "environment"
productFlavors {
    dev {
        applicationId "com.buildtrack.dev"
        resValue "string", "app_name", "BuildTrack Dev"
    }
    staging {
        applicationId "com.buildtrack.staging" 
        resValue "string", "app_name", "BuildTrack Staging"
    }
    prod {
        applicationId "com.buildtrack"
        resValue "string", "app_name", "BuildTrack"
    }
}
```

### 🔄 Workflow CI/CD
```yaml
name: Flutter CI/CD
on: [push, pull_request]
jobs:
  quality:
    - flutter analyze
    - flutter test
    - build apk (dev/staging/prod)
  deploy-staging:
    - Firebase App Distribution
```

## 🚀 Roadmap & Évolutions

### ✅ Sprint 1-3 Terminés
- [x] Architecture de base
- [x] Authentification complète
- [x] Profil employé
- [x] Dashboard tâches
- [x] Configuration CI/CD

### 🔄 Sprint 4 En Cours
- [ ] Scanner QR code caméra
- [ ] Dashboard administrateur
- [ ] Gestion tâches avancée
- [ ] Photos preuves

### 📅 Futurs Sprints
- [ ] Notifications push
- [ ] Chat interne
- [ ] Rapports PDF
- [ ] Module matériel

## 📞 Support & Contribution

### 🐛 Signaler un Bug
1. Vérifier les [issues existantes](https://github.com/daive-masi/BuildTrack-App/issues)
2. Créer une nouvelle issue avec le template
3. Inclure logs et étapes reproduction

### 💡 Suggestions d'Amélioration
- Ouvrir une discussion GitHub
- Proposer via Pull Request
- Contactez l'équipe sur Slack

### 🔐 Sécurité
Pour rapporter une vulnérabilité de sécurité :
- Email : daive@buildtrack.com
- **Ne pas ouvrir d'issue publique**

## 📄 Licence

Ce projet est sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

<div align="center">

**Développé avec ❤️ par l'équipe BuildTrack**  
*Suivez. Gérez. Bâtissez intelligemment.* 🏗️

</div>
