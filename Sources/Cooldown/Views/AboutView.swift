import SwiftUI

struct AboutView: View {
    @EnvironmentObject var settings: AppSettings
    var onDone: () -> Void

    private var l: L { L(settings.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Hero: ícone real do app + nome + versão + tagline
                AppIconGlyph(size: 68)
                    .shadow(color: Color(red: 0.08, green: 0.25, blue: 0.65).opacity(0.35),
                            radius: 10, y: 4)
                    .padding(.top, 16)

                VStack(spacing: 6) {
                    Text(AppConfig.appName)
                        .font(.title2.weight(.bold))

                    Text("v\(AppConfig.version)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(.quaternary))

                    Text(l.tagline)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 4)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 4) {
                            Text(l.developedBy)
                                .foregroundStyle(.secondary)
                            Text("Salto Solutions")
                                .fontWeight(.semibold)
                        }
                        .font(.callout)

                        Text(l.aboutText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            NSWorkspace.shared.open(AppConfig.websiteFromAbout)
                        } label: {
                            Label(l.visitSite, systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassPillButtonStyle(prominent: true))
                    }
                }
                .padding(.horizontal, 14)

                Text("© 2026 Salto Solutions")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 12)
            }
        }
    }
}
