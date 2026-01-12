# Ralph Agent Instructions

You are an autonomous coding agent working on a software project.

## Your Task

1. Read the PRD at `prd.json` (in the same directory as this file)
2. Read the progress log at `progress.txt` (check Codebase Patterns section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
4. Pick the **highest priority** user story where `passes: false`
5. Implement that single user story
6. Run quality checks (e.g., typecheck, lint, test - use whatever your project requires)
7. Update AGENTS.md files if you discover reusable patterns (see below)
8. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
9. Update the PRD to set `passes: true` for the completed story
10. Append your progress to `progress.txt`

## Progress Report Format

APPEND to progress.txt (never replace, always append):
```
## [Date/Time] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered (e.g., "this codebase uses X for Y")
  - Gotchas encountered (e.g., "don't forget to update Z when changing W")
  - Useful context (e.g., "the evaluation panel is in component X")
---
```

The learnings section is critical - it helps future iterations avoid repeating mistakes and understand the codebase better.

## Consolidate Patterns

If you discover a **reusable pattern** that future iterations should know, add it to the `## Codebase Patterns` section at the TOP of progress.txt (create it if it doesn't exist). This section should consolidate the most important learnings:

```
## Codebase Patterns
- Example: Use `sql<number>` template for aggregations
- Example: Always use `IF NOT EXISTS` for migrations
- Example: Export types from actions.ts for UI components
```

Only add patterns that are **general and reusable**, not story-specific details.

## Update AGENTS.md Files

Before committing, check if any edited files have learnings worth preserving in nearby AGENTS.md files:

1. **Identify directories with edited files** - Look at which directories you modified
2. **Check for existing AGENTS.md** - Look for AGENTS.md in those directories or parent directories
3. **Add valuable learnings** - If you discovered something future developers/agents should know:
   - API patterns or conventions specific to that module
   - Gotchas or non-obvious requirements
   - Dependencies between files
   - Testing approaches for that area
   - Configuration or environment requirements

**Examples of good AGENTS.md additions:**
- "When modifying X, also update Y to keep them in sync"
- "This module uses pattern Z for all API calls"
- "Tests require the dev server running on PORT 3000"
- "Field names must match the template exactly"

**Do NOT add:**
- Story-specific implementation details
- Temporary debugging notes
- Information already in progress.txt

Only update AGENTS.md if you have **genuinely reusable knowledge** that would help future work in that directory.

## Quality Requirements

- ALL commits must pass your project's quality checks (typecheck, lint, test)
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns

## iOS Build Validation (Required for iOS Projects)

For iOS/Swift projects, you MUST use `xcodebuild` for validation, NOT `swiftc -parse`:

```bash
# Build for iOS Simulator (catches all compilation errors)
xcodebuild -scheme <SchemeName> -destination 'generic/platform=iOS Simulator' -configuration Debug build

# If no simulators available, build with SDK flag
xcodebuild -scheme <SchemeName> -sdk iphonesimulator -configuration Debug build
```

**Why xcodebuild over swiftc -parse:**
- `swiftc -parse` only checks syntax, missing type errors, binding issues, and API mismatches
- `xcodebuild` performs full compilation and catches all errors
- Stories are NOT complete until xcodebuild succeeds with zero errors

## iOS Simulator Testing (Required for iOS UI Stories)

For any iOS story that changes UI, you MUST verify it works in the simulator. This is equivalent to browser testing for web apps.

### Setup (run once per session)

```bash
# Check available simulators
xcrun simctl list devices available

# Boot a simulator (e.g., iPhone 17 Pro)
xcrun simctl boot "iPhone 17 Pro"

# Open Simulator app
open -a Simulator
```

### Build, Install, and Launch App

```bash
# Build the app
xcodebuild -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install the app (find .app path in build output)
xcrun simctl install booted /path/to/DerivedData/<Project>/Build/Products/Debug-iphonesimulator/<AppName>.app

# Launch the app (use bundle ID from Info.plist)
xcrun simctl launch booted <BundleIdentifier>
```

### Capture Screenshots for Validation

```bash
# Take screenshot of current simulator state
xcrun simctl io booted screenshot /tmp/screenshot.png

# Use Read tool to view and analyze the screenshot
```

### Validation Workflow

1. **Build and install** the app on simulator
2. **Launch the app** using bundle identifier
3. **Capture screenshot** of the relevant screen
4. **Analyze screenshot** to verify UI matches acceptance criteria
5. **Document findings** in progress.txt

### User-Defined Success Criteria

In `prd.json`, users can define `simulatorValidation` for each story:

```json
{
  "id": "US-001",
  "title": "Tab navigation",
  "acceptanceCriteria": [...],
  "simulatorValidation": {
    "screens": [
      {
        "name": "Gallery Tab",
        "action": "Launch app",
        "expectedElements": ["Gallery title", "3-column photo grid", "Tab bar with 3 tabs"]
      },
      {
        "name": "Collections Tab",
        "action": "Tap Collections tab",
        "expectedElements": ["Collections title", "People section", "Albums list"]
      }
    ]
  }
}
```

### Validation Checks

When validating, verify these elements are present in screenshots:
- **Navigation elements**: Tab bars, navigation bars, back buttons
- **Content layout**: Grids, lists, cards as specified
- **Text labels**: Titles, descriptions, button labels
- **Icons**: SF Symbols, custom icons
- **States**: Loading, empty, error states as appropriate

### Example Validation Commands

```bash
# Full validation workflow
SCHEME="LocalPhotosApp"
BUNDLE_ID="com.ralph.LocalPhotosApp"
DEVICE="iPhone 17 Pro"

# Build
xcodebuild -scheme $SCHEME -destination "platform=iOS Simulator,name=$DEVICE" build

# Get app path (from DerivedData)
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "$SCHEME.app" -path "*/Debug-iphonesimulator/*" | head -1)

# Install and launch
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted $BUNDLE_ID

# Wait for app to load
sleep 2

# Capture and analyze
xcrun simctl io booted screenshot /tmp/validation.png
```

An iOS UI story is NOT complete until simulator validation passes.

## Browser Testing (Required for Frontend Stories)

For any story that changes UI, you MUST verify it works in the browser:

1. Use the WebFetch tool or a browser MCP server to navigate to the relevant page
2. Verify the UI changes work as expected
3. Take a screenshot if helpful for the progress log

A frontend story is NOT complete until browser verification passes.

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

If ALL stories are complete and passing, reply with:
<promise>COMPLETE</promise>

If there are still stories with `passes: false`, end your response normally (another iteration will pick up the next story).

## Important

- Work on ONE story per iteration
- Commit frequently
- Keep CI green
- Read the Codebase Patterns section in progress.txt before starting
