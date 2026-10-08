# Duff's Omarchy cookbook

These are Duff's customizations for [Omarchy](https://omarchy.org/). Some of
them might be helpful to others, or to someone's agents. 🙂

Each recipe covers one problem: what stock Omarchy does, why, the change, how
to check that it worked, and how to undo it. Most fit any Omarchy machine. The
recipe data at the end of each one says whether it needs particular hardware,
what it touches, and which Omarchy version it was tested on, so an agent can
tell whether it applies to yours.

## Mouse, touchpad, and keyboard

- [Scrolling direction feels backwards on the touchpad and mouse](recipes/scrolling-direction-feels-backwards/RECIPE.md): turn on natural scrolling for both; Hyprland has separate switches.
- [Moving the mouse steals keyboard focus](recipes/hovering-mouse-steals-keyboard-focus/RECIPE.md): click to focus, while hover still scrolls.
- [A light palm tap on the touchpad clicks things](recipes/touchpad-palm-tap-clicks-things/RECIPE.md): turn off tap-to-click.
- [High-DPI gaming mouse moves the cursor too fast to place it precisely](recipes/gaming-mouse-cursor-too-fast/RECIPE.md): a per-device acceleration curve, precise when slow and far on a flick.
- [MacBook T2 trackpad moves the cursor while typing](recipes/macbook-t2-trackpad-moves-cursor-while-typing/RECIPE.md): mark the pad internal, plus a small daemon that pauses it after each key.
- [Make Caps Lock Escape on tap and hjkl arrows on hold](recipes/caps-lock-as-escape-and-hjkl-arrows/RECIPE.md): with keyd.
- [Swap Alt and Super on the laptop keyboard only](recipes/swap-alt-and-super-on-laptop-keyboard-only/RECIPE.md): per-device keyd config that leaves an external keyboard alone.
- [Super+J shows a Lua error on a scrolling-layout workspace](recipes/super-j-error-on-scrolling-layout/RECIPE.md): only toggle the split on dwindle.
- [No volume keys on the keyboard](recipes/no-volume-keys-on-the-keyboard/RECIPE.md): Super+] and Super+[ turn the volume up and down.

## Compose key and dictation

- [Putting Compose on Right Alt breaks Right Alt as a modifier](recipes/right-alt-compose-key-loses-alt-modifier/RECIPE.md): tap for Compose, hold for Alt.
- [A Compose sequence types the wrong emoji, or one is missing](recipes/compose-sequence-types-the-wrong-emoji/RECIPE.md): override or add sequences in `~/.XCompose`.
- [A Compose snippet with a line break comes out scrambled in Chrome](recipes/compose-snippet-with-line-break-scrambled-in-chrome/RECIPE.md): commit a placeholder and type the lines with an fcitx5 add-on.
- [One Voxtype config on machines that need different Parakeet models](recipes/voxtype-parakeet-model-differs-per-machine/RECIPE.md): switch to Parakeet and keep the model choice per machine.
- [Voxtype keeps mishearing the same word](recipes/voxtype-mishears-the-same-word/RECIPE.md): `[text.replacements]`, and where to find what it actually heard.
- [Dictation keeps recording after letting go of push-to-talk](recipes/dictation-keeps-recording-after-releasing-push-to-talk/RECIPE.md): rebind both ends to ignore modifiers.
- [Dictated text types out slowly](recipes/voxtype-dictation-types-slowly/RECIPE.md): set the typing delay to zero.
- [Dictation went into the wrong field](recipes/dictation-typed-into-the-wrong-field/RECIPE.md): Super+D retypes the last dictation into the focused field.

## Apps, web apps, and links

- [A launcher shortcut opens a second window instead of focusing the open one](recipes/launcher-shortcut-opens-a-second-window/RECIPE.md): why stock focus misses some apps, how to fix shortcuts, and every web app in the launcher.
- [Two web app windows for the same site share a login or get mixed up](recipes/two-web-app-windows-for-the-same-site-get-mixed-up/RECIPE.md): separate profiles for two accounts, and telling production from a local copy.
- [A web app opens every link in a new window, or sends links to a browser tab](recipes/web-app-opens-links-in-new-windows-or-browser-tabs/RECIPE.md): use a regular window, or an installed Chrome app.
- [mailto: links open in Chrome instead of HEY](recipes/mailto-links-open-in-chrome-instead-of-hey/RECIPE.md): put HEY back as the handler and keep it there after updates.
- [No shortcut to open a typed or pasted URL](recipes/no-shortcut-to-open-a-typed-or-pasted-url/RECIPE.md): Super+U opens an address or searches the web.
- [Desktop shortcuts appear in the home folder](recipes/desktop-shortcuts-appear-in-home-folder/RECIPE.md): give them a real `~/Desktop`.
- [1Password locks every time the screen locks](recipes/1password-locks-every-time-the-screen-locks/RECIPE.md): skip Omarchy's lock call so 1Password's own settings decide.
- [Chrome shows a privacy warning on a local Caddy HTTPS site](recipes/chrome-privacy-warning-on-local-caddy-https-site/RECIPE.md): add Caddy's root certificate to Chrome's own store.
- [Wine app is tiny, blurry, or draws hair-thin lines on a HiDPI screen](recipes/wine-app-blurry-or-thin-lines-on-hidpi/RECIPE.md): draw at 96 DPI and let Hyprland double it.
- [Wine app quits on Super+W, or pops back up after hiding it](recipes/wine-app-quits-on-super-w-or-pops-back-up-when-hidden/RECIPE.md): show and hide an all-day app with one key.

## Displays and workspaces

- [HiDPI screens are left on auto scale instead of a fixed 2x](recipes/hidpi-screens-left-on-auto-scale/RECIPE.md): pin the scale.
- [Monitors swap left and right when the cables change ports](recipes/monitors-swap-sides-when-cables-change-ports/RECIPE.md): pin each screen by make, model, and serial.
- [Workspaces open on unpredictable monitors](recipes/workspaces-open-on-the-wrong-monitor/RECIPE.md): give each monitor its own block of workspace numbers.
- [Every display's bar shows the same workspace numbers](recipes/every-bar-shows-the-same-workspace-numbers/RECIPE.md): each bar lists only its own screen's workspaces.
- [Super+Slash made everything bigger, and it stays that way](recipes/super-slash-made-everything-bigger/RECIPE.md): what the shortcut changes and how to undo it.
- [Hard to see which window is focused](recipes/hard-to-see-which-window-is-focused/RECIPE.md): wider borders.
- [Windows are slightly see-through](recipes/windows-are-slightly-see-through/RECIPE.md): make every window fully opaque.
- [A lone window fills the whole screen in the scrolling layout](recipes/lone-window-fills-the-screen-in-scrolling-layout/RECIPE.md): keep it a half-width column.
- [Super+Shift+arrow only swaps windows](recipes/super-shift-arrow-only-swaps-windows/RECIPE.md): move a window into its neighbor's split.

## Laptop, power, network, and audio

- [Intel laptop screen stays black after undocking with the lid shut and sleeping](recipes/laptop-screen-stays-black-after-undocked-sleep/RECIPE.md): keep the panel off while closed and restore it on wake.
- [Laptop used as a headless server sleeps when the lid is shut](recipes/laptop-server-sleeps-when-lid-is-shut/RECIPE.md): ignore the lid and allow only key logins over SSH.
- [Laptop Wi-Fi falls back to slow 2.4 GHz with the lid shut](recipes/laptop-wifi-falls-back-to-2-4-ghz-with-lid-shut/RECIPE.md): WPA3 and a pinned 5 GHz band.
- [Screensaver starts too soon while reading](recipes/screensaver-starts-too-soon/RECIPE.md): longer idle timers.
- [Wrong default microphone records silence when docked](recipes/wrong-default-microphone-records-silence/RECIPE.md): WirePlumber priorities.
- [ErgoDox EZ cannot be flashed or trained from Oryx](recipes/ergodox-ez-cannot-be-flashed-from-oryx/RECIPE.md): udev rules and the plugdev group.

## Bar, notifications, menus, and terminals

- [Bar clock shows 24-hour time](recipes/bar-clock-shows-24-hour-time/RECIPE.md): switch to 12-hour.
- [Battery percentage not shown in the bar](recipes/battery-percentage-not-shown-in-the-bar/RECIPE.md): show it next to the icon.
- [Bar is missing a widget you want, or shows one you don't use](recipes/tailscale-missing-from-the-bar/RECIPE.md): enable, disable, or add bar widgets, such as Tailscale.
- [Bar and menu text too small](recipes/bar-and-menu-text-too-small/RECIPE.md): enlarge the shell font without changing terminals.
- [Reminder notification disappears after 5 seconds](recipes/reminder-disappears-after-5-seconds/RECIPE.md): keep reminders up until dismissed.
- [Reboot from the menu, or Ctrl+Alt+Delete, closes everything without asking](recipes/reboot-and-close-all-windows-without-asking/RECIPE.md): add confirmations.
- [No Print Screen key for screenshots](recipes/no-print-screen-key-for-screenshots/RECIPE.md): put a screenshot tool on Super+Shift+S and in the Capture menu.
- [Ctrl+Enter toggles fullscreen in Ghostty](recipes/ctrl-enter-toggles-fullscreen-in-ghostty/RECIPE.md): pass the key through to apps.

## Agents and terminal multiplexing

- [Clicking "Process crashed" starts an agent that may change files without asking](recipes/crash-notification-agent-changes-files-without-asking/RECIPE.md): open the crash diagnosis in plan mode.
- [Herdr closes a workspace, pane, or tab without asking](recipes/herdr-closes-workspace-pane-or-tab-without-asking/RECIPE.md): bring back the confirmation.
- [Herdr's agent list keeps reordering itself](recipes/herdr-agent-list-keeps-reordering/RECIPE.md): group by workspace.
- [Herdr has no shortcut to jump between agents](recipes/herdr-no-shortcut-to-jump-between-agents/RECIPE.md): Alt+Up and Alt+Down.
- [Herdr tab names don't show which tab is running an agent](recipes/herdr-tab-names-do-not-show-which-tab-runs-an-agent/RECIPE.md): rename the tab while the agent runs.

## Claude Code

- [Claude Code's status line doesn't show the project or whether git is clean](recipes/claude-status-line-does-not-show-project-or-git-state/RECIPE.md): model, effort, project, and a git check or cross.
- [Claude sessions can't be reached from my phone, or all look alike there](recipes/claude-sessions-look-alike-in-remote-control/RECIPE.md): Remote Control at startup, with each session named after its project.
- [Claude Code keeps asking "How is Claude doing?"](recipes/claude-feedback-survey-interrupts-sessions/RECIPE.md): turn off the feedback survey.
- [Claude Code adds "Co-Authored-By: Claude" to my commits](recipes/claude-adds-co-authored-by-to-commits/RECIPE.md): turn off attribution.
- [Claude Code commits but doesn't push, or asks whether to push](recipes/claude-asks-whether-to-push-after-committing/RECIPE.md): make them one step.
- [A prompt typed into the wrong Claude session changes the wrong project](recipes/prompt-typed-into-the-wrong-claude-session/RECIPE.md): have Claude stop and ask.
- [Claude Code settings and rules don't follow me to my other machines](recipes/claude-code-config-does-not-follow-to-other-machines/RECIPE.md): which files under `~/.claude` to sync and which to leave out.
- [Claude Code changes made on Omarchy never reach my Mac](recipes/claude-changes-never-reach-the-mac/RECIPE.md): queue each change as a GitHub issue in the Mac's repo.

## Agent rules

- [Coding agent writes long, unwrapped, or file-list commit messages](recipes/agent-commit-messages-ignore-git-conventions/RECIPE.md): a global commit-message rule.
- [Grok edits another project when a prompt goes to the wrong session](recipes/agent-edits-a-different-project-than-its-session/RECIPE.md): tie each session to its own repo.
- [Coding agent skips the Omarchy skill in a dotfiles repo](recipes/agent-skips-the-omarchy-skill-in-a-config-repo/RECIPE.md): a repo `CLAUDE.md` that always loads it.

## Developer tools

- [`mise upgrade` skips a release that just shipped](recipes/mise-upgrade-skips-a-release-that-just-shipped/RECIPE.md): turn off the release cooldown and track the mise config.
- [`git push` over HTTPS fails after syncing the git config](recipes/git-push-over-https-fails-after-syncing-git-config/RECIPE.md): keep gh as the credential helper.

## Keeping a setup across machines

- [My Omarchy customizations don't follow me to my other machines](recipes/customizations-do-not-follow-to-other-machines/RECIPE.md): a git overlay with a shared layer and a per-machine layer.
- [SSH key has to be created or copied onto every machine](recipes/ssh-key-has-to-be-copied-to-every-machine/RECIPE.md): use the 1Password SSH agent.

## Following this cookbook

Ask your agent to set you up with
[omarchy-kitchen](https://github.com/duff/omarchy-kitchen) and follow
`duff/omarchy-cookbook`. Once a week it shows you the new and changed recipes
that fit your machine, and applies only the ones you pick.

The recipe format is
[omarchy-kitchen's format.md](https://github.com/duff/omarchy-kitchen/blob/main/skills/omarchy-kitchen/format.md).
