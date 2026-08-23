# Paper Rabbit

Paper Rabbit is a cross-platform academic research assistant for discovering scholarly
work, following citation trails, and maintaining a personal reading workflow. The app
uses live [OpenAlex](https://help.openalex.org/api/) metadata rather than bundled or
mock paper data.

## What works today

- Keyword and semantic academic search with pagination.
- Paper details with authors, venue, date, topics, citation counts, abstract, original
  source link, related work, references, and citing papers.
- Interactive citation explorer with pan, zoom, direction-aware links, filters, and
  progressive re-centering on any paper.
- PostgreSQL-backed personal library with reading states, notes, tags, search, filters,
  metadata refresh, and removal.
- Optional Neo4j persistence for paper nodes and directed `CITES` relationships found
  during graph exploration.
- Explicit loading, empty, unavailable, and retry states throughout the main journey.

Paper Rabbit is currently a single-user local application. Authentication, multi-user
data isolation, PDF ingestion, and AI-generated summaries are not implemented. AI work
is intentionally deferred until a real provider, credentials, cost controls, and clear
failure behavior are selected.

## Architecture

```text
Flutter client
    |
    | REST / JSON
    v
Spring Boot API ---------> OpenAlex API
    |                          live scholarly metadata
    +----> PostgreSQL
    |      saved papers, notes, tags, reading states
    |
    +----> Neo4j (optional)
           discovered Paper nodes and CITES relationships
```

The Flutter client uses Riverpod for dependency injection, Dio for HTTP, and GoRouter
for navigation. The Java 21 backend uses Spring Boot, Spring MVC, Spring Data JPA,
Spring Data Neo4j, Flyway, PostgreSQL, and an H2-backed test profile.

## Prerequisites

- Java 21 or newer.
- Flutter with a Dart SDK compatible with `^3.12.2`.
- Docker Desktop or another Docker Compose implementation for PostgreSQL and Neo4j.

An OpenAlex API key is optional for development, but is recommended for sustained use.

## Local setup

### 1. Start PostgreSQL and Neo4j

From the repository root:

```powershell
Set-Location backend
Copy-Item .env.example .env
```

Replace both placeholder passwords in `.env`, then start the infrastructure:

```powershell
docker compose up -d
```

Compose automatically reads `backend/.env`. The backend also imports that file when it
is started from the `backend` directory. `.env` is ignored by Git.

If Neo4j is not wanted, set `GRAPH_PERSISTENCE_ENABLED=false`. Search and the live
citation explorer continue to work without graph persistence.

### 2. Start the backend

On Windows:

```powershell
.\mvnw.cmd spring-boot:run
```

On macOS or Linux:

```bash
./mvnw spring-boot:run
```

Flyway creates or upgrades the personal-library schema before Hibernate validates it.
Once ready:

- API base: `http://localhost:8080/api`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8080/api-docs`
- Health: `http://localhost:8080/actuator/health`

### 3. Start Flutter

In another terminal:

```powershell
Set-Location frontend
flutter pub get
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Android emulators default to `http://10.0.2.2:8080`; web and desktop default to
`http://localhost:8080`. Use `--dart-define=API_BASE_URL=...` for a physical device or
another deployment.

## Configuration

The main backend settings are environment variables or entries in `backend/.env`:

| Variable | Purpose | Default |
| --- | --- | --- |
| `DB_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/paperrabbit_db` |
| `DB_USERNAME` | PostgreSQL user | `paper_rabbit` |
| `DB_PASSWORD` | PostgreSQL password | required |
| `NEO4J_URI` | Neo4j Bolt endpoint | `bolt://localhost:7687` |
| `NEO4J_USERNAME` | Neo4j user | `neo4j` |
| `NEO4J_PASSWORD` | Neo4j password | required by the driver configuration |
| `GRAPH_PERSISTENCE_ENABLED` | Persist explored citation graphs | `false` |
| `OPENALEX_API_KEY` | Optional OpenAlex bearer token | empty |
| `APP_ALLOWED_ORIGINS` | Comma-separated browser origins | localhost ports 3000 and 8080 |

OpenAlex connection timeouts, retry attempts, and backoff can also be overridden with
the `OPENALEX_CONNECT_TIMEOUT`, `OPENALEX_READ_TIMEOUT`, `OPENALEX_MAX_ATTEMPTS`, and
`OPENALEX_INITIAL_BACKOFF` variables.

## API overview

| Method | Route | Purpose |
| --- | --- | --- |
| `GET` | `/api/papers/search` | Keyword or semantic paper search |
| `GET` | `/api/papers/{paperId}` | Full paper metadata |
| `GET` | `/api/papers/{paperId}/related` | Related papers |
| `GET` | `/api/papers/{paperId}/references` | Works referenced by the paper |
| `GET` | `/api/papers/{paperId}/citations` | Works that cite the paper |
| `GET` | `/api/papers/{paperId}/graph` | Directed citation neighborhood |
| `GET` | `/api/library` | List and filter saved papers |
| `POST` | `/api/library` | Save or refresh a paper |
| `GET` | `/api/library/{paperId}` | Read one saved paper |
| `PUT` | `/api/library/{paperId}` | Update status, notes, and tags |
| `DELETE` | `/api/library/{paperId}` | Remove a saved paper |

Search accepts `mode=keyword` or `mode=semantic`, `page`, and `pageSize`. Library list
filters include `status`, `tag`, and `q`. Validation and upstream failures use RFC 9457
Problem Details responses with stable application error codes.

## Testing and verification

Backend tests use H2, run the real Flyway migration, and validate the JPA model against
that migrated schema:

```powershell
Set-Location backend
.\mvnw.cmd test
```

Flutter checks:

```powershell
Set-Location frontend
flutter analyze
flutter test
flutter build web --release
```

The current automated suite covers OpenAlex mapping and failure conversion, search-mode
validation, citation direction and persistence fallback, personal-library CRUD and
filters, client model parsing, app navigation, paper cards, and the library empty state.

## Reliability and data behavior

- OpenAlex calls have bounded connect/read timeouts, retry only rate-limit and server
  failures, and use exponential backoff.
- Missing abstracts and optional metadata are shown as unavailable, not invented.
- Citation graph persistence is best-effort; Neo4j downtime does not block a live graph.
- Re-saving a library paper refreshes bibliographic metadata without overwriting notes,
  tags, or reading status.
- Secrets belong in the ignored `.env` file and are never required in source control.

## Roadmap

- Add authentication before any hosted multi-user deployment.
- Introduce an AI provider interface, consent and cost controls, and evidence-linked
  summaries only after selecting a production provider.
- Add PDF ingestion and section-aware reading tools.
- Add cached graph reads and deeper multi-hop graph expansion.
- Add end-to-end tests against containerized PostgreSQL and Neo4j in CI.

## License

No open-source license has been selected yet. All rights remain with the repository
owner until a license file is added.
