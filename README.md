# ⏳ Cooldown — AI Limit Timer for Claude, ChatGPT & Gemini

**Your AI is napping. We'll tell you when it wakes up.**

Cooldown is a lightweight macOS menu bar app that alerts you — with a sound and a notification — the moment your AI usage limit resets. Stop guessing when Claude's 5-hour window is over: set it once, get pinged, and go back to work.

*Leia em [português](README.pt-BR.md).*

![Cooldown living in the macOS menu bar, with timers for Claude, Codex, ChatGPT and Gemini](docs/hero.png)

## Features

- ⏱️ **Multiple timers** — track several accounts and services at once (e.g. "Claude — Work" and "Claude — Personal")
- 🤖 **Service presets** — Claude (5h), ChatGPT (3h), Gemini (24h), or fully custom name + duration
- 🔔 **Sound + notification** — pick from macOS system sounds with live preview; alerts fire even if the app is closed
- 🔁 **One-click re-arm** — the notification itself has a *"Starting now — new cycle"* action button, because the window only starts when *you* send the first message
- ♻️ **Optional auto-repeat** — per-timer toggle for hands-off cycles (off by default, since it can drift from the real reset)
- 🪟 **Liquid Glass design** — native on macOS 26+, translucent fallback on macOS 14–15
- 🌗 **Appearance** — system / light / dark
- 🇧🇷🇺🇸 **Bilingual** — Portuguese and English, switchable instantly
- 🚀 **Launch at login**, countdown in the menu bar, update checker

![Settings, donation and about screens](docs/screens.png)

## Privacy

Cooldown stores everything locally on your Mac (`UserDefaults`). No account, no telemetry, no data ever leaves your machine. The only network request is the optional update check against GitHub Releases.

## Install

### Homebrew (recommended)

```bash
brew install --cask erickakyo/tap/cooldown
```

### Manual download

Download the latest `Cooldown-x.y.z.dmg` from [Releases](../../releases), drag it to Applications, and allow notifications on first launch.

### First launch ("Apple could not verify…")

Cooldown is not notarized by Apple yet, so macOS blocks the first launch **regardless of install method** (Homebrew or DMG). Click **OK** (not "Move to Trash"), then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**. Or, in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/Cooldown.app
```

## Updating

Cooldown checks for new versions automatically when it starts (and every 24 hours while running). When an update is available, an orange banner appears in the main panel. Your timers and settings are always kept — they live in macOS preferences, not in the app bundle.

Update using the same method you installed with:

- **Homebrew:** `brew upgrade --cask erickakyo/tap/cooldown`
- **Manual (DMG):** click **Download & Quit** in the update banner (Cooldown closes itself so Finder can replace it), then drag the new Cooldown to Applications. If you downloaded manually, quit Cooldown first (right-click the menu bar icon → Quit). The first launch after a manual download hits the Gatekeeper prompt again — see the note in [Install](#install)
- **From source:** in your clone, `git pull && scripts/build.sh --install`

## Build from source

Requires macOS 14+ and Xcode Command Line Tools (full Xcode **not** required):

```bash
git clone https://github.com/erickakyo/cooldown.git
cd cooldown
scripts/build.sh --install   # builds and installs to /Applications
```

For development, `scripts/build.sh --run` builds and launches straight from `dist/` without installing.

> Note: the SwiftUI `@State` macro doesn't compile with Command Line Tools on the macOS 26 SDK, so views use `ObservableObject` + `@StateObject` instead. See [CLAUDE.md](CLAUDE.md) for architecture details.

## How the re-arm logic works

AI usage windows (like Claude's 5h) are *rolling*: they start when you send your first message, not on a fixed clock. So Cooldown fires **once** and switches the timer to a "✅ Ready!" state. From there:

1. Tap **"Starting now — new cycle"** on the notification (or in the app) the moment you actually start using the AI again — maximum precision, one click.
2. Or enable **auto-repeat** per timer if you prefer hands-off cycles.
3. **Adjust** any running timer at any time if the provider resets the count globally.

## Support the project ☕

Cooldown is free. If it saves you from staring at "limit reached" screens, you can buy us a coffee via the in-app donation button (card via Stripe, Pix via Mercado Pago for Brazil).

---

Made with ☕ by [Salto Solutions](https://salto.solutions) — tailor-made digital solutions, AI automations, apps and websites. Need something built? [Talk to us](https://salto.solutions).

© 2026 Salto Solutions. All rights reserved.
