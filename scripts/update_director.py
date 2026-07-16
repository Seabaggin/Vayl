import re

with open("Vayl/Features/Onboarding/Canvas/VaylDirector.swift", "r") as f:
    content = f.read()

# 1. Add properties for projector, curiosity, and ceremony
properties_to_add = """
    @ObservationIgnored lazy var projector = DealerProjector()
    @ObservationIgnored lazy var curiosity = CuriositySequencer(stage: self)
    @ObservationIgnored lazy var ceremony = BuildDeckCeremony()
"""
content = re.sub(r'(@ObservationIgnored lazy var gender = GenderSequencer\(stage: self\))', r'\1\n' + properties_to_add, content)

# 2. Remove Curiosity Phase State
curiosity_state_pattern = r'    // MARK: - Curiosity Phase.*?(?=    var foilIntegrity)'
content = re.sub(curiosity_state_pattern, '', content, flags=re.DOTALL)

# 3. Remove BuildDeck Foil State
foil_state_pattern = r'    var foilIntegrity: Double     = 1\.0\n    var foilTears:     \[FoilTear\] = \[\]\n'
content = re.sub(foil_state_pattern, '', content)

# 4. Remove Projected Text State
projected_text_state_pattern = r'    var projectedText:        String\? = nil\n    var projectedTextVisible: Bool    = false\n    /// Vertical anchor for the projected dealer line .*?\n    var projectedTextAnchorYFrac: CGFloat = AppLayout\.tableHorizonYFrac\n'
content = re.sub(projected_text_state_pattern, '', content, flags=re.DOTALL)

# 5. Remove Dealer Line Attempt State
dealer_line_attempt_pattern = r'    private var dealerLineAttempt: Int = 0\n'
content = re.sub(dealer_line_attempt_pattern, '', content)

# 6. Update advance(to:) to use projector.hideDealerLine()
content = content.replace("hideDealerLine()", "projector.hideDealerLine()")
content = content.replace("dealerLineAttempt += 1", "")

# 7. Update runCuriosityEntry
content = content.replace("runCuriosityEntry()", "curiosity.runEntry()")

# 8. Update runBuildDeckEntry
content = content.replace("runBuildDeckEntry()", "ceremony.runEntry()")

# 9. Update showContextHeadline()
context_headline_pattern = r'    @discardableResult\n    func showContextHeadline\(\) -> String \{\n.*?showDealerLineManual\(copy\)\n        return copy\n    \}'
new_context_headline = """    @discardableResult
    func showContextHeadline() -> String {
        let copy = DealerDictionary.contextHeadline(appMode: onboardingData.appMode)
        projector.showDealerLineManual(copy)
        return copy
    }"""
content = re.sub(context_headline_pattern, new_context_headline, content, flags=re.DOTALL)

# 10. Update showExpLevelExitLine()
exp_level_exit_pattern = r'    @discardableResult\n    func showExpLevelExitLine\(_ intensity: CandleIntensity\) -> String \{\n.*?showDealerLineManual\(copy\)\n        return copy\n    \}'
new_exp_level_exit = """    @discardableResult
    func showExpLevelExitLine(_ intensity: CandleIntensity) -> String {
        let copy = DealerDictionary.experienceLevelExitLine(intensity: intensity)
        projector.showDealerLineManual(copy)
        return copy
    }"""
content = re.sub(exp_level_exit_pattern, new_exp_level_exit, content, flags=re.DOTALL)

# 11. Update concludeContext
content = content.replace("let reply = contextResponse(for: situationalRegister)", "let reply = DealerDictionary.contextResponse(for: situationalRegister)")
content = content.replace("showDealerLineManual(reply)", "projector.showDealerLineManual(reply)")

# 12. Remove contextResponse function entirely
content = re.sub(r'    private func contextResponse.*?\}\n    \}', '', content, flags=re.DOTALL)

# 13. Remove curiosity methods
curiosity_methods_pattern = r'    private func runCuriosityEntry.*?(?=    private func runConfirmationEntry)'
content = re.sub(curiosity_methods_pattern, '', content, flags=re.DOTALL)

# 14. Update runBuildDeckEntry
build_deck_entry_pattern = r'    private func runBuildDeckEntry.*?(?=    func recedeTableForForge)'
new_build_deck_entry = """    private func runBuildDeckEntry() {
        tableFade = 1.0
        ceremony.runEntry()
    }
    
"""
content = re.sub(build_deck_entry_pattern, new_build_deck_entry, content, flags=re.DOTALL)

# 15. Remove dealer line projection functions
projector_methods_pattern = r'    func showDealerLine\(.*?hideDealerLine\(\) \{\n        withAnimation\(AppAnimation.textProject.reduceMotionSafe\) \{ projectedTextVisible = false \}\n    \}'
content = re.sub(projector_methods_pattern, '', content, flags=re.DOTALL)

# 16. Remove foil tearing methods and sequences
foil_tearing_methods_pattern = r'    /// Authored strike SEQUENCES.*?beginFoilDissolve\(\) \{.*?\n    \}'
content = re.sub(foil_tearing_methods_pattern, '', content, flags=re.DOTALL)

with open("Vayl/Features/Onboarding/Canvas/VaylDirector.swift", "w") as f:
    f.write(content)

