# PostgreSQL Primary-Replica Replication with Docker

A hands-on guide to setting up PostgreSQL streaming replication with one primary and two replica servers using Docker Compose.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![License](https://img.shields.io/github/license/ThimiraSadeesha/postgres-replication-docker?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/ThimiraSadeesha/postgres-replication-docker?style=for-the-badge)
![Forks](https://img.shields.io/github/forks/ThimiraSadeesha/postgres-replication-docker?style=for-the-badge)
![Issues](https://img.shields.io/github/issues/ThimiraSadeesha/postgres-replication-docker?style=for-the-badge)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Testing Replication](#testing-replication)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Contributing](#contributing)

## 🎯 Overview

This project demonstrates PostgreSQL streaming replication using Docker containers. It sets up:
- **1 Primary Server** (read-write)
- **2 Replica Servers** (read-only)

All changes made to the primary are automatically replicated to both replicas in real-time using PostgreSQL's built-in streaming replication feature.

## 🏗️ Architecture

```
┌─────────────────┐
│   pg-primary    │ (Port 5432)
│   (Read/Write)  │
└────────┬────────┘
         │
         ├─────────────┬─────────────┐
         │             │             │
         ▼             ▼             ▼
┌────────────────┐ ┌────────────────┐
│  pg-replica-1  │ │  pg-replica-2  │
│  (Read-Only)   │ │  (Read-Only)   │
│  Port 5433     │ │  Port 5434     │
└────────────────┘ └────────────────┘
```

## ✅ Prerequisites

- Docker Desktop or Docker Engine (20.10+)
- Docker Compose V2
- At least 2GB of available RAM
- Basic knowledge of PostgreSQL and Docker

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/ThimiraSadeesha/postgres-replication-docker.git
   cd postgres-replication-docker
   ```

2. **Make the initialization script executable**
   ```bash
   chmod +x init-primary.sh
   ```

3. **Start the cluster**
   ```bash
   docker compose up -d
   ```

4. **Wait for initialization** (30-60 seconds)
   ```bash
   docker compose ps
   ```

5. **Verify all containers are healthy**
   ```bash
   docker compose logs -f
   ```

## ⚙️ Configuration

### Environment Variables

You can customize the following variables in `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `postgres` | Primary database superuser |
| `POSTGRES_PASSWORD` | `my_password` | Primary database password |
| `POSTGRES_DB` | `mydb` | Default database name |
| Replication User | `replicator` | User for replication |
| Replication Password | `repl_password` | Password for replication user |

### PostgreSQL Configuration

The primary server is configured with:
- `wal_level=replica` - Enables replication
- `max_wal_senders=10` - Maximum concurrent replication connections
- `max_replication_slots=10` - Maximum replication slots
- `hot_standby=on` - Allows read queries on replicas

## 🧪 Testing Replication

### Test 1: Basic Replication

```bash
  # Create a table on primary
  docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -c "CREATE TABLE users (id serial PRIMARY KEY, name text);"

  # Insert data
  docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -c "INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');"

  # Check primary
  docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -d mydb -c "SELECT * FROM users;"

  # Check replica-1
  docker exec -it postgres-replication-docker-pg-replica-1-1 \
  psql -U postgres -d mydb -c "SELECT * FROM users;"

  # Check replica-2
  docker exec -it postgres-replication-docker-pg-replica-2-1 \
  psql -U postgres -d mydb -c "SELECT * FROM users;"
```

### Test 2: Verify Replication Lag

```bash
  # On primary - check replication status
  docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

### Test 3: Read-Only Verification

```bash
    # Try to write to replica (should fail)
  docker exec -it postgres-replication-docker-pg-replica-1-1 \
  psql -U postgres -d mydb -c "INSERT INTO users (name) VALUES ('David');"
```

Expected output: `ERROR: cannot execute INSERT in a read-only transaction`

## 📊 Monitoring

### Check Replication Status

```bash
 # View replication slots
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "SELECT slot_name, active, restart_lsn FROM pg_replication_slots;"

 # View replication connections
docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

### View Logs

```bash
  # All services
docker compose logs -f

# Specific service
docker compose logs -f pg-primary
docker compose logs -f pg-replica-1
docker compose logs -f pg-replica-2
```

## 🔧 Troubleshooting

### Problem: Replicas not starting

**Solution:**
```bash
  # Stop and remove all containers and volumes
  docker compose down -v

# Restart
  docker compose up -d
```

### Problem: Replication lag

**Check replication delay:**
```bash
  docker exec -it postgres-replication-docker-pg-primary-1 \
  psql -U postgres -c "SELECT pid, usename, application_name, client_addr, state, 
    sent_lsn, write_lsn, flush_lsn, replay_lsn, 
    write_lag, flush_lag, replay_lag 
  FROM pg_stat_replication;"
```

### Problem: Connection refused

**Check if primary is ready:**
```bash
  docker compose ps
  docker compose logs pg-primary
```

## 🎓 Advanced Usage

### Promoting a Replica to Primary

If the primary fails, you can promote a replica:

```bash
  # Promote replica-1 to primary
   docker exec -it postgres-replication-docker-pg-replica-1-1 \
  /bin/bash -c "pg_ctl promote -D /var/lib/postgresql/data"
```

### Scaling Replicas

To add more replicas, edit `docker-compose.yml` and add:

```yaml
pg-replica-3:
  image: postgres:16
  depends_on: 
    pg-primary:
      condition: service_healthy
  ports:
    - "5435:5432"
  environment:
    - POSTGRES_USER=postgres
    - POSTGRES_PASSWORD=my_password
  entrypoint: |
    bash -c "
    if [ ! -s /var/lib/postgresql/data/PG_VERSION ]; then
      echo 'Initializing replica from primary...'
      until PGPASSWORD=repl_password pg_basebackup -h pg-primary -U replicator -D /var/lib/postgresql/data -R -X stream -c fast -S replication_slot_3
      do
        echo 'Waiting for primary...'
        sleep 2
      done
      echo 'Backup complete!'
    fi
    docker-entrypoint.sh postgres
    "
  volumes:
    - pg_replica_3_data:/var/lib/postgresql/data
```

Don't forget to create the replication slot in `init-primary.sh`:
```sql
SELECT * FROM pg_create_physical_replication_slot('replication_slot_3');
```

### Backup Strategy

```bash
   # Backup primary database
  docker exec postgres-replication-docker-pg-primary-1 \
  pg_dump -U postgres mydb > backup.sql

  # Restore to primary
  docker exec -i postgres-replication-docker-pg-primary-1 \
  psql -U postgres mydb < backup.sql
```

## 🛑 Stopping the Cluster

```bash
   # Stop containers (data persists)
   docker compose down

  # Stop and remove all data
   docker compose down -v
```

## 📚 Learning Resources

- [PostgreSQL Replication Documentation](https://www.postgresql.org/docs/current/high-availability.html)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Streaming Replication](https://www.postgresql.org/docs/current/warm-standby.html#STREAMING-REPLICATION)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- PostgreSQL Community
- Docker Community
- Bitnami for initial inspiration

## 📧 Contact

Thimira Sadeesha - [@sadeesha.me](https://www.sadeesha.me/)

Project Link: [https://github.com/ThimiraSadeesha/postgres-replication-docker.git](https://github.com/ThimiraSadeesha/postgres-replication-docker.git)

---

⭐ Star this repository if you find it helpful!