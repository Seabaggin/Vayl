// Models/Enums/AppTab.swift

import Foundation

/// Tab identifiers for the main tab bar.
/// Raw value matches TabView selection tag.
enum AppTab: Hashable {
    case home
    case meUs       // "Me" for solo, "Us · Me" for couple — label driven by ExperienceType
    case explore
    case more
}
