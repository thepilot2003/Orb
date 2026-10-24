import SwiftUI

// MARK: - Notch Pet Container View (Flush Grounding on Notch Rim)

struct NotchPetContainerView: View {
    @ObservedObject var state: OrbState
    @ObservedObject var petManager = PetManager.shared

    var body: some View {
        let notchBottom: CGFloat = state.isExpanded ? state.expandedHeight : state.currentNotchHeight
        let isSpider = (petManager.petType == .spider)

        // Perfect Physical Alignment:
        // Anchoring at (notchBottom + 1) places the companion's head and ears right at the lower edge
        // of the physical MacBook camera cutout—100% visible on screen pixels with zero clipping and zero gap!
        let baseOffset: CGFloat = notchBottom + 1
        let yOffset: CGFloat = isSpider ? (baseOffset + petManager.spiderSilkLength) : baseOffset

        ZStack(alignment: .top) {
            // Spider Silk Thread: Solid glistening silver line anchored directly inside notch
            if isSpider && petManager.spiderSilkLength > 1 {
                ZStack {
                    // Anchor Knot at notch rim
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3.5, height: 3.5)
                        .position(x: petManager.petPositionX, y: notchBottom - 2)

                    // Silk Bungee Line
                    Path { path in
                        path.move(to: CGPoint(x: petManager.petPositionX, y: notchBottom - 2))
                        path.addLine(to: CGPoint(x: petManager.petPositionX, y: yOffset - 4))
                    }
                    .stroke(
                        LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.65)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.2
                    )
                }
            }

            // Falling Treat Snack Drop Animation
            if let treat = petManager.activeTreat {
                TreatDropView(treat: treat)
                    .offset(x: petManager.petPositionX, y: yOffset - 24)
                    .transition(.scale.combined(with: .opacity))
            }

            // Companion Character
            Button(action: {
                petManager.petInteracted()
            }) {
                NotchPetView(petManager: petManager, accentColor: state.accentColor)
            }
            .buttonStyle(.plain)
            .offset(x: petManager.petPositionX, y: yOffset)
            .rotationEffect(.degrees(isSpider ? petManager.spiderSwingAngle : 0), anchor: .top)
            .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.82), value: petManager.petPositionX)
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: yOffset)
        }
    }
}

// MARK: - Notch Pet Sprite & Accessory Composable View

struct NotchPetView: View {
    @ObservedObject var petManager: PetManager
    let accentColor: Color

    private var bobOffset: CGFloat {
        switch petManager.petAction {
        case .walking:
            return (petManager.petWalkStep % 2 == 0) ? -1.2 : 0.6
        case .dancing:
            return (petManager.petWalkStep % 2 == 0) ? (petManager.isFastDancing ? -4.0 : -1.8) : 1.2
        case .happy:
            return -5.0
        case .sleeping:
            return 0.5
        case .typing:
            return (petManager.petWalkStep % 2 == 0) ? -0.8 : 0.8
        case .stretching:
            return -2.5
        case .eating:
            return (petManager.petWalkStep % 2 == 0) ? -1.0 : 0.5
        case .singing, .idle:
            return 0
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Emote / Speech / Karaoke Bubble Overlay
            speechBubbleOverlay
                .offset(y: -26)

            // Pet Base Vector Body with Integrated Anatomy Accessories
            Group {
                switch petManager.petType {
                case .cat:
                    NotchCatSprite(
                        action: petManager.petAction,
                        step: petManager.petWalkStep,
                        isSinging: petManager.isSingingVocal,
                        hat: petManager.effectiveHat,
                        outfit: petManager.effectiveOutfit,
                        isCharging: petManager.isCharging && petManager.chargingSnackEnabled,
                        isTyping: petManager.isTypingFast && petManager.typingCompanionEnabled,
                        accentColor: accentColor
                    )
                case .dog:
                    NotchDogSprite(
                        action: petManager.petAction,
                        step: petManager.petWalkStep,
                        isSinging: petManager.isSingingVocal,
                        hat: petManager.effectiveHat,
                        outfit: petManager.effectiveOutfit,
                        isCharging: petManager.isCharging && petManager.chargingSnackEnabled,
                        isTyping: petManager.isTypingFast && petManager.typingCompanionEnabled,
                        accentColor: accentColor
                    )
                case .duck:
                    NotchDuckSprite(
                        action: petManager.petAction,
                        step: petManager.petWalkStep,
                        isSinging: petManager.isSingingVocal,
                        hat: petManager.effectiveHat,
                        outfit: petManager.effectiveOutfit,
                        isCharging: petManager.isCharging && petManager.chargingSnackEnabled,
                        isTyping: petManager.isTypingFast && petManager.typingCompanionEnabled,
                        accentColor: accentColor
                    )
                case .spider:
                    NotchSpiderSprite(
                        action: petManager.petAction,
                        step: petManager.petWalkStep,
                        isSinging: petManager.isSingingVocal,
                        isDangling: petManager.isSpiderDangling,
                        hat: petManager.effectiveHat,
                        outfit: petManager.effectiveOutfit,
                        isCharging: petManager.isCharging && petManager.chargingSnackEnabled,
                        accentColor: accentColor
                    )
                case .orb:
                    NotchOrbSprite(
                        action: petManager.petAction,
                        step: petManager.petWalkStep,
                        color: accentColor,
                        isSinging: petManager.isSingingVocal,
                        hat: petManager.effectiveHat,
                        outfit: petManager.effectiveOutfit,
                        isCharging: petManager.isCharging && petManager.chargingSnackEnabled
                    )
                }
            }
            .offset(y: bobOffset)
            .scaleEffect(x: petManager.petFacingLeft ? -1 : 1, y: 1)
        }
        .frame(width: 44, height: 38)
        .contentShape(Rectangle())
    }

    // MARK: - Emotes & Speech Bubble (Full Width, Never Truncated)

    @ViewBuilder
    private var speechBubbleOverlay: some View {
        if let text = petManager.speechBubbleText {
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                        .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
                )
                .transition(.scale.combined(with: .opacity))
        } else if petManager.isSingingVocal {
            HStack(spacing: 2) {
                Text("♪").foregroundColor(accentColor).font(.system(size: 11, weight: .bold))
                Text("♫").foregroundColor(.white).font(.system(size: 9))
            }
            .transition(.scale.combined(with: .opacity))
        } else if petManager.petAction == .sleeping {
            Text(petManager.petSleepZ < 20 ? "z" : "Z")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.85))
                .offset(x: 12, y: petManager.petSleepZ < 20 ? 0 : -4)
                .opacity(petManager.petSleepZ < 30 ? 0.9 : 0.2)
        } else if petManager.petAction == .happy {
            Text("❤️")
                .font(.system(size: 11))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Animated Treat Drop (Feeding Feature)

struct TreatDropView: View {
    let treat: PetTreat
    @State private var bounce: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 18, height: 18)
                .blur(radius: 2)

            Text(treat.emoji)
                .font(.system(size: 14))
                .scaleEffect(bounce ? 1.15 : 0.85)
                .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: bounce)
        }
        .onAppear { bounce = true }
    }
}
