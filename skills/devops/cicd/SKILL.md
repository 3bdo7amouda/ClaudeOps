# skill: devops/cicd
# triggers: pipeline, CI/CD, github actions, gitlab ci, jenkins, workflow, deploy

## GitHub Actions — Full Pipeline
```yaml
name: CI/CD
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }

permissions:
  contents: read
  id-token: write
  packages: write

env:
  IMAGE: ${{ secrets.ECR_REGISTRY }}/${{ github.event.repository.name }}
  TAG: ${{ github.sha }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: aws-actions/amazon-ecr-login@v2
      - run: |
          docker build -t $IMAGE:$TAG .
          docker push $IMAGE:$TAG

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: |
          aws eks update-kubeconfig --name ${{ secrets.EKS_CLUSTER }}
          kubectl set image deployment/app app=$IMAGE:$TAG
          kubectl rollout status deployment/app --timeout=5m
```

## Rollback
```bash
kubectl rollout undo deployment/app
kubectl rollout history deployment/app
```

## Rules
- OIDC only — no static AWS keys in secrets
- Pin all action versions to SHA
- Gate prod with `environment:` + required reviewers
- Always test → build → deploy order with `needs:`

## Verification Gate (verification-before-completion pattern)
```yaml
  verify:
    needs: deploy
    steps:
      - name: Smoke test
        run: |
          sleep 15
          curl -f https://$APP_URL/health || exit 1
          echo "Deploy verified at $(date -u)"
```

## From: superpowers
Never claim deploy is complete without fresh verification evidence. Run the smoke test command in the same step that makes the completion claim. "Should work" is not evidence — exit code 0 is.

## GitHub Actions — Cache + Matrix
```yaml
  build:
    strategy:
      matrix:
        platform: [linux/amd64, linux/arm64]  # multi-arch
    steps:
      - uses: actions/cache@v4                 # cache node_modules
        with:
          path: ~/.npm
          key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

  test:
    strategy:
      matrix:
        node: [20, 22]
        os: [ubuntu-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with: { node-version: ${{ matrix.node }} }
      - run: npm test
```

## Reusable Workflow
```yaml
# .github/workflows/deploy.yml — callable from other repos
on:
  workflow_call:
    inputs:
      environment: { type: string, required: true }
    secrets:
      AWS_ROLE_ARN: { required: true }

jobs:
  deploy:
    uses: org/shared-workflows/.github/workflows/deploy.yml@main
    with: { environment: prod }
    secrets: inherit
```

## GitLab CI Equivalent
```yaml
stages: [test, build, deploy]

test:
  stage: test
  script: [make test]

build:
  stage: build
  needs: [test]
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy_prod:
  stage: deploy
  needs: [build]
  environment: production
  when: manual
  only: [main]
  script:
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```
