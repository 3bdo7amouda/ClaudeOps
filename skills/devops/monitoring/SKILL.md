# skill: devops/monitoring
# triggers: prometheus, grafana, loki, alerting, metrics, logs, observability, monitoring

## Install
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f values.yaml
```

## Key PromQL
```promql
rate(container_cpu_usage_seconds_total{namespace="prod"}[5m])
container_memory_working_set_bytes / container_spec_memory_limit_bytes > 0.9
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
increase(kube_pod_container_status_restarts_total[1h]) > 0
```

## Alert Rules
```yaml
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  for: 2m
  labels: { severity: critical }
- alert: PodCrashLooping
  expr: increase(kube_pod_container_status_restarts_total[15m]) > 3
  labels: { severity: warning }
- alert: MemoryPressure
  expr: container_memory_working_set_bytes / container_spec_memory_limit_bytes > 0.9
  for: 5m
  labels: { severity: warning }
```

## LogQL
```logql
{namespace="prod"} |= "ERROR" | logfmt | level="error"
{app="nginx"} | json | duration > 1s
{namespace="prod"} | json | line_format "{{.level}} {{.msg}}"
```

## Incident CLI
```bash
kubectl top pods -A --sort-by=cpu
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
kubectl rollout restart deployment/app

# Quick triage
kubectl describe pod <pod> | grep -A 10 Events
kubectl logs <pod> --previous --tail=100
```

## SLO Definition
```yaml
# 99.9% availability SLO
- record: slo:http_availability:ratio_rate5m
  expr: |
    sum(rate(http_requests_total{status!~"5.."}[5m]))
    /
    sum(rate(http_requests_total[5m]))

- alert: SLOBudgetBurning
  expr: slo:http_availability:ratio_rate5m < 0.999
  for: 1m
  annotations:
    summary: "Error budget burning fast — {{ $value | humanizePercentage }} availability"
```

## OpenTelemetry (Traces)
```typescript
import { NodeSDK } from '@opentelemetry/sdk-node'
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: `${process.env.OTEL_ENDPOINT}/v1/traces` }),
  instrumentations: [getNodeAutoInstrumentations()],
})
sdk.start()

// Custom span
import { trace } from '@opentelemetry/api'
const tracer = trace.getTracer('my-service')
const span = tracer.startSpan('process-order')
span.setAttribute('order.id', orderId)
span.setAttribute('user.id', userId)
try {
  await processOrder(orderId)
} catch (e) {
  span.recordException(e as Error)
  span.setStatus({ code: SpanStatusCode.ERROR })
} finally {
  span.end()
}
```

## Alert Runbook Template
```markdown
## Alert: HighErrorRate

**Severity:** Critical
**Meaning:** >5% of HTTP requests are returning 5xx over 5 minutes

**Impact:** Users experiencing errors. Revenue/data loss possible.

**Step 1 (2 min): Identify scope**
  kubectl get events -n prod --sort-by='.lastTimestamp' | tail -20
  kubectl top pods -n prod

**Step 2 (5 min): Check logs**
  {namespace="prod"} |= "ERROR" | logfmt | level="error"

**Step 3: Common fixes**
  - OOMKilled → increase memory limits or find leak
  - CrashLoopBackOff → kubectl logs <pod> --previous
  - DB connection errors → check RDS CloudWatch

**Escalate if:** Not resolved in 15 min → page on-call lead
```

## Grafana Dashboard as Code
```bash
# Export existing dashboard
curl -s http://admin:admin@localhost:3000/api/dashboards/uid/my-dash | jq .dashboard > dashboard.json

# Import via API
curl -X POST http://admin:admin@localhost:3000/api/dashboards/import \
  -H 'Content-Type: application/json' \
  -d @dashboard.json
```
