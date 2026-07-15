# Kubernetes 1-Month Syllabus Guide

This guide provides a comprehensive explanation and code examples for all 24 topics in your Kubernetes learning syllabus. We use examples from this Django-Postgres-Redis-Celery project to make each concept clear.

---

## 📂 Syllabus Topics Directory

| # | Topic | Project Reference File | Key Command |
|:-:| :--- | :--- | :--- |
| 1 | **Pod** | [django-app.yaml](django-app.yaml) | `kubectl get pods` |
| 2 | **ReplicaSet** | Automatically created by Deployment | `kubectl get rs` |
| 3 | **Deployment** | [postgres-db.yaml](postgres-db.yaml) | `kubectl get deployment` |
| 4 | **Namespace** | Standard isolation groups | `kubectl get ns` |
| 5 | **Service** | [postgres-db.yaml](postgres-db.yaml) | `kubectl get svc` |
| 6 | **ClusterIP** | [redis-broker.yaml](redis-broker.yaml) | (Default Service Type) |
| 7 | **NodePort** | [flower-monitor.yaml](flower-monitor.yaml) | Exposes external ports |
| 8 | **LoadBalancer** | Exposes cloud external IP | cloud integrations |
| 9 | **Ingress** | HTTP/HTTPS path routing | `kubectl get ingress` |
| 10| **ConfigMap** | [k8s-configmap-secret.yaml](k8s-configmap-secret.yaml) | `kubectl get configmap` |
| 11| **Secret** | [k8s-configmap-secret.yaml](k8s-configmap-secret.yaml) | `kubectl get secrets` |
| 12| **Persistent Volume (PV)** | [postgres-db.yaml](postgres-db.yaml) | `kubectl get pv` |
| 13| **Persistent Volume Claim (PVC)**| [postgres-db.yaml](postgres-db.yaml) | `kubectl get pvc` |
| 14| **Storage Class** | Storage provider definitions | `kubectl get sc` |
| 15| **DaemonSet** | Node-level daemon logs/metrics | `kubectl get daemonset` |
| 16| **StatefulSet** | Stable state deployments | `kubectl get statefulset` |
| 17| **CronJob** | [postgres-backup-cronjob.yaml](postgres-backup-cronjob.yaml)| `kubectl get cronjob` |
| 18| **Job** | Run-to-completion tasks | `kubectl get jobs` |
| 19| **Rolling Update** | Zero-downtime updates | `kubectl rollout status` |
| 20| **Rollback** | Reverting bad deployments | `kubectl rollout undo` |
| 21| **Resource Limits** | [celery-worker.yaml](celery-worker.yaml) | CPU & RAM requests/limits |
| 22| **HPA (Horizontal Pod Autoscaler)**| Automated scaling metrics | `kubectl get hpa` |
| 23| **Readiness Probe** | [django-app.yaml](django-app.yaml) | Checks traffic readiness |
| 24| **Liveness Probe** | [django-app.yaml](django-app.yaml) | Restarts dead containers |

---

## 1. Pod
* **Concept**: The smallest deployable unit in Kubernetes. A Pod hosts one or more containers that share storage, network namespace, and specifications.
* **Example (Sidecar Pattern)**: In `django-app.yaml`, the `django-app` pod runs two containers together: `django` (WSGI app) and `nginx` (proxy). They share the same loopback network interface (`127.0.0.1`).
* **Command**: `kubectl get pods`

---

## 2. ReplicaSet
* **Concept**: A ReplicaSet ensures that a specified number of pod replicas are running at any given time. You rarely create ReplicaSets directly; Deployments manage them automatically.
* **Command**: `kubectl get rs` (Notice how it matches your deployment names followed by hash values).

---

## 3. Deployment
* **Concept**: A higher-level controller that manages Pods and ReplicaSets. It provides declarative updates (rollouts) for Pods.
* **Example**:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: redis-broker
  spec:
    replicas: 1
    template: ...
  ```

---

## 4. Namespace
* **Concept**: Virtual clusters within a physical cluster used to isolate resources (e.g., `development`, `staging`, `production`).
* **Command**:
  ```bash
  # Create a namespace
  kubectl create namespace development
  # List all namespaces
  kubectl get ns
  # Apply a manifest to a namespace
  kubectl apply -f postgres-db.yaml -n development
  ```

---

## 5. Service
* **Concept**: An abstract way to expose an application running on a set of Pods. Pod IPs change, but a Service provides a stable IP and DNS name.
* **Command**: `kubectl get svc`

---

## 6. ClusterIP Service
* **Concept**: The default Service type. Exposes the Service on a cluster-internal IP. It makes the Service only reachable from within the cluster.
* **Example**: `redis-service` inside `redis-broker.yaml` is a ClusterIP service. The django pod accesses it using `redis-service:6379`.

---

## 7. NodePort Service
* **Concept**: Exposes the Service on each Node's IP at a static port (in the `30000-32767` range). Allows external access.
* **Example**: `flower-service` in `flower-monitor.yaml` binds to `nodePort: 30055`. You can load the dashboard on your host machine at `http://<minikube-ip>:30055`.

---

## 8. LoadBalancer Service
* **Concept**: Exposes the Service externally using a cloud provider's load balancer. In local Minikube, you can run `minikube tunnel` to simulate a public IP.
* **Manifest Example**:
  ```yaml
  spec:
    type: LoadBalancer
    ports:
      - port: 80
        targetPort: 80
  ```

---

## 9. Ingress
* **Concept**: An API object that manages external access to the services in a cluster, typically HTTP. It provides routing rules (e.g., path-based or host-based routing), SSL/TLS termination, and name-based virtual hosting.
* **Manifest Example**:
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: app-ingress
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
    - host: devops-practice.local
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: django-nginx-service
              port:
                number: 80
  ```

---

## 10. ConfigMap
* **Concept**: Used to store non-sensitive configuration data as key-value pairs.
* **Example**: ConfigMap in `k8s-configmap-secret.yaml` holds plain text parameters like `DEBUG: "True"`.

---

## 11. Secret
* **Concept**: Used to store sensitive information like database passwords. Secret values must be Base64-encoded.
* **Example**: Secret in `k8s-configmap-secret.yaml` holds base64-encoded Postgres credentials.

---

## 12. Persistent Volume (PV)
* **Concept**: A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It outlives the lifecycles of individual Pods.
* **Example**: `postgres-pv` in `postgres-db.yaml` binds to host path `/mnt/data/postgres`.

---

## 13. Persistent Volume Claim (PVC)
* **Concept**: A user's request for storage. Pods mount PVCs as volumes to request storage space.
* **Example**: `postgres-pvc` in `postgres-db.yaml` requests a 5Gi storage volume to bind to `postgres-pv`.

---

## 14. Storage Class
* **Concept**: A StorageClass provides a way for administrators to describe the "classes" of storage they offer. It enables dynamic provisioning of Persistent Volumes when a PVC is created.
* **Manifest Example**:
  ```yaml
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: fast-ssd
  provisioner: kubernetes.io/gce-pd # Dynamic provisioner for Google Cloud Disk
  parameters:
    type: pd-ssd
  ```

---

## 15. DaemonSet
* **Concept**: A DaemonSet ensures that all (or some) Nodes run a copy of a Pod. As nodes are added to the cluster, Pods are added to them. Common use cases: log collectors (Fluentd) or monitoring agents (Prometheus Node Exporter).
* **Manifest Example**:
  ```yaml
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    name: node-exporter
  spec:
    selector:
      matchLabels:
        name: node-exporter
    template:
      metadata:
        labels:
          name: node-exporter
      spec:
        containers:
        - name: node-exporter
          image: prom/node-exporter:v1.3.1
  ```

---

## 16. StatefulSet
* **Concept**: Used to manage stateful applications (like database clusters: MongoDB, Elasticsearch, Postgres clusters). Unlike Deployments, Pods in a StatefulSet have stable, unique network identities (e.g. `postgres-0`, `postgres-1`) and persistent disk bindings that do not change when Pods reschedule.
* **Manifest Example**:
  ```yaml
  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: postgres-cluster
  spec:
    serviceName: "postgres-hacluster"
    replicas: 3
    selector:
      matchLabels:
        app: postgres
    template: ...
  ```

---

## 17. CronJob
* **Concept**: Creates Jobs on a repeating time schedule (similar to Crontab in Linux).
* **Example**: `postgres-backup` in `postgres-backup-cronjob.yaml` runs every day at 2:00 AM (`0 2 * * *`) to back up database data.

---

## 18. Job
* **Concept**: A Job creates one or more Pods and ensures that a specified number of them successfully terminate. It is designed for run-to-completion tasks (like database seed scripts or batch processing).
* **Manifest Example**:
  ```yaml
  apiVersion: batch/v1
  kind: Job
  metadata:
    name: db-seed-job
  spec:
    template:
      spec:
        containers:
        - name: seed
          image: devops-web:latest
          command: ["python", "manage.py", "loaddata", "initial_data.json"]
        restartPolicy: OnFailure
  ```

---

## 19. Rolling Update
* **Concept**: The default deployment strategy. It replaces old pods with new ones step-by-step to achieve zero-downtime updates.
* **Command**:
  ```bash
  # Update a container image to trigger rolling update
  kubectl set image deployment/django-app django=devops-web:v2
  
  # Check rollout progress
  kubectl rollout status deployment/django-app
  ```

---

## 20. Rollback
* **Concept**: Reverts a deployment update to a previous stable version if the rollout fails or has bugs.
* **Command**:
  ```bash
  # Check rollout revision history
  kubectl rollout history deployment/django-app
  
  # Rollback to the previous version
  kubectl rollout undo deployment/django-app
  
  # Rollback to a specific revision (e.g. revision 2)
  kubectl rollout undo deployment/django-app --to-revision=2
  ```

---

## 21. Resource Limits
* **Concept**: Controls container resources.
  * **Requests**: The minimum CPU/Memory K8s must guarantee to schedule the container on a node.
  * **Limits**: The maximum CPU/Memory the container is allowed to consume. Prevents resource hogging.
* **Example**:
  ```yaml
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"  # 100 millicores (0.1 CPU core)
    limits:
      memory: "256Mi"
      cpu: "250m"  # 250 millicores (0.25 CPU core)
  ```

---

## 22. Horizontal Pod Autoscaler (HPA)
* **Concept**: Automatically scales the number of Pods in a replication controller, deployment, replica set, or stateful set based on observed CPU utilization (or other metrics).
* **Manifest Example**:
  ```yaml
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: django-hpa
  spec:
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: django-app
    minReplicas: 2
    maxReplicas: 10
    metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 75 # Scale up if average CPU usage exceeds 75%
  ```

---

## 23. Readiness Probe
* **Concept**: Kubernetes uses readiness probes to know when a container is ready to start accepting traffic. If a Pod is not ready, it is removed from Service load balancers.
* **Example**: In `django-app.yaml`, the Nginx container readiness probe performs a GET request to `/health/` on port `80`.

---

## 24. Liveness Probe
* **Concept**: Kubernetes uses liveness probes to know when to restart a container. If a container is stuck (deadlock), the liveness probe fails, and K8s automatically restarts the container.
* **Example**: In `postgres-db.yaml`, the Postgres container liveness probe runs the shell command `pg_isready` to make sure the database engine is responding.
