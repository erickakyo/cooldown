# Cooldown — Textos e estratégia de lançamento

## Estratégia em duas fases

**Fase 1 — agora (sem notarização).** Canais de dev, que sabem contornar o
Gatekeeper e valorizam o one-liner do brew. Objetivo além de downloads:
**stars no GitHub** (75 stars + 30 dias de repo destravam a submissão ao
homebrew-cask oficial, onde a descoberta é orgânica).

1. **r/macapps** (Reddit) — comunidade que existe pra isso
2. **r/ClaudeAI** (Reddit) — dor exata do público
3. **Show HN** (Hacker News) — maior alcance potencial, maior exigência

**Fase 2 — após a notarização.** Público geral, instalação sem fricção:

4. **Product Hunt** — é "one shot" por produto; não desperdiçar com o aviso
   de malware na primeira impressão
5. **LinkedIn (PT)** — audiência do Erick/Salto
6. **AlternativeTo + MacUpdate** — cadastros permanentes, SEO de longo prazo

**Horários (dias úteis):**
- Reddit: 9h–12h ET (10h–13h BRT), ter–qui
- Show HN: 9h–11h ET, ter–qui (evitar seg/sex)
- Product Hunt: entra 00:01 PT (4h01 BRT) pra concorrer o dia inteiro

**Regras de ouro:** responder TODO comentário nas primeiras 3–4h (o
algoritmo de todos esses canais premia engajamento do autor); nunca postar
o mesmo texto em dois subreddits no mesmo dia; tom de "fiz uma coisinha
útil", nunca de release corporativo.

---

## 1. Reddit — r/macapps

**Título:**
> I made Cooldown — a free menu bar timer that pings you the moment your AI usage limit (Claude, ChatGPT, Gemini…) resets

**Corpo:**

I kept doing the same dumb dance: hit Claude's 5-hour limit, forget about it, come back 7 hours later — or worse, keep checking every 20 minutes. So I built a tiny menu bar app that does the remembering for me.

How it works: when you hit a limit, you tell Cooldown how long the window is (presets for Claude, ChatGPT, Codex, Gemini, or custom). It counts down in the menu bar and fires a notification + sound the moment you're back. The notification has a "starting now — new cycle" button, since these windows only restart when *you* send the first message.

- Free, no account
- Zero telemetry — everything stays on your Mac, the only network call is an optional update check against GitHub Releases
- Multiple timers (e.g. "Claude — Work" + "Claude — Personal")
- PT-BR / EN, light/dark, launch at login
- macOS 14+

Install (one command — also clears the Gatekeeper prompt, since I haven't paid Apple's $99 yet):

```
brew install --cask erickakyo/tap/cooldown && xattr -dr com.apple.quarantine /Applications/Cooldown.app && open /Applications/Cooldown.app
```

Or grab the DMG: https://github.com/erickakyo/cooldown

Would love feedback — especially which AI services deserve a preset next.

*(anexar docs/hero.png como imagem do post)*

---

## 2. Reddit — r/ClaudeAI

*(postar 1–2 dias depois do r/macapps, não no mesmo dia)*

**Título:**
> Tired of guessing when my 5-hour window resets, so I built a free menu bar timer for it (macOS)

**Corpo:**

The 5-hour window starts when you send your first message — so it resets at a different time every day, and I could never remember when. My workflow was: hit the limit mid-task, switch to something else, completely forget about Claude, come back way later than needed.

Cooldown sits in the menu bar, counts down, and pings you (sound + notification) the second the window resets. The notification has a "starting now" button to re-arm it in one click when you begin a new cycle — because the reset only matters once *you* actually message again.

Free, no account, zero telemetry (everything local). Also has presets for ChatGPT, Codex and Gemini quotas, and you can run several timers at once (work account + personal account, for instance).

```
brew install --cask erickakyo/tap/cooldown && xattr -dr com.apple.quarantine /Applications/Cooldown.app && open /Applications/Cooldown.app
```

GitHub (DMG + source): https://github.com/erickakyo/cooldown

If Anthropic ever ships an official reset-time API, I'll happily wire it in — until then, this beats staring at the error message.

---

## 3. Show HN (Hacker News)

**Título** (link aponta pro repositório GitHub):
> Show HN: Cooldown – macOS menu bar timer for Claude/ChatGPT rate-limit resets

**Primeiro comentário (do autor, postar imediatamente):**

I use Claude heavily and kept losing track of when the 5-hour window would reset — it's a rolling window that starts on your first message, so it's different every day. Cooldown is a small menu bar app: tell it the window length (presets for Claude/ChatGPT/Codex/Gemini or custom), it counts down and notifies you the moment you're back, with a one-click "starting now" re-arm.

A few implementation notes that might be interesting:

- Built with Swift/SwiftUI using **only Command Line Tools — no Xcode**. Fun constraint discovered along the way: the `@State` macro doesn't compile without the SwiftUIMacros plugin that ships with Xcode, so the whole app uses `ObservableObject` + `@StateObject` instead.
- Zero telemetry, no account, everything in `UserDefaults`. The only network request is an optional update check against GitHub Releases.
- Not notarized yet ($99/year adds up for a free app) — so macOS will complain on first launch. The brew one-liner in the README handles the quarantine flag; I'm upfront about this in the docs.

Install: `brew install --cask erickakyo/tap/cooldown` (full one-liner in the README) or DMG from Releases.

Happy to answer anything about the no-Xcode build setup or the app itself. Feedback very welcome — especially on which services deserve presets.

**Preparar-se para perguntas prováveis (ter respostas prontas):**
- "Por que não open source de verdade / cadê a LICENSE?" → decisão consciente:
  código visível para auditoria (privacidade verificável), direitos reservados.
  Responder sem defensividade; considerar licenciar se virar tema dominante.
- "Por que não notarizado?" → custo; em breve. Não prometer data.
- "Electron?" → não, Swift nativo, ~1 MB.
- "Linux/Windows?" → macOS only por ora; anotar interesse.

---

## 4. Product Hunt — SEGURAR ATÉ NOTARIZAÇÃO

**Name:** Cooldown
**Tagline** (≤60 chars): Know the moment your AI usage limit resets
**Description** (≤260 chars):
> Free macOS menu bar timer for AI rate limits. Presets for Claude, ChatGPT, Codex & Gemini — get a sound + notification the second your window resets, re-arm in one click. No account, zero telemetry, everything stays on your Mac.

**Maker comment:**

Hey PH! 👋

If you use Claude or ChatGPT for real work, you know the moment: "limit reached, come back later" — but *when* exactly? These windows are rolling (they start when you send your first message), so the reset time changes every day.

Cooldown is a tiny menu bar app that does the tracking for you: pick a preset (Claude 5h, ChatGPT 3h, Gemini 24h, or custom), and it pings you — sound + notification — the second you're back. One click re-arms it for the next cycle.

Design decisions I care about:
- **Zero telemetry.** No account, no analytics, nothing leaves your Mac.
- **Native & tiny.** Swift/SwiftUI, ~1 MB, Liquid Glass design on macOS 26.
- **Free.** There's a "buy me a coffee" button if it saves your day often enough. ☕

Would love to hear how you deal with rate limits today — and which AI services deserve a preset next!

**Assets:** hero.png + screens.png (galeria) já servem; idealmente gravar um
GIF de 15s (abrir popover → timer → notificação disparando).

---

## 5. LinkedIn (PT-BR — perfil do Erick, fase 2)

Todo mundo que usa Claude ou ChatGPT no trabalho conhece a tela: "limite atingido, volte mais tarde".

Mais tarde… quando, exatamente? A janela do Claude são 5 horas — mas contadas a partir da SUA primeira mensagem. Ou seja: o horário do reset muda todo dia.

Eu vivia esquecendo. Voltava 2 horas depois do necessário, ou ficava checando de 20 em 20 minutos.

Então construí o Cooldown: um app gratuito de barra de menus para macOS que faz a conta pra você. Configura uma vez, ele te avisa — com som e notificação — no segundo em que a IA libera. Um clique re-arma o ciclo.

Alguns princípios que fizeram questão de entrar:

→ Zero telemetria. Nenhum dado sai do seu Mac. Sem conta, sem cadastro.
→ Nativo e leve (Swift, ~1 MB) — nada de Electron.
→ Gratuito. Tem um botão de "me paga um café" se ele te salvar com frequência. ☕

Instalação num comando (Homebrew) ou DMG no GitHub: github.com/erickakyo/cooldown

Foi um projeto de fim de semana da Salto Solutions que virou ferramenta de uso diário aqui. Se você vive esbarrando nos limites das IAs, me conta como você lida com isso hoje. 👇

#buildinpublic #macOS #IA #produtividade

---

## 6. X/Twitter (EN, thread curta — fase 1 ou 2)

**Tweet 1:**
Claude's 5-hour limit starts counting from YOUR first message — so it resets at a different time every day.

I got tired of guessing, so I built Cooldown: a free macOS menu bar timer that pings you the second your AI is back. 🧵

**Tweet 2:**
- Presets: Claude, ChatGPT, Codex, Gemini (or custom)
- Sound + notification on reset, one-click re-arm
- Multiple timers (work + personal)
- Zero telemetry, no account, ~1 MB native Swift

**Tweet 3:**
Free. Install with one command:

brew install --cask erickakyo/tap/cooldown

DMG + source: github.com/erickakyo/cooldown

#buildinpublic

---

## 7. AlternativeTo / MacUpdate (fase 2, cadastro único)

**Descrição curta (EN):**
> Free, native macOS menu bar timer that alerts you the moment your AI usage limit resets. Presets for Claude, ChatGPT, Codex and Gemini, multiple timers, one-click re-arm, zero telemetry. Swift/SwiftUI, macOS 14+.

Listar como alternativa a: apps de pomodoro/timer genéricos; tag "AI tools".
