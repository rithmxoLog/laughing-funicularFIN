# CLAUDE.md Context Trees & Context Switching — A Deep Guide

## What is a CLAUDE.md?

**Definition:** A `CLAUDE.md` is a markdown file that provides persistent instructions to Claude Code. Think of it as a "rules file" — anything you write in it becomes part of Claude's system context for that session. It controls how Claude behaves, what conventions it follows, and what it knows about your project.

---

## Part 1: The CLAUDE.md Tree (Hierarchical Discovery)

### What "Treeing" Means

**Definition:** A CLAUDE.md **tree** is the hierarchical set of CLAUDE.md files that Claude discovers and loads based on directory nesting. Claude walks **upward** from your current working directory to find parent-level files, and discovers **downward** into child directories on demand.

### How Discovery Works

When you launch Claude Code, it performs two discovery passes:

#### Pass 1 — Upward Traversal (loaded at startup)

Claude starts at your **current working directory (cwd)** and walks up through every parent directory, collecting every `CLAUDE.md` it finds:

```
C:\Users\You\projects\my-app\src\features\auth\   ← you are here
C:\Users\You\projects\my-app\src\features\         ← checked
C:\Users\You\projects\my-app\src\                   ← checked
C:\Users\You\projects\my-app\                       ← checked (project root)
C:\Users\You\projects\                               ← checked
C:\Users\You\                                        ← checked
```

**All** of these are loaded into Claude's context immediately when the session starts. More specific (deeper) files take **higher priority** — they override instructions from parent directories.

#### Pass 2 — Downward Discovery (loaded on demand)

Claude also knows about CLAUDE.md files in **subdirectories below** your cwd. These are **not** loaded at startup. Instead, they load **when Claude reads or edits files in that subdirectory**. This is critical for performance — you don't pay the context cost until you actually work in that area.

### The Full Priority Hierarchy

Here is every source of instructions Claude loads, from **highest to lowest priority**:

| Priority | Location | Shared? | When Loaded |
|----------|----------|---------|-------------|
| 1 (highest) | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Yes (git) | Startup |
| 2 | `./CLAUDE.local.md` | No (gitignored) | Startup |
| 3 | `~/.claude/CLAUDE.md` | No (personal) | Startup |
| 4 | `.claude/rules/*.md` | Yes (git) | Startup or on-demand |
| 5 (lowest) | Organization managed policy | Yes (org) | Startup |
| dynamic | `<child-dir>/CLAUDE.md` | Yes (git) | On demand |

**Key definitions:**
- **`CLAUDE.local.md`** — A personal, gitignored version of CLAUDE.md. Use this for preferences only you care about (e.g., "I prefer verbose output", "always use pnpm").
- **`~/.claude/CLAUDE.md`** — A user-level file that applies to **every project** you open with Claude Code. Good for universal preferences.
- **`.claude/rules/*.md`** — Modular rule files (explained in Part 2).

### Example: A Real Tree

```
my-monorepo/
├── CLAUDE.md                          ← "Use TypeScript strict mode everywhere"
├── .claude/
│   └── rules/
│       ├── code-style.md              ← "2-space indent, no semicolons"
│       └── testing.md                 ← "Use vitest, 80% coverage target"
├── packages/
│   ├── frontend/
│   │   ├── CLAUDE.md                  ← "Use React 18, functional components only"
│   │   └── src/
│   │       └── components/
│   │           └── CLAUDE.md          ← "Every component gets its own directory"
│   ├── backend/
│   │   ├── CLAUDE.md                  ← "Use Express, follow REST conventions"
│   │   └── src/
│   │       └── routes/
│   │           └── CLAUDE.md          ← "All routes must validate input with zod"
│   └── shared/
│       └── CLAUDE.md                  ← "No framework-specific imports allowed"
└── docs/
    └── CLAUDE.md                      ← "Write in plain English, no jargon"
```

When Claude works on a file in `packages/frontend/src/components/`, it has **all of these active**:
1. `my-monorepo/CLAUDE.md` (root rules)
2. `.claude/rules/code-style.md` (universal style)
3. `.claude/rules/testing.md` (universal testing)
4. `packages/frontend/CLAUDE.md` (frontend rules — loaded on demand)
5. `packages/frontend/src/components/CLAUDE.md` (component rules — loaded on demand)

When it switches to a file in `packages/backend/src/routes/`, the frontend CLAUDE.md files are **no longer relevant** and the backend ones load instead.

---

## Part 2: Path-Specific Rules (Fine-Grained Context Switching)

### What Are Rules?

**Definition:** Rules are modular `.md` files placed inside `.claude/rules/`. They can apply **universally** or only when Claude is working with files matching a **glob pattern**.

### How Path-Specific Rules Work

Add YAML frontmatter with a `paths` key to scope a rule to specific files:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/routes/**/*.ts"
---

# API Development Rules

- All endpoints must validate input with zod schemas
- Return standardized error format: { error: string, code: number }
- Include OpenAPI JSDoc comments on every handler
```

This rule **only activates** when Claude reads, edits, or creates files matching those glob patterns. When Claude is working on a React component, this rule is invisible.

### Glob Pattern Syntax

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All `.ts` files in any directory |
| `src/**/*` | Everything under `src/` |
| `*.md` | Markdown files in the root only |
| `src/**/*.{ts,tsx}` | `.ts` and `.tsx` files under `src/` |
| `{src,lib}/**/*.ts` | `.ts` files under either `src/` or `lib/` |

### Organizing Rules into Subdirectories

```
.claude/rules/
├── general/
│   ├── code-style.md          ← no paths → always active
│   └── git-workflow.md        ← no paths → always active
├── frontend/
│   ├── react.md               ← paths: ["src/components/**"]
│   └── styles.md              ← paths: ["**/*.css", "**/*.scss"]
├── backend/
│   ├── api.md                 ← paths: ["src/api/**"]
│   └── database.md            ← paths: ["src/db/**", "prisma/**"]
└── testing/
    └── conventions.md         ← paths: ["**/*.test.*", "**/*.spec.*"]
```

The subdirectory names (`frontend/`, `backend/`) are purely organizational — Claude discovers all `.md` files recursively inside `.claude/rules/`.

---

## Part 3: How to Make Claude Switch Context Per Subtask

Claude does **not** automatically switch CLAUDE.md files mid-conversation. You have to architect your setup so that the right context loads at the right time. Here are the four primary methods, from simplest to most powerful:

### Method 1: Directory-Level CLAUDE.md (Automatic, Passive)

**How it works:** Place CLAUDE.md files in subdirectories. When Claude reads or edits files in that directory, the local CLAUDE.md loads automatically.

**When to use:** Monorepos, or any project where different directories have genuinely different conventions.

```
packages/frontend/CLAUDE.md   →  loads when Claude touches frontend files
packages/backend/CLAUDE.md    →  loads when Claude touches backend files
```

**Limitation:** Claude doesn't "unload" a CLAUDE.md once it's in context. If it reads a frontend file and then a backend file, both contexts are active. But the **more specific** one to what it's currently doing takes priority.

### Method 2: Path-Specific Rules (Automatic, Targeted)

**How it works:** Rules in `.claude/rules/` with `paths` frontmatter only activate for matching files.

**When to use:** When different file types need different conventions (e.g., test files vs. source files, CSS vs. TypeScript).

This is the **most precise** automatic method — it fires based on exactly which files Claude is touching.

### Method 3: Subagents via the Task Tool (Explicit, Isolated)

**Definition:** A **subagent** is a separate Claude instance spawned by the Task tool. It gets its own context window, its own system prompt, and can have restricted tool access. It runs independently, returns a result, and its internal context is then discarded.

**How it works for context switching:** When you ask Claude to do subtask A (frontend) and subtask B (backend), you can instruct it to delegate each to a different subagent. Each subagent inherits the CLAUDE.md tree from the parent but can also receive a **completely different prompt** that scopes its behavior.

**Example — in your root CLAUDE.md:**

```markdown
# Task Delegation

When working on multiple subsystems, delegate to subagents:
- For frontend tasks, use the Task tool with this prompt prefix:
  "You are a frontend specialist. Follow React 18 patterns..."
- For backend tasks, use the Task tool with this prompt prefix:
  "You are a backend specialist. Follow Express REST patterns..."
- For database tasks, use the Task tool with this prompt prefix:
  "You are a database specialist. Use Prisma conventions..."
```

**What actually happens:**

```
Main Claude session
├── Task: "Build the login form" → subagent with frontend prompt
│   └── Has its own context window, works in packages/frontend/
├── Task: "Build the auth API" → subagent with backend prompt
│   └── Has its own context window, works in packages/backend/
└── Task: "Add user table migration" → subagent with database prompt
    └── Has its own context window, works in prisma/
```

Each subagent:
- **Inherits** the parent's CLAUDE.md tree
- Gets its own **task-specific prompt** (the `prompt` parameter)
- Has its own **isolated context window** (won't pollute the main conversation)
- Can use a **different model** (e.g., `haiku` for simple tasks, `opus` for complex ones)
- Can run in **parallel** with other subagents

**This is the most powerful method for true context switching.** The subagent's context is completely separate from the main session.

### Method 4: The `@import` System (Composable Context)

**Definition:** The `@path` syntax inside a CLAUDE.md file pulls in the contents of another file, letting you compose contexts from reusable building blocks.

```markdown
# packages/frontend/CLAUDE.md

@../../docs/typescript-conventions.md
@../../docs/react-patterns.md
@../../docs/testing-strategy.md

# Frontend-specific overrides
- Use Tailwind for styling
- Components go in src/components/<Name>/<Name>.tsx
```

```markdown
# packages/backend/CLAUDE.md

@../../docs/typescript-conventions.md
@../../docs/api-conventions.md
@../../docs/testing-strategy.md

# Backend-specific overrides
- Use Express router pattern
- Routes go in src/routes/<resource>.ts
```

Both share `typescript-conventions.md` and `testing-strategy.md`, but diverge on their domain-specific imports. This gives you **composable, DRY context trees**.

**Import rules:**
- Relative paths resolve from the **importing file's location**, not cwd
- Imports can be nested up to **5 levels deep**
- Imports inside markdown code blocks (`` ` `` or `` ``` ``) are ignored
- First use of external imports triggers an approval dialog

---

## Part 4: Putting It All Together — A Complete Setup

Here is a production-grade CLAUDE.md tree for a full-stack monorepo:

```
my-app/
├── CLAUDE.md                              ← global rules
├── CLAUDE.local.md                        ← your personal prefs (gitignored)
├── .claude/
│   └── rules/
│       ├── code-style.md                  ← universal (no paths)
│       ├── commit-conventions.md          ← universal (no paths)
│       ├── react-components.md            ← paths: ["src/client/**/*.tsx"]
│       ├── api-endpoints.md               ← paths: ["src/server/routes/**"]
│       ├── database.md                    ← paths: ["prisma/**", "src/server/db/**"]
│       └── test-conventions.md            ← paths: ["**/*.test.*"]
├── docs/
│   ├── architecture.md                    ← imported by root CLAUDE.md
│   └── api-spec.md                        ← imported by api-endpoints rule
├── src/
│   ├── client/
│   │   └── CLAUDE.md                      ← "This is the React frontend..."
│   └── server/
│       └── CLAUDE.md                      ← "This is the Express backend..."
└── prisma/
    └── CLAUDE.md                          ← "Database schema and migrations..."
```

**Root `CLAUDE.md`:**

```markdown
# My App

Full-stack TypeScript application.

@docs/architecture.md

## Global Rules
- TypeScript strict mode
- No `any` types
- All functions must have explicit return types

## Task Delegation
When I ask you to work on both frontend and backend in the same request,
use separate subagents for each:
- Frontend subagent: work in src/client/
- Backend subagent: work in src/server/
Run them in parallel when they are independent.
```

With this setup:
- **Path-specific rules** automatically activate based on what files Claude touches
- **Directory CLAUDE.md files** load on demand as Claude enters subdirectories
- **Subagent delegation** is instructed in the root CLAUDE.md, so Claude knows to split cross-cutting work
- **Imports** pull in architectural docs without bloating the CLAUDE.md itself

---

## Part 5: Key Concepts Summary

| Concept | Definition |
|---------|-----------|
| **CLAUDE.md** | A persistent instruction file that becomes part of Claude's system context |
| **Tree** | The hierarchical set of CLAUDE.md files discovered via upward and downward directory traversal |
| **Priority** | More specific (deeper nested) files override broader (parent) files |
| **On-demand loading** | Child directory CLAUDE.md files load only when Claude works with files in that directory |
| **Path-specific rules** | `.claude/rules/*.md` files with `paths` frontmatter that activate only for matching file globs |
| **Subagent** | An isolated Claude instance (via Task tool) with its own context window and prompt |
| **Context switching** | Achieved through directory scoping, path rules, subagent delegation, or imports — not automatic |
| **`@import`** | Syntax for pulling another file's contents into a CLAUDE.md, enabling composable/DRY instructions |
| **`CLAUDE.local.md`** | A gitignored personal variant for preferences not shared with the team |
| **Auto memory** | Claude's persistent learning files at `~/.claude/projects/<project>/memory/` — supplements CLAUDE.md |

The core principle: **structure your directories and rules so that the right instructions load at the right time, and use subagents when you need truly isolated context per subtask.**
