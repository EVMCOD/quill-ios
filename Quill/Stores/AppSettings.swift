import SwiftUI
import Foundation

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @AppStorage("app.quill.hasOnboarded") public var hasOnboarded: Bool = false
    @AppStorage("app.quill.appearance")   public var appearanceRaw: String = "system"

    public var appearance: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    public func setAppearance(_ v: Appearance) {
        appearanceRaw = v.rawValue
    }

    public enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        public var id: String { rawValue }
        public var label: String { rawValue.capitalized }
    }
}
