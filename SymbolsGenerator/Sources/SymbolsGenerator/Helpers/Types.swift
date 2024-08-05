import Foundation

/// The base symbol when scanned from the manifest
struct ScannedSymbol: Hashable {
    var name: String
    var availability: Availability
}

/// The symbol data type containing all versions for one specific symbol
struct Symbol: Hashable {
    var name: String
    var restriction: String?
    var preview: String?
    var availability: Availability
    var isBaseLocalizationAvailable: Bool
    var availableLocalizations: [Availability: Set<Localization>]
    var availableLayersets: [Availability: Set<String>]
    var olderSymbol: ScannedSymbol?
    var newerSymbol: ScannedSymbol?

    var propertyName: String { name.toPropertyName }
}

struct Availability: Comparable, Equatable, Hashable {
    var iOS: VersionString
    var tvOS: VersionString
    var watchOS: VersionString
    var visionOS: VersionString
    private var _macOS: VersionString
    var year: String // E. g. "2020" or "2020.1"

    var isBase: Bool { version == "1.0" }
    var macOS: VersionString { _macOS.rawValue == "10.15" ? .init(rawValue: "11.0") : _macOS }

    var version: String {
        let ver = Decimal(string: "1.0")! + (Decimal(string: year)! - Decimal(string: "2019")!)
        return String(format: "%.1f", NSDecimalNumber(decimal: ver).doubleValue)
    }

    var versionUnderscored: String { version.replacingOccurrences(of: ".", with: "_") }

    static private(set) var base: Availability!

    /// Convert into an expression than can be used in code when prefixed with either `#` or `@`.
    var availableExpression: String {
        "available(iOS \(iOS), macOS \(macOS), tvOS \(tvOS), watchOS \(watchOS), visionOS \(visionOS), *)"
    }

    /// Convert into an expression than can be used in code when prefixed with either `#` or `@`.
    /// Availability specifications which are not strictly more restrictive than `Availability.base` are dropped.
    var availableExpressionWithoutRedundancyToBase: String {
        "available(" +
        (iOS > Availability.base.iOS ? "iOS \(iOS), " : "") +
        (macOS > Availability.base.macOS ? "macOS \(macOS), " : "") +
        (tvOS > Availability.base.tvOS ? "tvOS \(tvOS), " : "") +
        (watchOS > Availability.base.watchOS ? "watchOS \(watchOS), " : "") +
        (visionOS > Availability.base.visionOS ? "visionOS \(visionOS), " : "") +
        "*)"
    }

    init(iOS: String, macOS: String, tvOS: String, watchOS: String, visionOS: String, year: String) {
        self.iOS = .init(rawValue: iOS)
        self._macOS = .init(rawValue: macOS)
        self.tvOS = .init(rawValue: tvOS)
        self.watchOS = .init(rawValue: watchOS)
        self.visionOS = .init(rawValue: visionOS)
        self.year = year

        if isBase { Availability.base = self }
    }

    static func < (lhs: Availability, rhs: Availability) -> Bool {
        // The `orderedDescending` is intentional, because the availability is smaller when the year is higher
        return lhs.year.compare(rhs.year, options: .numeric) == .orderedDescending
    }

    static func > (lhs: Availability, rhs: Availability) -> Bool {
        return lhs.year.compare(rhs.year, options: .numeric) == .orderedAscending
    }

    static func == (lhs: Availability, rhs: Availability) -> Bool {
        return lhs.year == rhs.year
    }
}

/// A single layerset availability specification when scanned from the layerset plist
struct LayersetAvailability {
    var name: String
    var availability: Availability
}

struct VersionString: RawRepresentable, Comparable, Hashable, CustomStringConvertible {

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String {
        return rawValue
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue.compare(rhs.rawValue, options: .numeric) == .orderedSame
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue.compare(rhs.rawValue, options: .numeric) == .orderedAscending
    }
}

enum Localization: String, Hashable, CaseIterable {
    case ar = "ar"
    case he = "he"
    case hi = "hi"
    case ja = "ja"
    case km = "km"
    case ko = "ko"
    case my = "my"
    case rtl = "rtl"
    case th = "th"
    case zh = "zh"

    var title: String {
        switch self {
            case .ar: return "Arabic"
            case .he: return "Hebrew"
            case .hi: return "Hindi"
            case .ja: return "Japanese"
            case .km: return "Central Khmer"
            case .ko: return "Korean"
            case .my: return "Burmese"
            case .rtl: return "Right-to-Left"
            case .th: return "Thai"
            case .zh: return "Chinese"
        }
    }
    /// The name for a variable exposing this localization, e.g. "zhTraditional".
    var variableName: String {
        decapFirst(noDots(rawValue.capitalized))
    }

    /// The name for the SymbolLocalization struct exposing this localization for the base availability.
    /// E.g. "Ar".
    var baseStructName: String {
        noDots(rawValue.capitalized)
    }

    /// The name for the SymbolLocalization struct exposing this localization given a specific (or base) availability.
    /// E.g. "Ar_v2" or "Ar_v2_0".
    func structName(for availability: Availability) -> String {
        // Remove (possibly multiple) ".0"s from the ending
        var version = String(availability.version.reversed().drop(while: [".", "0"].contains).reversed())
        version = version.replacingOccurrences(of: ".", with: "_")
        let availabilitySuffix = availability.isBase ? "" : ("_v" + version)
        return baseStructName + availabilitySuffix
    }
}

private let noDots: (String) -> String = { $0.replacingOccurrences(of: ".", with: "") }
private let decapFirst: (String) -> String = { String($0.prefix(1)).lowercased() + String($0.dropFirst()) }
