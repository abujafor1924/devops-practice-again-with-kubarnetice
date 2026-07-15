# GitHub Actions CI/CD Learning Guide

This guide explains the core concepts of Continuous Integration (CI) and Continuous Delivery (CD) implemented in our project's GitHub Actions workflow: **[.github/workflows/cicd.yml](../.github/workflows/cicd.yml)**.

---

## 🚀 Core DevOps Concepts

### 1. Workflow
* **What it is**: A configurable automated process that will run one or more jobs. Workflows are defined by a YAML file in your repository under `.github/workflows/`.
* **Triggers (`on`)**: Events that start a workflow (e.g., code push, pull requests, or a schedule).
  * In our workflow, we listen to `push` and `pull_request` events targeting the `main` and `master` branches.

### 2. Runner
* **What it is**: The machine/VM that runs the workflow steps.
* **Types**:
  * **GitHub-hosted Runners**: Clean virtual machines hosted by GitHub (e.g., `ubuntu-latest`, `windows-latest`, `macos-latest`) that are created fresh for every run.
  * **Self-hosted Runners**: Servers you own and configure yourself (e.g., an on-premise VM or cloud instance) to run actions inside private corporate networks.

### 3. Secrets
* **What it is**: Encrypted variables you create in your GitHub repository settings. They allow you to securely store passwords, API tokens, and SSH keys without exposing them in your source code.
* **Access**: Referenced in the workflow using `${{ secrets.NAME }}` syntax.
* **How to configure them in GitHub**:
  1. Go to your repository on GitHub.
  2. Navigate to **Settings** -> **Secrets and variables** -> **Actions**.
  3. Click **New repository secret**.
  4. Add the following secrets to run this project's pipeline:
     * `DOCKERHUB_USERNAME`: Your Docker Hub profile name.
     * `DOCKERHUB_TOKEN`: Your Docker Hub personal access token (PAT).
     * *Optional*: `SSH_PRIVATE_KEY` / `SERVER_HOST` / `SERVER_USER` (for server deployments).

### 4. Matrix
* **What it is**: A matrix strategy allows you to run multiple jobs concurrently by dynamically interpolating configurations (like testing different combinations of OS, Python versions, or databases).
* **Why it matters**: It guarantees compatibility. If your application needs to support Python `3.11` and `3.12`, the matrix creates two separate concurrent test runs. If Python `3.12` introduces a breaking change, only that job fails, allowing you to isolate compatibility issues easily.
* **Example Code**:
  ```yaml
  strategy:
    matrix:
      python-version: ["3.11", "3.12"]
  ```

---

## 📊 Pipeline Stage Architecture

```mermaid
graph TD
    Trigger[Code Push / PR to main] -->|Step 1| JobTest[Job: Run Unit Tests]
    
    subgraph JobTest (Matrix Execution)
        Test311[Python 3.11 Test Run]
        Test312[Python 3.12 Test Run]
    end
    
    JobTest -->|If Successful| JobBuild[Job: Build & Push Docker Image]
    
    subgraph JobBuild
        Login[Log in to Docker Hub via Secrets]
        Build[Build Docker image]
        Push[Push to Docker Hub repository]
    end
    
    JobBuild -->|If Successful| JobDeploy[Job: Deploy to Server]
    
    subgraph JobDeploy
        SSH[SSH into Server via Secrets]
        Pull[Pull new image version]
        Restart[Recreate container or update K8s deployment]
    end
```

---

## 🛠️ How to Test and Run the Pipeline

1. **Commit the Workflow**: Push the `.github` directory to your GitHub repository.
2. **Setup Secrets**: Configure your `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` in your GitHub repository settings.
3. **Trigger**: Push a commit or open a Pull Request.
4. **Monitor**: Go to the **Actions** tab on your GitHub repository page to see the pipeline execute in real time, view runner logs, and verify that the image is built and pushed to Docker Hub!
