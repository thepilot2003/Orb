import SwiftUI

// MARK: - Apple Music Karaoke Syllable & Character Highlighting View

struct IntroDotsView: View {
    let accentColor: Color
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(accentColor.opacity(phase == i ? 1.0 : 0.35))
                    .frame(width: 4.5, height: 4.5)
                    .scaleEffect(phase == i ? 1.25 : 0.85)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.16),
                        value: phase
                    )
            }
        }
        .onAppear {
            phase = 1
        }
    }
}

struct AppleMusicKaraokeLyricView: View {
    let line: LyricLine
    let currentTime: Double
    var font: Font = .system(size: 13, weight: .bold, design: .rounded)

    private var progress: CGFloat {
        let dur = max(line.endTime - line.time, 0.4)
        let raw = (currentTime - line.time) / dur
        return CGFloat(min(max(raw, 0.0), 1.0))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Unlit inactive layer (Apple Music 35% opacity)
            Text(line.text)
                .font(font)
                .foregroundColor(Color.white.opacity(0.35))

            // Lit active layer (glowing illuminated bright white character reveal)
            if progress > 0 {
                Text(line.text)
                    .font(font)
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.85), radius: 5, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(0.40), radius: 10, x: 0, y: 0)
                    .mask(
                        GeometryReader { geo in
                            let width = geo.size.width
                            let p = progress
                            let wipeX = width * p
                            let feather: CGFloat = 14

                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: max(0, wipeX - feather / 2))

                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.6), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: min(feather, max(0, width - (wipeX - feather / 2))))

                                Spacer(minLength: 0)
                            }
                        }
                    )
            }
        }
        .lineLimit(1)
    }
}
