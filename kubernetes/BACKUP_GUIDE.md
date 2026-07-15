# Kubernetes Database Backup & Restore Guide

This guide covers the core DevOps workflows for managing PostgreSQL database backups and performing disaster recovery restores inside a Kubernetes cluster. 

---

## 1. How the Backup Works

The backup is managed by the Kubernetes CronJob defined in **[postgres-backup-cronjob.yaml](postgres-backup-cronjob.yaml)**.

### Execution Flow:
1. **Trigger**: At 2:00 AM (configured via `schedule: "0 2 * * *"`), the Kubernetes Control Plane creates a temporary Pod.
2. **Setup**: The backup Pod mounts the dedicated **PersistentVolumeClaim** (`postgres-backup-pvc`) to `/backups`.
3. **Execution**: The script executes `pg_dump` connecting to the internal database host `postgres-service`.
4. **Compression**: The output of `pg_dump` is piped to `gzip` to compress the size before writing it to `/backups/db_backup_<timestamp>.sql.gz`.
5. **Teardown**: Once the backup completes, the Pod exits with status `0` (Success). Kubernetes automatically terminates the Pod to release CPU and memory resources.

---

## 2. Step-by-Step Recovery (How to Restore a Backup)

If a disaster happens (e.g., data corruption, accidental table drop), follow this procedure to restore the database to a healthy snapshot:

### Step 1: Locate the Backup File
Find the name of the backup file you want to restore inside the backup storage:
```bash
# Exec into a shell or list files in the backup volume
kubectl exec -it <any-active-pod-mounting-the-backup-pvc> -- ls -lh /backups/
```
For example, assume your backup file is `/backups/db_backup_20260715_020000.sql.gz`.

### Step 2: Temporarily Scale Down the Django Web & Celery App
Before restoring a database, scale down your web applications to `0` replicas. This prevents clients from writing new data or executing queries during the restore process:
```bash
# Scale down Django application
kubectl scale deployment django-app --replicas=0

# Scale down Celery worker
kubectl scale deployment celery-worker --replicas=0
```

### Step 3: Copy the Backup File into the Postgres Container
If the backup file is on your host machine, copy it into the Postgres container:
```bash
kubectl cp ./db_backup_20260715_020000.sql.gz <postgres-pod-name>:/tmp/db_backup.sql.gz
```
*(If the backup is already inside the mounted backup volume, you can skip this step).*

### Step 4: Wipe and Recreate the Database
To ensure a clean restore, drop the existing database tables or drop/recreate the database:
```bash
# Log into Postgres inside the container
kubectl exec -it <postgres-pod-name> -- psql -U myuser -d postgres

# Inside the psql shell, terminate connections and drop the database:
# SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'mydatabase' AND pid <> pg_backend_pid();
# DROP DATABASE mydatabase;
# CREATE DATABASE mydatabase;
# \q (quit)
```

### Step 5: Restore the SQL Script
Unzip the backup file and pipe it back into the PostgreSQL service:
```bash
# Exec into the postgres container and restore the compressed SQL file
kubectl exec -it <postgres-pod-name> -- sh -c "zcat /backups/db_backup_20260715_020000.sql.gz | psql -U myuser -d mydatabase"
```
Verify the output to ensure the tables and indices are recreated.

### Step 6: Scale Up the Applications
Restore the stack back to normal operations:
```bash
# Scale Django back up to 2 replicas
kubectl scale deployment django-app --replicas=2

# Scale Celery worker back up to 1 replica
kubectl scale deployment celery-worker --replicas=1
```

---

## 3. Advanced DevOps Backup Best Practices

### A. Off-site Replication (Production Setup)
Storing backups on the same node or cluster is risky (e.g. if the physical node disk fails). In production, you should modify the CronJob command to upload the file to a secure cloud bucket (e.g., AWS S3):
```bash
# Example script extension:
# aws s3 cp /backups/db_backup_${DATE}.sql.gz s3://my-company-backups/postgres/
```

### B. Backup Retention (Rotation)
To prevent the backup PVC from filling up, write a script to delete backups older than `N` days:
```bash
# Delete backups older than 7 days
find /backups -name "db_backup_*.sql.gz" -mtime +7 -delete
```

### C. Monitoring Backups
If a backup fails, you need to know. You can use Kubernetes event alerts or integrate the CronJob with monitoring tools like Prometheus Alertmanager or Slack Webhooks:
```bash
# Notify Slack on backup failure:
# curl -X POST -H 'Content-type: application/json' --data '{"text":"Backup Failed!"}' https://hooks.slack.com/services/...
```
