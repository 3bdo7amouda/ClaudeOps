# skill: devops/gitops
# triggers: gitops, argocd, flux, progressive delivery, argo rollouts, canary, blue-green, sync, reconcile

## ArgoCD — App Definition
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/infra
    targetRevision: main
    path: k8s/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
```

## ArgoCD CLI — Essential Commands
```bash
argocd app list
argocd app get my-app
argocd app sync my-app --prune
argocd app rollback my-app 3          # rollback to revision 3
argocd app history my-app
argocd app diff my-app                 # diff live vs desired
argocd app set my-app --sync-policy automated
```

## Kustomize Overlay Structure (GitOps-ready)
```
k8s/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml       # patches for dev
    │   └── patch-replicas.yaml
    ├── staging/
    └── prod/
        ├── kustomization.yaml
        └── patch-resources.yaml     # higher limits for prod
```
```yaml
# overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [../../base]
images:
  - name: app
    newTag: "abc1234"                # CI updates this line
patches:
  - path: patch-resources.yaml
```

## Progressive Delivery (Argo Rollouts)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata: { name: app }
spec:
  replicas: 5
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: { duration: 5m }
        - setWeight: 30
        - pause: { duration: 5m }
        - setWeight: 100
      analysis:
        templates: [{ templateName: success-rate }]
        startingStep: 2
```

## Flux (alternative to ArgoCD)
```bash
# Bootstrap
flux bootstrap github \
  --owner=org --repo=infra \
  --branch=main --path=clusters/prod

# Add app
flux create source git my-app \
  --url=https://github.com/org/app \
  --branch=main
flux create kustomization my-app \
  --source=my-app --path=./k8s \
  --prune=true --interval=1m
```

## CI → GitOps Handoff
```yaml
# In GitHub Actions — update image tag (triggers ArgoCD sync)
- name: Update image tag
  run: |
    cd infra
    kustomize edit set image app=$IMAGE:$TAG \
      --kustomization k8s/overlays/prod/kustomization.yaml
    git config user.email "ci@company.com"
    git add .
    git commit -m "chore: deploy app $TAG"
    git push
```

## Rules
- Never apply kubectl directly in prod — always commit to Git
- ArgoCD: enable `selfHeal` — drift auto-corrected
- Separate app repos from infra/config repos
- Image tags in Git = audit trail of every deploy
- Progressive delivery for any change affecting >10% traffic
