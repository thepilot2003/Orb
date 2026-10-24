import SwiftUI
import AppKit
import Combine

@main
struct OrbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var orbState = OrbState.shared

    var body: some Scene {
        MenuBarExtra("Orb", systemImage: "capsule.tophalf.filled") {
            Label("Orb", systemImage: "capsule.tophalf.filled")

            Divider()

            Button("Settings...") {
                appDelegate.showSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Orb") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

// MARK: - Panel

final class OrbNotchPanel: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OrbHostingView<Content: View>: NSHostingView<Content> {
    // Lets the first click hit a button even though the panel never becomes key.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private(set) static var shared: AppDelegate?
    private(set) var notchPanel: OrbNotchPanel!
    private var settingsWindow: NSWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var visibilityTimer: Timer?
    private var collapseWork: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    // Big enough for the open island plus its shadow, small enough not to cover much of the menu bar.
    private let canvasSize = NSSize(width: 560, height: 360)

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        // No Dock icon by default until Settings is opened
        NSApp.setActivationPolicy(.accessory)
        setupAppIcon()

        let panel = OrbNotchPanel(
            contentRect: NSRect(origin: .zero, size: canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar + 2
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = true   // click-through until the cursor enters the notch

        let hostingView = OrbHostingView(rootView: OrbNotchView())
        hostingView.frame = NSRect(origin: .zero, size: canvasSize)
        hostingView.autoresizingMask = [.width, .height]
        if #available(macOS 13.0, *) { hostingView.sizingOptions = [] }
        panel.contentView = hostingView

        notchPanel = panel

        repositionOrb()
        panel.orderFrontRegardless()

        installMouseMonitors()
        observeSettings()

        NotificationCenter.default.addObserver(forName: Notification.Name("orbOpenSettings"), object: nil, queue: .main) { [weak self] _ in
            self?.showSettings()
        }
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name("orbOpenSettingsDistributed"), object: nil, queue: .main) { [weak self] _ in
            self?.showSettings()
        }

        // Re-measure the notch whenever the display setup changes.
        NotificationCenter.default.addObserver(self, selector: #selector(repositionOrb),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)

        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(evaluateVisibility),
                              name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(evaluateVisibility),
                              name: NSWorkspace.didActivateApplicationNotification, object: nil)
        workspace.addObserver(self, selector: #selector(repositionOrb),
                              name: NSWorkspace.screensDidWakeNotification, object: nil)

        // Low-frequency fallback timer (workspace observers do the instant work).
        visibilityTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            self?.evaluateVisibility()
        }
    }

    // MARK: Settings window (managed by AppKit so it reliably opens from the menu bar)

    private func setupAppIcon() {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = img
        } else if let img = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = img
        } else if let fallbackPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                  let img = NSImage(contentsOfFile: fallbackPath) {
            NSApp.applicationIconImage = img
        }
    }

    func showSettings() {
        // Switch to regular app so Orb appears in the Dock and Cmd+Tab switcher
        NSApp.setActivationPolicy(.regular)
        setupAppIcon()

        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: ContentView())
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.title = "Orb Settings"
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.isMovableByWindowBackground = false
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.backgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1)
            let fixedSize = NSSize(width: 680, height: 640)
            window.setContentSize(fixedSize)
            window.minSize = fixedSize
            window.maxSize = fixedSize
            window.contentMinSize = fixedSize
            window.contentMaxSize = fixedSize
            window.showsResizeIndicator = false
            if #available(macOS 13.0, *) {
                hosting.sizingOptions = []
            }
            window.center()
            settingsWindow = window
        }
        guard let window = settingsWindow else { return }

        // Temporarily raise to floating so it opens directly in front of any active app
        window.level = .floating
        window.center()
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        // Force app activation over any currently focused apps
        NSApp.activate(ignoringOtherApps: true)

        // Drop back to normal window level so it behaves as a standard window once visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            window.level = .normal
            window.makeKey()
        }
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window === settingsWindow {
            // Revert to menu bar accessory when settings is closed
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: Settings bindings

    private func observeSettings() {
        OrbState.shared.$hideFromScreenCapture
            .sink { [weak self] hide in
                self?.notchPanel?.sharingType = hide ? NSWindow.SharingType.none : NSWindow.SharingType.readOnly
            }
            .store(in: &cancellables)

        OrbState.shared.$hideInFullscreen
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.evaluateVisibility() }
            }
            .store(in: &cancellables)
    }

    // MARK: Positioning (always on the notched display, not just NSScreen.main)

    @objc func repositionOrb() {
        OrbState.shared.detectHardwareNotch()
        guard let screen = OrbState.targetScreen(), let panel = notchPanel else { return }
        let x = screen.frame.midX - canvasSize.width / 2
        let y = screen.frame.maxY - canvasSize.height
        panel.setFrame(NSRect(x: x, y: y, width: canvasSize.width, height: canvasSize.height), display: true)
    }

    // MARK: Hover + click handling
    // The panel ignores mouse events by default so it never blocks the menu bar or app
    // toolbars underneath. Mouse monitors turn events on only while the cursor is over the
    // island. Hovering plays a small "peek" animation; the island opens on click or on hover,
    // depending on the setting.

    private func installMouseMonitors() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .leftMouseDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            if event.type == .leftMouseDown {
                self?.handleClickOutside()
            } else {
                self?.updateHover()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self = self else { return event }
            if event.type == .leftMouseDown { return self.handleClick(event) }
            self.updateHover()
            return event
        }
    }

    private func isMouseInsideNotch() -> Bool {
        guard let panel = notchPanel else { return false }
        let mouse = NSEvent.mouseLocation
        let frame = panel.frame

        let state = OrbState.shared
        let margin: CGFloat = state.isExpanded ? 16 : 4
        let width = state.currentNotchWidth + 20 + margin * 2
        let height = state.currentNotchHeight + margin

        // Instant fast exit when cursor is not near the notch (saves CPU on 95% of movements)
        guard mouse.y >= frame.maxY - (height + 20) else { return false }

        let minX = frame.midX - width / 2
        let maxX = frame.midX + width / 2
        let minY = frame.maxY - height

        return mouse.x >= minX && mouse.x <= maxX && mouse.y >= minY && mouse.y <= frame.maxY + 1
    }

    private func isMouseOverPet() -> Bool {
        guard let panel = notchPanel, OrbState.shared.showNotchPet else { return false }
        let mouse = NSEvent.mouseLocation
        let frame = panel.frame
        let state = OrbState.shared
        let petManager = PetManager.shared

        let petCenterX = frame.midX + petManager.petPositionX
        let notchBottom = state.isExpanded ? state.expandedHeight : state.currentNotchHeight
        let petY = frame.maxY - notchBottom

        let petBox = NSRect(x: petCenterX - 24, y: petY - 44, width: 48, height: 46)
        return petBox.contains(mouse)
    }

    private func collapse() {
        collapseWork?.cancel()
        collapseWork = nil
        let state = OrbState.shared
        state.isExpanded = false
        state.isHovered = false
        notchPanel?.ignoresMouseEvents = true
    }

    private func updateHover() {
        guard let panel = notchPanel, panel.isVisible else { return }
        let state = OrbState.shared

        let overPet = isMouseOverPet()
        let insideNotch = isMouseInsideNotch()

        if overPet {
            // Enable mouse clicks on pet without expanding island
            panel.ignoresMouseEvents = false
        } else if insideNotch {
            collapseWork?.cancel()
            collapseWork = nil
            if !state.isHovered {
                state.isHovered = true
                if state.openTrigger == .click { state.haptic() }   // tiny tick for the peek
            }
            if state.openTrigger == .hover && !state.isExpanded {
                state.isExpanded = true
                state.haptic()
            }
            panel.ignoresMouseEvents = false
        } else if state.isHovered || state.isExpanded {
            // Short grace period so brushing the edge doesn't flicker, and never collapse mid-drag
            guard collapseWork == nil, NSEvent.pressedMouseButtons == 0 else { return }
            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.collapseWork = nil
                if !self.isMouseInsideNotch() && !self.isMouseOverPet() { self.collapse() }
            }
            collapseWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: work)
        } else {
            panel.ignoresMouseEvents = true
        }
    }

    /// Click on the island itself: opens it when it is closed.
    private func handleClick(_ event: NSEvent) -> NSEvent? {
        let state = OrbState.shared
        guard event.window === notchPanel else { return event }

        // If clicking directly on the pet, pet the pet instead of expanding the notch
        if isMouseOverPet() {
            PetManager.shared.petInteracted()
            return nil
        }

        if !state.isExpanded && isMouseInsideNotch() {
            collapseWork?.cancel()
            collapseWork = nil
            state.isHovered = true
            state.isExpanded = true
            state.haptic()
            return nil   // swallow, the click was only meant to open the island
        }
        return event
    }

    /// Click anywhere else closes an open island.
    private func handleClickOutside() {
        if OrbState.shared.isExpanded && !isMouseInsideNotch() { collapse() }
    }

    // MARK: Fullscreen hiding

    @objc func evaluateVisibility() {
        guard let panel = notchPanel, let screen = OrbState.targetScreen() else { return }
        let shouldHide = OrbState.shared.hideInFullscreen && Self.isFullscreenAppActive(on: screen)
        if shouldHide {
            if panel.isVisible {
                collapse()
                panel.orderOut(nil)
            }
        } else if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    /// A normal window can never cover the menu bar area, so a layer-0 window that exactly
    /// matches the display bounds means a fullscreen app (or game) is on screen.
    private static func isFullscreenAppActive(on screen: NSScreen) -> Bool {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return false
        }
        let displayBounds = CGDisplayBounds(CGDirectDisplayID(number.uint32Value))
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        for window in windows {
            guard (window[kCGWindowLayer as String] as? Int) == 0,
                  let boundsDict = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }

            if abs(bounds.origin.x - displayBounds.origin.x) < 1,
               abs(bounds.origin.y - displayBounds.origin.y) < 1,
               abs(bounds.width - displayBounds.width) < 1,
               abs(bounds.height - displayBounds.height) < 1 {
                return true
            }
        }
        return false
    }
}
