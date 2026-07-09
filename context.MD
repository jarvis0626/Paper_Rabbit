# Paper Rabbit — Project Summary & End-to-End Pipeline

## 1. Project Summary

**What it is:** A mobile app (Flutter + Spring Boot) that lets students/researchers search academic papers and explore them through an interactive citation graph, rather than a flat list. Papers are nodes, citations are edges. Users can search, view paper details, expand/collapse citation branches, and bookmark papers into collections.

**Why it's a good FYP:** It combines a relational store (Postgres), a graph store (Neo4j), a non-trivial interactive UI (graph rendering with pan/zoom/expand), external API integration (Semantic Scholar/OpenAlex), and — with the ML extension — a real vector-search/recommendation component. It's not just CRUD with a nice theme; the graph and the ML layer give you defensible "hard parts" to discuss in a viva.

**Core user journey:**
`Sign in → Search → View paper → Explore citation graph → Bookmark papers`

**ML extension (recommended):** SPECTER2 paper embeddings + `pgvector` for semantic search, optionally layered with Neo4j graph-based recommendations (Node2Vec) that reuse the citation graph you already built.

---

## 2. High-Level Architecture

```
┌─────────────────────────────┐
│        Flutter App          │
│  (Riverpod + GoRouter+Dio)  │
└──────────────┬───────────────┘
               │ REST (JSON) + JWT
               ▼
┌─────────────────────────────┐
│      Spring Boot Backend     │
│  controller → service →      │
│  repository → external APIs  │
└──────┬───────────┬───────────┘
       │           │
       ▼           ▼
┌─────────────┐ ┌─────────────┐       ┌──────────────────────┐
│ PostgreSQL   │ │   Neo4j     │       │ External Data Source │
│ users,       │ │ Paper/Author│◄──────┤ Semantic Scholar API │
│ bookmarks,   │ │ /Institution│       │ OpenAlex API (fallback)│
│ paper cache, │ │ CITES/WROTE │       └──────────────────────┘
│ embeddings   │ │ /WORKS_AT   │
│ (pgvector)   │ └─────────────┘
└─────────────┘
```

Two databases exist because they solve different problems:
- **Postgres** — transactional data: users, auth, bookmarks, cached paper metadata, and (later) embedding vectors via `pgvector`.
- **Neo4j** — the citation graph itself. Recursive citation traversal (references, citations, 2-hop expansion) is a natural fit for a graph DB and painful in pure SQL.

---

## 3. End-to-End Pipeline (Build Order)

Build in this order — each phase is independently testable and unlocks the next.

### Phase 0 — Project Scaffolding
- Set up Flutter project with the clean architecture folder structure (`core/`, `features/`, `services/`, `widgets/`).
- Set up Spring Boot project (Maven, Java 21) with `controller/service/repository/model/dto/config/security`.
- Set up Postgres + Neo4j locally (Docker Compose is the easiest path — one file spins up both).
- Set up Dio interceptors in Flutter for JWT attachment and centralized error handling.
- **Output:** empty but running app + empty but running API, both talking to their respective databases.

### Phase 1 — Authentication
- Backend: `POST /auth/register`, `POST /auth/login`, JWT issuing + validation filter, Spring Security config, password hashing (BCrypt).
- Postgres: `users` table (id, email, password_hash, created_at).
- Flutter: `features/auth/` — login/register screens, token storage (flutter_secure_storage), Riverpod `AuthProvider` that gates routing via GoRouter redirect logic.
- **Output:** a user can register, log in, and reach a protected home screen. Logout clears the token.

### Phase 2 — External Data Ingestion Layer
This is the backend service that talks to Semantic Scholar/OpenAlex and normalizes their responses into your own DTOs — build this *before* search, since search depends on it.
- `PaperApiClient` interface with two implementations: `SemanticScholarClient`, `OpenAlexClient` (fallback if primary fails or rate-limits).
- Normalize both APIs' responses into a single internal `PaperDto` (title, authors, year, venue, citationCount, abstract, references[], citations[], externalId).
- Cache fetched papers into Postgres (`papers` table) so repeat lookups don't re-hit the external API.
- **Output:** an internal service method `getPaperById(id)` that works regardless of which upstream API actually served the data.

### Phase 3 — Search
- Backend: `GET /papers/search?q=` → calls the ingestion layer → returns a list of `PaperSummaryDto` (title, authors, year, citationCount, abstract preview).
- Flutter: `features/search/` — search bar, results list, loading/error states, pull-to-refresh.
- Cache recent searches locally (Hive or shared_preferences) for the "Recent searches" home screen section.
- **Output:** user types a query, sees a real list of papers from Semantic Scholar.

### Phase 4 — Paper Details
- Backend: `GET /papers/{id}`, `GET /papers/{id}/references`, `GET /papers/{id}/citations` — all backed by the ingestion layer from Phase 2.
- Flutter: `features/paper/` — detail screen with full abstract, venue, year, citation count, Save/Share/Open PDF buttons.
- **Output:** tapping a search result shows a full detail page with working references/citations lists (still as flat lists at this point — the graph comes next).

### Phase 5 — Bookmarks
- Backend: `POST /bookmarks`, `DELETE /bookmarks/{id}`, `GET /bookmarks`. Postgres tables: `bookmarks` (user_id, paper_id, collection_id, created_at) and `collections` (id, user_id, name).
- Flutter: `features/bookmarks/` — save/remove buttons wired into paper detail and search result cards, a bookmarks tab with collection filtering.
- **Output:** save state persists and is reflected across search results, paper detail, and a dedicated bookmarks screen.

### Phase 6 — Neo4j Sync + Citation Graph (the hard part — budget the most time here)
- Whenever a paper is fetched via Phase 2's ingestion layer, also upsert it into Neo4j: `MERGE (:Paper {externalId})`, plus `(:Paper)-[:CITES]->(:Paper)` edges for each reference/citation, and `(:Author)-[:WROTE]->(:Paper)` / `(:Author)-[:WORKS_AT]->(:Institution)` where available.
- Backend: a graph-specific endpoint, e.g. `GET /papers/{id}/graph?depth=1`, that runs a Cypher query to pull the local citation neighborhood (not just direct references/citations — this is what makes it a *graph* view rather than two lists).
- Flutter: `features/graph/` — pick a graph rendering package (e.g. `graphview` or a custom `CustomPainter` + `flutter_force_directed` style layout), implement:
  - Node = paper (title truncated, citation count as node size/color intensity)
  - Edge = citation direction
  - Pinch-to-zoom, drag-to-pan (`InteractiveViewer` is a good base)
  - Tap node → expand its references/citations (lazy-load via the graph endpoint, add new nodes/edges to the local graph state)
  - Collapse a branch → remove its descendant nodes from view
  - Highlight the selected node (color/border change via Riverpod state)
- **Output:** the signature feature — tap into a paper, see its citation neighborhood, expand outward interactively.

### Phase 7 (ML) — Semantic Search via Embeddings
- Enable `pgvector` extension on Postgres; add an `embedding vector(768)` column to the `papers` table (SPECTER2 embeddings are 768-dim).
- Build an ingestion job: for each paper cached in Phase 2, fetch or compute its SPECTER2 embedding (Semantic Scholar exposes these for most indexed papers; otherwise run SPECTER2 yourself via a small Python microservice or ONNX runtime).
- Backend: add `RecommendationService` interface with method `findSimilarPapers(paperId, limit)` — implemented via `pgvector`'s cosine distance operator (`<=>`).
- Add a semantic search mode alongside keyword search: `GET /papers/search?q=&mode=semantic` embeds the query and does a vector similarity lookup instead of keyword match.
- **Output:** "Papers like this" section on paper detail, and a semantic search toggle that returns conceptually related papers, not just keyword matches.

### Phase 8 (ML, stretch) — Graph-Based Recommendations
- Run Node2Vec (or a simpler graph embedding) offline over your Neo4j citation graph to produce graph-based paper embeddings.
- Combine with Phase 7's content embeddings for a hybrid recommendation score, or keep them as two separate "Similar by topic" vs. "Similar by citation network" sections — the latter is a nice, explainable comparison to put in your report (content similarity vs. structural similarity).
- **Output:** a recommendation feature that visibly uses the graph you built, not just an API bolt-on.

### Phase 9 — Polish, Testing, Deployment
- Dark mode (Material 3 theming), animations (page transitions, node expand/collapse animation).
- Unit tests: service layer (backend), widget tests (Flutter), repository mocks.
- Offline cache: last-viewed papers and bookmarks available without network (Hive/Isar on Flutter side).
- Deployment: Dockerize backend + Postgres + Neo4j via Docker Compose; deploy to a free/cheap tier (Railway, Render, or a university-provided VM) for your demo; Flutter app built as APK for examiners to install directly.

---

## 4. Example Request Flow (concrete trace)

User searches "transformer attention" →
1. Flutter `SearchScreen` calls `SearchRepository.search(query)` via Dio.
2. Hits `GET /papers/search?q=transformer+attention`.
3. Spring Boot `PaperController` → `PaperService.search()` → `PaperApiClient.search()` (Semantic Scholar first, OpenAlex on failure).
4. Results normalized to `PaperSummaryDto[]`, cached into Postgres `papers` table (upsert), returned as JSON.
5. Flutter renders result list via Riverpod `AsyncNotifier`.
6. User taps a result → `GET /papers/{id}` → same ingestion layer, also triggers async Neo4j upsert of that paper + its direct citation edges.
7. User taps "View Graph" → `GET /papers/{id}/graph?depth=1` → Cypher query returns neighborhood → Flutter graph widget renders nodes/edges.
8. User taps a neighboring node → new `GET /papers/{id}/graph?depth=1` call for that node → merged into existing graph state, animated in.
9. User taps Save → `POST /bookmarks` → Postgres `bookmarks` row created → UI updates save icon state everywhere via Riverpod provider invalidation.

---

## 5. Suggested Timeline (for a typical 6–8 month FYP)

| Weeks | Phase |
|---|---|
| 1–2 | Phase 0 scaffolding, Docker Compose setup |
| 3–4 | Phase 1 auth |
| 5–6 | Phase 2 ingestion layer + Phase 3 search |
| 7–8 | Phase 4 paper details |
| 9–10 | Phase 5 bookmarks |
| 11–16 | Phase 6 citation graph (heaviest phase — do not underestimate) |
| 17–20 | Phase 7 semantic search / embeddings |
| 21–22 | Phase 8 graph recommendations (stretch, cut first if behind schedule) |
| 23–24+ | Phase 9 polish, testing, deployment, report writing |

If you're behind schedule at any point, cut Phase 8 first, then trim Phase 9 polish — never cut time from Phase 6, since the graph is your most demo-able and most defensible feature in a viva.