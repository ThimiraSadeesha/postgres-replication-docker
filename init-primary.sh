##!/bin/bash
#set -e
#
#psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
#    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'repl_password';
#    SELECT * FROM pg_create_physical_replication_slot('replication_slot_1');
#    SELECT * FROM pg_create_physical_replication_slot('replication_slot_2');
#EOSQL
#
## Allow replication connections from any host in the Docker network
#echo "host replication replicator 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
#
## Reload PostgreSQL configuration
#psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT pg_reload_conf();"

#!/bin/bash
set -e

echo "Setting up replication user..."

# Wait for Postgres to be ready
until pg_isready -U "$POSTGRES_USER"; do
  echo "Waiting for PostgreSQL to start..."
  sleep 2
done

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'replicator') THEN
            CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl_password';
        END IF;
    END
    \$\$;
EOSQL

# Allow replication connections from any Docker container
echo "host replication replicator 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

# Reload configuration
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT pg_reload_conf();"

echo "Replication user configured successfully."
