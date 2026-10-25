import SwiftUI

private let orbTeal = Color(red: 0.23, green: 0.84, blue: 0.75)

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance = "Appearance"
    case dynamicIsland = "Island"
    case mediaLyrics = "Media & Lyrics"
    case pet = "Notch Pet"
    case calendar = "Calendar"
    case advanced = "Advanced"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appearance: return "sparkles"
        case .dynamicIsland: return "capsule.portrait.fill"
        case .mediaLyrics: return "music.note"
        case .pet: return "pawprint.fill"
        case .calendar: return "calendar"
        case .advanced: return "gearshape.fill"
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(_ title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(orbTeal)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.95))
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ContentView: View {
    @ObservedObject var state = OrbState.shared
    @State private var selectedTab: SettingsTab = .appearance

    private let swatchColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            // Header with App info and status badge
            header
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Top Tab Navigation Bar
            tabBar
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            Divider()
                .background(Color.white.opacity(0.08))

            // Tab Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if state.automationDenied {
                        automationWarning
                    }

                    switch selectedTab {
                    case .appearance:
                        appearanceTab
                    case .dynamicIsland:
                        islandTab
                    case .mediaLyrics:
                        mediaLyricsTab
                    case .pet:
                        PetSettingsTab()
                    case .calendar:
                        calendarTab
                    case .advanced:
                        advancedTab
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
            }
        }
        .frame(width: 680, height: 640)
        .background(Color(red: 0.09, green: 0.09, blue: 0.10))
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(orbTeal.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: "capsule.tophalf.filled")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(orbTeal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Orb")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Dynamic Island for your Mac notch")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
            }

            Spacer()

            statusBadge
        }
    }

    private var statusBadge: some View {
        let text: String
        let active: Bool
        switch state.playback {
        case .playing:
            text = "Playing: \(state.trackName)"
            active = true
        case .paused:
            text = "Paused"
            active = true
        case .stopped:
            text = "Idle"
            active = false
        }
        return HStack(spacing: 6) {
            Circle()
                .fill(active ? orbTeal : Color.gray)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(active ? orbTeal.opacity(0.18) : Color.white.opacity(0.08))
        .foregroundColor(active ? orbTeal : Color.white.opacity(0.6))
        .cornerRadius(8)
    }

    private var automationWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text("Orb isn't allowed to control Music or Spotify.")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.9))
            Spacer()
            Button("Open Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundColor(orbTeal)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: Tab Bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    state.haptic()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Color.white.opacity(0.14) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Tab 1: Appearance

    private var appearanceTab: some View {
        VStack(spacing: 16) {
            SettingsCard("Liquid Glass Style", icon: "sparkles") {
                glassStyleGrid

                sliderRow(title: "Glass intensity",
                          valueText: "\(Int(state.glassIntensity * 100))%",
                          value: $state.glassIntensity,
                          range: 0...1,
                          step: 0.05)
                    .disabled(state.glassStyle == .solid)
                    .opacity(state.glassStyle == .solid ? 0.4 : 1)

                toggleRow("Progressive blur",
                          detail: "Multi-stage gradient blur that blends the album art smoothly into the background.",
                          isOn: $state.progressiveBlur)
            }

            SettingsCard("Accent Colour", icon: "paintpalette.fill") {
                LazyVGrid(columns: swatchColumns, spacing: 14) {
                    ForEach(AccentChoice.allCases.filter { $0 != .custom }) { choice in
                        swatch(choice)
                    }
                    customSwatch
                }
                .padding(.vertical, 4)

                Text(state.accentChoice == .albumArt
                     ? "The accent follows the colours of the current album art."
                     : "Selected: \(state.accentChoice.title)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
    }

    private var glassStyleGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(GlassStyle.allCases) { style in
                let isSelected = state.glassStyle == style
                Button(action: {
                    state.glassStyle = style
                    state.haptic()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: glassIcon(for: style))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? orbTeal : Color.white.opacity(0.7))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(style.title)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.85))

                            Text(glassSub(for: style))
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.45))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(orbTeal)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? orbTeal.opacity(0.14) : Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? orbTeal.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func glassIcon(for style: GlassStyle) -> String {
        switch style {
        case .solid: return "circle.fill"
        case .frosted: return "aqi.medium"
        case .dynamicGlass: return "sparkles"
        case .albumArt: return "photo.fill"
        }
    }

    private func glassSub(for style: GlassStyle) -> String {
        switch style {
        case .solid: return "Matches notch"
        case .frosted: return "Translucent glass"
        case .dynamicGlass: return "Optical refraction"
        case .albumArt: return "Ambient artwork glow"
        }
    }

    private func swatch(_ choice: AccentChoice) -> some View {
        let selected = state.accentChoice == choice
        return Button(action: {
            state.accentChoice = choice
            state.haptic()
        }) {
            swatchFill(choice)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(selected ? 0.95 : 0), lineWidth: 2)
                        .padding(-4)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(choice.title)
    }

    @ViewBuilder
    private func swatchFill(_ choice: AccentChoice) -> some View {
        if choice == .albumArt {
            Circle()
                .fill(AngularGradient(colors: [.pink, .orange, .yellow, .green, .teal, .blue, .purple, .pink],
                                      center: .center))
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                )
        } else {
            Circle().fill(state.color(for: choice))
        }
    }

    private var customSwatch: some View {
        let selected = state.accentChoice == .custom
        let binding = Binding<Color>(
            get: { Color(hex: state.customAccentHex) },
            set: { newColor in
                state.customAccentHex = newColor.hexString
                state.accentChoice = .custom
            }
        )
        return ColorPicker("", selection: binding, supportsOpacity: false)
            .labelsHidden()
            .frame(width: 28, height: 28)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(selected ? 0.95 : 0), lineWidth: 2)
                    .padding(-4)
            )
            .help("Custom colour")
    }

    // MARK: - Tab 2: Dynamic Island

    private var islandTab: some View {
        VStack(spacing: 16) {
            SettingsCard("Trigger & Interaction", icon: "slider.horizontal.3") {
                labeled("Open the island with") {
                    segmented($state.openTrigger)
                }
                Text(state.openTrigger == .click
                     ? "Hovering the notch plays a small preview animation. Click it to expand."
                     : "The island expands as soon as your cursor touches the notch.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                toggleRow("Song-change banner",
                          detail: "The island drops down briefly to show the new title and artist.",
                          isOn: $state.trackBanner)
            }

            SettingsCard("Display Elements", icon: "capsule.portrait") {
                toggleRow("Keep song name visible",
                          detail: "Keep the track title visible next to the island even when collapsed.",
                          isOn: $state.keepSongNameVisible)

                toggleRow("Keep artist visible",
                          detail: "Keep the artist name visible alongside the song title.",
                          isOn: $state.keepArtistVisible)

                toggleRow("Scroll long names",
                          detail: "Smoothly scroll song titles and artist names that exceed the island width.",
                          isOn: $state.scrollLongNames)
            }

            SettingsCard("Physical Notch Fine-Tuning", icon: "ruler") {
                HStack {
                    Text("Orb measures your MacBook's notch automatically. Only adjust these if alignment is slightly off.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Spacer(minLength: 12)
                    Button("Reset") {
                        state.widthOffsetPx = 0
                        state.heightOffsetPx = 0
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(orbTeal)
                }

                sliderRow(title: "Width offset",
                          valueText: "\(Int(state.widthOffsetPx)) px",
                          value: $state.widthOffsetPx,
                          range: -40...40,
                          step: 1)

                sliderRow(title: "Height offset",
                          valueText: "\(Int(state.heightOffsetPx)) px",
                          value: $state.heightOffsetPx,
                          range: -16...24,
                          step: 1)
            }
        }
    }

    // MARK: - Tab 3: Media & Lyrics

    private var mediaLyricsTab: some View {
        VStack(spacing: 16) {
            SettingsCard("Lyrics Experience", icon: "quote.bubble.fill") {
                toggleRow("Show lyrics below notch",
                          detail: "Synchronized karaoke lyrics stream in real time right below the notch in compact mode.",
                          isOn: $state.showLyricsBelowNotch)

                toggleRow("Show lyrics when expanded",
                          detail: "Synchronized lyrics with Apple Music karaoke alphabet glow sweep inside the expanded island.",
                          isOn: $state.showLyricsExpanded)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lyrics Sync Offset")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.9))
                        Text("Shift timing forward or backward for exact vocal sync.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button("Reset to 0s") {
                        state.lyricsOffsetSeconds = 0.0
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(orbTeal)
                }

                sliderRow(title: "Offset",
                          valueText: String(format: "%+.1fs", state.lyricsOffsetSeconds),
                          value: $state.lyricsOffsetSeconds,
                          range: -3.0...3.0,
                          step: 0.1)
            }

            SettingsCard("Visualizer & Waveform", icon: "waveform") {
                labeled("Waveform style") {
                    segmented($state.waveformStyle)
                }

                labeled("Waveform colour") {
                    segmented($state.waveformColor)
                }
                .disabled(state.waveformStyle == .off)
                .opacity(state.waveformStyle == .off ? 0.4 : 1)

                toggleRow("Automix animation",
                          detail: "Simulates dynamic beat-blending DJ crossfade modulation on the waveform visualizer.",
                          isOn: $state.automixAnimation)
                    .disabled(state.waveformStyle == .off)
                    .opacity(state.waveformStyle == .off ? 0.4 : 1)

                toggleRow("Motion artwork",
                          detail: "Plays animated motion album artwork from Apple Music when available.",
                          isOn: $state.motionArtworkEnabled)

                labeled("Progress bar style") {
                    segmented($state.progressStyle)
                }

                labeled("Progress bar colour") {
                    segmented($state.progressColor)
                }
            }
        }
    }

    // MARK: - Tab 4: Calendar

    private var calendarTab: some View {
        VStack(spacing: 16) {
            SettingsCard("Calendar Integration", icon: "calendar") {
                toggleRow("Show calendar when idle",
                          detail: "Displays today's date, clickable week strip, and upcoming meeting alerts when nothing is playing.",
                          isOn: $state.showCalendar)

                calendarStatusRow

                HStack {
                    Text("Interactive Week Strip allows clicking any day to inspect scheduled events and opens Apple Calendar directly.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Open Calendar.app") {
                        state.openCalendar()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(orbTeal)
                }
            }
        }
    }

    private var calendarStatusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(calendarColor)
                .frame(width: 7, height: 7)
            Text(calendarText)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Spacer()
            switch state.calendarAccess {
            case .granted:
                EmptyView()
            case .denied:
                Button("Open Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(orbTeal)
            case .unknown:
                Button("Request access") { state.setupCalendar() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(orbTeal)
            }
        }
        .padding(.vertical, 4)
    }

    private var calendarColor: Color {
        switch state.calendarAccess {
        case .granted: return .green
        case .denied: return .red
        case .unknown: return .orange
        }
    }

    private var calendarText: String {
        switch state.calendarAccess {
        case .granted: return "Calendar access granted"
        case .denied: return "Calendar access denied"
        case .unknown: return "Waiting for calendar permission"
        }
    }

    // MARK: - Tab 5: Advanced

    private var advancedTab: some View {
        VStack(spacing: 16) {
            SettingsCard("Haptic Feedback", icon: "hand.tap.fill") {
                segmented($state.hapticLevel)
                HStack {
                    Text("Plays on hover, open, track changes, and scrubber interaction.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Test") { state.haptic() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(orbTeal)
                        .disabled(state.hapticLevel == .off)
                }
            }

            SettingsCard("Window & Security", icon: "macwindow") {
                toggleRow("Hide in fullscreen",
                          detail: "Automatically hides the notch island when an app enters full screen.",
                          isOn: $state.hideInFullscreen)

                toggleRow("Hide from screen capture",
                          detail: "Hides Orb from screen recordings, AirPlay and screenshots for privacy.",
                          isOn: $state.hideFromScreenCapture)
            }
        }
    }

    // MARK: Building blocks

    private func segmented<T: OrbOption>(_ selection: Binding<T>) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(T.allCases)) { option in
                let isSelected = selection.wrappedValue == option
                Button(action: {
                    selection.wrappedValue = option
                    state.haptic()
                }) {
                    Text(option.title)
                        .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.18) : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.75))
            content()
        }
    }

    private func toggleRow(_ title: String, detail: String?, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.9))
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(orbTeal)
        }
    }

    private func sliderRow(title: String, valueText: String, value: Binding<Double>,
                           range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.9))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            Slider(value: value, in: range, step: step)
                .tint(orbTeal)
        }
    }
}
