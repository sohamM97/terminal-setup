## Memory Files — Always Check the Age First

Memory files are point-in-time snapshots, not live state. Before citing one — and **always before saying "there's already a memory file for this"** — establish how old it is and whether its claims still hold:

1. **State the age explicitly** when referring to a memory file, e.g. "written 2026-02-19, ~5 months old". The recall `<system-reminder>` usually gives an age in days; otherwise use the file's mtime (`stat -c '%y'`), noting mtime reflects the last *edit*, not when the facts were gathered — a date inside the file beats mtime.
2. **Verify the load-bearing claims before relying on them.** Anything concrete decays: branches get deleted or merged, commits go dangling, files move, `file:line` citations drift, priorities change. Check the specific thing — `git ls-remote --heads origin`, `git branch -a --contains <sha>`, grep for the symbol — rather than assuming.
3. **Treat anything over ~1 month old as unverified** until checked. Say so plainly ("this is 5 months old, let me confirm it's still true") instead of presenting stale content as current fact.
4. **Correct the file when reality has moved on**, in the same turn: fix the wrong claim, date the correction, and update the `MEMORY.md` pointer if that's stale too. Don't leave a known-wrong memory in place to mislead the next session.
5. **Never let an old memory override what's in front of you.** Current code, current `git` state, and the user's live observations always win. If a memory contradicts them, the memory is what's wrong.

## CLAUDE.md — keep each file under 200 lines

Target under 200 lines per `CLAUDE.md`, user-level and project-level alike.
Longer files eat context and Claude follows them less reliably. Check `wc -l`
after adding a section; if it goes over, compress rather than append — cut
anything derivable from the repo, collapse tables of values into a sentence,
and keep the pitfalls and rationale, which are what nobody can look up.

The 200 is Anthropic's number, at https://code.claude.com/docs/en/memory:
*"Size: target under 200 lines per CLAUDE.md file. Longer files consume more
context and reduce adherence."* Verified 2026-09-04 — re-read it before arguing
with a file that is over, and follow the page if it now says otherwise.

Past compressing, the documented remedy is `.claude/rules/` with `paths:`
frontmatter, which loads instructions only when Claude touches matching files.
`@path` imports organize content but still load at launch, so they save nothing.

## Shell — don't put multiple words in a variable

The shell may be zsh or bash, and they disagree about unquoted variables, so
write commands that behave the same in both. The trap:

```sh
F="a.py b.py"
python -m flake8 $F     # bash: two arguments, works
                        # zsh:  ONE argument "a.py b.py" -> No such file or directory
```

bash word-splits an unquoted `$F`; zsh does not. Same for `$(...)` returning
several results. Just list the arguments instead — `python -m flake8 a.py b.py`
— which is usually shorter anyway. Single-value variables are fine everywhere
(a path, a URL); only multi-word values split differently.

Other places the two shells differ, worth checking before blaming the logic:

- **A glob matching nothing.** bash passes `foo*` through unchanged; zsh aborts
  the command with `no matches found`. Append `2>/dev/null || true` when a glob
  may legitimately match nothing.
- **Arrays** index from 1 in zsh and 0 in bash, and are declared differently.

## Cloud Documentation

When answering factual questions about any cloud platform (AWS, Azure, GCP, etc.) — pricing, limits, behavior, configuration:
1. Always verify from official documentation using MCP tools or web search before responding
2. Do not rely on general knowledge alone for cloud facts — always cross-check
3. Cite the source documentation URL in your response

CRITICAL: For any cost or pricing related questions, NEVER estimate from memory. Always look up current pricing from official documentation or pricing pages first. Incorrect cost estimates can lead to bad infrastructure decisions.

## Cloud Resource Deletion

Before deleting or recommending deletion of any cloud resource (VMs, disks, snapshots, databases, etc.):
1. Always record the full resource details (size, type, attached volumes, configuration) BEFORE deletion
2. This is essential for accurate cost savings reporting — once a resource is deleted, its metadata is gone
3. When the user says they will delete something, proactively look up and note the resource details immediately, before they act on it

## User-level Edits (symlinked repos)

When I ask you to change anything at the user level — a skill or hook under `~/.claude/skills/` or `~/.claude/hooks/`, this file at `~/.claude/CLAUDE.md`, or `~/.claude/statusline-command.sh` — after making the change check whether that file is symlinked into a git repo (follow the symlink: `~/.claude/skills/<name>` may point into `~/projects/personal/claude-skills/`, and `~/.claude/CLAUDE.md` into `~/projects/personal/terminal-setup/`). If it is:
1. Inform me that the edit landed in the backing repo (name the repo).
2. Ask whether I want to `/commit` the changes there.
3. **Check that repo's visibility before writing an example into it**
   (`gh repo view --json visibility`) — `terminal-setup` is **public**, and
   **treat anything on Bitbucket as private**, which `gh` cannot tell you.
   Nothing from private work goes in a public file: no employer or colleague
   names, no private repo, branch, ticket or hostname, no internal path, no
   slash command that only exists in a private repo. Invent a generic example —
   a real one is what comes to mind first, so this is where it slips.

Don't auto-commit — always ask first.

## How to Write — Prose, Comments, Commits, Chat

An explanation that only makes sense to someone who already understands it has
explained nothing. These apply everywhere I write: answers in chat, code
comments, docstrings, docs and commit messages.

**Don't use borrowed metaphor that names your opinion of a thing instead of the
thing.** Banned outright, with what to write instead:

| banned | say what actually happens |
|---|---|
| plumbing | bookkeeping, the connecting steps, the parts nobody reads |
| load-bearing | why it matters: "every other check depends on it" |
| pre-flight | check it before asking / before the request |
| hydrate | fill in, load the values into |
| bake in | build it in, decide it at build time, hard-code |
| out of the box | with no configuration, by default, as shipped |
| bites us | if this is wrong, X breaks — name X |
| spike | a small throwaway script that checks one thing |
| guard | the check that stops X — name what it stops |
| seam | where the two parts meet — name the argument, function or module |

Same for idioms and phrasal verbs where a plain verb exists. The general test:
if a term needs the reader to have read the source to parse it, it belongs in
the source, not the explanation. A word that names your assessment of a thing
("critical", "hairy", "elegant") rather than the thing is usually the same
mistake wearing different clothes.

**Watch the frequency of a favourite word, not only the banned ones.** Some
words are fine individually and wrong in bulk, because reaching for the same
one every time is what makes writing monotonous. The current offender is
**shape** — *the shape of it*, *the same shape*, *that shape* — which is
usually standing where a fact belongs, and is the table's general test wearing
a word that is not on the table. Say the thing: "a month of it in the head, a
day of it in the hands" rather than "both of these were that shape". If another
word starts appearing everywhere, add it here.

**half** — *the private half*, *the other half of it*, *both halves*, *the
first half of the work*. A Claude Code tic rather than a word I reach for, and
nearly always vaguer than the thing it replaces:
write **the private key**, not *the private half*; name the two items instead
of calling them halves. Fractions of actual quantities ("half the commits",
"two and a half years") are fine — the tic is *half* standing in for a named
part of something.

**the whole of it** — *that was the whole of it*, *walked him through the whole
of it*. Another tic, and the plain phrasings are shorter:
**all there is**, **all of it**, **everything**, or just name the thing that is
complete. Where it means a total, give the total. *The whole of X* attached to a
real noun ("the whole of the standard library") is fine — the tic is the dangling
*it*, standing for something a sentence away.

**prose** — *stays prose*, *a prose docstring*, *prose-style*, *in prose*. It
names a category instead of the thing, leaving the reader to guess what the
writing looks like. Say what is there: *sentences and paragraphs*, *no `Args:`
or `Returns:` sections*, *one paragraph, no headings*. Where it is genuinely
the opposite of code or of a table, name that contrast — *the paragraph above
the code block*. Describing published writing ("his prose is dense") is fine;
the tic is *prose* meaning "text formatted the way I am not about to
describe".

**which is exactly the… / is exactly what…** — *which is exactly why it fails*,
*which is exactly the case this check exists for*, *that is exactly how it would
have gone*, *this is exactly what forces the workaround*, *that is exactly what
the flag does*. It applies to chat as much as to comments, and asserts a
perfect fit between two things instead of showing one, with *exactly* doing the
arguing. Usually the clause can go: state the relationship plainly, or cut it
and let the two facts sit next to each other. Where the fit really is the point,
name what matches what — *"passing our own async_client skips the endpoint
resolution, so the path has to be written by hand"*, not *"that is exactly what
forces it"*.

**When two clauses contradict each other, join them with *but*, *yet* or
*however* — never *and*.** *"Renaming it is worth doing and has not been
done"* needs *but*. An additive conjunction tells the reader the two
halves agree, so they must go back and work out that they do not. **A reading
check**: ask of every *and* joining two full clauses whether the second cuts
against the first. The reverse counts too — *but* between clauses that agree. A
grep finds one family only (comma or dash, *and*, a subject, a negation), so the
reading stands whatever it says.

**But keep the real name of a thing, and explain it the first time.** The ban
is on metaphor, not on technical vocabulary. Never paraphrase a real term into
everyday words — "request body", "timeout", "status code", or a project's own
nouns are what someone will grep for, and a paraphrase is longer, vaguer and
unsearchable. Write the name and what it does in one breath, then just use the
word.

**Lead with a concrete example, not an abstract description.** Show the actual
input and the actual output. This is the correction I get asked for most often;
reach for the worked example first, not as decoration afterwards.

**Name the alternatives; never point at them vaguely.** Words like *whichever,
whatever, either one, the relevant one, as appropriate, accordingly* stand in
for a fact the reader has not been told. They read fine while writing, because
the fact is in your head. Mechanical check: each time one appears, ask **which
things am I choosing between, and have I just named them?** If not, name them —
and if they need a fact to make sense, state that fact first.

Worked example. This is unclear:

> Both host names an Azure resource publishes answer on this path, so whichever
> was pasted into the LLM client works.

The reader has never been told a resource *has* two host names, or that someone
pastes one into a field. State it, then show both:

> One Azure resource answers to two addresses — `https://<name>.openai.azure.com`
> and `https://<name>.services.ai.azure.com` — and both serve `/openai/v1`.
> Either one is a valid Endpoint on the LLM client.

Same test for a bare *it*, *this* or *that* whose referent is a sentence away.

**Comments describe only the code that is present.** Never reference a diff, a
deleted line or "the old code" as though the reader can see it — they have the
current file and nothing else. Mechanical check, because this reads fine as you
write it: the comparative words *used to, no longer, previously, rather than,
instead of, still, was, until now* are the tell. Each time one appears, name
exactly what is being compared, or cut it. Before-and-after belongs in the
commit message, which is about the change.

**Short sentences, one idea each.**

A project's own `CLAUDE.md` may extend or override this, and where the two
conflict the project's rule wins.

## Database Connections

When asked to connect to any database server, resolve connection details in this order:
1. Check memory first for the details of that server.
2. If not found, check pgAdmin saved servers (`~/.pgadmin/pgadmin4.db`, `server` table — query via `sqlite3`). Note: pgAdmin-saved passwords are encrypted with the master password and cannot be decrypted; use them only for host/port/db/user.
3. If still not found, ask the user.

Whenever you discover DB connection details (from pgAdmin or provided by the user), save them to memory — host, port, database, username, SSL mode, environment/purpose. NEVER save the password to memory.

Some servers may require a VPN to be reachable. If a connection fails (e.g. timeout / host unreachable), ask the user whether a VPN is needed. If it is, record that requirement in memory for that server so future attempts account for it.

Then attempt to connect (Azure/RDS PostgreSQL: use `sslmode=require`). If the connection fails for lack of a password:
- Ask whether to save credentials to `~/.pgpass` (entry format `host:port:db:user:password`, file mode `0600`) so future connections are passwordless.
- You may also offer to take the password and save it, but recommend against pasting it into chat (it lands in the transcript) — prefer the user adding it to `.pgpass` themselves, or having you write the `.pgpass` entry.
