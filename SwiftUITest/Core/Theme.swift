//
//  Theme.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI
import UIKit
import Observation

typealias Theme = ThemeManager

// MARK: - 1. THEME MANAGER (edit palette / font family here)
enum AppAppearance: String, CaseIterable {
    case system, light, dark
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var palette: ThemePalette = .default
    /// nil = system font. Set e.g. "Poppins" to use Poppins-Regular, Poppins-Medium...
    var fontFamily: String? = nil
    private(set) var appearance: AppAppearance

    private init() {
        appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "") ?? .system
    }

    func setAppearance(_ a: AppAppearance) {
        appearance = a
        UserDefaults.standard.set(a.rawValue, forKey: "appearance")
    }
}

// MARK: - 2. TOKENS (enums you pass into modifiers)
enum AppFontWeight {
    case light, regular, medium, semibold, bold, heavy
    var systemWeight: Font.Weight {
        switch self {
        case .light: .light; case .regular: .regular; case .medium: .medium
        case .semibold: .semibold; case .bold: .bold; case .heavy: .heavy
        }
    }
    /// Suffix of your custom font file. Change if your font names differ.
    var suffix: String {
        switch self {
        case .light: "Light"; case .regular: "Regular"; case .medium: "Medium"
        case .semibold: "SemiBold"; case .bold: "Bold"; case .heavy: "ExtraBold"
        }
    }
}

enum AppTextStyle {
    case largeTitle, title, headline, body, callout, caption
    var spec: (weight: AppFontWeight, size: CGFloat) {
        switch self {
        case .largeTitle: (.bold, 32)
        case .title:      (.semibold, 24)
        case .headline:   (.semibold, 18)
        case .body:       (.regular, 16)
        case .callout:    (.medium, 14)
        case .caption:    (.regular, 12)
        }
    }
}

enum AppColor { case brand, brandSecondary, bg, surface, textPrimary, textSecondary, border, success, warning, error
    var color: Color { Theme.shared.palette.color(for: self) }
}

enum AppSpacing: CGFloat { case xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48 }
enum AppRadius: CGFloat { case sm = 8, md = 12, lg = 16, xl = 24, full = 999 }

enum AppShadow {
    case none, soft, medium, strong
    var p: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .none: (0, 0, 0); case .soft: (0.06, 8, 2)
        case .medium: (0.12, 14, 4); case .strong: (0.2, 24, 8)
        }
    }
}

struct ThemePalette {
    var brand, brandSecondary, bg, surface, textPrimary, textSecondary, border, success, warning, error: Color

    func color(for c: AppColor) -> Color {
        switch c {
        case .brand: brand; case .brandSecondary: brandSecondary; case .bg: bg
        case .surface: surface; case .textPrimary: textPrimary; case .textSecondary: textSecondary
        case .border: border; case .success: success; case .warning: warning; case .error: error
        }
    }

    // Each color is (light, dark), so dark mode works automatically
    static let `default` = ThemePalette(
        brand:         Color(light: "#4F46E5", dark: "#818CF8"),
        brandSecondary:Color(light: "#EEF2FF", dark: "#312E81"),
        bg:            Color(light: "#F8FAFC", dark: "#0B0F19"),
        surface:       Color(light: "#FFFFFF", dark: "#161B26"),
        textPrimary:   Color(light: "#0F172A", dark: "#F1F5F9"),
        textSecondary: Color(light: "#64748B", dark: "#94A3B8"),
        border:        Color(light: "#E2E8F0", dark: "#2A3140"),
        success:       Color(light: "#16A34A", dark: "#4ADE80"),
        warning:       Color(light: "#D97706", dark: "#FBBF24"),
        error:         Color(light: "#DC2626", dark: "#F87171")
    )
}

// MARK: - 3. CORE EXTENSIONS
extension Font {
    static func app(_ weight: AppFontWeight, _ size: CGFloat) -> Font {
        if let family = Theme.shared.fontFamily { return .custom("\(family)-\(weight.suffix)", size: size) }
        return .system(size: size, weight: weight.systemWeight)
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (v >> 8) * 17, (v >> 4 & 0xF) * 17, (v & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, v >> 16, v >> 8 & 0xFF, v & 0xFF)
        case 8:  (a, r, g, b) = (v >> 24, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    init(light: Color, dark: Color) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
    init(light: String, dark: String) { self.init(light: Color(hex: light), dark: Color(hex: dark)) }
}

extension View {
    // Fonts:  .font(.medium, 24)  |  .textStyle(.title)
    func font(_ weight: AppFontWeight, _ size: CGFloat) -> some View { font(Font.app(weight, size)) }
    func textStyle(_ s: AppTextStyle) -> some View { font(Font.app(s.spec.weight, s.spec.size)) }

    // Colors:  .foreground(.brand)  |  .bgColor(.surface)  |  .screenBackground()
    func foreground(_ c: AppColor) -> some View { foregroundStyle(c.color) }
    func bgColor(_ c: AppColor) -> some View { background(c.color) }
    func screenBackground(_ c: AppColor = .bg) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity).background(c.color.ignoresSafeArea())
    }

    // Layout:  .padding(.md)  |  .padding(.horizontal, .lg)  |  .rounded(.lg)
    func padding(_ s: AppSpacing) -> some View { padding(s.rawValue) }
    func padding(_ edges: Edge.Set, _ s: AppSpacing) -> some View { padding(edges, s.rawValue) }
    func rounded(_ r: AppRadius = .md) -> some View { clipShape(RoundedRectangle(cornerRadius: r.rawValue)) }
    func outline(_ c: AppColor = .border, width: CGFloat = 1, radius: AppRadius = .md) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius.rawValue).stroke(c.color, lineWidth: width))
    }
    func shadow(_ s: AppShadow) -> some View {
        shadow(color: .black.opacity(s.p.opacity), radius: s.p.radius, x: 0, y: s.p.y)
    }
    func card(inset: AppSpacing = .md, radius: AppRadius = .lg, elevation: AppShadow = .soft) -> some View {
        self.padding(inset).background(AppColor.surface.color).rounded(radius).shadow(elevation)
    }

    // Utilities
    @ViewBuilder func `if`<T: View>(_ condition: Bool, _ transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
    func onFirstAppear(_ action: @escaping () -> Void) -> some View { modifier(OnFirstAppear(action: action)) }
    func onTap(haptic: Bool = true, perform: @escaping () -> Void) -> some View {
        contentShape(Rectangle()).onTapGesture { if haptic { Haptic.impact() }; perform() }
    }
    func onTapHideKeyboard() -> some View { onTapGesture { UIApplication.hideKeyboard() } }
    func loading(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView().padding(.lg).background(.regularMaterial).rounded(.lg)
                }
            }
        }
    }
    func errorAlert(_ message: Binding<String?>, title: String = "Error") -> some View {
        alert(title, isPresented: Binding(get: { message.wrappedValue != nil },
                                          set: { if !$0 { message.wrappedValue = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message.wrappedValue ?? "") }
    }
    /// Apply once on your root view: applies appearance override + tint
    func themed() -> some View { modifier(ThemedRoot()) }
}

private struct OnFirstAppear: ViewModifier {
    let action: () -> Void
    @State private var done = false
    func body(content: Content) -> some View {
        content.onAppear { guard !done else { return }; done = true; action() }
    }
}

private struct ThemedRoot: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(Theme.shared.appearance.colorScheme)
            .tint(AppColor.brand.color)
    }
}

// MARK: - 4. BUTTONS
enum AppButtonKind { case primary, secondary, outline, text, destructive }

struct AppButtonStyle: ButtonStyle {
    var kind: AppButtonKind = .primary
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled

    private var fg: AppColor {
        switch kind {
        case .primary, .destructive: .surface   // text on filled buttons
        case .secondary, .outline, .text: .brand
        }
    }
    private var bg: Color {
        switch kind {
        case .primary: AppColor.brand.color
        case .secondary: AppColor.brandSecondary.color
        case .destructive: AppColor.error.color
        case .outline, .text: .clear
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.semibold, 16)
            .foreground(fg)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, .md)
            .padding(.horizontal, .lg)
            .background(bg)
            .rounded(.md)
            .if(kind == .outline) { $0.outline(.brand) }
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static var primary: AppButtonStyle { .init(kind: .primary) }
    static var secondary: AppButtonStyle { .init(kind: .secondary) }
    static var outline: AppButtonStyle { .init(kind: .outline) }
    static var text: AppButtonStyle { .init(kind: .text, fullWidth: false) }
    static var destructive: AppButtonStyle { .init(kind: .destructive) }
}

/// Ready-made button with loading + icon:  AppButton("Login", isLoading: vm.loading) { ... }
struct AppButton: View {
    let title: String
    var kind: AppButtonKind
    var icon: String?
    var isLoading: Bool
    var fullWidth: Bool
    let action: () -> Void

    init(_ title: String, kind: AppButtonKind = .primary, icon: String? = nil,
         isLoading: Bool = false, fullWidth: Bool = true, action: @escaping () -> Void) {
        self.title = title; self.kind = kind; self.icon = icon
        self.isLoading = isLoading; self.fullWidth = fullWidth; self.action = action
    }

    var body: some View {
        Button { Haptic.impact(); action() } label: {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(.white) }
                else if let icon { Image(systemName: icon) }
                Text(title)
            }
        }
        .buttonStyle(AppButtonStyle(kind: kind, fullWidth: fullWidth))
        .disabled(isLoading)
    }
}

// MARK: - 5. TEXT FIELD (handles icon, secure toggle, focus + error border)
struct AppTextField: View {
    let title: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool
    var error: String?
    var keyboard: UIKeyboardType

    @State private var reveal = false
    @FocusState private var focused: Bool

    init(_ title: String, text: Binding<String>, icon: String? = nil, isSecure: Bool = false,
         error: String? = nil, keyboard: UIKeyboardType = .default) {
        self.title = title; self._text = text; self.icon = icon
        self.isSecure = isSecure; self.error = error; self.keyboard = keyboard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).foreground(.textSecondary) }
                Group {
                    if isSecure && !reveal { SecureField(title, text: $text) }
                    else { TextField(title, text: $text).keyboardType(keyboard) }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .font(.regular, 16)
                .foreground(.textPrimary)
                if isSecure {
                    Button { reveal.toggle() } label: {
                        Image(systemName: reveal ? "eye.slash" : "eye").foreground(.textSecondary)
                    }
                }
            }
            .padding(.md)
            .bgColor(.surface)
            .rounded(.md)
            .outline(error != nil ? .error : (focused ? .brand : .border))

            if let error { Text(error).font(.regular, 12).foreground(.error) }
        }
    }
}

// MARK: - 6. HELPERS (haptics, keyboard, data extensions)
enum Haptic {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

extension UIApplication {
    static func hideKeyboard() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var isBlank: Bool { trimmed.isEmpty }
    var isValidEmail: Bool {
        range(of: #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }
    var isValidPassword: Bool { count >= 8 }
    var localized: String { NSLocalizedString(self, comment: "") }
}

extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
}

extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

extension Date {
    func string(_ format: String = "dd MMM yyyy") -> String {
        let f = DateFormatter(); f.dateFormat = format; return f.string(from: self)
    }
    var isToday: Bool { Calendar.current.isDateInToday(self) }
}

extension Double {
    func currency(_ code: String = "USD") -> String { formatted(.currency(code: code)) }
}

extension Bundle {
    var appVersion: String { infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
}

//MARK: Examples Usage
//Text("Welcome back")
//    .font(.bold, 28)              // your requested style
//    .foreground(.textPrimary)
//
//Text("Subtitle").textStyle(.callout).foreground(.textSecondary)
//
//VStack(spacing: AppSpacing.md.rawValue) {
//    AppTextField("Email", text: $email, icon: "envelope", error: emailError, keyboard: .emailAddress)
//    AppTextField("Password", text: $password, icon: "lock", isSecure: true)
//
//    AppButton("Sign In", isLoading: isLoading) { login() }
//    AppButton("Create account", kind: .outline) { router.push(.signUp) }
//
//    Button("Forgot password?") { router.push(.forgotPassword) }.buttonStyle(.text)
//    Button("Delete") { }.buttonStyle(.destructive)
//}
//.padding(.horizontal, .lg)
//.screenBackground()
//.loading(isLoading)
//.errorAlert($errorMessage)
//.onTapHideKeyboard()
//
//// Card
//VStack { Text("Balance").textStyle(.caption); Text("$120").font(.bold, 24) }
//    .card()
//
//// Switch appearance from a settings screen
//Button("Dark mode") { Theme.shared.setAppearance(.dark) }
//
//// Validation / helpers
//email.isValidEmail
//items[safe: 3]
//Date().string("dd/MM/yyyy")
