import SwiftUI

// MARK: - Compact (collapsed) panel + track-change banner

struct CompactPanel: View {
    @ObservedObject var state = OrbState.shared
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top notch row: Album Art on left, Waveform on right (aligned with the notch wings)
            HStack(spacing: 8) {
                ArtworkView(state: state, size: 22, corner: 6)
                    .padding(.leading, 20)

                Spacer(minLength: 4)

                WaveformView(style: state.waveformStyle,
                             color: state.color(for: state.waveformColor),
                             isPlaying: state.playback == .playing,
                             width: 18, height: 13, barCount: 4)
                    .padding(.trailing, 20)
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
        .offset(x: dragOffset)
        .simultaneousGesture(
            state.swipeToChangeSongs && state.playback != .stopped ?
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        dragOffset = value.translation.width * 0.35
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 30
                        if value.translation.width < -threshold {
                            state.haptic()
                            state.skipNext()
                        } else if value.translation.width > threshold {
                            state.haptic()
                            state.skipPrevious()
                        }
                        withAnimation(OrbMotion.quick) {
                            dragOffset = 0
                        }
                    }
            : nil
        )
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

                            AppleMusicKaraoryLyricViewWrapper(line: active.line, currentTime: pos)
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

private struct AppleMusicKaraoryLyricViewWrapper: View {
    let line: LyricLine
    let currentTime: Double

    var body: some View {
        AppleMusicKaraokeLyricView(line: line, currentTime: currentTime, font: .system(size: 11.5, weight: .semibold, design: .rounded))
    }
}

// MARK: - Queue Panel

struct QueuePanel: View {
    @ObservedObject var state: OrbState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(state.accentColor)
                    Text("Up Next")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {
                    state.haptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        state.isQueueOpen = false
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(state.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(state.accentColor.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 24)

            if state.upNextQueue.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(state.accentColor.opacity(0.7))
                    Text("No upcoming queue loaded")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 145)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 5) {
                        ForEach(state.upNextQueue) { track in
                            QueueTrackRow(state: state, track: track)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 2)
                }
                .frame(height: 145)
            }
        }
        .transition(.opacity)
    }
}

private struct QueueTrackRow: View {
    @ObservedObject var state: OrbState
    let track: QueueTrack
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            state.playQueueTrack(track)
        }) {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? state.accentColor : Color.white.opacity(0.35))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(OrbState.format(track.duration))
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Expanded Now Playing Panel

struct NowPlayingPanel: View {
    @ObservedObject var state: OrbState
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
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
            .offset(x: dragOffset)
            .simultaneousGesture(
                state.swipeToChangeSongs ?
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            dragOffset = value.translation.width * 0.35
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 35
                            if value.translation.width < -threshold {
                                state.haptic()
                                state.skipNext()
                            } else if value.translation.width > threshold {
                                state.haptic()
                                state.skipPrevious()
                            }
                            withAnimation(OrbMotion.quick) {
                                dragOffset = 0
                            }
                        }
                : nil
            )

            if state.isQueueOpen {
                Spacer(minLength: 6)
                QueuePanel(state: state)
                Spacer(minLength: 6)
            } else {
                // Apple Music Karaoke Lyrics with alphabet glow sweep
                if state.showLyricsExpanded && !state.lyrics.isEmpty {
                    lyricsSection
                }

                Spacer(minLength: 8)

                // 2. Middle Row: Progress Scrubber with time labels
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state.playback != .playing)) { timeline in
                    OrbProgressRow(state: state, position: state.livePosition(at: timeline.date))
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 10)
            }

            // 3. Bottom Row: Media Controls (Queue, Star, Previous, Play/Pause, Next)
            controls
                .padding(.horizontal, 24)

            Spacer().frame(height: 18)
        }
        .animation(OrbMotion.content, value: state.trackID)
    }

    private var lyricsSection: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state.playback != .playing)) { timeline in
            let pos = state.livePosition(at: timeline.date)
            if let active = state.activeLyric(at: pos) {
                VStack(spacing: 3) {
                    if active.index > 0 && active.index - 1 < state.lyrics.count {
                        Text(state.lyrics[active.index - 1].text)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.24))
                            .lineLimit(1)
                    }

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

                    if active.index + 1 < state.lyrics.count {
                        Text(state.lyrics[active.index + 1].text)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.28))
                            .lineLimit(1)
                    }
                }
                .padding(.top, 4)
            } else if let first = state.lyrics.first, pos < first.time {
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

// MARK: - Waveform

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
        if state.automixAnimation {
            let pulse = 0.85 + 0.15 * sin(t * 3.5 + Double(index) * 0.7)
            return AnyShapeStyle(color.opacity(pulse))
        }
        return AnyShapeStyle(color)
    }

    private func barHeight(_ index: Int, _ t: Double) -> CGFloat {
        guard isPlaying else { return 4 }
        let phase = Double(index) * 1.3
        let speed = 4.2 + Double(index) * 0.9
        let a = sin(t * speed + phase)
        let b = 0.6 + 0.4 * sin(t * 1.7 + phase * 2)
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

// MARK: - Progress bar

enum WaveSeed {
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
        let h: CGFloat = dragFraction == nil ? 6 : 8
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.12))
            Capsule()
                .fill(
                    LinearGradient(colors: [barColor, barColor.opacity(0.85)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: max(h, width * CGFloat(fraction)))
        }
        .frame(height: h)
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
    }

    private func waveformBar(fraction: Double, size: CGSize) -> some View {
        let count = 38
        let heights = WaveSeed.heights(seed: state.trackName + state.artistName, count: count)
        let gap: CGFloat = 2.0
        let totalBarsWidth = size.width - (CGFloat(count - 1) * gap)
        let barW = max(1.5, totalBarsWidth / CGFloat(count))

        return HStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { index in
                let barFraction = Double(index) / Double(count)
                let isPlayed = barFraction <= fraction
                let rawH = index < heights.count ? heights[index] : 0.5
                let h = max(3.0, CGFloat(rawH) * size.height)

                Capsule()
                    .fill(isPlayed ? Color.white.opacity(0.95) : Color.white.opacity(0.25))
                    .frame(width: barW, height: h)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
