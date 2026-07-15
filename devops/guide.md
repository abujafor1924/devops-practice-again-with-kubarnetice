# Docker Compose Commands Guide

This guide contains the common Docker Compose commands used to build, manage, and verify the Django, PostgreSQL, Redis, Celery, and Nginx container stack in this project.

All commands should be executed from the project root directory.

---

## 1. Starting the Stack

### Start all services in the background (Detached Mode)
Builds images (if not built) and starts all containers in the background. Specifies `.env` to load environment variables.
```bash
docker compose -f devops/docker-compose.yml --env-file .env up -d
```

### Build and start all services (Force Rebuild)
Rebuilds the Docker images for `web` and `celery` workers to incorporate code changes and starts the stack.
```bash
docker compose -f devops/docker-compose.yml --env-file .env up -d --build
```

---

## 2. Managing Services

### List running containers
Shows the status of all active containers in the stack, including health status and port mappings.
```bash
docker compose -f devops/docker-compose.yml ps
```

### View container logs
Stream logs for all services in real time.
```bash
docker compose -f devops/docker-compose.yml logs -f
```

### View logs for a specific service
Stream logs only for a particular container (e.g., `web` or `celery`).
```bash
# View Django web application logs
docker compose -f devops/docker-compose.yml logs -f web

# View Celery worker logs
docker compose -f devops/docker-compose.yml logs -f celery
```

### Restart a specific service
Restart a single container (e.g., after a configuration tweak).
```bash
docker compose -f devops/docker-compose.yml restart web
```

---

## 3. Django and Database Administration

### Run Django Database Migrations
Executes migrations inside the running `web` container.
```bash
docker compose -f devops/docker-compose.yml exec web python manage.py migrate
```

### Create a Django Superuser
Access the shell inside the container to create an admin account.
```bash
docker compose -f devops/docker-compose.yml exec web python manage.py createsuperuser
```

### Run Django Test Suite inside container
Runs tests using the test database configuration inside the container environment.
```bash
docker compose -f devops/docker-compose.yml exec web python manage.py test
```

### Access PostgreSQL command line (psql)
Log directly into the PostgreSQL database container.
```bash
docker compose -f devops/docker-compose.yml exec postgres psql -U myuser -d mydatabase
```

---

## 4. Stopping and Cleaning Up

### Stop the stack (Keep data)
Stops and removes containers and networks but preserves data in the named volumes (`postgres_data`, `static_volume`).
```bash
docker compose -f devops/docker-compose.yml down
```

### Stop the stack and delete all volumes (Full Reset)
Stops containers, deletes networks, and deletes database data volumes. **WARNING: This deletes the database data.**
```bash
docker compose -f devops/docker-compose.yml down -v
```
