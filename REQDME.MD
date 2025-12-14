lib/
├── main.dart
├── core/
│   ├── firebase_config.dart
│   ├── constants/
│   │   └── app_constants.dart
│   └── services/
│       ├── auth_service.dart
│       └── project_service.dart
├── models/
│   ├── user_model.dart
│   ├── project_model.dart
│   └── task_model.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── role_selection_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   ├── projects/
│   │   ├── screens/
│   │   │   ├── project_list_screen.dart
│   │   │   ├── project_detail_screen.dart
│   │   │   └── qr_generator_screen.dart
│   │   └── widgets/
│   │       └── project_card.dart
│   └── qr_scanner/
│       ├── screens/
│       │   └── qr_scanner_screen.dart
│       └── services/
│           └── qr_service.dart
├── shared/
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_textfield.dart
│   │   └── loading_indicator.dart
│   └── utils/
│       └── validators.dart
└── navigation/
└── app_router.dart