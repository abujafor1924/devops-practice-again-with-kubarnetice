# Ansible Configuration Management Guide

This guide covers the core configuration patterns and architectural concepts for **Ansible** as an automated server configuration and deployment tool, referencing the files created in the `ansible/` directory.

---

## 🧭 Syllabus Topics Explained

### 1. Inventory
* **Concept**: An inventory is a list of managed nodes (servers) that Ansible connects to and configures. You can define hostnames, IPs, groupings (e.g., `[webservers]`, `[dbservers]`), and custom SSH variables.
* **Example**: Check **[inventory.ini](inventory.ini)**. It specifies the host IP and the private SSH key path needed to connect to the AWS instance.
* **Syntax**:
  ```ini
  [webservers]
  app-server-1 ansible_host=54.210.12.89 ansible_user=ubuntu
  ```

---

### 2. Playbook
* **Concept**: Playbooks are YAML files that define the tasks to execute on your hosts. A playbook maps host groups to configuration tasks.
* **Example**: Check **[playbook.yml](playbook.yml)**. It maps the host group `webservers` to tasks that clone our project Git repository and spin up Docker containers.

---

### 3. Role
* **Concept**: Roles allow you to organize playbooks into modular, reusable directory structures. Each role contains its own default variables, tasks, templates, and handlers.
* **Project Structure**:
  Our project defines a `docker` role inside `ansible/roles/docker/` with the following structure:
  * `defaults/main.yml`: Default variable variables.
  * `tasks/main.yml`: Sequential list of installation steps.
  * `handlers/main.yml`: Service restart operations.

---

### 4. Variables
* **Concept**: Ansible variables are used to customize playbooks, roles, and tasks.
* **Variable Precedence**: Ansible has a clear order of variable overriding. Variables declared at the command line have the highest precedence, while variables in `roles/<name>/defaults/main.yml` have the lowest precedence.
* **Syntax**: Double curly braces are used to reference variables: `"{{ project_dir }}"`.

---

### 5. Handlers
* **Concept**: Handlers are special tasks that are only executed when they are **notified** by another task. A task notifies a handler when it creates a change (e.g., modifying a config file).
* **Usage**: Prevents restarting services (like Docker or Nginx) unless the config files were actually modified. Handlers run once at the very end of all tasks.
* **Example**:
  ```yaml
  # Inside tasks/main.yml
  - name: Configure Docker
    copy:
      content: ...
    notify: Restart Docker Daemon

  # Inside handlers/main.yml
  - name: Restart Docker Daemon
    service:
      name: docker
      state: restarted
  ```

---

### 6. Deploy
* **Concept**: Automated deployment involves orchestrating code pulls, setup updates, database migrations, and container restarts on target servers using Ansible.
* **Our Playbook Deploy Actions**:
  1. Checks if system prerequisites (git, pip) are installed.
  2. Clones the target git repository branch to the production path `/home/ubuntu/devops-practice`.
  3. Writes the environment variables `.env` file securely on the server.
  4. Triggers `docker compose up --build` to launch the container stack.

---

## 🛠️ Step-by-Step Execution Guide

To use these configurations, follow these terminal instructions from the `ansible/` directory:

### Step 1: Install Ansible on your Control Machine
```bash
sudo apt update
sudo apt install -y ansible
```

### Step 2: Test Host Connectivity (Ping test)
Run an ad-hoc ping task to verify that Ansible can connect to the target servers using your SSH credentials:
```bash
ansible all -i inventory.ini -m ping
```

### Step 3: Run the Deploy Playbook
Execute the playbook tasks against the hosts listed in the inventory:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### Step 4: Run dry-run Check (Simulation)
You can run a dry-run to see what tasks would make changes without executing them:
```bash
ansible-playbook -i inventory.ini playbook.yml --check
```
