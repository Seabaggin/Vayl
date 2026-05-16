#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# gather_audit_home.sh — Open Lightly · Home Screen Audit
# Version: 2026-04-11
#
# Run from: OpenLightly/
#   bash gather_audit_home.sh
# Output: llm_audit_home.md
#
# Scope philosophy:
#   ✅ Core home views, router, state
#   ✅ Home-specific components (cards, chips, banners)
#   ✅ Theme tokens (colors + fonts only — no AppTheme/Modifiers to save space)
#   ✅ ContentView (home is gated behind it)
#   ✅ AppState (drives home routing logic)
#   ❌ Pulse, Learn, Explore, Onboarding — separate audits
#   ❌ Full design system components (Buttons, Cards, etc.) — too broad
#   ❌ Services — not directly home UI
# ─────────────────────────────────────────────────────────────────────────────

OUTPUT_FILE="llm_audit_home.md"
SOURCE_ROOT="Open Lightly"
WARNINGS=()
FILES_FOUND=0

TARGET_FILES=(

  # ── App Shell (home lives inside these) ──────────────────────────────────
  "$SOURCE_ROOT/App/ContentView.swift"
  "$SOURCE_ROOT/Core/Services/AppState.swift"

  # ── Home: Routing & State ─────────────────────────────────────────────────
  # HomeRouterView decides what the home tab renders
  # HomeStates holds the enums/structs that drive conditional rendering
  # HomeDashboardView is the top-level composition view
  "$SOURCE_ROOT/Features/Home/HomeRouterView.swift"
  "$SOURCE_ROOT/Features/Home/HomeStates.swift"
  "$SOURCE_ROOT/Features/Home/HomeDashboardView.swift"

  # ── Home: Components ──────────────────────────────────────────────────────
  # Only home-specific components — not the global design system
  "$SOURCE_ROOT/Features/Home/Components/PickUpCard.swift"
  "$SOURCE_ROOT/Features/Home/Components/ReflectionCard.swift"
  "$SOURCE_ROOT/Features/Home/Components/ReflectionBannerView.swift"
  "$SOURCE_ROOT/Features/Home/Components/PartnerChip.swift"
  "$SOURCE_ROOT/Features/Home/Components/DesireMapIndicator.swift"
  "$SOURCE_ROOT/Features/Home/Components/ResearchTicker.swift"
  "$SOURCE_ROOT/Features/Home/Components/PostMapReflectionView.swift"

  # ── Navigation Shell (tab bar & wrapper used by home) ─────────────────────
  # RacetrackTabBar renders the tab the home view sits in
  # TabContentWrapper wraps each tab's content
  "$SOURCE_ROOT/Design/Components/Navigation/RacetrackTabBar.swift"
  "$SOURCE_ROOT/Design/Components/Navigation/TabContentWrapper.swift"

  # ── Design Tokens (light touch — just what home renders against) ──────────
  # Omitting AppTheme, ThemeManager, ThemeModifiers — too much boilerplate
  "$SOURCE_ROOT/App/Theme/AppColors.swift"
  "$SOURCE_ROOT/App/Theme/AppFonts.swift"

)

# ─────────────────────────────────────────────────────────────────────────────
# SCRIPT BODY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  gather_audit_home.sh — Open Lightly"
echo "  Source root : \"$SOURCE_ROOT/\""
echo "  Output      : $OUTPUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -d "$SOURCE_ROOT" ]; then
  echo "  ❌  ERROR: \"$SOURCE_ROOT/\" not found."
  echo "      Run from the OpenLightly/ root."
  echo ""; exit 1
fi

{
  echo "# LLM Audit Context — Open Lightly · Home Screen"
  echo ""
  echo "> **Scope: Home tab — routing, state, dashboard, home-specific components, nav shell, theme tokens.**"
  echo ">"
  echo "> What's intentionally excluded to keep context tight:"
  echo ">   - Pulse / Learn / Explore / Onboarding features"
  echo ">   - Global design system (Buttons, Cards, Banners)"
  echo ">   - Services, Auth, Supabase layer"
  echo ">   - AppTheme / ThemeManager / ThemeModifiers"
  echo ">"
  echo "> File map:"
  echo ">   ContentView        — auth gate, injects AppState + theme"
  echo ">   AppState           — experience-type routing (solo/coupled/NM)"
  echo ">   HomeRouterView     — decides which home variant to render"
  echo ">   HomeStates         — enums + structs driving conditional UI"
  echo ">   HomeDashboardView  — top-level home composition"
  echo ">   Home Components    — PickUpCard, ReflectionCard, Banner, Chip, etc."
  echo ">   Nav Shell          — RacetrackTabBar, TabContentWrapper"
  echo ">   Theme Tokens       — AppColors, AppFonts"
  echo ">"
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo ""
  echo "---"
  echo ""
  echo "## Table of Contents"
  echo ""
} > "$OUTPUT_FILE"

TOC_INDEX=1
for FILE_PATH in "${TARGET_FILES[@]}"; do
  if [ -f "$FILE_PATH" ]; then
    ANCHOR=$(echo "$FILE_PATH" \
      | tr '[:upper:]' '[:lower:]' \
      | sed 's|[^a-z0-9]|-|g' \
      | sed 's|-\{2,\}|-|g' \
      | sed 's|^-||; s|-$||')
    printf "  %d. [\`%s\`](#file-%s)\n" \
      "$TOC_INDEX" "$FILE_PATH" "$ANCHOR" >> "$OUTPUT_FILE"
    ((TOC_INDEX++))
  fi
done

{ echo ""; echo "---"; echo ""; } >> "$OUTPUT_FILE"

for FILE_PATH in "${TARGET_FILES[@]}"; do
  if [ -f "$FILE_PATH" ]; then
    ANCHOR=$(echo "$FILE_PATH" \
      | tr '[:upper:]' '[:lower:]' \
      | sed 's|[^a-z0-9]|-|g' \
      | sed 's|-\{2,\}|-|g' \
      | sed 's|^-||; s|-$||')
    EXTENSION="${FILE_PATH##*.}"
    case "$EXTENSION" in
      swift) LANG="swift"    ;;
      metal) LANG="metal"    ;;
      json)  LANG="json"     ;;
      md)    LANG="markdown" ;;
      sh)    LANG="bash"     ;;
      *)     LANG=""         ;;
    esac
    {
      echo "## File: \`${FILE_PATH}\` {#file-${ANCHOR}}"
      echo ""
      echo "\`\`\`${LANG}"
      cat "$FILE_PATH"
      echo ""
      echo "\`\`\`"
      echo ""
      echo "---"
      echo ""
    } >> "$OUTPUT_FILE"
    echo "  ✅  $FILE_PATH"
    ((FILES_FOUND++))
  else
    WARNINGS+=("$FILE_PATH")
    echo "  ⚠️   MISSING → $FILE_PATH"
  fi
done

if [ ${#WARNINGS[@]} -gt 0 ]; then
  {
    echo "## ⚠️ Files Listed But Not Found"
    echo ""
    for W in "${WARNINGS[@]}"; do echo "- \`$W\`"; done
    echo ""
    echo "> Check paths — folder may be \`Views/\` not \`Models/\` for Dashboard/Router."
    echo ""
  } >> "$OUTPUT_FILE"
fi

BYTE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done. $FILES_FOUND / ${#TARGET_FILES[@]} files · ${BYTE_SIZE} bytes"
echo "  Warnings : ${#WARNINGS[@]} missing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "  ⚠️  Fix paths before uploading:"
  for W in "${WARNINGS[@]}"; do echo "     → $W"; done
  echo ""
  echo "  Hint: HomeDashboardView/HomeRouterView may live under"
  echo "        Features/Home/Views/ rather than Features/Home/Models/"
  echo "        Adjust TARGET_FILES above if needed."
  echo ""
fi
