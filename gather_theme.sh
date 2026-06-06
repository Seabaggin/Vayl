#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# gather_theme.sh — Vayl · Theme Files
# Version: 2026-05-09
#
# Run from: ~/Documents/School/Code/Vayl/
#   bash gather_theme.sh
# Output: theme_files.md
#
# Scope: All theme tokens and primitives
#   [1] Color, Font, Spacing, Layout, Glows tokens
#   [2] Theme manager + modifiers
#   [3] Root view + Vayl primitives
# ─────────────────────────────────────────────────────────────────────────────

OUTPUT_FILE="theme_files.md"
SOURCE_ROOT="Vayl"
WARNINGS=()
FILES_FOUND=0

TARGET_FILES=(

  # ── Theme Tokens ──────────────────────────────────────────────────────────
  "$SOURCE_ROOT/App/Theme/AppAnimation.swift"
  "$SOURCE_ROOT/App/Theme/AppColors.swift"
  "$SOURCE_ROOT/App/Theme/AppElevation.swift"
  "$SOURCE_ROOT/App/Theme/AppFonts.swift"
  "$SOURCE_ROOT/App/Theme/AppGlows.swift"
  "$SOURCE_ROOT/App/Theme/AppGrid.swift"
  "$SOURCE_ROOT/App/Theme/AppLayout.swift"
  "$SOURCE_ROOT/App/Theme/AppRadius.swift"
  "$SOURCE_ROOT/App/Theme/AppRootView.swift"
  "$SOURCE_ROOT/App/Theme/AppSafeArea.swift"
  "$SOURCE_ROOT/App/Theme/AppSpacing.swift"
  "$SOURCE_ROOT/App/Theme/AppTheme.swift"

  # ── Theme Manager + Modifiers ─────────────────────────────────────────────
  "$SOURCE_ROOT/App/Theme/ThemeManager.swift"
  "$SOURCE_ROOT/App/Theme/ThemeModifiers.swift"

  # ── Primitives ────────────────────────────────────────────────────────────
  "$SOURCE_ROOT/App/Theme/VaylPrimitives.swift"

)

# ─────────────────────────────────────────────────────────────────────────────
# SCRIPT BODY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  gather_theme.sh — Vayl"
echo "  Source root : \"$SOURCE_ROOT/\""
echo "  Output      : $OUTPUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -d "$SOURCE_ROOT" ]; then
  echo "  ❌  ERROR: \"$SOURCE_ROOT/\" not found."
  echo "      Run from the Vayl/ root."
  echo ""; exit 1
fi

{
  echo "# LLM Audit Context — Vayl · Theme Files"
  echo ""
  echo "> **Scope: All theme tokens, primitives, and modifiers.**"
  echo ">"
  echo "> Contents:"
  echo ">   [1] Color, Font, Spacing, Layout, Grid, Radius, Elevation, SafeArea, Glows tokens"
  echo ">       → AppColors / AppFonts / AppSpacing / AppLayout / AppGrid / AppRadius / AppElevation / AppSafeArea / AppGlows"
  echo ">   [2] Animation + Theme entry point"
  echo ">       → AppAnimation / AppTheme"
  echo ">   [3] Theme manager + view modifiers"
  echo ">       → ThemeManager / ThemeModifiers"
  echo ">   [4] Root view + Vayl design primitives"
  echo ">       → AppRootView / VaylPrimitives"
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
    echo "> Quick check — run this to find actual locations:"
    echo "> find \"$SOURCE_ROOT\" -name \"AppColors.swift\""
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
  echo "    find \"$SOURCE_ROOT\" -name \"AppGlows.swift\" -o \\"
  echo "                        -name \"AppRootView.swift\""
  echo ""
fi
