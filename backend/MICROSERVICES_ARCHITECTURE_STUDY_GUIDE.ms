.TL
TeamOps Microservices Architecture
.AU
Study guide and migration reference
.DA
September 2026

.NH 1
Purpose
.PP
This document is a practical architecture reference for evolving TeamOps from a Django monolith into a set of independently deployable microservices. The goal is not to maximize the number of services. The goal is to make business boundaries, ownership, and scaling clear while preserving delivery speed and reliability.

.NH 1
Target architecture
.PP
Clients call an API gateway or Backend for Frontend (BFF). The gateway routes requests to the service that owns the capability. Each service owns its own data and can be deployed independently.
.PP
Frontend
.br
  |-- API gateway / BFF
.br
       |-- Auth service             -> PostgreSQL database
.br
       |-- Product / Workspace      -> PostgreSQL database
.br
       |-- Project service          -> PostgreSQL database
.br
       |-- Task service             -> PostgreSQL database
.br
       `-- Notification service     -> database and message queue
.PP
Shared infrastructure includes a message broker such as RabbitMQ, Redis where justified, centralized logs, metrics, tracing, and secret management.

.NH 1
Recommended service boundaries
.IP "Auth / Identity" 18
Users, registration, passwords, login, refresh tokens, email verification, password reset, roles, and authentication audit records.
.IP "Product / Workspace" 18
Organizations, workspaces, workspace membership, invitation lifecycle, and subscription-related ownership.
.IP "Project" 18
Projects, project configuration, and project membership policies.
.IP "Task" 18
Tasks, comments, labels, assignees, due dates, and workflow/status changes.
.IP "Notification" 18
Email, in-app notifications, delivery preferences, and fan-out of activity events.

.NH 1
Non-negotiable design rules
.IP "1." 5
Every service owns its database. A service must never read or write another service's tables.
.IP "2." 5
Share contracts, not domain models. A small versioned package may contain logging helpers, JWT validation utilities, standardized error formats, and event schemas. It must not contain shared ORM models.
.IP "3." 5
Use synchronous HTTP/gRPC calls only when an immediate response is required. Use events for propagation and background work.
.IP "4." 5
Design every consumer to be idempotent: processing the same event twice must be safe.
.IP "5." 5
Do not use distributed database transactions. Prefer local transactions, retries, compensating actions, and the transactional outbox pattern.

.NH 1
Authentication and authorization model
.PP
The Auth service is the identity authority. It authenticates a user and issues a short-lived access token plus a longer-lived refresh token. Prefer asymmetric JWT signing (for example RS256 or EdDSA). The Auth service keeps the private key; other services retrieve public keys from a JWKS endpoint and validate tokens locally.
.PP
An access token should minimally include the subject (the user UUID), issued-at and expiry times, issuer, audience, and only stable authorization claims that are appropriate for the token lifetime. Do not place sensitive profile data or large membership lists in a JWT.
.PP
The Product, Project, and Task services should validate the JWT signature locally rather than call Auth for every request. They then authorize locally based on the resource: for example, the Task service checks whether the authenticated user UUID is permitted to access that task's workspace and project.
.PP
Use UUIDs as externally visible IDs. They avoid exposing sequential record counts and work well across service boundaries.

.NH 1
Communication patterns
.IP "Request-response" 18
Use an API call when the caller needs an answer now: creating a task, reading a project, or validating a command.
.IP "Domain event" 18
Use RabbitMQ initially for events such as user.created, workspace.member_added, project.created, task.assigned, and task.completed. It is an approachable first broker for this system.
.IP "Outbox pattern" 18
When a service changes its database, it writes the domain event to an outbox table in the same local transaction. A worker publishes that outbox record to the broker. This prevents a successful database commit from silently losing its event.

.NH 1
Migration plan
.IP "Phase 1: strengthen the modular monolith" 26
Keep the current Django deployment while the product is small. Define module boundaries, APIs, ownership, automated tests, and Docker-based local development.
.IP "Phase 2: extract Auth" 26
Turn the current accounts app into its own Auth service. Add UUID user IDs, login, access and refresh token rotation, password reset, email verification, throttling, security/audit logs, health checks, migrations, and its own PostgreSQL database.
.IP "Phase 3: introduce Product / Workspace" 26
Create a separate service and database for workspaces and memberships. The workspace service stores the auth user UUID as an external reference, never as a foreign key to the Auth database.
.IP "Phase 4: extract Project and Task" 26
Extract only after those domains have real functionality and clear ownership. Start with a single Task service rather than splitting comments, labels, and assignments into separate services.
.IP "Phase 5: introduce events" 26
Add RabbitMQ and the outbox pattern for cross-service activity. Use events for notifications, search indexing, analytics, and projections.
.IP "Phase 6: production readiness" 26
Add structured logs with correlation IDs, metrics, tracing, backups, alerting, CI/CD, image scanning, secret management, and rate limits. Kubernetes is optional; Docker Compose is sufficient for local development and early deployment.

.NH 1
Repository layout
.PP
TeamOps/
.br
  services/
.br
    auth-service/
.br
    product-service/
.br
    project-service/
.br
    task-service/
.br
    notification-service/
.br
  packages/
.br
    common/              # Small shared technical utilities only
.br
    contracts/           # Versioned API and event schemas
.br
  infrastructure/
.br
    docker-compose.yml
.br
    gateway/

.NH 1
Operational checklist
.IP "Security" 18
TLS everywhere, hashed passwords, refresh token rotation and revocation, key rotation, request throttling, strict CORS policy, secrets outside source control, dependency scanning, and audit logs for authentication and privileged actions.
.IP "Reliability" 18
Health and readiness endpoints, timeouts, retry limits, circuit breakers where appropriate, idempotency keys for write APIs, backups that are tested by restoration, and dead-letter queues for failed events.
.IP "Observability" 18
Structured JSON logs, a correlation/trace ID propagated between gateway and services, metrics for latency/error rates/queue depth, and distributed tracing using OpenTelemetry.
.IP "Data" 18
Per-service migrations, no cross-database joins, explicit data retention policy, and event schemas that are backward compatible.

.NH 1
What to avoid
.IP "1." 5
Do not split into many services before the domain warrants it. Each service adds deployment, testing, monitoring, security, and incident-response cost.
.IP "2." 5
Do not use a shared database as the integration mechanism.
.IP "3." 5
Do not make Auth a required network call for each user request.
.IP "4." 5
Do not add Kubernetes merely because services exist. Use it when operational needs justify it.
.IP "5." 5
Do not make cross-service calls in long chains. They are slow and fragile; prefer a direct owner or asynchronous events.

.NH 1
First implementation milestone
.PP
The best first milestone is an independently deployable Auth service. It should provide registration, login, token refresh, logout/revocation, email verification, password reset, JWKS, OpenAPI documentation, health endpoints, automated tests, and its own PostgreSQL database. Then create the Product / Workspace service and integrate it by validating Auth-issued JWTs locally.
.PP
This sequence gives TeamOps a secure identity foundation without prematurely creating a complex distributed system.
