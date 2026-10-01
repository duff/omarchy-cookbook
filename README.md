# omarchy-recipes

Fixes and tweaks for [Omarchy](https://omarchy.org/), one problem per recipe.
Each recipe says what stock Omarchy does, why, the change that fixes it, and
how to check that it worked. They come from one person's daily setup on a Dell
XPS 16 with Apple Studio Displays and a MacBook Air.

Every recipe was tested on **Omarchy 4.0.4 and Hyprland 0.56.2**, where the
Hyprland config is Lua (`~/.config/hypr/*.lua`). Older advice written for
`hyprland.conf` will not work as-is. If your versions differ, check the stock
files under `/usr/share/omarchy/` before applying a recipe.

All changes go in `~/.config/`. None edit `/usr/share/omarchy/`, which
`omarchy update` replaces.

## Mouse, touchpad, and keyboard

- [Scrolling direction feels backwards on the touchpad and mouse](recipes/scrolling-direction-feels-backwards.md): turn on natural scrolling for both; Hyprland has separate switches.
- [Moving the mouse steals keyboard focus](recipes/hovering-mouse-steals-keyboard-focus.md): click to focus, while hover still scrolls.
- [A light palm tap on the touchpad clicks things](recipes/touchpad-palm-tap-clicks-things.md): turn off tap-to-click.
- [Gaming mouse moves the cursor too fast to place it precisely](recipes/gaming-mouse-cursor-too-fast.md): a per-device acceleration curve, precise when slow and far on a flick.
- [MacBook T2 trackpad moves the cursor while typing](recipes/macbook-t2-trackpad-moves-cursor-while-typing.md): mark the pad internal, plus a small daemon that pauses it after each key.
- [Make Caps Lock Escape on tap and hjkl arrows on hold](recipes/caps-lock-as-escape-and-hjkl-arrows.md): with keyd.
- [Swap Alt and Super on the laptop keyboard only](recipes/swap-alt-and-super-on-laptop-keyboard-only.md): per-device keyd config that leaves an external keyboard alone.
- [Super+J shows a Lua error on a scrolling-layout workspace](recipes/super-j-error-on-scrolling-layout.md): only toggle the split on dwindle.

## Compose key and dictation

- [Putting Compose on Right Alt breaks Right Alt as a modifier](recipes/right-alt-compose-key-loses-alt-modifier.md): tap for Compose, hold for Alt.
- [A Compose sequence types the wrong emoji, or one is missing](recipes/compose-sequence-types-the-wrong-emoji.md): override or add sequences in `~/.XCompose`.
- [A Compose snippet with a line break comes out scrambled in Chrome](recipes/compose-snippet-with-line-break-scrambled-in-chrome.md): commit a placeholder and type the lines with an fcitx5 add-on.
- [One Voxtype config on machines that need different Parakeet models](recipes/voxtype-parakeet-model-differs-per-machine.md): switch to Parakeet and keep the model choice per machine.
- [Voxtype keeps mishearing the same word](recipes/voxtype-mishears-the-same-word.md): `[text.replacements]`, and where to find what it actually heard.
- [Dictation keeps recording after letting go of push-to-talk](recipes/dictation-keeps-recording-after-releasing-push-to-talk.md): rebind both ends to ignore modifiers.
- [Dictated text types out slowly](recipes/voxtype-dictation-types-slowly.md): set the typing delay to zero.
- [Dictation went into the wrong field](recipes/dictation-typed-into-the-wrong-field.md): Super+D retypes the last dictation into the focused field.

## Apps, web apps, and links

- [A launcher shortcut opens a second window instead of focusing the open one](recipes/launcher-shortcut-opens-a-second-window.md): why stock focus misses some apps, and how to fix shortcuts and launcher entries.
- [Two web app windows for the same site share a login or get mixed up](recipes/two-web-app-windows-for-the-same-site-get-mixed-up.md): separate profiles for two accounts, and telling production from a local copy.
- [A web app opens every link in a new window, or sends links to a browser tab](recipes/web-app-opens-links-in-new-windows-or-browser-tabs.md): use a regular window, or an installed Chrome app.
- [mailto: links open in Chrome instead of HEY](recipes/mailto-links-open-in-chrome-instead-of-hey.md): put HEY back as the handler and keep it there after updates.
- [No shortcut to open a typed or pasted URL](recipes/no-shortcut-to-open-a-typed-or-pasted-url.md): Super+U opens an address or searches the web.
- [Desktop shortcuts appear in the home folder](recipes/desktop-shortcuts-appear-in-home-folder.md): give them a real `~/Desktop`.
- [Chrome shows a privacy warning on a local Caddy HTTPS site](recipes/chrome-privacy-warning-on-local-caddy-https-site.md): add Caddy's root certificate to Chrome's own store.
- [Wine app is tiny, blurry, or draws hair-thin lines on a HiDPI screen](recipes/wine-app-blurry-or-thin-lines-on-hidpi.md): draw at 96 DPI and let Hyprland double it.
- [Wine app quits on Super+W, or pops back up after hiding it](recipes/wine-app-quits-on-super-w-or-pops-back-up-when-hidden.md): show and hide an all-day app with one key.

## Displays and workspaces

- [HiDPI screens are left on auto scale instead of a fixed 2x](recipes/hidpi-screens-left-on-auto-scale.md): pin the scale.
- [Monitors swap left and right when the cables change ports](recipes/monitors-swap-sides-when-cables-change-ports.md): pin each screen by make, model, and serial.
- [Workspaces open on unpredictable monitors](recipes/workspaces-open-on-the-wrong-monitor.md): give each monitor its own block of workspace numbers.
- [Super+Slash made everything bigger, and it stays that way](recipes/super-slash-made-everything-bigger.md): what the shortcut changes and how to undo it.
- [Hard to see which window is focused](recipes/hard-to-see-which-window-is-focused.md): wider borders.
- [Super+Shift+arrow only swaps windows](recipes/super-shift-arrow-only-swaps-windows.md): move a window into its neighbor's split.

## Laptop, power, network, and audio

- [Laptop screen stays black after undocking with the lid shut and sleeping](recipes/laptop-screen-stays-black-after-undocked-sleep.md): keep the panel off while closed and restore it on wake.
- [Laptop used as a headless server sleeps when the lid is shut](recipes/laptop-server-sleeps-when-lid-is-shut.md): ignore the lid and allow only key logins over SSH.
- [Laptop Wi-Fi falls back to slow 2.4 GHz with the lid shut](recipes/laptop-wifi-falls-back-to-2-4-ghz-with-lid-shut.md): WPA3 and a pinned 5 GHz band.
- [Screensaver starts too soon while reading](recipes/screensaver-starts-too-soon.md): longer idle timers.
- [Wrong default microphone records silence when docked](recipes/wrong-default-microphone-records-silence.md): WirePlumber priorities.
- [ErgoDox EZ cannot be flashed or trained from Oryx](recipes/ergodox-ez-cannot-be-flashed-from-oryx.md): udev rules and the plugdev group.

## Bar, notifications, menus, and terminals

- [Bar clock shows 24-hour time](recipes/bar-clock-shows-24-hour-time.md): switch to 12-hour.
- [Battery percentage not shown in the bar](recipes/battery-percentage-not-shown-in-the-bar.md): show it next to the icon.
- [Tailscale is missing from the bar, or a widget you don't use is on it](recipes/tailscale-missing-from-the-bar.md): enable, disable, or add bar widgets.
- [Bar and menu text too small](recipes/bar-and-menu-text-too-small.md): enlarge the shell font without changing terminals.
- [Reminder notification disappears after 5 seconds](recipes/reminder-disappears-after-5-seconds.md): keep reminders up until dismissed.
- [Reboot from the menu, or Ctrl+Alt+Delete, closes everything without asking](recipes/reboot-and-close-all-windows-without-asking.md): add confirmations.
- [No Print Screen key for screenshots](recipes/no-print-screen-key-for-screenshots.md): put a screenshot tool on Super+Shift+S and in the Capture menu.
- [Ctrl+Enter toggles fullscreen in Ghostty](recipes/ctrl-enter-toggles-fullscreen-in-ghostty.md): pass the key through to apps.

## Agents and terminal multiplexing

- [Clicking "Process crashed" starts an agent that may change files without asking](recipes/crash-notification-agent-changes-files-without-asking.md): open the crash diagnosis in plan mode.
- [Herdr closes a workspace, pane, or tab without asking](recipes/herdr-closes-workspace-pane-or-tab-without-asking.md): bring back the confirmation.
- [Herdr's agent list keeps reordering itself](recipes/herdr-agent-list-keeps-reordering.md): group by workspace.
- [Herdr has no shortcut to jump between agents](recipes/herdr-no-shortcut-to-jump-between-agents.md): Alt+Up and Alt+Down.
- [Herdr tab names don't show which tab is running an agent](recipes/herdr-tab-names-do-not-show-which-tab-runs-an-agent.md): rename the tab while the agent runs.

## Claude Code

- [Claude Code's status line doesn't show the project or whether git is clean](recipes/claude-status-line-does-not-show-project-or-git-state.md): model, effort, project, and a git check or cross.
- [Claude sessions can't be reached from my phone, or all look alike there](recipes/claude-sessions-look-alike-in-remote-control.md): Remote Control at startup, with each session named after its project.
- [Claude Code keeps asking "How is Claude doing?"](recipes/claude-feedback-survey-interrupts-sessions.md): turn off the feedback survey.
- [Claude Code adds "Co-Authored-By: Claude" to my commits](recipes/claude-adds-co-authored-by-to-commits.md): turn off attribution.
- [Claude Code commits but doesn't push, or asks whether to push](recipes/claude-asks-whether-to-push-after-committing.md): make them one step.
- [A prompt typed into the wrong Claude session changes the wrong project](recipes/prompt-typed-into-the-wrong-claude-session.md): have Claude stop and ask.
- [Claude Code settings and rules don't follow me to my other machines](recipes/claude-code-config-does-not-follow-to-other-machines.md): which files under `~/.claude` to sync and which to leave out.
- [Claude Code changes made on Omarchy never reach my Mac](recipes/claude-changes-never-reach-the-mac.md): queue each change as a GitHub issue in the Mac's repo.

## Agent rules

- [Coding agent writes long, unwrapped, or file-list commit messages](recipes/agent-commit-messages-ignore-git-conventions.md): a global commit-message rule.
- [Coding agent edits another project when a prompt goes to the wrong session](recipes/agent-edits-a-different-project-than-its-session.md): tie each session to its own repo.
- [Coding agent skips the Omarchy skill in a dotfiles repo](recipes/agent-skips-the-omarchy-skill-in-a-config-repo.md): a repo `CLAUDE.md` that always loads it.

## Developer tools

- [`mise upgrade` skips a release that just shipped](recipes/mise-upgrade-skips-a-release-that-just-shipped.md): turn off the release cooldown and track the mise config.
- [`git push` over HTTPS fails after syncing the git config](recipes/git-push-over-https-fails-after-syncing-git-config.md): keep gh as the credential helper.

## Keeping a setup across machines

- [My Omarchy customizations don't follow me to my other machines](recipes/customizations-do-not-follow-to-other-machines.md): a git overlay with a shared layer and a per-machine layer.
- [SSH key has to be created or copied onto every machine](recipes/ssh-key-has-to-be-copied-to-every-machine.md): use the 1Password SSH agent.

## Writing a recipe

Start from [recipes/TEMPLATE.md](recipes/TEMPLATE.md). Name the file after the
symptom someone would search for, and state the versions you tested on.
