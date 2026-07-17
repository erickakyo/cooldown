import SwiftUI

/// Cartão de um timer na lista principal.
struct TimerRowView: View {
    @EnvironmentObject var store: TimerStore
    @EnvironmentObject var settings: AppSettings
    let timer: AITimer
    var onEdit: () -> Void

    private var l: L { L(settings.language) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ServiceIconView(serviceID: timer.serviceID, fallbackSymbol: timer.symbol, size: 16)
                    Text(timer.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if timer.autoRepeat {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .help(l.autoRepeat)
                    }
                    Spacer()
                    menuButton
                }

                switch timer.state {
                case .running:
                    runningBody
                case .ready:
                    readyBody
                case .idle:
                    idleBody
                }
            }
        }
    }

    private var runningBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(AITimer.formatRemaining(timer.remaining))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                if let reset = timer.resetDate {
                    Text(reset, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
        }
    }

    private var readyBody: some View {
        HStack {
            Label(l.ready, systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)
            Spacer()
            Button(l.newCycle(shortDuration)) { store.rearm(id: timer.id) }
                .buttonStyle(GlassPillButtonStyle(prominent: true))
            Button(l.adjust) { onEdit() }
                .buttonStyle(GlassPillButtonStyle())
        }
    }

    private var idleBody: some View {
        HStack {
            Text(l.idle)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button(l.newCycle(shortDuration)) { store.rearm(id: timer.id) }
                .buttonStyle(GlassPillButtonStyle(prominent: true))
        }
    }

    private var menuButton: some View {
        Menu {
            Button(l.adjust, systemImage: "pencil") { onEdit() }
            if timer.state == .running {
                Button(l.stop, systemImage: "stop.circle") { store.stop(id: timer.id) }
            }
            Divider()
            Button(l.delete, systemImage: "trash", role: .destructive) {
                store.remove(id: timer.id)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var progress: Double {
        guard timer.windowDuration > 0 else { return 0 }
        return min(1, max(0, 1 - timer.remaining / timer.windowDuration))
    }

    private var shortDuration: String {
        let h = Int(timer.windowDuration) / 3600
        let m = (Int(timer.windowDuration) % 3600) / 60
        if m == 0 { return "\(h)h" }
        return h > 0 ? "\(h)h\(m)" : "\(m)min"
    }
}
