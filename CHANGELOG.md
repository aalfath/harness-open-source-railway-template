# Changelog

Breaking changes are listed first in each entry.

## 3.3.0 (2026-11-17, README only)

No change to the app, the image or the variables: nothing to do when you apply this update.

- The Deploy on Railway button now links to the published template code `harness-open-sourc-1`. Railway shortens long codes on publish, so the earlier link (`harness-open-source-1`) returned 404.

## 3.3.0 (2026-11-17)

First version of this template.

- Harness Open Source 3.3.0, `harness/harness:3.3.0@sha256:c1bd76817ad7d2e7d78827653a54c55d4aec87c2777a586ebbad1ed01fc9e83f` ([release notes](https://github.com/harness/harness/releases/tag/v3.3.0)).
- Railway Postgres for metadata; Git repositories, uploads, registry blobs and the SSH host key on the `/data` volume.
- Admin account created on first boot with a generated password; open sign-up off.
- Git over SSH through a Railway TCP proxy; Gitspaces off (they need a Docker host).
- Health check at `/api/v1/system/health`.
- Deploy on Railway button in the README.
