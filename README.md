[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/harness-open-sourc-1?utm_medium=integration&utm_source=button&utm_campaign=harness-open-source)

# Harness Open Source on Railway

A one-click Railway template for [Harness Open Source](https://github.com/harness/harness) (formerly Gitness, Apache-2.0): Git hosting with pull requests and code review, a built-in artifact and container registry, and secrets, on your own Postgres.

## What it deploys

| Service | Source | State |
|---|---|---|
| **Harness** | this repo: `harness/harness:3.3.0`, pinned by digest `sha256:c1bd7681…9e83f` | volume at `/data`: Git repositories, uploads, registry blobs, SSH host key |
| **Postgres** | Railway's Postgres | volume at `/var/lib/postgresql/data`: users, spaces, pull requests, settings |

- The public domain serves the web UI, the REST API (`/api`), Git over HTTPS (`/git/...`) and the registry.
- Git over SSH runs through a Railway TCP proxy to port 3022. The clone URLs in the UI show the proxy's address.
- Health check: `/api/v1/system/health`.
- `start.sh` keeps every piece of state under `/data`. Upstream keeps uploads in `~/.gitness/blob` and the SSH host key in `/app/ssh`, which would be lost (and the host key would change) on every redeploy.

## First login

The admin account is created on the first boot:

- **User:** `admin`, or the email you entered at deploy (`GITNESS_PRINCIPAL_ADMIN_EMAIL`).
- **Password:** the generated `GITNESS_PRINCIPAL_ADMIN_PASSWORD` on the Harness service (Railway → Harness → Variables). Change it in your profile after the first login. Changing the variable later does not change the password.

Open sign-up is off, so strangers can't create accounts. Add users from **Admin → Users**, or set `GITNESS_USER_SIGNUP_ENABLED=true` to open sign-up.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `GITNESS_PRINCIPAL_ADMIN_EMAIL` | asked at deploy | Email of the admin account created on first boot |
| `GITNESS_PRINCIPAL_ADMIN_PASSWORD` | `${{secret(24)}}` | Initial admin password |
| `GITNESS_ENCRYPTER_SECRET` | `${{secret(32)}}` | Encrypts stored secrets. Must be exactly 32 characters. Never change it after the first boot |
| `GITNESS_REGISTRY_HTTP_SECRET` | `${{secret(32)}}` | Signs registry upload sessions |
| `GITNESS_URL_BASE` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL used for links, clone URLs and the registry. Set it to your custom domain if you add one |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Postgres connection. Remove it to use SQLite on the volume instead |
| `PORT` | `3000` | HTTP port |

Any other [Harness setting](https://github.com/harness/harness/blob/v3.3.0/types/config.go) can be added as a `GITNESS_*` variable, for example SMTP (`GITNESS_SMTP_HOST`, `GITNESS_SMTP_PORT`, `GITNESS_SMTP_USERNAME`, `GITNESS_SMTP_PASSWORD`, `GITNESS_SMTP_FROM_MAIL`).

## What doesn't run on Railway

- **Pipelines (CI/CD) and Gitspaces** start Docker containers, and Railway gives services no Docker host. Gitspaces are turned off. To run pipelines, point `GITNESS_DOCKER_HOST` at a Docker host you run elsewhere.

## Updates

Railway tells everyone who deployed this template when a change lands on this repo's `main` branch. A version bump changes the pinned image in `Dockerfile`, and [CHANGELOG.md](CHANGELOG.md) lists what changed, with breaking changes first. Read it, then apply the update from your Railway project. Harness migrates its database schema itself on start.

Note: Harness's GitHub releases also carry Drone tags (`v2.x`, branch `drone`). This template follows the Harness Open Source releases (`v3.x`) on Docker Hub as `harness/harness`.

## Run it elsewhere

```sh
docker build -t harness-railway .
docker run -p 3000:3000 -v harness-data:/data \
  -e GITNESS_URL_BASE=http://localhost:3000 \
  -e GITNESS_ENCRYPTER_SECRET=<32 characters> \
  -e GITNESS_PRINCIPAL_ADMIN_EMAIL=you@example.com -e GITNESS_PRINCIPAL_ADMIN_PASSWORD=<password> \
  harness-railway
```

Without `DATABASE_URL` it uses SQLite on the volume. Upstream docs: https://developer.harness.io/docs/open-source (settings: https://developer.harness.io/docs/open-source/installation/settings)
