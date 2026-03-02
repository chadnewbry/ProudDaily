import AppIntents
import WidgetKit

// MARK: - Category Option

enum WidgetCategoryOption: String, CaseIterable, AppEnum {
    case all
    case comingOut
    case selfAcceptance
    case chosenFamily
    case queerJoy
    case resilience
    case queerLove
    case bodyPositivity
    case transNonBinary
    case generalWellness

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")

    static var caseDisplayRepresentations: [WidgetCategoryOption: DisplayRepresentation] {
        [
            .all: "All Categories",
            .comingOut: "🚪 Coming Out",
            .selfAcceptance: "🪞 Self-Acceptance",
            .chosenFamily: "👨‍👩‍👧‍👦 Chosen Family",
            .queerJoy: "🎉 Queer Joy",
            .resilience: "💪 Resilience",
            .queerLove: "💕 Queer Love",
            .bodyPositivity: "✨ Body Positivity",
            .transNonBinary: "🏳️‍⚧️ Trans & Non-Binary",
            .generalWellness: "🌿 General Wellness",
        ]
    }
}

// MARK: - Widget Configuration Intent

struct CategorySelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Category"
    static var description = IntentDescription("Choose which affirmation category to display.")

    @Parameter(title: "Category", default: .all)
    var category: WidgetCategoryOption
}
