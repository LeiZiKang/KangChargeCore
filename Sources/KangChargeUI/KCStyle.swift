import SwiftUI
import KangChargeCore

/// Restrained Apple-native minimalist design tokens shared across macOS, iOS, watchOS, and widgets.
public enum KCStyle {
    /// Warm restrained amber-orange used sparingly for hero power and active selection.
    public static let accent = Color(red: 0.96, green: 0.44, blue: 0.14)
    /// Apple-style vibrant green for "actively delivering power" and online indicators.
    public static let charging = Color(red: 0.19, green: 0.78, blue: 0.35)
    public static let caution = Color(red: 1.0, green: 0.62, blue: 0.04)
    public static let hot = Color(red: 0.96, green: 0.26, blue: 0.21)

    public static func portTint(for port: PortSnapshot) -> Color {
        if !port.enabled { return .secondary.opacity(0.45) }
        return port.isCharging ? charging : .secondary
    }

    public static func temperatureColor(_ raw: String?) -> Color {
        switch raw?.lowercased() {
        case "cool": return charging
        case "moderate": return caution
        case "warm": return hot
        default: return .secondary
        }
    }

    /// 5-step Apple-restrained heatmap intensity colors (level 0...4).
    public static func heatmapColor(level: Int, tint: Color = charging, colorScheme: ColorScheme) -> Color {
        switch level {
        case 0:
            return colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
        case 1:
            return tint.opacity(colorScheme == .dark ? 0.30 : 0.25)
        case 2:
            return tint.opacity(colorScheme == .dark ? 0.52 : 0.48)
        case 3:
            return tint.opacity(colorScheme == .dark ? 0.76 : 0.72)
        default:
            return tint
        }
    }
}

public enum KCFormat {
    /// "58.2" below 100 W, "140" at/above 100 W, "0" at zero.
    public static func watts(_ value: Double) -> String {
        if value >= 100 || value < 0.05 { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }

    public static func volts(_ value: Double) -> String {
        value >= 10 ? String(format: "%.1f V", value) : String(format: "%.2f V", value)
    }

    public static func amps(_ value: Double) -> String {
        String(format: "%.2f A", value)
    }

    public static func energy(wattHours wh: Double) -> String {
        if wh >= 1000 { return String(format: "%.2f kWh", wh / 1000) }
        if wh >= 100 { return String(format: "%.0f Wh", wh) }
        if wh >= 1 { return String(format: "%.1f Wh", wh) }
        return "0 Wh"
    }

    public static func energy(mWh: Double) -> String {
        if mWh < 1000 && mWh > 0 { return String(format: "%.0f mWh", mWh) }
        return energy(wattHours: mWh / 1000)
    }

    public static func protocolTag(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let upper = raw.uppercased()
        for tag in ["PPS", "EPR", "PD", "FCP", "SCP", "AFC"] where upper.contains(tag) { return tag }
        if upper.contains("QC") || upper.contains("QUICK") { return "QC" }
        if upper.contains("LEGACY") || upper.contains("BC") { return "BC 1.2" }
        if upper.contains("APPLE") { return "Apple" }
        return raw.split(separator: " ").first.map(String.init)
    }

    public static func portDisplayName(_ port: PortSnapshot) -> String {
        port.connector == "A" && port.name == "A" ? "USB-A" : port.name
    }

    public static func portBadgeName(_ port: PortSnapshot) -> String {
        port.connector == "A" ? "A" : port.name
    }
}

/// Thin capsule progress bar for total load and per-port load.
public struct KCLoadBar: View {
    public var fraction: Double
    public var color: Color
    public var height: CGFloat

    public init(fraction: Double, color: Color = KCStyle.accent, height: CGFloat = 6) {
        self.fraction = fraction
        self.color = color
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(fraction, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(color)
                    .frame(width: clamped > 0 ? max(height, proxy.size.width * clamped) : 0)
            }
        }
        .frame(height: height)
    }
}
