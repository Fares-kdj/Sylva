# 🌐 Challenge 1: Introduction to Sylva in Telco Cloud

> **SYLVA-LAB – Getting Started with Sylva**
> Level: Beginner | Mode: Repo exploration + Web

---

## 🎯 Objective

Understand what Sylva is, why it exists in the telecom context, and identify where 5G Network Functions would run in a Sylva architecture.

---

## 📋 Prerequisites

- `git` installed
- `../start-cluster.sh` already run (to clone sylva-core)
- Internet access

---

## 📂 PRACTICE 1.1: What is Sylva?

### Step 1: Read the Sylva overview

Navigate to: **https://sylvaproject.org**

Sylva is a **Linux Foundation project** that provides a cloud-native infrastructure framework for telecom workloads. It is built on top of Kubernetes and defines how to deploy, configure, and manage the infrastructure that runs 5G Network Functions.

**Key positioning:**

```
Physical Hardware (servers, switches)
         │
    Sylva Framework          ← what Sylva manages
    ├── Kubernetes cluster
    ├── CNI (Multus, SR-IOV)
    ├── Storage
    └── GitOps (Flux/ArgoCD)
         │
    5G Network Functions     ← what runs ON Sylva
    ├── AMF (Access & Mobility)
    ├── SMF (Session Management)
    ├── UPF (User Plane)
    └── ...
```

### Step 2: Explore the Sylva GitLab

Navigate to: **https://gitlab.com/sylva-projects**

Identify the main repositories:
- `sylva-core` — the core framework (charts, cluster templates)
- `sylva-elements` — reusable building blocks
- `sylva-units` — unit testing framework

**📸 To capture:** Screenshot of the Sylva GitLab project list.

---

## 📂 PRACTICE 1.2: Explore the sylva-core Repository

```bash
# From the root of SYLVA-LAB
ls sylva-core/
```

Identify the key folders:

| Folder | Purpose |
|---|---|
| `charts/` | Helm charts for infrastructure components |
| `cluster-templates/` | Ready-made cluster configurations |
| `unit-tests/` | Validation tests for Sylva components |
| `docs/` | Architecture documentation |

```bash
# List available Helm charts
ls sylva-core/charts/

# Look at a chart's values
cat sylva-core/charts/sylva-core/values.yaml 2>/dev/null | head -50
```

**📸 To capture:** Terminal output showing the sylva-core folder structure.

---

## 📂 PRACTICE 1.3: Map 5G NFs to a Sylva Architecture

### The 5G Core Network Functions

| NF | Full Name | Role |
|---|---|---|
| **AMF** | Access and Mobility Management Function | Handles UE registration and mobility |
| **SMF** | Session Management Function | Manages data sessions (PDU sessions) |
| **UPF** | User Plane Function | Forwards user data packets |
| **PCF** | Policy Control Function | Enforces QoS and charging policies |
| **UDM** | Unified Data Management | Stores subscriber data |
| **NRF** | Network Repository Function | Service discovery registry |

### Where would they run in Sylva?

```
Sylva Cluster
├── control-plane node
│   └── Kubernetes control plane
│
├── worker node (CORE site)
│   ├── namespace: nf-5g-core
│   │   ├── AMF pod  ← handles signaling
│   │   ├── SMF pod  ← manages sessions
│   │   └── NRF pod  ← service registry
│   └── namespace: nf-5g-data
│       └── UPF pod  ← data plane (needs DPDK/SR-IOV)
│
└── worker node (EDGE site)
    └── namespace: nf-5g-edge
        └── UPF pod  ← local breakout for MEC
```

### Your task: Fill in the mapping table

| 5G NF | Sylva Site (edge/core) | Kubernetes namespace | Reason |
|---|---|---|---|
| AMF | ? | ? | ? |
| SMF | ? | ? | ? |
| UPF (data plane) | ? | ? | ? |
| UPF (edge breakout) | ? | ? | ? |
| NRF | ? | ? | ? |

```bash
# Check the node labels in your cluster
kubectl get nodes --show-labels | grep sylva-site

# See which nodes are edge vs core
kubectl get nodes -l sylva-site=edge
kubectl get nodes -l sylva-site=core
```

**📸 To capture:** Your completed mapping table + terminal output showing node labels.

---

## 📝 Reference Commands

```bash
# Explore sylva-core charts
ls ../sylva-core/charts/

# Read Sylva architecture docs
find ../sylva-core/docs -name "*.md" 2>/dev/null | head -10

# Check node labels
kubectl get nodes -o wide --show-labels

# Describe a node (see all labels and taints)
kubectl describe node $(kubectl get nodes -l sylva-site=edge -o name | head -1)
```

---

## ✅ Validation Checklist

- [ ] Accessed sylvaproject.org and read the project overview
- [ ] Explored the Sylva GitLab and identified the main repos
- [ ] Listed the contents of `sylva-core/` locally
- [ ] Identified the 5G NF categories (control plane vs data plane)
- [ ] Completed the NF-to-Sylva mapping table
- [ ] Verified edge and core node labels in the cluster
- [ ] Screenshots captured

---

**🎉 Challenge 1 complete! Proceed to Challenge 2.**
