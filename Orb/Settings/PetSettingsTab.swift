import SwiftUI

private let orbTeal = Color(red: 0.23, green: 0.84, blue: 0.75)

struct PetSettingsTab: View {
    @ObservedObject var state = OrbState.shared
    @ObservedObject var petManager = PetManager.shared

    private let hatColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private let outfitColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 16) {
            // Master Companion Toggle Card
            SettingsCard("Notch Companion", icon: "pawprint.fill") {
                Toggle(isOn: $state.showNotchPet) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Show Notch Pet Companion")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("An adorable animated friend that lives, perches, and plays along your MacBook notch.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: orbTeal))
            }

            if state.showNotchPet {
                // Live Pet Preview & Stage
                liveStageCard

                // Companion Picker Card
                companionPickerCard

                // Interactive Feeding Station Card
                feedingStationCard

                // Wardrobe Studio (Hats & Outfits)
                wardrobeStudioCard

                // Smart Notch Interactive Behaviors
                smartBehaviorsCard
            }
        }
    }

    // MARK: - Live Pet Stage & Interaction Preview

    private var liveStageCard: some View {
        SettingsCard("Live Companion Stage", icon: "sparkles") {
            HStack(spacing: 18) {
                // Interactive Pet Stage
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 110, height: 80)

                    // Notch ledge simulation bar
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 80, height: 4)
                        .offset(y: -14)

                    // Pet Avatar
                    Button(action: {
                        petManager.petInteracted()
                    }) {
                        NotchPetView(petManager: petManager, accentColor: state.accentColor)
                    }
                    .buttonStyle(.plain)
                    .offset(y: 4)
                }

                // Companion Bio & Stats
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(petManager.petType.emoji)
                            .font(.system(size: 18))
                        Text(petManager.petType.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text(petManager.petType.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    HStack(spacing: 8) {
                        Button(action: { petManager.petInteracted() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                Text("Pet Me")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
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
                        }
                        .buttonStyle(.plain)

                        Button(action: { petManager.triggerBreakReminder() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "cup.and.saucer.fill")
                                Text("Break Reminder")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundColor(orbTeal)
                }
            }
        }
    }

    // MARK: - Companion Selector

    private var companionPickerCard: some View {
        SettingsCard("Choose Your Companion", icon: "person.2.badge.gearshape.fill") {
            HStack(spacing: 8) {
                ForEach(NotchPetType.allCases) { companion in
                    let isSelected = (petManager.petType == companion)
                    Button(action: {
                        state.haptic()
                        petManager.petType = companion
                    }) {
                        VStack(spacing: 6) {
                            Text(companion.emoji)
                                .font(.system(size: 22))

                            Text(companion.title)
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
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Feeding Station

    private var feedingStationCard: some View {
        SettingsCard("Feeding Station & Treats", icon: "fork.knife") {
            VStack(alignment: .leading, spacing: 12) {
                // Meters: Hunger & Happiness
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

                Text("Feed a treat to your pet:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))

                // Treat Buttons
                HStack(spacing: 8) {
                    ForEach(PetTreat.allCases) { treat in
                        let isFav = (petManager.petType.favoriteTreat == treat)
                        Button(action: {
                            petManager.feed(treat: treat)
                        }) {
                            VStack(spacing: 3) {
                                Text(treat.emoji)
                                    .font(.system(size: 20))
                                Text(treat.rawValue)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(isFav ? Color(hex: "#FFD60A") : .white)
                                if isFav {
                                    Text("Fav ❤️")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(Color(hex: "#FFD60A"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isFav ? Color(hex: "#FFD60A").opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Wardrobe Boutique (Hats & Outfits)

    private var wardrobeStudioCard: some View {
        SettingsCard("Wardrobe Studio", icon: "tshirt.fill") {
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
                                        .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                                        .lineLimit(1)
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
                                        .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                                        .lineLimit(1)
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
        SettingsCard("Smart Companion Behaviors", icon: "brain.head.profile") {
            VStack(alignment: .leading, spacing: 12) {
                // 1. DJ Headphones
                toggleRow("🎧 Mini DJ Headphones",
                          detail: "Automatically puts on glowing headphones and bobs with the music waveform.",
                          isOn: $petManager.djHeadphonesEnabled)

                // 2. Singing Lip-Sync
                toggleRow("🎤 Apple Music Karaoke Singing",
                          detail: "Opens mouth to sing in sync with lyrics vocal phrases, rests during instrumental breaks.",
                          isOn: $petManager.singingEnabled)

                // 3. Adaptive Dance Routines
                toggleRow("💃 Adaptive Dance Routines",
                          detail: "Performs lively bouncy jumps on fast upbeat songs and gentle swaying on acoustic tracks.",
                          isOn: $petManager.adaptiveDanceEnabled)

                // 4. MagSafe Battery Snack
                toggleRow("⚡ MagSafe Charging Snack",
                          detail: "Holds a glowing battery snack or lightning bolt when plugged into power.",
                          isOn: $petManager.chargingSnackEnabled)

                // 5. Typing Work Companion
                toggleRow("💻 Rapid Typing Companion",
                          detail: "Pulls out a tiny laptop or cheers you on with pom-poms when you type fast.",
                          isOn: $petManager.typingCompanionEnabled)

                // 6. Pomodoro Break Reminder
                toggleRow("⏳ Break & Hydration Reminder",
                          detail: "Yawns, stretches, and prompts a quick water break every 45-60 min of continuous work.",
                          isOn: $petManager.breakReminderEnabled)

                // 7. Weather Reactions
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
                    .padding(.top, 4)
                }

                // 8. Notch Roaming
                toggleRow("🚶 Roam Notch Ledge",
                          detail: "Allows your pet to freely walk along the bottom ledge of the notch.",
                          isOn: $petManager.roamingEnabled)

                // Activity Level
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Pace")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)

                    Picker("Activity", selection: $petManager.petActivity) {
                        ForEach(NotchPetActivity.allCases) { act in
                            Text(act.title).tag(act)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.top, 4)
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
