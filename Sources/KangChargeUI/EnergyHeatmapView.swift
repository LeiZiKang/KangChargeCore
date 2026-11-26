import SwiftUI
import KangChargeCore

/// GitHub-contribution-style daily energy heatmap view.
/// Uses a single SwiftUI Canvas + continuous hover/tap coordinate mapping so even a full
/// 44-week grid renders in <2 ms in Xcode Previews, live windows, and WidgetKit timelines.
public struct EnergyHeatmapView: View {
    public let summary: EnergySummary
    public var tint: Color
    public var cellSpacing: CGFloat
    public var cornerRadius: CGFloat
    public var maxCellSize: CGFloat
    public var interactive: Bool
    public var showLegend: Bool
    public var showHeader: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDay: EnergyDay?

    public init(
        summary: EnergySummary,
        tint: Color = KCStyle.charging,
        cellSpacing: CGFloat = 3.5,
        cornerRadius: CGFloat = 3,
        maxCellSize: CGFloat = 13,
        interactive: Bool = true,
        showLegend: Bool = true,
        showHeader: Bool = true
    ) {
        self.summary = summary
        self.tint = tint
        self.cellSpacing = cellSpacing
        self.cornerRadius = cornerRadius
        self.maxCellSize = maxCellSize
        self.interactive = interactive
        self.showLegend = showLegend
        self.showHeader = showHeader
    }

    private var colCount: Int {
        max(1, (summary.days.count + 6) / 7)
    }

    private var scaleMaxWh: Double {
        max(summary.peakWattHours, 180)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showHeader {
                headerRow
            }

            heatmapCanvas

            if showLegend {
                legendRow
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let selectedDay {
                Text(selectedDay.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(KCFormat.energy(wattHours: selectedDay.wattHours))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            } else {
                let zh = Locale.kcPrefersChinese
                Text(zh ? "今日 \(KCFormat.energy(wattHours: summary.todayWattHours))" : "Today \(KCFormat.energy(wattHours: summary.todayWattHours))")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(zh ? "近 7 天 \(KCFormat.energy(wattHours: summary.last7DaysWattHours))" : "7d \(KCFormat.energy(wattHours: summary.last7DaysWattHours))")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if summary.currentStreak > 0 {
                let zh = Locale.kcPrefersChinese
                Text(zh ? "连续 \(summary.currentStreak) 天" : "\(summary.currentStreak)d streak")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func cellSize(for width: CGFloat) -> CGFloat {
        let totalHSpacing = cellSpacing * CGFloat(max(colCount - 1, 0))
        let fitWidth = (width - totalHSpacing) / CGFloat(colCount)
        return max(5, min(maxCellSize, floor(fitWidth * 2) / 2))
    }

    private func day(at point: CGPoint, width: CGFloat) -> EnergyDay? {
        let size = cellSize(for: width)
        let stride = size + cellSpacing
        guard stride > 0 else { return nil }
        let col = Int(point.x / stride)
        let row = Int(point.y / stride)
        guard col >= 0, col < colCount, row >= 0, row < 7 else { return nil }
        let idx = col * 7 + row
        guard idx >= 0, idx < summary.days.count else { return nil }
        return summary.days[idx]
    }

    private var heatmapCanvas: some View {
        let days = summary.days
        let maxWh = scaleMaxWh
        let cols = colCount
        let selectedID = selectedDay?.id
        let scheme = colorScheme
        let palette = (0..<5).map { KCStyle.heatmapColor(level: $0, tint: tint, colorScheme: scheme) }
        let highlightStroke = Color.primary.opacity(0.65)

        return GeometryReader { geo in
            let size = cellSize(for: geo.size.width)
            let stride = size + cellSpacing

            let canvas = Canvas { context, _ in
                for idx in days.indices {
                    let col = idx / 7
                    let row = idx % 7
                    guard col < cols else { continue }
                    let day = days[idx]
                    let level = day.level(maxWattHours: maxWh)
                    let rect = CGRect(x: CGFloat(col) * stride, y: CGFloat(row) * stride, width: size, height: size)
                    let path = Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
                    context.fill(path, with: .color(palette[min(max(level, 0), 4)]))
                    if day.id == selectedID {
                        context.stroke(path, with: .color(highlightStroke), lineWidth: 1.2)
                    }
                }
            }

            if interactive {
                canvas
                    .contentShape(Rectangle())
                    #if os(macOS) || os(iOS)
                    .onTapGesture { location in
                        let hit = day(at: location, width: geo.size.width)
                        selectedDay = (hit?.id == selectedDay?.id) ? nil : hit
                    }
                    #endif
                    #if os(macOS)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            selectedDay = day(at: location, width: geo.size.width)
                        case .ended:
                            selectedDay = nil
                        }
                    }
                    #endif
            } else {
                canvas
            }
        }
        .frame(height: 7 * maxCellSize + 6 * cellSpacing)
    }

    private var legendRow: some View {
        HStack(spacing: 4) {
            let zh = Locale.kcPrefersChinese
            Text(zh ? "合计 \(KCFormat.energy(wattHours: summary.totalWattHours))" : "Total \(KCFormat.energy(wattHours: summary.totalWattHours))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer()
            Text(zh ? "少" : "Less")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(KCStyle.heatmapColor(level: level, tint: tint, colorScheme: colorScheme))
                    .frame(width: 9, height: 9)
            }
            Text(zh ? "多" : "More")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
