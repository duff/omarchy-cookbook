# Claude Code changes made on Omarchy never reach my Mac

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Claude Code 2.1.286
**Applies to:** an Omarchy machine plus a Mac (or any machine that does not run your Omarchy config)

## Problem

You tune Claude Code on Omarchy: a status line, a global rule, a shell
wrapper. You also use Claude Code on a Mac. Your Omarchy config repo cannot
just be installed there: the wrapper reads `/proc`, renames Herdr tabs, and
assumes Omarchy's paths and commands. So the Mac falls behind, and months
later you cannot remember what changed.

## Why it happens

The two machines have different configs for good reasons, so syncing files
does not work. What is missing is a list of goals the Mac still has to catch
up on, written so a Claude session on the Mac can do the work in a way that
suits macOS.

## Fix

Give the Mac its own config repo (here `your-org/your-mac-config`). Then add a
section to the rules file your Omarchy config repo's Claude session follows
(a `RULES.md` that its `CLAUDE.md` points to, or the `CLAUDE.md` itself). It
tells Claude to queue each Claude Code change as a GitHub issue in the Mac's
repo:

````markdown
## Queuing Claude changes for the Mac

Omarchy is the reference machine. The Mac never runs anything from this repo. It has its own repo, `your-org/your-mac-config`, and a Claude session there brings the Mac up to date in a way that suits macOS.

When a change affects how Claude Code behaves or looks, ask whether to queue it for the Mac. That covers `claude/` (`CLAUDE.md`, `settings.json`, `statusline.sh`), the `claude()` wrapper in `bashrc`, and Claude hooks, skills, plugins, or keybindings. Per-project memory does not count. Ask after the change works here and is committed, so the entry can cite the commit.

On a yes, write the issue yourself:

```bash
gh issue create -R your-org/your-mac-config --label port-from-omarchy \
  --title "<the goal, e.g. Name Claude sessions after their project>" --body-file -
```

The body describes the goal, not the Omarchy code:

- **Goal:** what the user gets, in a sentence or two.
- **Behavior:** what is observable, including edge cases, so the Mac side can check its version.
- **Omarchy reference:** `your-org/your-omarchy-config@<sha>`, for context only. The Mac should not copy it.
- **Omarchy-only, skip or replace:** anything that exists only here (Herdr, Hyprland, `/proc`, Omarchy commands), with a note on what the Mac equivalent might be.

Always open a new issue, even when the change updates a goal an earlier issue covered. Link the earlier issue in the body. Never add a change as a comment on an existing issue: the Mac may already have closed it, and the Mac only looks at open issues, so the change would never be seen.
````

Why it is written this way:

- **Ask, don't assume.** Some Claude changes are Linux-only. Asking after the
  commit means the issue can cite a commit that exists.
- **Goal and behavior, not code.** The Omarchy commit is context only. The
  Mac session decides how to get the same behavior on macOS, and the
  Behavior section gives it something to check its version against.
- **A new issue every time.** An earlier version said to comment on the open
  issue when a goal changed. That fails once the Mac has closed the issue: the
  comment lands on a closed issue nobody looks at.

On the Mac, a Claude session in the Mac's repo works through the queue:

```bash
gh issue list -R your-org/your-mac-config --label port-from-omarchy --state open
```

## Apply and check

Create the label once (`gh issue create` fails if the label does not exist):

```bash
gh label create port-from-omarchy -R your-org/your-mac-config
```

Then make a small Claude Code change on Omarchy, such as a new line in
`~/.claude/CLAUDE.md`, and commit it. Claude should ask whether to queue it
for the Mac. Say yes and check that a new open issue appears with the label
and the four sections.

## Notes

- `gh` must be logged in with access to the Mac's repo (`gh auth status`).
- Keep the Mac's repo private if the issues will mention your project names or
  paths.
- The same pattern works for any second machine that keeps its own config,
  such as a work laptop. Rename the label to match.
