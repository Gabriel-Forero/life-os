# Requirements Verification Questions — LifeOS

Please answer the following questions to help complete the Product Requirements Document.
Fill in the letter choice after each [Answer]: tag.

---

## Question 1
What is the true MVP scope? The spec lists Finanzas, Gym, Nutricion, and Habitos for Phase 1, but building all 4 at once is ambitious. What should ship in v1.0?

A) All 4 modules (Finanzas + Gym + Nutricion + Habitos) — full Phase 1 as written
B) Only Finanzas + Gym (the two highest priority), then add the rest in updates
C) Only Finanzas (P1) first, ship fast, iterate
D) Finanzas + Habitos (the two lightest modules to build)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
What languages should the app UI support?

A) Spanish only — as specified in the spec
B) Spanish + English — bilingual from day one
C) Spanish first, with localization architecture ready for future languages
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 3
What is the minimum iOS version you want to support?

A) iOS 17+ (as written in spec — required for SwiftData)
B) iOS 18+ (allows use of newer APIs, smaller user base)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
How should the app handle data privacy for financial and health data?

A) Local-only by default, iCloud backup as explicit opt-in. No data leaves the device unless user enables it
B) iCloud sync enabled by default for multi-device support, with option to disable
C) Local-only always — no cloud features at all
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 5
For the IA layer (BYOK), should there be any fallback when the user has no API key configured?

A) No IA features shown at all — the section is hidden until a key is added
B) Show IA features but grayed out with a message "Configure tu API key para desbloquear"
C) Provide basic local analytics (averages, simple trends) without IA, and upgrade to full insights with API key
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 6
For automatic payment registration (bank notifications, Apple Pay, Shortcuts), what happens when a transaction is auto-detected?

A) Auto-create the transaction immediately and notify the user to review/categorize
B) Show a confirmation prompt before creating the transaction — nothing is saved without user approval
C) Create a "pending" transaction that the user must confirm within 24h, otherwise it's discarded
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 7
What is the target device form factor?

A) iPhone only
B) iPhone + iPad (universal app)
C) iPhone + iPad + Mac (Catalyst or native macOS)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 8
Should the app have a monetization strategy?

A) Completely free — no ads, no in-app purchases, no subscriptions
B) Free with optional tip jar / "buy me a coffee"
C) Freemium — core features free, advanced features (IA, widgets, export) behind one-time purchase
D) Freemium — core free, premium subscription for IA + advanced features
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 9
What accessibility level should the app meet?

A) Basic — VoiceOver support and Dynamic Type only
B) Standard — VoiceOver, Dynamic Type, Reduce Motion, high contrast colors
C) Full WCAG 2.1 AA compliance — comprehensive accessibility testing
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 10
What should happen with the data when a user deletes the app?

A) All local data is permanently deleted. If iCloud backup exists, it persists in iCloud until user deletes it from Settings
B) Prompt user to export data before deletion (via an app setting, not at delete time)
C) No special handling — standard iOS behavior (local data deleted, iCloud data persists)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 11
For the gym module, should the exercise library (200+ exercises) be bundled with the app or downloaded on first launch?

A) Bundled in the app binary (larger app size, works offline immediately)
B) Downloaded on first launch from a remote source (smaller app, requires internet once)
C) Bundled as a JSON file in the app bundle (lightweight, no download needed)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 12
What currency should be the default, and how should multi-currency work?

A) COP (Colombian Peso) as default, with option to add other currencies later
B) USD as default, multi-currency in post-MVP
C) User selects their primary currency during onboarding, multi-currency in post-MVP
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 13: Security Extensions
Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)
B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 14: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)
B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)
C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)
X) Other (please describe after [Answer]: tag below)

[Answer]: A
