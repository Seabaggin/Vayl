# Open Lightly — Development Rules

## Architecture
- MVVM (Model-View-ViewModel)
- Views only handle display and user input
- ViewModels are @Observable classes — no SwiftUI imports
- Services handle business logic and external communication
- Models are dumb data containers

## Naming
- Views: [Feature]View.swift (e.g., HomeView.swift)
- ViewModels: [Feature]ViewModel.swift
- Services: [Name]Service.swift or [Name]Manager.swift
- Models: singular noun (e.g., User.swift, Card.swift)
- Enums: singular noun (e.g., CardStatus.swift)

## SwiftUI
- iOS 17+ minimum
- @Observable (not ObservableObject)
- SwiftData (not Core Data)
- async/await (not Combine unless bridging)
- SF Symbols for all icons
- System font only (San Francisco)

## Design System
- Three theme modes: system / light / amoled
- AMOLED (dark): pure black backgrounds, vibrant accents
- Light: warm off-white backgrounds, deeper accent tones
- Primary accents: cyan (#5ED0EE light / #0891B2 dark) + magenta (#F472AD light / #BE185D dark)
- Decorative accent: navy (#9494D0 light / #1A3A8F dark) — score ring, spectrum bar only
- Card surfaces: semi-transparent on elevated background with subtle border
- See AppTheme.swift for full palette

## Categories
- 6 categories in therapeutic order (not 8):
  1. Relationship Health — foundation
  2. Insecurities & Jealousy — foundation
  3. Sexual Satisfaction — exploration
  4. Compatibility & Vision — exploration
  5. Boundaries & Agreements — framework
  6. NM Logistics — planning (locked until 2+ categories complete)

## Privacy
- Individual assessment answers never leave device
- Kink Hard No ratings are NEVER revealed to partner — matchResult returns nil
- Safe word usage never logged anywhere
- Encrypt sensitive local data with CryptoKit
