# Kubernetes DevOps Learning Guide

Welcome to the Kubernetes deployment guide! This guide explains how to run this entire multi-service stack (Django, Gunicorn, Nginx, PostgreSQL, Redis, Celery, and Flower) inside a Kubernetes (K8s) cluster. 

This configuration is designed for DevOps learning, with extensive inline comments in every manifest file.

---

## 1. Architecture Overview

```mermaid
graph TD
    Client[Client Browser]
    
    subgraph K8s Node
        ServiceNodePort[NodePort Service :30080]
        FlowerNodePort[NodePort Service :30055]
        
        subgraph Django Pod (Multi-Container)
            NginxContainer[Nginx Proxy Container]
            DjangoContainer[Django Gunicorn Container]
            SharedVolume[(Shared emptyDir Volume)]
        end
        
        CeleryPod[Celery Worker Pod]
        FlowerPod[Celery Flower Pod]
        PostgresPod[Postgres Database Pod]
        RedisPod[Redis Broker Pod]
        
        PostgresPVC[(Postgres PVC Storage)]
    end
    
    Client -->|port 30080| ServiceNodePort
    Client -->|port 30055| FlowerNodePort
    
    ServiceNodePort --> NginxContainer
    NginxContainer -->|127.0.0.1:8000| DjangoContainer
    
    NginxContainer -.->|Reads Static Assets| SharedVolume
    DjangoContainer -.->|Writes Static Assets| SharedVolume
    
    DjangoContainer -->|postgres-service:5432| PostgresPod
    DjangoContainer -->|redis-service:6379| RedisPod
    
    CeleryPod -->|postgres-service:5432| PostgresPod
    CeleryPod -->|redis-service:6379| RedisPod
    
    FlowerPod -->|redis-service:6379| RedisPod
    
    PostgresPod --> PostgresPVC
```

---

## 2. Essential Concepts Covered

### A. ConfigMaps and Secrets ([k8s-configmap-secret.yaml](k8s-configmap-secret.yaml))
* **ConfigMap**: Stores plain-text environment variables (e.g. `DEBUG=True`).
* **Secret**: Stores base64-encoded credentials (e.g. PostgreSQL password).
* **Environment Variable Expansion**: In `django-app.yaml`, we compose the `DATABASE_URL` dynamically using `$(POSTGRES_USER)` syntax. K8s expands these in order!

### B. Storage Subsystem ([postgres-db.yaml](postgres-db.yaml))
* **PersistentVolume (PV)**: Reconciles physical hardware storage (directories on the node).
* **PersistentVolumeClaim (PVC)**: A request for storage resource made by Postgres deployment.
* **Volume Mount**: Maps the claimed PVC to the Postgres container at `/var/lib/postgresql/data`.

### C. Init-Containers ([django-app.yaml](django-app.yaml))
* An Init-Container (`init-migrate`) runs and finishes **before** the main application containers start.
* **Database Check**: The init-container runs a check using `pg_isready` in a loop. It blocks until PostgreSQL is up, then runs `python manage.py migrate --noinput`. This prevents Django from starting up and crashing if the database is not ready.

### D. Multi-Container Pods (Sidecar Pattern) ([django-app.yaml](django-app.yaml))
Instead of deploying Nginx and Django separately, they are packaged into the **same Pod**.
1. **Shared Network**: They share the network namespace. Nginx routes traffic directly to Gunicorn using `127.0.0.1:8000`.
2. **Shared Volume**: They share a temporary volume (`emptyDir`). Django runs `collectstatic` inside this volume, and Nginx reads the files directly to serve them on `/static/` bypass routes.
3. **Atomic Scaling**: If you scale up the Deployment (`replicas: 2`), both containers scale up together, guaranteeing a 1:1 match.

### E. Health Probes ([django-app.yaml](django-app.yaml))
* **Readiness Probe**: Checks if the container is ready to accept user connections. If this probe fails, the Pod is removed from the Service endpoints (no traffic is sent to it).
* **Liveness Probe**: Checks if the container has crashed or hung. If it fails, Kubernetes kills the container and starts a new one.

---

## 3. Step-by-Step Local Deployment (Minikube)

Follow these steps to run the manifests locally:

### Step 1: Start Minikube
Start your local Kubernetes single-node cluster:
```bash
minikube start
```

### Step 2: Use Minikube's Docker Daemon
To allow Minikube to find the images we built locally (without pushing them to Docker Hub), point your terminal's docker CLI to minikube's registry:
```bash
eval $(minikube docker-env)
```

### Step 3: Build Container Images
Build the project container images inside the Minikube registry:
```bash
# Build the django web app image
docker build -f devops/dockerfile -t devops-web:latest .

# Build the celery image
docker build -f devops/dockerfile -t devops-celery:latest .

# Build the flower image
docker build -f devops/dockerfile -t devops-flower:latest .
```

### Step 4: Apply Manifests
Deploy the manifests in order. 
*Note: ConfigMaps and Secrets must be applied first so that deployments can load them.*
```bash
# 1. Configs & Secrets
kubectl apply -f kubernetes/k8s-configmap-secret.yaml

# 2. Database (Storage -> Deployment -> Service)
kubectl apply -f kubernetes/postgres-db.yaml

# 3. Redis Broker
kubectl apply -f kubernetes/redis-broker.yaml

# 4. Django & Nginx Multi-Container Pod
kubectl apply -f kubernetes/django-app.yaml

# 5. Celery Worker & Flower Monitor
kubectl apply -f kubernetes/celery-worker.yaml
kubectl apply -f kubernetes/flower-monitor.yaml
```

### Step 5: Get Node URL
To access the services from your host browser, ask Minikube to resolve the NodePort URLs:
```bash
# Fetch URL for Django/Nginx web app
minikube service django-nginx-service --url

# Fetch URL for Celery Flower Monitor
minikube service flower-service --url
```
Open the returned URLs (e.g. `http://<minikube-ip>:30080`) in your browser to verify!

---

## 4. DevOps Troubleshooting Commands

Use these commands to debug any issues in the cluster:

### Check Status of resources
```bash
# List all pods and their states (Running, Pending, Error, CrashLoopBackOff)
kubectl get pods

# List all services and their NodePort assignments
kubectl get svc
```

### Describe a Resource (Diagnose Pending states or CrashLoopBackOffs)
If a Pod is stuck in `Pending` or `ContainerCreating`, use `describe` to see K8s event logs:
```bash
kubectl describe pod <pod_name>
```

### Inspect Container Logs (Diagnose Application Crashes)
```bash
# View logs of a single-container Pod (e.g., redis or postgres)
kubectl logs <pod_name>

# View logs of the Django container inside the multi-container pod
kubectl logs <django_pod_name> -c django

# View logs of the Nginx container inside the multi-container pod
kubectl logs <django_pod_name> -c nginx

# View logs of the init-container inside the pod
kubectl logs <django_pod_name> -c init-migrate
```

### Execute Shell inside Container (Diagnostic Access)
```bash
# Log into the Postgres container and run psql
kubectl exec -it <postgres_pod_name> -- psql -U myuser -d mydatabase
```
