import SwiftUI

struct AboutView: View {
    @EnvironmentObject var settings: AppSettings
    var onDone: () -> Void

    private var l: L { L(settings.language) }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
                .padding(.top, 8)

            VStack(spacing: 2) {
                Text(AppConfig.appName)
                    .font(.title2.weight(.bold))
                Text("v\(AppConfig.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
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
                    }
                    .buttonStyle(GlassPillButtonStyle(prominent: true))
                }
            }
            .padding(.horizontal, 14)

            Spacer(minLength: 12)
        }
    }
}
