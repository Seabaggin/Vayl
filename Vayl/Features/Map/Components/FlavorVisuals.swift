//
//  FlavorVisuals.swift
//  Vayl
//
//  Shared visual atoms for the Me Card: the lattice sigil portrait, the flavor
//  chip, and the "Drawn to" tag (shared tags glow in the flavor colour). Used by
//  both the compact card and the full editor sheet.
//

import SwiftUI

/// Two nested diamonds — the lattice sigil used on identity surfaces.
struct FlavorSigil: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = w / 2, cy = h / 2
        p.move(to: CGPoint(x: cx, y: 0))
        p.addLine(to: CGPoint(x: w, y: cy))
        p.addLine(to: CGPoint(x: cx, y: h))
        p.addLine(to: CGPoint(x: 0, y: cy))
        p.closeSubpath()
        let inset = min(w, h) * 0.28
        p.move(to: CGPoint(x: cx, y: inset))
        p.addLine(to: CGPoint(x: w - inset, y: cy))
        p.addLine(to: CGPoint(x: cx, y: h - inset))
        p.addLine(to: CGPoint(x: inset, y: cy))
        p.closeSubpath()
        return p
    }
}

/// The portrait: a spectrum ring around the lattice sigil (V1 has no opt-in photo).
struct FlavorPortrait: View {
    var size: CGFloat = 56

    private var spectrum: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(spectrum, lineWidth: 2)
            FlavorSigil()
                .stroke(spectrum, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                .frame(width: size * 0.46, height: size * 0.46)
        }
        .frame(width: size, height: size)
    }
}

/// The flavor chip (icon + label, tinted by the flavor colour).
struct FlavorChip: View {
    let flavor: Flavor

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: flavor.icon)
                .font(AppFonts.body(11, weight: .semibold, relativeTo: .caption))
            Text(flavor.label.uppercased())
                .font(AppFonts.overline)
                .tracking(0.6)
        }
        .foregroundStyle(AppColors.textBody)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs + 1)
        .background(Capsule().fill(flavor.color.opacity(0.22)))
        .overlay(Capsule().strokeBorder(flavor.color.opacity(0.45), lineWidth: 1))
    }
}

/// A "Drawn to" tag. Shared (mutual) tags glow in the flavor colour.
struct DrawnTagChip: View {
    let tag: MapStore.DrawnTag
    let flavor: Flavor

    var body: some View {
        HStack(spacing: 3) {
            if tag.isShared {
                Image(systemName: "sparkle").font(AppFonts.body(8, weight: .regular, relativeTo: .caption2))
            }
            Text(tag.name).font(AppFonts.caption)
        }
        .foregroundStyle(tag.isShared ? .white : AppColors.textBody)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Capsule().fill(tag.isShared ? flavor.color.opacity(0.18) : AppColors.glassSurface))
        .overlay(
            Capsule().strokeBorder(
                tag.isShared ? flavor.color.opacity(0.45) : AppColors.borderSubtle,
                lineWidth: 1
            )
        )
    }
}

// MARK: - Couple crest

/// Two side-by-side diamonds — the couple crest (the Us-layer counterpart to the
/// single-diamond Me sigil).
struct CoupleCrestSigil: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.30
        diamond(&p, center: CGPoint(x: rect.midX - r * 0.7, y: rect.midY), radius: r)
        diamond(&p, center: CGPoint(x: rect.midX + r * 0.7, y: rect.midY), radius: r)
        return p
    }

    private func diamond(_ p: inout Path, center c: CGPoint, radius r: CGFloat) {
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y + r))
        p.addLine(to: CGPoint(x: c.x - r, y: c.y))
        p.closeSubpath()
    }
}

/// A couple crest portrait — spectrum ring around the twin-diamond crest.
struct CoupleCrestPortrait: View {
    var size: CGFloat = 52

    private var spectrum: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(spectrum, lineWidth: 2)
            CoupleCrestSigil()
                .stroke(spectrum, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
    }
}
