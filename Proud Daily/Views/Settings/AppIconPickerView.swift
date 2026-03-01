import SwiftUI

enum AppIconVariant: String, CaseIterable, Identifiable {
    case rainbow = "AppIcon"
    case trans = "TransPride"
    case bi = "BiPride"
    case subtle = "Subtle"
    case pastel = "PastelRainbow"
    case bold = "BoldPride"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .trans: return "Trans Pride"
        case .bi: return "Bi Pride"
        case .subtle: return "Subtle"
        case .pastel: return "Pastel Rainbow"
        case .bold: return "Bold Pride"
        }
    }

    var description: String {
        switch self {
        case .rainbow: return "Classic pride rainbow gradient"
        case .trans: return "Trans flag colors"
        case .bi: return "Bisexual flag colors"
        case .subtle: return "Discreet with hidden pride accent"
        case .pastel: return "Soft pastel rainbow"
        case .bold: return "Vibrant diagonal pride"
        }
    }

    /// The value to pass to `setAlternateIconName`. `nil` means primary icon.
    var iconName: String? {
        self == .rainbow ? nil : rawValue
    }
}

struct AppIconPickerView: View {
    @State private var selectedIcon: AppIconVariant = .rainbow

    var body: some View {
        List {
            ForEach(AppIconVariant.allCases) { variant in
                Button {
                    setIcon(variant)
                } label: {
                    HStack(spacing: 16) {
                        Image(variant.rawValue + "Preview")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(variant.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(variant.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedIcon == variant {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accent)
                                .font(.title3)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("App Icon")
        .onAppear {
            loadCurrentIcon()
        }
    }

    private func loadCurrentIcon() {
        let current = UIApplication.shared.alternateIconName
        selectedIcon = AppIconVariant.allCases.first { $0.iconName == current } ?? .rainbow
    }

    private func setIcon(_ variant: AppIconVariant) {
        guard selectedIcon != variant else { return }
        selectedIcon = variant
        UIApplication.shared.setAlternateIconName(variant.iconName)
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
