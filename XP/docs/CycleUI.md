# Cycle UI Features

## Overview
The cycle UI system provides visual feedback about active objectives and cycle progress, helping users track their goals within each timeframe.

## Components

### Cycle Progress View
- Shows completion ratio (e.g., "2 of 3 completed this week")
- Animated progress bar
- Color-coded to match pathway theme
- Updates in real-time

### Objective Highlighting
- Glowing effect for active cycle objectives
- Maintains glow through entire cycle
- Shows completion state
- Visual hierarchy for active vs. inactive objectives

### Visual States
- Active & Incomplete: Glowing ring
- Active & Complete: Checkmark with glow
- Inactive: Standard appearance
- Current Task: "START" indicator

## Implementation Details

### Glow Effect
- Dynamic radius based on state
- Pathway color-matched
- Smooth animations
- Proper layering

### Progress Tracking
- Real-time updates
- Clear fraction display
- Timeframe-specific language
- Animated progress bar

### Best Practices
- Consistent visual language
- Clear state indication
- Responsive feedback
- Accessible design 