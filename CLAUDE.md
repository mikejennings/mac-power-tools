# CLAUDE.md - Master Configuration for All Repositories

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
- `Bash(ls:*)` - List directory contents
- `Bash(find:*)` - Find files and directories
- `Bash(cp:*)` - Copy files
- `Bash(mv:*)` - Move/rename files
- `Bash(chmod:*)` - Change file permissions
- `Bash(umask)` - Check file creation mask

### Git Operations
- `Bash(git add:*)` - Stage files
- `Bash(git commit:*)` - Commit changes
- `Bash(git restore:*)` - Restore files
- `Bash(git init:*)` - Initialize repositories

### Search & Analysis
- `Bash(rg:*)` - Ripgrep searches
- `Bash(grep:*)` - Pattern matching
- `Bash(log show:*)` - View logs

### Package Management
- `Bash(brew:*)` - All Homebrew operations
- `Bash(brew upgrade:*)` - Upgrade packages
- `Bash(brew untap:*)` - Remove taps
- `Bash(npx:*)` - Node package execution

### Python & Scripts
- `Bash(python3:*)` - Python 3 execution
- `Bash(/opt/homebrew/bin/python3.11:*)` - Specific Python version
- `Bash(bash:*)` - Bash script execution
- `Bash(./repo-info.sh)` - Repository info script

### Web Operations
- `WebFetch(domain:docs.anthropic.com)` - Anthropic documentation
- `WebFetch(domain:github.com)` - GitHub content
- `WebFetch(domain:www.desktopextensions.com)` - Extension docs

### Testing & Development
- `Bash(test:*)` - Test commands
- `Bash(timeout:*)` - Commands with timeout
- `Bash(for:*)` - For loops
- `Bash(if [ -f "$file" ])` - File existence checks

### System Operations
- `Bash(do echo *)` - Echo commands in loops
- `Bash(then echo *)` - Conditional echoes
- `Bash(else echo *)` - Alternative echoes
- `Bash(fi)` - End if statements
- `Bash(done)` - End loops

### Project-Specific Scripts
- `Bash(SORT_SCRIPT="/Users/mikejennings/src/github/mikejennings/OSshit/scripts/sort-downloads.py")`

## 🚨 ABSOLUTE CRITICAL REQUIREMENTS

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

---

*This master configuration ensures consistent, efficient development across all repositories using specialized agents and MCP tools.*