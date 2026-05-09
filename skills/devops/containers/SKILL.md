# skill: devops/containers
# triggers: docker, container, image, dockerfile, kubernetes, k8s, helm, pod, hpa, autoscale

## Dockerfile — Production Standard
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=app:app . .
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "server.js"]
```

## K8s Deployment — Full Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata: { name: app }
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }
  selector: { matchLabels: { app: app } }
  template:
    spec:
      securityContext: { runAsNonRoot: true, runAsUser: 1000 }
      containers:
        - name: app
          image: IMAGE:TAG
          resources:
            requests: { cpu: 100m, memory: 128Mi }
            limits: { cpu: 500m, memory: 256Mi }
          livenessProbe:
            httpGet: { path: /health, port: 3000 }
            initialDelaySeconds: 15
          readinessProbe:
            httpGet: { path: /ready, port: 3000 }
            initialDelaySeconds: 5
```

## K8s Ops
```bash
kubectl apply -f k8s/ --dry-run=server
kubectl apply -f k8s/
kubectl rollout status deployment/app -w
kubectl rollout undo deployment/app
kubectl logs -f deploy/app --tail=100
kubectl exec -it deploy/app -- sh
kubectl top pods -l app=app
```

## Helm Chart Structure
```
chart/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    └── hpa.yaml
```

```bash
helm upgrade --install app ./chart \
  -f chart/values-prod.yaml \
  --set image.tag=$IMAGE_TAG \
  --namespace prod --create-namespace \
  --atomic --timeout 5m
```

## Multi-Arch Build (AMD64 + ARM64)
```bash
docker buildx create --use --name multi
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag $IMAGE:$TAG \
  --push .
```

## HPA — Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: app }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: app }
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: { type: Utilization, averageUtilization: 70 }
    - type: Resource
      resource:
        name: memory
        target: { type: Utilization, averageUtilization: 80 }
```

## Security Hardening
```yaml
# NetworkPolicy — default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
# Allow only app to db
spec:
  podSelector: { matchLabels: { app: backend } }
  egress:
    - to: [{ podSelector: { matchLabels: { app: postgres } } }]
      ports: [{ port: 5432 }]
```
