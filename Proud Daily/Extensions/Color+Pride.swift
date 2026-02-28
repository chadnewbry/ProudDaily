import SwiftUI

extension Color {
    static let prideRed = Color(red: 0.89, green: 0.01, blue: 0.01)
    static let prideOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    static let prideYellow = Color(red: 1.0, green: 0.93, blue: 0.0)
    static let prideGreen = Color(red: 0.0, green: 0.50, blue: 0.15)
    static let prideBlue = Color(red: 0.0, green: 0.30, blue: 0.77)
    static let prideViolet = Color(red: 0.46, green: 0.03, blue: 0.53)

    static let transBlue = Color(red: 0.36, green: 0.81, blue: 0.98)
    static let transPink = Color(red: 0.96, green: 0.66, blue: 0.72)

    static let biPink = Color(red: 0.84, green: 0.0, blue: 0.44)
    static let biPurple = Color(red: 0.61, green: 0.31, blue: 0.64)
    static let biBlue = Color(red: 0.0, green: 0.22, blue: 0.66)

    static let panPink = Color(red: 1.0, green: 0.09, blue: 0.55)
    static let panYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let panCyan = Color(red: 0.13, green: 0.69, blue: 0.93)

    static let nbYellow = Color(red: 0.99, green: 0.95, blue: 0.20)
    static let nbPurple = Color(red: 0.61, green: 0.35, blue: 0.82)

    static let lesbianDarkOrange = Color(red: 0.83, green: 0.18, blue: 0.0)
    static let lesbianOrange = Color(red: 0.99, green: 0.60, blue: 0.32)
    static let lesbianPink = Color(red: 0.84, green: 0.37, blue: 0.56)
    static let lesbianDarkPink = Color(red: 0.64, green: 0.03, blue: 0.33)

    static let acePurple = Color(red: 0.50, green: 0.0, blue: 0.50)

    static let rainbowGradient = LinearGradient(
        colors: [.prideRed, .prideOrange, .prideYellow, .prideGreen, .prideBlue, .prideViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
