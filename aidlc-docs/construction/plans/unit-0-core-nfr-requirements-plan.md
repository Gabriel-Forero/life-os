# NFR Requirements Plan — Unit 0: Core Foundation

## Context
Most NFR decisions are already established:
- Security extension enabled (SECURITY-01 to SECURITY-15)
- PBT extension enabled full (PBT-01 to PBT-10)
- WCAG 2.1 AA accessibility required
- Error handling: Result<T> + AppFailure → AsyncValue
- Biometric: local_auth
- Secure storage: flutter_secure_storage

One key decision remains: PBT framework selection for Dart (required by PBT-09).

---

## Questions

### Question 1
Which property-based testing framework for Dart/Flutter?

A) glados — Dart PBT framework with shrinking, custom generators, seed reproducibility. Closest to Hypothesis (Python). ~200 pub.dev likes, actively maintained.
B) propcheck — Lighter PBT for Dart. Custom generators, basic shrinking. Less mature but simpler API.
C) Use dart_test with custom randomized test helpers — no dedicated PBT package, write generators manually using dart:math + test package. Maximum control, no extra dependency.
X) Other (please describe after [Answer]: tag below)

[Answer]: A

**Decision**: glados — framework PBT para Dart con shrinking, generators custom, y seed reproducibility.

**Rationale**:
- glados es el framework PBT más maduro del ecosistema Dart. Ofrece shrinking automático (cuando un test falla, reduce el input al caso mínimo que reproduce el fallo), generators tipados para tipos primitivos y compuestos, y reproducibilidad por seed — exactamente lo que PBT-09 requiere.
- Su API es idiomática en Dart y se integra directamente con el `test` package estándar, así que los PBT tests viven junto a los unit tests existentes sin infraestructura adicional.
- Soporta generators custom, lo cual es necesario para generar instancias válidas de AppSettings, BackupManifest, AppEvent subclasses, y NotificationConfig respetando sus constraints (ej: currency siempre ISO 4217, enabledModules con al menos 1 módulo).
- El shrinking es especialmente valioso para las round-trip properties (RT-01 a RT-05): si un JSON round-trip falla, glados reduce automáticamente el input a la estructura mínima que rompe la serialización.
- ~200 likes en pub.dev y mantenido activamente — suficiente comunidad para encontrar soluciones a problemas comunes.

**Alternatives Discarded**:
- B (propcheck): API más simple pero shrinking menos sofisticado y menos maduro. Para 14 testable properties con tipos sealed complejos, necesitamos shrinking robusto.
- C (custom helpers): Máximo control pero reinventa la rueda. Escribir generators con shrinking manualmente para cada tipo es effort significativo sin beneficio claro. El `test` package no tiene soporte nativo para PBT.

---

## Execution Steps

- [x] Step 1: Answer PBT framework question ✅ — glados selected
- [x] Step 2: Document all NFR requirements for Unit 0 ✅ — 6 categories, 25+ requirements
- [x] Step 3: Document tech stack decisions ✅ — core + testing + dev tools + compliance
- [x] Step 4: Generate NFR artifacts ✅ — 2 files
