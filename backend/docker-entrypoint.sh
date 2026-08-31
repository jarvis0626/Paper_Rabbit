#!/bin/sh
set -eu

# Render exposes a postgresql:// URL with credentials in its authority section.
# PostgreSQL JDBC requires the host URL and credentials as separate settings.
if [ -n "${DATABASE_URL:-}" ] && [ -z "${DB_URL:-}" ]; then
  database_address="${DATABASE_URL#*://}"
  database_address="${database_address#*@}"
  export DB_URL="jdbc:postgresql://${database_address}"
fi

exec java ${JAVA_OPTS:-} -jar /app/app.jar
