import SwiftUI

private let orbTeal = Color(red: 0.23, green: 0.84, blue: 0.75)

enum PetSubSection: String, CaseIterable, Identifiable {
    case companion = "Companion"
    case feeding = "Snack Bowl"
    case wardrobe = "Wardrobe"
    case behaviors = "Behaviors"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .companion: return "pawprint.fill"
        case .feeding: return "fork.knife"
        case .wardrobe: return "tshirt.fill"
        case .behaviors: return "sparkles"
        }
    }
}

struct PetSettingsTab: View {
    @ObservedObject var state = OrbState.shared
    @ObservedObject var petManager = PetManager.shared
    @State private var subSection: PetSubSection = .companion

    private let hatColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let outfitColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 14) {
            // Master Companion Toggle Card
            SettingsCard("Notch Companion", icon: "pawprint.fill") {
                VStack(spacing: 12) {
                    Toggle(isOn: $state.showNotchPet) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show Notch Pet Companion")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("An adorable animated friend that perches and plays beside your MacBook notch in the menu bar.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: orbTeal))

                    if state.showNotchPet {
                        Divider().background(Color.white.opacity(0.1))

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Pet Placement")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Beside notch · Zero workspace overlap")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.gray)
                            }

                            HStack(spacing: 8) {
                                ForEach(NotchPetPlacement.allCases) { place in
                                    let isSel = (petManager.placement == place)
                                    Button(action: {
                                        state.haptic()
                                        petManager.placement = place
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: place.icon)
                                                .font(.system(size: 10, weight: .semibold))
                                            Text(place.rawValue)
                                                .font(.system(size: 10.5, weight: isSel ? .bold : .medium))
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(isSel ? orbTeal.opacity(0.25) : Color.white.opacity(0.04))
                                        .foregroundColor(isSel ? .white : Color.white.opacity(0.6))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(isSel ? orbTeal : Color.clear, lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }

            if state.showNotchPet {
                // Compact Stage Preview
                liveStageHeader

                // Segmented Sub-Navigation (Organized & Compact, Never Overwhelming)
                HStack(spacing: 6) {
                    ForEach(PetSubSection.allCases) { section in
                        let isSelected = (subSection == section)
                        Button(action: {
                            state.haptic()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                subSection = section
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(section.rawValue)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(isSelected ? orbTeal.opacity(0.25) : Color.white.opacity(0.05))
                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? orbTeal : Color.clear, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Sub-Section Content
                switch subSection {
                case .companion:
                    companionPickerCard
                case .feeding:
                    animalSpecificFeedingCard
                case .wardrobe:
                    wardrobeStudioCard
                case .behaviors:
                    smartBehaviorsCard
                }
            }
        }
    }

    // MARK: - Compact Live Pet Stage

    private var liveStageHeader: some View {
        SettingsCard("Companion Stage", icon: "sparkles") {
            HStack(spacing: 16) {
                // Notch Ledge Simulator
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .frame(width: 95, height: 72)

                    // Simulated hardware notch bottom rim
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 70, height: 3)
                        .offset(y: -10)

                    // Pet Avatar sitting flush on rim
                    Button(action: {
                        petManager.petInteracted()
                    }) {
                        NotchPetView(petManager: petManager, accentColor: state.accentColor)
                    }
                    .buttonStyle(.plain)
                    .offset(y: 4)
                }

                // Companion Bio & Quick Actions
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(petManager.petType.emoji)
                            .font(.system(size: 16))
                        Text(petManager.petType.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text(petManager.petType.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    HStack(spacing: 8) {
                        Button(action: { petManager.petInteracted() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                Text("Pet \(petManager.petType.shortName)")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button(action: { petManager.recordKeyPress() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "keyboard.fill")
                                Text("Test Typing")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button(action: { petManager.triggerBreakReminder() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "cup.and.saucer.fill")
                                Text("Test Break")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundColor(orbTeal)
                    .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Companion Selector

    private var companionPickerCard: some View {
        SettingsCard("Select Companion", icon: "person.2.badge.gearshape.fill") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(NotchPetType.allCases) { companion in
                        let isSelected = (petManager.petType == companion)
                        Button(action: {
                            state.haptic()
                            petManager.petType = companion
                        }) {
                            VStack(spacing: 5) {
                                Text(companion.emoji)
                                    .font(.system(size: 22))

                                Text(companion.shortName)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? orbTeal.opacity(0.22) : Color.white.opacity(0.04))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? orbTeal : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Roaming Pace Selector
                HStack {
                    Text("Roaming Activity:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("Activity", selection: $petManager.petActivity) {
                        ForEach(NotchPetActivity.allCases) { act in
                            Text(act.title).tag(act)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .frame(width: 220)
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Animal-Specific Feeding Card (Cats eat Fish/Milk, Dogs eat Bones/Meat, etc.)

    private var animalSpecificFeedingCard: some View {
        SettingsCard("\(petManager.petType.shortName)'s Snack Bowl", icon: "fork.knife") {
            VStack(alignment: .leading, spacing: 12) {
                // Fullness & Happiness Progress
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Fullness")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(petManager.hungerLevel * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        ProgressView(value: petManager.hungerLevel)
                            .tint(Color.orange)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Happiness")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(petManager.happinessLevel * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        ProgressView(value: petManager.happinessLevel)
                            .tint(Color.pink)
                    }
                }

                Text("Feed \(petManager.petType.shortName) their favorite snack:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))

                // Shows ONLY this animal's authentic favorite treats!
                HStack(spacing: 10) {
                    ForEach(petManager.petType.availableTreats) { treat in
                        Button(action: {
                            petManager.feed(treat: treat)
                        }) {
                            VStack(spacing: 4) {
                                Text(treat.emoji)
                                    .font(.system(size: 24))
                                Text(treat.label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Wardrobe Studio

    private var wardrobeStudioCard: some View {
        SettingsCard("Wardrobe Boutique", icon: "tshirt.fill") {
            VStack(alignment: .leading, spacing: 14) {
                // Hats Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hats & Headwear")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)

                    LazyVGrid(columns: hatColumns, spacing: 6) {
                        ForEach(PetHat.allCases) { hat in
                            let isSelected = (petManager.petHat == hat)
                            Button(action: {
                                state.haptic()
                                petManager.petHat = hat
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: hat.icon)
                                        .font(.system(size: 10))
                                    Text(hat.rawValue)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                .background(isSelected ? orbTeal.opacity(0.25) : Color.white.opacity(0.04))
                                .cornerRadius(6)
                                .foregroundColor(isSelected ? .white : .gray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? orbTeal : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.06))

                // Outfits Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Outfits & Suits")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)

                    LazyVGrid(columns: outfitColumns, spacing: 6) {
                        ForEach(PetOutfit.allCases) { outfit in
                            let isSelected = (petManager.petOutfit == outfit)
                            Button(action: {
                                state.haptic()
                                petManager.petOutfit = outfit
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: outfit.icon)
                                        .font(.system(size: 10))
                                    Text(outfit.rawValue)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                .background(isSelected ? orbTeal.opacity(0.25) : Color.white.opacity(0.04))
                                .cornerRadius(6)
                                .foregroundColor(isSelected ? .white : .gray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? orbTeal : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Smart Behaviors Card

    private var smartBehaviorsCard: some View {
        SettingsCard("Interactive Behaviors", icon: "brain.head.profile") {
            VStack(alignment: .leading, spacing: 10) {
                toggleRow("🎧 Mini DJ Headphones",
                          detail: "Automatically puts on glowing headphones and bobs with the music waveform.",
                          isOn: $petManager.djHeadphonesEnabled)

                toggleRow("🎤 Apple Music Karaoke Singing",
                          detail: "Opens mouth to sing in sync with lyrics vocal phrases, rests during instrumental breaks.",
                          isOn: $petManager.singingEnabled)

                toggleRow("💃 Adaptive Dance Routines",
                          detail: "Performs lively bouncy jumps on fast upbeat songs and gentle swaying on acoustic tracks.",
                          isOn: $petManager.adaptiveDanceEnabled)

                toggleRow("⚡ MagSafe Charging Snack",
                          detail: "Holds a glowing battery snack or lightning bolt when plugged into power.",
                          isOn: $petManager.chargingSnackEnabled)

                toggleRow("💻 Rapid Typing Companion",
                          detail: "Pulls out a tiny laptop or cheers you on with pom-poms when you type fast.",
                          isOn: $petManager.typingCompanionEnabled)

                toggleRow("⏳ Break & Hydration Reminder",
                          detail: "Yawns, stretches, and prompts a quick water break every 45-60 min of continuous work.",
                          isOn: $petManager.breakReminderEnabled)

                toggleRow("🌦 Weather Reactions",
                          detail: "Automatically puts on yellow raincoat for rain, winter beanie for cold, or sunglasses when sunny.",
                          isOn: $petManager.weatherReactionsEnabled)

                if petManager.weatherReactionsEnabled {
                    Picker("Weather Condition", selection: $petManager.weatherMode) {
                        ForEach(PetWeatherMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .padding(.top, 2)
                }

                toggleRow("🚶 Roam Beside Notch",
                          detail: "Allows your pet to freely stroll beside the notch inside the menu bar.",
                          isOn: $petManager.roamingEnabled)
            }
        }
    }

    private func toggleRow(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: orbTeal))
    }
}
