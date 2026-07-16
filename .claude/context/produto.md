# Cooldown — Produto e Decisões

## O que é

App gratuito de barra de menus para macOS que avisa (som + notificação) quando
o limite de uso de uma IA reseta. O usuário informa quanto tempo falta (ou a que
horas a janela começou) e o Cooldown conta o resto. Desenvolvido pela Salto
Solutions (https://salto.solutions) como vitrine/canal de contato.

- Nome: **Cooldown** — bundle id `solutions.salto.cooldown`
- Idiomas: pt-BR 🇧🇷 e en-US 🇺🇸 (troca em runtime, sem relaunch)
- macOS mínimo: 14 (Sonoma); Liquid Glass nativo no 26+, fallback translúcido

## Presets de serviço (2026-07)

| Serviço | Janela padrão | Observação |
|---|---|---|
| Claude | 5h | janela rolante; começa na 1ª mensagem |
| ChatGPT | 3h | limites variam por plano |
| Gemini | 24h | quota diária |
| Personalizado | livre | nome + duração definidos pelo usuário |

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

## Pendências (fora do código)

- [ ] Criar Payment Link no Stripe e link/código Pix no Mercado Pago → `AppConfig.swift`
- [x] Criar repositório GitHub (`erickakyo/cooldown`, público)
- [ ] Conta Apple Developer p/ notarização
- [ ] Revisar texto da janela "Sobre" com os serviços reais do site salto.solutions
- [ ] Ícone definitivo (o atual é gerado por script: gradiente + ampulheta)
