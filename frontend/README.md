# Paper Rabbit Flutter client

The cross-platform client for Paper Rabbit. It provides academic search, paper details,
citation exploration, and a persistent research-library workflow.

See the [project README](../README.md) for complete setup, architecture, configuration,
testing, and current feature status.

For a local web session with the backend on port 8080:

```powershell
flutter pub get
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```
