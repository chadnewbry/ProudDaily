import SwiftUI
import PhotosUI

struct ThemeSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        @Bindable var tm = themeManager
        List {
            // MARK: - Preview
            Section {
                ThemePreviewCard()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // MARK: - Pride Themes
            Section("Pride Themes") {
                ForEach(PrideTheme.allCases) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.selectedTheme = theme
                        }
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.gradient(isDark: colorScheme == .dark))
                                .frame(width: 44, height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                )
                            Text("\(theme.emoji) \(theme.displayName)")
                                .foregroundStyle(.primary)
                            Spacer()
                            if themeManager.selectedTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.accentColor)
                            }
                        }
                    }
                }
            }

            // MARK: - Seasonal Themes
            if !themeManager.availableSeasonalThemes.isEmpty {
                Section("Seasonal Themes") {
                    Toggle("Use Seasonal Theme", isOn: $tm.useSeasonalTheme)

                    if themeManager.useSeasonalTheme {
                        ForEach(themeManager.availableSeasonalThemes) { seasonal in
                            Button {
                                themeManager.selectedSeasonalThemeId = seasonal.id
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(seasonal.gradient(isDark: colorScheme == .dark))
                                        .frame(width: 44, height: 30)
                                    Text("\(seasonal.emoji) \(seasonal.displayName)")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if themeManager.selectedSeasonalThemeId == seasonal.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(seasonal.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Custom Background
            Section("Background") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Photo Background", systemImage: "photo.on.rectangle")
                }
                .onChange(of: selectedPhoto) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            themeManager.setCustomBackground(image)
                        }
                    }
                }

                if themeManager.customBackgroundData != nil {
                    Button(role: .destructive) {
                        themeManager.clearCustomBackground()
                    } label: {
                        Label("Remove Background Photo", systemImage: "trash")
                    }
                }
            }

            // MARK: - Font
            Section("Font") {
                ForEach(FontTheme.allCases) { font in
                    Button {
                        withAnimation { themeManager.fontTheme = font }
                    } label: {
                        HStack {
                            Text(font.previewText)
                                .font(font.font(size: 17))
                                .foregroundStyle(.primary)
                            Spacer()
                            if themeManager.fontTheme == font {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(themeManager.activeAccentColor)
                            }
                        }
                    }
                }
            }

            // MARK: - Text Size
            Section("Text Size") {
                ForEach(TextSizePreference.allCases) { size in
                    Button {
                        withAnimation { themeManager.textSize = size }
                    } label: {
                        HStack {
                            Text(size.displayName)
                                .font(.system(size: 17 * size.scaleFactor))
                                .foregroundStyle(.primary)
                            Spacer()
                            if themeManager.textSize == size {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(themeManager.activeAccentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Theme")
        .onAppear {
            themeManager.colorSchemeIsDark = colorScheme == .dark
        }
        .onChange(of: colorScheme) { _, newValue in
            themeManager.colorSchemeIsDark = newValue == .dark
        }
    }
}

// MARK: - Preview Card

private struct ThemePreviewCard: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if let bgImage = themeManager.customBackgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipped()
                    .overlay(
                        themeManager.activeGradient.opacity(0.5)
                    )
            } else {
                themeManager.activeGradient
            }

            VStack(spacing: 8) {
                Text("Today's Affirmation")
                    .font(themeManager.scaledFont(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text("You are worthy of love.")
                    .font(themeManager.scaledFont(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
            .environment(ThemeManager())
    }
}
