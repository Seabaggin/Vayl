#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# gather_checkin_context.sh — Open Lightly · Daily Check-In Feature
# Version: 2026-04-06
#
# Run from: OpenLightly/
#   bash gather_checkin_context.sh
# Output: llm_checkin_context.md
#
# Covers:
#   — Existing design system + effects (reusable)
#   — Existing home layer (carousel, dashboard, states)
#   — Existing home components (RelationalWeather if present)
#   — Models layer
#   — New stub files to be created for the check-in feature
#   — React prototype pasted inline as port reference
# ─────────────────────────────────────────────────────────────────────────────

OUTPUT_FILE="llm_checkin_context.md"
SOURCE_ROOT="Open Lightly"
WARNINGS=()
FILES_FOUND=0

TARGET_FILES=(

  # ── Design System ─────────────────────────────────────────────────────────
  "$SOURCE_ROOT/App/Theme/AppColors.swift"
  "$SOURCE_ROOT/App/Theme/AppFonts.swift"

  # ── Design Components — Effects (reusable in check-in) ───────────────────
  "$SOURCE_ROOT/Design/Components/CardLayout.swift"
  "$SOURCE_ROOT/Design/Components/Effects/AuroraGlowField.swift"
  "$SOURCE_ROOT/Design/Components/Effects/GlowOrb.swift"
  "$SOURCE_ROOT/Design/Components/Effects/HolographicShimmer.swift"
  "$SOURCE_ROOT/Design/Components/Effects/OnboardingAtmosphere.swift"

  # ── Design Components — Buttons ───────────────────────────────────────────
  "$SOURCE_ROOT/Design/Components/Buttons/SelectablePill.swift"

  # ── Home Layer — Shell ────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Home/HomeDashboardView.swift"
  "$SOURCE_ROOT/Features/Home/HomeStates.swift"
  "$SOURCE_ROOT/Features/Home/HomeRouterView.swift"

  # ── Home Layer — Components ───────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Home/Components/HomeCardCarousel.swift"
  "$SOURCE_ROOT/Features/Home/Components/DesireMapIndicator.swift"
  "$SOURCE_ROOT/Features/Home/Components/ReflectionCard.swift"
  "$SOURCE_ROOT/Features/Home/Components/ResearchTicker.swift"
  "$SOURCE_ROOT/Features/Home/Components/PartnerChip.swift"
  "$SOURCE_ROOT/Features/Home/Components/PickUpCard.swift"
  "$SOURCE_ROOT/Features/Home/Components/ReflectionBannerView.swift"

  # ── Models ────────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Models/Prompt.swift"

  # ── NEW: Check-In Feature (stubs — to be created) ─────────────────────────
  # These files do not exist yet. They will appear in the MISSING warnings
  # section below, which tells the new chat exactly what needs to be built.
  "$SOURCE_ROOT/Features/Home/CheckIn/CheckInPhase.swift"
  "$SOURCE_ROOT/Features/Home/CheckIn/DailyCheckInView.swift"
  "$SOURCE_ROOT/Features/Home/CheckIn/CheckInQuestionView.swift"
  "$SOURCE_ROOT/Features/Home/CheckIn/CheckInResolutionView.swift"
  "$SOURCE_ROOT/Features/Home/Components/RelationalWeather.swift"
  "$SOURCE_ROOT/Models/RelationalWeatherEntry.swift"
  "$SOURCE_ROOT/Models/CheckInEntry.swift"

)

# ─────────────────────────────────────────────────────────────────────────────
# SCRIPT BODY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  gather_checkin_context.sh — Open Lightly"
echo "  Source root : \"$SOURCE_ROOT/\""
echo "  Output      : $OUTPUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -d "$SOURCE_ROOT" ]; then
  echo "  ❌  ERROR: \"$SOURCE_ROOT/\" not found."
  echo "      Run from the OpenLightly/ root."
  echo ""; exit 1
fi

# ── Header ────────────────────────────────────────────────────────────────────
{
  echo "# LLM Context — Open Lightly · Daily Check-In Feature"
  echo ""
  echo "> **Scope: Existing reusable design system + home layer + new check-in files to build.**"
  echo ">"
  echo "> Feature being built:"
  echo ">   RelationalWeather   — 14-day capacity barometer chart (home dashboard widget)"
  echo ">   DailyCheckInView    — 5-question check-in sequence (cinematic resolution)"
  echo ">   CheckInPhase        — phase machine: idle | questions | resolving | done"
  echo ">   CheckInEntry        — model: date, capacityScore, glowColor, speed"
  echo ">   RelationalWeatherEntry — model: per-day score for the timeline graph"
  echo ">"
  echo "> React prototype (port reference) is appended at the end of this file."
  echo "> All dy math, tier thresholds, and camera step geometry come from there."
  echo ">"
  echo "> Files marked MISSING in warnings = new files that need to be created."
  echo ">"
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo ""
  echo "---"
  echo ""
  echo "## Table of Contents"
  echo ""
} > "$OUTPUT_FILE"

# ── TOC ───────────────────────────────────────────────────────────────────────
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

{
  echo ""
  echo "---"
  echo ""
} >> "$OUTPUT_FILE"

# ── File blocks ───────────────────────────────────────────────────────────────
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

# ── Missing files section ─────────────────────────────────────────────────────
if [ ${#WARNINGS[@]} -gt 0 ]; then
  {
    echo "## ⚠️ Files Listed But Not Found — These Need To Be Created"
    echo ""
    echo "> The following files do not exist yet."
    echo "> They represent the exact new files the check-in feature requires."
    echo "> Use the React prototype below as the port specification."
    echo ""
    for W in "${WARNINGS[@]}"; do echo "- \`$W\`"; done
    echo ""
    echo "---"
    echo ""
  } >> "$OUTPUT_FILE"
fi

# ── React prototype appended inline as port reference ─────────────────────────
{
  echo "## React Prototype — Port Reference"
  echo ""
  echo "> This is the working React/JS implementation."
  echo "> All tier thresholds, dy math, camera step geometry, and"
  echo "> cinematic timing values should be ported 1:1 to SwiftUI."
  echo ">"
  echo "> Key translation map:"
  echo ">   useState(dotY)          → @State var dotY: Double"
  echo ">   useState(glowColor)     → @State var glowColor: Color"
  echo ">   useState(camScale/Tx/Ty)→ @State var camScale/camTx/camTy: CGFloat"
  echo ">   CSS transform: translateY → .offset(y:).animation(.spring(response:0.5))"
  echo ">   CSS transform: scale      → .scaleEffect().animation(.easeInOut(duration:))"
  echo ">   stroke-dashoffset 0→len  → Path.trim(from:0, to: progress).animation()"
  echo ">   setTimeout(fn, ms)       → DispatchQueue.main.asyncAfter(deadline: .now() + s)"
  echo ""
  echo "\`\`\`jsx"
  echo "// PASTE FULL REACT ARTIFACT SOURCE HERE"
  echo "// (copy from the artifact window before running this script)"
  echo "\`\`\`"
  echo ""
  echo "---"
  echo ""
} >> "$OUTPUT_FILE"

# ── Summary ───────────────────────────────────────────────────────────────────
BYTE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done. $FILES_FOUND / ${#TARGET_FILES[@]} files · ${BYTE_SIZE} bytes"
echo "  Warnings : ${#WARNINGS[@]} missing (= new files to build)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "  ⚠️  New files to create in the new chat:"
  for W in "${WARNINGS[@]}"; do echo "     → $W"; done
  echo ""
fi

