# skill: devops/automation
# triggers: bash, script, automate, cron, python, makefile, cli, tooling

## Bash Template
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "Usage: $0 -e <env>" >&2; exit 1; }
ENV=""; while getopts "e:h" o; do case $o in e) ENV=$OPTARG;; *) usage;; esac; done
[[ -z "$ENV" ]] && usage

log() { echo "[$(date -u +%FT%TZ)] INFO  $*"; }
err() { echo "[$(date -u +%FT%TZ)] ERROR $*" >&2; }
die() { err "$@"; exit 1; }
trap 'log "done"' EXIT

command -v aws &>/dev/null || die "aws CLI required"
[[ "$ENV" =~ ^(dev|staging|prod)$ ]] || die "invalid env: $ENV"
```

## Patterns
```bash
# Retry with backoff
retry() {
  local n=0 max=3
  until [[ $n -ge $max ]]; do "$@" && return; n=$((n+1)); sleep $((2**n)); done
  return 1
}

# Wait for condition
wait_for() {
  local cmd=$1 timeout=${2:-120} start=$SECONDS
  until eval "$cmd"; do
    [[ $((SECONDS-start)) -gt $timeout ]] && die "timeout: $cmd"; sleep 5
  done
}

# Parallel + wait
for svc in app worker; do kubectl rollout restart deploy/$svc & done; wait

# Required var
: "${MY_VAR:?Must set MY_VAR}"

# Temp dir cleanup
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT
```

## Python Skeleton
```python
#!/usr/bin/env python3
import boto3, sys, logging, argparse
log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

def main(env, dry_run=False):
    client = boto3.client("ec2")
    try:
        pass  # logic here
    except Exception as e:
        log.error(e); return 1
    return 0

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--env", required=True, choices=["dev","staging","prod"])
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args()
    sys.exit(main(a.env, a.dry_run))
```

## Makefile Pattern
```makefile
.PHONY: help build test deploy clean
.DEFAULT_GOAL := help

ENV ?= dev
IMAGE_TAG ?= $(shell git rev-parse --short HEAD)

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

build:  ## Build docker image
	docker build -t app:$(IMAGE_TAG) .

test:  ## Run tests
	docker run --rm app:$(IMAGE_TAG) npm test

deploy:  ## Deploy to ENV (default: dev)
	./scripts/deploy.sh -e $(ENV) -t $(IMAGE_TAG)

clean:  ## Remove local artifacts
	docker rmi app:$(IMAGE_TAG) 2>/dev/null; true
```

## From: superpowers
TDD principle applied to scripts: write the test/validation check first, then the logic. Every script should have a dry-run mode that shows what would happen without doing it. Verification gate: after any deploy script, run a health check and only exit 0 if health passes.
