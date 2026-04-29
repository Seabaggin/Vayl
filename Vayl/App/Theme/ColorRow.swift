//
//  ColorRow.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/20/26.
//


// TokenAudit.swift
// Drop this file in the project, run the Preview.
// Every color swatch and font label must render.
// Delete this file before shipping.

import SwiftUI

// ── Color audit ───────────────────────────────────────────────────────────
// Each row: swatch | hex label | opacity label
// Fail condition: swatch is black (hex init failed) or view crashes

private struct ColorRow: View {
    let name:    String
    let color:   Color
    let hex:     String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 28, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.80))
                Text(hex)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }
}

// ── Font audit ────────────────────────────────────────────────────────────
// Each row renders the actual font.
// Fail condition: text falls back to system font (wrong weight/style visible)
// How to spot failure: ClashDisplay has very distinctive wide letterforms.
// If it looks like SF Pro it failed to load.

private struct FontRow: View {
    let label:   String
    let font:    Font
    let preview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.30))
            Text(preview)
                .font(font)
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }
}

#Preview("Token Audit", traits: .sizeThatFitsLayout) {
    ScrollView {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ───────────────────────────────────────────────────
            Text("TOKEN AUDIT")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))
                .tracking(3)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 14)

            // ── Core spectrum ─────────────────────────────────────────────
            Group {
                sectionLabel("CORE SPECTRUM")
                ColorRow(name: "cyan",    color: AppColors.cyan,    hex: "#00C2FF")
                ColorRow(name: "purple",  color: AppColors.purple,  hex: "#6C3AE0")
                ColorRow(name: "magenta", color: AppColors.magenta, hex: "#FF006A")
                ColorRow(name: "gold",    color: AppColors.gold,    hex: "#C8960A")
                ColorRow(name: "violet",  color: AppColors.electricViolet, hex: "#8B5CF6")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)

            Separator()

            // ── Page backgrounds ──────────────────────────────────────────
            Group {
                sectionLabel("PAGE BG")
                ColorRow(name: "pageBg",           color: AppColors.pageBg,          hex: "#030305")
                ColorRow(name: "widgetDarkFloor",  color: AppColors.widgetDarkFloor, hex: "#08060A  ← NOT pageBg")
                ColorRow(name: "lightPageBg",      color: AppColors.lightPageBg,     hex: "#F8F6EE")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)

            Separator()

            // ── Dark text ─────────────────────────────────────────────────
            Group {
                sectionLabel("DARK MODE TEXT")
                textAuditRow("textPrimary",   AppColors.textPrimary,   "#E8E8F0 100%")
                textAuditRow("textSecondary", AppColors.textSecondary, "white 65%")
                textAuditRow("textTertiary",  AppColors.textTertiary,  "white 38%")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)
            .background(AppColors.pageBg)

            Separator()

            // ── Light text ────────────────────────────────────────────────
            Group {
                sectionLabel("LIGHT MODE TEXT")
                lightTextRow("lightTextPrimary",   AppColors.lightTextPrimary,   "#1A1A1E 100%")
                lightTextRow("lightTextSecondary", AppColors.lightTextSecondary, "#1A1A1E 55%")
                lightTextRow("lightTextTertiary",  AppColors.lightTextTertiary,  "#1A1A1E 30%")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)
            .background(AppColors.lightPageBg)

            Separator()

            // ── Clash Display ──────────────────────────────────────────────
            Group {
                sectionLabel("CLASH DISPLAY — if fallback to SF Pro this section fails")
                FontRow(label: "sectionHeading  20pt medium",  font: AppFonts.sectionHeading, preview: "Sovereign Space")
                FontRow(label: "screenTitle     24pt semibold", font: AppFonts.screenTitle,   preview: "Jordan.")
                FontRow(label: "cardTitle       22pt semibold", font: AppFonts.cardTitle,     preview: "The Pulse")
                FontRow(label: "prompt          17pt medium",   font: AppFonts.prompt,        preview: "What are you bringing in?")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)

            Separator()

            // ── Switzer ───────────────────────────────────────────────────
            Group {
                sectionLabel("SWITZER — if fallback to SF Pro check font file names")
                FontRow(label: "bodyText    16pt regular",  font: AppFonts.bodyText,    preview: "High capacity · 14 check-ins")
                FontRow(label: "bodyMedium  15pt medium",   font: AppFonts.bodyMedium,  preview: "What are you bringing into today?")
                FontRow(label: "caption     13pt regular",  font: AppFonts.caption,     preview: "Last entry · 2 days ago")
                FontRow(label: "overline    11pt semibold", font: AppFonts.overline,    preview: "THE PULSE")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)

            // ── opacity delta test ─────────────────────────────────────────
            Separator()
            sectionLabel("OPACITY DELTA — pageBg vs widgetDarkFloor must be visibly different")
                .padding(.horizontal, 16)
            HStack(spacing: 0) {
                AppColors.pageBg
                    .frame(height: 40)
                    .overlay(Text("#030305\npageBg").font(.system(size: 8, design: .monospaced)).foregroundStyle(.white.opacity(0.4)).multilineTextAlignment(.center))
                AppColors.widgetDarkFloor
                    .frame(height: 40)
                    .overlay(Text("#08060A\ndarkFloor").font(.system(size: 8, design: .monospaced)).foregroundStyle(.white.opacity(0.4)).multilineTextAlignment(.center))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }
    .background(Color(white: 0.08))
}

// ── Helpers ───────────────────────────────────────────────────────────────

private func sectionLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
        .foregroundStyle(Color(hex: "00C2FF").opacity(0.55))
        .tracking(1.5)
        .padding(.top, 10)
        .padding(.bottom, 4)
}

private func textAuditRow(_ name: String, _ color: Color, _ desc: String) -> some View {
    HStack(spacing: 10) {
        Text("Aa")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 28)
        VStack(alignment: .leading, spacing: 1) {
            Text(name).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(Color.white.opacity(0.60))
            Text(desc).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.white.opacity(0.30))
        }
    }
}

private func lightTextRow(_ name: String, _ color: Color, _ desc: String) -> some View {
    HStack(spacing: 10) {
        Text("Aa")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 28)
        VStack(alignment: .leading, spacing: 1) {
            Text(name).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(AppColors.lightTextSecondary)
            Text(desc).font(.system(size: 10, design: .monospaced)).foregroundStyle(AppColors.lightTextTertiary)
        }
    }
}

private struct Separator: View {
    var body: some View {
        Divider()
            .background(Color.white.opacity(0.07))
            .padding(.vertical, 6)
    }
}