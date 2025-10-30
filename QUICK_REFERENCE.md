# 📖 Quick Reference Guide

Essential commands and configurations for PostgreSQL replication.

## 🚀 Getting Started

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Stop and remove all data
docker compose down -v

# View logs
docker compose logs -f

# Check status
docker compose ps
```

## 🔌 Connection Information

| Service | Host | Port | User | Password | Database |
|---------|------|------|------|----------|----------|
| Primary | localhost | 5432 | postgres | my_password | mydb |
| Replica-1 | localhost | 5433 | postgres | my_password | mydb |
| Replica-2 | localhost | 5434 | postgres | my_password | mydb |

## 📝 Common psql Commands

### Connect to Database

```bash
# Primary
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb

# Replica-1
docker exec -it postgres-replication-docker-pg-replica-1-1 \
  psql -U postgres -d mydb

# Replica-2
docker exec -it postgres-replication-docker-pg-replica-2-1 \
  psql -U postgres -d mydb
```

### Inside psql

```sql
-- List databases
\l

-- Connect to database
\c mydb

-- List tables
\dt

-- Describe table
\d table_name

-- Show table contents
SELECT * FROM table_name;

-- Quit
\q
```

## 🔍 Monitoring Commands

### Check Replication Status

```bash
# View replication connections
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# View replication slots
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "SELECT * FROM pg_replication_slots;"

# Check replication lag
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "
  SELECT 
    application_name,
    client_addr,
    state,
    write_lag,
    flush_lag,
    replay_lag
  FROM pg_stat_replication;"
```

### Check Database Size

```bash
# Primary database size
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "
  SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
  FROM pg_database;"

# Table sizes
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -c "
  SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
  FROM pg_tables
  WHERE schemaname = 'public'
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

## 🧪 Testing Commands

### Create Test Data

```bash
# Single insert
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -c "
  CREATE TABLE IF NOT EXISTS test (id serial, data text);
  INSERT INTO test (data) VALUES ('test data');"

# Bulk insert
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -c "
  INSERT INTO test (data) 
  SELECT 'test_' || generate_series(1, 1000);"
```

### Verify Replication

```bash
# Check row count on primary
docker exec postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -t -c "SELECT COUNT(*) FROM test;"

# Check row count on replica-1
docker exec postgres-replication-docker-pg-replica-1-1 \
  psql -U postgres -d mydb -t -c "SELECT COUNT(*) FROM test;"

# Check row count on replica-2
docker exec postgres-replication-docker-pg-replica-2-1 \
  psql -U postgres -d mydb -t -c "SELECT COUNT(*) FROM test;"
```

## 💾 Backup & Restore

### Backup

```bash
# Backup specific database
docker exec postgres-replication-docker-pg-primary-1 \
  pg_dump -U postgres mydb > backup.sql

# Backup all databases
docker exec postgres-replication-docker-pg-primary-1 \
  pg_dumpall -U postgres > backup_all.sql

# Compressed backup
docker exec postgres-replication-docker-pg-primary-1 \
  pg_dump -U postgres -Fc mydb > backup.dump
```

### Restore

```bash
# Restore from SQL
docker exec -i postgres-replication-docker-pg-primary-1 \
  psql -U postgres mydb < backup.sql

# Restore from compressed dump
docker exec -i postgres-replication-docker-pg-primary-1 \
  pg_restore -U postgres -d mydb backup.dump
```

## 🔧 Troubleshooting Commands

### Check Container Logs

```bash
# All services
docker compose logs

# Specific service
docker compose logs pg-primary
docker compose logs pg-replica-1
docker compose logs pg-replica-2

# Follow logs
docker compose logs -f pg-primary

# Last 50 lines
docker compose logs --tail 50 pg-replica-1
```

### Check Container Resources

```bash
# View resource usage
docker stats

# Inspect container
docker inspect postgres-replication-docker-pg-primary-1

# Check disk usage
docker exec postgres-replication-docker-pg-primary-1 df -h
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart pg-primary
docker compose restart pg-replica-1
docker compose restart pg-replica-2
```

### Reset Everything

```bash
# Complete reset
docker compose down -v
docker volume prune -f
docker compose up -d
```

## 🔐 Security Commands

### Change Passwords

```sql
-- Connect to primary
-- Change postgres password
ALTER USER postgres WITH PASSWORD 'new_password';

-- Change replication user password
ALTER USER replicator WITH PASSWORD 'new_repl_password';
```

**Note:** Update docker-compose.yml with new passwords and restart.

### View User Permissions

```sql
-- List all users
SELECT usename, usesuper, userepl FROM pg_user;

-- View user privileges
\du
```

## 📊 Performance Commands

### Analyze Query Performance

```sql
-- Enable query timing
\timing

-- Explain query plan
EXPLAIN ANALYZE SELECT * FROM your_table;

-- View slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

### Check Active Connections

```bash
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "
  SELECT 
    datname,
    count(*) as connections
  FROM pg_stat_activity
  GROUP BY datname;"
```

### Kill Idle Connections

```sql
-- View idle connections
SELECT pid, usename, datname, state, query_start
FROM pg_stat_activity
WHERE state = 'idle';

-- Kill specific connection
SELECT pg_terminate_backend(pid);
```

## 🔄 Failover Commands

### Promote Replica to Primary

```bash
# Stop primary (simulate failure)
docker compose stop pg-primary

# Promote replica-1
docker exec -it postgres-replication-docker-pg-replica-1-1 \
  /bin/bash -c "pg_ctl promote -D /var/lib/postgresql/data"

# Verify it's accepting writes
docker exec -it postgres-replication-docker-pg-replica-1-1 \
  psql -U postgres -d mydb -c "CREATE TABLE failover_test (id int);"
```

## 📦 Docker Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect replica_pg_primary_data

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm -v replica_pg_primary_data:/data \
  -v $(pwd):/backup ubuntu \
  tar czf /backup/postgres-backup.tar.gz /data
```

## 🌐 Network Commands

```bash
# View networks
docker network ls

# Inspect network
docker network inspect replica_default

# View container IPs
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  postgres-replication-docker-pg-primary-1
```

## 📈 Useful Queries

### Replication Status Dashboard

```sql
SELECT 
    client_addr AS replica_ip,
    usename AS user,
    application_name,
    state,
    sync_state,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)) AS sending_lag,
    pg_size_pretty(pg_wal_lsn_diff(sent_lsn, write_lsn)) AS write_lag,
    pg_size_pretty(pg_wal_lsn_diff(write_lsn, flush_lsn)) AS flush_lag,
    pg_size_pretty(pg_wal_lsn_diff(flush_lsn, replay_lsn)) AS replay_lag,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS total_lag
FROM pg_stat_replication;
```

### Database Statistics

```sql
SELECT 
    datname,
    numbackends AS connections,
    xact_commit AS commits,
    xact_rollback AS rollbacks,
    blks_read AS disk_reads,
    blks_hit AS cache_hits,
    round(blks_hit*100.0/(blks_hit+blks_read), 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'mydb';
```

## 🎯 Quick Tips

1. **Always test on replicas first** - Replicas are read-only, safe for testing queries
2. **Monitor replication lag** - Run monitoring queries regularly
3. **Backup from replicas** - Reduces load on primary
4. **Use connection pooling** - For production environments
5. **Regular maintenance** - Run VACUUM and ANALYZE periodically

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/postgres-replication-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/postgres-replication-docker/discussions)
- **Documentation**: [PostgreSQL Docs](https://www.postgresql.org/docs/)

---

💡 **Pro Tip**: Bookmark this page for quick access to commands!