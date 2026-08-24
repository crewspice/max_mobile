# max_mobile

Flutter client for MaxReachPro / MaxHighReach fleet & rental operations.

## Backend

All API calls (`lib/services/api_service.dart`) hit the production server at
`5.78.73.173:8080` directly — there's no local/dev backend for this app. The backend is a
separate sibling repo, `MaxReachPro-API` (Spring Boot), not nested under this directory, so its
`CLAUDE.md` isn't automatically visible from here. If a bug traces back to the server (hangs,
500s, data issues), check `../MaxReachPro-API/CLAUDE.md` — it documents the private Postgres
setup and `root@5.78.73.173` SSH/deploy access via `deploy_api.bat`.
