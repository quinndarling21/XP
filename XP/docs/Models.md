# XP Tracker Models

## Core Data Models

### User
Represents the user's progress and achievements in the app.

#### Attributes
- `id`: UUID - Unique identifier for the user (automatically generated)
- `currentLevel`: Int32 - User's current level (default: 1)
- `currentXP`: Int32 - Experience points in current level (default: 0)
- `requiredXPForLevel`: Int32 - XP needed to reach next level (default: 1000)
- `objectivesCompleted`: Int32 - Total number of completed objectives (default: 0)
- `streakStartDate`: Date? - Start date of current streak
- `streakEndDate`: Date? - Last completion date of streak

#### Implementation Details
- UUID is automatically generated via `awakeFromInsert()` in User+CoreDataClass.swift
- Default values are set in the Core Data model
- Helper method `createUser()` available in PersistenceController for convenient initialization

## Runtime Models

### Objective
Represents a single objective that can be completed to earn XP.

#### Properties
- `id`: UUID - Unique identifier for the objective
- `xpValue`: Int - Experience points earned for completing (100-500, divisible by 10)
- `isCompleted`: Bool - Whether the objective has been completed

#### Generation
Objectives are generated at runtime rather than stored permanently. This allows for:
- Dynamic XP values
- Fresh objectives each session
- No persistent storage overhead

## File Organization
- `Models/`
  - `User+CoreDataClass.swift` - User entity extensions
  - `User+Extensions.swift` - User entity extensions
  - `Objective.swift` - Runtime objective model
- `CoreData/`
  - `XP.xcdatamodeld` - Core Data model schema
  - `PersistenceController.swift` - Core Data stack management