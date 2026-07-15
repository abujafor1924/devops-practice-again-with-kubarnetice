# Django DevOps Practice Application

A minimal, DevOps-ready Django web application designed for practicing containerization, database configurations, and deployment strategies.

## Features

- **Dashboard**: A modern dark-mode responsive dashboard that displays hostname, IP, Python/Django versions, database status, and a real-time visit count.
- **Database Integration**: Saves visit records (timestamp and client IP) using Django models.
- **Health Check Endpoint**: `/health/` returns JSON status (ideal for load balancers or container orchestrator probes).
- **Environment-Driven Configuration**: Configured to easily hook into Docker environment variables (e.g., PostgreSQL database URL, debug settings, allowed hosts).

---

## Local Setup

Follow these steps to run the application directly on your host machine:

### 1. Set Up Virtual Environment

```bash
# Create a virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Run Database Migrations

By default, the application will fall back to using local SQLite (`db.sqlite3` in the root folder) if no database configuration environment variable is provided.

```bash
python manage.py migrate
```

### 4. Start Development Server

```bash
python manage.py runserver
```

Open your browser and navigate to `http://localhost:8000`.

---

## Environment Variables

This application is designed to be easily configurable via environment variables, perfect for Docker containers or Kubernetes ConfigMaps/Secrets:

| Variable | Description | Default | Example |
| :--- | :--- | :--- | :--- |
| `DEBUG` | Controls Django debug mode | `True` | `False` |
| `SECRET_KEY` | Django security secret key | A default insecure key | `production-secure-random-key` |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hostnames/IPs | `localhost,127.0.0.1,[::1]` | `example.com,10.0.0.5` |
| `DATABASE_URL` | Connection URL for external databases (e.g. PostgreSQL) | Falls back to SQLite | `postgres://user:password@localhost:5432/dbname` |

### Example running with custom environment variables:

```bash
export DEBUG=False
export SECRET_KEY="my-production-only-key"
export ALLOWED_HOSTS="my-devops-app.internal,localhost"
export DATABASE_URL="postgres://db_user:db_password@postgres-service:5432/devops_db"

python manage.py runserver
```

---

## Running Tests

To run the automated test suite verifying dashboard rendering and health-check responses:

```bash
python manage.py test
```
# devops-practice-again-with-kubarnetice
