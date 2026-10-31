# No way to print from Neovim, and printed lines break mid-word

## Problem

Neovim has no print command, so printing a note or a text file means leaving
the editor. Sending it with `lp` from a terminal works, but any line longer
than the page is wide gets cut at the right edge in the middle of a word, and
the rest of the word starts the next line. Paragraphs written as one long line
each, as in Markdown, come out full of broken words.

## Why it happens

- Neovim removed Vim's `:hardcopy` in 0.9 (`:help nvim-removed`), and
  Omarchy's Neovim (LazyVim, from the `omarchy-nvim` package) adds nothing in
  its place.
- `lp file.txt` sends plain text to CUPS, which turns it into a PDF with the
  `texttopdf` filter (`/usr/lib/cups/filter/texttopdf`, from cups-filters).
  The filter prints 10 characters to the inch and starts a new line when it
  reaches the right margin, wherever that falls. On Letter paper that's
  about 80 characters. It never looks for a space.
- The filter's margin options (`-o page-left=` and `-o page-right=`) made no
  difference in testing with cups-filters 2.0.1, so the page width can't be
  widened to hold longer lines either.

## Fix

Wrap the lines in Neovim before handing them to `lp`, and bind it to a key.

1. Save [`files/print.lua`](files/print.lua) as
   `~/.config/nvim/lua/config/print.lua`. Its `buffer()` function:
   - expands tabs to spaces, using the buffer's `tabstop`;
   - breaks each line longer than 80 characters at the last space that fits;
   - indents the continuation like the line it came from. On a list item
     (`-`, `*`, `+`, `1.` or `1)`), it lines up under the item's text rather
     than its marker;
   - breaks mid-word only when a single word is longer than the whole line;
   - pipes the result to `lp -t <file name>`, so the job is named after the
     file, and shows lp's reply (`request id is ...`) or its error as a
     notification.

   The file in the buffer isn't changed. Only the printed copy is wrapped.

2. Add a key to `~/.config/nvim/lua/config/keymaps.lua`:

   ```lua
   -- Prints to the default printer, wrapped at words, and shows lp's request
   -- id, or its error.
   vim.keymap.set("n", "<leader>p", function()
     vim.cmd.write()
     require("config.print").buffer()
   end, { desc = "Save and Print" })
   ```

   It saves first, so what prints matches the file on disk.

What's specific to one machine:

- `local width = 80` at the top of `print.lua` fits Letter paper with
  quarter-inch margins. Use about 77 for A4, or fewer if your printer's
  margins are wider. A test page with a long line of digits shows where the
  filter breaks.
- `<leader>` is Space in stock LazyVim, so the key is Space then p. It was
  written with a comma leader (`vim.g.mapleader = ","`), where it's ,p. If you
  use LazyVim's yanky extra, it already has `<leader>p` for yank history, so
  pick another key.
- It prints to the default printer (`lpstat -d`). To pick one, add
  `"-d", "<printer>"` to the `lp` command in `print.lua`.

## Apply and check

Restart Neovim. Then check that a printer is the default:

```bash
lpstat -d
```

Open a file with a long line, press `<leader>p`, and look for a "request id
is ..." notification. The printout should break lines only between words.

To check the wrapping without paper, run the same wrap from the command line
and look at the widths:

```bash
nvim --headless +'lua local p = require("config.print"); vim.fn.system = function(_, l) io.write(table.concat(l, "\n"), "\n"); return "" end; p.buffer()' +qa somefile.md
```

## Undo

Delete `~/.config/nvim/lua/config/print.lua` and the `<leader>p` mapping from
`~/.config/nvim/lua/config/keymaps.lua`, then restart Neovim. Nothing else was
installed or changed.

## Notes

- Printing Markdown this way prints the source text, `#` and `**` included.
  For formatted output, render it to PDF or HTML first and print that.
- `:TOhtml`, which `:help nvim-removed` suggests, keeps syntax colors, but
  then needs a browser to print, and colors from a dark theme print poorly.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/neovim-cannot-print-or-printouts-break-words",
  "title": "No way to print from Neovim, and printed lines break mid-word",
  "summary": "Save and print the current file on a key, with long lines wrapped at words before lp gets them.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "neovim": "0.12.6", "cups": "2.4.20", "cups-filters": "2.0.1"},
  "applies_to": "Omarchy's Neovim, with a printer set up in CUPS.",
  "requires": [{"command": "nvim"}, {"command": "lp"}],
  "touches": ["~/.config/nvim/lua/config/print.lua", "~/.config/nvim/lua/config/keymaps.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
