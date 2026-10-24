import SwiftUI
import AppKit
import AVFoundation
import QuartzCore

// MARK: - Native Text Display

struct MarqueeTextView: View {
    let text: String
    let font: Font
    let color: Color
    var scrollEnabled: Bool = true

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { geo in
            let shouldScroll = scrollEnabled && textWidth > geo.size.width && geo.size.width > 0

            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = textGeo.size.width
                            }
                            .onChange(of: text) { _ in
                                textWidth = textGeo.size.width
                                resetAnimation(shouldScroll: shouldScroll, geoWidth: geo.size.width)
                            }
                        }
                    )
                    .offset(x: offset)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
            .onAppear {
                containerWidth = geo.size.width
                startAnimationIfNeeded(shouldScroll: shouldScroll, geoWidth: geo.size.width)
            }
            .onChange(of: geo.size.width) { newWidth in
                containerWidth = newWidth
                resetAnimation(shouldScroll: scrollEnabled && textWidth > newWidth && newWidth > 0, geoWidth: newWidth)
            }
        }
    }

    private func resetAnimation(shouldScroll: Bool, geoWidth: CGFloat) {
        offset = 0
        isAnimating = false
        startAnimationIfNeeded(shouldScroll: shouldScroll, geoWidth: geoWidth)
    }

    private func startAnimationIfNeeded(shouldScroll: Bool, geoWidth: CGFloat) {
        guard shouldScroll, !isAnimating else { return }
        isAnimating = true
        let overflow = textWidth - geoWidth + 12
        let duration = Double(overflow) / 20.0 + 2.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard isAnimating else { return }
            withAnimation(.easeInOut(duration: duration)) {
                offset = -overflow
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.2) {
                guard isAnimating else { return }
                withAnimation(.easeInOut(duration: 0.8)) {
                    offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isAnimating = false
                    startAnimationIfNeeded(shouldScroll: scrollEnabled && textWidth > geoWidth, geoWidth: geoWidth)
                }
            }
        }
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
                looper?.disableLooping()
                player?.pause()
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
        guard rect.height > 1, rect.width > 1 else { return path }
        let ear = min(max(0, topEarRadius), rect.height / 2)
        let maxBottomR = max(0, rect.height - ear)
        let bottomR = min(max(0, bottomCornerRadius), min(maxBottomR, rect.height / 2))
        path.move(to: CGPoint(x: rect.minX, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear, y: ear), control: CGPoint(x: rect.minX + ear, y: 0))
        path.addLine(to: CGPoint(x: rect.minX + ear, y: max(ear, rect.maxY - bottomR)))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear + bottomR, y: rect.maxY), control: CGPoint(x: rect.minX + ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: max(rect.minX + ear + bottomR, rect.maxX - ear - bottomR), y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - ear, y: max(ear, rect.maxY - bottomR)), control: CGPoint(x: rect.maxX - ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: ear))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: 0), control: CGPoint(x: rect.maxX - ear, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Motion

enum OrbMotion {
    static let morph = Animation.spring(response: 0.46, dampingFraction: 0.78)
    static let peek = Animation.spring(response: 0.3, dampingFraction: 0.62)
    static let quick = Animation.spring(response: 0.32, dampingFraction: 0.8)
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

// MARK: - Island background (solid / frosted / liquid glass)

struct IslandBackground: View {
    @ObservedObject var state: OrbState
    var shape: OrbNotchShape

    var body: some View {
        let raised = state.isExpanded || state.isCompactDroppedDown

        ZStack {
            switch state.glassStyle {
            case .solid:
                solidBackground
            case .frosted:
                frostedBackground
            case .dynamicGlass:
                dynamicGlassBackground
            case .albumArt:
                albumArtBackground
            }

            if raised {
                shape
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.22), location: 0.0),
                                .init(color: Color.white.opacity(0.08), location: 0.3),
                                .init(color: Color.white.opacity(0.03), location: 0.7),
                                .init(color: Color.white.opacity(0.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.plusLighter)
            }
        }
    }

    private var solidBackground: some View {
        shape
            .fill(Color.black)
    }

    private var frostedBackground: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                .clipShape(shape)
            shape
                .fill(Color.black.opacity(0.65))
        }
    }

    private var dynamicGlassBackground: some View {
        ZStack {
            LiquidGlassBackgroundView(cornerRadius: shape.bottomCornerRadius, variant: 11)
                .clipShape(shape)
            shape
                .fill(Color.black.opacity(0.55))
        }
    }

    private var albumArtBackground: some View {
        ZStack {
            LiquidGlassBackgroundView(cornerRadius: shape.bottomCornerRadius, variant: 11)
                .clipShape(shape)

            if let tint = state.playback != .stopped ? state.artColor : nil {
                shape
                    .fill(tint.opacity(0.35))
                    .transition(.opacity)
            }

            shape
                .fill(Color.black.opacity(0.50))
        }
    }
}

// MARK: - Progressive blur

struct ProgressiveBlurView: View {
    var radius: CGFloat = 20

    var body: some View {
        VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .black.opacity(0.8), location: 0.3),
                        .init(color: .black.opacity(0.4), location: 0.7),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
