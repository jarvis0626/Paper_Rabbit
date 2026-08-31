#!/bin/sh
set -eu

# Render and similar providers expose postgresql:// URLs. JDBC expects the
# same URL with a jdbc: prefix.
if [ -n "${DATABASE_URL:-}" ] && [ -z "${DB_URL:-}" ]; then
  export DB_URL="jdbc:${DATABASE_URL}"
fi

exec java ${JAVA_OPTS:-} -jar /app/app.jar
