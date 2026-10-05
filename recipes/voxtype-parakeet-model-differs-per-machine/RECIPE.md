---
{
  "id": "duff/voxtype-parakeet-model-differs-per-machine",
  "title": "One Voxtype config on machines that need different Parakeet models",
  "summary": "Switch Voxtype to Parakeet and keep the model choice per machine.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "voxtype": "1.1.0"},
  "applies_to": "Every machine with Voxtype dictation, most useful with several machines.",
  "requires": [{"command": "voxtype"}],
  "touches": ["~/.config/voxtype/config.toml", "~/.config/systemd/user/voxtype.service.d/parakeet.conf", "~/.local/share/voxtype/models/<model name>/"],
  "root": false,
  "network": true,
  "installs": ["Parakeet model weights (parakeet-tdt-0.6b-v2-int8)"],
  "runs": ["voxtype.service, through the parakeet.conf drop-in"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# One Voxtype config on machines that need different Parakeet models

## Problem

Omarchy's dictation (Voxtype) uses Whisper `base.en` out of the box. This
setup uses NVIDIA's Parakeet instead, and wants a different size of it on each
machine: the full-precision model on a Dell XPS 16 with plenty of memory, and
the smaller int8 build on a MacBook Air.

The Voxtype config is otherwise the same everywhere (word fixes, typing
speed), so it is synced between machines. Syncing it as one file copies one
machine's model onto the other. Leaving the model line out of the shared copy
caused a worse problem: dictation stopped recording.

## Why it happens

`omarchy-voxtype-install` copies `/usr/share/omarchy/default/voxtype/config.toml`
to `~/.config/voxtype/config.toml`. That file has no `engine` line, so Voxtype
uses Whisper with `[whisper] model = "base.en"`.

The package's `/usr/bin/voxtype` is a symlink to the Whisper build
(`/usr/lib/voxtype/voxtype-avx2`). Parakeet runs only in the ONNX build
(`/usr/lib/voxtype/voxtype-onnx-avx2`). `voxtype setup onnx --enable` swaps
the symlink, but that needs root.

The model is a single `model =` line under `[parakeet]`. Voxtype will not
record without it, and the `voxtype config set parakeet.model ...` command
refuses to load a config that is missing that field, so it cannot be used to
put the line back.

## Fix

### 1. Switch the engine to Parakeet

In `~/.config/voxtype/config.toml`, add `engine` at the top level (next to
`state_file`) and a `[parakeet]` table:

```toml
state_file = "auto"
engine = "parakeet"

# ... stock sections unchanged ...

[parakeet]
model = "parakeet-tdt-0.6b-v2-int8"
on_demand_loading = false
model_type = "tdt"
```

`on_demand_loading = false` keeps the model loaded between dictations instead
of loading it each time you record.

Point the daemon at the ONNX build with a systemd drop-in instead of changing
the symlink. `~/.config/systemd/user/voxtype.service.d/parakeet.conf`:

```ini
[Service]
# The packaged /usr/bin/voxtype symlink is the Whisper binary. Parakeet
# lives in the ONNX build, and switching that symlink needs root.
ExecStart=
ExecStart=/usr/lib/voxtype/voxtype-onnx-avx2 daemon
```

Use `voxtype-onnx-avx512` if your CPU has AVX-512. The `voxtype record
start/stop` commands in Omarchy's F9 bindings still go through
`/usr/bin/voxtype`; they only talk to the daemon, so they work either way.

Download the weights with the ONNX build:

```bash
/usr/lib/voxtype/voxtype-onnx-avx2 setup --download --model parakeet-tdt-0.6b-v2-int8 --no-post-install
```

They land in `~/.local/share/voxtype/models/<model name>/`.
`voxtype info models` lists the Parakeet names. The ones used here:

| Model | Notes |
|---|---|
| `parakeet-tdt-0.6b-v2` | English only, full precision. 2.4 GB on disk; the daemon peaked around 2.3 GB of memory. |
| `parakeet-tdt-0.6b-v2-int8` | Same model, quantized to int8. Smaller; used on the machine with less memory. |
| `parakeet-tdt-0.6b-v3` (and `-int8`) | Voxtype's default Parakeet; adds European languages. |

### 2. Keep the model out of the shared config

If you sync `~/.config/voxtype/config.toml` between machines, strip the
`[parakeet] model` line from the shared copy and keep each machine's model
name in a one-line file of its own (this setup uses
`hosts/<hostname>/voxtype.model` in its dotfiles repo). When the shared config
is copied onto a machine, write that machine's line back right away. Do not
leave it for the end of a long install script: if a step in between fails,
the machine is left with no model and dictation stops working.

Since `voxtype config set` cannot repair the file, write the line directly:

```bash
# snapshot keeps parakeet.model out of the shared config. The voxtype
# CLI will not load a file that is missing that field, so `config set`
# cannot write it back. Put the line in directly.
write_parakeet_model() {
  local file=$1 model=$2 tmp
  tmp=$(mktemp)
  awk -v model="$model" '
    BEGIN { written = 0 }
    /^\[parakeet\]/ {
      in_p = 1
      print
      print "model = \"" model "\""
      written = 1
      next
    }
    in_p && /^model[[:space:]]*=/ { next }
    /^\[/ { in_p = 0 }
    { print }
    END {
      if (!written) {
        print ""
        print "[parakeet]"
        print "model = \"" model "\""
      }
    }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

write_parakeet_model ~/.config/voxtype/config.toml "$(tr -d '[:space:]' < voxtype.model)"
```

It drops any existing `model =` line in `[parakeet]`, writes the new one
directly under the header, and adds the table if it is missing.

## Apply and check

```bash
systemctl --user daemon-reload
systemctl --user restart voxtype
systemctl --user cat voxtype        # the drop-in should be listed
grep -A1 '^\[parakeet\]' ~/.config/voxtype/config.toml
```

Dictate something, then:

```bash
journalctl --user -u voxtype -n 20 -o cat
```

A working Parakeet setup logs a line like `Parakeet Tdt transcription
completed in 0.51s`. `voxtype status` should show `idle` between dictations.

## Undo

To go back to stock, remove the drop-in, delete the `engine` line and the
`[parakeet]` table, and restart the service:

```bash
rm ~/.config/systemd/user/voxtype.service.d/parakeet.conf
systemctl --user daemon-reload
systemctl --user restart voxtype
```

The downloaded model stays in `~/.local/share/voxtype/models/`. Delete its
folder there to get the space back.

## Notes

- Clicking the dictation indicator in Omarchy's bar runs `voxtype configure`,
  which can also pick a model. Whatever it picks is written into
  `~/.config/voxtype/config.toml`, so on a synced setup make sure the model
  line stays out of the shared copy.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
