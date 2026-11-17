# MASTER PROMPT: React to Flutter Attendance Tracker Migration & Modernization

## 1. ROLE & RESPONSIBILITY

Act as a Senior Flutter Architect, Software Engineer, UI/UX Engineer, Firebase Specialist, and Technical Project Manager.

Your responsibility is to migrate my existing React-based Attendance Tracker application into Flutter while preserving its existing functionality, business logic, data integrity, UI/UX behavior, and user experience.

This is NOT a simple code conversion task.

Treat this as a professional software engineering project focused on:

- Clean Architecture
- Modular and feature-first architecture
- Scalability
- Maintainability
- Reusability
- Performance
- Security
- Testability
- Long-term extensibility

The final application must be production-ready, not just a working prototype.

## 2. PRIMARY OBJECTIVE

Build a Flutter application that reproduces the existing React application as closely as possible.

Existing React application is the source of truth for:

- Features and functionality
- Business rules
- Attendance calculation logic
- UI/UX behavior
- Navigation flow
- User interactions
- Data models
- Firebase integration
- Existing workflows

Do not remove, simplify, reinterpret, or invent existing features without explicit approval.

Existing Flutter implementation may already contain partially completed modules.

Before modifying anything, inspect the entire existing Flutter project and understand its current implementation.

Preserve working code and improve it incrementally.

## 3. NON-NEGOTIABLE ARCHITECTURAL PRINCIPLES

### A. Feature-First Modular Architecture

Organize the project by features instead of creating one giant files directory.

Each feature should have its own presentation, domain, and data layers wherever appropriate.

Suggested structure:

lib/
  main.dart

  app/
    app.dart
    bootstrap.dart
    router/
    theme/
    config/

  core/
    constants/
    errors/
    exceptions/
    extensions/
    utils/
    network/
    services/
    storage/
    widgets/

  shared/
    widgets/
    models/
    components/

  features/
    authentication/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        widgets/
        providers/

    dashboard/
      data/
      domain/
      presentation/

    attendance/
      data/
      domain/
      presentation/

    subjects/
      data/
      domain/
      presentation/

    timetable/
      data/
      domain/
      presentation/

    reports/
      data/
      domain/
      presentation/

    settings/
      data/
      domain/
      presentation/

  firebase/
    firebase_options.dart

This is a suggested structure, not a reason to create unnecessary abstractions. Adapt it to actual project requirements.

### B. Avoid Monolithic Files

Strict rules:

- No 1000+ line widgets or screens.
- No giant main.dart.
- No mixing UI, business logic, and database operations.
- No unnecessary duplicate implementations.
- No hardcoded business rules inside widgets.
- No repeated Firebase queries across screens.
- No excessive nesting.
- No unnecessary abstraction for simple functionality.

Split components into small, reusable, meaningful files.

Every file must have a clear responsibility.

### C. Centralized Data Management

Establish a single source of truth for application data.

Requirements:

- Centralized repository layer.
- Consistent state management.
- Centralized Firebase access.
- Shared data models.
- Centralized configuration.
- Centralized error handling.
- Consistent loading, empty, success, and failure states.

Never allow multiple screens to independently maintain conflicting copies of the same business data.

Use repositories as the boundary between the application and external data sources.

### D. State Management

Evaluate the existing implementation and choose an appropriate scalable state-management solution.

Preferred options:

- Riverpod (recommended).
- Bloc/Cubit when justified by project complexity.

Use one primary state-management approach consistently.

Requirements:

- Clear separation of UI and application logic.
- Predictable state transitions.
- Reactive updates.
- Proper lifecycle management.
- No unnecessary rebuilds.
- Avoid global mutable state.

### E. Clean Architecture

Maintain separation between:

1. Presentation Layer
2. Domain Layer
3. Data Layer

Domain logic must not depend on Flutter widgets, Firebase SDKs, or UI implementation details.

Repositories should be defined through abstractions where beneficial.

Use dependency injection for services and repositories.

## 4. DEVELOPMENT BEST PRACTICES

Follow these engineering standards throughout the project:

- SOLID principles where applicable.
- DRY without overengineering.
- KISS.
- Effective naming conventions.
- Null safety.
- Immutable models where appropriate.
- Strong typing.
- Reusable UI components.
- Centralized design tokens.
- Responsive layouts.
- Accessibility support.
- Lazy loading for large datasets.
- Pagination where necessary.
- Efficient database queries.
- Proper async/await handling.
- Memory and resource management.
- Logging and error reporting.
- Secure configuration management.
- Input validation.
- Offline and connectivity handling where required.
- Unit, widget, and integration testing.
- Documentation for complex business logic.

Never expose Firebase Admin credentials or service account secrets in the client application.

Use Firebase Security Rules and validate authorization on the backend.

Do not assume that hiding a UI element provides security.

## 5. UI/UX MIGRATION RULES

The existing React application is the visual reference.

Reproduce:

- Layout hierarchy.
- Spacing.
- Typography.
- Colors.
- Cards.
- Navigation.
- Icons.
- Charts.
- Dialogs.
- Bottom sheets.
- Animations.
- Interactive elements.
- Responsive behavior.

Do not redesign the application unless explicitly instructed.

Use centralized design tokens:

- AppColors
- AppTypography
- AppSpacing
- AppRadius
- AppShadows
- AppTheme

Avoid repeating raw color values, spacing values, and typography definitions throughout the application.

Build reusable components only when they represent genuinely reusable UI patterns.

## 6. FIREBASE & DATA ARCHITECTURE

First inspect the existing Firebase implementation.

Determine which services are currently used:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Cloud Functions

Do not add unnecessary Firebase services.

Preserve the existing database schema and document structure unless a migration is necessary.

If a schema change is required:

1. Explain the reason.
2. Identify affected collections and documents.
3. Design a backward-compatible migration.
4. Define rollback considerations.
5. Obtain approval before destructive changes.

Implement:

- Centralized Firebase initialization.
- Repository-based data access.
- Consistent error handling.
- Proper security rules.
- Query optimization.
- Server-side validation where required.
- Offline persistence where appropriate.

Never scatter direct Firestore calls throughout presentation widgets.

## 7. PHASE-WISE EXECUTION PLAN

Execute the project in the following phases.

Do not skip phases.

### PHASE 0 — Project Discovery & Audit

Inspect:

- Complete React source code.
- Complete Flutter source code.
- Existing Firebase architecture.
- Existing dependencies.
- Existing navigation.
- Current implementation progress.
- Existing business logic.
- Data models.
- UI components.
- Assets and fonts.

Deliverables:

- React application feature inventory.
- Flutter implementation status report.
- React-to-Flutter feature mapping.
- Missing functionality report.
- Architecture audit.
- Dependency audit.
- Migration risk assessment.
- Recommended implementation roadmap.

Do not modify code during this phase.

### PHASE 1 — Architecture Foundation

Establish:

- Folder architecture.
- Dependency injection.
- State management.
- Navigation and routing.
- Theme system.
- Design tokens.
- Error handling.
- Logging.
- Firebase initialization.
- Environment configuration.

Deliverables:

- Scalable project structure.
- Working application bootstrap.
- Centralized dependencies.
- Reusable architectural foundations.

### PHASE 2 — Core Data & Backend Layer

Implement:

- Domain entities.
- Data models.
- Repository contracts.
- Firebase data sources.
- Repository implementations.
- Data serialization.
- Validation.
- Error mapping.
- Centralized data access.

Verify compatibility with the existing React application's Firebase data.

### PHASE 3 — Core UI Components

Build:

- Shared widgets.
- Reusable cards.
- Buttons.
- Input fields.
- Dialogs.
- Bottom sheets.
- Navigation components.
- Loading states.
- Empty states.
- Error states.

Match the React application's visual language.

### PHASE 4 — Feature-by-Feature Migration

Migrate existing features individually.

For each feature:

1. Understand React implementation.
2. Identify business logic.
3. Identify required data.
4. Implement domain logic.
5. Implement repository integration.
6. Implement state management.
7. Build Flutter UI.
8. Match existing interactions.
9. Test edge cases.
10. Compare against React.

Do not start another feature until the current feature passes its acceptance criteria.

### PHASE 5 — Business Logic & Attendance Engine

Pay special attention to attendance calculations.

Preserve the exact existing rules for:

- Total classes.
- Attended classes.
- Absent classes.
- Attendance percentage.
- Required attendance percentage.
- Classes needed to reach the target.
- Maximum classes that can be skipped.
- Attendance recovery planning.
- Subject-wise calculations.
- Overall attendance calculations.

Keep calculations in dedicated domain services or use cases.

Do not duplicate calculation logic across screens.

Add unit tests for all critical calculations.

### PHASE 6 — Integration & Data Consistency

Verify:

- Authentication.
- Firestore integration.
- Real-time updates where required.
- Data persistence.
- State synchronization.
- Offline behavior.
- Error recovery.
- Data consistency across screens.

### PHASE 7 — Testing & Quality Assurance

Implement:

- Unit tests.
- Widget tests.
- Integration tests.
- Repository tests.
- Business logic tests.
- Firebase integration tests where practical.

Run:

flutter analyze
flutter test

Resolve all critical errors and warnings.

Compare the Flutter implementation against the React reference.

### PHASE 8 — Performance & Security

Audit:

- Unnecessary widget rebuilds.
- Excessive Firebase reads.
- Memory leaks.
- Large asset loading.
- Rendering performance.
- App startup time.
- Security rules.
- Authentication handling.
- Data validation.
- Error reporting.

Optimize based on actual measurements rather than assumptions.

### PHASE 9 — Production Readiness

Prepare:

- Android release build.
- App icon.
- Splash screen.
- App metadata.
- Version management.
- Release configuration.
- Crash reporting if required.
- Final QA checklist.
- Deployment documentation.

Do not claim production readiness until all critical acceptance criteria pass.

## 8. PHASE EXECUTION PROTOCOL

This is extremely important.

Follow this workflow for every phase:

1. Inspect the relevant existing code.
2. Understand dependencies and architecture.
3. Prepare a short implementation plan.
4. Identify files to create, modify, or remove.
5. Implement the changes.
6. Run relevant tests and static analysis.
7. Fix regressions.
8. Review architectural consistency.
9. Update project documentation.
10. Provide a completion report.

After every phase, report:

- What was implemented.
- Files created.
- Files modified.
- Files removed, with reasons.
- Features completed.
- Tests executed.
- Test results.
- Known issues.
- Remaining tasks.
- Next phase prerequisites.

Maintain a PHASE_PROGRESS.md file containing:

- Current phase.
- Completed phases.
- In-progress tasks.
- Pending tasks.
- Known issues.
- Architecture decisions.
- Important migration notes.

Also maintain an ARCHITECTURE.md file documenting important architectural decisions and dependencies.

## 9. STRICT DEVELOPMENT RESTRICTIONS

- Never rewrite the entire project unnecessarily.
- Never delete working code without understanding its purpose.
- Never introduce packages without evaluating their necessity.
- Never duplicate existing functionality.
- Never silently change business rules.
- Never create dummy implementations and mark them complete.
- Never use placeholder data in production flows.
- Never ignore analyzer errors.
- Never bypass tests to claim completion.
- Never make destructive database changes without approval.
- Never modify unrelated features during a phase.
- Never assume a feature is complete just because its UI exists.

If something is unclear, inspect the source code first.

If a decision could affect existing functionality or data, explain the trade-offs and ask for approval.

## 10. FINAL ACCEPTANCE CRITERIA

The migration is successful only when:

- All existing React features are accounted for.
- Existing business logic is preserved.
- Flutter UI matches the reference application.
- Firebase integration works correctly.
- Data remains consistent.
- Architecture is modular and maintainable.
- No critical analyzer errors remain.
- Critical unit and integration tests pass.
- No major navigation or interaction regressions exist.
- Application performs reliably on target devices.
- Documentation is updated.
- Android release build succeeds.

## 11. FIRST ACTION

START WITH PHASE 0 ONLY.

Inspect both the React and Flutter projects thoroughly.

Do not start implementation.

Do not modify any source files.

Produce a comprehensive audit report and a realistic phased migration roadmap.

Wait for my approval before beginning Phase 1.

Remember: prioritize correctness, architectural quality, maintainability, and preservation of existing functionality over development speed.