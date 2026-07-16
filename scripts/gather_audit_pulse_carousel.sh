#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# gather_audit_pulse_carousel.sh — Open Lightly · Pulse + Card Carousel
# Version: 2026-04-11
#
# Run from: OpenLightly/
#   bash gather_audit_pulse_carousel.sh
# Output: llm_audit_pulse_carousel.md
#
# Scope: Everything visible in the home content stack:
#   [1] Card carousel (stacked prompt cards)
#   [2] Pulse widget (graph + sovereign space)
#   [3] Research ticker
#   + supporting cards, carousel, graph primitives
# ─────────────────────────────────────────────────────────────────────────────

OUTPUT_FILE="llm_audit_pulse_carousel.md"
SOURCE_ROOT="Open Lightly"
WARNINGS=()
FILES_FOUND=0

TARGET_FILES=(

  # ── Pulse Feature Views ──────────────────────────────────────────────────
  "$SOURCE_ROOT/Design/Components/Pulse/PulseCanvasScrollView.swift"
  "$SOURCE_ROOT/Design/Components/Pulse/PulseDotSummary.swift"
  "$SOURCE_ROOT/Design/Components/Pulse/PulseFullView.swift"
  "$SOURCE_ROOT/Design/Components/Pulse/PulseGraph.swift"
  "$SOURCE_ROOT/Design/Components/Pulse/PulseWidget.swift"
  "$SOURCE_ROOT/Design/Components/Pulse/CheckInShell.swift"
  "$SOURCE_ROOT/Design/Components/Pulse/DailyCheckInView.swift"

  # ── Global Card + Carousel Components ────────────────────────────────────
  # These likely back the stacked prompt card carousel at top of home
  "$SOURCE_ROOT/Design/Components/Cards/CardCarousel.swift"
  "$SOURCE_ROOT/Design/Components/Cards/CardBackView.swift"
  "$SOURCE_ROOT/Design/Components/Cards/AtmosphericGhostDeck.swift"

  # ── Home Components that appear in same scroll context ────────────────────
  "$SOURCE_ROOT/Features/Home/Components/PickUpCard.swift"
  "$SOURCE_ROOT/Features/Home/Components/ResearchTicker.swift"

  # ── Theme Tokens ──────────────────────────────────────────────────────────
  "$SOURCE_ROOT/App/Theme/AppColors.swift"
  "$SOURCE_ROOT/App/Theme/AppFonts.swift"

)

# ─────────────────────────────────────────────────────────────────────────────
# SCRIPT BODY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  gather_audit_pulse_carousel.sh — Open Lightly"
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
  echo "# LLM Audit Context — Open Lightly · Pulse + Card Carousel"
  echo ""
  echo "> **Scope: Everything in the home content stack below the greeting.**"
  echo ">"
  echo "> Visual layout (top → bottom):"
  echo ">   [1] Stacked prompt card carousel"
  echo ">       → CardCarousel / AtmosphericGhostDeck / CardBackView / PickUpCard"
  echo ">   [2] Pulse widget — graph, sovereign space label, check-in dot trail"
  echo ">       → PulseWidget / PulseGraph / PulseDotSummary"
  echo ">   [3] Research ticker strip"
  echo ">       → ResearchTicker"
  echo ">   [4] Full pulse / check-in flow (triggered from widget)"
  echo ">       → PulseCanvasScrollView / PulseFullView / CheckInShell / DailyCheckInView"
  echo ">"
  echo "> Intentionally excluded:"
  echo ">   - HomeDashboardView / HomeRouterView (separate audit)"
  echo ">   - Learn / Explore / Onboarding features"
  echo ">   - Services / Supabase layer"
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
    echo "> Likely path fixes:"
    echo "> - Pulse files may live under \`Features/Home/Pulse/\` or \`Features/Pulse/Views/\`"
    echo "> - Card files may live under \`Design/Components/Cards/\` or \`Features/Home/Components/\`"
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
  echo "  Quick check — run this to find actual locations:"
  echo "    find \"$SOURCE_ROOT\" -name \"PulseWidget.swift\" -o \\"
  echo "                        -name \"CardCarousel.swift\" -o \\"
  echo "                        -name \"AtmosphericGhostDeck.swift\""
  echo ""
fi
