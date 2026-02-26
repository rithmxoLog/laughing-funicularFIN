# Comprehensive Guide: MD Files as Context & Slash Commands in Claude Code

---

## PART 1: MD FILES AND CONTEXT MANAGEMENT

### What Are MD Files?

MD files are **markdown files that Claude reads to understand your project, preferences, and rules**. They persist across sessions, providing continuous context. There are two categories:

1. **CLAUDE.md files** — Instructions and rules **you** write for Claude to follow
2. **Auto memory files** — Notes **Claude** writes for itself as it learns your project

---

### The Complete Memory Hierarchy

Claude discovers and loads memory from multiple locations. **More specific files take precedence over general ones.**

| Location | File | Scope | Purpose |
|----------|------|-------|---------|
| **Managed Policy** | `CLAUDE.md` at OS-level paths | Organization-wide | Company standards, compliance |
| **Project Root** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team (in git) | Project architecture, coding standards |
| **Modular Rules** | `.claude/rules/*.md` | Team (in git) | Topic-specific rules, optionally path-filtered |
| **User Home** | `~/.claude/CLAUDE.md` | Personal (all projects) | Your coding preferences everywhere |
| **Project Local** | `./CLAUDE.local.md` | Personal (one project) | Personal project prefs (auto .gitignored) |
| **Parent Dirs** | `CLAUDE.md` in any parent dir | Inherited | Recursive discovery up to filesystem root |
| **Child Dirs** | `CLAUDE.md` in subdirs | Lazy-loaded | Discovered when Claude reads files in those dirs |
| **Auto Memory** | `~/.claude/projects/<project>/memory/MEMORY.md` | Personal per-project | Claude's own notes on patterns and debugging |

### How Discovery Works

When you start Claude in a directory:

**Phase 1 — Upward Discovery:** Claude walks up from your cwd to filesystem root, collecting every `CLAUDE.md` and `CLAUDE.local.md` it finds. All loaded in full at session start.

**Phase 2 — Downward Discovery (Lazy):** When Claude reads files in subdirectories, it checks if those subdirs have their own `CLAUDE.md`. These load on-demand, not at startup.

**Phase 3 — Auto Memory:** First 200 lines of `MEMORY.md` load at startup. Topic files (e.g., `debugging.md`) load on-demand.

---

### CLAUDE.md — Definition & Purpose

**CLAUDE.md** is a special markdown file Claude reads at the start of every session containing instructions, rules, and context you maintain.

#### What to Include

- Build/run/test commands (`npm test`, `dotnet run`, `ad push`)
- Code style rules that differ from defaults
- Testing conventions and preferred frameworks
- Repository etiquette (branch naming, PR conventions, commit format)
- Architecture decisions and common gotchas
- Deployment commands and environment quirks

#### What NOT to Include

- Things Claude can figure out by reading code
- Standard language conventions Claude already knows
- Long tutorials or file-by-file descriptions
- Self-evident practices ("write clean code")

#### Where to Place It

| File | Who sees it | Use for |
|------|------------|---------|
| `./CLAUDE.md` | Whole team (checked into git) | Project standards |
| `./.claude/CLAUDE.md` | Whole team (alternative location) | Same as above |
| `./CLAUDE.local.md` | Just you (auto .gitignored) | Personal project prefs |
| `~/.claude/CLAUDE.md` | Just you (all projects) | Your global preferences |

#### Importing Other Files

Use `@path/to/file` syntax inside CLAUDE.md to import additional context:

```markdown
# Overview
See @README.md for project overview.
# Deployment
@docs/git-instructions.md
```

- Relative paths resolve relative to the importing file
- Supports recursive imports (max 5 hops)
- Not evaluated inside code blocks

---

### Modular Rules: `.claude/rules/`

For larger projects, split instructions into focused files instead of one monolithic CLAUDE.md:

```
.claude/
├── CLAUDE.md
└── rules/
    ├── code-style.md
    ├── testing.md
    ├── security.md
    └── frontend/
        └── react.md
```

All `.md` files in `.claude/rules/` auto-load with the same priority as `.claude/CLAUDE.md`.

#### Path-Specific Rules (Conditional)

Rules can apply only to certain files using YAML frontmatter:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "backend/**/*.cs"
---

# API Rules
- All endpoints must have input validation
- Use consistent error response format
```

Rules without `paths` apply unconditionally.

---

### Auto Memory — What Claude Writes

**Auto memory** is a persistent directory where **Claude records learnings** as it works.

**What Claude remembers:**
- Build patterns, test commands discovered
- Debugging insights and solutions
- Architecture notes, key files, module relationships
- Your code style and workflow preferences

**Where it's stored:**
- `~/.claude/projects/<project>/memory/MEMORY.md` — Main index (first 200 lines loaded at startup)
- `~/.claude/projects/<project>/memory/{topic}.md` — Detailed topic files (loaded on-demand)

**Managing auto memory:**
- Toggle via `/memory` command
- Toggle via settings: `{ "autoMemoryEnabled": false }` in `~/.claude/settings.json`
- Toggle via env var: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`

**Manually saving:** Just tell Claude: `"Remember that we use pnpm, not npm"`

---

### Project Instructions vs User Instructions vs Auto Memory

| Type | Who writes it | Who sees it | Persists where |
|------|--------------|-------------|----------------|
| **Project CLAUDE.md** | You (team) | Everyone on the team | Git repo |
| **User CLAUDE.md** | You (personal) | Just you | `~/.claude/CLAUDE.md` |
| **CLAUDE.local.md** | You (personal) | Just you, one project | `.gitignored` in project |
| **Auto Memory** | Claude | Just you, one project | `~/.claude/projects/` |

---

## PART 2: SLASH COMMANDS

**Slash commands** are built-in shortcuts you invoke by typing `/` at the prompt. They trigger specific Claude Code functionality rather than prompting Claude with a question.

### Complete Slash Command Reference

| Command | Purpose |
|---------|---------|
| `/clear` | Clear conversation history and reset context |
| `/compact [instructions]` | Compress conversation, optionally focusing on specific topics |
| `/config` | Open settings interface |
| `/context` | Visualize current context window usage |
| `/copy` | Copy last response or code blocks to clipboard |
| `/cost` | Show token usage and cost statistics |
| `/debug [description]` | Troubleshoot session issues |
| `/desktop` | Hand off session to Claude Code Desktop app |
| `/doctor` | Check installation health |
| `/exit` | Exit the session |
| `/export [filename]` | Export conversation to file or clipboard |
| `/help` | Get usage help |
| `/init` | Generate a starter CLAUDE.md by analyzing your codebase |
| `/memory` | Edit CLAUDE.md and auto memory files |
| `/model` | Select or change AI model (with effort level adjustment) |
| `/mcp` | Manage MCP servers and OAuth |
| `/permissions` | View or update tool permissions |
| `/plan` | Enter Plan Mode (exploration only, no code changes) |
| `/rename <name>` | Rename current session |
| `/resume [session]` | Resume a previous conversation |
| `/rewind` | Rewind conversation/code to a previous checkpoint |
| `/stats` | Visualize usage stats, daily usage, streaks |
| `/status` | Show version, model, account info |
| `/statusline` | Configure status line UI |
| `/tasks` | List and manage background tasks |
| `/teleport` | Resume remote web session locally |
| `/theme` | Change color theme |
| `/todos` | List current TODO items |
| `/usage` | Show subscription plan usage and rate limits |
| `/vim` | Toggle Vim-style editing mode |

### Key Commands Explained

**`/memory`** — The primary way to manage your context files. Opens a picker showing all CLAUDE.md files, auto memory, and a toggle for auto memory on/off.

**`/init`** — Analyzes your codebase and generates a starter CLAUDE.md with detected build systems, test frameworks, and patterns. Great for new projects.

**`/compact [focus]`** — Compresses conversation history to free up context. Optionally pass a focus topic: `/compact Focus on the API changes` keeps API context, removes the rest.

**`/clear`** — Resets conversation history completely. Use between unrelated tasks to avoid context pollution.

**`/plan`** — Enters Plan Mode where Claude can explore and analyze but won't make code changes. Great for understanding before acting.

**`/resume`** — Resumes a previous session with full context. Use `/rename` to give sessions memorable names first.

**`/rewind`** — Opens a menu to restore conversation or code to a previous checkpoint. Claude creates checkpoints automatically before making changes.

### Slash Commands vs Skills

| Feature | Slash Commands | Skills |
|---------|---------------|--------|
| **Source** | Built into Claude Code | You create them in `.claude/skills/` |
| **Modifiable** | No | Yes |
| **Invocation** | `/command` | `/skill-name` |
| **Examples** | `/clear`, `/memory`, `/plan` | `/commit`, `/review`, `/security-review` |

---

## PART 3: KEYBOARD SHORTCUTS & QUICK COMMANDS

| Shortcut | Function |
|----------|----------|
| `?` | Show available shortcuts |
| `/` at prompt start | Show slash commands and skills |
| `!` at prompt start | **Bash mode** — run shell commands directly |
| `@` in prompt | File path autocomplete |
| `Ctrl+C` | Cancel input or generation |
| `Ctrl+D` | Exit session |
| `Ctrl+G` | Edit prompt in text editor |
| `Ctrl+L` | Clear screen |
| `Ctrl+O` | Toggle verbose output |
| `Ctrl+V` / `Cmd+V` | Paste image from clipboard |
| `Ctrl+B` | Background running task |
| `Ctrl+T` | Toggle task list |
| `Shift+Tab` / `Alt+M` | Toggle permission modes |
| `Alt+P` | Switch model |
| `Alt+T` | Toggle extended thinking |
| `Esc + Esc` | Open rewind menu |
| `Up/Down arrows` | Navigate command history |

**Bash Mode (`!`):** Run commands directly without Claude interpreting them:

```
! npm test
! git status
! ad push
```

---

## PART 4: BEST PRACTICES

### CLAUDE.md Best Practices

- **Golden Rule:** If Claude would make mistakes without it, keep it. Otherwise, delete it.
- Start with 10-15 key rules, expand only as needed
- If Claude ignores rules, your file is probably too long
- Be specific: `"Use 2-space indentation"` beats `"Format code properly"`
- Treat it like code — check it into git, review changes
- Test your instructions by starting a fresh session

### Memory Organization for Large Projects

Use `.claude/rules/` instead of one monolithic file:

```
.claude/
├── CLAUDE.md              # Core instructions
├── rules/
│   ├── code-style.md
│   ├── testing.md
│   └── api-design.md
└── skills/
    └── deploy/
        └── SKILL.md
```

### Context Management

Context is your **scarcest resource**. Manage it with:
- `/clear` — Reset between unrelated tasks
- `/compact` — Compress when context gets full
- `/rewind` — Go back to a clean state
- Subagents (Task tool) — Offload research to protect your main context

---

## GLOSSARY OF TERMS

| Term | Definition |
|------|-----------|
| **CLAUDE.md** | A markdown file containing instructions for Claude, loaded at session start |
| **Auto Memory** | Persistent notes Claude writes about your project patterns and preferences |
| **Slash Command** | A `/` prefixed built-in command that triggers specific Claude Code functionality |
| **Skill** | A custom user-created command stored in `.claude/skills/` |
| **Context Window** | The total amount of text Claude can "see" at once (conversation + files + memory) |
| **Plan Mode** | A mode where Claude explores and analyzes but doesn't modify code |
| **MCP (Model Context Protocol)** | A protocol for connecting Claude to external tools and services |
| **Session** | A single conversation with Claude, which can be resumed later |
| **Compact** | Compressing conversation history to free up context space |
| **Rewind** | Restoring conversation or code to a previous checkpoint |
| **Lazy Loading** | Loading context only when needed (e.g., child CLAUDE.md files) |
| **Vertical Slices** | Organizing code by feature rather than by technical layer |
| **CQRS** | Command Query Responsibility Segregation — separating read and write operations |
| **Frontmatter** | YAML metadata at the top of a markdown file (between `---` markers) |
| **Glob Pattern** | A wildcard pattern for matching file paths (e.g., `**/*.ts`) |
