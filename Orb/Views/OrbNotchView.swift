import SwiftUI

// MARK: - Main Dynamic Island Notch View Coordinator

struct OrbNotchView: View {
    @ObservedObject var state = OrbState.shared

    private var cornerRadius: CGFloat {
        if state.isExpanded { return 24 }
        if state.isCompactDroppedDown { return 18 }
        return 14
    }

    var body: some View {
        let shape = OrbNotchShape(topEarRadius: 10, bottomCornerRadius: cornerRadius)
        let raised = state.isExpanded || state.isCompactDroppedDown

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    IslandBackground(state: state, shape: shape)
                    panels
                }
                .frame(width: state.currentNotchWidth + 20, height: state.currentNotchHeight, alignment: .top)
                .clipShape(shape)
                .shadow(color: Color.black.opacity(raised ? 0.5 : 0), radius: 16, y: 8)

                // MagSafe charging line wrapping around the notch
                if state.isCharging && state.chargingGlowEnabled {
                    ChargingNotchBorderView(cornerRadius: cornerRadius)
                        .frame(width: state.currentNotchWidth + 20, height: state.currentNotchHeight, alignment: .top)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                // Companion anchored along the notch rim
                if state.showNotchPet {
                    NotchPetContainerView(state: state)
                }
            }
            .animation(OrbMotion.morph, value: state.isExpanded)
            .animation(OrbMotion.peek, value: state.isHovered)
            .animation(OrbMotion.morph, value: state.isBannerVisible)
            .animation(OrbMotion.morph, value: state.playback)
            .animation(.interactiveSpring(), value: state.widthOffsetPx)
            .animation(.interactiveSpring(), value: state.heightOffsetPx)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var panels: some View {
        if state.isExpanded {
            if state.playback != .stopped {
                NowPlayingPanel(state: state)
                    .transition(.blurFade(12))
            } else {
                IdlePanel(state: state)
                    .transition(.blurFade(12))
            }
        } else {
            CompactPanel(state: state)
                .transition(.opacity)
        }
    }
}

// MARK: - Notch Rim Contour (Open contour path that wraps around the MacBook notch)

struct NotchRimContour: Shape {
    var topEarRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topEarRadius, bottomCornerRadius) }
        set { topEarRadius = newValue.first; bottomCornerRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard rect.height > 1, rect.width > 1 else { return path }
        let ear = min(max(0, topEarRadius), rect.height / 2)
        let maxBottomR = max(0, rect.height - ear)
        let bottomR = min(max(0, bottomCornerRadius), min(maxBottomR, rect.height / 2))

        // Start at left ear flush with top edge
        path.move(to: CGPoint(x: rect.minX, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear, y: ear), control: CGPoint(x: rect.minX + ear, y: 0))
        path.addLine(to: CGPoint(x: rect.minX + ear, y: max(ear, rect.maxY - bottomR)))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear + bottomR, y: rect.maxY), control: CGPoint(x: rect.minX + ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: max(rect.minX + ear + bottomR, rect.maxX - ear - bottomR), y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - ear, y: max(ear, rect.maxY - bottomR)), control: CGPoint(x: rect.maxX - ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: ear))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: 0), control: CGPoint(x: rect.maxX - ear, y: 0))

        return path
    }
}

// MARK: - MagSafe Notch Charging Border (Glowing electric line wrapping around notch)

struct ChargingNotchBorderView: View {
    @ObservedObject var state = OrbState.shared
    var cornerRadius: CGFloat

    @State private var isPulsing = false

    private var chargingColors: [Color] {
        switch state.chargingColorChoice {
        case "cyan":
            return [Color(hex: "#00E5FF"), Color(hex: "#18FFFF"), Color(hex: "#84FFFF"), Color(hex: "#00E5FF")]
        case "amber":
            return [Color(hex: "#FFB300"), Color(hex: "#FFC107"), Color(hex: "#FFE082"), Color(hex: "#FFB300")]
        case "accent":
            return [state.accentColor, state.accentColor.opacity(0.85), Color.white.opacity(0.85), state.accentColor]
        default: // "magsafe"
            return [Color(hex: "#30D158"), Color(hex: "#34C759"), Color(hex: "#69F0AE"), Color(hex: "#30D158")]
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: chargingColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        let rim = NotchRimContour(topEarRadius: 10, bottomCornerRadius: cornerRadius)

        ZStack {
            // 1. Outer ambient bloom halo
            rim
                .stroke(gradient, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
                .blur(radius: 3.5)
                .opacity(isPulsing ? 0.75 : 0.45)

            // 2. Focused electric neon glow
            rim
                .stroke(gradient, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .blur(radius: 1.0)
                .opacity(isPulsing ? 0.95 : 0.65)

            // 3. Crisp sharp white light core
            rim
                .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                .blendMode(.plusLighter)
                .opacity(isPulsing ? 0.8 : 0.5)

            // 4. Primary vivid contour line
            rim
                .stroke(gradient, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .opacity(0.95)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
