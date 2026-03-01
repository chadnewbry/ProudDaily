import SwiftUI
import PhotosUI

@Observable
class ThemeManager {
    var selectedTheme: PrideTheme {
        didSet { save() }
    }
    var fontTheme: FontTheme {
        didSet { save() }
    }
    var textSize: TextSizePreference {
        didSet { save() }
    }
    var useSeasonalTheme: Bool {
        didSet { save() }
    }
    var unlockedSeasonalThemeIds: Set<String> {
        didSet { save() }
    }
    var customBackgroundData: Data? {
        didSet { saveBackgroundImage() }
    }
    var selectedSeasonalThemeId: String? {
        didSet { save() }
    }

    // MARK: - Computed

    var activeGradientColors: [Color] {
        let isDark = colorSchemeIsDark
        if let seasonalId = effectiveSeasonalThemeId,
           let seasonal = SeasonalTheme.all.first(where: { $0.id == seasonalId }) {
            return isDark ? seasonal.gradientColors.map { $0.opacity(0.75) } : seasonal.gradientColors
        }
        return selectedTheme.gradientColors(isDark: isDark)
    }

    var activeGradient: LinearGradient {
        LinearGradient(
            colors: activeGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var activeAccentColor: Color {
        if let seasonalId = effectiveSeasonalThemeId,
           let seasonal = SeasonalTheme.all.first(where: { $0.id == seasonalId }) {
            return seasonal.accentColor
        }
        return selectedTheme.accentColor
    }

    var customBackgroundImage: UIImage? {
        guard let data = customBackgroundData else { return nil }
        return UIImage(data: data)
    }

    var colorSchemeIsDark = false

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.selectedTheme = PrideTheme(rawValue: defaults.string(forKey: "theme.pride") ?? "") ?? .rainbow
        self.fontTheme = FontTheme(rawValue: defaults.string(forKey: "theme.font") ?? "") ?? .system
        self.textSize = TextSizePreference(rawValue: defaults.string(forKey: "theme.textSize") ?? "") ?? .standard
        self.useSeasonalTheme = defaults.bool(forKey: "theme.useSeasonal")
        self.selectedSeasonalThemeId = defaults.string(forKey: "theme.seasonalId")
        let ids = defaults.stringArray(forKey: "theme.unlockedSeasonal") ?? []
        self.unlockedSeasonalThemeIds = Set(ids)
        self.customBackgroundData = Self.loadBackgroundImage()

        // Auto-unlock currently active seasonal themes
        for theme in SeasonalTheme.currentlyActive {
            unlockedSeasonalThemeIds.insert(theme.id)
        }
    }

    // MARK: - Seasonal

    var availableSeasonalThemes: [SeasonalTheme] {
        SeasonalTheme.all.filter { $0.isCurrentlyActive || unlockedSeasonalThemeIds.contains($0.id) }
    }

    private var effectiveSeasonalThemeId: String? {
        guard useSeasonalTheme else { return nil }
        if let id = selectedSeasonalThemeId,
           availableSeasonalThemes.contains(where: { $0.id == id }) {
            return id
        }
        return SeasonalTheme.currentlyActive.first?.id
    }

    // MARK: - Font helpers

    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        fontTheme.font(size: size * textSize.scaleFactor, weight: weight)
    }

    // MARK: - Background image

    func setCustomBackground(_ image: UIImage?) {
        customBackgroundData = image?.jpegData(compressionQuality: 0.8)
    }

    func clearCustomBackground() {
        customBackgroundData = nil
        try? FileManager.default.removeItem(at: Self.backgroundImageURL)
    }

    // MARK: - Persistence

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(selectedTheme.rawValue, forKey: "theme.pride")
        defaults.set(fontTheme.rawValue, forKey: "theme.font")
        defaults.set(textSize.rawValue, forKey: "theme.textSize")
        defaults.set(useSeasonalTheme, forKey: "theme.useSeasonal")
        defaults.set(selectedSeasonalThemeId, forKey: "theme.seasonalId")
        defaults.set(Array(unlockedSeasonalThemeIds), forKey: "theme.unlockedSeasonal")
    }

    private func saveBackgroundImage() {
        guard let data = customBackgroundData else { return }
        try? data.write(to: Self.backgroundImageURL)
    }

    private static var backgroundImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("custom_background.jpg")
    }

    private static func loadBackgroundImage() -> Data? {
        try? Data(contentsOf: backgroundImageURL)
    }
}
