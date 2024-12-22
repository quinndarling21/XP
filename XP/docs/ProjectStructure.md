# XP Tracker App Structure

## Overview
XP Tracker is a gamified habit tracking iOS app built with SwiftUI and Core Data. The app allows users to complete objectives and earn experience points (XP) to level up.

## Project Structure

### App
- `XPApp.swift` - The main app entry point
- `Info.plist` - App configuration

### Views
- `ContentView.swift` - The main view of the application
- Additional views will be added as needed

### ViewModels
ViewModels will be added to handle the business logic for:
- User progression
- XP calculations
- Objective management
- Streak tracking

### Models
Core Data models for:
- User
- Objectives (to be implemented)

### CoreData
- `XP.xcdatamodeld` - Core Data model
- `PersistenceController.swift` - Manages Core Data stack

### Assets
- `Assets.xcassets` - Contains app icons and other assets

## Testing
Tests will be organized in:
- Unit Tests for ViewModels
- UI Tests for View interactions
- Core Data Tests for persistence logic 

## New Features

### Pathways
- `Pathway` model with attributes for name, description, and XP tracking.
- `PathwayViewModel` for managing pathways.
- `PathwayListView` for displaying and navigating pathways.