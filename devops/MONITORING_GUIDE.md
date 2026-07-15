# DevOps Monitoring & Logging Guide

This guide covers the core concepts, configurations, and best practices for setting up observability in your application using **Prometheus**, **Alertmanager**, **Grafana Loki**, and comparing them to alternative platforms like the **ELK Stack**.

---

## 🧭 Syllabus Topics Explained

### 1. Prometheus
* **Concept**: An open-source metrics collection engine and time-series database. It pulls (scrapes) numeric metrics from targets at designated intervals, evaluates rule expressions, displays results, and triggers alerts if specified conditions are met.
* **Pull vs Push**: Unlike traditional monitoring tools that require agents to "push" data, Prometheus actively "pulls" (scrapes) metrics from HTTP endpoints exposed by target systems.

---

### 2. Metrics
* **Concept**: Numeric, time-series data values representing resource state.
* **Core Metric Types**:
  * **Counter**: A cumulative metric that only increases (e.g. `http_requests_total`).
  * **Gauge**: A metric that can go up and down (e.g. `node_memory_Active_bytes`).
  * **Histogram**: Samples observations (typically request durations or response sizes) and counts them in configurable buckets.
  * **Summary**: Similar to histogram, but calculates configurable quantiles over a sliding time window.

---

### 3. Exporters
* **Concept**: A helper agent that translates host/service metrics into a Prometheus-readable format (HTTP text format).
* **Exporters in this Project**:
  * **Node Exporter**: Collects host physical metrics (CPU load, RAM usage, disk input/output).
  * **cAdvisor**: Collects container-level resource statistics (stats for CPU/RAM limits per container running in Docker).

---

### 4. Grafana & Dashboards
* **Concept**: An open-source visualization suite. It connects to data sources like Prometheus (metrics) and Loki (logs) to render charts, graphs, tables, and alert timelines.
* **Grafana Dashboard**: A visual collection of panels querying metrics using PromQL (Prometheus Query Language) or LogQL (Loki Query Language).

---

### 5. Alertmanager
* **Concept**: Receives alert events from Prometheus, groups/deduplicates them, and routes them to communication channels (Slack, PagerDuty, Email, SMS).
* **Configuration**: Defined in **[alertmanager.yml](alertmanager.yml)**. It routes alerts based on labels (e.g. route `severity: critical` to pager, and `severity: warning` to Slack).

---

### 6. Grafana Loki & Promtail (Modern Logging)
* **Loki**: A log aggregation system inspired by Prometheus. It does not index the full log text, but instead indexes *metadata labels* (e.g., `job=docker-containers`, `env=dev`). This makes it extremely fast and lightweight.
* **Promtail**: The agent that runs on servers, grabs log files from disk (e.g. `/var/log/*` or Docker container JSON logs), and pushes them to Loki.

---

## 🆚 Loki vs ELK Stack (Elasticsearch, Logstash, Kibana)

For log aggregation, you will study both Loki and the ELK Stack in your DevOps curriculum. Here is a comparison:

| Metric / Feature | Grafana Loki Stack (PLG) | ELK Stack (Elasticsearch, Logstash, Kibana) |
| :--- | :--- | :--- |
| **Components** | Promtail (Agent) -> Loki (Storage) -> Grafana (UI) | Logstash/Beats (Agent) -> Elasticsearch (DB) -> Kibana (UI) |
| **Indexing Method** | Indexes **labels only** (metadata). Log content is stored compressed. | Full-text indexing of the entire log message (Lucene index). |
| **Resource Consumption** | **Extremely Low**. Loki runs easily with 100-200MB of RAM. | **Very High**. Elasticsearch consumes massive RAM (needs at least 2GB-4GB just to boot). |
| **Search Capabilities** | Grep-like queries (LogQL). Best for locating errors or tracing requests. | Advanced text search, auto-complete, and semantic text parsing. |
| **Cost** | Cheap (low disk storage and low RAM requirements). | Expensive (large storage index footprint, high RAM requirements). |

---

## 🛠️ Step-by-Step Execution Guide

### Step 1: Restart the Container Stack
Deploy the monitoring stack:
```bash
docker compose -f devops/docker-compose.yml --env-file .env up -d
```

### Step 2: Verify Prometheus Targets
1. Open `http://localhost:9090/targets` in your browser.
2. Ensure `prometheus`, `cadvisor`, `node-exporter`, and `alertmanager` targets show a status of **UP (Green)**.

### Step 3: Setup Grafana Observability
1. Open Grafana at `http://localhost:3000` (Default credentials: `admin` / `admin`).
2. **Add Prometheus Data Source**:
   * Go to **Connections** -> **Data Sources** -> **Add new data source**.
   * Select **Prometheus**.
   * Set Connection URL to: `http://prometheus:9090`
   * Click **Save & test**.
3. **Add Loki Data Source**:
   * Click **Add new data source** -> Select **Loki**.
   * Set Connection URL to: `http://loki:3100`
   * Click **Save & test**.
4. **View Logs**:
   * Go to **Explore** in the sidebar.
   * Select the **Loki** data source.
   * Use LogQL to search: `{job="docker-containers"}` or `{job="varlogs"}`. Click **Run query** to see container stdout logs streamed live in Grafana!
