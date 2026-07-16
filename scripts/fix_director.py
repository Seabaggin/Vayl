import re

with open("Vayl/Features/Onboarding/Canvas/VaylDirector.swift", "r") as f:
    content = f.read()

# Remove curiosity methods starting with `private func curiosity.runEntry()`
curiosity_pattern = r'    private func curiosity\.runEntry\(\) \{.*?(?=    private func runConfirmationEntry\(\) \{)'
content = re.sub(curiosity_pattern, '', content, flags=re.DOTALL)

# Remove build deck entry methods starting with `private func ceremony.runEntry()`
build_deck_pattern = r'    private func ceremony\.runEntry\(\) \{.*?(?=    func recedeTableForForge\(\) \{)'
new_build_deck = """    private func ceremony.runEntry() {
        tableFade = 1.0
        ceremony.runEntry()
    }

"""
content = re.sub(build_deck_pattern, new_build_deck, content, flags=re.DOTALL)

with open("Vayl/Features/Onboarding/Canvas/VaylDirector.swift", "w") as f:
    f.write(content)
