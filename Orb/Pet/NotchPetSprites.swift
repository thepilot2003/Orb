import SwiftUI

// MARK: - Cat Sprite (Mochi 🐱 - 3D-Shaded, Expressive Feline)

struct NotchCatSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool
    let hat: PetHat
    let outfit: PetOutfit
    let isCharging: Bool
    let isTyping: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Grounding Shadow on Notch Ledge
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 28, height: 6)
                .offset(y: 15)

            // Swishing Tail
            Path { path in
                path.move(to: CGPoint(x: 2, y: 11))
                let tailWiggle = CGFloat(step % 2 == 0 ? -4 : 4)
                path.addQuadCurve(to: CGPoint(x: -7, y: 3 + tailWiggle), control: CGPoint(x: -5, y: 10))
            }
            .stroke(
                LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#D97706")], startPoint: .top, endPoint: .bottom),
                style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
            )

            // Cape Outfit (behind body)
            if outfit == .superheroCape {
                Path { p in
                    p.move(to: CGPoint(x: 4, y: 2))
                    let flutter = CGFloat(step % 2 == 0 ? -2 : 2)
                    p.addLine(to: CGPoint(x: -3, y: 14 + flutter))
                    p.addLine(to: CGPoint(x: 17, y: 14 + flutter))
                    p.addLine(to: CGPoint(x: 10, y: 2))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color(hex: "#FF3B30"), Color(hex: "#D70015")], startPoint: .top, endPoint: .bottom))
                .offset(y: 2)
            }

            // Cat Body (Chubby 3D-shaded rounded silhouette)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFB03A"), Color(hex: "#F59E0B"), Color(hex: "#D97706")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 21)
                .overlay(
                    // White fluffy chest patch
                    UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 4)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 13, height: 12)
                        .offset(y: 3)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 2)
                .offset(y: 4)

            // Outfits (On body)
            if outfit == .raincoat {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(hex: "#FFD60A"))
                    .frame(width: 25, height: 14)
                    .overlay(
                        VStack(spacing: 2) {
                            Circle().fill(Color.black.opacity(0.7)).frame(width: 2, height: 2)
                            Circle().fill(Color.black.opacity(0.7)).frame(width: 2, height: 2)
                        }
                    )
                    .offset(y: 6)
            } else if outfit == .winterSweater {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(hex: "#AF52DE"))
                    .frame(width: 25, height: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "#FF3B30"))
                            .frame(width: 22, height: 4)
                            .offset(y: -4)
                    )
                    .offset(y: 6)
            } else if outfit == .tuxedo {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(hex: "#1C1C1E"))
                        .frame(width: 25, height: 14)
                    Text("🎀").font(.system(size: 8)).offset(y: -2)
                }
                .offset(y: 6)
            }

            // Pointed Cat Ears (Positioned directly on head)
            HStack(spacing: 12) {
                // Left Ear
                ZStack {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 7))
                        p.addLine(to: CGPoint(x: 4, y: -2))
                        p.addLine(to: CGPoint(x: 8, y: 7))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#D97706"))
                    Path { p in
                        p.move(to: CGPoint(x: 2, y: 6))
                        p.addLine(to: CGPoint(x: 4, y: 1))
                        p.addLine(to: CGPoint(x: 6, y: 6))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#FF85A2"))
                }
                .frame(width: 8, height: 8)

                // Right Ear
                ZStack {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 7))
                        p.addLine(to: CGPoint(x: 4, y: -2))
                        p.addLine(to: CGPoint(x: 8, y: 7))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#D97706"))
                    Path { p in
                        p.move(to: CGPoint(x: 2, y: 6))
                        p.addLine(to: CGPoint(x: 4, y: 1))
                        p.addLine(to: CGPoint(x: 6, y: 6))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#FF85A2"))
                }
                .frame(width: 8, height: 8)
            }
            .offset(y: -7)

            // Whiskers
            Path { p in
                p.move(to: CGPoint(x: 4, y: 5))
                p.addLine(to: CGPoint(x: -3, y: 4))
                p.move(to: CGPoint(x: 4, y: 7))
                p.addLine(to: CGPoint(x: -3, y: 8))

                p.move(to: CGPoint(x: 24, y: 5))
                p.addLine(to: CGPoint(x: 31, y: 4))
                p.move(to: CGPoint(x: 24, y: 7))
                p.addLine(to: CGPoint(x: 31, y: 8))
            }
            .stroke(Color.white.opacity(0.85), lineWidth: 0.9)
            .offset(x: -14, y: -2)

            // Almond Eyes (Double specular sparkle)
            HStack(spacing: 8) {
                if action == .sleeping {
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                } else if action == .happy {
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.9))
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.9))
                } else {
                    ZStack {
                        Circle().fill(Color(hex: "#1E1E24")).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 1.6, height: 1.6).offset(x: -0.7, y: -0.7)
                        Circle().fill(Color.white).frame(width: 0.8, height: 0.8).offset(x: 0.8, y: 0.8)
                    }
                    ZStack {
                        Circle().fill(Color(hex: "#1E1E24")).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 1.6, height: 1.6).offset(x: -0.7, y: -0.7)
                        Circle().fill(Color.white).frame(width: 0.8, height: 0.8).offset(x: 0.8, y: 0.8)
                    }
                }
            }
            .offset(y: -1)

            // Cute Nose & Mouth
            VStack(spacing: 1) {
                // Pink nose
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 2.8, y: 0))
                    p.addLine(to: CGPoint(x: 1.4, y: 1.8))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#FF85A2"))
                .frame(width: 3, height: 2)

                // Singing open mouth or feline smile
                if isSinging {
                    Circle()
                        .fill(Color(hex: "#FF3B30"))
                        .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 0.6))
                        .frame(width: 4.2, height: 4.2)
                } else {
                    Text("3")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.75))
                }
            }
            .offset(y: 4)

            // Front White Paws
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4.5, height: step % 2 == 0 ? 5 : 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4.5, height: step % 2 == 0 ? 3 : 5)
            }
            .offset(y: 13)

            // Perfectly Fitted DJ Headphones for Cat
            if hat == .djHeadphones {
                ZStack {
                    // Headband curved right over head
                    Path { p in
                        p.addArc(center: CGPoint(x: 15, y: 7), radius: 11, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    }
                    .stroke(LinearGradient(colors: [accentColor, Color.cyan], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .shadow(color: accentColor.opacity(0.8), radius: 3)

                    // Ear cups directly hugging cat ears
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "#1C1C1E"))
                        .overlay(RoundedRectangle(cornerRadius: 2.5).stroke(accentColor, lineWidth: 1.2))
                        .frame(width: 4, height: 9)
                        .position(x: 4, y: 7)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "#1C1C1E"))
                        .overlay(RoundedRectangle(cornerRadius: 2.5).stroke(accentColor, lineWidth: 1.2))
                        .frame(width: 4, height: 9)
                        .position(x: 26, y: 7)
                }
                .frame(width: 30, height: 14)
                .offset(y: -6)
            } else if hat == .sunglasses {
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 8, height: 5)
                    Rectangle().fill(Color.black).frame(width: 2, height: 1)
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 8, height: 5)
                }
                .offset(y: -1)
            } else if hat == .winterBeanie {
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 8)
                    .fill(LinearGradient(colors: [Color.red, Color.purple], startPoint: .top, endPoint: .bottom))
                    .frame(width: 22, height: 11)
                    .overlay(Circle().fill(Color.white).frame(width: 5, height: 5).offset(y: -7))
                    .offset(y: -10)
            } else if hat == .royalCrown {
                Text("👑").font(.system(size: 11)).offset(y: -13)
            }

            // MagSafe Battery Snack in Paw
            if isCharging {
                ZStack {
                    Circle().fill(Color(hex: "#30D158").opacity(0.25)).frame(width: 12, height: 12).blur(radius: 1)
                    Image(systemName: "bolt.fill").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "#30D158"))
                }
                .offset(x: 12, y: 6)
            }

            // Typing Mini Laptop
            if isTyping || action == .typing {
                VStack(spacing: 0.5) {
                    RoundedRectangle(cornerRadius: 1).fill(Color.cyan.opacity(0.9)).frame(width: 10, height: 6)
                    RoundedRectangle(cornerRadius: 1).fill(Color.gray).frame(width: 12, height: 2)
                }
                .offset(x: 0, y: 10)
            }
        }
        .frame(width: 36, height: 32)
    }
}

// MARK: - Dog Sprite (Bento 🐶 - Bouncy Puppy)

struct NotchDogSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool
    let hat: PetHat
    let outfit: PetOutfit
    let isCharging: Bool
    let isTyping: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Grounding Shadow on Notch Ledge
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 28, height: 6)
                .offset(y: 15)

            // Wagging Tail
            Path { path in
                path.move(to: CGPoint(x: 3, y: 11))
                let tailWag = CGFloat(step % 2 == 0 ? -5 : 5)
                path.addQuadCurve(to: CGPoint(x: -6, y: 5 + tailWag), control: CGPoint(x: -3, y: 9))
            }
            .stroke(Color(hex: "#C68B45"), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))

            // Dog Body (3D warm golden coat)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(hex: "#E0A96D"), Color(hex: "#C68B45")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 29, height: 21)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#FBF3D5"))
                        .frame(width: 14, height: 12)
                        .offset(y: 3)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 2)
                .offset(y: 4)

            // Floppy Puppy Ears on sides
            HStack(spacing: 17) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#9E6229"))
                    .frame(width: 7, height: 12)
                    .rotationEffect(.degrees(step % 2 == 0 ? -8 : -14))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#9E6229"))
                    .frame(width: 7, height: 12)
                    .rotationEffect(.degrees(step % 2 == 0 ? 8 : 14))
            }
            .offset(y: -1)

            // Round Soulful Eyes
            HStack(spacing: 8) {
                if action == .sleeping {
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                } else if action == .happy {
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.9))
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.9))
                } else {
                    ZStack {
                        Circle().fill(Color(hex: "#1E1E24")).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 1.6, height: 1.6).offset(x: -0.7, y: -0.7)
                    }
                    ZStack {
                        Circle().fill(Color(hex: "#1E1E24")).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 1.6, height: 1.6).offset(x: -0.7, y: -0.7)
                    }
                }
            }
            .offset(y: -1)

            // Puppy Snout with Wet Button Nose & Panting Tongue
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(hex: "#1E1E24"))
                    .frame(width: 4.5, height: 2.8)

                if isSinging || action == .happy {
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 0)
                        .fill(Color(hex: "#FF4568"))
                        .frame(width: 4.5, height: 5)
                } else {
                    Text("•").font(.system(size: 6)).foregroundColor(.black.opacity(0.6))
                }
            }
            .offset(y: 4)

            // Puppy Paws
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#FBF3D5"))
                    .frame(width: 4.5, height: step % 2 == 0 ? 5 : 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#FBF3D5"))
                    .frame(width: 4.5, height: step % 2 == 0 ? 3 : 5)
            }
            .offset(y: 13)

            // Fitted DJ Headphones for Dog
            if hat == .djHeadphones {
                ZStack {
                    Path { p in
                        p.addArc(center: CGPoint(x: 16, y: 6), radius: 12, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    }
                    .stroke(LinearGradient(colors: [accentColor, Color.cyan], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .shadow(color: accentColor.opacity(0.8), radius: 3)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "#1C1C1E"))
                        .overlay(RoundedRectangle(cornerRadius: 2.5).stroke(accentColor, lineWidth: 1.2))
                        .frame(width: 4.5, height: 10)
                        .position(x: 4, y: 7)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "#1C1C1E"))
                        .overlay(RoundedRectangle(cornerRadius: 2.5).stroke(accentColor, lineWidth: 1.2))
                        .frame(width: 4.5, height: 10)
                        .position(x: 28, y: 7)
                }
                .frame(width: 32, height: 14)
                .offset(y: -7)
            } else if hat == .sunglasses {
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 8, height: 5)
                    Rectangle().fill(Color.black).frame(width: 2, height: 1)
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 8, height: 5)
                }
                .offset(y: -1)
            }

            // MagSafe Golden Lightning Snack
            if isCharging {
                ZStack {
                    Circle().fill(Color(hex: "#30D158").opacity(0.25)).frame(width: 12, height: 12).blur(radius: 1)
                    Image(systemName: "bolt.fill").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "#30D158"))
                }
                .offset(x: 12, y: 6)
            }
        }
        .frame(width: 36, height: 32)
    }
}

// MARK: - Duck Sprite (Waddles 🦆 - Fluffy Duckling)

struct NotchDuckSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool
    let hat: PetHat
    let outfit: PetOutfit
    let isCharging: Bool
    let isTyping: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Grounding Shadow on Notch Ledge
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 26, height: 6)
                .offset(y: 15)

            // Feather crest on crown
            Path { p in
                p.move(to: CGPoint(x: 2, y: 4))
                p.addLine(to: CGPoint(x: 0, y: -1))
                p.addLine(to: CGPoint(x: 4, y: 4))
            }
            .stroke(Color(hex: "#E09C00"), lineWidth: 1.4)
            .offset(y: -10)

            // Duck Round Body
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "#FFD60A"), Color(hex: "#F59E0B")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 26, height: 23)
                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 2)
                .offset(y: 2)

            // Flapping Wing
            Path { p in
                p.move(to: CGPoint(x: 1, y: 5))
                let flap = CGFloat(step % 2 == 0 ? -3 : 2)
                p.addQuadCurve(to: CGPoint(x: 9, y: 12 + flap), control: CGPoint(x: 1, y: 11))
            }
            .stroke(Color(hex: "#D97706"), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            .offset(x: 6, y: 1)

            // Glossy Duck Eye
            ZStack {
                Circle().fill(Color(hex: "#1E1E24")).frame(width: 4, height: 4)
                Circle().fill(Color.white).frame(width: 1.4, height: 1.4).offset(x: -0.7, y: -0.7)
            }
            .offset(x: 3, y: -1)

            // Wide Orange Beak (Opens when singing/quacking)
            ZStack {
                if isSinging {
                    VStack(spacing: 0) {
                        UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 3)
                            .fill(Color(hex: "#FF9500"))
                            .frame(width: 8, height: 2.8)
                        Circle().fill(Color.red).frame(width: 3.5, height: 3.5)
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 0)
                            .fill(Color(hex: "#FF9500"))
                            .frame(width: 7, height: 2.4)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 8, height: 3.6)
                }
            }
            .offset(x: 9, y: 4)

            // Orange Webbed Feet
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 1.5).fill(Color(hex: "#FF9500")).frame(width: 5, height: 3).offset(y: step % 2 == 0 ? 0 : 2)
                RoundedRectangle(cornerRadius: 1.5).fill(Color(hex: "#FF9500")).frame(width: 5, height: 3).offset(y: step % 2 == 0 ? 2 : 0)
            }
            .offset(x: -1, y: 13)

            // Fitted DJ Headphones for Duck
            if hat == .djHeadphones {
                ZStack {
                    Path { p in
                        p.addArc(center: CGPoint(x: 13, y: 6), radius: 10, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .shadow(color: accentColor.opacity(0.8), radius: 2)

                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#1C1C1E")).frame(width: 4, height: 8).position(x: 3, y: 6)
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#1C1C1E")).frame(width: 4, height: 8).position(x: 23, y: 6)
                }
                .frame(width: 26, height: 12)
                .offset(y: -8)
            }
        }
        .frame(width: 36, height: 32)
    }
}

// MARK: - Spider Sprite (Webby 🕷️ - Notch Acrobat with 8 Jointed Legs)

struct NotchSpiderSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool
    let isDangling: Bool
    let hat: PetHat
    let outfit: PetOutfit
    let isCharging: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            // Grounding Shadow on Notch Ledge
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 26, height: 5)
                .offset(y: 13)

            // 8 Animated Jointed Spindly Legs (4 Left, 4 Right)
            // Left legs
            Group {
                Path { p in
                    p.move(to: CGPoint(x: 10, y: 9))
                    let j = CGFloat(step % 2 == 0 ? -3 : -1)
                    p.addLine(to: CGPoint(x: 2, y: 4 + j))
                    p.addLine(to: CGPoint(x: -3, y: 11 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 10, y: 12))
                    let j = CGFloat(step % 2 == 0 ? -1 : -3)
                    p.addLine(to: CGPoint(x: 1, y: 10 + j))
                    p.addLine(to: CGPoint(x: -4, y: 16 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 10, y: 15))
                    let j = CGFloat(step % 2 == 0 ? 0 : -2)
                    p.addLine(to: CGPoint(x: 2, y: 17 + j))
                    p.addLine(to: CGPoint(x: -2, y: 22 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 11, y: 18))
                    let j = CGFloat(step % 2 == 0 ? 2 : -1)
                    p.addLine(to: CGPoint(x: 4, y: 23 + j))
                    p.addLine(to: CGPoint(x: 1, y: 26 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }

            // Right legs
            Group {
                Path { p in
                    p.move(to: CGPoint(x: 22, y: 9))
                    let j = CGFloat(step % 2 == 0 ? -1 : -3)
                    p.addLine(to: CGPoint(x: 30, y: 4 + j))
                    p.addLine(to: CGPoint(x: 35, y: 11 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 22, y: 12))
                    let j = CGFloat(step % 2 == 0 ? -3 : -1)
                    p.addLine(to: CGPoint(x: 31, y: 10 + j))
                    p.addLine(to: CGPoint(x: 36, y: 16 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 22, y: 15))
                    let j = CGFloat(step % 2 == 0 ? -2 : 0)
                    p.addLine(to: CGPoint(x: 30, y: 17 + j))
                    p.addLine(to: CGPoint(x: 34, y: 22 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 21, y: 18))
                    let j = CGFloat(step % 2 == 0 ? -1 : 2)
                    p.addLine(to: CGPoint(x: 28, y: 23 + j))
                    p.addLine(to: CGPoint(x: 31, y: 26 + j))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }

            // Fuzzy Velvet Spider Body (3D Spherical Gradients)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: "#5C5C60"), Color(hex: "#242426"), Color(hex: "#101012")], center: .center, startRadius: 1, endRadius: 10))
                    .frame(width: 17, height: 16)
                    .offset(y: 1)

                Circle()
                    .fill(Color(hex: "#2C2C2E"))
                    .frame(width: 13, height: 11)
                    .offset(y: 6)
            }

            // Big Reflective Anime Eyes (Lucas the Spider Style!)
            HStack(spacing: 3) {
                if action == .sleeping {
                    Text("◡").font(.system(size: 7, weight: .bold)).foregroundColor(.cyan)
                    Text("◡").font(.system(size: 7, weight: .bold)).foregroundColor(.cyan)
                } else if action == .happy {
                    Text("^").font(.system(size: 7, weight: .bold)).foregroundColor(.cyan)
                    Text("^").font(.system(size: 7, weight: .bold)).foregroundColor(.cyan)
                } else {
                    ZStack {
                        Circle().fill(Color.cyan).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color(hex: "#101012")).frame(width: 3.2, height: 3.2)
                        Circle().fill(Color.white).frame(width: 1.3, height: 1.3).offset(x: -0.7, y: -0.7)
                        Circle().fill(Color.white).frame(width: 0.7, height: 0.7).offset(x: 0.7, y: 0.7)
                    }
                    ZStack {
                        Circle().fill(Color.cyan).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color(hex: "#101012")).frame(width: 3.2, height: 3.2)
                        Circle().fill(Color.white).frame(width: 1.3, height: 1.3).offset(x: -0.7, y: -0.7)
                        Circle().fill(Color.white).frame(width: 0.7, height: 0.7).offset(x: 0.7, y: 0.7)
                    }
                }
            }
            .offset(y: 4)

            // Pink Cheeks
            HStack(spacing: 9) {
                Circle().fill(Color.pink.opacity(0.6)).frame(width: 2.5, height: 2.5)
                Circle().fill(Color.pink.opacity(0.6)).frame(width: 2.5, height: 2.5)
            }
            .offset(y: 8)

            // Spider Fangs / Mouth
            if isSinging {
                Circle().fill(Color.red).frame(width: 3, height: 3).offset(y: 9.5)
            } else {
                HStack(spacing: 2) {
                    Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 1.2, y: 2.4)); p.addLine(to: CGPoint(x: 2.4, y: 0)) }.fill(Color.white).frame(width: 2.4, height: 2.4)
                }
                .offset(y: 9.5)
            }

            // Cyber DJ Visor for Spider
            if hat == .djHeadphones {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [accentColor, Color.cyan], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 13, height: 3.5)
                    .shadow(color: accentColor.opacity(0.8), radius: 2)
                    .offset(y: 4)
            }
        }
        .frame(width: 38, height: 32)
    }
}

// MARK: - Orb Sprite (Lumi 🔮 - Holographic Audio Sphere)

struct NotchOrbSprite: View {
    let action: NotchPetAction
    let step: Int
    let color: Color
    let isSinging: Bool
    let hat: PetHat
    let outfit: PetOutfit
    let isCharging: Bool

    var body: some View {
        ZStack {
            // Grounding Shadow on Notch Ledge
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 24, height: 6)
                .offset(y: 14)

            // Pulsing Outer Glow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 28, height: 28)
                .blur(radius: 3)

            // Equator Audio Waveform Ring
            Circle()
                .stroke(
                    LinearGradient(colors: [color, color.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
                .frame(width: 27, height: 11)
                .rotationEffect(.degrees(Double(step * 35)))

            // Core 3D Liquid Orb
            Circle()
                .fill(RadialGradient(colors: [Color.white, color, Color(hex: "#0A0A0C")], center: .center, startRadius: 1, endRadius: 11))
                .frame(width: 22, height: 22)
                .shadow(color: color.opacity(0.6), radius: 4)

            // Digital Eyes
            HStack(spacing: 5) {
                if action == .sleeping {
                    Text("-").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                    Text("-").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                } else if action == .happy {
                    Text("^").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                    Text("^").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                } else {
                    Circle().fill(Color.white).frame(width: 2.5, height: 2.5)
                    Circle().fill(Color.white).frame(width: 2.5, height: 2.5)
                }
            }

            // Equalizer ring when DJ headphones active
            if hat == .djHeadphones || isSinging {
                HStack(spacing: 1.5) {
                    RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: 1.2, height: 5)
                    RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: 1.2, height: 7)
                    RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: 1.2, height: 5)
                }
                .offset(y: 4)
            }
        }
        .frame(width: 36, height: 32)
    }
}
