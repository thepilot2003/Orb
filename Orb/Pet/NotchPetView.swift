import SwiftUI

// MARK: - Notch Pet Container View (Full Visibility Below Notch)

struct NotchPetContainerView: View {
    @ObservedObject var state: OrbState
    @ObservedObject var petManager = PetManager.shared

    var body: some View {
        let notchBottom: CGFloat = state.isExpanded ? state.expandedHeight : state.currentNotchHeight
        let isSpider = (petManager.petType == .spider)

        // Vertical Anchor:
        // Physical notch ends at notchBottom (~32-34px idle, 180-220px expanded).
        // Placing pet at (notchBottom + 14) positions the character completely in the clear screen area,
        // perching right below the notch rim without any hardware bezel obstruction.
        let yOffset: CGFloat = isSpider ? (notchBottom + 12 + petManager.spiderSilkLength) : (notchBottom + 14)

        ZStack(alignment: .top) {
            // Spider Silk Thread: Silver hanging line suspended directly from notch lip
            if isSpider && (petManager.spiderSilkLength > 2 || petManager.isSpiderDangling) {
                Path { path in
                    path.move(to: CGPoint(x: petManager.petPositionX, y: notchBottom))
                    path.addLine(to: CGPoint(x: petManager.petPositionX, y: yOffset - 10))
                }
                .stroke(
                    LinearGradient(colors: [Color.white.opacity(0.85), Color(hex: "#8E8E93").opacity(0.4)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 1.0, dash: [4, 1])
                )
            }

            // Falling Treat Snack Drop Animation
            if let treat = petManager.activeTreat {
                TreatDropView(treat: treat)
                    .offset(x: petManager.petPositionX, y: yOffset - 22)
                    .transition(.scale.combined(with: .opacity))
            }

            // Companion Character & Wardrobe
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
            return (petManager.petWalkStep % 2 == 0) ? -1.5 : 0.8
        case .dancing:
            return (petManager.petWalkStep % 2 == 0) ? (petManager.isFastDancing ? -4.5 : -2.0) : 1.5
        case .happy:
            return -6.0
        case .sleeping:
            return 0.5
        case .typing:
            return (petManager.petWalkStep % 2 == 0) ? -1.0 : 1.0
        case .stretching:
            return -3.0
        case .eating:
            return (petManager.petWalkStep % 2 == 0) ? -1.2 : 0.5
        case .singing, .idle:
            return 0
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Emote / Speech / Karaoke Bubble Overlay
            speechBubbleOverlay
                .offset(y: -24)

            // Pet Base Vector Body
            Group {
                switch petManager.petType {
                case .cat:
                    NotchCatSprite(action: petManager.petAction, step: petManager.petWalkStep, isSinging: petManager.isSingingVocal)
                case .dog:
                    NotchDogSprite(action: petManager.petAction, step: petManager.petWalkStep, isSinging: petManager.isSingingVocal)
                case .duck:
                    NotchDuckSprite(action: petManager.petAction, step: petManager.petWalkStep, isSinging: petManager.isSingingVocal)
                case .spider:
                    NotchSpiderSprite(action: petManager.petAction, step: petManager.petWalkStep, isSinging: petManager.isSingingVocal, isDangling: petManager.isSpiderDangling)
                case .orb:
                    NotchOrbSprite(action: petManager.petAction, step: petManager.petWalkStep, color: accentColor, isSinging: petManager.isSingingVocal)
                }
            }
            .offset(y: bobOffset)
            .scaleEffect(x: petManager.petFacingLeft ? -1 : 1, y: 1)

            // Wardrobe & Interactive Overlays (Headphones, Hats, Outfits, Laptop, Battery Snack)
            NotchPetWardrobeView(
                hat: petManager.effectiveHat,
                outfit: petManager.effectiveOutfit,
                action: petManager.petAction,
                step: petManager.petWalkStep,
                isCharging: petManager.isCharging && petManager.chargingSnackEnabled,
                isTyping: petManager.isTypingFast && petManager.typingCompanionEnabled,
                accentColor: accentColor
            )
            .offset(y: bobOffset)
            .scaleEffect(x: petManager.petFacingLeft ? -1 : 1, y: 1)
        }
        .frame(width: 44, height: 38)
        .contentShape(Rectangle())
    }

    // MARK: - Emotes & Speech Bubble

    @ViewBuilder
    private var speechBubbleOverlay: some View {
        if let text = petManager.speechBubbleText {
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.82))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
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
            // Sparkles
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
