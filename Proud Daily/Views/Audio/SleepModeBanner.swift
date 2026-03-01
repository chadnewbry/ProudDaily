import SwiftUI

struct SleepModeBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.indigo)
            Text("Sleep Mode Active")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Stop sleep mode")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sleep mode is active. Double tap to stop.")
    }
}

#Preview {
    SleepModeBanner {}
}
