# Harness Open Source (formerly Gitness), official image pinned by version and digest.
# Update: change the tag and digest together, add a CHANGELOG.md entry, merge to main.
FROM harness/harness:3.3.0@sha256:c1bd76817ad7d2e7d78827653a54c55d4aec87c2777a586ebbad1ed01fc9e83f

COPY start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

EXPOSE 3000 3022
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
