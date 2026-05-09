# skill: dev/cli
# triggers: cli, command line, cli tool, oclif, commander, clack, ink, terminal, shell tool, bin script

## Stack Decision
```
Node.js:
  clack + commander → interactive prompts + subcommands (best DX)
  oclif             → plugin system, complex CLIs, Heroku-style
  ink               → React for terminal (rich interactive UIs)

Python:
  typer + rich      → typed args, beautiful output (recommended)
  click             → mature, composable
```

## Node.js CLI (clack + commander)
```typescript
#!/usr/bin/env node
// bin/mycli.ts
import { program } from 'commander'
import * as p from '@clack/prompts'
import { deploy } from './commands/deploy.js'

program
  .name('mycli')
  .version('1.0.0')

program
  .command('deploy [env]')
  .description('Deploy to environment')
  .option('-d, --dry-run', 'preview changes')
  .action(deploy)

program.parse()
```
```typescript
// commands/deploy.ts
export async function deploy(env: string | undefined, opts: { dryRun?: boolean }) {
  p.intro('Deploy')

  const environment = env ?? await p.select({
    message: 'Select environment',
    options: [
      { value: 'dev', label: 'Development' },
      { value: 'staging', label: 'Staging' },
      { value: 'prod', label: 'Production', hint: 'requires approval' },
    ],
  })

  if (p.isCancel(environment)) { p.cancel('Cancelled'); process.exit(0) }

  const spinner = p.spinner()
  spinner.start('Deploying...')
  // do work
  spinner.stop('Deploy complete')
  p.outro('Done')
}
```

## Python CLI (typer + rich)
```python
#!/usr/bin/env python3
import typer
from rich.console import Console
from rich.table import Table
from rich.progress import track

app = typer.Typer(name="mycli", help="My production CLI")
console = Console()

@app.command()
def deploy(
    env: str = typer.Argument("dev", help="Target environment"),
    dry_run: bool = typer.Option(False, "--dry-run", "-d"),
    yes: bool = typer.Option(False, "--yes", "-y", help="Skip confirmation"),
):
    """Deploy to environment."""
    if env == "prod" and not yes:
        typer.confirm("Deploy to production?", abort=True)

    for step in track(["Build", "Push", "Apply"], description="Deploying..."):
        if not dry_run:
            run_step(step, env)

    console.print(f"[green]✓ Deployed to {env}[/green]")

# Rich table output
def list_resources(items: list[dict]):
    table = Table(title="Resources")
    table.add_column("Name", style="cyan")
    table.add_column("Status", style="green")
    for item in items:
        table.add_row(item["name"], item["status"])
    console.print(table)

if __name__ == "__main__":
    app()
```

## package.json Setup
```json
{
  "bin": { "mycli": "./dist/bin/mycli.js" },
  "scripts": {
    "build": "tsup src/bin/mycli.ts --format esm --banner.js '#!/usr/bin/env node'",
    "dev":   "tsx src/bin/mycli.ts"
  }
}
```
```bash
npm link        # install locally for testing
npm publish     # publish to npm
```

## Config File Pattern
```typescript
import { cosmiconfig } from 'cosmiconfig'

const explorer = cosmiconfig('mycli')  // reads .myclicrc, mycli.config.js, etc.
const result = await explorer.search()
const config = result?.config ?? {}
```

## Patterns
```typescript
// Exit codes
process.exit(0)   // success
process.exit(1)   // general error
process.exit(2)   // usage error

// Color only when TTY (respect pipes/CI)
const useColor = process.stdout.isTTY && !process.env.NO_COLOR

// Read stdin
if (!process.stdin.isTTY) {
  const input = await new Promise<string>(r => {
    let data = ''; process.stdin.on('data', c => data += c); process.stdin.on('end', () => r(data))
  })
}
```

## Rules
- Always handle `--help` and `--version`
- Exit code 0 = success, 1 = error (scripts depend on this)
- `--dry-run` for any destructive command
- Require explicit `--yes`/`-y` for prod/destructive actions
- Print errors to stderr, data to stdout (enables piping)
