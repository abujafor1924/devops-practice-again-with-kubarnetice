# Nginx DevOps Study Guide

This guide covers the core configuration patterns and architectural concepts for **Nginx** as a reverse proxy, load balancer, web server, and SSL/TLS termination endpoint.

---

## 🧭 Syllabus Topics Explained

### 1. Reverse Proxy
* **Concept**: A reverse proxy sits in front of one or more web servers (like Gunicorn/Django) and intercepts requests from clients. It decides which backend server should handle the request and returns the response as if it originated from the proxy itself.
* **Benefits**: Hides backend server IPs, offloads SSL termination, limits request rates, and filters malicious traffic.
* **Configuration**:
  ```nginx
  location / {
      proxy_pass http://django_servers;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Proto $scheme;
  }
  ```

---

### 2. Load Balancer
* **Concept**: Distributes incoming network traffic across a group of backend servers to prevent overload and ensure high availability.
* **Nginx Algorithms**:
  * **Round Robin** (Default): Distributes requests sequentially.
  * **Least Connections** (`least_conn`): Routes traffic to the server with the fewest active connections.
  * **IP Hash** (`ip_hash`): Uses client IP to determine which server receives the request (good for session persistence).
* **Configuration Example**:
  ```nginx
  upstream django_servers {
      # Add multiple server instances for load balancing:
      server web-node-1:8000;
      server web-node-2:8000;
      # server web-node-3:8000 backup; # Backup server
  }
  ```

---

### 3. SSL/TLS Secure Server
* **Concept**: Encrypts data transmitted between client browser and Nginx server.
* **Local Setup (Self-Signed)**:
  * For local testing, we generate certificates using `openssl` (saved in `devops/ssl/`).
* **Configuration**:
  ```nginx
  listen 443 ssl;
  ssl_certificate /etc/nginx/ssl/nginx.crt;
  ssl_certificate_key /etc/nginx/ssl/nginx.key;
  ssl_protocols TLSv1.2 TLSv1.3; # Secure protocols only
  ```

---

### 4. Gzip Compression
* **Concept**: Compresses file sizes before sending them over the network. Modern browsers automatically decompress them.
* **Benefit**: Saves network bandwidth and speeds up page loading.
* **Configuration**:
  ```nginx
  gzip on;
  gzip_types text/plain text/css application/json application/javascript;
  gzip_min_length 1000; # Compresses only files > 1KB
  ```

---

### 5. Browser Caching
* **Concept**: Tells the client browser to store static assets (images, CSS, JS) locally so they don't have to download them again on future visits.
* **Configuration**:
  ```nginx
  location /static/ {
      alias /app/staticfiles/;
      expires 30d; # Cache files for 30 days
      add_header Cache-Control "public, no-transform";
  }
  ```

---

### 6. Static Files serving
* **Concept**: Direct disk-to-client serving for CSS, Javascript, and Images. In Django, running python code to serve static files is extremely slow. Nginx serves them directly from disk in milliseconds.
* **Difference between `root` and `alias`**:
  * **`root`**: Appends the URL path to the directory path. (e.g. `root /var/www;` for `/static/` looks in `/var/www/static/`).
  * **`alias`**: Replaces the matching location path with the directory path. (e.g. `alias /app/staticfiles/;` for `/static/` looks in `/app/staticfiles/`).

---

## 🔐 Let's Encrypt & Certbot (Production SSL Setup)

Let's Encrypt provides free, automated, open-source SSL certificates. **Certbot** is the CLI tool used to generate and auto-renew these certificates.

### Step 1: Set up DNS
Ensure your domain name (e.g., `example.com`) has an **A Record** pointing to your public server IP.

### Step 2: Install Certbot on Host
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

### Step 3: Stop Nginx (For Standalone Mode) or keep running (For Webroot Mode)
To let Let's Encrypt verify domain ownership, Certbot needs to listen on port 80.
```bash
# Generate cert using Nginx plugin (automatic server block edits)
sudo certbot --nginx -d example.com -d www.example.com
```

### Step 4: Using Certbot with Docker Compose
If running Nginx inside Docker, use Certbot in **Webroot** mode:
1. Map host directory `.well-known/acme-challenge/` in your Nginx container:
   ```nginx
   location /.well-known/acme-challenge/ {
       root /var/www/certbot;
   }
   ```
2. Run the Certbot container to request certificates:
   ```bash
   docker run -it --rm --name certbot \
     -v "/etc/letsencrypt:/etc/letsencrypt" \
     -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
     -v "/home/user/project/certbot:/var/www/certbot" \
     certbot/certbot certonly --webroot \
     -w /var/www/certbot -d example.com
   ```
3. Update `docker-compose.yml` to mount the certificate files from host directory `/etc/letsencrypt/live/example.com/` directly into Nginx.

### Step 5: Test Auto-Renewal
Let's Encrypt certificates are valid for 90 days. Auto-renew can be tested using:
```bash
sudo certbot renew --dry-run
```
*(Add a CronJob or systemd timer on your host machine to run `certbot renew` twice a day).*
