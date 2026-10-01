# omarchy-recipes

Public write-ups of how one Omarchy setup differs from the stock install, one
problem per recipe. The readers are people and AI agents customizing their own
Omarchy machines, so every recipe has to stand on its own.

The working config lives in a separate private repo. This repo never copies
it wholesale and never names it. Each recipe explains the problem and shows
only the snippet that fixes it.

## Nothing private, ever

This repo is meant to be public. Before writing or committing, leave out:

- People's names, family details, email addresses, phone numbers, signatures.
  Duff's first name is fine, since these are his customizations; his surname,
  age, and birth year are not.
- Hostnames, usernames in paths (write `~`, not `/home/<user>`), IPs, Wi-Fi
  network names, Tailscale names, display or device serial numbers.
- Accounts and services that reveal finances, health, school, or home life
  (brokerages, banks, calendars, Home Assistant entities and URLs).
- Names of private projects or repos, and any token, key, or credential.

When the technique is useful but the example is private, generalize it: "two
logins to the same site as separate web apps", not the real site and account.
When even the idea is private, leave the recipe out.

## Recipe format

One file per problem in `recipes/<slug>.md`, named after the symptom, not the
fix. Use `recipes/TEMPLATE.md`. Every recipe states the Omarchy and Hyprland
versions it was tested on, because Omarchy changes quickly and Hyprland moved
to Lua config in 0.56.

List every recipe in `README.md` with a one-line summary.

## Adding new recipes

New recipes come from a review of the private repo's commits since the last
review. Nothing is written or pushed here until Duff has confirmed each item.
The review steps and the record of where the last review stopped live in the
private repo.
