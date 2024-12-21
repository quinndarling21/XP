# View Models

## MainViewModel

The primary view model managing user progression and objectives.

### Properties
- `user: User?` - Current user with progression data
- `objectives: [Objective]` - Current set of available objectives

### Key Methods

#### Data Management
- `fetchUserData()` - Loads or creates user from Core Data
- `generateObjectives()` - Creates new set of random objectives

#### User Actions
- `markObjectiveComplete(_:)` - Records objective completion and updates user XP

### Implementation Details
- Uses Core Data for persistence
- Generates random objectives at runtime
- Manages user XP and level progression
- Implements ObservableObject for SwiftUI binding 
