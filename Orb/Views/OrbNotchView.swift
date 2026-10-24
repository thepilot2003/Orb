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
