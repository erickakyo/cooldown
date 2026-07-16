import Foundation

/// Strings do app em pt-BR e en-US, trocáveis em tempo real (sem relaunch).
struct L {
    let lang: AppLanguage
    init(_ lang: AppLanguage) { self.lang = lang }

    private func t(_ pt: String, _ en: String) -> String { lang == .pt ? pt : en }

    // Lista / popover
    var noTimers: String { t("Nenhum timer ainda", "No timers yet") }
    var noTimersHint: String { t("Adicione um timer para ser avisado quando sua IA liberar.", "Add a timer to get notified when your AI is back.") }
    var newTimer: String { t("Novo timer", "New timer") }
    var ready: String { t("Liberado!", "Ready!") }
    var idle: String { t("Parado", "Stopped") }
    var quit: String { t("Sair do Cooldown", "Quit Cooldown") }
    var openApp: String { t("Abrir Cooldown", "Open Cooldown") }

    // Ações do timer
    func newCycle(_ duration: String) -> String { t("Novo ciclo (\(duration))", "New cycle (\(duration))") }
    var adjust: String { t("Ajustar", "Adjust") }
    var stop: String { t("Parar", "Stop") }
    var delete: String { t("Excluir", "Delete") }
    var ok: String { "OK" }

    // Sheet de criação/edição
    var editTimer: String { t("Ajustar timer", "Adjust timer") }
    var service: String { t("Serviço", "Service") }
    var customName: String { t("Nome do serviço", "Service name") }
    var accountOptional: String { t("Conta (opcional) — ex.: Trabalho", "Account (optional) — e.g. Work") }
    var timeRemaining: String { t("Tempo restante", "Time remaining") }
    var startedAt: String { t("Começou às", "Started at") }
    var windowLabel: String { t("Janela do limite", "Limit window") }
    var hoursShort: String { "h" }
    var minutesShort: String { "min" }
    func justStarted(_ duration: String) -> String { t("Comecei agora (\(duration))", "Just started (\(duration))") }
    var autoRepeat: String { t("Repetição automática", "Auto-repeat") }
    var autoRepeatWarning: String {
        t("Re-arma sozinho ao disparar. Pode desalinhar do reset real — a janela só começa quando você usa a IA.",
          "Re-arms automatically when it fires. May drift from the real reset — the window only starts when you use the AI.")
    }
    var sound: String { t("Som", "Sound") }
    var alertAt: String { t("Alerta às", "Alert at") }
    var defaultSound: String { t("Padrão do app", "App default") }
    var create: String { t("Criar", "Create") }
    var save: String { t("Salvar", "Save") }
    var cancel: String { t("Cancelar", "Cancel") }

    // Configurações
    var settings: String { t("Configurações", "Settings") }
    var launchAtLogin: String { t("Iniciar com o sistema", "Launch at login") }
    var appearance: String { t("Aparência", "Appearance") }
    var appearanceSystem: String { t("Sistema", "System") }
    var appearanceLight: String { t("Claro", "Light") }
    var appearanceDark: String { t("Escuro", "Dark") }
    var languageLabel: String { t("Idioma", "Language") }
    var defaultSoundLabel: String { t("Som padrão", "Default sound") }
    var showCountdown: String { t("Contagem na barra de menus", "Countdown in menu bar") }
    var checkUpdates: String { t("Verificar atualizações…", "Check for updates…") }
    var upToDate: String { t("Você já está na versão mais recente.", "You're on the latest version.") }
    func updateAvailable(_ v: String) -> String { t("Nova versão \(v) disponível!", "New version \(v) available!") }
    var download: String { t("Baixar", "Download") }
    var updateError: String { t("Não foi possível verificar agora.", "Couldn't check right now.") }

    // Sobre
    var about: String { t("Sobre o Cooldown", "About Cooldown") }
    var developedBy: String { t("Desenvolvido com ☕ por", "Developed with ☕ by") }
    var aboutText: String {
        t("A Salto Solutions cria soluções digitais sob medida — automações com IA, apps, sites e sistemas para o seu negócio. Precisa de algo assim? Fale com a gente!",
          "Salto Solutions builds tailor-made digital solutions — AI automations, apps, websites and systems for your business. Need something like this? Talk to us!")
    }
    var visitSite: String { t("Visitar salto.solutions", "Visit salto.solutions") }

    // Doações
    // Mantido em inglês nos dois idiomas — "Buy me a coffee" é o termo
    // consagrado para doação em apps indie.
    var donate: String { "Buy me a coffee ☕" }
    var donateSubtitle: String {
        t("O Cooldown é gratuito. Se ele te ajuda, um cafezinho mantém as atualizações vindo. 💙",
          "Cooldown is free. If it helps you, a coffee keeps the updates coming. 💙")
    }
    var donateCard: String { t("Doar com cartão (Stripe)", "Donate with card (Stripe)") }
    var donatePix: String { t("Doar via Pix (Mercado Pago)", "Donate via Pix (Mercado Pago)") }
    var copyPix: String { t("Copiar código Pix", "Copy Pix code") }
    var copied: String { t("Copiado!", "Copied!") }
    var donateSoon: String { t("Links de doação em breve", "Donation links coming soon") }

    // Notificação
    func notificationTitle(_ name: String) -> String { t("\(name) liberado! 🎉", "\(name) is ready! 🎉") }
    var notificationBody: String { t("Seu limite resetou. Bora voltar ao trabalho!", "Your limit has reset. Back to work!") }
    var notificationRearm: String { t("Comecei agora — novo ciclo", "Starting now — new cycle") }
}
