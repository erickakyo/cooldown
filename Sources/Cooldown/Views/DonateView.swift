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

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .padding(.top, 8)

            Text(l.donateSubtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            GlassCard {
                VStack(spacing: 10) {
                    // Brasil primeiro quando o idioma é PT; cartão primeiro em EN.
                    if settings.language == .pt {
                        pixButtons
                        cardButton
                    } else {
                        cardButton
                        pixButtons
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

            Spacer(minLength: 12)
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

    @ViewBuilder
    private var pixButtons: some View {
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

        if !AppConfig.isPlaceholder(AppConfig.pixCopyPasteCode) {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(AppConfig.pixCopyPasteCode, forType: .string)
                feedback.copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak feedback] in
                    feedback?.copied = false
                }
            } label: {
                Label(feedback.copied ? l.copied : l.copyPix,
                      systemImage: feedback.copied ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassPillButtonStyle())
        }
    }

    private var allPlaceholders: Bool {
        AppConfig.isPlaceholder(AppConfig.stripeDonationURL)
            && AppConfig.isPlaceholder(AppConfig.mercadoPagoDonationURL)
    }
}
