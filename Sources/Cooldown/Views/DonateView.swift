import SwiftUI

/// Feedback do botão de copiar Pix. (Classe em vez de @State — sem plugin de macros nas CLT.)
final class CopyFeedbackModel: ObservableObject {
    @Published var copied = false
}

struct DonateView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var feedback = CopyFeedbackModel()
    var onDone: () -> Void

    private var l: L { L(settings.language) }

    // Tons de café, para o hero desta tela ter identidade própria
    // (o azul-gelo fica com a marca; doação é quente e acolhedora).
    private static let coffeeLight = Color(red: 0.93, green: 0.58, blue: 0.22)
    private static let coffeeDark = Color(red: 0.52, green: 0.28, blue: 0.10)

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Hero: xícara sobre gradiente quente, mesmo formato do ícone do app
                RoundedRectangle(cornerRadius: 68 * 0.225, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Self.coffeeLight, Self.coffeeDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Self.coffeeDark.opacity(0.35), radius: 10, y: 4)
                    .padding(.top, 16)

                Text(l.donateSubtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                GlassCard {
                    VStack(spacing: 10) {
                        // Brasil primeiro quando o idioma é PT; cartão primeiro em EN.
                        if settings.language == .pt {
                            pixButton
                            cardButton
                        } else {
                            cardButton
                            pixButton
                        }
                        if allPlaceholders {
                            Text(l.donateSoon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 14)

                if !AppConfig.isPlaceholder(AppConfig.pixCopyPasteCode) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(l.pixKeyLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Text(AppConfig.pixCopyPasteCode)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 4)
                                Button {
                                    copyPixKey()
                                } label: {
                                    Label(feedback.copied ? l.copied : l.copyPix,
                                          systemImage: feedback.copied ? "checkmark" : "doc.on.doc")
                                }
                                .buttonStyle(GlassPillButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }

                Text(l.donateThanks)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
            }
        }
    }

    private var cardButton: some View {
        Button {
            if let url = URL(string: AppConfig.stripeDonationURL) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Label(l.donateCard, systemImage: "creditcard")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassPillButtonStyle(prominent: settings.language == .en))
        .disabled(AppConfig.isPlaceholder(AppConfig.stripeDonationURL))
    }

    private var pixButton: some View {
        Button {
            if let url = URL(string: AppConfig.mercadoPagoDonationURL) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Label(l.donatePix, systemImage: "qrcode")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassPillButtonStyle(prominent: settings.language == .pt))
        .disabled(AppConfig.isPlaceholder(AppConfig.mercadoPagoDonationURL))
    }

    private func copyPixKey() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(AppConfig.pixCopyPasteCode, forType: .string)
        feedback.copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak feedback] in
            feedback?.copied = false
        }
    }

    private var allPlaceholders: Bool {
        AppConfig.isPlaceholder(AppConfig.stripeDonationURL)
            && AppConfig.isPlaceholder(AppConfig.mercadoPagoDonationURL)
    }
}
