import multiprocessing

# Gunicorn configuration file for production deployment
# For reference on configuration parameters, see:
# https://docs.gunicorn.org/en/stable/configure.html

# Socket binding
bind = "0.0.0.0:8000"

# Workers count (2 * cores + 1)
workers = multiprocessing.cpu_count() * 2 + 1

# Worker class
worker_class = "sync"

# Maximum time (seconds) a worker can spend responding to a request
timeout = 120

# Server socket backlog connection limit
backlog = 2048

# Output container logs to stdout/stderr
accesslog = "-"
errorlog = "-"

# Severity of logging
loglevel = "info"

# Captures stdout/stderr outputs to errorlog
capture_output = True

# Process name
proc_name = "django_app_gunicorn"
