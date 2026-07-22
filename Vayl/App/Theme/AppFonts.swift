// App/Theme/AppFonts.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Typography scale.
//
// Rules:
//   • Every token uses Font.custom(_:size:relativeTo:) — no exceptions
//   • relativeTo: maps to the TextStyle closest to the token's
//     visual role — this is what Dynamic Type scales against
//   • Font.system(size:) is banned in this file
//   • assertionFailure fires on unsupported weights in debug
//     before the fallback path — surfaces programmer errors
//     without crashing in production
//   • Every token has a one-sentence use context comment
// ─────────────────────────────────────────────────────────────

struct AppFonts {

    // ─────────────────────────────────────────────
    // MARK: Typeface constructors
    //
    // Not for direct use in views.
    // Use the semantic tokens below.
    // ─────────────────────────────────────────────

    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size, relativeTo: textStyle)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size, relativeTo: textStyle)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size, relativeTo: textStyle)
        default:
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size, relativeTo: textStyle)
        }
    }

    static func body(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size, relativeTo: textStyle)
        case .medium:
            return Font.custom("Switzer-Medium", size: size, relativeTo: textStyle)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size, relativeTo: textStyle)
        case .bold:
            return Font.custom("Switzer-Bold", size: size, relativeTo: textStyle)
        default:
            assertionFailure(
                "AppFonts.body: unsupported weight \(weight). " +
                "Supported: .regular, .medium, .semibold, .bold"
            )
            return Font.custom("Switzer-Regular", size: size, relativeTo: textStyle)
        }
    }

    /// Editorial serif — deck **case titles ONLY**. A deliberate third typeface
    /// (Playfair Display Black), scoped to the sealed-case face for its engraved,
    /// editorial weight. Do NOT use elsewhere without a brand decision — it is not
    /// part of the general type system (ClashDisplay + Switzer).
    static func editorial(
        _ size: CGFloat,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        Font.custom("PlayfairDisplay-Black", size: size, relativeTo: textStyle)
    }

    // ─────────────────────────────────────────────
    // MARK: Display scale — ClashDisplay
    // ─────────────────────────────────────────────

    /// The in-case deck title on a `DeckCaseView`. Playfair Black, spectrum
    /// gradient applied at the call site. Case face only.
    static var caseTitle: Font {
        editorial(15, relativeTo: .headline)
    }

    /// Full-screen hero text. Splash screens and empty state illustrations only.
    static var heroTitle: Font {
        display(42, weight: .bold, relativeTo: .largeTitle)
    }

    /// Tab masthead wordmark — the hand-built tab titles (Home / Cards / Map / Learn).
    /// One per tab, top-of-screen. Replaces the ad-hoc display(40) and Learn's drifted
    /// display(42) so every masthead renders at one size.
    static var tabMasthead: Font {
        display(40, weight: .bold, relativeTo: .largeTitle)
    }

    /// Oversized display numeral or word. One element per screen maximum.
    static var displayHero: Font {
        display(64, weight: .bold, relativeTo: .largeTitle)
    }

    /// StatPhase "1 in 5" holographic hero. Larger than displayHero (64) and
    /// responsive — the size comes from AppLayout.statHeroSize(usableHeight:screenWidth:),
    /// never an inline literal. relativeTo: .largeTitle so Dynamic Type still scales it.
    /// Exclusive to the StatPhase arrival hero; one per app.
    static func statHero(_ size: CGFloat) -> Font {
        display(size, weight: .bold, relativeTo: .largeTitle)
    }

    /// Numeric data display — scores, counts, codes. Never prose.
    static var scoreDisplay: Font {
        display(32, weight: .bold, relativeTo: .title)
    }

    /// Featured-deck hero title (Play tab) — the deck name above the hero card.
    /// Prose counterpart to scoreDisplay: same 32pt scale, semibold, never numeric data.
    static var deckHeroTitle: Font {
        display(32, weight: .semibold, relativeTo: .title)
    }

    /// One per screen. Top of content area, primary screen identifier.
    static var screenTitle: Font {
        display(24, weight: .semibold, relativeTo: .title)
    }

    /// Sheet title — the headline at the top of a `.vaylSheet`. Same metrics as
    /// screenTitle, named for the sheet-title rule so the intent reads at the call site.
    static var sheetTitle: Font {
        display(24, weight: .semibold, relativeTo: .title)
    }

    /// Cover-family afterglow headline — the session-close recap
    /// ("You went N cards deep tonight."). A hero statement inside the protected
    /// cover, sized well above screenTitle so the moment lands with weight.
    /// relativeTo: .largeTitle so it still scales at accessibility sizes.
    /// Session close only — one per screen.
    static var closeHero: Font {
        display(34, weight: .bold, relativeTo: .largeTitle)
    }

    /// The airlock "Let's Lock In." hero title — a cover-family hero statement,
    /// bold and large so it owns the top of the lock-in moment (matches the design
    /// reference docs/mockups/airlock-lock-in.html). Airlock only, one per screen.
    /// relativeTo: .largeTitle so it still scales at accessibility sizes.
    static var lockInTitle: Font {
        display(38, weight: .bold, relativeTo: .largeTitle)
    }

    /// Onboarding phase headline. One per OB phase screen.
    /// Used for the cinematic opening statement on each onboarding phase —
    /// "Let's get acquainted.", "Good to meet you.", and equivalent lines
    /// on subsequent phases. Larger than screenTitle to anchor the emotional
    /// beat of each phase as a hero statement, not a navigation label.
    /// Never use outside the Onboarding canvas.
    /// relativeTo: .largeTitle — scales against the largest Dynamic Type style
    /// so the statement remains dominant at all accessibility sizes.
    static var obPhaseTitle: Font {
        display(32, weight: .semibold, relativeTo: .largeTitle)
    }

    /// Primary text inside a card surface. Never the screen title.
    static var cardTitle: Font {
        display(22, weight: .semibold, relativeTo: .title2)
    }

    /// Compact card/widget title — for dense rows where cardTitle (22pt) would
    /// truncate beside other elements. Pulse rail state name, list-row headers.
    static var cardTitleCompact: Font {
        display(16, weight: .semibold, relativeTo: .headline)
    }

    /// The Home Pulse widget's hero line — "How's your capacity?" (dormant) or the
    /// landed Space name (active). Sized up from cardTitle (22) so it holds its own
    /// beside the widget's enlarged 84pt aura. Home Pulse widget only.
    static var pulseWidgetTitle: Font {
        display(28, weight: .semibold, relativeTo: .title2)
    }

    /// Section labels inside a screen. Never the screen title.
    static var sectionHeading: Font {
        display(20, weight: .medium, relativeTo: .title3)
    }

    /// Category tags and grouped list headers.
    static var sectionLabelSmall: Font {
        display(13, weight: .medium, relativeTo: .subheadline)
    }

    /// The question or statement on a prompt card.
    static var prompt: Font {
        display(17, weight: .medium, relativeTo: .body)
    }

    /// Keyword emphasis within a prompt. Gradient foreground applied at usage site.
    static var promptHighlight: Font {
        display(17, weight: .semibold, relativeTo: .body)
    }

    // ─────────────────────────────────────────────
    // MARK: Body scale — Switzer
    // ─────────────────────────────────────────────

    /// Primary CTA button label. One per screen.
    static var ctaLabel: Font {
        body(17, weight: .semibold, relativeTo: .body)
    }

    /// Paragraph content. Never UI labels or navigation elements.
    static var bodyText: Font {
        body(16, weight: .regular, relativeTo: .body)
    }

    /// Emphasized body. Form labels, card subtitles, inline emphasis.
    static var bodyMedium: Font {
        body(15, weight: .medium, relativeTo: .body)
    }

    /// Secondary button and action label. Not the primary CTA.
    static var buttonLabel: Font {
        body(14, weight: .semibold, relativeTo: .callout)
    }

    /// Supporting information. Never primary content.
    static var caption: Font {
        body(13, weight: .regular, relativeTo: .caption)
    }

    /// Section dividers only. Always uppercase with tracking at usage site.
    static var overline: Font {
        body(11, weight: .semibold, relativeTo: .caption2)
    }

    /// Compact pill and chip labels only.
    static var buttonLabelSmall: Font {
        body(11, weight: .medium, relativeTo: .caption2)
    }

    /// Navigation labels at the bottom of the screen.
    static var tabLabel: Font {
        body(10, weight: .medium, relativeTo: .caption2)
    }

    /// Badges, counts, status indicators.
    static var label: Font {
        body(10, weight: .semibold, relativeTo: .caption2)
    }

    /// Notification and count badges only.
    static var badge: Font {
        body(10, weight: .medium, relativeTo: .caption2)
    }

    /// Timestamps, counts, secondary metadata. Never primary content.
    static var meta: Font {
        body(10, weight: .regular, relativeTo: .caption2)
    }

    /// Micro badge label — 9pt bold. Tokenizes a verbatim-repeated
    /// `.font(.system(size: 9, weight: .bold))` literal found in RitualPills,
    /// PartnerChipExpand (x2), and PulseFullView's compact status/count badges.
    /// Deliberately System, not Switzer/ClashDisplay — the four call sites all
    /// render System today, and this token exists to preserve that exact
    /// rendered value while still removing the raw literal from the Views.
    /// Do not use for anything that is not one of these compact micro-badges;
    /// do not "upgrade" to body(9, ...) without a deliberate visual decision —
    /// that would change the typeface, not just tokenize it.
    static var microBadge: Font {
        // Deliberate system-font token: 9pt sits below the custom face's usable range;
        // this is the one sanctioned Font.system in the app, defined here at the source.
        // swiftlint:disable:next no_font_system
        Font.system(size: 9, weight: .bold)
    }

    // ─────────────────────────────────────────────
    // MARK: Founder letter — Menlo monospace
    //
    // One-screen use only: FounderLetterPhase.
    // Monospace signals "written by a person" —
    // subconscious dealer/typewriter register.
    // ─────────────────────────────────────────────

    /// Founder letter body. Size is geometry-driven — use letterFont(for:) in FounderLetterPhase.
    static func founderLetter(_ size: CGFloat) -> Font {
        Font.custom("Menlo-Regular", size: size, relativeTo: .body)
    }

    /// Founder letter sign-off weight. Heavier than body to anchor the close.
    static func founderLetterBold(_ size: CGFloat) -> Font {
        Font.custom("Menlo-Bold", size: size, relativeTo: .body)
    }

    // ─────────────────────────────────────────────
    // MARK: Debug
    // ─────────────────────────────────────────────

    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Overline (tracked, uppercased)
//
// SwiftUI `Font` cannot carry tracking or case, so the section-divider
// overline is a View modifier, not a Font token. It bakes in the uppercase
// transform + 2pt tracking so source strings stay sentence-case (never
// pre-uppercased string literals in Views).
// ─────────────────────────────────────────────────────────────

extension View {
    /// The canonical section-overline treatment: `AppFonts.overline`, uppercased,
    /// 2pt tracking. Keep the string in sentence case at the call site.
    func overlineTracked() -> some View {
        self
            .font(AppFonts.overline)
            .textCase(.uppercase)
            .tracking(2)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Optical tracking (size-specific letter-spacing)
//
// Apple's type model: tracking is SIZE-specific, never one value for all sizes.
// Large display text reads too loose as it grows, so it wants NEGATIVE tracking;
// body text wants ~0. SwiftUI `Font` can't carry tracking, so this is a View
// modifier keyed to the token's point size — the display counterpart to the
// fixed 2pt `overlineTracked` (which is for small uppercase labels only).
//
// FEEL-GATE: the slope/threshold below are a starting curve; Bryan dials final
// feel on device. Do NOT apply to the overline/caption labels — those keep their
// deliberate positive tracking.
// ─────────────────────────────────────────────────────────────

extension AppFonts {
    /// Size-specific letter-spacing, in points. Display sizes tighten (negative);
    /// body sizes sit at zero. Linear ramp between `bodyCeiling` and `displayFloor`.
    /// -0.02em on large text is Apple's rule of thumb; expressed here in points.
    static func opticalTracking(forSize size: CGFloat) -> CGFloat {
        let bodyCeiling: CGFloat = 20    // at/below this, no tightening
        let displayFloor: CGFloat = 34   // at/above this, full -0.02em
        guard size > bodyCeiling else { return 0 }
        let t = min(1, (size - bodyCeiling) / (displayFloor - bodyCeiling))
        return -0.02 * size * t
    }
}

extension View {
    /// Applies `AppFonts.opticalTracking(forSize:)` for a display token's point
    /// size — headlines tighten as they grow, body stays at zero. Pass the same
    /// size the font token was built at (e.g. `.vaylDisplayTracking(40)` for a
    /// `tabMasthead`). See the optical-tracking note above.
    func vaylDisplayTracking(_ size: CGFloat) -> some View {
        self.tracking(AppFonts.opticalTracking(forSize: size))
    }
}
