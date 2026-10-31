# Neovim's autocomplete gets in the way when writing prose

## Problem

Writing notes, Markdown, or a commit message in Omarchy's Neovim, a
completion menu keeps popping up under the cursor with words from your open
files. Gray text also appears after the cursor, previewing the word it would
fill in. Neither helps with prose, and both pull your eye away from what
you're writing.

## Why it happens

Omarchy's Neovim is LazyVim (the `omarchy-nvim` package sets it up), and
LazyVim completes with blink.cmp. Two of its settings do this:

- blink.cmp shows its menu on its own as you type (`completion.menu.auto_show
  = true` by default), and LazyVim includes the `buffer` source, which
  offers words from open buffers. In code a language server fills the menu
  with useful items; in prose there's no language server, so it's only
  those words.
- LazyVim turns blink's ghost text on: in
  `lazyvim/plugins/extras/coding/blink.lua` it sets `ghost_text = { enabled =
  vim.g.ai_cmp }`, and `vim.g.ai_cmp` is `true` by default. That's the gray
  preview, and it shows even where the menu doesn't.

## Fix

Two small plugin specs, which lazy.nvim merges into LazyVim's blink.cmp
settings.

`~/.config/nvim/lua/plugins/completion-quiet-in-text.lua` keeps the menu from
popping up in prose:

```lua
-- In prose there's no language server, so the completion menu only offers
-- words from open buffers. Don't pop it up while typing there; Ctrl-Space
-- still opens it.
local prose = { [""] = true, text = true, markdown = true, gitcommit = true }

return {
	"saghen/blink.cmp",
	opts = {
		completion = {
			menu = {
				auto_show = function()
					return not prose[vim.bo.filetype]
				end,
			},
		},
	},
}
```

`~/.config/nvim/lua/plugins/completion-no-ghost-text.lua` turns off the gray
preview everywhere:

```lua
-- No gray preview of the suggested completion after the cursor. The menu
-- still offers the same words, and Ctrl-Space opens it anywhere.
return {
	"saghen/blink.cmp",
	opts = {
		completion = {
			ghost_text = { enabled = false },
		},
	},
}
```

- `auto_show` takes a function, checked each time the menu would open, so
  the menu still pops up in code and stays down in the listed filetypes.
  `""` covers a new buffer that has no filetype yet. Add any others you write
  prose in, such as `rst` or `org`.
- Ctrl-Space (LazyVim's key for showing completion) still opens the menu in
  prose when you want it.
- To keep the gray preview in code and drop it only in prose, give
  `ghost_text.enabled` a function too:
  `enabled = function() return not prose[vim.bo.filetype] end`.

## Apply and check

Restart Neovim (`:qa`, then open it again). Then:

- Open a Markdown file and type a paragraph: no menu pops up, and no gray text
  follows the cursor. Ctrl-Space opens the menu.
- Open a code file with a language server and type: the menu pops up as
  before, without the gray preview.

## Undo

Delete the two files and restart Neovim:

```bash
rm ~/.config/nvim/lua/plugins/completion-quiet-in-text.lua
rm ~/.config/nvim/lua/plugins/completion-no-ghost-text.lua
```

## Notes

- Ghost text in the command line (`:`) is a separate setting,
  `cmdline.completion.ghost_text`, which LazyVim also turns on. This recipe
  leaves it alone.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/neovim-autocomplete-gets-in-the-way-of-prose",
  "title": "Neovim's autocomplete gets in the way when writing prose",
  "summary": "Keep blink.cmp's menu from popping up in text, Markdown and commit messages, and turn off its gray preview.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "neovim": "0.12.6", "lazyvim": "16.0.0", "blink.cmp": "1.10.2"},
  "applies_to": "Omarchy's Neovim (LazyVim with blink.cmp).",
  "requires": [{"command": "nvim"}],
  "touches": ["~/.config/nvim/lua/plugins/completion-quiet-in-text.lua", "~/.config/nvim/lua/plugins/completion-no-ghost-text.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
