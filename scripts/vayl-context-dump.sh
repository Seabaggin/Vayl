#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# vayl-context-dump.sh — Vayl · LLM Context Gatherer
# Version: 2026-06-28
#
# Run from: Vayl/ (repo root)
#   bash vayl-context-dump.sh
# Output: vayl-context.md
#
# Covers:
#   — D4  Desire Reveal (reveal view, store, constellation, sheets)
#   — D4  Companion Card (model + store)
#   — T1  Home (router + store)
#   — M2  Monetization (entitlement, StoreKit, paywall)
#   — T3  Map (view + store + vault)
#   — S   Sessions (airlock)
#   — Core (app state, desire sync, desire map store, models, auth, profile)
#   — Settings
#   — Theme
#
# Files marked MISSING = wrong path or stub to create.
# ─────────────────────────────────────────────────────────────────────────────

OUTPUT_FILE="vayl-context.md"
SOURCE_ROOT="Vayl"
WARNINGS=()
FILES_FOUND=0

TARGET_FILES=(

  # ── D4 Desire Reveal ───────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Desire Map/Views/DesireRevealView.swift"
  "$SOURCE_ROOT/Features/Desire Map/Store/DesireRevealStore.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/Components/DesireConstellationView.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/Components/DesireMapListSheet.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/Components/DesireMatchDetail.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/Components/DesireStarView.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/Components/ConstellationField.swift"
  "$SOURCE_ROOT/Features/Desire Map/CeremonyVariant.swift"
  "$SOURCE_ROOT/Features/Desire Map/ConstellationLayout.swift"

  # ── D4 Companion Card ──────────────────────────────────────────────────────
  "$SOURCE_ROOT/Core/Models/CompanionCard.swift"
  "$SOURCE_ROOT/Features/Desire Map/Store/CompanionCardStore.swift"

  # ── D4 Desire Map Store + Models ──────────────────────────────────────────
  "$SOURCE_ROOT/Features/Desire Map/Store/DesireMapStore.swift"
  "$SOURCE_ROOT/Features/Desire Map/Views/DesireMapView.swift"
  "$SOURCE_ROOT/Core/Models/DesireMatch.swift"
  "$SOURCE_ROOT/Core/Models/DesireItem.swift"
  "$SOURCE_ROOT/Core/Models/DesireRating.swift"
  "$SOURCE_ROOT/Core/Models/Enums/AppDesireEnums.swift"

  # ── Core Services ──────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Core/Services/AppState.swift"
  "$SOURCE_ROOT/Core/Services/DesireSyncService.swift"
  "$SOURCE_ROOT/Core/Services/EntitlementService.swift"

  # ── M2 Monetization ────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Monetization/Store/EntitlementStore.swift"
  "$SOURCE_ROOT/Features/Monetization/Views/PaywallSheet.swift"
  "$SOURCE_ROOT/Core/Models/EntitlementRecord.swift"

  # ── T1 Home ────────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Home/Views/HomeRouterView.swift"
  "$SOURCE_ROOT/Features/Home/Store/HomeStore.swift"
  "$SOURCE_ROOT/Features/Home/Components/DesireMapIndicator.swift"
  "$SOURCE_ROOT/Features/Home/Views/MapChartedMoment.swift"

  # ── T3 Map ─────────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Map/MapView.swift"
  "$SOURCE_ROOT/Features/Map/MapStore.swift"
  "$SOURCE_ROOT/Features/Map/MeCardSheet.swift"
  "$SOURCE_ROOT/Features/Map/PrismView.swift"
  "$SOURCE_ROOT/Features/Map/Components/FlavorVisuals.swift"
  "$SOURCE_ROOT/Features/Map/Components/MapPrimitives.swift"
  "$SOURCE_ROOT/Features/Map/Components/MapPulseHero.swift"
  "$SOURCE_ROOT/Features/Map/Components/MapRecord.swift"
  "$SOURCE_ROOT/Features/Map/Components/MapUsLayer.swift"
  "$SOURCE_ROOT/Features/Map/Components/MeCardCompact.swift"

  # ── T3 Vault ───────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Map/Vault/VaultSheet.swift"
  "$SOURCE_ROOT/Features/Map/Vault/VaultStore.swift"
  "$SOURCE_ROOT/Features/Map/Vault/EventEntryEditor.swift"
  "$SOURCE_ROOT/Features/Map/Vault/Components/VaultDesireSection.swift"
  "$SOURCE_ROOT/Features/Map/Vault/Components/VaultAgreementsSection.swift"
  "$SOURCE_ROOT/Features/Map/Vault/Components/VaultLogSection.swift"
  "$SOURCE_ROOT/Features/Map/Vault/Components/DiscussionCardView.swift"

  # ── Sessions ───────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Sessions/AirlockView.swift"

  # ── Theme ──────────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/App/Theme/AppColors.swift"
  "$SOURCE_ROOT/App/Theme/AppFonts.swift"
  "$SOURCE_ROOT/App/Theme/AppSpacing.swift"
  "$SOURCE_ROOT/App/Theme/AppRadius.swift"
  "$SOURCE_ROOT/App/Theme/AppAnimation.swift"

  # ── Settings ───────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/Features/Settings/SettingsView.swift"

)

# ─────────────────────────────────────────────────────────────────────────────
# SCRIPT BODY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  vayl-context-dump.sh"
echo "  Source root : \"$SOURCE_ROOT/\""
echo "  Output      : $OUTPUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -d "$SOURCE_ROOT" ]; then
  echo "  ❌  ERROR: \"$SOURCE_ROOT/\" not found."
  echo "      Run from the Vayl repo root."
  echo ""; exit 1
fi

# ── Header ────────────────────────────────────────────────────────────────────
{
  echo "# Vayl — LLM Context Dump"
  echo ""
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo ">"
  echo "> **Active segment:** D4 — Desire Reveal (request affordance + bridge-card nav)"
  echo ">"
  echo "> **What this covers:**"
  echo ">   D4    — DesireRevealView, DesireRevealStore, constellation, sheets, companion card"
  echo ">   Core  — AppState, DesireSyncService, EntitlementService, models, enums"
  echo ">   M2    — EntitlementStore, EntitlementRecord, PaywallSheet"
  echo ">   T1    — HomeRouterView, HomeStore"
  echo ">   T3    — MapView, MapStore, MeCardSheet, all Map components + Vault"
  echo ">   S     — AirlockView"
  echo ">   Theme — AppColors, AppFonts, AppSpacing, AppRadius, AppAnimation"
  echo ">   Settings — SettingsView"
  echo ">"
  echo "> Files marked MISSING = wrong path or stub to create."
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
    echo "## ⚠️ Files Not Found — Fix Path or Create Stub"
    echo ""
    echo "> The following files were listed but not found on disk."
    echo "> Either the path is wrong or the file needs to be created."
    echo ""
    for W in "${WARNINGS[@]}"; do echo "- \`$W\`"; done
    echo ""
    echo "---"
    echo ""
  } >> "$OUTPUT_FILE"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
BYTE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done."
echo "  Found   : $FILES_FOUND / ${#TARGET_FILES[@]} files"
echo "  Missing : ${#WARNINGS[@]} (wrong path or stub to create)"
echo "  Output  : $OUTPUT_FILE (${BYTE_SIZE} bytes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "  ⚠️  Missing files — fix paths or create stubs:"
  for W in "${WARNINGS[@]}"; do echo "     → $W"; done
  echo ""
fi
