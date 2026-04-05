# TCMS Ansible

Ansible automation for provisioning and deploying the TCMS (Test Case Management System) application stack on AWS.

## Overview

This repository manages the full infrastructure lifecycle for TCMS:
- **PostgreSQL** primary + replica database cluster
- **PgBouncer** connection pooler
- **Docker** container runtime and private registry
- **Apache** web server
- **HAProxy** load balancer
- **Jenkins** CI server
- **Pulsar** messaging
- **Application deployment** (WAR / batch JAR via Docker)

## Prerequisites

- Ansible ≥ 2.14
- Python ≥ 3.10
- AWS CLI configured (or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` set)
- `ansible-galaxy collection install -r requirements.yml`

## Directory Structure

```
tcms-ansible/
├── ansible.cfg                   # Ansible configuration (forks, SSH tuning, fact caching)
├── requirements.yml              # Ansible Galaxy collection dependencies
├── inventories/
│   └── dev/
│       ├── hosts.ini             # Inventory for dev environment
│       └── group_vars/
│           ├── all.yml           # Shared variables (non-secret)
│           └── vault.yml.example # Template — copy to vault.yml and encrypt
├── playbooks/
│   ├── site.yml                  # Full infrastructure playbook
│   ├── deploy.yml                # Unified deployment playbook (war | batch)
│   ├── deploy_war.yml            # WAR deployment shortcut
│   ├── deploy_batch.yml          # Batch deployment shortcut
│   ├── docker.yml
│   ├── postgresql.yml
│   ├── pgbouncer.yml
│   ├── haproxy.yml
│   ├── apache.yml
│   ├── jenkins.yml
│   └── roles/
│       ├── common/               # Shared prerequisites (apt cache, base packages)
│       ├── deploy_backend/       # Docker build + deploy for WAR/batch
│       ├── docker/               # Docker CE installation
│       ├── postgresql/           # PostgreSQL install, primary & replica config
│       ├── pgbouncer/            # PgBouncer connection pooler
│       ├── haproxy/              # HAProxy load balancer
│       ├── apache/               # Apache web server
│       ├── jenkins/              # Jenkins CI
│       └── pulsar/               # Apache Pulsar messaging
└── pipelines/
    ├── shared/vars/              # Jenkins shared library steps
    │   ├── tcmsBuild.groovy      # Checkout + Maven build step
    │   └── tcmsDeploy.groovy     # Ansible deploy step
    ├── aio-tcms-backend/Jenkinsfile
    ├── aio-tcms-batch/Jenkinsfile
    └── aio-tcms-frontend/Jenkinsfile
```

## Environment Setup

### 1. Install Galaxy Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure SSH Key

Set the `ANSIBLE_SSH_KEY` environment variable pointing to your private key, or place your key at `~/.ssh/tcms-dev.pem`:

```bash
export ANSIBLE_SSH_KEY=~/.ssh/your-key.pem
```

### 3. Create Vault for Secrets

```bash
cp inventories/dev/group_vars/vault.yml.example inventories/dev/group_vars/vault.yml
ansible-vault encrypt inventories/dev/group_vars/vault.yml
```

Edit `vault.yml` to set real values for:
- `vault_replication_password` — PostgreSQL replication user password
- `vault_pgbouncer_password` — PgBouncer auth password

## Deployment Commands

### Deploy WAR (backend)

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/deploy_war.yml
```

### Deploy Batch JAR

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/deploy_batch.yml
```

### Unified Deploy (either type)

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/deploy.yml -e deploy_type=war
ansible-playbook -i inventories/dev/hosts.ini playbooks/deploy.yml -e deploy_type=batch
```

### Full Infrastructure Provisioning

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/site.yml
```

### Single Role (example)

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/docker.yml --tags docker
```

## Jenkins Pipelines

Each pipeline is located in `pipelines/<service>/Jenkinsfile` and uses the shared library steps from `pipelines/shared/vars/`:

| Pipeline | Repo | Ansible Playbook |
|---|---|---|
| `aio-tcms-backend` | `aio-jira-tcms-backend` | `deploy_war.yml` |
| `aio-tcms-batch` | `aio-jira-tcms-backend` | `deploy_batch.yml` |
| `aio-tcms-frontend` | `aio-tcms-frontend-v2` | _(static deploy)_ |

## Security Notes

- Secrets are never stored in plain text. Use `ansible-vault` for `vault.yml`.
- The SSH key path is resolved from the `ANSIBLE_SSH_KEY` environment variable with a safe fallback.
- PgBouncer uses `md5` authentication with `auth_query` for proper credential validation.
- `.pem` files and `vault.yml` are excluded from version control via `.gitignore`.
