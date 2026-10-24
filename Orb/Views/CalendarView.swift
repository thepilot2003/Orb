import SwiftUI

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
                    state.openCalendar(at: selectedDate ?? now)
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
                        state.openCalendar(at: targetDate)
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
                            state.openCalendar(at: event.start)
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
