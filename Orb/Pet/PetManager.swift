import SwiftUI
import Combine
import IOKit.ps

final class PetManager: ObservableObject {
    static let shared = PetManager()

    // MARK: - Companion Configuration
    @Published var petType: NotchPetType = {
        let raw = UserDefaults.standard.string(forKey: "orbPetType") ?? NotchPetType.cat.rawValue
        return NotchPetType(rawValue: raw) ?? .cat
    }() {
        didSet {
            UserDefaults.standard.set(petType.rawValue, forKey: "orbPetType")
            resetSpiderState()
        }
    }

    @Published var placement: NotchPetPlacement = {
        let raw = UserDefaults.standard.string(forKey: "orbPetPlacement") ?? NotchPetPlacement.right.rawValue
        return NotchPetPlacement(rawValue: raw) ?? .right
    }() {
        didSet {
            UserDefaults.standard.set(placement.rawValue, forKey: "orbPetPlacement")
            resetPetPosition()
        }
    }
    @Published var petActiveSide: NotchPetPlacement = .right

    @Published var petActivity: NotchPetActivity = {
        let raw = UserDefaults.standard.string(forKey: "orbPetActivity") ?? NotchPetActivity.playful.rawValue
        return NotchPetActivity(rawValue: raw) ?? .playful
    }() {
        didSet {
            UserDefaults.standard.set(petActivity.rawValue, forKey: "orbPetActivity")
            restartDecisionTimer()
        }
    }

    // MARK: - Wardrobe Selections
    @Published var petHat: PetHat = {
        let raw = UserDefaults.standard.string(forKey: "orbPetHat") ?? PetHat.none.rawValue
        return PetHat(rawValue: raw) ?? .none
    }() {
        didSet { UserDefaults.standard.set(petHat.rawValue, forKey: "orbPetHat") }
    }

    @Published var petOutfit: PetOutfit = {
        let raw = UserDefaults.standard.string(forKey: "orbPetOutfit") ?? PetOutfit.none.rawValue
        return PetOutfit(rawValue: raw) ?? .none
    }() {
        didSet { UserDefaults.standard.set(petOutfit.rawValue, forKey: "orbPetOutfit") }
    }

    @Published var weatherMode: PetWeatherMode = {
        let raw = UserDefaults.standard.string(forKey: "orbPetWeatherMode") ?? PetWeatherMode.auto.rawValue
        return PetWeatherMode(rawValue: raw) ?? .auto
    }() {
        didSet { UserDefaults.standard.set(weatherMode.rawValue, forKey: "orbPetWeatherMode") }
    }

    // MARK: - Smart Behavior Toggles
    @Published var djHeadphonesEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetDJHeadphones") as? Bool ?? true {
        didSet { UserDefaults.standard.set(djHeadphonesEnabled, forKey: "orbPetDJHeadphones") }
    }
    @Published var singingEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetSinging") as? Bool ?? true {
        didSet { UserDefaults.standard.set(singingEnabled, forKey: "orbPetSinging") }
    }
    @Published var adaptiveDanceEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetAdaptiveDance") as? Bool ?? true {
        didSet { UserDefaults.standard.set(adaptiveDanceEnabled, forKey: "orbPetAdaptiveDance") }
    }
    @Published var chargingSnackEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetChargingSnack") as? Bool ?? true {
        didSet { UserDefaults.standard.set(chargingSnackEnabled, forKey: "orbPetChargingSnack") }
    }
    @Published var typingCompanionEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetTypingCompanion") as? Bool ?? true {
        didSet { UserDefaults.standard.set(typingCompanionEnabled, forKey: "orbPetTypingCompanion") }
    }
    @Published var breakReminderEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetBreakReminder") as? Bool ?? true {
        didSet { UserDefaults.standard.set(breakReminderEnabled, forKey: "orbPetBreakReminder") }
    }
    @Published var weatherReactionsEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetWeatherReactions") as? Bool ?? true {
        didSet { UserDefaults.standard.set(weatherReactionsEnabled, forKey: "orbPetWeatherReactions") }
    }
    @Published var roamingEnabled: Bool = UserDefaults.standard.object(forKey: "orbPetRoaming") as? Bool ?? true {
        didSet { UserDefaults.standard.set(roamingEnabled, forKey: "orbPetRoaming") }
    }

    // MARK: - Live Animation & Physical State
    @Published var petPositionX: CGFloat = 0
    @Published var petTargetX: CGFloat = 0
    @Published var petFacingLeft: Bool = false
    @Published var petAction: NotchPetAction = .idle
    @Published var petWalkStep: Int = 0
    @Published var petSleepZ: Int = 0
    @Published var isSingingVocal: Bool = false
    @Published var isFastDancing: Bool = false

    // Spider Hanging Silk Mechanics
    @Published var spiderSilkLength: CGFloat = 0
    @Published var spiderSwingAngle: Double = 0
    @Published var isSpiderDangling: Bool = false

    // Live Sensor States
    @Published var isCharging: Bool = false
    @Published var isTypingFast: Bool = false
    @Published var speechBubbleText: String? = nil

    // Feeding & Mood
    @Published var hungerLevel: Double = 0.8
    @Published var happinessLevel: Double = 0.95
    @Published var activeTreat: PetTreat? = nil
    @Published var isEating: Bool = false

    // MARK: - Internal Timers & Monitors
    private var decisionTimer: Timer?
    private var motionTimer: Timer?
    private var powerCheckTimer: Timer?
    private var breakReminderTimer: Timer?
    private var typingResetWorkItem: DispatchWorkItem?
    private var speechBubbleResetWorkItem: DispatchWorkItem?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var recentKeyPressCount: Int = 0
    private var lastKeyTime: Date = Date()
    private var workSessionMinutes: Int = 0

    private init() {
        checkPowerSource()
        setupTimers()
        setupTypingMonitor()
        resetPetPosition()
    }

    // MARK: - Geometry Beside Notch

    func computedPetX(currentNotchWidth: CGFloat) -> CGFloat {
        let halfIsland = (currentNotchWidth + 20) / 2
        let baseGap: CGFloat = 36
        let side: NotchPetPlacement = (placement == .both) ? petActiveSide : placement
        switch side {
        case .left:
            return -(halfIsland + baseGap + petPositionX)
        case .right, .both:
            return (halfIsland + baseGap + petPositionX)
        }
    }

    func resetPetPosition() {
        petPositionX = 0
        petTargetX = 0
        if placement == .left {
            petFacingLeft = false  // Faces right toward the notch
            petActiveSide = .left
        } else {
            petFacingLeft = true   // Faces left toward the notch
            petActiveSide = .right
        }
    }

    deinit {
        stopTimers()
        if let gm = globalKeyMonitor { NSEvent.removeMonitor(gm) }
        if let lm = localKeyMonitor { NSEvent.removeMonitor(lm) }
    }

    // MARK: - Effective Computed Wardrobe (Context-Aware)

    private var resolvedWeather: PetWeatherMode {
        if weatherMode != .auto { return weatherMode }
        let month = Calendar.current.component(.month, from: Date())
        let hour = Calendar.current.component(.hour, from: Date())
        if month == 12 || month <= 2 {
            return .snowy
        } else if hour >= 8 && hour <= 17 {
            return .sunny
        } else {
            return .rainy
        }
    }

    var effectiveHat: PetHat {
        // 1. If Music is playing & DJ Headphones enabled, wear DJ Headphones
        // Only override if user hasn't selected an explicit wardrobe hat
        if djHeadphonesEnabled && OrbState.shared.playback == .playing && (petHat == .none || petHat == .djHeadphones) {
            return .djHeadphones
        }
        // 2. Weather reactions (if enabled and no explicit hat chosen)
        if weatherReactionsEnabled && petHat == .none {
            switch resolvedWeather {
            case .rainy: return .rainHat
            case .snowy: return .winterBeanie
            case .sunny: return .sunglasses
            case .auto: break
            }
        }
        // 3. User selected hat
        return petHat
    }

    var effectiveOutfit: PetOutfit {
        // Weather reactions (if enabled and no explicit outfit chosen)
        if weatherReactionsEnabled && petOutfit == .none {
            switch resolvedWeather {
            case .rainy: return .raincoat
            case .snowy: return .winterSweater
            case .sunny, .auto: break
            }
        }
        return petOutfit
    }

    // MARK: - Lifecycle & Timers

    func setupTimers() {
        stopTimers()

        // 1. Decision Timer: AI behavior selector
        restartDecisionTimer()

        // 2. Smooth Motion Tick Timer (25 FPS for silky smooth micro-steps)
        motionTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            self?.tickMotion()
        }

        // 3. Power Source / Battery Check (every 5 seconds)
        powerCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPowerSource()
        }

        // 4. Pomodoro / Break Reminder (tracks 45-60 min work chunks)
        breakReminderTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.tickWorkSession()
        }
    }

    func stopTimers() {
        decisionTimer?.invalidate()
        decisionTimer = nil
        motionTimer?.invalidate()
        motionTimer = nil
        powerCheckTimer?.invalidate()
        powerCheckTimer = nil
        breakReminderTimer?.invalidate()
        breakReminderTimer = nil
    }

    private func restartDecisionTimer() {
        decisionTimer?.invalidate()
        let interval = petActivity.interval
        decisionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.decideNextAction()
        }
    }

    // MARK: - Behavioral Brain

    private func decideNextAction() {
        guard !isEating, petAction != .happy, petAction != .typing, petAction != .stretching else { return }

        let orb = OrbState.shared
        let isMusicPlaying = orb.playback == .playing

        // 1. Music Reactive Mode: Dance or Sing
        if isMusicPlaying && adaptiveDanceEnabled {
            let r = Double.random(in: 0...1)
            if r < 0.65 {
                petAction = .dancing
                isFastDancing = Double.random(in: 0...1) > 0.4
                return
            }
        }

        // 2. Spider Specialty: Dangle down from notch silk thread
        if petType == .spider && Double.random(in: 0...1) < 0.45 {
            triggerSpiderDangle()
            return
        }

        // 3. Notch Roaming Walking Beside Notch
        if roamingEnabled && Double.random(in: 0...1) < 0.60 {
            if placement == .both && Double.random(in: 0...1) < 0.35 {
                petActiveSide = (petActiveSide == .right) ? .left : .right
                petPositionX = 0
            }
            let target = CGFloat.random(in: 0...24)
            petTargetX = target
            let side = (placement == .both) ? petActiveSide : placement
            if side == .right {
                petFacingLeft = (target < petPositionX)
            } else {
                petFacingLeft = (target > petPositionX)
            }
            petAction = .walking
            return
        }

        // 4. Idle or Sleep
        let side = (placement == .both) ? petActiveSide : placement
        petFacingLeft = (side == .right)
        let idleChoice = Double.random(in: 0...1)
        if idleChoice < 0.70 {
            petAction = .idle
        } else {
            petAction = .sleeping
        }
    }

    private func triggerSpiderDangle() {
        isSpiderDangling = true
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            spiderSilkLength = CGFloat.random(in: 5...11)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...4.5)) { [weak self] in
            guard let self = self else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                self.spiderSilkLength = 0
                self.isSpiderDangling = false
            }
        }
    }

    private func resetSpiderState() {
        spiderSilkLength = 0
        spiderSwingAngle = 0
        isSpiderDangling = false
    }

    // MARK: - 25fps Motion Ticker (Lightweight, No Redraw Overhead)

    private func tickMotion() {
        // Sync Karaoke Lyrics Singing
        if singingEnabled && OrbState.shared.playback == .playing {
            syncSingingState()
        } else if isSingingVocal {
            isSingingVocal = false
        }

        // Handle Spider pendulum swing when dangling
        if isSpiderDangling {
            let t = Date().timeIntervalSinceReferenceDate
            spiderSwingAngle = sin(t * 3.5) * 6.0
        }

        switch petAction {
        case .walking:
            let diff = petTargetX - petPositionX
            let stepSpeed: CGFloat = (petActivity == .energetic) ? 2.2 : (petActivity == .playful ? 1.6 : 1.0)

            if abs(diff) <= stepSpeed {
                petPositionX = petTargetX
                petAction = .idle
                let side = (placement == .both) ? petActiveSide : placement
                petFacingLeft = (side == .right)
            } else {
                petPositionX += (diff > 0 ? stepSpeed : -stepSpeed)
                let side = (placement == .both) ? petActiveSide : placement
                if side == .right {
                    petFacingLeft = (diff < 0)
                } else {
                    petFacingLeft = (diff > 0)
                }
                petWalkStep = (petWalkStep + 1) % 4
            }

        case .dancing:
            petWalkStep = (petWalkStep + 1) % 4
            if OrbState.shared.playback != .playing {
                petAction = .idle
            }

        case .sleeping:
            petSleepZ = (petSleepZ + 1) % 40

        case .idle, .singing, .typing, .stretching, .eating, .happy:
            break
        }
    }

    // MARK: - Karaoke Lyrics Singing Lip-Sync

    private func syncSingingState() {
        let orb = OrbState.shared
        guard !orb.lyrics.isEmpty else {
            if isSingingVocal { isSingingVocal = false }
            return
        }

        let currentPos = orb.livePosition()
        let isPhraseActive = orb.lyrics.contains { line in
            currentPos >= line.time && currentPos <= line.endTime
        }

        if isPhraseActive != isSingingVocal {
            isSingingVocal = isPhraseActive
            if isPhraseActive && petAction != .dancing {
                petAction = .singing
            } else if !isPhraseActive && petAction == .singing {
                petAction = .idle
            }
        }
    }

    // MARK: - IOKit Power Source Check (Battery Snack)

    func checkPowerSource() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }

        var charging = false
        for ps in list {
            if let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any] {
                let isCh = desc[kIOPSIsChargingKey] as? Bool ?? false
                let powerState = desc[kIOPSPowerSourceStateKey] as? String
                if isCh || powerState == kIOPSACPowerValue {
                    charging = true
                    break
                }
            }
        }

        if charging != isCharging {
            isCharging = charging
            if isCharging && chargingSnackEnabled {
                showSpeechBubble("MagSafe Charging! ⚡️", duration: 3.0)
            }
        }
    }

    // MARK: - Typing & Work Companion Monitor

    private func setupTypingMonitor() {
        // Global monitor (records user typing speed across apps)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.recordKeyPress()
        }

        // Local monitor (Orb window focused)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.recordKeyPress()
            return event
        }
    }

    func recordKeyPress() {
        guard typingCompanionEnabled else { return }

        let now = Date()
        if now.timeIntervalSince(lastKeyTime) < 1.8 {
            recentKeyPressCount += 1
        } else {
            recentKeyPressCount = 1
        }
        lastKeyTime = now

        // Fast typing threshold (e.g. coding / rapid typing)
        if recentKeyPressCount >= 5 && !isTypingFast {
            isTypingFast = true
            petAction = .typing
            let cheers = ["Fast coder! ⚡️", "Crushing it! 💻", "Speed run! 🔥", "You got this! 🚀"]
            showSpeechBubble(cheers.randomElement() ?? "Fast coder! ⚡️", duration: 3.0)

            // Release action back to idle after 4 seconds of cheer so AI decision loop isn't permanently locked
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                guard let self = self else { return }
                if self.petAction == .typing {
                    self.petAction = .idle
                }
            }
        }

        // Reset debounce timer
        typingResetWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isTypingFast = false
            self.recentKeyPressCount = 0
            if self.petAction == .typing {
                self.petAction = .idle
            }
        }
        typingResetWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }

    // MARK: - Pomodoro / Break Reminder

    private func tickWorkSession() {
        guard breakReminderEnabled else { return }

        // Only count towards work session if there was recent typing in the last 2 minutes
        let isCurrentlyActive = abs(Date().timeIntervalSince(lastKeyTime)) < 120
        if isCurrentlyActive {
            workSessionMinutes += 1
        } else if abs(Date().timeIntervalSince(lastKeyTime)) > 900 {
            // User stepped away / took a break (>15 min idle); reset counter
            workSessionMinutes = 0
        }

        // Trigger yawn and water reminder after 45 minutes of active work
        if workSessionMinutes >= 45 {
            workSessionMinutes = 0
            triggerBreakReminder()
        }
    }

    func triggerBreakReminder() {
        petAction = .stretching
        showSpeechBubble("Time to stretch & hydrate! 💧", duration: 6.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.petAction == .stretching else { return }
            self.petAction = .idle
        }
    }

    // MARK: - Interactive Feeding Station

    func feed(treat: PetTreat) {
        OrbState.shared.haptic()
        activeTreat = treat
        isEating = true
        petAction = .eating
        hungerLevel = min(1.0, hungerLevel + 0.35)
        happinessLevel = min(1.0, happinessLevel + 0.25)

        showSpeechBubble("nom nom nom! 😋", duration: 2.5)

        // After eating, perform happy victory hop
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self = self else { return }
            self.activeTreat = nil
            self.isEating = false
            self.petAction = .happy
            self.showSpeechBubble("❤️ Delicious!", duration: 1.8)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                guard let self = self, self.petAction == .happy else { return }
                self.petAction = .idle
            }
        }
    }

    // MARK: - User Direct Interaction (Petting)

    func petInteracted() {
        OrbState.shared.haptic()
        if isSpiderDangling {
            // Spider does a spin and zips up
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                spiderSilkLength = 0
                isSpiderDangling = false
            }
            showSpeechBubble("Wheee! 🕷️", duration: 1.5)
            return
        }

        petAction = .happy
        happinessLevel = min(1.0, happinessLevel + 0.15)
        showSpeechBubble(petType.soundText, duration: 1.6)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self = self, self.petAction == .happy else { return }
            self.petAction = .idle
        }
    }

    // MARK: - Speech Bubble Helper

    func showSpeechBubble(_ text: String, duration: TimeInterval) {
        speechBubbleResetWorkItem?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            speechBubbleText = text
        }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.speechBubbleText = nil
            }
        }
        speechBubbleResetWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }
}
