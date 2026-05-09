# skill: devops/networking
# triggers: ingress, nginx ingress, cert-manager, service mesh, istio, linkerd, network policy, load balancer, tls termination

## Ingress (NGINX) — Production Config
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts: [app.example.com]
      secretName: app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: app, port: { number: 3000 } }
```

## cert-manager — Let's Encrypt
```bash
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set installCRDs=true
```
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata: { name: letsencrypt-prod }
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ops@example.com
    privateKeySecretRef: { name: letsencrypt-prod }
    solvers:
      - http01:
          ingress: { class: nginx }
```

## NetworkPolicy — Default Deny
```yaml
# Block all ingress/egress by default, then allow explicitly
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny, namespace: prod }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
# Allow app to reach database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-app-to-db, namespace: prod }
spec:
  podSelector:
    matchLabels: { app: postgres }
  ingress:
    - from:
        - podSelector: { matchLabels: { app: api } }
      ports:
        - port: 5432
```

## NGINX Ingress Install
```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb
```

## Service Mesh — Linkerd (lightweight)
```bash
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
# Annotate namespace to inject sidecars
kubectl annotate ns prod linkerd.io/inject=enabled
linkerd check
linkerd viz dashboard
```

## Internal DNS Patterns (K8s)
```
# Service: my-service.my-namespace.svc.cluster.local
# Short form within same namespace: my-service
# Cross-namespace: my-service.other-namespace

# Headless service for statefulsets (each pod gets DNS)
clusterIP: None  # → pod-0.my-svc.namespace.svc.cluster.local
```

## External DNS (auto-update Route53 from K8s)
```bash
helm upgrade --install external-dns external-dns/external-dns \
  --set provider=aws \
  --set aws.region=us-east-1 \
  --set policy=upsert-only
```

## Debugging Networking
```bash
# Test connectivity from inside cluster
kubectl run debug --image=busybox --rm -it -- sh
  wget -qO- http://service-name:port/health

# Dump network policies
kubectl get networkpolicy -A -o yaml

# Check endpoints behind a service
kubectl get endpoints service-name

# Port-forward for local debugging
kubectl port-forward svc/my-service 8080:3000
```
