# ☸️ Challenge 2: Kubernetes Fundamentals (Telco View)

> **SYLVA-LAB** | Namespace: `nf-5g` | Node: `core`

---

## 🎯 Objective

Deploy a simulated 5G AMF (Access & Mobility Management Function) as a Kubernetes pod and understand how Kubernetes primitives map to telecom network function concepts.

---

## 🌐 Access

| Service | URL | Description |
|---|---|---|
| AMF API | http://localhost:8002 | 5G AMF mock REST API |

---

## 📂 PRACTICE 2.1: Kubernetes Primitives → Telecom Mapping

### The mapping

| Kubernetes Object | Telecom Equivalent |
|---|---|
| **Pod** | A Network Function instance (AMF, SMF, UPF…) |
| **Deployment** | NF with lifecycle management (rolling update, restart) |
| **Service** | NF communication endpoint (SBI interface) |
| **Namespace** | Network slice or NF domain isolation |
| **ConfigMap** | NF configuration (operator settings, parameters) |
| **Node labels** | Site classification (core, edge, RAN) |

```bash
# See the AMF pod running on the core node
kubectl get pods -n nf-5g -o wide

# See the node where AMF is running
kubectl get nodes -l sylva-site=core

# Describe the AMF pod (see nodeSelector, resources, probes)
kubectl describe pod -n nf-5g -l app=amf
```

**📸 To capture:** Output of `kubectl get pods -n nf-5g -o wide`

---

## 📂 PRACTICE 2.2: Explore the AMF as a Network Function

### Step 1: Check AMF health
```bash
curl -s http://localhost:8002/health | jq .
```

**✅ Expected:**
```json
{
  "status": "UP",
  "nf": "AMF",
  "version": "15.3.0",
  "instance": "amf-<pod-hash>"
}
```

### Step 2: Get AMF NF information
```bash
curl -s http://localhost:8002/namf-comm/v1/nf-info | jq .
```

**💡 Explanation:** In a real 5G network, the AMF registers itself with the NRF (Network Repository Function) and exposes this information. The `namf-comm` path follows the 3GPP SBI (Service Based Interface) naming convention.

### Step 3: Register a UE (User Equipment)
```bash
curl -s -X POST http://localhost:8002/namf-comm/v1/ue-registrations \
  -H "Content-Type: application/json" \
  -d '{
    "supi": "imsi-208930000000001",
    "plmnId": { "mcc": "208", "mnc": "93" }
  }' | jq .
```

**💡 Explanation:**
- `supi` = Subscription Permanent Identifier (the 5G equivalent of IMSI)
- `plmnId` = Public Land Mobile Network ID (operator identifier)
- When a UE (phone) connects to the network, it sends a registration request to the AMF

### Step 4: List all registered UEs
```bash
curl -s http://localhost:8002/namf-comm/v1/ue-registrations | jq .
```

**📸 To capture:** Terminal output showing UE registration response with `registrationId`

---

## 📂 PRACTICE 2.3: Kubernetes Operations on a Network Function

### Scale the AMF
```bash
# Scale to 2 replicas (simulates AMF HA)
kubectl scale deployment amf --replicas=2 -n nf-5g

# Watch the new pod appear
kubectl get pods -n nf-5g -w

# Scale back to 1
kubectl scale deployment amf --replicas=1 -n nf-5g
```

### Inspect logs (as an operator would)
```bash
kubectl logs -n nf-5g -l app=amf --tail=20
```

### Update NF configuration (ConfigMap)
```bash
# View current config
kubectl get configmap amf-config -n nf-5g -o yaml | head -30

# Edit the config (add a custom label)
kubectl label pod -n nf-5g -l app=amf nf-status=active
kubectl get pods -n nf-5g --show-labels
```

### Namespaces as network slices
```bash
# Create a second namespace for a different slice
kubectl create namespace nf-5g-slice2

# Label it
kubectl label namespace nf-5g-slice2 network-slice=enterprise

# List namespaces with labels
kubectl get namespaces --show-labels | grep network-slice
```

**📸 To capture:** Output of `kubectl get namespaces --show-labels`

---

## 📝 Reference Commands

```bash
# All NF pods with node placement
kubectl get pods -n nf-5g -o wide

# Service details
kubectl get svc -n nf-5g

# Node labels (edge vs core)
kubectl get nodes --show-labels | grep sylva-site

# AMF logs
kubectl logs -n nf-5g deployment/amf -f

# AMF resource usage
kubectl top pod -n nf-5g 2>/dev/null || echo "(metrics-server not installed)"
```

---

## ✅ Validation Checklist

- [ ] AMF pod running on core node (`kubectl get pods -n nf-5g -o wide`)
- [ ] AMF health endpoint returns HTTP 200
- [ ] AMF NF info endpoint returns `nfType: AMF`
- [ ] UE registration via POST returns `registrationId`
- [ ] AMF scaled to 2 replicas and back to 1
- [ ] Second namespace created for a different slice
- [ ] Screenshots captured

---

**🎉 Challenge 2 complete! Proceed to Challenge 3.**
