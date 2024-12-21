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
- Tap gesture to show detail view

### ObjectiveDetailView
A modal view showing detailed objective information:
- Large icon indicating completion status
- XP reward value
- Mark as Complete button (if not completed)
- Dismissible sheet presentation

### XPProgressBar
Shows user progression with:
- Current level
- XP progress bar
- Current/Required XP values

## Implementation Details
- Uses MVVM pattern with MainViewModel
- Sheet-based navigation for objective details
- Grid layout adapts to screen size
- Progress bar updates in real-time
- Smooth animations on completion