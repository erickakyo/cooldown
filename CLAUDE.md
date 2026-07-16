# Cooldown — app de menu bar (macOS)

Alerta quando o limite de uso de IAs (Claude 5h, ChatGPT, Gemini…) reseta.
Detalhes de produto e decisões: `.claude/context/produto.md`.

## Stack

- Swift + SwiftUI, `MenuBarExtra` (app agente, `LSUIElement`)
- Swift Package Manager — **sem Xcode**: compila só com Command Line Tools
- macOS mínimo: 14 (Sonoma). Liquid Glass nativo no macOS 26+, fallback `.ultraThinMaterial`
- Persistência: `UserDefaults` + `Codable` (chaves `cooldown.timers`, `cooldown.settings`)

## Comandos

```bash
scripts/build.sh          # compila e monta dist/Cooldown.app (assinatura ad-hoc)
scripts/build.sh --run    # idem + relança o app
```

## Arquitetura

- `Sources/Cooldown/CooldownApp.swift` — @main, MenuBarExtra + AppDelegate
- `Models/` — AITimer (estado idle/running/ready), ServicePreset, AppSettings
- `Stores/TimerStore.swift` — fonte de verdade: tick 1s, persistência, agendamento
- `Services/` — NotificationService (UN local + ação de re-arme), SoundService,
  LaunchAtLogin (SMAppService), UpdateChecker (GitHub Releases)
- `Views/` — MenuPopover (navegação por telas), TimerEditorView, SettingsView,
  AboutView, DonateView, GlassCard (Liquid Glass/fallback)
- `L10n.swift` — strings pt-BR/en-US trocáveis em runtime

## Regras específicas deste projeto

- **NUNCA usar `@State`/`@Binding` como macro em código novo sem testar**: as
  Command Line Tools não têm o plugin `SwiftUIMacros` do SDK macOS 26+ —
  `@State` NÃO compila. Usar classes `ObservableObject` + `@StateObject`/
  `@Published` (padrão já adotado em todas as views). `@Binding` funciona.
- Rodar sempre via bundle (`scripts/build.sh --run`): `UNUserNotificationCenter`
  crasha fora de um `.app`.
- Sons de notificação: copiar o .aiff do sistema para `~/Library/Sounds`
  (já feito em `SoundService`) — é onde o UN procura sons customizados.
- Links de doação/repositório em `AppConfig.swift`; placeholders contêm
  "PREENCHER" e desabilitam os botões na UI.
