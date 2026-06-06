# LTMA — LivingTreeMoonBitAgent

MoonBit AI Agent framework inspired by Microsoft MAF pipeline architecture.

## Project Structure

```
moon.mod — module livingtree/ltma, preferred_target = native
moon.pkg — root package, re-exports core sub-packages
cmd/ltma/ — CLI entry (is-main), run via `moon run cmd/ltma`
├── main.mbt      — demo pipeline: EchoAgent → ChatAgent → Workflow
├── args.mbt      — CLI argument parser (stub)
└── echo_agent.mbt — EchoAgent demo

core/         — AgentId, AgentHandle, Message, AgentStatus (all structs + factory fns)
pipeline/     — HostAdapter, LifecycleManager
host/         — AgentHost (register → activate → call → shutdown), AgentCatalog, EventBus
agent/        — AgentBase, create_metadata
agents/       — ChatAgent (LLM + ToolRegistry, closure-based state via `let mut`)
llm/          — LLMProviderHandle, ChatMessage, LLMConfig, DeepSeekProvider (stub)
tool/         — ToolRegistry + builtin/ (echo, greet)
http/         — MockHttpClient (HTTP abstraction, no external deps)
orchestration/ — Workflow + HandoffDef + StepDef (struct-based)
```

## MoonBit Language Quirks (moonc v0.9.3)

These are hard-earned rules from actual compilation errors:

- **No `use` keyword** — reserved for future. Use `@package.TypeName` for cross-package types.
- **No trait objects** — traits cannot be used as types/struct fields. Use closure-based handles instead (`AgentHandle`, `LLMProviderHandle`).
- **`impl Trait for Type` is unstable** — prefer closures over trait implementations.
- **Structs & enum variants are read-only across packages** — can't construct `@pkg.Type::{field: val}` or `@pkg.Type::Variant`. Always expose `fn Type::create(...)` factories in the defining package.
- **`fn meth(self: T, ...)` is deprecated** — use `fn T::meth(self, ...)`.
- **`fn f[T]` is deprecated** — use `fn[ T] f`.
- **`-> T!` is deprecated** — just use `-> T`; call functions without `!` suffix.
- **`init` is reserved** — don't use it as a method name (no-arg constructor hook).
- **Struct fields are newline-separated** — no commas in `struct { a : Int \n b : String }`.
- **Deprecated APIs to avoid**: `Map::new()` → `Map([])`, `.or()` → `.unwrap_or()`, `.size()` → `.length()`, `.is_some()` → `x is Some(_)`.
- **`String::to_chars()` etc. may not exist** — prefer simple string construction over complex manipulation.

## Commands

```sh
moon check --target native   # type-check (primary verification — no C compiler needed)
moon fmt                     # format code
moon info                    # update .mbti interface files
moon run cmd/ltma            # run CLI (needs MSVC environment)
moon test                    # run tests

## Moon IDE — semantic code navigation (prefer over grep)

moon ide doc '<query>'       # discover APIs, types, packages
  # '' => list all packages; "@pkg" => explore package exports
  # "Type::method" => find type methods; "*glob*" => glob match
moon ide peek-def <symbol>   # view definition with context
  # --loc file:line[:col] => resolve ambiguous symbols
moon ide find-references     # find all usages of a symbol
moon ide outline <dir|file>  # structural overview of package/file

## C Compiler Setup (Windows)

Two options, both installed on this system:

### Option A: MSVC (recommended for full builds with async deps)

MSVC at `cl.exe` in VS 2022 Community. Each new terminal run once:

```pwsh
# Run the official VS setup script
"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

Or set paths manually:
```pwsh
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;$env:PATH"
$env:INCLUDE = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\include;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\ucrt;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\um;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\shared"
$env:LIB = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"
```

### Option B: MinGW-w64 (general C compilation)

Path: `C:\ProgramData\mingw64\mingw64\bin\gcc.exe`  
Version: 15.2.0 (x86_64-posix-seh-rev0)

```pwsh
$env:PATH = "C:\ProgramData\mingw64\mingw64\bin;$env:PATH"
```

Note: `moonbitlang/async` dependency only supports MSVC on Windows. For packages without async deps, MinGW works fine.
```

**Final step**: always run `moon info && moon fmt` before finishing. Check `.mbti` diffs for unexpected API changes.

## Architecture

MAF-inspired 5-layer pipeline:

```
Host App → AgentHost → HostAdapter → [AgentHandle] → Agent
```

- **AgentHandle** (closure struct in `core/contract.mbt`) — central abstraction, replaces trait objects.
- **Factory fn pattern** — all shared types expose `Type::create(...)` in their own package; consumers call `@pkg.Type::create(...)`.
- **Mutable state in closures** — use `let mut` in the outer scope captured by closures (see `agents/chat_agent.mbt`).
- **Tests**: whitebox (`_wbtest.mbt`) has access to package internals; inline `test "name" { ... }` anywhere.

## External Sources

- Package search API: `https://mooncakes.io/api/v0/modules`
- MoonBit docs: `https://docs.moonbitlang.com`
- MoonBit blog: `https://www.moonbitlang.cn/blog`
- **MoonBit Agent Skill** (installed locally): `.opencode/skills/moonbit/moonbit-agent-guide/SKILL.md`

## Dependencies (added, cached locally)

- `mizchi/tui@0.10.0` — TUI framework with virtual DOM, Flexbox/Grid layout, reactive signals
- `mizchi/signals@0.6.4` — Reactive signals for UI state
- `mizchi/crater-core@0.18.0` — Layout engine used by tui
- `moonbitlang/async@0.19.2` — Async runtime (HTTP, sockets, filesystem)

### Async IO Patterns

Key facts from official MoonBit Agent Guide:
- **Entry point**: `async fn main { ... }` (not `fn main`)
- **Structured concurrency**: `@async.with_task_group(group => { group.spawn_bg(() => { ... }) })`
- **Async implies raising**: `async fn` already has raising effect — do NOT add `raise`
- **No `await` keyword**: Call async functions normally, no `await` or `!` suffix
- **Native target required**: `moonbitlang/async` only supports MSVC on Windows

Usage in llm/ package:
```moonbit
///| llm/deepseek.mbt
pub async fn call_deepseek_api(config, messages) -> String {
  let (resp, data) = @async_http.post(url, body, headers=headers)
  data.text()  // &Data has .text() method via Data trait
}
```

### TUI Key API

The `tui/` package wraps `mizchi/tui`. Key functions:
- `@vnode.run_vnode_app(w, h, render_fn, output_fn)` → `stop_fn` — run interactive TUI
- `@vnode.render_vnode_once(w, h, node)` → `String` — render once (used in demo)
- `@vnode.column(...children)` / `@vnode.text(content, fg?, bold?)` — layout primitives
- `@miztui.get_terminal_size()` → `(Int, Int)`
