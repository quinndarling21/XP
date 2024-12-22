# Cycle Management System

## Overview
The cycle management system handles the automatic transitions between cadence cycles, ensuring objectives are properly reset and tracked according to their defined timeframes.

## Key Components

### CadenceManager
Singleton class responsible for:
- Checking cycle expiration
- Creating new cycles
- Generating objectives
- Calculating reset dates

### Cycle Transitions
- Automatic checks on app launch/resume
- Clean transition between cycles
- Preservation of historical data
- Generation of new objectives

### Reset Timing
- Daily: Midnight local time
- Weekly: Monday at midnight
- Monthly: First of month at midnight

## Implementation Details

### Cycle Checking Process
1. App becomes active
2. Check all pathways with active cycles
3. Identify expired cycles
4. Create new cycles as needed
5. Generate new objectives

### Date Calculations
- Uses Calendar for consistent date math
- Handles timezone considerations
- Maintains proper week/month boundaries

### Error Handling
- Graceful handling of date calculation edge cases
- Proper context management
- Error logging and recovery

## Best Practices
- Regular cycle checks
- Clean state transitions
- Proper objective generation
- Data consistency maintenance 