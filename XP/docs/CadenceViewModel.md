# Cadence ViewModel

## Overview
The CadenceViewModel manages the lifecycle and data operations for pathway cadences, handling cycle creation, updates, and resets.

## Key Responsibilities

### Cycle Management
- Creating new cycles
- Ending active cycles
- Checking for resets
- Selecting objectives

### Data Operations
- Fetching cycle objectives
- Managing cycle state
- Handling transitions
- Maintaining data integrity

### Lifecycle Events
- App state monitoring
- Automatic resets
- State synchronization
- UI updates

## Implementation Details

### Cycle Creation Process
1. End current cycle if exists
2. Calculate dates based on frequency
3. Select appropriate objectives
4. Save new cycle state

### Reset Handling
1. Check for expired cycles
2. End expired cycles
3. Create new cycles if needed
4. Update UI state

### Objective Selection
1. Find existing incomplete objectives
2. Create new objectives if needed
3. Assign to current cycle
4. Maintain proper ordering

## Best Practices

### State Management
- Clean transitions
- Data consistency
- Error handling
- UI synchronization

### Performance
- Efficient queries
- Batch updates
- Minimal UI updates
- Resource management

### Error Handling
- Graceful degradation
- User feedback
- Data recovery
- State consistency 