import SwiftUI
import KangChargeCore

/// GitHub-contribution-style daily energy heatmap view.
/// Keeps cells crisp and restrained (capped by `maxCellSize`) across macOS windows, iOS lists, and WidgetKit.
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

    private var columns: [[EnergyDay]] {
        let count = summary.days.count
        guard count > 0 else { return [] }
        var result: [[EnergyDay]] = []
        var index = 0
        while index < count {
            let end = min(index + 7, count)
            result.append(Array(summary.days[index..<end]))
            index = end
        }
        return result
    }

    private var scaleMaxWh: Double {
        max(summary.peakWattHours, 180)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showHeader {
                headerRow
            }

            grid

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

    private var grid: some View {
        let cols = columns
        let colCount = max(cols.count, 1)
        return GeometryReader { geo in
            let totalHSpacing = cellSpacing * CGFloat(max(colCount - 1, 0))
            let fitWidth = (geo.size.width - totalHSpacing) / CGFloat(colCount)
            let cellSize = max(5, min(maxCellSize, floor(fitWidth * 2) / 2))

            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(Array(cols.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: cellSpacing) {
                        ForEach(week) { day in
                            cellView(for: day, size: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 7 * maxCellSize + 6 * cellSpacing)
    }

    @ViewBuilder
    private func cellView(for day: EnergyDay, size: CGFloat) -> some View {
        let level = day.level(maxWattHours: scaleMaxWh)
        let isSelected = selectedDay?.id == day.id
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let base = shape
            .fill(KCStyle.heatmapColor(level: level, tint: tint, colorScheme: colorScheme))
            .frame(width: size, height: size)
            .overlay {
                if isSelected {
                    shape.strokeBorder(Color.primary.opacity(0.65), lineWidth: 1)
                }
            }
            .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(KCFormat.energy(wattHours: day.wattHours))")

        if interactive {
            base
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedDay = (selectedDay?.id == day.id) ? nil : day
                    }
                }
                #if os(macOS)
                .onHover { hovering in
                    if hovering {
                        selectedDay = day
                    } else if selectedDay?.id == day.id {
                        selectedDay = nil
                    }
                }
                #endif
        } else {
            base
        }
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
