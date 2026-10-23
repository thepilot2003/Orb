import SwiftUI
import AppKit
import Combine
import EventKit

// MARK: - Option protocol (lets every settings enum share the same picker code)

protocol OrbOption: CaseIterable, Hashable, Identifiable, RawRepresentable where RawValue == String {
    var title: String { get }
}
extension OrbOption {
    var id: String { rawValue }
}

// MARK: - Models

enum PlaybackState { case stopped, paused, playing }

enum PlayerSource: Equatable {
    case music, spotify, nowPlaying(app: String)

    static var allCases: [PlayerSource] { [.music, .spotify] }

    var bundleID: String {
        switch self {
        case .music: return "com.apple.Music"
        case .spotify: return "com.spotify.client"
        case .nowPlaying(let app): return app
        }
    }

    var displayName: String {
        switch self {
        case .music: return "Apple Music"
        case .spotify: return "Spotify"
        case .nowPlaying(let app): return app.isEmpty ? "Now Playing" : app
        }
    }

    var isRunning: Bool {
        switch self {
        case .music, .spotify:
            return !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
        case .nowPlaying:
            return true
        }
    }
}

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let time: Double
    let endTime: Double
    let text: String
}

struct QueueTrack: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let duration: Double
}

private struct NowPlayingSnapshot {
    let source: PlayerSource
    let state: PlaybackState
    let title: String
    let artist: String
    let position: Double   // seconds
    let duration: Double   // seconds
    let shuffle: Bool
    let favorited: Bool
    let trackKey: String
    let artworkURL: URL?
    let artworkData: Data?
    let positionTimestamp: Date?
    let playbackRate: Double
}

// MARK: - MediaRemote Bridge (System-wide Now Playing)

final class MediaRemoteBridge {
    static let shared = MediaRemoteBridge()

    typealias MRGetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    typealias MRRegisterFn = @convention(c) (DispatchQueue) -> Void
    typealias MRGetClientFn = @convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void
    typealias MRIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    typealias MRSendCmdFn = @convention(c) (Int32, AnyObject?) -> Void
    typealias MRSetTimeFn = @convention(c) (Double) -> Void
    typealias MRSetShuffleFn = @convention(c) (Int32) -> Void

    private let getInfoFn: MRGetNowPlayingInfoFn?
    private let registerFn: MRRegisterFn?
    private let getClientFn: MRGetClientFn?
    private let isPlayingFn: MRIsPlayingFn?
    private let sendCmdFn: MRSendCmdFn?
    private let setTimeFn: MRSetTimeFn?
    private let setShuffleFn: MRSetShuffleFn?

    private init() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            getInfoFn = nil
            registerFn = nil
            getClientFn = nil
            isPlayingFn = nil
            sendCmdFn = nil
            setTimeFn = nil
            setShuffleFn = nil
            return
        }

        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getInfoFn = unsafeBitCast(sym, to: MRGetNowPlayingInfoFn.self)
        } else { getInfoFn = nil }

        if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerFn = unsafeBitCast(sym, to: MRRegisterFn.self)
        } else { registerFn = nil }

        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingClient") {
            getClientFn = unsafeBitCast(sym, to: MRGetClientFn.self)
        } else { getClientFn = nil }

        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            isPlayingFn = unsafeBitCast(sym, to: MRIsPlayingFn.self)
        } else { isPlayingFn = nil }

        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCmdFn = unsafeBitCast(sym, to: MRSendCmdFn.self)
        } else { sendCmdFn = nil }

        if let sym = dlsym(handle, "MRMediaRemoteSetElapsedTime") {
            setTimeFn = unsafeBitCast(sym, to: MRSetTimeFn.self)
        } else { setTimeFn = nil }

        if let sym = dlsym(handle, "MRMediaRemoteSetShuffleMode") {
            setShuffleFn = unsafeBitCast(sym, to: MRSetShuffleFn.self)
        } else { setShuffleFn = nil }

        registerFn?(DispatchQueue.main)
    }

    func getNowPlayingInfo(completion: @escaping ([String: Any]?) -> Void) {
        guard let fn = getInfoFn else {
            completion(nil)
            return
        }
        fn(DispatchQueue.main) { info in
            completion(info)
        }
    }

    func getNowPlayingClient(completion: @escaping (String?, String?) -> Void) {
        guard let fn = getClientFn else {
            completion(nil, nil)
            return
        }
        fn(DispatchQueue.main) { client in
            guard let dict = client as? [String: Any] else {
                completion(nil, nil)
                return
            }
            let bundleId = (dict["parentApplicationBundleIdentifier"] as? String) ?? (dict["bundleIdentifier"] as? String)
            let displayName = dict["displayName"] as? String
            completion(bundleId, displayName)
        }
    }

    func sendCommand(_ cmd: Int32) {
        sendCmdFn?(cmd, nil)
    }

    func seek(to seconds: Double) {
        setTimeFn?(seconds)
    }

    func setShuffle(_ on: Bool) {
        setShuffleFn?(on ? 3 : 1)
    }
}

enum OpenTrigger: String, OrbOption {
    case click, hover
    var title: String { self == .click ? "Click" : "Hover" }
}

enum GlassStyle: String, OrbOption {
    case solid, frosted, dynamicGlass, albumArt
    var title: String {
        switch self {
        case .solid: return "Solid"
        case .frosted: return "Frosted"
        case .dynamicGlass: return "Dynamic Glass"
        case .albumArt: return "Album Art"
        }
    }
}

enum HapticLevel: String, OrbOption {
    case off, subtle, standard, strong
    var title: String {
        switch self {
        case .off: return "Off"
        case .subtle: return "Subtle"
        case .standard: return "Standard"
        case .strong: return "Strong"
        }
    }
}

enum AccentChoice: String, OrbOption {
    case albumArt, system, orange, pink, red, yellow, green, teal, blue, purple, white, custom
    var title: String {
        switch self {
        case .albumArt: return "Album art"
        case .system: return "System"
        case .custom: return "Custom"
        default: return rawValue.capitalized
        }
    }
}

enum ColorSource: String, OrbOption {
    case albumArt, accent, white
    var title: String {
        switch self {
        case .albumArt: return "Album art"
        case .accent: return "Accent"
        case .white: return "White"
        }
    }
}

enum WaveformStyle: String, OrbOption {
    case bars, wave, off
    var title: String {
        switch self {
        case .bars: return "Live bars"
        case .wave: return "Smooth wave"
        case .off: return "Hidden"
        }
    }
}

enum ProgressStyle: String, OrbOption {
    case capsule, glass, waveform
    var title: String {
        switch self {
        case .capsule: return "Line"
        case .glass: return "Glass"
        case .waveform: return "Waveform"
        }
    }
}

enum CalendarAccess { case unknown, granted, denied }

struct OrbCalendarEvent: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let color: Color
}

// MARK: - Persistence helpers

private enum Prefs {
    static func option<T: RawRepresentable>(_ key: String, _ fallback: T) -> T where T.RawValue == String {
        T(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? fallback
    }
    static func bool(_ key: String, _ fallback: Bool) -> Bool {
        (UserDefaults.standard.object(forKey: key) as? Bool) ?? fallback
    }
    static func double(_ key: String, _ fallback: Double) -> Double {
        (UserDefaults.standard.object(forKey: key) as? Double) ?? fallback
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor.systemOrange
        let r = Int((ns.redComponent * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Shared state + media controller

final class OrbState: ObservableObject {
    static let shared = OrbState()

    // Playback
    @Published var playback: PlaybackState = .stopped
    @Published var activeSource: PlayerSource? = nil
    @Published var trackName: String = "Nothing Playing"
    @Published var artistName: String = "Play a song in Music or Spotify"
    @Published var trackID: String = ""
    @Published var artworkImage: NSImage? = nil
    @Published var artworkVersion: Int = 0
    @Published var artColor: Color = Color(red: 1.0, green: 0.62, blue: 0.04)
    @Published var position: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Double = 1.0
    @Published var lyricsOffsetSeconds: Double = Prefs.double("lyricsOffsetSeconds", 0.0) {
        didSet { UserDefaults.standard.set(lyricsOffsetSeconds, forKey: "lyricsOffsetSeconds") }
    }
    @Published var shuffleOn: Bool = false
    @Published var isFavorited: Bool = false
    @Published var automationDenied: Bool = false
    @Published var debugInfo: String = ""

    // Track-change banner
    @Published var showTrackBanner: Bool = false

    // Calendar
    @Published var calendarAccess: CalendarAccess = .unknown
    @Published var upcomingEvents: [OrbCalendarEvent] = []

    // UI
    @Published var isHovered: Bool = false    // cursor is over the island (small "peek" animation)
    @Published var isExpanded: Bool = false   // island is fully open
    @Published var hardwareNotchWidth: CGFloat = 184
    @Published var hardwareNotchHeight: CGFloat = 32

    // MARK: Settings (persisted manually; @AppStorage does not publish from an ObservableObject)

    @Published var widthOffsetPx: Double = UserDefaults.standard.double(forKey: "orbWidthOffset") {
        didSet { UserDefaults.standard.set(widthOffsetPx, forKey: "orbWidthOffset") }
    }
    @Published var heightOffsetPx: Double = UserDefaults.standard.double(forKey: "orbHeightOffset") {
        didSet { UserDefaults.standard.set(heightOffsetPx, forKey: "orbHeightOffset") }
    }
    @Published var hideInFullscreen: Bool = Prefs.bool("hideInFullscreen", true) {
        didSet { UserDefaults.standard.set(hideInFullscreen, forKey: "hideInFullscreen") }
    }
    @Published var hideFromScreenCapture: Bool = Prefs.bool("hideFromScreenCapture", false) {
        didSet { UserDefaults.standard.set(hideFromScreenCapture, forKey: "hideFromScreenCapture") }
    }
    @Published var openTrigger: OpenTrigger = Prefs.option("openTrigger", OpenTrigger.click) {
        didSet { UserDefaults.standard.set(openTrigger.rawValue, forKey: "openTrigger") }
    }

    // Appearance
    @Published var glassStyle: GlassStyle = Prefs.option("glassStyle", GlassStyle.albumArt) {
        didSet { UserDefaults.standard.set(glassStyle.rawValue, forKey: "glassStyle") }
    }
    @Published var glassIntensity: Double = Prefs.double("glassIntensity", 0.6) {
        didSet { UserDefaults.standard.set(glassIntensity, forKey: "glassIntensity") }
    }
    @Published var progressiveBlur: Bool = Prefs.bool("progressiveBlur", true) {
        didSet { UserDefaults.standard.set(progressiveBlur, forKey: "progressiveBlur") }
    }

    // Haptics
    @Published var hapticLevel: HapticLevel = Prefs.option("hapticLevel", HapticLevel.subtle) {
        didSet { UserDefaults.standard.set(hapticLevel.rawValue, forKey: "hapticLevel") }
    }

    // Accent
    @Published var accentChoice: AccentChoice = Prefs.option("accentChoice", AccentChoice.albumArt) {
        didSet { UserDefaults.standard.set(accentChoice.rawValue, forKey: "accentChoice") }
    }
    @Published var customAccentHex: String = UserDefaults.standard.string(forKey: "customAccentHex") ?? "#FF9F0A" {
        didSet { UserDefaults.standard.set(customAccentHex, forKey: "customAccentHex") }
    }

    // Waveform + progress bar
    @Published var waveformStyle: WaveformStyle = Prefs.option("waveformStyle", WaveformStyle.bars) {
        didSet { UserDefaults.standard.set(waveformStyle.rawValue, forKey: "waveformStyle") }
    }
    @Published var waveformColor: ColorSource = Prefs.option("waveformColor", ColorSource.albumArt) {
        didSet { UserDefaults.standard.set(waveformColor.rawValue, forKey: "waveformColor") }
    }
    @Published var progressStyle: ProgressStyle = Prefs.option("progressStyle", ProgressStyle.glass) {
        didSet { UserDefaults.standard.set(progressStyle.rawValue, forKey: "progressStyle") }
    }
    @Published var progressColor: ColorSource = Prefs.option("progressColor", ColorSource.albumArt) {
        didSet { UserDefaults.standard.set(progressColor.rawValue, forKey: "progressColor") }
    }

    // Behaviour
    @Published var trackBanner: Bool = Prefs.bool("trackBanner", true) {
        didSet { UserDefaults.standard.set(trackBanner, forKey: "trackBanner") }
    }
    @Published var showCalendar: Bool = Prefs.bool("showCalendar", true) {
        didSet {
            UserDefaults.standard.set(showCalendar, forKey: "showCalendar")
            if showCalendar { setupCalendar() }
        }
    }

    // Lyrics: Two distinct options requested by user
    @Published var showLyricsBelowNotch: Bool = Prefs.bool("showLyricsBelowNotch", true) {
        didSet {
            UserDefaults.standard.set(showLyricsBelowNotch, forKey: "showLyricsBelowNotch")
            checkFetchLyrics()
        }
    }
    @Published var showLyricsExpanded: Bool = Prefs.bool("showLyricsExpanded", true) {
        didSet {
            UserDefaults.standard.set(showLyricsExpanded, forKey: "showLyricsExpanded")
            checkFetchLyrics()
        }
    }
    var anyLyricsEnabled: Bool { showLyricsBelowNotch || showLyricsExpanded }

    @Published private(set) var lyrics: [LyricLine] = []

    func checkFetchLyrics() {
        if anyLyricsEnabled && lyrics.isEmpty && !trackName.isEmpty && trackName != "Nothing Playing" {
            fetchLyrics(title: trackName, artist: artistName, duration: duration)
        }
    }

    // Desktop / Lock Screen Media Widget
    @Published var showMediaWidget: Bool = Prefs.bool("showMediaWidget", true) {
        didSet { UserDefaults.standard.set(showMediaWidget, forKey: "showMediaWidget") }
    }
    @Published var mediaWidgetAboveApps: Bool = Prefs.bool("mediaWidgetAboveApps", true) {
        didSet { UserDefaults.standard.set(mediaWidgetAboveApps, forKey: "mediaWidgetAboveApps") }
    }

    // Automix & Queue
    @Published var automixAnimation: Bool = Prefs.bool("automixAnimation", true) {
        didSet { UserDefaults.standard.set(automixAnimation, forKey: "automixAnimation") }
    }
    @Published var isQueueOpen: Bool = false
    @Published var upNextQueue: [QueueTrack] = []

    // Dynamic Island Display Controls
    @Published var keepSongNameVisible: Bool = Prefs.bool("keepSongNameVisible", false) {
        didSet { UserDefaults.standard.set(keepSongNameVisible, forKey: "keepSongNameVisible") }
    }
    @Published var keepArtistVisible: Bool = Prefs.bool("keepArtistVisible", false) {
        didSet { UserDefaults.standard.set(keepArtistVisible, forKey: "keepArtistVisible") }
    }
    @Published var scrollLongNames: Bool = Prefs.bool("scrollLongNames", true) {
        didSet { UserDefaults.standard.set(scrollLongNames, forKey: "scrollLongNames") }
    }

    // Motion Artwork (Apple Music animated album art)
    @Published var motionArtworkEnabled: Bool = Prefs.bool("motionArtworkEnabled", true) {
        didSet {
            UserDefaults.standard.set(motionArtworkEnabled, forKey: "motionArtworkEnabled")
            if !motionArtworkEnabled { videoArtworkURL = nil }
        }
    }
    @Published var videoArtworkURL: URL? = nil

    // Persistent favorites store
    private(set) var favoriteTrackKeys: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "orbFavoriteKeys") ?? [])

    // MARK: Private

    private let scriptQueue = DispatchQueue(label: "orb.applescript", qos: .userInitiated)
    private let eventStore = EKEventStore()
    private var pollTimer: Timer?
    private var calendarTimer: Timer?
    private var bannerWork: DispatchWorkItem?
    private var refreshInFlight = false
    private var currentTrackKey = ""
    private var positionStamp = Date()
    private var permissionRequested = Set<String>()   // touched only on scriptQueue
    private var optimisticUntil = Date.distantPast     // ignore polled play/pause state briefly after a click
    private var missCount = 0                          // consecutive polls that found nothing

    private init() {
        detectHardwareNotch()

        // Instant updates when the player changes track or state.
        let dnc = DistributedNotificationCenter.default()
        for name in ["com.apple.Music.playerInfo", "com.spotify.client.PlaybackStateChanged"] {
            dnc.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }

        let nc = NotificationCenter.default
        let mrNotifs = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification"
        ]
        for name in mrNotifs {
            nc.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }

        // Adaptive poll for playback progress. Common mode so it keeps firing while menus are open.
        // Fast (2.0s) only when playing; slow (6.0s) when paused; no AppleScript when stopped.
        var pollCounter = 0
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            pollCounter += 1
            if self.playback == .playing {
                self.refresh()
            } else if PlayerSource.allCases.contains(where: { $0.isRunning }) {
                if pollCounter % 3 == 0 {
                    self.refresh()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer

        refresh()

        // Calendar
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: eventStore, queue: .main) { [weak self] _ in
            self?.loadEvents()
        }
        let calTimer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in self?.loadEvents() }
        RunLoop.main.add(calTimer, forMode: .common)
        calendarTimer = calTimer
        if showCalendar { setupCalendar() }
    }

    // MARK: Derived values

    /// Smoothly interpolated playback position without causing view invalidation.
    func livePosition(at date: Date = Date()) -> Double {
        if playback == .playing {
            let diff = max(0, date.timeIntervalSince(positionStamp))
            let rate = playbackRate > 0 ? playbackRate : 1.0
            let live = position + (diff * rate)
            return duration > 0 ? min(live, duration) : live
        }
        return duration > 0 ? min(max(0, position), duration) : max(0, position)
    }

    /// Pure function to find the active lyric line at a given playback position.
    func activeLyric(at rawPos: Double) -> (line: LyricLine, index: Int)? {
        guard anyLyricsEnabled, !lyrics.isEmpty else { return nil }
        let pos = rawPos + lyricsOffsetSeconds
        guard let first = lyrics.first, pos >= first.time - 0.2 else { return nil }
        if let idx = lyrics.lastIndex(where: { $0.time <= pos }) {
            let line = lyrics[idx]
            let nextTime = (idx + 1 < lyrics.count) ? lyrics[idx + 1].time : (line.endTime + 5.0)
            if pos < nextTime {
                return (line, idx)
            }
        }
        return nil
    }

    var statusText: String {
        if automationDenied { return "Allow Orb to control Music (System Settings)" }
        switch playback {
        case .playing: return "Playing: \(trackName)"
        case .paused: return "Paused: \(trackName)"
        case .stopped: return debugInfo.isEmpty ? "Waiting for Music or Spotify..." : debugInfo
        }
    }

    static func format(_ seconds: Double) -> String {
        let t = max(0, Int(seconds))
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private static func number(_ s: String?) -> Double {
        guard let s = s else { return 0 }
        return Double(s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
    }

    // MARK: Colours

    func color(for choice: AccentChoice) -> Color {
        switch choice {
        case .albumArt: return artColor
        case .system: return Color(nsColor: NSColor.controlAccentColor)
        case .orange: return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .pink: return Color(red: 1.00, green: 0.30, blue: 0.55)
        case .red: return Color(red: 1.00, green: 0.27, blue: 0.23)
        case .yellow: return Color(red: 1.00, green: 0.84, blue: 0.04)
        case .green: return Color(red: 0.19, green: 0.82, blue: 0.35)
        case .teal: return Color(red: 0.25, green: 0.85, blue: 0.78)
        case .blue: return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .purple: return Color(red: 0.69, green: 0.40, blue: 0.95)
        case .white: return Color.white
        case .custom: return Color(hex: customAccentHex)
        }
    }

    var accentColor: Color { color(for: accentChoice) }

    func color(for source: ColorSource) -> Color {
        switch source {
        case .albumArt: return artColor
        case .accent: return accentColor
        case .white: return Color.white
        }
    }

    // MARK: Liquid glass levels (used by the menu bar)

    static let glassLevels: [(name: String, value: Double)] = [
        ("Low", 0.25), ("Medium", 0.5), ("High", 0.75), ("Max", 1.0)
    ]

    var glassLevelIndex: Int {
        var best = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, level) in Self.glassLevels.enumerated() {
            let d = abs(level.value - glassIntensity)
            if d < bestDistance { best = index; bestDistance = d }
        }
        return best
    }

    // MARK: Haptics

    func haptic() {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch hapticLevel {
        case .off: return
        case .subtle: pattern = .alignment
        case .standard: pattern = .generic
        case .strong: pattern = .levelChange
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }

    // MARK: Notch geometry

    static func targetScreen() -> NSScreen? {
        NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.screens.first
    }

    func detectHardwareNotch() {
        guard let screen = Self.targetScreen() else { return }
        let top = screen.safeAreaInsets.top
        if top > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let width = right.minX - left.maxX
            hardwareNotchWidth = width > 0 ? width : 184
            hardwareNotchHeight = top
        } else {
            hardwareNotchWidth = 184
            hardwareNotchHeight = max(24, NSStatusBar.system.thickness)
        }
    }

    var baseWidth: CGFloat { max(120, hardwareNotchWidth + CGFloat(widthOffsetPx)) }
    var baseHeight: CGFloat { max(22, hardwareNotchHeight + CGFloat(heightOffsetPx)) }

    // Open size. Everything is derived from the detected notch, so each MacBook gets a matching island.
    var expandedWidth: CGFloat { max(380, baseWidth + 180) }
    var expandedHeight: CGFloat {
        let hasLyrics = showLyricsExpanded && !lyrics.isEmpty
        return hasLyrics ? max(285, baseHeight + 250) : max(215, baseHeight + 180)
    }

    var bannerWidth: CGFloat { shouldShowLyricsBelowNotch ? max(baseWidth + 180, 360) : max(baseWidth + 140, 320) }
    var bannerHeight: CGFloat { baseHeight + 32 }

    var isBannerVisible: Bool { showTrackBanner && !isExpanded && playback != .stopped }
    var isSneakPeekVisible: Bool { isHovered && !isExpanded && playback != .stopped }
    var shouldShowLyricsBelowNotch: Bool { showLyricsBelowNotch && !lyrics.isEmpty && playback == .playing && !isExpanded }
    var isCompactDroppedDown: Bool { isBannerVisible || isSneakPeekVisible || shouldShowLyricsBelowNotch || (keepSongNameVisible && playback != .stopped) }

    var currentNotchWidth: CGFloat {
        if isExpanded { return expandedWidth }
        if isCompactDroppedDown { return bannerWidth }
        return playback == .stopped ? baseWidth : baseWidth + 84
    }

    var currentNotchHeight: CGFloat {
        if isExpanded { return expandedHeight }
        if isCompactDroppedDown { return bannerHeight }
        return baseHeight
    }

    // MARK: Refresh

    func refresh() {
        guard !refreshInFlight else { return }
        refreshInFlight = true

        // 1. Check system-wide MediaRemote Now Playing first (works with YouTube, Safari, Chrome, Music, Spotify, etc.)
        MediaRemoteBridge.shared.getNowPlayingInfo { [weak self] mrInfo in
            guard let self = self else { return }

            if let info = mrInfo,
               let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let duration = (info["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? 0
                let elapsed = (info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? 0
                let rate = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? 0
                let artData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
                let mrTimestamp = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date

                MediaRemoteBridge.shared.getNowPlayingClient { [weak self] bundleId, displayName in
                    guard let self = self else { return }
                    let source: PlayerSource
                    let id = bundleId ?? ""
                    if id.contains("Music") {
                        source = .music
                    } else if id.contains("spotify") {
                        source = .spotify
                    } else {
                        let name = displayName ?? (id.components(separatedBy: ".").last ?? "Now Playing")
                        source = .nowPlaying(app: name)
                    }

                    let snap = NowPlayingSnapshot(
                        source: source,
                        state: rate > 0 ? .playing : .paused,
                        title: title,
                        artist: artist,
                        position: elapsed,
                        duration: duration,
                        shuffle: false,
                        favorited: false,
                        trackKey: "\(title)|\(artist)",
                        artworkURL: nil,
                        artworkData: artData,
                        positionTimestamp: mrTimestamp,
                        playbackRate: rate
                    )

                    DispatchQueue.main.async {
                        self.apply([snap], denied: false)
                    }
                }
                return
            }

            // 2. Fallback to AppleScript for running Music or Spotify
            self.refreshViaAppleScript()
        }
    }

    private func refreshViaAppleScript() {
        scriptQueue.async { [weak self] in
            guard let self = self else { return }
            let runningSources = PlayerSource.allCases.filter { $0.isRunning }
            if runningSources.isEmpty {
                DispatchQueue.main.async {
                    self.apply([], denied: false)
                }
                return
            }

            var snapshots: [NowPlayingSnapshot] = []
            var denied = false
            var notes: [String] = []

            for source in runningSources {
                let result = self.query(source)
                if let code = result.errorCode {
                    notes.append("\(source.displayName) error \(code): \(result.message ?? "")")
                    if code == -1743 { denied = true }
                    continue
                }
                if let snap = result.snapshot { snapshots.append(snap) }
            }

            let debug = notes.joined(separator: " | ")

            DispatchQueue.main.async {
                if debug != self.debugInfo { print("[Orb] \(debug.isEmpty ? "ok" : debug)") }
                self.debugInfo = debug
                self.apply(snapshots, denied: denied)
            }
        }
    }

    private func apply(_ snapshots: [NowPlayingSnapshot], denied: Bool) {
        refreshInFlight = false

        let chosen = snapshots.first(where: { $0.state == .playing })
            ?? snapshots.first(where: { $0.source == activeSource })
            ?? snapshots.first

        guard let snap = chosen else {
            // Players briefly report nothing while switching state; don't flash "Nothing Playing".
            if !denied && playback != .stopped {
                missCount += 1
                if missCount < 3 { return }
            }
            automationDenied = denied
            playback = .stopped
            activeSource = nil
            trackName = "Nothing Playing"
            artistName = denied
                ? "Allow Orb in Privacy & Security > Automation"
                : (debugInfo.isEmpty ? "Play a song in Music or Spotify" : debugInfo)
            if artworkImage != nil { artworkImage = nil; artworkVersion += 1 }
            artColor = Color(red: 0.15, green: 0.55, blue: 0.95)
            position = 0
            duration = 0
            trackID = ""
            currentTrackKey = ""
            lyrics = []
            upNextQueue = []
            isQueueOpen = false
            videoArtworkURL = nil
            showTrackBanner = false
            return
        }

        missCount = 0
        automationDenied = false
        activeSource = snap.source
        if Date() >= optimisticUntil { playback = snap.state }
        trackName = snap.title.isEmpty ? "Unknown Track" : snap.title
        artistName = snap.artist

        // Precise time tracking from MediaRemote or AppleScript
        if let ts = snap.positionTimestamp, abs(Date().timeIntervalSince(ts)) < 5.0 {
            position = snap.position
            positionStamp = ts
            playbackRate = (snap.state == .playing) ? (snap.playbackRate > 0 ? snap.playbackRate : 1.0) : 0.0
        } else {
            position = snap.position
            positionStamp = Date()
            playbackRate = (snap.state == .playing) ? 1.0 : 0.0
        }

        duration = snap.duration
        shuffleOn = snap.shuffle
        isFavorited = favoriteTrackKeys.contains(snap.trackKey) || snap.favorited

        if snap.trackKey != currentTrackKey {
            currentTrackKey = snap.trackKey
            trackID = snap.trackKey
            lyrics = []
            isQueueOpen = false
            loadArtwork(for: snap)
            fetchMotionArtwork(title: snap.title, artist: snap.artist)
            fetchLyrics(title: snap.title, artist: snap.artist, duration: snap.duration)
            fetchQueue(title: snap.title, artist: snap.artist)
            triggerBanner()
        }
    }

    // MARK: Track-change banner

    private func triggerBanner() {
        guard trackBanner, !isExpanded else { return }
        bannerWork?.cancel()
        showTrackBanner = true
        haptic()
        let work = DispatchWorkItem { [weak self] in self?.showTrackBanner = false }
        bannerWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2, execute: work)
    }

    // MARK: AppleScript helpers (always called on scriptQueue)

    private func run(_ source: String) -> (output: String?, descriptor: NSAppleEventDescriptor?, errorCode: Int?, errorMessage: String?) {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error = error {
            return (nil, nil,
                    error["NSAppleScriptErrorNumber"] as? Int,
                    error["NSAppleScriptErrorMessage"] as? String)
        }
        return (result?.stringValue, result, nil, nil)
    }

    /// Triggers the macOS "Orb wants to control Music" prompt (and registers Orb in
    /// System Settings > Privacy & Security > Automation). Blocks until the user answers.
    private func requestAutomation(for source: PlayerSource) {
        let target = NSAppleEventDescriptor(bundleIdentifier: source.bundleID)
        guard let desc = target.aeDesc else { return }
        let status = AEDeterminePermissionToAutomateTarget(desc,
                                                           AEEventClass(typeWildCard),
                                                           AEEventID(typeWildCard),
                                                           true)
        print("[Orb] automation permission for \(source.bundleID): \(status)")
    }

    /// Asks one player for its state using tiny one-line scripts, so a problem in one query
    /// can't take down the rest.
    private func query(_ source: PlayerSource) -> (snapshot: NowPlayingSnapshot?, errorCode: Int?, message: String?) {
        if !permissionRequested.contains(source.bundleID) {
            permissionRequested.insert(source.bundleID)
            requestAutomation(for: source)
        }

        let tell = "tell application id \"\(source.bundleID)\" to get "

        // 1. Is it playing or paused?
        let stateResult = run(tell + "{player state is playing, player state is paused}")
        if let code = stateResult.errorCode { return (nil, code, stateResult.errorMessage) }
        guard let stateDesc = stateResult.descriptor, stateDesc.numberOfItems >= 2 else { return (nil, nil, nil) }
        let isPlaying = stateDesc.atIndex(1)?.booleanValue ?? false
        let isPaused = stateDesc.atIndex(2)?.booleanValue ?? false
        guard isPlaying || isPaused else { return (nil, nil, nil) }

        // 2. Track info and position.
        var title = ""
        var artist = ""
        var duration = 0.0
        var position = 0.0
        var trackID = ""
        var artworkURL: URL? = nil

        let infoExpression = source == .music
            ? "{name of current track, artist of current track, duration of current track, player position}"
            : "{name of current track, artist of current track, duration of current track, player position, id of current track, artwork url of current track}"
        let info = run(tell + infoExpression)

        if let d = info.descriptor, info.errorCode == nil, d.numberOfItems >= 4 {
            title = d.atIndex(1)?.stringValue ?? ""
            artist = d.atIndex(2)?.stringValue ?? ""
            duration = Self.number(d.atIndex(3)?.stringValue)
            position = Self.number(d.atIndex(4)?.stringValue)
            if source == .spotify, d.numberOfItems >= 6 {
                trackID = d.atIndex(5)?.stringValue ?? ""
                artworkURL = URL(string: d.atIndex(6)?.stringValue ?? "")
            }
        } else {
            // Streams / radio may not expose a normal track. Still show progress if we can.
            let p = run(tell + "player position")
            position = Self.number(p.output)
        }
        if source == .spotify { duration /= 1000 }   // Spotify reports milliseconds

        // 3. Shuffle (optional).
        let shuffleResult = run(tell + (source == .music ? "shuffle enabled" : "shuffling"))
        let shuffle = shuffleResult.descriptor?.booleanValue ?? false

        // 4. Favorite (Apple Music)
        var favorited = false
        if source == .music {
            let favResult = run(tell + "try\n(favorited of current track as boolean)\non error\ntry\n(loved of current track as boolean)\non error\nfalse\nend try\nend try")
            favorited = favResult.descriptor?.booleanValue ?? false
        }

        let key = trackID.isEmpty ? "\(source)|\(title)|\(artist)|\(Int(duration))" : trackID

        let snap = NowPlayingSnapshot(source: source,
                                      state: isPlaying ? .playing : .paused,
                                      title: title, artist: artist,
                                      position: position, duration: duration,
                                      shuffle: shuffle, favorited: favorited, trackKey: key,
                                      artworkURL: artworkURL, artworkData: nil,
                                      positionTimestamp: Date(),
                                      playbackRate: isPlaying ? 1.0 : 0.0)
        return (snap, nil, nil)
    }

    // MARK: Artwork (fetched once per track, never on the main thread)

    private func loadArtwork(for snap: NowPlayingSnapshot) {
        let key = snap.trackKey
        let title = snap.title
        let artist = snap.artist

        if let data = snap.artworkData, let image = NSImage(data: data) {
            setArtwork(image, key: key)
            return
        }

        if let url = snap.artworkURL {
            download(url, key: key)
            return
        }

        if snap.source == .music {
            scriptQueue.async { [weak self] in
                guard let self = self else { return }
                if let image = self.exportMusicArtwork() {
                    DispatchQueue.main.async { self.setArtwork(image, key: key) }
                } else {
                    // Streamed Apple Music tracks often have no local artwork.
                    self.searchArtwork(title: title, artist: artist, key: key)
                }
            }
        } else {
            searchArtwork(title: title, artist: artist, key: key)
        }
    }

    // MARK: - Synchronized Lyrics & Motion Artwork Cache

    private var lyricsCache: [String: [LyricLine]] = [:]
    private var motionArtworkCache: [String: URL] = [:]

    private func cleanLyricsComponent(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: "(?i)vevo$", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        t = t.replacingOccurrences(of: "(?i)\\s*-\\s*topic$", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        return t
    }

    private func cleanSongTitle(_ title: String) -> String {
        var clean = cleanLyricsComponent(title)
        let patterns = [
            "\\s*\\((official\\s+)?(lyric|music|audio|video|visualizer|hd|4k)[^\\)]*\\)",
            "\\s*\\[(official\\s+)?(lyric|music|audio|video|visualizer|hd|4k)[^\\]]*\\]",
            "\\s*-\\s*(official\\s+)?(lyric|music|audio|video|visualizer).*$",
            "\\s*\\((feat\\.?|ft\\.?|featuring)[^\\)]*\\)",
            "\\s*\\[(feat\\.?|ft\\.?|featuring)[^\\]]*\\]",
            "\\s*-\\s*(feat\\.?|ft\\.?|featuring)\\s+.*$",
            "\\s*\\(lyrics?\\)",
            "\\s*\\[lyrics?\\]",
            "\\s*\\((remaster(ed)?|live|mono|stereo|deluxe|bonus|version|anniversary|radio edit|original mix|extended mix|orange version)[^\\)]*\\)",
            "\\s*\\[(remaster(ed)?|live|mono|stereo|deluxe|bonus|version|anniversary|radio edit|original mix|extended mix|orange version)[^\\]]*\\]",
            "\\s*-\\s*(remaster(ed)?|live|mono|stereo|deluxe|bonus|version|anniversary|radio edit|original mix|extended mix).*$",
            "\\s*\\(with\\s+[^\\)]*\\)",
            "\\s*\\[with\\s+[^\\]]*\\]",
            "\\s*-\\s*with\\s+.*$"
        ]
        for pattern in patterns {
            clean = clean.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fetchLyrics(title: String, artist: String, duration: Double) {
        let cacheKey = "\(title.lowercased())|\(artist.lowercased())"
        if let cached = lyricsCache[cacheKey], !cached.isEmpty {
            DispatchQueue.main.async { self.lyrics = cached }
            return
        }

        let cleanTitle = cleanSongTitle(title)
        let cleanArtist = cleanLyricsComponent(artist)
        let primaryArtist = primaryArtistName(artist)

        // 1. Try Apple Music native lyrics first
        if activeSource == .music {
            scriptQueue.async { [weak self] in
                guard let self = self else { return }
                let result = self.run("tell application id \"com.apple.Music\" to try\nlyrics of current track\non error\n\"\"\nend try")
                if let raw = result.output, !raw.isEmpty {
                    let parsed = self.parseLRC(raw, songDuration: duration)
                    if !parsed.isEmpty {
                        self.lyricsCache[cacheKey] = parsed
                        DispatchQueue.main.async { self.lyrics = parsed }
                        return
                    }
                }
                // Fallback to LRCLIB
                self.fetchLRCLIB(title: title, cleanTitle: cleanTitle, artist: cleanArtist, primaryArtist: primaryArtist, duration: duration, cacheKey: cacheKey)
            }
        } else {
            fetchLRCLIB(title: title, cleanTitle: cleanTitle, artist: cleanArtist, primaryArtist: primaryArtist, duration: duration, cacheKey: cacheKey)
        }
    }

    private func primaryArtistName(_ artist: String) -> String {
        let clean = cleanLyricsComponent(artist)
        let separators = [" feat. ", " ft. ", " featuring ", " & ", " and ", " with ", " / ", ", "]
        for sep in separators {
            if let range = clean.range(of: sep, options: .caseInsensitive) {
                return String(clean[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return clean
    }

    private func lrclibRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("Orb/2.0 (macOS; DynamicIslandApp)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 7.0
        return req
    }

    private func lyricsMatchScore(for result: [String: Any], artist: String, title: String, duration: Double) -> Int {
        let rArtist = cleanLyricsComponent((result["artistName"] as? String) ?? "").lowercased()
        let rTitle = cleanLyricsComponent((result["trackName"] as? String) ?? "").lowercased()
        let rDuration = (result["duration"] as? Double) ?? 0

        var score = 0
        let targetTitle = title.lowercased()
        let targetArtist = artist.lowercased()

        if rTitle == targetTitle { score += 20 }
        else if rTitle.contains(targetTitle) || targetTitle.contains(rTitle) { score += 10 }

        if rArtist == targetArtist { score += 20 }
        else if rArtist.contains(targetArtist) || targetArtist.contains(rArtist) { score += 10 }

        if duration > 0 && rDuration > 0 && abs(rDuration - duration) <= 3.0 {
            score += 25
        } else if duration > 0 && rDuration > 0 && abs(rDuration - duration) <= 6.0 {
            score += 12
        }

        let synced = ((result["syncedLyrics"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !synced.isEmpty { score += 40 }

        return score
    }

    private func applyBestLrclibMatch(_ results: [[String: Any]], title: String, artist: String, duration: Double, cacheKey: String) -> Bool {
        // Strictly prioritize results that contain synchronized lyrics
        let syncedOnly = results.filter {
            let s = ($0["syncedLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !s.isEmpty
        }
        let pool = syncedOnly.isEmpty ? results : syncedOnly

        let sorted = pool.sorted { lhs, rhs in
            lyricsMatchScore(for: lhs, artist: artist, title: title, duration: duration) >
            lyricsMatchScore(for: rhs, artist: artist, title: title, duration: duration)
        }

        guard let match = sorted.first else { return false }
        let synced = (match["syncedLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let plain = (match["plainLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !synced.isEmpty {
            let parsed = self.parseLRC(synced, songDuration: duration)
            if !parsed.isEmpty {
                self.lyricsCache[cacheKey] = parsed
                DispatchQueue.main.async { self.lyrics = parsed }
                return true
            }
        } else if !plain.isEmpty {
            let parsed = self.parseLRC(plain, songDuration: duration)
            if !parsed.isEmpty {
                self.lyricsCache[cacheKey] = parsed
                DispatchQueue.main.async { self.lyrics = parsed }
                return true
            }
        }
        return false
    }

    private func fetchLRCLIB(title: String, cleanTitle: String, artist: String, primaryArtist: String, duration: Double, cacheKey: String) {
        var candidates: [(title: String, artist: String)] = [
            (cleanTitle, primaryArtist),
            (cleanTitle, artist)
        ]
        if cleanTitle.contains(" - ") {
            let parts = cleanTitle.components(separatedBy: " - ")
            if parts.count >= 2 {
                let p1 = cleanSongTitle(parts[0])
                let p2 = cleanSongTitle(parts[1])
                candidates.append((p2, p1))
                candidates.append((p1, p2))
                candidates.append((p2, primaryArtist))
                candidates.append((p1, primaryArtist))
            }
        }

        func tryNextCandidate(index: Int) {
            guard index < candidates.count else {
                // Fallback to full-text search with q=
                let qStr = "\(cleanTitle) \(primaryArtist)"
                if let encodedQ = qStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let qUrl = URL(string: "https://lrclib.net/api/search?q=\(encodedQ)") {
                    URLSession.shared.dataTask(with: lrclibRequest(url: qUrl)) { [weak self] qData, _, _ in
                        guard let self = self, let qData = qData else { return }
                        if let qResults = try? JSONSerialization.jsonObject(with: qData) as? [[String: Any]], !qResults.isEmpty {
                            if self.applyBestLrclibMatch(qResults, title: cleanTitle, artist: primaryArtist, duration: duration, cacheKey: cacheKey) {
                                return
                            }
                        }
                        self.fetchLRCLIBDirect(cleanTitle: cleanTitle, artist: primaryArtist, duration: duration, cacheKey: cacheKey)
                    }.resume()
                } else {
                    self.fetchLRCLIBDirect(cleanTitle: cleanTitle, artist: primaryArtist, duration: duration, cacheKey: cacheKey)
                }
                return
            }

            let cand = candidates[index]
            guard let encodedTitle = cand.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedArtist = cand.artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://lrclib.net/api/search?track_name=\(encodedTitle)&artist_name=\(encodedArtist)") else {
                tryNextCandidate(index: index + 1)
                return
            }

            URLSession.shared.dataTask(with: lrclibRequest(url: url)) { [weak self] data, _, _ in
                guard let self = self else { return }
                if let data = data,
                   let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   !results.isEmpty,
                   self.applyBestLrclibMatch(results, title: cand.title, artist: cand.artist, duration: duration, cacheKey: cacheKey) {
                    return
                }
                tryNextCandidate(index: index + 1)
            }.resume()
        }

        tryNextCandidate(index: 0)
    }

    private func fetchLRCLIBDirect(cleanTitle: String, artist: String, duration: Double, cacheKey: String) {
        var directComponents = URLComponents(string: "https://lrclib.net/api/get")
        directComponents?.queryItems = [
            URLQueryItem(name: "track_name", value: cleanTitle),
            URLQueryItem(name: "artist_name", value: artist)
        ]
        if let directUrl = directComponents?.url {
            URLSession.shared.dataTask(with: lrclibRequest(url: directUrl)) { [weak self] data, _, _ in
                guard let self = self, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                _ = self.applyBestLrclibMatch([json], title: cleanTitle, artist: artist, duration: duration, cacheKey: cacheKey)
            }.resume()
        }
    }

    // MARK: - Motion Artwork Fetching (Apple Music Animated Artwork)

    func fetchMotionArtwork(title: String, artist: String) {
        guard motionArtworkEnabled else {
            DispatchQueue.main.async { self.videoArtworkURL = nil }
            return
        }

        let cacheKey = "\(title.lowercased())|\(artist.lowercased())"
        if let cached = motionArtworkCache[cacheKey] {
            DispatchQueue.main.async { self.videoArtworkURL = cached }
            return
        }

        let cleanTitle = cleanSongTitle(title)
        let cleanArtist = cleanLyricsComponent(artist)
        guard var components = URLComponents(string: "https://itunes.apple.com/search") else { return }
        components.queryItems = [
            URLQueryItem(name: "term", value: "\(cleanTitle) \(cleanArtist)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let searchUrl = components.url else { return }

        URLSession.shared.dataTask(with: searchUrl) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first else {
                DispatchQueue.main.async { self?.videoArtworkURL = nil }
                return
            }

            let viewUrlStr = (first["collectionViewUrl"] as? String) ?? (first["trackViewUrl"] as? String) ?? ""
            guard let viewUrl = URL(string: viewUrlStr) else {
                DispatchQueue.main.async { self.videoArtworkURL = nil }
                return
            }

            // Fetch the Apple Music web page HTML to locate the .m3u8 motion video stream
            var req = URLRequest(url: viewUrl)
            req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

            URLSession.shared.dataTask(with: req) { pageData, _, _ in
                guard let pageData = pageData, let html = String(data: pageData, encoding: .utf8) else {
                    DispatchQueue.main.async { self.videoArtworkURL = nil }
                    return
                }

                // Apple stores editorial motion videos under mvod.itunes.apple.com with .m3u8 extension
                if let regex = try? NSRegularExpression(pattern: "https://mvod\\.itunes\\.apple\\.com[^\"]+\\.m3u8"),
                   let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range, in: html) {
                    let videoUrlStr = String(html[range])
                    if let videoUrl = URL(string: videoUrlStr) {
                        self.motionArtworkCache[cacheKey] = videoUrl
                        DispatchQueue.main.async {
                            if self.motionArtworkEnabled {
                                self.videoArtworkURL = videoUrl
                            }
                        }
                        return
                    }
                }
                DispatchQueue.main.async { self.videoArtworkURL = nil }
            }.resume()
        }.resume()
    }

    private func parseLRC(_ lrc: String, songDuration: Double = 0) -> [LyricLine] {
        let offsetPattern = "\\[offset:\\s*([+-]?\\d+)\\]"
        var offsetMs: Double = 0
        if let offsetRegex = try? NSRegularExpression(pattern: offsetPattern, options: .caseInsensitive),
           let match = offsetRegex.firstMatch(in: lrc, range: NSRange(lrc.startIndex..., in: lrc)),
           let range = Range(match.range(at: 1), in: lrc) {
            offsetMs = Double(lrc[range]) ?? 0
        }

        let timeTagPattern = "\\[(\\d{1,2}):(\\d{2})(?:\\.(\\d{1,3}))?\\]"
        guard let timeRegex = try? NSRegularExpression(pattern: timeTagPattern) else { return [] }

        var rawLines: [(time: Double, text: String)] = []

        for line in lrc.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let nsLine = trimmed as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)
            let matches = timeRegex.matches(in: trimmed, options: [], range: fullRange)
            guard !matches.isEmpty, let lastMatch = matches.last else { continue }

            let textStart = lastMatch.range.location + lastMatch.range.length
            guard textStart <= nsLine.length else { continue }
            let text = nsLine.substring(from: textStart).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            for match in matches {
                let minStr = nsLine.substring(with: match.range(at: 1))
                let secStr = nsLine.substring(with: match.range(at: 2))
                var fraction: Double = 0
                if match.range(at: 3).location != NSNotFound {
                    let fracStr = nsLine.substring(with: match.range(at: 3))
                    let div = fracStr.count == 3 ? 1000.0 : 100.0
                    fraction = (Double(fracStr) ?? 0) / div
                }
                let total = (Double(minStr) ?? 0) * 60.0 + (Double(secStr) ?? 0) + fraction + (offsetMs / 1000.0)
                rawLines.append((time: max(0, total), text: text))
            }
        }

        if rawLines.isEmpty {
            let plainLines = lrc.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("[") }
            if !plainLines.isEmpty {
                let step = songDuration > 0 ? songDuration / Double(max(plainLines.count, 1)) : 4.0
                return plainLines.enumerated().map { i, text in
                    let t = Double(i) * step
                    let nextT = Double(i + 1) * step
                    return LyricLine(time: t, endTime: nextT, text: text)
                }
            }
            return []
        }

        let sorted = rawLines.sorted(by: { $0.time < $1.time })
        var result: [LyricLine] = []

        for i in 0..<sorted.count {
            let t = sorted[i].time
            let nextT = (i + 1 < sorted.count) ? sorted[i + 1].time : (songDuration > t ? songDuration : t + 4.5)
            let gap = max(0.6, nextT - t)

            // Realistic vocal duration based on words and characters
            let text = sorted[i].text
            let words = max(1, text.split(separator: " ").count)
            let charCount = max(4, text.count)
            let estimatedVocalDuration = max(1.2, min(Double(words) * 0.45, Double(charCount) * 0.14))
            let vocalDuration = min(estimatedVocalDuration, max(0.5, gap - 0.25))

            let endTime = t + vocalDuration
            result.append(LyricLine(time: t, endTime: endTime, text: text))
        }

        return result
    }

    private func exportMusicArtwork() -> NSImage? {
        let path = NSTemporaryDirectory() + "orb_art_\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = """
        tell application id "com.apple.Music"
            try
                set artData to raw data of artwork 1 of current track
            on error
                return "none"
            end try
        end tell
        try
            set f to open for access (POSIX file "\(path)") with write permission
            set eof f to 0
            write artData to f
            close access f
        on error
            try
                close access (POSIX file "\(path)")
            end try
            return "none"
        end try
        return "ok"
        """

        let result = run(script)
        guard result.output == "ok", let data = FileManager.default.contents(atPath: path) else { return nil }
        return NSImage(data: data)
    }

    private func searchArtwork(title: String, artist: String, key: String) {
        guard var components = URLComponents(string: "https://itunes.apple.com/search") else {
            DispatchQueue.main.async { self.failArtwork(key: key) }
            return
        }
        components.queryItems = [
            URLQueryItem(name: "term", value: "\(title) \(artist)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components.url else {
            DispatchQueue.main.async { self.failArtwork(key: key) }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let small = results.first?["artworkUrl100"] as? String,
                  let big = URL(string: small.replacingOccurrences(of: "100x100", with: "300x300"))
            else {
                DispatchQueue.main.async { self.failArtwork(key: key) }
                return
            }
            self.download(big, key: key)
        }.resume()
    }

    private func download(_ url: URL, key: String) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            guard let data = data, let image = NSImage(data: data) else {
                DispatchQueue.main.async { self.failArtwork(key: key) }
                return
            }
            DispatchQueue.main.async { self.setArtwork(image, key: key) }
        }.resume()
    }

    private func setArtwork(_ image: NSImage, key: String) {
        guard key == currentTrackKey else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            artworkImage = image
            artworkVersion += 1
        }

        // Work out the dominant colour off the main thread.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let nsColor = Self.dominantColor(of: image) else { return }
            DispatchQueue.main.async {
                guard let self = self, key == self.currentTrackKey else { return }
                withAnimation(.easeInOut(duration: 0.6)) { self.artColor = Color(nsColor: nsColor) }
            }
        }
    }

    /// No artwork could be found for this track: drop the previous track's picture.
    private func failArtwork(key: String) {
        guard key == currentTrackKey, artworkImage != nil else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            artworkImage = nil
            artworkVersion += 1
        }
    }

    /// A vivid, bright representative colour of the artwork (weighted towards saturated pixels).
    private static func dominantColor(of image: NSImage) -> NSColor? {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let size = 24
        var pixels = [UInt8](repeating: 0, count: size * size * 4)

        let drawn: Bool = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress,
                                      width: size, height: size,
                                      bitsPerComponent: 8, bytesPerRow: size * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.interpolationQuality = .medium
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard drawn else { return nil }

        var r = 0.0, g = 0.0, b = 0.0, total = 0.0
        for i in 0..<(size * size) {
            let pr = Double(pixels[i * 4]) / 255
            let pg = Double(pixels[i * 4 + 1]) / 255
            let pb = Double(pixels[i * 4 + 2]) / 255
            let maxc = max(pr, pg, pb)
            let minc = min(pr, pg, pb)
            let sat = maxc == 0 ? 0 : (maxc - minc) / maxc
            let weight = 0.05 + sat * sat * 2.0 + maxc * 0.2
            r += pr * weight
            g += pg * weight
            b += pb * weight
            total += weight
        }
        guard total > 0 else { return nil }

        let base = NSColor(deviceRed: CGFloat(r / total), green: CGFloat(g / total), blue: CGFloat(b / total), alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        base.getHue(&h, saturation: &s, brightness: &v, alpha: &a)

        // Greyscale artwork: keep it neutral instead of inventing a hue.
        if s < 0.12 { return NSColor(white: 0.88, alpha: 1) }

        s = min(1, max(s * 1.15, 0.35))
        v = max(v, 0.82)
        return NSColor(hue: h, saturation: s, brightness: v, alpha: 1)
    }

    // MARK: Calendar

    func setupCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if hasCalendarAccess(status) {
            calendarAccess = .granted
            loadEvents()
        } else if status == .notDetermined {
            requestCalendarAccess()
        } else {
            calendarAccess = .denied
        }
    }

    private func hasCalendarAccess(_ status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    private func requestCalendarAccess() {
        let handler: (Bool, Error?) -> Void = { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.calendarAccess = granted ? .granted : .denied
                if granted { self?.loadEvents() }
            }
        }
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents(completion: handler)
        } else {
            eventStore.requestAccess(to: .event, completion: handler)
        }
    }

    func loadEvents() {
        guard calendarAccess == .granted else { return }
        let store = eventStore
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let cal = Calendar.current
            let now = Date()
            let start = cal.startOfDay(for: now)
            guard let end = cal.date(byAdding: .day, value: 8, to: start) else { return }

            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
            let upcoming = store.events(matching: predicate)
                .filter { $0.endDate > now }
                .sorted { $0.startDate < $1.startDate }
                .prefix(25)

            var mapped: [OrbCalendarEvent] = []
            for ev in upcoming {
                let nsColor: NSColor = ev.calendar?.color ?? NSColor.systemBlue
                let ident = ev.eventIdentifier ?? UUID().uuidString
                mapped.append(OrbCalendarEvent(id: "\(ident)-\(ev.startDate.timeIntervalSince1970)",
                                               title: ev.title ?? "Untitled",
                                               start: ev.startDate,
                                               end: ev.endDate,
                                               isAllDay: ev.isAllDay,
                                               color: Color(nsColor: nsColor)))
            }
            DispatchQueue.main.async { self?.upcomingEvents = mapped }
        }
    }

    /// Safely opens Apple Calendar without deprecated or unsupported URL schemes.
    func openCalendar(at date: Date? = nil) {
        if let date = date {
            let cal = Calendar.current
            let year = cal.component(.year, from: date)
            let month = cal.component(.month, from: date)
            let day = cal.component(.day, from: date)
            let script = """
            tell application "Calendar"
                activate
                try
                    set targetDate to current date
                    set year of targetDate to \(year)
                    set month of targetDate to \(month)
                    set day of targetDate to \(day)
                    switch view to day view
                    view calendar at targetDate
                on error
                    activate
                end try
            end tell
            """
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    appleScript.executeAndReturnError(&error)
                }
            }
        } else {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } else {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
            }
        }
    }

    // MARK: Controls (only ever sent to the active, running player)

    private func send(_ command: String) {
        guard let source = activeSource else { return }

        switch source {
        case .nowPlaying:
            // MediaRemote private framework commands:
            // 2 = TogglePlayPause, 4 = NextTrack, 5 = PreviousTrack
            if command == "playpause" {
                MediaRemoteBridge.shared.sendCommand(2)
            } else if command == "next track" {
                MediaRemoteBridge.shared.sendCommand(4)
            } else if command == "previous track" {
                MediaRemoteBridge.shared.sendCommand(5)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.refresh() }

        case .music, .spotify:
            let script = "tell application id \"\(source.bundleID)\" to \(command)"
            scriptQueue.async { [weak self] in
                _ = self?.run(script)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self?.refresh() }
            }
        }
    }

    func togglePlayPause() {
        let now = Date()
        // Freeze / resume the interpolated position so the bar doesn't jump.
        position = livePosition(at: now)
        positionStamp = now
        optimisticUntil = now.addingTimeInterval(1.0)
        playback = (playback == .playing) ? .paused : .playing   // optimistic
        send("playpause")
    }

    func skipNext() { send("next track") }
    func skipPrevious() { send("previous track") }

    func toggleFavorite() {
        guard !trackID.isEmpty else { return }
        haptic()
        if favoriteTrackKeys.contains(trackID) {
            favoriteTrackKeys.remove(trackID)
            isFavorited = false
        } else {
            favoriteTrackKeys.insert(trackID)
            isFavorited = true
        }
        UserDefaults.standard.set(Array(favoriteTrackKeys), forKey: "orbFavoriteKeys")

        if activeSource == .music {
            scriptQueue.async { [weak self] in
                _ = self?.run("tell application id \"com.apple.Music\" to try\nset favorited of current track to not (favorited of current track)\nend try")
            }
        }
    }

    private func fetchQueue(title: String, artist: String) {
        guard let encoded = "\(artist) \(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=9") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    var list: [QueueTrack] = []
                    for (idx, r) in results.enumerated() {
                        let name = r["trackName"] as? String ?? ""
                        let art = r["artistName"] as? String ?? ""
                        let dur = (r["trackTimeMillis"] as? Double ?? 0) / 1000.0
                        if !name.isEmpty && name.lowercased() != title.lowercased() {
                            list.append(QueueTrack(id: "\(idx)-\(name)", title: name, artist: art, duration: dur))
                        }
                    }
                    DispatchQueue.main.async {
                        self.upNextQueue = list
                    }
                }
            } catch {}
        }.resume()
    }

    func toggleShuffle() {
        guard let source = activeSource else { return }
        shuffleOn.toggle()   // optimistic
        send(source == .music
             ? "set shuffle enabled to (not shuffle enabled)"
             : "set shuffling to (not shuffling)")
    }

    func seek(toFraction fraction: Double) {
        guard duration > 0 else { return }
        let target = min(max(fraction, 0), 1) * duration
        position = target
        positionStamp = Date()
        if case .nowPlaying = activeSource {
            MediaRemoteBridge.shared.seek(to: target)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.refresh() }
        } else {
            send("set player position to \(String(format: "%.2f", target))")
        }
    }

    func openActivePlayer() {
        guard let source = activeSource else { return }
        switch source {
        case .music, .spotify:
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: source.bundleID) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        case .nowPlaying(let app):
            if let running = NSWorkspace.shared.runningApplications.first(where: {
                $0.localizedName?.localizedCaseInsensitiveContains(app) == true ||
                $0.bundleIdentifier?.localizedCaseInsensitiveContains(app) == true
            }) {
                if #available(macOS 14.0, *) {
                    running.activate()
                } else {
                    running.activate(options: [.activateIgnoringOtherApps])
                }
            }
        }
    }
}
