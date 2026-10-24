import SwiftUI

// MARK: - Cat Sprite (Realistic & Adorable Feline)

struct NotchCatSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool

    var body: some View {
        ZStack {
            // Swishing Tail
            Path { path in
                path.move(to: CGPoint(x: 4, y: 18))
                let tailWiggle = CGFloat(step % 2 == 0 ? -4 : 4)
                path.addQuadCurve(to: CGPoint(x: -4, y: 8 + tailWiggle), control: CGPoint(x: -2, y: 16))
            }
            .stroke(Color(hex: "#FF9F0A"), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Back paws
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#E07B00"))
                    .frame(width: 4, height: step % 2 == 0 ? 5 : 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#E07B00"))
                    .frame(width: 4, height: step % 2 == 0 ? 3 : 5)
            }
            .offset(x: 2, y: 16)

            // Cat Body with soft gradient
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#FFA524"), Color(hex: "#E07B00")], startPoint: .top, endPoint: .bottom))
                .frame(width: 28, height: 19)
                .offset(x: 2, y: 7)

            // Cream Tummy Patch
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#FFF4E6"))
                .frame(width: 13, height: 12)
                .offset(x: 2, y: 9)

            // Cat Ears (Pointed with pink inner ear)
            HStack(spacing: 10) {
                // Left Ear
                ZStack {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 7))
                        p.addLine(to: CGPoint(x: 4, y: -2))
                        p.addLine(to: CGPoint(x: 8, y: 7))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#E07B00"))
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
                    .fill(Color(hex: "#E07B00"))
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
            .offset(x: 2, y: -5)

            // Whiskers
            Path { p in
                // Left whiskers
                p.move(to: CGPoint(x: 1, y: 6))
                p.addLine(to: CGPoint(x: -5, y: 5))
                p.move(to: CGPoint(x: 1, y: 8))
                p.addLine(to: CGPoint(x: -5, y: 9))
                // Right whiskers
                p.move(to: CGPoint(x: 23, y: 6))
                p.addLine(to: CGPoint(x: 29, y: 5))
                p.move(to: CGPoint(x: 23, y: 8))
                p.addLine(to: CGPoint(x: 29, y: 9))
            }
            .stroke(Color.white.opacity(0.85), lineWidth: 1)
            .offset(x: -10, y: 0)

            // Eyes (Almond cat eyes with glint)
            HStack(spacing: 8) {
                if action == .sleeping {
                    // Closed sleepy crescent curves
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.75))
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.75))
                } else if action == .happy {
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.85))
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.85))
                } else {
                    ZStack {
                        Circle().fill(Color(hex: "#2C2C2E")).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 1.5, height: 1.5).offset(x: -0.8, y: -0.8)
                    }
                    ZStack {
                        Circle().fill(Color(hex: "#2C2C2E")).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 1.5, height: 1.5).offset(x: -0.8, y: -0.8)
                    }
                }
            }
            .offset(x: 2, y: 2)

            // Pink Nose & Mouth
            VStack(spacing: 1) {
                // Nose
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 3, y: 0))
                    p.addLine(to: CGPoint(x: 1.5, y: 2))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#FF85A2"))
                .frame(width: 3, height: 2)

                // Singing open mouth or smile
                if isSinging {
                    Circle()
                        .fill(Color(hex: "#D70015"))
                        .overlay(Circle().stroke(Color.black.opacity(0.7), lineWidth: 0.8))
                        .frame(width: 4.5, height: 4.5)
                } else {
                    Text("ω")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.7))
                }
            }
            .offset(x: 2, y: 7)

            // Front Paws
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
            }
            .offset(x: 2, y: 16)
        }
        .frame(width: 36, height: 32)
    }
}

// MARK: - Dog Sprite (Playful Puppy with Wagging Tail)

struct NotchDogSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool

    var body: some View {
        ZStack {
            // Wagging Tail
            Path { path in
                path.move(to: CGPoint(x: 4, y: 17))
                let tailWag = CGFloat(step % 2 == 0 ? -5 : 5)
                path.addQuadCurve(to: CGPoint(x: -3, y: 10 + tailWag), control: CGPoint(x: 0, y: 14))
            }
            .stroke(Color(hex: "#C68B45"), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))

            // Dog Body
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#E0A96D"), Color(hex: "#C68B45")], startPoint: .top, endPoint: .bottom))
                .frame(width: 29, height: 20)
                .offset(x: 2, y: 7)

            // Chest Cream Patch
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#FBF3D5"))
                .frame(width: 14, height: 13)
                .offset(x: 2, y: 9)

            // Floppy Puppy Ears
            HStack(spacing: 16) {
                // Left floppy ear
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#9E6229"))
                    .frame(width: 7, height: 13)
                    .rotationEffect(.degrees(step % 2 == 0 ? -8 : -14))

                // Right floppy ear
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#9E6229"))
                    .frame(width: 7, height: 13)
                    .rotationEffect(.degrees(step % 2 == 0 ? 8 : 14))
            }
            .offset(x: 2, y: 0)

            // Round Soulful Puppy Eyes
            HStack(spacing: 9) {
                if action == .sleeping {
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                } else if action == .happy {
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.9))
                    Text("^").font(.system(size: 9, weight: .bold)).foregroundColor(.black.opacity(0.9))
                } else {
                    ZStack {
                        Circle().fill(Color(hex: "#1C1C1E")).frame(width: 5, height: 5)
                        Circle().fill(Color.white).frame(width: 1.8, height: 1.8).offset(x: -1, y: -1)
                    }
                    ZStack {
                        Circle().fill(Color(hex: "#1C1C1E")).frame(width: 5, height: 5)
                        Circle().fill(Color.white).frame(width: 1.8, height: 1.8).offset(x: -1, y: -1)
                    }
                }
            }
            .offset(x: 2, y: 2)

            // Snout with Black Button Nose & Pink Tongue
            VStack(spacing: 1) {
                // Shiny Black Nose
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#1C1C1E"))
                    .frame(width: 5, height: 3)

                // Tongue panting or singing
                if isSinging || action == .happy {
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 0)
                        .fill(Color(hex: "#FF4568"))
                        .frame(width: 5, height: 5)
                } else {
                    Text("•")
                        .font(.system(size: 6))
                        .foregroundColor(Color.black.opacity(0.6))
                }
            }
            .offset(x: 2, y: 8)

            // Puppy Paws
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#FBF3D5"))
                    .frame(width: 4, height: step % 2 == 0 ? 5 : 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#FBF3D5"))
                    .frame(width: 4, height: step % 2 == 0 ? 3 : 5)
            }
            .offset(x: 2, y: 16)
        }
        .frame(width: 36, height: 32)
    }
}

// MARK: - Duck Sprite (Cute Waddling Duckling)

struct NotchDuckSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool

    var body: some View {
        ZStack {
            // Feather tuft on head
            Path { p in
                p.move(to: CGPoint(x: 3, y: 4))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 6, y: 4))
            }
            .stroke(Color(hex: "#FFCC00"), lineWidth: 1.5)
            .offset(y: -11)

            // Duck Round Body
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "#FFD60A"), Color(hex: "#FFB800")], startPoint: .top, endPoint: .bottom))
                .frame(width: 25, height: 23)
                .offset(y: 4)

            // Wing that flaps during walk/dance
            Path { p in
                p.move(to: CGPoint(x: 2, y: 6))
                let flap = CGFloat(step % 2 == 0 ? -3 : 2)
                p.addQuadCurve(to: CGPoint(x: 10, y: 13 + flap), control: CGPoint(x: 2, y: 12))
            }
            .stroke(Color(hex: "#E09C00"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .offset(x: 7, y: 2)

            // Big Glossy Duck Eyes
            HStack(spacing: 8) {
                if action == .sleeping {
                    Text("◡").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.8))
                } else if action == .happy {
                    Text("^").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.9))
                } else {
                    ZStack {
                        Circle().fill(Color(hex: "#1C1C1E")).frame(width: 4, height: 4)
                        Circle().fill(Color.white).frame(width: 1.5, height: 1.5).offset(x: -0.8, y: -0.8)
                    }
                }
            }
            .offset(x: 3, y: 1)

            // Wide Orange Beak (Opens when singing/quacking)
            ZStack {
                if isSinging {
                    // Open beak
                    VStack(spacing: 0) {
                        UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 3)
                            .fill(Color(hex: "#FF9500"))
                            .frame(width: 8, height: 3)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 3.5, height: 3.5)
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 0)
                            .fill(Color(hex: "#FF9500"))
                            .frame(width: 7, height: 2.5)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 9, height: 4)
                }
            }
            .offset(x: 9, y: 6)

            // Webbed Feet
            HStack(spacing: 8) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 5, y: 0))
                    p.addLine(to: CGPoint(x: 6, y: 3))
                    p.addLine(to: CGPoint(x: -1, y: 3))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#FF9500"))
                .frame(width: 6, height: 3)
                .offset(y: step % 2 == 0 ? 0 : 2)

                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 5, y: 0))
                    p.addLine(to: CGPoint(x: 6, y: 3))
                    p.addLine(to: CGPoint(x: -1, y: 3))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#FF9500"))
                .frame(width: 6, height: 3)
                .offset(y: step % 2 == 0 ? 2 : 0)
            }
            .offset(x: -1, y: 15)
        }
        .frame(width: 36, height: 32)
    }
}

// MARK: - Spider Sprite (Special Notch Companion with 8 Articulated Legs)

struct NotchSpiderSprite: View {
    let action: NotchPetAction
    let step: Int
    let isSinging: Bool
    let isDangling: Bool

    var body: some View {
        ZStack {
            // 8 Animated Spindly Legs (4 Left, 4 Right)
            // Left 4 Legs
            Group {
                // Leg 1
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 11))
                    let joint = CGFloat(step % 2 == 0 ? -4 : -2)
                    p.addLine(to: CGPoint(x: 3, y: 5 + joint))
                    p.addLine(to: CGPoint(x: -3, y: 13 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // Leg 2
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 14))
                    let joint = CGFloat(step % 2 == 0 ? -2 : -4)
                    p.addLine(to: CGPoint(x: 2, y: 12 + joint))
                    p.addLine(to: CGPoint(x: -4, y: 18 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // Leg 3
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 17))
                    let joint = CGFloat(step % 2 == 0 ? 0 : -3)
                    p.addLine(to: CGPoint(x: 3, y: 19 + joint))
                    p.addLine(to: CGPoint(x: -2, y: 24 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // Leg 4
                Path { p in
                    p.move(to: CGPoint(x: 13, y: 20))
                    let joint = CGFloat(step % 2 == 0 ? 2 : -1)
                    p.addLine(to: CGPoint(x: 5, y: 25 + joint))
                    p.addLine(to: CGPoint(x: 1, y: 28 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }

            // Right 4 Legs
            Group {
                // Leg 5
                Path { p in
                    p.move(to: CGPoint(x: 24, y: 11))
                    let joint = CGFloat(step % 2 == 0 ? -2 : -4)
                    p.addLine(to: CGPoint(x: 33, y: 5 + joint))
                    p.addLine(to: CGPoint(x: 39, y: 13 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // Leg 6
                Path { p in
                    p.move(to: CGPoint(x: 24, y: 14))
                    let joint = CGFloat(step % 2 == 0 ? -4 : -2)
                    p.addLine(to: CGPoint(x: 34, y: 12 + joint))
                    p.addLine(to: CGPoint(x: 40, y: 18 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // Leg 7
                Path { p in
                    p.move(to: CGPoint(x: 24, y: 17))
                    let joint = CGFloat(step % 2 == 0 ? -3 : 0)
                    p.addLine(to: CGPoint(x: 33, y: 19 + joint))
                    p.addLine(to: CGPoint(x: 38, y: 24 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // Leg 8
                Path { p in
                    p.move(to: CGPoint(x: 23, y: 20))
                    let joint = CGFloat(step % 2 == 0 ? -1 : 2)
                    p.addLine(to: CGPoint(x: 31, y: 25 + joint))
                    p.addLine(to: CGPoint(x: 35, y: 28 + joint))
                }
                .stroke(Color(hex: "#3A3A3C"), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }

            // Fuzzy Velvet Spider Body (Abdomen & Cephalothorax)
            ZStack {
                // Abdomen (rear)
                Circle()
                    .fill(
                        RadialGradient(colors: [Color(hex: "#48484A"), Color(hex: "#1C1C1E")], center: .center, startRadius: 2, endRadius: 10)
                    )
                    .frame(width: 17, height: 16)
                    .offset(y: 4)

                // Head
                Circle()
                    .fill(Color(hex: "#2C2C2E"))
                    .frame(width: 13, height: 11)
                    .offset(y: 9)
            }

            // Big Glossy Anime Spider Eyes (Primary pair) + Secondary pair
            VStack(spacing: 1) {
                // Secondary tiny top eyes
                HStack(spacing: 4) {
                    Circle().fill(Color.cyan).frame(width: 1.5, height: 1.5)
                    Circle().fill(Color.cyan).frame(width: 1.5, height: 1.5)
                }

                // Primary big expressive eyes
                HStack(spacing: 3) {
                    if action == .sleeping {
                        Text("◡").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.8))
                        Text("◡").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.8))
                    } else if action == .happy {
                        Text("^").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.9))
                        Text("^").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.9))
                    } else {
                        ZStack {
                            Circle().fill(Color.cyan).frame(width: 4.5, height: 4.5)
                            Circle().fill(Color(hex: "#1C1C1E")).frame(width: 3, height: 3)
                            Circle().fill(Color.white).frame(width: 1.2, height: 1.2).offset(x: -0.8, y: -0.8)
                        }
                        ZStack {
                            Circle().fill(Color.cyan).frame(width: 4.5, height: 4.5)
                            Circle().fill(Color(hex: "#1C1C1E")).frame(width: 3, height: 3)
                            Circle().fill(Color.white).frame(width: 1.2, height: 1.2).offset(x: -0.8, y: -0.8)
                        }
                    }
                }
            }
            .offset(y: 7)

            // Pink Cheeks / Blush
            HStack(spacing: 8) {
                Circle().fill(Color.pink.opacity(0.6)).frame(width: 2.5, height: 2.5)
                Circle().fill(Color.pink.opacity(0.6)).frame(width: 2.5, height: 2.5)
            }
            .offset(y: 11)

            // Cute Spider Fangs / Singing Mouth
            if isSinging {
                Circle()
                    .fill(Color.red)
                    .frame(width: 3, height: 3)
                    .offset(y: 12)
            } else {
                HStack(spacing: 2) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 0))
                        p.addLine(to: CGPoint(x: 1.5, y: 3))
                        p.addLine(to: CGPoint(x: 3, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 3, height: 3)
                }
                .offset(y: 12.5)
            }
        }
        .frame(width: 42, height: 34)
    }
}

// MARK: - Orb Sprite (Cosmic Energy Sphere with Liquid Ring)

struct NotchOrbSprite: View {
    let action: NotchPetAction
    let step: Int
    let color: Color
    let isSinging: Bool

    var body: some View {
        ZStack {
            // Pulsing Outer Glow
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 30, height: 30)
                .blur(radius: 4)

            // Orbiting Ring
            Circle()
                .stroke(
                    LinearGradient(colors: [color.opacity(0.9), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
                .frame(width: 28, height: 12)
                .rotationEffect(.degrees(Double(step * 35)))

            // Core Orb
            Circle()
                .fill(
                    RadialGradient(colors: [Color.white, color, Color(hex: "#0A0A0C")], center: .center, startRadius: 1, endRadius: 12)
                )
                .frame(width: 22, height: 22)
                .shadow(color: color.opacity(0.6), radius: 5)

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

            // Singing waveform inside orb
            if isSinging {
                HStack(spacing: 1.5) {
                    RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: 1.5, height: 5)
                    RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: 1.5, height: 8)
                    RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: 1.5, height: 5)
                }
                .offset(y: 4)
            }
        }
        .frame(width: 36, height: 32)
    }
}
