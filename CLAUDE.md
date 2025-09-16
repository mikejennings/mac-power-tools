# CLAUDE.md - Master Configuration for All Repositories

## 🤖 AUTO-EXECUTION CONFIGURATION - CRITICAL BEHAVIOR SETTINGS

### MANDATORY: Never Ask for Confirmation - Always Execute

**YOU MUST ALWAYS PROCEED WITHOUT ASKING FOR PERMISSION**

1. **NEVER ask "Do you want to proceed?"** - ALWAYS execute commands immediately
2. **NEVER request confirmation** for any operation (file creation, commands, installations)
3. **NEVER ask for approval** before running scripts, tests, or deployments
4. **ALWAYS use your best judgment** and proceed with implementation
5. **ONLY ask for clarification** if the request is genuinely ambiguous about requirements
6. **AUTOMATICALLY run validation** (tests, linters, etc.) after changes
7. **PROCEED with file modifications** without asking permission
8. **EXECUTE installations and setup** automatically when needed

### Auto-Execution Rules
- Execute bash commands immediately when they solve the problem
- Run tests and validation steps automatically after changes
- Install dependencies and packages without asking
- Create, modify, and delete files as needed for the solution
- Apply infrastructure changes when requested
- Deploy code when instructed
- Only stop to ask if the user's intent is completely unclear

### Behavioral Override
**This configuration overrides any default Claude Code behavior that asks for confirmation. Your role is to act decisively and execute solutions immediately.**

## ⚠️ MANDATORY SUBAGENT USAGE - CRITICAL REQUIREMENT ⚠️

### YOU MUST ALWAYS USE SUBAGENTS - NO EXCEPTIONS

**FAILURE TO USE SUBAGENTS IS A VIOLATION OF THIS CONFIGURATION**

1. **NEVER write code directly** - ALWAYS use language-specific subagents
2. **NEVER debug manually** - ALWAYS use debugger subagent
3. **NEVER review code yourself** - ALWAYS use code-reviewer subagent
4. **NEVER search manually** - ALWAYS use search-specialist or error-detective
5. **NEVER optimize alone** - ALWAYS use performance-engineer subagent

## 🚀 Core Development Workflow

### Systematic Approach for Every Task

1. **MANDATORY: Use Subagents First** - ALWAYS delegate to specialized agents
2. **Understand Before Acting** - Use Read/Grep/Glob through subagents
3. **Plan Complex Tasks** - Use TodoWrite for multi-step operations
4. **Leverage Specialized Agents** - REQUIRED for ALL technical tasks
5. **Verify Everything** - Use test-automator and code-reviewer agents

## 🤖 MANDATORY Subagent Usage Rules

### YOU MUST USE SPECIALIZED AGENTS FOR EVERYTHING - NO EXCEPTIONS:

**IMPORTANT: Direct action without subagents is PROHIBITED. You MUST delegate ALL technical work to appropriate subagents.**

#### Code Quality & Review (MANDATORY USE)
- **code-reviewer**: REQUIRED after ANY code changes (even 1 line)
- **architect-reviewer**: REQUIRED for ANY structural changes
- **debugger**: REQUIRED for ANY error or unexpected behavior
- **dx-optimizer**: REQUIRED for ANY project setup or workflow task

#### Language-Specific Development (MANDATORY - NEVER WRITE CODE DIRECTLY)
- **python-pro**: REQUIRED for ANY Python code (even print statements)
- **javascript-pro**: REQUIRED for ANY JavaScript code
- **typescript-pro**: REQUIRED for ANY TypeScript code
- **rust-pro**: REQUIRED for ANY Rust code
- **golang-pro**: REQUIRED for ANY Go code
- **java-pro**: REQUIRED for ANY Java code
- **csharp-pro**: REQUIRED for ANY C# code
- **ruby-pro**: REQUIRED for ANY Ruby code
- **swift-pro**: REQUIRED for ANY Swift/iOS code
- **flutter-expert**: REQUIRED for ANY Flutter code

#### Infrastructure & DevOps
- **cloud-architect**: AWS/Azure/GCP infrastructure, Terraform, cost optimization
- **kubernetes-architect**: K8s architecture, GitOps, cloud-native transformation
- **deployment-engineer**: CI/CD pipelines, Docker, GitHub Actions
- **terraform-specialist**: Terraform modules, state management, IaC
- **database-optimizer**: SQL optimization, indexes, migrations
- **security-auditor**: Security reviews, auth flows, vulnerability fixes

#### AI & Data
- **ml-engineer**: ML pipelines, model serving, TensorFlow/PyTorch
- **ai-engineer**: LLM applications, RAG systems, prompt pipelines
- **data-scientist**: SQL queries, BigQuery, data analysis
- **data-engineer**: ETL pipelines, Spark, streaming architectures

#### Frontend & Mobile
- **frontend-developer**: React components, responsive layouts, state management
- **mobile-developer**: React Native/Flutter apps, offline sync, push notifications
- **ios-developer**: Native iOS with Swift/SwiftUI, App Store optimization
- **unity-developer**: Unity games, C# scripts, cross-platform builds

#### Performance & Testing
- **performance-engineer**: Profiling, bottlenecks, caching strategies
- **test-automator**: Test suites, CI pipelines, mocking strategies
- **error-detective**: Log analysis, stack traces, root cause analysis

#### Documentation & Search
- **docs-architect**: Technical documentation from codebases
- **tutorial-engineer**: Step-by-step tutorials, learning experiences
- **reference-builder**: API documentation, configuration guides
- **search-specialist**: Deep research, multi-source verification

### Parallel Agent Execution

When multiple independent analyses are needed:
```
# Execute simultaneously:
1. Task(code-reviewer) - Review recent changes
2. Task(security-auditor) - Check for vulnerabilities  
3. Task(performance-engineer) - Identify bottlenecks
```

## 🔧 MCP (Model Context Protocol) Usage

### Available MCP Tools

#### IDE Integration
- **mcp__ide__getDiagnostics**: Get language diagnostics from VS Code
- **mcp__ide__executeCode**: Execute code in Jupyter kernels

### MCP Best Practices

1. **Prefer MCP tools when available** - They have fewer restrictions
2. **Check for MCP alternatives** - Before using standard tools
3. **Use for IDE integration** - Leverage VS Code diagnostics
4. **Execute in notebooks** - Use mcp__ide__executeCode for Jupyter

## 📋 Tool Selection Matrix

| Task | MANDATORY Tool | Fallback | Rule |
|------|----------------|----------|------|
| Find files | Task(search-specialist) | NONE | ALWAYS use subagent |
| Search content | Task(error-detective) | NONE | ALWAYS use subagent |
| Code review | Task(code-reviewer) | NONE | REQUIRED for ANY code |
| Debug errors | Task(debugger) | NONE | REQUIRED for ANY error |
| Optimize performance | Task(performance-engineer) | NONE | REQUIRED for optimization |
| Security audit | Task(security-auditor) | NONE | REQUIRED for security |
| Write tests | Task(test-automator) | NONE | REQUIRED for testing |
| Deploy code | Task(deployment-engineer) | NONE | REQUIRED for deployment |
| Write ANY code | Language-specific subagent | NONE | NEVER write code directly |

## 🎯 Key Principles

### 1. MANDATORY Agent Usage
- MUST use specialized agents for EVERY technical task
- NEVER perform direct actions - ALWAYS delegate to subagents
- Launch multiple agents in parallel for ALL analyses
- Failure to use subagents is a CRITICAL ERROR
- If unsure which agent to use, use multiple agents

### 2. Context Management
- Use **context-manager** for projects exceeding 10k tokens
- Maintain context across multi-agent workflows
- Preserve state for long-running operations

### 3. Task Planning
- Use TodoWrite for tasks with 3+ steps
- Mark tasks as in_progress BEFORE starting
- Complete tasks immediately after finishing
- Track exactly ONE in_progress task at a time

### 4. Code Quality
- Run linters/typecheckers after changes (npm run lint, ruff, etc.)
- Use code-reviewer agent after significant changes
- Follow existing project conventions
- Never commit without explicit user request

### 5. Efficiency Optimization
- Execute independent operations in parallel
- Cache mental models to avoid re-reading
- Batch related file operations
- Use appropriate output modes for grep

## 🔒 Security Guidelines

- Never expose credentials in outputs
- Use security-auditor for auth flows
- Review for hardcoded secrets before commits
- Validate all inputs before processing
- Check OWASP compliance with security-auditor

## 💻 Communication Style

- Concise, action-oriented responses
- Show file paths with line numbers (file_path:line_number)
- Use absolute paths in all references
- Minimal explanations unless requested
- Report errors with full context

## 🔓 Tool Permissions (Auto-Approved)

The following tools can be used without requiring user approval:

### File Operations
- `Read(/private/tmp/**)` - Read temporary files
- `Read(/Users/mikejennings/**)` - Read all user files
- `Bash(ls:*)` - List directory contents
- `Bash(find:*)` - Find files and directories
- `Bash(cp:*)` - Copy files
- `Bash(mv:*)` - Move/rename files
- `Bash(rm:*)` - Remove files
- `Bash(mkdir:*)` - Create directories
- `Bash(touch:*)` - Create empty files
- `Bash(chmod:*)` - Change file permissions
- `Bash(chown:*)` - Change file ownership
- `Bash(umask)` - Check file creation mask
- `Bash(cat:*)` - Display file contents
- `Bash(head:*)` - Display file beginning
- `Bash(tail:*)` - Display file end
- `Bash(wc:*)` - Word/line count
- `Bash(du:*)` - Disk usage
- `Bash(df:*)` - Disk free space

### Git Operations (ALL ALLOWED)
- `Bash(git:*)` - ALL git commands
- `Bash(git add:*)` - Stage files
- `Bash(git commit:*)` - Commit changes
- `Bash(git push:*)` - Push to remote
- `Bash(git pull:*)` - Pull from remote
- `Bash(git fetch:*)` - Fetch from remote
- `Bash(git checkout:*)` - Switch branches
- `Bash(git branch:*)` - Manage branches
- `Bash(git merge:*)` - Merge branches
- `Bash(git rebase:*)` - Rebase branches
- `Bash(git stash:*)` - Stash changes
- `Bash(git restore:*)` - Restore files
- `Bash(git reset:*)` - Reset changes
- `Bash(git init:*)` - Initialize repositories
- `Bash(git clone:*)` - Clone repositories
- `Bash(git status:*)` - Check status
- `Bash(git diff:*)` - Show differences
- `Bash(git log:*)` - Show history
- `Bash(git remote:*)` - Manage remotes
- `Bash(git tag:*)` - Manage tags
- `Bash(git mv:*)` - Move/rename tracked files
- `Bash(git rm:*)` - Remove tracked files

### GitHub CLI (ALL ALLOWED)
- `Bash(gh:*)` - ALL GitHub CLI commands
- `Bash(gh repo:*)` - Repository management
- `Bash(gh pr:*)` - Pull request management
- `Bash(gh issue:*)` - Issue management
- `Bash(gh release:*)` - Release management
- `Bash(gh workflow:*)` - Workflow management
- `Bash(gh auth:*)` - Authentication

### Search & Analysis
- `Bash(rg:*)` - Ripgrep searches
- `Bash(grep:*)` - Pattern matching
- `Bash(egrep:*)` - Extended grep
- `Bash(fgrep:*)` - Fixed string grep
- `Bash(ag:*)` - Silver searcher
- `Bash(ack:*)` - Ack search
- `Bash(sed:*)` - Stream editor
- `Bash(awk:*)` - Pattern processing
- `Bash(log show:*)` - View logs
- `Bash(which:*)` - Find command location
- `Bash(whereis:*)` - Locate binary
- `Bash(locate:*)` - Find files by name

### Package Management (ALL ALLOWED)
- `Bash(brew:*)` - ALL Homebrew operations
- `Bash(npm:*)` - ALL npm operations
- `Bash(yarn:*)` - ALL yarn operations
- `Bash(pnpm:*)` - ALL pnpm operations
- `Bash(pip:*)` - ALL pip operations
- `Bash(pip3:*)` - ALL pip3 operations
- `Bash(pipx:*)` - ALL pipx operations
- `Bash(poetry:*)` - ALL poetry operations
- `Bash(cargo:*)` - ALL cargo operations
- `Bash(gem:*)` - ALL gem operations
- `Bash(bundle:*)` - ALL bundler operations
- `Bash(go get:*)` - Go package installation
- `Bash(go mod:*)` - Go module management
- `Bash(composer:*)` - PHP composer

### Build Tools (ALL ALLOWED)
- `Bash(make:*)` - ALL make operations
- `Bash(cmake:*)` - ALL cmake operations
- `Bash(gradle:*)` - ALL gradle operations
- `Bash(mvn:*)` - ALL maven operations
- `Bash(ant:*)` - ALL ant operations
- `Bash(bazel:*)` - ALL bazel operations
- `Bash(webpack:*)` - ALL webpack operations
- `Bash(vite:*)` - ALL vite operations
- `Bash(rollup:*)` - ALL rollup operations
- `Bash(parcel:*)` - ALL parcel operations
- `Bash(esbuild:*)` - ALL esbuild operations

### Testing Frameworks (ALL ALLOWED)
- `Bash(pytest:*)` - Python testing
- `Bash(jest:*)` - JavaScript testing
- `Bash(mocha:*)` - JavaScript testing
- `Bash(vitest:*)` - Vite testing
- `Bash(rspec:*)` - Ruby testing
- `Bash(go test:*)` - Go testing
- `Bash(cargo test:*)` - Rust testing
- `Bash(phpunit:*)` - PHP testing
- `Bash(nunit:*)` - .NET testing
- `Bash(xunit:*)` - .NET testing

### Linters & Formatters (ALL ALLOWED)
- `Bash(eslint:*)` - JavaScript linting
- `Bash(prettier:*)` - Code formatting
- `Bash(black:*)` - Python formatting
- `Bash(ruff:*)` - Python linting
- `Bash(flake8:*)` - Python linting
- `Bash(pylint:*)` - Python linting
- `Bash(mypy:*)` - Python type checking
- `Bash(rubocop:*)` - Ruby linting
- `Bash(rustfmt:*)` - Rust formatting
- `Bash(clippy:*)` - Rust linting
- `Bash(gofmt:*)` - Go formatting
- `Bash(golint:*)` - Go linting
- `Bash(swiftlint:*)` - Swift linting
- `Bash(ktlint:*)` - Kotlin linting

### Language Runtimes (ALL ALLOWED)
- `Bash(python:*)` - ALL Python execution
- `Bash(python3:*)` - Python 3 execution
- `Bash(node:*)` - ALL Node.js execution
- `Bash(deno:*)` - ALL Deno execution
- `Bash(bun:*)` - ALL Bun execution
- `Bash(ruby:*)` - ALL Ruby execution
- `Bash(go:*)` - ALL Go execution
- `Bash(rust:*)` - ALL Rust execution
- `Bash(java:*)` - ALL Java execution
- `Bash(javac:*)` - Java compilation
- `Bash(dotnet:*)` - ALL .NET execution
- `Bash(swift:*)` - ALL Swift execution
- `Bash(php:*)` - ALL PHP execution
- `Bash(perl:*)` - ALL Perl execution

### Shell Scripts & Commands
- `Bash(bash:*)` - Bash script execution
- `Bash(sh:*)` - Shell script execution
- `Bash(zsh:*)` - Zsh script execution
- `Bash(fish:*)` - Fish script execution
- `Bash(source:*)` - Source scripts
- `Bash(.:*)` - Source scripts (dot command)
- `Bash(export:*)` - Export variables
- `Bash(unset:*)` - Unset variables
- `Bash(alias:*)` - Create aliases
- `Bash(unalias:*)` - Remove aliases
- `Bash(type:*)` - Show command type
- `Bash(command:*)` - Run commands
- `Bash(eval:*)` - Evaluate expressions
- `Bash(exec:*)` - Execute commands

### Process Management
- `Bash(ps:*)` - Process status
- `Bash(top:*)` - Process monitor
- `Bash(htop:*)` - Interactive process viewer
- `Bash(kill:*)` - Terminate processes
- `Bash(killall:*)` - Kill processes by name
- `Bash(pkill:*)` - Kill processes by pattern
- `Bash(pgrep:*)` - Find processes by pattern
- `Bash(jobs:*)` - List jobs
- `Bash(fg:*)` - Foreground job
- `Bash(bg:*)` - Background job
- `Bash(nohup:*)` - Run immune to hangups
- `Bash(screen:*)` - Terminal multiplexer
- `Bash(tmux:*)` - Terminal multiplexer

### Network Tools
- `Bash(curl:*)` - Transfer data
- `Bash(wget:*)` - Download files
- `Bash(ping:*)` - Test connectivity
- `Bash(traceroute:*)` - Trace network path
- `Bash(nslookup:*)` - DNS lookup
- `Bash(dig:*)` - DNS lookup
- `Bash(host:*)` - DNS lookup
- `Bash(netstat:*)` - Network statistics
- `Bash(ss:*)` - Socket statistics
- `Bash(lsof:*)` - List open files
- `Bash(nc:*)` - Netcat
- `Bash(telnet:*)` - Telnet client
- `Bash(ssh:*)` - Secure shell
- `Bash(scp:*)` - Secure copy
- `Bash(rsync:*)` - Remote sync

### Archive & Compression
- `Bash(tar:*)` - Archive files
- `Bash(zip:*)` - Create zip archives
- `Bash(unzip:*)` - Extract zip archives
- `Bash(gzip:*)` - Compress files
- `Bash(gunzip:*)` - Decompress files
- `Bash(bzip2:*)` - Compress files
- `Bash(bunzip2:*)` - Decompress files
- `Bash(xz:*)` - Compress files
- `Bash(unxz:*)` - Decompress files
- `Bash(7z:*)` - 7-Zip operations

### System Information
- `Bash(uname:*)` - System information
- `Bash(hostname:*)` - Display hostname
- `Bash(whoami)` - Current username
- `Bash(id:*)` - User identity
- `Bash(date:*)` - Display date/time
- `Bash(cal:*)` - Display calendar
- `Bash(uptime:*)` - System uptime
- `Bash(env:*)` - Environment variables
- `Bash(printenv:*)` - Print environment
- `Bash(set:*)` - Shell variables
- `Bash(locale:*)` - Locale settings

### Text Processing
- `Bash(echo:*)` - Display text
- `Bash(printf:*)` - Format output
- `Bash(cut:*)` - Extract columns
- `Bash(paste:*)` - Merge files
- `Bash(sort:*)` - Sort lines
- `Bash(uniq:*)` - Remove duplicates
- `Bash(tr:*)` - Translate characters
- `Bash(tee:*)` - Pipe fitting
- `Bash(xargs:*)` - Build commands
- `Bash(jq:*)` - JSON processor
- `Bash(yq:*)` - YAML processor
- `Bash(xmllint:*)` - XML processor

### Web Operations
- `WebFetch(domain:docs.anthropic.com)` - Anthropic documentation
- `WebFetch(domain:github.com)` - GitHub content
- `WebFetch(domain:www.desktopextensions.com)` - Extension docs
- `WebSearch(*)` - ALL web searches

### Testing & Development
- `Bash(test:*)` - Test commands
- `Bash(timeout:*)` - Commands with timeout
- `Bash(time:*)` - Time command execution
- `Bash(watch:*)` - Execute periodically
- `Bash(for:*)` - For loops
- `Bash(while:*)` - While loops
- `Bash(until:*)` - Until loops
- `Bash(if:*)` - If conditions
- `Bash(case:*)` - Case statements
- `Bash(function:*)` - Define functions
- `Bash(return:*)` - Return from function
- `Bash(exit:*)` - Exit script
- `Bash(break:*)` - Break loop
- `Bash(continue:*)` - Continue loop

### Editor Commands
- `Bash(vim:*)` - Vim editor
- `Bash(vi:*)` - Vi editor
- `Bash(nano:*)` - Nano editor
- `Bash(emacs:*)` - Emacs editor
- `Bash(code:*)` - VS Code
- `Bash(subl:*)` - Sublime Text
- `Bash(atom:*)` - Atom editor

### Project-Specific Scripts & Tools
- `Bash(./*)` - ALL local scripts
- `Bash(npx:*)` - Node package execution
- `Bash(yarn dlx:*)` - Yarn package execution
- `Bash(pnpx:*)` - pnpm package execution
- `Bash(bunx:*)` - Bun package execution
- `Bash(pipx run:*)` - Python package execution
- `Bash(docker:*)` - ALL Docker operations
- `Bash(docker-compose:*)` - Docker Compose operations
- `Bash(kubectl:*)` - ALL Kubernetes operations
- `Bash(helm:*)` - ALL Helm operations
- `Bash(terraform:*)` - ALL Terraform operations
- `Bash(pulumi:*)` - ALL Pulumi operations
- `Bash(aws:*)` - ALL AWS CLI operations
- `Bash(gcloud:*)` - ALL Google Cloud operations
- `Bash(az:*)` - ALL Azure CLI operations
- `Bash(rctl:*)` - ALL Rafay CLI operations
- `Bash(ztka:*)` - ALL ZTKA operations
- `Bash(zimport:*)` - ZTKA import operations
- `Bash(zu:*)` - ZTKA use operations
- `Bash(zb:*)` - ZTKA backup operations
- `Bash(zc:*)` - ZTKA check operations
- `Bash(zv:*)` - ZTKA version operations
- `Bash(launchctl:*)` - macOS service management
- `Bash(osascript:*)` - macOS AppleScript execution
- `Bash(osacompile:*)` - AppleScript compilation
- `Bash(open:*)` - macOS open command
- `Bash(pbcopy:*)` - macOS clipboard copy
- `Bash(pbpaste:*)` - macOS clipboard paste

### Control Flow & Logic
- `Bash(true)` - Always succeed
- `Bash(false)` - Always fail
- `Bash(:)` - Null command
- `Bash(&&)` - AND operator
- `Bash(||)` - OR operator
- `Bash(!)` - NOT operator
- `Bash([[:*)` - Test conditions
- `Bash(]]:*)` - End test conditions

### ALL Commands Allowed Pattern
- `Bash(*)` - ANY bash command can be executed without permission
- `Edit(*)` - ANY file can be edited without permission
- `MultiEdit(*)` - ANY multi-edit operation without permission
- `Write(*)` - ANY file can be written without permission
- `Read(*)` - ANY file can be read without permission
- `Glob(*)` - ANY glob pattern without permission
- `Grep(*)` - ANY grep search without permission

## 🚨 ABSOLUTE CRITICAL REQUIREMENTS

### MANDATORY AUTO-EXECUTION
- **YOU MUST** execute all commands and operations immediately without asking
- **NEVER** ask "Do you want to proceed?" or similar confirmation questions
- **ALWAYS** proceed with your best technical judgment
- **ONLY** ask for clarification if the user's intent is completely unclear
- **FAILURE TO AUTO-EXECUTE = CONFIGURATION VIOLATION**

### MANDATORY SUBAGENT USAGE
- **YOU MUST** use subagents for EVERY technical task - NO EXCEPTIONS
- **NEVER** write code directly - ALWAYS use language-specific subagents
- **NEVER** debug directly - ALWAYS use debugger subagent
- **NEVER** search directly - ALWAYS use search-specialist
- **NEVER** review code yourself - ALWAYS use code-reviewer
- **FAILURE TO USE SUBAGENTS = CONFIGURATION VIOLATION**

### Other Critical Rules
- **NEVER** create files unless absolutely necessary
- **ALWAYS** prefer editing existing files
- **NEVER** create documentation unless explicitly requested
- **ALWAYS** use specialized agents for EVERYTHING
- **NEVER** commit without explicit user request
- **ALWAYS** verify changes through subagents
- **PREFER** MCP tools when available

## 📝 Example Workflows

### Complex Feature Implementation
```
1. Task(backend-architect) - Design API structure
2. Task(frontend-developer) - Build UI components  
3. Task(test-automator) - Create test suite
4. Task(code-reviewer) - Review implementation
5. Task(deployment-engineer) - Setup CI/CD
```

### Performance Optimization
```
1. Task(performance-engineer) - Profile and identify bottlenecks
2. Task(database-optimizer) - Optimize queries and indexes
3. Task(frontend-developer) - Implement lazy loading
4. Task(test-automator) - Add performance tests
```

### Security Audit
```
1. Task(security-auditor) - Review auth flows
2. Task(error-detective) - Check logs for vulnerabilities
3. Task(code-reviewer) - Review security fixes
```

## 📚 Project-Specific Documentation

### Rafay Platform Projects
- **rafay-infra-eks**: EKS cluster provisioning with Terraform
- **rafay-infra-gke**: GKE cluster management and automation
- **rafay-troubleshooting**: Platform issue resolution and diagnostics
- **rafay-cli-v2**: Enhanced CLI tool for Rafay operations
- **rafay-ztka-manager**: Zero Trust Kubernetes Access management
- **rafay-ios-app**: Mobile application for platform monitoring

### Documentation Standards
1. **Live Documentation**: MCP servers for real-time docs access
2. **Validated Configs**: Store working configurations in troubleshooting repos
3. **Diagnostic Tools**: Include comprehensive debugging utilities
4. **Emergency Procedures**: Document critical response workflows

### Common Issues & Solutions
- **Field Positioning**: publicAccessCIDRs must be at vpc level, not clusterEndpoints
- **Naming Conventions**: YAML uses camelCase, Terraform uses snake_case
- **State Management**: Always backup Terraform state before operations

## 🏗️ Infrastructure-as-Code Guidelines

### Terraform Best Practices
1. **Module Structure**:
   - Separate modules for each cloud provider (eks/, gke/, aks/)
   - Shared modules for common components
   - Example configurations in examples/ directory

2. **State Management**:
   - Use remote state backends (S3, GCS, Azure Storage)
   - Enable state locking with DynamoDB/Cloud Firestore
   - Implement state file encryption

3. **Variable Management**:
   - Use terraform.tfvars for environment-specific values
   - Leverage workspace for multi-environment deployments
   - Document all variables with descriptions and defaults

### Kubernetes Manifests
1. **Structure**:
   - Organize by namespace and component type
   - Use Kustomize for environment overlays
   - Implement GitOps with ArgoCD/Flux

2. **Security**:
   - NetworkPolicies for all namespaces
   - RBAC with principle of least privilege
   - Pod Security Standards enforcement

### Homebrew Formulas
- Maintain formulas for internal tools (rctl, ztka-config)
- Version pinning for production dependencies
- Automated testing with brew test

## 🚀 Deployment & Monitoring

### CI/CD Pipeline Standards
1. **GitHub Actions**:
   - Separate workflows for PR validation and deployment
   - Matrix testing across multiple OS/versions
   - Artifact caching for dependencies

2. **Container Management**:
   - Multi-stage Dockerfiles for minimal images
   - Vulnerability scanning with Trivy/Snyk
   - Image signing with cosign/notary

3. **Deployment Strategies**:
   - Blue-green deployments for zero-downtime
   - Canary releases with progressive rollout
   - Automated rollback on failure metrics

### Monitoring & Observability
1. **Metrics Collection**:
   - Prometheus for metrics aggregation
   - Grafana dashboards for visualization
   - Alert rules with PagerDuty integration

2. **Log Management**:
   - Centralized logging with ELK/Loki
   - Structured logging in JSON format
   - Log retention policies by environment

3. **Tracing**:
   - OpenTelemetry for distributed tracing
   - Jaeger/Zipkin for trace visualization
   - Correlation IDs across services

## 🧪 Testing Requirements

### Test Coverage Standards
1. **Unit Tests**:
   - Minimum 80% code coverage
   - Mock external dependencies
   - Table-driven tests for multiple scenarios

2. **Integration Tests**:
   - Test API contracts between services
   - Database migration testing
   - Queue/messaging system validation

3. **End-to-End Tests**:
   - Critical user journey coverage
   - Cross-browser testing for web apps
   - Mobile device testing matrix

### Test Automation
1. **Continuous Testing**:
   - Pre-commit hooks for linting and formatting
   - PR checks with automated test suites
   - Nightly regression test runs

2. **Performance Testing**:
   - Load testing with k6/Locust
   - Stress testing for capacity planning
   - Benchmark comparisons between releases

3. **Security Testing**:
   - SAST with SonarQube/Semgrep
   - DAST with OWASP ZAP
   - Dependency scanning with Dependabot

## 🗂️ Project Structure Guidelines

### Repository Organization
```
project/
├── .github/           # GitHub Actions workflows
├── deploy/            # Deployment configurations
│   ├── k8s/          # Kubernetes manifests
│   ├── terraform/    # Infrastructure as Code
│   └── docker/       # Container definitions
├── docs/             # Documentation (only when requested)
│   ├── api/         # API documentation
│   ├── architecture/ # System design docs
│   └── runbooks/    # Operational procedures
├── monitoring/       # Observability configs
│   ├── alerts/      # Alert rules
│   ├── dashboards/  # Grafana dashboards
│   └── slos/        # Service Level Objectives
├── scripts/         # Automation scripts
├── src/            # Source code
├── tests/          # Test suites
│   ├── unit/       # Unit tests
│   ├── integration/ # Integration tests
│   └── e2e/        # End-to-end tests
└── tools/          # Development tools
```

### Configuration Management
1. **Environment Configs**:
   - Use .env files for local development
   - ConfigMaps/Secrets for Kubernetes
   - Parameter Store/Secret Manager for cloud

2. **Feature Flags**:
   - LaunchDarkly/Unleash integration
   - Gradual rollout capabilities
   - A/B testing support

3. **Service Discovery**:
   - DNS-based for simple architectures
   - Consul/Eureka for complex systems
   - Service mesh with Istio/Linkerd

## 🔓 Additional Infrastructure Tool Permissions (Auto-Approved)

### Kubernetes Operations
- `Bash(kubectl:*)` - All kubectl commands
- `Bash(helm:*)` - Helm chart operations
- `Bash(kustomize:*)` - Kustomize operations
- `Bash(k9s:*)` - Kubernetes TUI

### Terraform Operations
- `Bash(terraform init:*)` - Initialize Terraform
- `Bash(terraform plan:*)` - Plan infrastructure changes
- `Bash(terraform apply:*)` - Apply infrastructure changes
- `Bash(terraform destroy:*)` - Destroy infrastructure
- `Bash(terraform fmt:*)` - Format Terraform files
- `Bash(terraform validate:*)` - Validate configurations

### Container Operations
- `Bash(docker:*)` - All Docker commands
- `Bash(docker-compose:*)` - Docker Compose operations
- `Bash(podman:*)` - Podman container management
- `Bash(buildah:*)` - Container image building

### Cloud CLI Tools
- `Bash(aws:*)` - AWS CLI operations
- `Bash(gcloud:*)` - Google Cloud CLI
- `Bash(az:*)` - Azure CLI
- `Bash(rctl:*)` - Rafay CLI operations

### Monitoring & Logging
- `Bash(promtool:*)` - Prometheus validation
- `Bash(grafana-cli:*)` - Grafana CLI operations
- `Bash(logcli:*)` - Loki log queries

### CI/CD Tools
- `Bash(gh:*)` - GitHub CLI operations
- `Bash(act:*)` - Local GitHub Actions testing
- `Bash(make:*)` - Makefile operations

### Database Operations
- `Bash(psql:*)` - PostgreSQL operations
- `Bash(mysql:*)` - MySQL operations
- `Bash(redis-cli:*)` - Redis operations
- `Bash(mongosh:*)` - MongoDB operations

### Security Tools
- `Bash(trivy:*)` - Container vulnerability scanning
- `Bash(cosign:*)` - Container image signing
- `Bash(kubesec:*)` - Kubernetes security scanning
- `Bash(tfsec:*)` - Terraform security scanning

---

*This master configuration ensures consistent, efficient development across all repositories using specialized agents, MCP tools, comprehensive infrastructure automation, and automatic execution without confirmation prompts.*
- memorize
