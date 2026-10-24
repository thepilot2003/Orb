import SwiftUI

// MARK: - Wardrobe & Accessory Overlays

struct NotchPetWardrobeView: View {
    let hat: PetHat
    let outfit: PetOutfit
    let action: NotchPetAction
    let step: Int
    let isCharging: Bool
    let isTyping: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Outfits (behind or layered over body)
            switch outfit {
            case .raincoat:
                RaincoatOverlay()
            case .winterSweater:
                WinterSweaterOverlay(step: step)
            case .tuxedo:
                TuxedoOverlay()
            case .superheroCape:
                SuperheroCapeOverlay(step: step)
            case .hawaiianShirt:
                HawaiianShirtOverlay()
            case .onesie:
                DinoOnesieOverlay()
            case .astronaut:
                AstronautSuitOverlay()
            case .none:
                EmptyView()
            }

            // Hats (on head)
            switch hat {
            case .djHeadphones:
                DJHeadphonesOverlay(accentColor: accentColor)
            case .sunglasses:
                SunglassesOverlay()
            case .rainHat:
                RainHatOverlay()
            case .winterBeanie:
                WinterBeanieOverlay()
            case .partyHat:
                PartyHatOverlay()
            case .royalCrown:
                RoyalCrownOverlay()
            case .chefHat:
                ChefHatOverlay()
            case .detectiveFedora:
                DetectiveFedoraOverlay()
            case .wizardHat:
                WizardHatOverlay()
            case .strawSunhat:
                StrawSunhatOverlay()
            case .gamerHeadset:
                GamerHeadsetOverlay(accentColor: accentColor)
            case .none:
                EmptyView()
            }

            // Interactive Accessories:
            // 1. MagSafe Battery / Lightning Snack
            if isCharging {
                BatterySnackOverlay()
                    .offset(x: 14, y: 4)
            }

            // 2. Typing Work Companion: Tiny Laptop or Pom-Poms
            if isTyping || action == .typing {
                MiniLaptopOverlay(step: step)
                    .offset(x: 0, y: 12)
            }
        }
    }
}

// MARK: - Hats

struct DJHeadphonesOverlay: View {
    let accentColor: Color
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            // Glowing Headband
            Path { path in
                path.addArc(center: CGPoint(x: 18, y: 10), radius: 14, startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
            }
            .stroke(
                LinearGradient(colors: [accentColor, Color.cyan], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .shadow(color: accentColor.opacity(0.8), radius: 3)

            // Left Ear Cup
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(accentColor, lineWidth: 1.5)
                )
                .frame(width: 5, height: 11)
                .position(x: 5, y: 11)
                .shadow(color: accentColor.opacity(0.6), radius: 2)

            // Right Ear Cup
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(accentColor, lineWidth: 1.5)
                )
                .frame(width: 5, height: 11)
                .position(x: 31, y: 11)
                .shadow(color: accentColor.opacity(0.6), radius: 2)
        }
        .frame(width: 36, height: 26)
        .offset(y: -9)
    }
}

struct SunglassesOverlay: View {
    var body: some View {
        ZStack {
            HStack(spacing: 3) {
                // Left lens
                ZStack {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 9, height: 6)
                    // Specular gleam
                    Path { p in
                        p.move(to: CGPoint(x: 1.5, y: 1.5))
                        p.addLine(to: CGPoint(x: 4.5, y: 4.5))
                    }
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }

                // Bridge
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 1.5)

                // Right lens
                ZStack {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 9, height: 6)
                    Path { p in
                        p.move(to: CGPoint(x: 1.5, y: 1.5))
                        p.addLine(to: CGPoint(x: 4.5, y: 4.5))
                    }
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }
            }
        }
        .offset(y: -2)
    }
}

struct RainHatOverlay: View {
    var body: some View {
        ZStack {
            // Brim
            Ellipse()
                .fill(Color(hex: "#FFD60A"))
                .frame(width: 30, height: 7)
                .offset(y: 2)
            // Crown
            UnevenRoundedRectangle(topLeadingRadius: 7, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 7)
                .fill(Color(hex: "#FFCC00"))
                .frame(width: 20, height: 11)
                .offset(y: -4)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 1, y: 1)
        .offset(y: -14)
    }
}

struct WinterBeanieOverlay: View {
    var body: some View {
        ZStack {
            // Beanie body
            UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 10)
                .fill(LinearGradient(colors: [Color(hex: "#FF3B30"), Color(hex: "#AF52DE")], startPoint: .top, endPoint: .bottom))
                .frame(width: 24, height: 14)
                .offset(y: -2)

            // Folded brim
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: 26, height: 5)
                .offset(y: 4)

            // Fluffy pom-pom on top
            Circle()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .offset(y: -10)
        }
        .offset(y: -14)
    }
}

struct PartyHatOverlay: View {
    var body: some View {
        ZStack {
            // Striped cone
            Path { p in
                p.move(to: CGPoint(x: 8, y: 0))
                p.addLine(to: CGPoint(x: 16, y: 16))
                p.addLine(to: CGPoint(x: 0, y: 16))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(colors: [Color(hex: "#FF2D55"), Color(hex: "#5856D6"), Color(hex: "#FFCC00")], startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 16, height: 16)

            // Sparkle pom on top
            Circle()
                .fill(Color(hex: "#FFD60A"))
                .frame(width: 5, height: 5)
                .offset(y: -9)
        }
        .offset(x: 2, y: -16)
    }
}

struct RoyalCrownOverlay: View {
    var body: some View {
        ZStack {
            // Golden Crown
            Path { p in
                p.move(to: CGPoint(x: 0, y: 11))
                p.addLine(to: CGPoint(x: 0, y: 3))
                p.addLine(to: CGPoint(x: 4.5, y: 7))
                p.addLine(to: CGPoint(x: 9, y: 1))
                p.addLine(to: CGPoint(x: 13.5, y: 7))
                p.addLine(to: CGPoint(x: 18, y: 3))
                p.addLine(to: CGPoint(x: 18, y: 11))
                p.closeSubpath()
            }
            .fill(Color(hex: "#FFD60A"))
            .frame(width: 18, height: 11)

            // Ruby gem in center
            Circle()
                .fill(Color(hex: "#FF3B30"))
                .frame(width: 3, height: 3)
                .offset(y: -1)
        }
        .shadow(color: Color.orange.opacity(0.4), radius: 2)
        .offset(y: -15)
    }
}

struct ChefHatOverlay: View {
    var body: some View {
        ZStack {
            // White puffy toque
            UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 10)
                .fill(Color.white)
                .frame(width: 22, height: 16)
                .offset(y: -3)
            // Headband
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "#E5E5EA"))
                .frame(width: 20, height: 4)
                .offset(y: 6)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 1)
        .offset(y: -16)
    }
}

struct DetectiveFedoraOverlay: View {
    var body: some View {
        ZStack {
            // Brim
            Ellipse()
                .fill(Color(hex: "#636366"))
                .frame(width: 28, height: 6)
                .offset(y: 2)
            // Hat crown with crease
            UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 6)
                .fill(Color(hex: "#48484A"))
                .frame(width: 18, height: 10)
                .offset(y: -4)
            // Hat ribbon
            Rectangle()
                .fill(Color(hex: "#1C1C1E"))
                .frame(width: 18, height: 2.5)
                .offset(y: 0.5)
        }
        .offset(y: -14)
    }
}

struct WizardHatOverlay: View {
    var body: some View {
        ZStack {
            // Starry cone
            Path { p in
                p.move(to: CGPoint(x: 12, y: 0))
                p.addLine(to: CGPoint(x: 20, y: 18))
                p.addLine(to: CGPoint(x: 0, y: 18))
                p.closeSubpath()
            }
            .fill(Color(hex: "#5856D6"))
            .frame(width: 20, height: 18)

            // Star on hat
            Text("✨")
                .font(.system(size: 8))
                .offset(x: 2, y: -2)
        }
        .offset(y: -16)
    }
}

struct StrawSunhatOverlay: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "#E5C07B"))
                .frame(width: 32, height: 7)
                .offset(y: 2)
            UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 6)
                .fill(Color(hex: "#D4A359"))
                .frame(width: 18, height: 9)
                .offset(y: -4)
            // Cyan ribbon
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 18, height: 2)
                .offset(y: 0)
        }
        .offset(y: -14)
    }
}

struct GamerHeadsetOverlay: View {
    let accentColor: Color

    var body: some View {
        ZStack {
            // Headband
            Path { path in
                path.addArc(center: CGPoint(x: 18, y: 10), radius: 14, startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
            }
            .stroke(Color(hex: "#2C2C2E"), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

            // RGB Glowing ear pads
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.green, Color.mint], startPoint: .top, endPoint: .bottom))
                .frame(width: 5, height: 12)
                .position(x: 5, y: 11)

            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.green, Color.mint], startPoint: .top, endPoint: .bottom))
                .frame(width: 5, height: 12)
                .position(x: 31, y: 11)

            // Boom Mic
            Path { p in
                p.move(to: CGPoint(x: 5, y: 14))
                p.addLine(to: CGPoint(x: 14, y: 17))
            }
            .stroke(Color(hex: "#8E8E93"), lineWidth: 1.5)

            Circle()
                .fill(Color.red)
                .frame(width: 2.5, height: 2.5)
                .position(x: 14, y: 17)
        }
        .frame(width: 36, height: 26)
        .offset(y: -9)
    }
}

// MARK: - Outfits

struct RaincoatOverlay: View {
    var body: some View {
        ZStack {
            // Yellow coat torso
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#FFCC00"))
                .frame(width: 26, height: 16)
                .offset(y: 8)

            // Black buttons
            VStack(spacing: 3) {
                Circle().fill(Color.black.opacity(0.8)).frame(width: 2, height: 2)
                Circle().fill(Color.black.opacity(0.8)).frame(width: 2, height: 2)
            }
            .offset(y: 8)
        }
    }
}

struct WinterSweaterOverlay: View {
    let step: Int

    var body: some View {
        ZStack {
            // Knit sweater
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#AF52DE"))
                .frame(width: 26, height: 15)
                .offset(y: 8)

            // Cozy wool scarf wrapped around neck
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#FF3B30"))
                .frame(width: 24, height: 5)
                .offset(y: 2)

            // Hanging scarf tail
            Rectangle()
                .fill(Color(hex: "#FF3B30"))
                .frame(width: 4, height: 9)
                .offset(x: 6, y: 6)
        }
    }
}

struct TuxedoOverlay: View {
    var body: some View {
        ZStack {
            // Black jacket
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#1C1C1E"))
                .frame(width: 26, height: 15)
                .offset(y: 8)

            // White shirt V-neck
            Path { p in
                p.move(to: CGPoint(x: 7, y: 2))
                p.addLine(to: CGPoint(x: 13, y: 10))
                p.addLine(to: CGPoint(x: 19, y: 2))
                p.closeSubpath()
            }
            .fill(Color.white)
            .frame(width: 26, height: 15)
            .offset(y: 4)

            // Red Bowtie
            Text("🎀")
                .font(.system(size: 9))
                .offset(y: 2)
        }
    }
}

struct SuperheroCapeOverlay: View {
    let step: Int

    var body: some View {
        ZStack {
            // Fluttering cape in background
            Path { p in
                p.move(to: CGPoint(x: 6, y: 4))
                let flutter = CGFloat(step % 2 == 0 ? -3 : 3)
                p.addLine(to: CGPoint(x: 2, y: 20 + flutter))
                p.addLine(to: CGPoint(x: 24, y: 20 + flutter))
                p.addLine(to: CGPoint(x: 20, y: 4))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(hex: "#FF3B30"), Color(hex: "#D70015")], startPoint: .top, endPoint: .bottom))
            .shadow(color: Color.red.opacity(0.4), radius: 2)
            .offset(y: 2)
        }
    }
}

struct HawaiianShirtOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#34C759"))
                .frame(width: 26, height: 15)
                .offset(y: 8)

            // Tropical floral dots
            HStack(spacing: 4) {
                Circle().fill(Color.pink).frame(width: 3, height: 3)
                Circle().fill(Color.yellow).frame(width: 3, height: 3)
                Circle().fill(Color.pink).frame(width: 3, height: 3)
            }
            .offset(y: 8)
        }
    }
}

struct DinoOnesieOverlay: View {
    var body: some View {
        ZStack {
            // Green onesie body
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#30D158"))
                .frame(width: 27, height: 17)
                .offset(y: 7)

            // Orange dorsal plates / spikes
            HStack(spacing: 3) {
                Triangle().fill(Color(hex: "#FF9500")).frame(width: 4, height: 4)
                Triangle().fill(Color(hex: "#FF9500")).frame(width: 4, height: 4)
                Triangle().fill(Color(hex: "#FF9500")).frame(width: 4, height: 4)
            }
            .offset(y: -4)
        }
    }
}

struct AstronautSuitOverlay: View {
    var body: some View {
        ZStack {
            // White space suit
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#F2F2F7"))
                .frame(width: 28, height: 17)
                .offset(y: 7)

            // Gold visor reflection
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9500")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 16, height: 8)
                .offset(y: -1)
        }
    }
}

// MARK: - Interactive Gadgets: MagSafe Battery Snack & Mini Laptop

struct BatterySnackOverlay: View {
    @State private var spark: Bool = false

    var body: some View {
        ZStack {
            // Glowing golden lightning bolt or energy battery
            ZStack {
                Circle()
                    .fill(Color(hex: "#30D158").opacity(0.3))
                    .frame(width: 16, height: 16)
                    .blur(radius: 2)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#30D158"))
                    .shadow(color: Color(hex: "#30D158"), radius: 4)
            }
            .scaleEffect(spark ? 1.15 : 0.95)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: spark)
            .onAppear { spark = true }
        }
    }
}

struct MiniLaptopOverlay: View {
    let step: Int

    var body: some View {
        ZStack {
            // Open miniature glowing laptop
            VStack(spacing: 1) {
                // Laptop display with glowing Apple/Orb logo
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(hex: "#2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.cyan.opacity(0.85))
                            .frame(width: 12, height: 8)
                    )
                    .frame(width: 15, height: 10)

                // Keyboard base
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: "#48484A"))
                    .frame(width: 17, height: 3)
            }
            .shadow(color: Color.cyan.opacity(0.5), radius: 3)
        }
    }
}

// MARK: - Helper Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
