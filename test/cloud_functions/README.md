# Tests des fonctions Stripe

Pour générer les fichiers mock, exécutez la commande suivante:

```bash
flutter pub run build_runner build
```

Cela générera le fichier `stripe_functions_test.mocks.dart` nécessaire pour les tests.

## Notes importantes

1. Assurez-vous que votre `pubspec.yaml` contient bien les dépendances suivantes pour les tests:
   - `mockito`
   - `build_runner` (en dev_dependencies)

2. Si vous rencontrez des erreurs avec `MockFirebaseFunctionsService`, vérifiez que la version de mockito est compatible avec le code généré.
