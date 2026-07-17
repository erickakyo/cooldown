# Cooldown — Produto e Decisões

## O que é

App gratuito de barra de menus para macOS que avisa (som + notificação) quando
o limite de uso de uma IA reseta. O usuário informa quanto tempo falta (ou a que
horas a janela começou) e o Cooldown conta o resto. Desenvolvido pela Salto
Solutions (https://salto.solutions) como vitrine/canal de contato.

- Nome: **Cooldown** — bundle id `solutions.salto.cooldown`
- Idiomas: pt-BR 🇧🇷 e en-US 🇺🇸 (troca em runtime, sem relaunch); **padrão: inglês**
- Botão de doação sempre "Buy me a coffee ☕" (termo consagrado, nos dois idiomas)
- macOS mínimo: 14 (Sonoma); Liquid Glass nativo no 26+, fallback translúcido

## Presets de serviço (2026-07)

| Serviço | Janela padrão | Observação |
|---|---|---|
| Claude | 5h | janela rolante; começa na 1ª mensagem |
| Codex | 5h | jul/2026: OpenAI removeu a janela de 5h dos planos pagos, mantendo teto semanal — usuário ajusta p/ 168h se for o caso |
| ChatGPT | 3h | limites de mensagens variam por plano/modelo |
| Antigravity | 5h | quotas dos planos Google AI Pro/Ultra renovam a cada 5h |
| Gemini | 24h | quota diária (app/API) |
| Personalizado | livre | nome + duração definidos pelo usuário |

Janela máxima configurável: 168h (1 semana), para cobrir tetos semanais.

Duração é editável em qualquer preset. Novos presets são entregues via
atualização do app (sem backend).

## Decisão: alerta dispara uma vez + re-arme em 1 clique

1. Padrão: dispara **uma vez** e o timer fica no estado "✅ Liberado!".
2. A notificação e o card têm botão **"Comecei agora — novo ciclo"** (re-arme
   em 1 clique — preciso porque a janela só começa quando o usuário usa a IA).
3. **Auto-repetição opcional** por timer (off por padrão), com aviso de que
   pode desalinhar do reset real. Botão "Ajustar" corrige o tempo a qualquer
   momento (cobre reset global do Claude).

## Doações

- Internacional: **Stripe Payment Link** (conta existente; sem taxa de plataforma além do Stripe)
- Brasil: **Pix via Mercado Pago** (Stripe Pix ainda não liberado na conta)
- Botões abrem o navegador; nada de pagamento in-app
- Links em `Sources/Cooldown/AppConfig.swift` — **PENDENTE preencher**
- Segurança: os links de doação são públicos por natureza (só permitem ENVIAR
  dinheiro; não expõem conta nem permitem cobranças). Nunca colocar chaves de
  API (`sk_live_...`, access token MP) no app — não são necessárias.
- Pix: usar **chave aleatória** (ou só o link de pagamento do MP). Código
  "copia e cola" gerado de chave CPF/e-mail/telefone expõe esse dado dentro
  do código Pix.

## Atualizações

V1: `UpdateChecker` consulta a última release do GitHub
(`AppConfig.githubRepo` — **PENDENTE criar o repositório**) e oferece download.
Motivo: Sparkle exige bundling de framework, complicado sem Xcode na máquina.
Quando houver Xcode/conta Apple Developer, migrar para Sparkle 2 (auto-update
de verdade, appcast + EdDSA).

## Distribuição

Fora da App Store (site/GitHub). **PENDENTE: conta Apple Developer (US$ 99/ano)**
para assinar com Developer ID + notarizar — sem isso o Gatekeeper bloqueia o
app em outras máquinas. Build local usa assinatura ad-hoc (funciona só nesta máquina).

Roadmap de release: repositório GitHub → conta Apple Developer → script de
notarização + DMG → página no site → (V2) Sparkle.

## GitHub

Repositório: `erickakyo/cooldown` — **público** desde 2026-07-16 (decisão do
Erick). Sem arquivo LICENSE = todos os direitos reservados (explícito no
README); ninguém pode reutilizar o código legalmente. Releases publicadas com
`scripts/release.sh` (DMG + tag `vX.Y.Z`) — é o que alimenta o update checker
do app.

## Imagens dos READMEs (`docs/`)

- `docs/hero.png`: **imagem de marketing sob medida** (`_assets/github-cooldown-hero.png`),
  copiada direto — não é gerada a partir de mockup. **Não regenerar via
  `docs/mockups/hero.html`** — isso substitui a imagem de marketing pelo
  mockup fiel à UI (já aconteceu por engano em 2026-07-17, revertido na hora).
- `docs/screens.png`: gerado a partir de `docs/mockups/gallery.html` via
  Playwright (`deviceScaleFactor: 2`, viewport 1140x560 → PNG 2280x1120).
  Esse mockup precisa ser mantido em sincronia manual com a UI real — depois
  de qualquer mudança visual no popover (header, botões, ícones), atualizar
  o HTML antes de re-renderizar. Sem script fixo; comando usado:
  `node -e "const {chromium}=require('playwright'); ..."` com
  `page.screenshot({ path: 'docs/screens.png' })` (Playwright instalado à parte,
  não é dependência do projeto).

## Analytics — decisão (2026-07-17)

**Zero telemetria no app** — o README promete "no telemetry, no data ever
leaves your machine" e isso é argumento de venda. Medição de uso:
`scripts/stats.sh` (downloads por release + tráfego do repo via API do
GitHub) e GA4 do site (o botão Sobre já manda utm_source=cooldown).
Se um dia precisar de dados de uso reais: TelemetryDeck (anônimo, SDK
Swift, grátis até 100k sinais/mês) + atualizar README + toggle opt-out.

## Estado atual (2026-07-17)

**v1.0.0 lançada.** Ciclo 0.1.x validou de ponta a ponta: instalação por
código-fonte (`build.sh --install`), DMG e Homebrew (tap `erickakyo/tap`,
cask com `uninstall quit`); atualização com banner + "Baixar e Sair",
re-checagem a cada 24h, one-liner de upgrade no README. Gatekeeper segue
exigindo "Abrir Mesmo Assim" até a notarização. READMEs com imagens
(mockups HTML em docs/mockups, regeneráveis via Chrome headless).

Histórico v0.1.0 (2026-07-16). Implementado e testado:
timers múltiplos com presets (Claude/Codex/ChatGPT/Antigravity/Gemini/custom),
notificação com re-arme em 1 clique, auto-repetição opcional, pré-alerta
(5/10/15 min), onboarding na primeira abertura, menu de contexto no clique
direito (com re-arme direto), update check a cada inicialização + banner,
idiomas (padrão inglês), aparência, iniciar com o sistema, UI legível sobre
Liquid Glass, ícone floco de neve (app) e floco + ampulheta (barra de menus),
link do Sobre com UTM, git/GitHub só com a conta erickakyo.

## Pendências

### Bloqueiam o lançamento público
- [ ] **Conta Apple Developer** (Erick, US$ 99/ano): sem Developer ID +
      notarização, o Gatekeeper alerta "desenvolvedor não verificado" em
      outras máquinas. Depois de ativa: configurar assinatura/notarização
      no `scripts/release.sh`

### Divulgação (2026-07-17)
Canais definidos: LinkedIn, Instagram, Reddit e outros (ver
`.claude/context/lancamento.md` para textos e estratégia por canal).
Página no salto.solutions **já existe**.

### Backlog técnico (sem pressa)
- [ ] Migrar UpdateChecker → Sparkle 2 quando houver Xcode instalado
      (auto-update de verdade, sem abrir navegador)
- [ ] Atalho global de teclado para abrir o painel

### Concluídas
- [x] Repositório GitHub público (`erickakyo/cooldown`) + release v0.1.0
- [x] Ícone definitivo: floco de neve (gradiente azul-gelo)
- [x] Histórico git 100% na conta erickakyo (akyo@me.com), sem coautoria
- [x] Links de doação preenchidos em `AppConfig.swift` (2026-07-16): Stripe
      Payment Link fixo R$ 2,99, link Pix Mercado Pago, chave Pix aleatória
      (UUID) para o botão "copiar código Pix" — copia só a chave, usuário
      digita o valor manualmente no app do banco
- [x] Logotipos monocromáticos reais para Claude, ChatGPT, Gemini, Codex e Antigravity/Custom (2026-07-17)
- [x] Correção do Spacebar Bug (causa raiz real: toque acidental no trackpad, não foco/teclado — ver seção abaixo) (2026-07-17)
- [x] Melhoria no botão voltar (hit target estendido com fundo circular de 24x24) e remoção dos ícones de título (2026-07-17)
- [x] Bandeiras de idioma dessaturadas pelo vidro no dark mode: trocada a
      renderização de `Text(emoji)` para `Image(nsImage:)` com o emoji
      desenhado em bitmap (cache em `PillPicker.swift`) — vibrancy do glass
      não afeta bitmaps, só texto (2026-07-17)
- [x] Ajuste fino do ícone da barra de menus (2026-07-17): a ampulheta
      usava um `y` fixo (0.5) que a deixava visivelmente mais baixa que o
      floco de neve, e a margem esquerda do ícone com timer (0) não batia
      com a do ícone sem timer (1.5), então os dois pareciam "pular" de
      posição ao alternar. Corrigido em `CooldownApp.swift`:
      `drawSymbolCentered` centraliza o símbolo verticalmente pela altura
      real do `NSImage` renderizado (em vez de `y` chutado), e a margem
      esquerda de 1.5 foi igualada entre os dois ícones.

### Spacebar Bug — causa raiz (2026-07-17)

Sintoma: digitar no campo "Account" do editor de timer (ex. "Salto
Solutions") fechava o popover assim que se apertava a barra de espaço.

Hipóteses tentadas e descartadas, nessa ordem, cada uma com log de
diagnóstico (`NSLog` + stack trace em `popoverShouldClose`/`popoverDidClose`)
que provou a hipótese errada antes de passar pra próxima:
1. `popover.behavior = .transient` reagindo a qualquer keyDown não tratado
   → trocado para `.applicationDefined` + monitores manuais de dismiss.
   Não resolveu sozinho.
2. Acesso Total pelo Teclado / VoiceOver "clicando" no ícone da barra via
   `sendAction`/`performClick` sem mouse real → `button.setAccessibilityElement(false)`.
   Não resolveu sozinho.
3. O clique ainda acontecia mesmo **sem nenhuma `action`/`target` no botão**
   (removidos por completo, substituídos por um monitor de mouse local) —
   provando que não era `sendAction`/`performClick`/acessibilidade.

Causa raiz real (confirmada por log): a barra de espaço chegava
**normalmente** como tecla de texto na janela certa (`_NSPopoverWindow`,
key window). No mesmíssimo instante, um evento **genuíno de
`NSEvent.leftMouseDown`** (não sintético, não via Accessibility API) chegava
na janela do próprio ícone da barra de menus. Ou seja: um toque acidental no
trackpad (Tap to Click) — a mão alcançando a barra de espaço encosta ou
aproxima o polegar/palma do trackpad, e o cursor do mouse geralmente ainda
está em cima do ícone (de quando o usuário clicou nele pra abrir o popover)
— gera um clique real e indistinguível de um clique intencional.

**Correção aplicada** (`CooldownApp.swift`): um monitor local de `keyDown` no
popover grava o timestamp da última tecla digitada (`lastPopoverKeyDown`).
O monitor de mouse do ícone da barra ignora um `leftMouseDown` que chegue a
menos de 500ms dessa última tecla — sinal forte de toque acidental — sem
afetar o clique intencional de "fechar de novo" clicando no ícone (que
raramente vem tão colado a uma tecla).

**Se o bug voltar:** não insista em teorias de foco/first-responder/behavior
do NSPopover — já descartadas com prova. Comece verificando se o timestamp de
500ms ainda é suficiente (aumentar se necessário) ou se há um caso de clique
intencional real sendo bloqueado por engano (diminuir). O ponto de
instrumentação mais rápido pra depurar de novo: `NSLog` em
`popoverDidClose`/`popoverShouldClose` com `Thread.callStackSymbols`, e um
monitor local de `.keyDown` logando `window`/`keyWindow` — reproduz o
problema em segundos e mostra exatamente quem fechou o popover.
