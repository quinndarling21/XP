# Views

## ContentView
The main view of the application, displaying objectives and XP progress.

### Components
- Grid of ObjectiveCards
- XP Progress Bar at bottom
- Level indicator

## Supporting Views

### ObjectiveCard
Displays a single objective with:
- Visual completion status
- XP value
- Complete button (if not completed)

### XPProgressBar
Shows user progression with:
- Current level
- XP progress bar
- Current/Required XP values

## Implementation Details
- Uses MVVM pattern with MainViewModel
- Grid layout adapts to screen size
- Progress bar updates in real-time
- Smooth animations on completion 