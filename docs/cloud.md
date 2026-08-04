---
title: "Cloud & Kubernetes"
description: "Google Cloud SDK, AWS CLI, kubectl aliases, and k9s Kubernetes TUI reference."
tags: [cloud, gcloud, aws, kubectl, k9s, kubernetes]
related:
  - title: "Index"
    href: index.md
  - title: "Shell"
    href: shell.md
  - title: "Maintenance"
    href: maintenance.md
---

# Cloud & Kubernetes

> **gcloud config:** `~/.dotfiles/.config/gcloud/`
>
> **AWS config:** `~/.dotfiles/.aws/config`
>
> **k9s config:** `~/.dotfiles/.config/k9s/`

---

## Google Cloud — gcloud

The `gcloud` CLI manages GCP resources and authentication. Two interactive shell functions simplify profile management.

### Authentication

```bash
gcloud auth login                         # browser-based login
gcloud auth application-default login     # for local development SDKs
gcloud auth list                          # show all credentialed accounts
```

### Profile Management

#### `gcloud_swap_profile`

fzf picker to switch between gcloud configurations. The active profile is marked.

```bash
gcloud_swap_profile
```

#### `gcloud_generate_profile`

Step-by-step wizard: select project → select account → select region → enter profile name. Creates and activates a fully configured gcloud configuration.

```bash
gcloud_generate_profile
```

### Common Operations

```bash
# Projects
gcloud projects list
gcloud config set project <PROJECT_ID>

# Compute
gcloud compute instances list
gcloud compute ssh <instance-name>

# Secrets (used for secrets.sh)
gcloud secrets versions access latest --secret=<secret-name> --project=<PROJECT_ID>

# Container Registry / Artifact Registry
gcloud auth configure-docker
gcloud artifacts repositories list

# Kubernetes
gcloud container clusters get-credentials <cluster> --region <region>
```

### Configured Project

| Setting | Value |
|---------|-------|
| SSO Session | `<sso-session-name>` |
| SSO Start URL | `https://<org>.awsapps.com/start`  <!-- redacted: public repo --> |
| Secrets Project | `<gcp-secrets-project>` |

---

## AWS CLI

> **Config:** `~/.dotfiles/.aws/config`

### Profile Management

The `aws_profile` helper was removed — the `aws` CLI is not installed on this
machine. Reinstate both together when taking on an AWS project.

### Configured Profile

| Setting | Value |
|---------|-------|
| Profile name | `Admin-Management` |
| SSO account | `<aws-account-id>` |
| SSO role | `AWSAdministratorAccess` |
| Region | `ca-central-1` |
| Output | `yaml` |

### SSO Login

```bash
aws sso login --profile Admin-Management
aws sts get-caller-identity        # verify current identity
```

### Common Operations

```bash
aws s3 ls                                          # list buckets
aws s3 cp <file> s3://<bucket>/<key>               # upload file
aws ec2 describe-instances --output table          # list EC2 instances
aws eks update-kubeconfig --name <cluster>         # add cluster to kubeconfig
aws logs tail <log-group> --follow                 # tail CloudWatch logs
```

---

## kubectl — Kubernetes CLI

> **Alias config:** `~/.dotfiles/.alias/kubectl`

### Core Aliases

| Alias | Command |
|-------|---------|
| `k` | `kubectl` |
| `kns <namespace>` | `kubectl config set-context --current --namespace` — switch default namespace |
| `kctx <context>` | `kubectl config use-context` — switch cluster context |

### Get Resources

| Alias | Command |
|-------|---------|
| `kgp` | `kubectl get pods` |
| `kgpa` | `kubectl get pods --all-namespaces` |
| `kgs` | `kubectl get services` |
| `kgd` | `kubectl get deployments` |
| `kgn` | `kubectl get nodes` |
| `kgns` | `kubectl get namespaces` |

### Describe

| Alias | Command |
|-------|---------|
| `kdp <pod>` | `kubectl describe pod` |
| `kds <svc>` | `kubectl describe service` |
| `kdd <deploy>` | `kubectl describe deployment` |

### Operations

| Alias | Command |
|-------|---------|
| `kl <pod>` | `kubectl logs -f` — follow logs |
| `kex <pod> -- bash` | `kubectl exec -it` — interactive shell in pod |
| `ka <file>` | `kubectl apply -f` — apply manifest |
| `kak <dir>` | `kubectl apply -k` — apply kustomize directory |
| `krm <resource>` | `kubectl delete` |
| `kpf <pod> <local>:<remote>` | `kubectl port-forward` |
| `kro` | `kubectl rollout` |
| `krs <deploy>` | `kubectl rollout status` |

### Common Patterns

```bash
kgp -n production                           # pods in specific namespace
kl my-pod -n staging                        # follow logs in staging
kex my-pod -- /bin/bash                     # shell into pod
kns production                              # switch default namespace
kpf my-pod 8080:8080                        # forward port locally
krs deployment/my-app                       # wait for rollout to complete
k get events --sort-by='.lastTimestamp'     # recent cluster events
```

---

## k9s — Kubernetes TUI

> **Alias:** `k9s`
>
> **Config:** `~/.dotfiles/.config/k9s/`
>
> Theme: Catppuccin Macchiato Transparent

k9s is a terminal UI for Kubernetes. It provides a live, interactive view of all cluster resources.

### Navigation

| Key | Action |
|-----|--------|
| `0–9` | Switch to a predefined resource view (pods=0, services=1, etc.) |
| `:` | **Command mode** — type a resource name (e.g. `:pods`, `:deployments`) |
| `/` | **Filter** — fuzzy filter the current resource list |
| `Esc` | Go back / cancel |
| `Enter` | Drill into selected resource |
| `Tab` | Toggle focus between panels |

### Pod Operations

| Key | Action |
|-----|--------|
| `l` | View **logs** for selected pod |
| `s` | Open **shell** in selected pod |
| `d` | **Describe** resource |
| `e` | **Edit** resource YAML |
| `ctrl-d` | **Delete** resource |
| `ctrl-k` | **Kill** (force delete) pod |
| `y` | View resource **YAML** |
| `ctrl-f` | Toggle log auto-scroll |

### Views

| Command | Resource view |
|---------|--------------|
| `:pods` or `:po` | Pods |
| `:deployments` or `:dp` | Deployments (custom alias) |
| `:services` or `:svc` | Services |
| `:namespaces` or `:ns` | Namespaces |
| `:nodes` or `:no` | Nodes |
| `:secrets` or `:sec` | Secrets (custom alias) |
| `:jobs` or `:jo` | Jobs (custom alias) |
| `:clusterroles` or `:cr` | ClusterRoles (custom alias) |
| `:clusterrolebindings` or `:crb` | ClusterRoleBindings (custom alias) |
| `:roles` or `:ro` | Roles (custom alias) |
| `:rolebindings` or `:rb` | RoleBindings (custom alias) |
| `:networkpolicies` or `:np` | NetworkPolicies (custom alias) |

### Global Keys

| Key | Action |
|-----|--------|
| `?` | Show keybind help for current view |
| `ctrl-a` | Show all available resource aliases |
| `ctrl-e` | Toggle header (full screen) |
| `ctrl-g` | Toggle crumbs |
| `ctrl-s` | Save resource YAML to disk |
| `q` | Quit k9s |

---

*← [Git](git.md) | [Index](index.md) | [OpenCode →](opencode.md)*
