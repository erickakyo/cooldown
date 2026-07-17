import Foundation

/// Constantes de configuração do app. Links de doação e repositório de
/// releases são preenchidos pela Salto Solutions antes do release público.
enum AppConfig {
    static let appName = "Cooldown"
    static let bundleID = "solutions.salto.cooldown"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    static let website = URL(string: "https://salto.solutions")!

    /// Link do site com UTM: permite medir no Google Analytics quantos
    /// acessos vieram da tela Sobre do app.
    static let websiteFromAbout = URL(
        string: "https://salto.solutions/?utm_source=cooldown&utm_medium=app&utm_campaign=about"
    )!

    // Doações — preencher com os links reais (Stripe Payment Link / Mercado Pago).
    // Enquanto contiverem "PREENCHER", os botões ficam desabilitados na UI.
    static let stripeDonationURL = "https://buy.stripe.com/28EdR25Jsffg3pu3zYd7q00"
    static let mercadoPagoDonationURL = "https://link.mercadopago.com.br/cooldown"
    static let pixCopyPasteCode = "499817ae-9dcd-4bc4-96df-67bbef4a96f6"

    // Checagem de atualização via GitHub Releases (owner/repo).
    // Nota: o update checker só funciona quando o repositório for público.
    static let githubRepo = "erickakyo/cooldown"
    static var releasesPageURL: URL { URL(string: "https://github.com/\(githubRepo)/releases/latest")! }
    static var latestReleaseAPI: URL { URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest")! }

    static func isPlaceholder(_ value: String) -> Bool {
        value.contains("PREENCHER")
    }
}
