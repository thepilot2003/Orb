import SwiftUI
import Combine
import AppKit
import AVFoundation
import QuartzCore

// MARK: - Native Text Display

struct MarqueeTextView: View {
    let text: String
    let font: Font
    let color: Color
    var scrollEnabled: Bool = true

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

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
            phase = 2
        }
    }
}

struct AppleMusicKaraokeLyricView: View {
    let line: LyricLine
    let currentTime: Double
    var font: Font = .system(size: 13, weight: .bold, design: .rounded)

    private var progress: CGFloat {
        let dur = max(line.endTime - line.time, 0.35)
        let effectiveTime = currentTime + OrbState.shared.lyricsOffsetSeconds
        let raw = (effectiveTime - line.time) / dur
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

// MARK: - Motion Artwork Looper View (Apple Music Animated Artwork)

struct DynamicIslandArtworkVideoView: NSViewRepresentable {
    let url: URL
    let cornerRadius: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> DynamicIslandArtworkVideoContainerView {
        let view = DynamicIslandArtworkVideoContainerView(cornerRadius: cornerRadius)
        context.coordinator.attach(layer: view.playerLayer, url: url)
        return view
    }

    func updateNSView(_ nsView: DynamicIslandArtworkVideoContainerView, context: Context) {
        nsView.updateCornerRadius(cornerRadius)
        context.coordinator.attach(layer: nsView.playerLayer, url: url)
    }

    final class Coordinator {
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var currentURL: URL?

        func attach(layer: AVPlayerLayer, url: URL) {
            if currentURL != url || player == nil {
                currentURL = url
                let item = AVPlayerItem(url: url)
                let qPlayer = AVQueuePlayer(playerItem: item)
                qPlayer.isMuted = true
                qPlayer.actionAtItemEnd = .none
                self.looper = AVPlayerLooper(player: qPlayer, templateItem: item)
                self.player = qPlayer
                layer.player = qPlayer
                qPlayer.play()
            }
            if layer.player !== self.player {
                layer.player = self.player
                self.player?.play()
            }
        }

        deinit {
            player?.pause()
            looper = nil
            player = nil
        }
    }
}

final class DynamicIslandArtworkVideoContainerView: NSView {
    let playerLayer = AVPlayerLayer()

    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = cornerRadius
        layer?.backgroundColor = NSColor.clear.cgColor
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.clear.cgColor
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { nil }

    func updateCornerRadius(_ radius: CGFloat) {
        layer?.cornerRadius = radius
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}

// MARK: - Dynamic Glass (Apple NSGlassEffectView + Real-time backdrop refraction)

struct LiquidGlassBackgroundView: NSViewRepresentable {
    var cornerRadius: CGFloat
    var variant: Int = 11

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        container.wantsLayer = true
        container.layer?.masksToBounds = true
        container.layer?.cornerRadius = cornerRadius

        if let glassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glass = glassClass.init(frame: .zero)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.setValue(cornerRadius, forKey: "cornerRadius")

            // Private variant selector _setVariant:
            let sel = NSSelectorFromString("_setVariant:")
            if glass.responds(to: sel) {
                let imp = glass.method(for: sel)
                typealias VariantFn = @convention(c) (AnyObject, Selector, Int) -> Void
                let fn = unsafeBitCast(imp, to: VariantFn.self)
                fn(glass, sel, variant)
            }
            container.addSubview(glass)
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                glass.topAnchor.constraint(equalTo: container.topAnchor),
                glass.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            // Configure backdrop layer for live desktop refraction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak glass] in
                guard let glass = glass else { return }
                func configureBackdrops(_ layer: CALayer) {
                    if NSStringFromClass(type(of: layer)).contains("CABackdropLayer") {
                        layer.setValue(true, forKey: "windowServerAware")
                        layer.setValue(1.0, forKey: "scale")
                    }
                    layer.sublayers?.forEach { configureBackdrops($0) }
                }
                if let root = glass.layer { configureBackdrops(root) }
            }
        } else {
            let effect = NSVisualEffectView(frame: .zero)
            effect.translatesAutoresizingMaskIntoConstraints = false
            effect.material = .hudWindow
            effect.blendingMode = .behindWindow
            effect.state = .active
            container.addSubview(effect)
            NSLayoutConstraint.activate([
                effect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                effect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                effect.topAnchor.constraint(equalTo: container.topAnchor),
                effect.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Shape

struct OrbNotchShape: Shape {
    var topEarRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topEarRadius, bottomCornerRadius) }
        set { topEarRadius = newValue.first; bottomCornerRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let ear = min(topEarRadius, rect.height / 2)
        let bottomR = min(bottomCornerRadius, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear, y: ear), control: CGPoint(x: rect.minX + ear, y: 0))
        path.addLine(to: CGPoint(x: rect.minX + ear, y: rect.maxY - bottomR))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear + bottomR, y: rect.maxY), control: CGPoint(x: rect.minX + ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - ear - bottomR, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - ear, y: rect.maxY - bottomR), control: CGPoint(x: rect.maxX - ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: ear))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: 0), control: CGPoint(x: rect.maxX - ear, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Motion

enum OrbMotion {
    /// Opening / closing the island: slightly bouncy, like liquid.
    static let morph = Animation.spring(response: 0.46, dampingFraction: 0.78)
    /// The small "peek" when the cursor touches the collapsed island.
    static let peek = Animation.spring(response: 0.3, dampingFraction: 0.62)
    /// Small state changes (play/pause icon, buttons).
    static let quick = Animation.spring(response: 0.32, dampingFraction: 0.8)
    /// Content swapping (track changes).
    static let content = Animation.spring(response: 0.5, dampingFraction: 0.86)
}

struct OrbPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Blur transition (content sharpens in, blurs out)

struct BlurFadeModifier: ViewModifier {
    var radius: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

extension AnyTransition {
    static func blurFade(_ radius: CGFloat = 10) -> AnyTransition {
        AnyTransition.modifier(active: BlurFadeModifier(radius: radius, opacity: 0),
                               identity: BlurFadeModifier(radius: 0, opacity: 1))
    }
}

// MARK: - Native AppKit Visual Effect (Behind-Window Blur)

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Liquid glass helper

struct OrbGlass<S: Shape>: ViewModifier {
    @ObservedObject var state = OrbState.shared
    var shape: S
    var tint: Color?

    func body(content: Content) -> some View {
        switch state.glassStyle {
        case .solid:
            content
                .background(shape.fill(Color.white.opacity(0.10)))
        case .frosted:
            content
                .background(shape.fill(Color.white.opacity(0.08)))
                .overlay(shape.stroke(Color.white.opacity(0.14), lineWidth: 0.5))
        case .dynamicGlass:
            content
                .background(shape.fill(Color.white.opacity(0.06)))
                .overlay(shape.stroke(Color.white.opacity(0.18), lineWidth: 0.5))
        case .albumArt:
            content
                .background(
                    ZStack {
                        shape.fill(Color.white.opacity(0.08))
                        if let tint = tint ?? (state.playback != .stopped ? state.artColor : nil) {
                            shape.fill(tint.opacity(0.25))
                        }
                    }
                )
                .overlay(shape.stroke(Color.white.opacity(0.22), lineWidth: 0.6))
        }
    }
}

extension View {
    func orbGlass<S: Shape>(_ shape: S, tint: Color? = nil) -> some View {
        modifier(OrbGlass(shape: shape, tint: tint))
    }
}

// MARK: - Main notch view
// Hover / click handling lives in AppDelegate (mouse monitors), so the transparent part
// of the panel never blocks clicks on the menu bar or other apps.

struct OrbNotchView: View {
    @ObservedObject var state = OrbState.shared

    private var cornerRadius: CGFloat {
        if state.isExpanded { return 28 }
        if state.isCompactDroppedDown { return 18 }
        return 11
    }

    private var expandTransition: AnyTransition {
        let appear = state.progressiveBlur ? AnyTransition.blurFade(12) : AnyTransition.opacity
        return AnyTransition.asymmetric(
            insertion: appear
                .combined(with: AnyTransition.scale(scale: 0.94, anchor: .top))
                .animation(.easeOut(duration: 0.34).delay(0.07)),
            removal: AnyTransition.opacity.animation(.easeIn(duration: 0.1))
        )
    }

    var body: some View {
        let shape = OrbNotchShape(topEarRadius: 10, bottomCornerRadius: cornerRadius)
        let raised = state.isExpanded || state.isCompactDroppedDown

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                IslandBackground(state: state, shape: shape)
                panels
            }
            .frame(width: state.currentNotchWidth + 20, height: state.currentNotchHeight, alignment: .top)
            .clipShape(shape)
            .shadow(color: Color.black.opacity(raised ? 0.5 : 0), radius: 16, y: 8)
            .animation(OrbMotion.morph, value: state.isExpanded)
            .animation(OrbMotion.peek, value: state.isHovered)
            .animation(OrbMotion.morph, value: state.isBannerVisible)
            .animation(OrbMotion.morph, value: state.playback)
            .animation(.interactiveSpring(), value: state.widthOffsetPx)
            .animation(.interactiveSpring(), value: state.heightOffsetPx)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var panels: some View {
        if state.isExpanded {
            Group {
                if state.playback == .stopped {
                    IdlePanel(state: state)
                } else {
                    NowPlayingPanel(state: state)
                }
            }
            .frame(width: state.expandedWidth, height: state.expandedHeight, alignment: .top)
            .transition(expandTransition)
        } else if state.playback != .stopped {
            CompactPanel(state: state)
                .frame(width: state.currentNotchWidth, height: state.currentNotchHeight, alignment: .top)
                .transition(AnyTransition.opacity)
        }
    }
}

// MARK: - Island background (solid / frosted / liquid glass)

struct IslandBackground: View {
    @ObservedObject var state: OrbState
    var shape: OrbNotchShape

    var body: some View {
        let k = state.glassIntensity
        let hasActiveTrack = state.playback != .stopped

        ZStack {
            base(k)

            if state.glassStyle != .solid {
                tintLayers(k, isMusic: hasActiveTrack)
            }

            // Ambient artwork blur backdrop when music is active
            if state.isExpanded, hasActiveTrack, let image = state.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: state.expandedWidth + 30, height: state.expandedHeight + 30)
                    .blur(radius: 40)
                    .opacity(state.glassStyle == .albumArt ? 0.42 + 0.32 * k : (state.glassStyle == .solid ? 0.16 : 0.22))
                    .mask(
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: Color.clear, location: 0.0),
                                Gradient.Stop(color: Color.black.opacity(0.4), location: 0.22),
                                Gradient.Stop(color: Color.black, location: 1.0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .id(state.artworkVersion)
                    .transition(AnyTransition.opacity)
                    .allowsHitTesting(false)
            }

            if state.glassStyle != .solid {
                rim
            }
        }
        .animation(.easeInOut(duration: 0.45), value: state.artworkVersion)
        .animation(.easeInOut(duration: 0.35), value: state.playback)
    }

    @ViewBuilder
    private func base(_ k: Double) -> some View {
        switch state.glassStyle {
        case .solid:
            shape.fill(Color.black)

        case .frosted:
            // Crisp, high-transmittance frosted glass
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                    .clipShape(shape)
                shape.fill(Color.white.opacity(0.04 + 0.04 * k))
                shape.fill(Color.black.opacity(0.10 - 0.03 * k))

                // Surface optical sheen
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.white.opacity(0.14 * k + 0.04), location: 0.0),
                        Gradient.Stop(color: Color.white.opacity(0.03), location: 0.3),
                        Gradient.Stop(color: Color.clear, location: 0.6),
                        Gradient.Stop(color: Color.white.opacity(0.05 * k), location: 1.0)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }

        case .dynamicGlass:
            // Dynamic liquid glass with Apple's private NSGlassEffectView
            ZStack {
                LiquidGlassBackgroundView(cornerRadius: shape.bottomCornerRadius)
                    .clipShape(shape)
                shape.fill(Color.white.opacity(0.03 + 0.03 * k))
                shape.fill(Color.black.opacity(0.08 - 0.02 * k))

                // Surface optical sheen
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.white.opacity(0.18 * k + 0.06), location: 0.0),
                        Gradient.Stop(color: Color.white.opacity(0.04), location: 0.25),
                        Gradient.Stop(color: Color.clear, location: 0.6),
                        Gradient.Stop(color: Color.white.opacity(0.08 * k), location: 1.0)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }

        case .albumArt:
            // Dynamic subtle album art aura with frosted glass
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                    .clipShape(shape)

                shape.fill(Color.black.opacity(0.12))
                shape.fill(Color.white.opacity(0.04 + 0.02 * k))

                if state.playback != .stopped, let image = state.artworkImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(1.2)
                        .blur(radius: 36)
                        .opacity(0.18 + 0.14 * k)
                        .clipShape(shape)
                }

                // Surface optical sheen
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.white.opacity(0.16 * k + 0.05), location: 0.0),
                        Gradient.Stop(color: Color.white.opacity(0.04), location: 0.28),
                        Gradient.Stop(color: Color.clear, location: 0.58),
                        Gradient.Stop(color: Color.white.opacity(0.07 * k), location: 1.0)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
        }
    }

    private func tintLayers(_ k: Double, isMusic: Bool) -> some View {
        let isAlbumArt = state.glassStyle == .albumArt
        let primaryColor = isMusic ? state.artColor : state.accentColor.opacity(0.4)

        return ZStack {
            RadialGradient(colors: [primaryColor.opacity(isAlbumArt ? 0.20 * k + 0.06 : 0.09 * k), Color.clear],
                           center: .topLeading, startRadius: 0, endRadius: 280)
            if isMusic {
                RadialGradient(colors: [primaryColor.opacity(isAlbumArt ? 0.14 * k : 0.05 * k), Color.clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 220)
            }
            LinearGradient(colors: [Color.white.opacity(isAlbumArt ? 0.06 : 0.03), Color.clear],
                           startPoint: .top, endPoint: .bottom)
        }
        .allowsHitTesting(false)
    }

    /// Specular glass rim: razor-sharp specular edge
    private var rim: some View {
        let rimAlpha = state.glassStyle == .albumArt ? 0.45 : 0.35
        return shape
            .stroke(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.white.opacity(rimAlpha * 1.2), location: 0.0),
                        Gradient.Stop(color: Color.white.opacity(rimAlpha * 0.4), location: 0.35),
                        Gradient.Stop(color: Color.white.opacity(0.06), location: 0.65),
                        Gradient.Stop(color: Color.white.opacity(rimAlpha * 0.8), location: 1.0)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1)
            .allowsHitTesting(false)
    }
}

// MARK: - Progressive blur (sharp near the top, increasingly blurred towards the bottom)

struct ProgressiveBlurBackdrop: View {
    let image: NSImage
    let size: CGSize
    let progressive: Bool

    var body: some View {
        ZStack {
            if progressive {
                layer(2, [stop(0, 1), stop(0.2, 1), stop(0.45, 0)])
                layer(9, [stop(0.1, 0), stop(0.35, 1), stop(0.55, 1), stop(0.8, 0)])
                layer(20, [stop(0.4, 0), stop(0.7, 1), stop(0.85, 1), stop(1.0, 0.6)])
                layer(36, [stop(0.65, 0), stop(1.0, 1)])
            } else {
                layer(30, [stop(0, 1), stop(1, 1)])
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func stop(_ location: CGFloat, _ opacity: Double) -> Gradient.Stop {
        Gradient.Stop(color: Color.black.opacity(opacity), location: location)
    }

    private func layer(_ radius: CGFloat, _ stops: [Gradient.Stop]) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipped()
            .scaleEffect(1.2)
            .saturation(1.25)
            .blur(radius: radius)
            .mask(LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom))
    }
}

// MARK: - Compact (collapsed) panel + track-change banner

struct CompactPanel: View {
    @ObservedObject var state = OrbState.shared

    var body: some View {
        VStack(spacing: 0) {
            // Top notch row: Album Art on left, Waveform on right (aligned with the notch wings)
            HStack(spacing: 8) {
                ArtworkView(state: state, size: 22, corner: 6)
                    .padding(.leading, 12)

                Spacer(minLength: 4)

                WaveformView(style: state.waveformStyle,
                             color: state.color(for: state.waveformColor),
                             isPlaying: state.playback == .playing,
                             width: 18, height: 13, barCount: 4)
                    .padding(.trailing, 12)
            }
            .frame(height: state.baseHeight)

            // Dropped-down sneak peek row: sits completely below the hardware camera notch!
            if state.isCompactDroppedDown {
                sneakPeekRow
                    .id(state.trackID)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -4)).animation(.spring(response: 0.32, dampingFraction: 0.78)),
                        removal: .opacity.animation(.easeOut(duration: 0.12))
                    ))
            }
        }
        .animation(OrbMotion.peek, value: state.isHovered)
        .animation(OrbMotion.content, value: state.trackID)
    }

    private var lyricsTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    private var songTitleRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "music.note")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(state.accentColor)

            let combinedTitle = (state.keepArtistVisible || state.isHovered) && !state.artistName.isEmpty
                ? "\(state.trackName) · \(state.artistName)"
                : state.trackName

            Text(combinedTitle)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var sneakPeekRow: some View {
        Group {
            if state.showLyricsBelowNotch && !state.lyrics.isEmpty {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state.playback != .playing)) { timeline in
                    let pos = state.livePosition(at: timeline.date)
                    if let active = state.activeLyric(at: pos) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(state.accentColor)

                            AppleMusicKaraokeLyricView(line: active.line, currentTime: pos, font: .system(size: 11.5, weight: .semibold, design: .rounded))
                                .id(active.line.id)
                                .transition(lyricsTransition)
                                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: active.line.id)
                        }
                    } else if let first = state.lyrics.first, pos < first.time {
                        HStack(spacing: 6) {
                            IntroDotsView(accentColor: state.accentColor)
                            Text(first.text)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        .transition(lyricsTransition)
                    } else {
                        songTitleRow
                    }
                }
            } else {
                songTitleRow
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
    }
}

// MARK: - Expanded: now playing

struct QueuePanel: View {
    @ObservedObject var state: OrbState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Up Next")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        state.isQueueOpen = false
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(state.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            if state.upNextQueue.isEmpty {
                VStack(spacing: 4) {
                    Text("No upcoming queue loaded")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(state.upNextQueue) { track in
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 9))
                                    .foregroundColor(state.accentColor)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(track.title)
                                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.65))
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(OrbState.format(track.duration))
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.45))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .frame(maxHeight: 75)
            }
        }
        .transition(.opacity)
    }
}

struct NowPlayingPanel: View {
    @ObservedObject var state: OrbState

    var body: some View {
        VStack(spacing: 0) {
            // Sits comfortably below the hardware notch cutout and menu bar
            Spacer().frame(height: state.baseHeight + 10)

            // 1. Top Row: Artwork + Track details + Waveform
            HStack(spacing: 12) {
                ArtworkView(state: state, size: 54, corner: 12, bordered: true, showBadge: true)
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(state.trackName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(state.artistName)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.75))
                        .lineLimit(1)
                }
                .id(state.trackID)
                .transition(.opacity)

                Spacer(minLength: 6)

                WaveformView(style: state.waveformStyle,
                             color: state.color(for: state.waveformColor),
                             isPlaying: state.playback == .playing,
                             width: 24, height: 16, barCount: 5)
            }
            .padding(.horizontal, 24)

            if state.isQueueOpen {
                Spacer(minLength: 6)
                QueuePanel(state: state)
                Spacer(minLength: 6)
            } else {
                // Apple Music Karaoke Lyrics with alphabet glow sweep
                if state.showLyricsExpanded && !state.lyrics.isEmpty {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state.playback != .playing)) { timeline in
                        let pos = state.livePosition(at: timeline.date)
                        if let active = state.activeLyric(at: pos) {
                            VStack(spacing: 3) {
                                // Previous line preview in subtle dim
                                if active.index > 0 && active.index - 1 < state.lyrics.count {
                                    Text(state.lyrics[active.index - 1].text)
                                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.24))
                                        .lineLimit(1)
                                }

                                // Active illuminated Karaoke line
                                HStack(spacing: 6) {
                                    Image(systemName: "quote.bubble.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(state.accentColor)

                                    AppleMusicKaraokeLyricView(line: active.line, currentTime: pos, font: .system(size: 12.5, weight: .bold, design: .rounded))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .id(active.line.id)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    )
                                )
                                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: active.line.id)

                                // Next line preview in subtle dim
                                if active.index + 1 < state.lyrics.count {
                                    Text(state.lyrics[active.index + 1].text)
                                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.28))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.top, 4)
                        } else if let first = state.lyrics.first, pos < first.time {
                            // Intro section before first lyric starts
                            VStack(spacing: 4) {
                                HStack(spacing: 7) {
                                    IntroDotsView(accentColor: state.accentColor)
                                    Text("Intro")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(state.accentColor.opacity(0.85))
                                    Text("•")
                                        .foregroundColor(Color.white.opacity(0.25))
                                    Text(first.text)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.55))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                            }
                            .padding(.top, 4)
                            .transition(.opacity)
                        } else if let nextIdx = state.lyrics.firstIndex(where: { $0.time > pos }) {
                            // Instrumental break between lyrics
                            VStack(spacing: 4) {
                                HStack(spacing: 7) {
                                    IntroDotsView(accentColor: state.accentColor)
                                    Text("Instrumental")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(state.accentColor.opacity(0.85))
                                    Text("•")
                                        .foregroundColor(Color.white.opacity(0.25))
                                    Text(state.lyrics[nextIdx].text)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.55))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                            }
                            .padding(.top, 4)
                            .transition(.opacity)
                        }
                    }
                }

                Spacer(minLength: 8)

                // 2. Middle Row: Progress Scrubber with time labels
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state.playback != .playing)) { timeline in
                    OrbProgressRow(state: state, position: state.livePosition(at: timeline.date))
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 10)
            }

            // 3. Bottom Row: Media Controls (Queue, Star, Previous, Play/Pause, Next, Device)
            controls
                .padding(.horizontal, 24)

            Spacer().frame(height: 18)
        }
        .animation(OrbMotion.content, value: state.trackID)
    }

    private var controls: some View {
        ZStack {
            // Left & Right flanking utilities
            HStack {
                Button(action: {
                    state.haptic()
                    state.toggleFavorite()
                }) {
                    Image(systemName: state.isFavorited ? "star.fill" : "star")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(state.isFavorited ? Color(hex: "#FFD60A") : Color.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(OrbPressStyle())
                .help("Favorite track")

                Spacer()

                Button(action: {
                    state.haptic()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        state.isQueueOpen.toggle()
                    }
                }) {
                    Image(systemName: state.isQueueOpen ? "list.bullet.circle.fill" : "list.bullet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(state.isQueueOpen ? state.accentColor : Color.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(OrbPressStyle())
                .help("Toggle Queue")
            }

            // Dead-center playback controls
            HStack(spacing: 26) {
                Button(action: {
                    state.haptic()
                    state.skipPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 32)
                }
                .buttonStyle(OrbPressStyle())

                Button(action: {
                    state.haptic()
                    state.togglePlayPause()
                }) {
                    Image(systemName: state.playback == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 38)
                        .contentShape(Rectangle())
                }
                .buttonStyle(OrbPressStyle())

                Button(action: {
                    state.haptic()
                    state.skipNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 32)
                }
                .buttonStyle(OrbPressStyle())
            }
        }
    }
}

// MARK: - Artwork

struct ArtworkView: View {
    @ObservedObject var state: OrbState
    var size: CGFloat
    var corner: CGFloat
    var bordered: Bool = false
    var showBadge: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                LinearGradient(colors: [Color.orange, Color.pink, Color.purple],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.45, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.95))
                    )

                if state.motionArtworkEnabled, let videoUrl = state.videoArtworkURL {
                    DynamicIslandArtworkVideoView(url: videoUrl, cornerRadius: corner)
                        .frame(width: size, height: size)
                        .clipped()
                        .transition(.opacity)
                } else if let image = state.artworkImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .id(state.artworkVersion)
                        .transition(.opacity)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Color.white.opacity(bordered ? 0.25 : 0), lineWidth: 0.75)
            )

            // Source badge (Apple Music / Spotify / Universal Now Playing)
            if showBadge, let source = state.activeSource {
                ZStack {
                    Circle()
                        .fill(badgeColor(for: source))
                    Image(systemName: badgeIcon(for: source))
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 15, height: 15)
                .shadow(color: Color.black.opacity(0.35), radius: 2, y: 1)
                .offset(x: 2, y: 2)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: state.artworkVersion)
    }

    private func badgeColor(for source: PlayerSource) -> Color {
        switch source {
        case .music:
            return Color(red: 0.98, green: 0.18, blue: 0.33)
        case .spotify:
            return Color(red: 0.12, green: 0.84, blue: 0.38)
        case .nowPlaying(let app):
            let lower = app.lowercased()
            if lower.contains("safari") { return Color(red: 0.0, green: 0.48, blue: 1.0) }
            if lower.contains("chrome") { return Color(red: 0.26, green: 0.52, blue: 0.96) }
            if lower.contains("youtube") { return Color(red: 1.0, green: 0.15, blue: 0.15) }
            return Color(red: 0.4, green: 0.36, blue: 0.9)
        }
    }

    private func badgeIcon(for source: PlayerSource) -> String {
        switch source {
        case .music: return "music.note"
        case .spotify: return "waveform"
        case .nowPlaying(let app):
            let lower = app.lowercased()
            if lower.contains("safari") || lower.contains("chrome") || lower.contains("browser") {
                return "globe"
            }
            if lower.contains("youtube") {
                return "play.rectangle.fill"
            }
            return "play.fill"
        }
    }
}

// MARK: - Waveform (live bars / smooth wave), smooth 30 fps, no random jitter

struct WaveformView: View {
    @ObservedObject var state = OrbState.shared
    var style: WaveformStyle
    var color: Color
    var isPlaying: Bool
    var width: CGFloat = 26
    var height: CGFloat = 18
    var barCount: Int = 5

    var body: some View {
        Group {
            switch style {
            case .off:
                EmptyView()
            case .bars:
                bars
            case .wave:
                wave
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPlaying)
    }

    private func barFill(_ index: Int, _ t: Double) -> some ShapeStyle {
        AnyShapeStyle(color)
    }

    private func barHeight(_ index: Int, _ t: Double) -> CGFloat {
        guard isPlaying else { return 4 }
        let phase = Double(index) * 1.3
        let speed = 4.2 + Double(index) * 0.9
        let a = sin(t * speed + phase)
        let b = 0.6 + 0.4 * sin(t * 1.7 + phase * 2)
        // Automix beat-blending dynamic modulation
        let automixMod = state.automixAnimation ? (0.78 + 0.35 * sin(t * 4.8 - Double(index) * 0.85)) : 1.0
        let value = (0.5 + 0.5 * a * b) * automixMod
        let usable = Double(height) - 4
        return CGFloat(4 + max(0.12, min(value, 1.0)) * usable)
    }

    private var bars: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let gap = max(2, (width - CGFloat(barCount) * 3) / CGFloat(max(barCount - 1, 1)))
            HStack(spacing: gap) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(barFill(index, t))
                        .frame(width: 3, height: barHeight(index, t))
                }
            }
            .frame(width: width, height: height)
        }
    }

    private var wave: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                var path = Path()
                let mid = size.height / 2
                let strength: Double = isPlaying ? 1 : 0.05
                var x: CGFloat = 0
                while x <= size.width {
                    let rel = Double(x / size.width)
                    let envelope = sin(rel * Double.pi)
                    let wobble = 0.7 + 0.3 * sin(t * 2.3 + rel * 4)
                    let automixWave = state.automixAnimation ? (0.85 + 0.3 * sin(t * 3.6 + rel * 6)) : 1.0
                    let phase = sin(rel * 10 + t * 7)
                    let amplitude = Double(size.height) * 0.42 * envelope * wobble * automixWave * strength
                    let y = mid + CGFloat(phase * amplitude)
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    x += 1
                }
                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(width: width, height: height)
        }
    }
}

// MARK: - Progress bar (line / glass / waveform) with click + drag to seek

enum WaveSeed {
    /// Stable pseudo-random "waveform" for a track (we can't read real audio data from the player).
    static func heights(seed: String, count: Int) -> [Double] {
        guard count > 0 else { return [] }
        var h = seed.unicodeScalars.reduce(UInt64(5381)) { ($0 &* 33) &+ UInt64($1.value) }
        if h == 0 { h = 12345 }
        var raw: [Double] = []
        for _ in 0..<count {
            h = h &* 6364136223846793005 &+ 1442695040888963407
            raw.append(Double((h >> 33) % 1000) / 1000.0)
        }
        var out = raw
        for i in 0..<count {
            let a = raw[max(0, i - 1)]
            let b = raw[i]
            let c = raw[min(count - 1, i + 1)]
            out[i] = (a + 2 * b + c) / 4
        }
        return out
    }
}

struct OrbProgressRow: View {
    @ObservedObject var state: OrbState
    var position: Double
    @State private var dragFraction: Double? = nil

    var body: some View {
        let duration = state.duration
        let playedFraction = duration > 0 ? min(max(position / duration, 0), 1) : 0
        let fraction = dragFraction ?? playedFraction
        let shown = dragFraction.map { $0 * duration } ?? position

        HStack(spacing: 10) {
            Text(OrbState.format(shown))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.85))
                .frame(width: 32, alignment: .leading)
            bar(fraction: fraction)
            Text("-" + OrbState.format(max(duration - shown, 0)))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.85))
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func bar(fraction: Double) -> some View {
        GeometryReader { geo in
            Group {
                switch state.progressStyle {
                case .capsule:
                    capsuleBar(fraction: fraction, width: geo.size.width)
                case .glass:
                    glassBar(fraction: fraction, width: geo.size.width)
                case .waveform:
                    waveformBar(fraction: fraction, size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragFraction = min(max(Double(value.location.x / max(geo.size.width, 1)), 0), 1)
                    }
                    .onEnded { value in
                        let f = min(max(Double(value.location.x / max(geo.size.width, 1)), 0), 1)
                        state.haptic()
                        state.seek(toFraction: f)
                        dragFraction = nil
                    }
            )
        }
        .frame(height: 18)
    }

    private var barColor: Color { state.color(for: state.progressColor) }

    private func capsuleBar(fraction: Double, width: CGFloat) -> some View {
        let h: CGFloat = dragFraction == nil ? 5 : 7
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.25))
            Capsule().fill(Color.white.opacity(0.95))
                .frame(width: max(h, width * CGFloat(fraction)))
        }
        .frame(height: h)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: dragFraction == nil)
    }

    private func glassBar(fraction: Double, width: CGFloat) -> some View {
        let isDragging = dragFraction != nil
        let h: CGFloat = isDragging ? 9 : 7
        let fillWidth = max(h, width * CGFloat(fraction))
        let thumbSize: CGFloat = isDragging ? 14 : 10

        return ZStack(alignment: .leading) {
            // 1. Translucent glass track background with subtle inner depth
            Capsule()
                .fill(Color.white.opacity(0.12))
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )
                .frame(height: h)

            // 2. Luminous filled track with glass gleam and gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [barColor, barColor.opacity(0.80)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Upper specular shine running along the filled bar
                    VStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.70), Color.white.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: max(1.5, h * 0.35))
                            .padding(.horizontal, 2)
                            .padding(.top, 1)
                        Spacer(minLength: 0)
                    }
                )
                .frame(width: fillWidth, height: h)
                .shadow(color: barColor.opacity(0.4), radius: isDragging ? 4 : 2, y: 0)

            // 3. Polished glass thumb / bead at the leading edge
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 3, y: 1)
                .shadow(color: barColor.opacity(0.6), radius: 4, y: 0)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: max(0, min(fillWidth - thumbSize / 2, width - thumbSize)))
                .opacity(isDragging ? 1.0 : 0.85)
        }
        .frame(height: 14)
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isDragging)
    }

    private func waveformBar(fraction: Double, size: CGSize) -> some View {
        let barW: CGFloat = 2.4
        let gap: CGFloat = 1.8
        let count = max(8, Int((size.width + gap) / (barW + gap)))
        let heights = WaveSeed.heights(seed: state.trackID, count: count)
        let color = barColor
        let dragging = dragFraction != nil

        return Canvas { context, canvasSize in
            for i in 0..<count {
                let norm = heights[i]
                let h = canvasSize.height * CGFloat(0.28 + 0.72 * norm) * (dragging ? 1.0 : 0.88)
                let x = CGFloat(i) * (barW + gap)
                let rect = CGRect(x: x, y: (canvasSize.height - h) / 2, width: barW, height: h)
                let played = (Double(i) + 0.5) / Double(count) <= fraction
                context.fill(Path(roundedRect: rect, cornerRadius: barW / 2),
                             with: .color(played ? color : Color.white.opacity(0.22)))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Expanded: idle (calendar)

struct IdlePanel: View {
    @ObservedObject var state: OrbState

    var body: some View {
        if state.showCalendar {
            CalendarPanel(state: state)
        } else {
            NothingPlayingPanel(state: state)
        }
    }
}

struct NothingPlayingPanel: View {
    @ObservedObject var state: OrbState

    var body: some View {
        VStack(spacing: 6) {
            Spacer().frame(height: state.baseHeight + 6)
            Image(systemName: "music.note.list")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(state.accentColor)
                .frame(width: 54, height: 54)
                .orbGlass(Circle(), tint: state.accentColor.opacity(0.25))
            Text("Nothing playing")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(state.automationDenied ? "Allow Orb in System Settings > Automation" : "Play something in Music or Spotify")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.55))
            Spacer(minLength: 0)
        }
    }
}

struct CalendarPanel: View {
    @ObservedObject var state: OrbState
    @State private var selectedDate: Date? = nil

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 20)) { timeline in
            content(now: timeline.date)
        }
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: state.baseHeight + 1)
            header(now: now)
            Spacer(minLength: 4)
            weekStrip(now: now)
            Spacer(minLength: 4)
            eventsArea(now: now)
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        let cal = Calendar.current
        let activeDay = selectedDate ?? now
        let count = state.upcomingEvents.filter { cal.isDate($0.start, inSameDayAs: activeDay) }.count

        return HStack(spacing: 8) {
            if let sel = selectedDate, !cal.isDate(sel, inSameDayAs: now) {
                HStack(spacing: 5) {
                    Text(sel.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Button(action: {
                        state.haptic()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedDate = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Return to Today")
                }
            } else {
                Text(now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            if state.calendarAccess == .granted {
                Text(count == 0 ? "No events" : (count == 1 ? "1 event" : "\(count) events"))
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .orbGlass(Capsule(), tint: state.accentColor.opacity(0.18))

                Button(action: {
                    state.haptic()
                    let timestamp = (selectedDate ?? now).timeIntervalSinceReferenceDate
                    if let url = URL(string: "calshow:\(timestamp)") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Open in Apple Calendar")
            }
        }
        .frame(height: 20)
    }

    // MARK: Week strip

    private func weekStrip(now: Date) -> some View {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? cal.startOfDay(for: now)
        let days: [Date] = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }

        return HStack(spacing: 3) {
            ForEach(days, id: \.self) { day in
                let isToday = cal.isDate(day, inSameDayAs: now)
                let isSelected = selectedDate != nil && cal.isDate(day, inSameDayAs: selectedDate!)
                let hasEvents = state.upcomingEvents.contains { cal.isDate($0.start, inSameDayAs: day) }

                Button(action: {
                    state.haptic()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        if isSelected {
                            selectedDate = nil
                        } else {
                            selectedDate = day
                        }
                    }
                }) {
                    dayCell(day, isToday: isToday, isSelected: isSelected, hasEvents: hasEvents)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 34)
    }

    private func dayCell(_ day: Date, isToday: Bool, isSelected: Bool, hasEvents: Bool) -> some View {
        VStack(spacing: 1) {
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : (isToday ? Color.white.opacity(0.95) : Color.white.opacity(0.45)))

            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : (isToday ? .white : Color.white.opacity(0.85)))

            Circle()
                .fill(isSelected ? Color.white : (hasEvents ? state.accentColor : Color.clear))
                .frame(width: 3.5, height: 3.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(isSelected ? state.accentColor.opacity(0.9) : (isToday ? state.accentColor.opacity(0.35) : Color.white.opacity(0.04)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.5) : (isToday ? state.accentColor.opacity(0.6) : Color.clear), lineWidth: 1)
        )
    }

    // MARK: Events

    @ViewBuilder
    private func eventsArea(now: Date) -> some View {
        switch state.calendarAccess {
        case .granted:
            let cal = Calendar.current
            let targetDate = selectedDate ?? now
            let displayedEvents: [OrbCalendarEvent] = selectedDate != nil
                ? state.upcomingEvents.filter { cal.isDate($0.start, inSameDayAs: targetDate) }
                : state.upcomingEvents.filter { $0.end > now }

            if displayedEvents.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(state.accentColor)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(selectedDate != nil ? "No events on this day" : "Nothing scheduled")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Click anywhere to open Apple Calendar")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Button(action: {
                        state.haptic()
                        let timestamp = targetDate.timeIntervalSinceReferenceDate
                        if let url = URL(string: "calshow:\(timestamp)") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(state.accentColor.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(displayedEvents.prefix(2))) { event in
                        Button(action: {
                            state.haptic()
                            let timestamp = event.start.timeIntervalSinceReferenceDate
                            if let url = URL(string: "calshow:\(timestamp)") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            eventRow(event, now: now)
                        }
                        .buttonStyle(OrbPressStyle())
                    }
                }
            }
        case .denied:
            VStack(spacing: 4) {
                emptyState(icon: "calendar.badge.exclamationmark", title: "Calendar access needed", subtitle: nil)
                Button("Open Calendar Privacy Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(state.accentColor)
            }
        case .unknown:
            emptyState(icon: "calendar", title: "Allow calendar access", subtitle: "Choose Allow in the system prompt.")
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(state.accentColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
    }

    private func eventRow(_ event: OrbCalendarEvent, now: Date) -> some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(event.color)
                .frame(width: 3.5, height: 14)
            Text(event.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(timeText(for: event, now: now))
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
                .lineLimit(1)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .orbGlass(RoundedRectangle(cornerRadius: 9, style: .continuous), tint: event.color.opacity(0.22))
    }

    private func timeText(for event: OrbCalendarEvent, now: Date) -> String {
        if event.isAllDay { return "All day" }
        if event.start <= now && now <= event.end { return "Now" }
        let minutes = Int(event.start.timeIntervalSince(now) / 60)
        if minutes > 0 && minutes < 60 { return "in \(minutes)m" }
        let time = event.start.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInTomorrow(event.start) { return "Tomorrow \(time)" }
        return time
    }
}

// MARK: - Floating Desktop & Lock Screen Media Widget

struct OrbMediaWidgetView: View {
    @ObservedObject var state = OrbState.shared

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        ZStack {
            // Luminous liquid glass background matching lock screen reference
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                .clipShape(shape)

            shape.fill(Color.white.opacity(0.08))

            if let image = state.artworkImage, state.playback != .stopped {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 40)
                    .opacity(0.24)
                    .clipShape(shape)
            }

            // Specular perimeter stroke
            shape.stroke(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.white.opacity(0.45), location: 0.0),
                        Gradient.Stop(color: Color.white.opacity(0.12), location: 0.35),
                        Gradient.Stop(color: Color.clear, location: 0.65),
                        Gradient.Stop(color: Color.white.opacity(0.32), location: 1.0)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1
            )

            // Content matching reference image
            VStack(spacing: 9) {
                // Top Row: Artwork + Track Details + Waveform + Close button
                HStack(spacing: 12) {
                    ArtworkView(state: state, size: 50, corner: 13, bordered: true, showBadge: true)

                    VStack(alignment: .leading, spacing: 2) {
                        if state.scrollLongNames {
                            MarqueeTextView(text: state.trackName,
                                            font: .system(size: 15, weight: .bold, design: .rounded),
                                            color: .white,
                                            scrollEnabled: true)
                        } else {
                            Text(state.trackName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        Text(state.artistName)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.80))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    WaveformView(style: state.waveformStyle,
                                 color: state.color(for: state.waveformColor),
                                 isPlaying: state.playback == .playing,
                                 width: 22, height: 16, barCount: 4)

                    Button(action: {
                        state.showMediaWidget = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }

                // Middle Row: Scrubber with timestamps
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state.playback != .playing)) { timeline in
                    let pos = state.livePosition(at: timeline.date)
                    let dur = state.duration
                    let fraction = dur > 0 ? min(max(pos / dur, 0), 1) : 0

                    HStack(spacing: 8) {
                        Text(OrbState.format(pos))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 30, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.20))
                                Capsule().fill(Color.white.opacity(0.95))
                                    .frame(width: max(4.5, geo.size.width * CGFloat(fraction)))
                            }
                            .frame(height: 4.5)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let f = min(max(Double(value.location.x / max(geo.size.width, 1)), 0), 1)
                                        state.haptic()
                                        state.seek(toFraction: f)
                                    }
                            )
                        }
                        .frame(height: 12)

                        Text(OrbState.format(dur))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 30, alignment: .trailing)
                    }
                }

                // Bottom Row: Clean borderless glyph controls
                HStack(spacing: 34) {
                    Button(action: { state.toggleFavorite() }) {
                        Image(systemName: state.isFavorited ? "star.fill" : "star")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(state.isFavorited ? Color(hex: "#FFD60A") : Color.white.opacity(0.85))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(OrbPressStyle())

                    Spacer()

                    Button(action: {
                        state.haptic()
                        state.skipPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 30)
                    }
                    .buttonStyle(OrbPressStyle())

                    Button(action: {
                        state.haptic()
                        state.togglePlayPause()
                    }) {
                        Image(systemName: state.playback == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 34)
                    }
                    .buttonStyle(OrbPressStyle())

                    Button(action: {
                        state.haptic()
                        state.skipNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 30)
                    }
                    .buttonStyle(OrbPressStyle())

                    Spacer()

                    Button(action: {
                        state.haptic()
                        state.openActivePlayer()
                    }) {
                        Image(systemName: "display")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(OrbPressStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 350, height: 140)
        .shadow(color: Color.black.opacity(0.35), radius: 18, y: 8)
    }
}
