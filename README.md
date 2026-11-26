# KangChargeCore

Shared Swift Package powering [Kang Charge for macOS](https://github.com/LeiZiKang/KangCharge) and [Kang Charge for iOS & watchOS](https://github.com/LeiZiKang/KangCharge-iOS).

## Modules

- **`KangChargeCore`**: HTTP+SSE MCP client for CANDYSIGN `ionbridge-mcp`, typed models, Keychain & App Group storage, and `EnergyLedger` (hardware `session_charge_mwh` daily energy accumulator with optional iCloud KVS cross-device sync).
- **`KangChargeUI`**: Shared restrained Apple-native SwiftUI design tokens, number formatters, load bars, and `EnergyHeatmapView` (GitHub-contribution-style daily energy grid).

## Platforms

- macOS 14+
- iOS 17+
- watchOS 10+

## License

[MIT](LICENSE)
