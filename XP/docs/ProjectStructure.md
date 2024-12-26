# XP Tracker App Structure

## Overview
XP Tracker is a gamified habit tracking iOS app built with SwiftUI and Core Data. The app allows users to create multiple pathways, each with their own objectives and progression systems.

## Core Components

### Pathway Management
- Creation and deletion of pathways with:
  - Name and description
  - Color theme selection
  - XP tracking and leveling
  - Optional cadence settings
  - Minimum of 10 objectives per pathway
- Cascade deletion of associated data
- Persistent storage using Core Data

### Pathway Features
- Individual XP and level progression
- Customizable color themes
- Optional cadence system for timed objectives
- Progress tracking and statistics
- Objective management

### Data Model
Core Data models for:
- Pathway
  - Basic information (name, description, color)
  - Progress tracking (XP, level, objectives completed)
  - Relationships to objectives and cadence cycles
- StoredObjective
  - XP value and completion status
  - Order tracking
  - Relationships to pathway and cadence cycles
- CadenceCycle (optional)
  - Frequency settings
  - Objective count
  - Progress tracking

### ViewModels
- PathwayViewModel
  - Pathway CRUD operations
  - Objective generation
  - Data persistence
  - State management
- MainViewModel
  - User progression
  - Cross-pathway functionality
  - Global state management

## Testing
Comprehensive unit tests for:
- Pathway creation and initialization
- Cadence system integration
- Objective generation and management
- Deletion and cleanup
- Data persistence
- State management

## Future Considerations
- Achievement system
- Cross-pathway challenges
- Social features
- Advanced statistics