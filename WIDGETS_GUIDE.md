# Mobile Widgets

This app now includes three home screen widgets that you can add to your Android or iOS home screen.

## Available Widgets

### 1. Note Widget
- **Description**: Displays your most recently updated note in view mode
- **Features**:
  - Shows note title and content preview (up to 500 characters)
  - Black background with 30% transparency for elegant look
  - Tap to open the note in the app
  - Auto-updates every 30 minutes
- **Size**: Medium to Large (resizable)

### 2. Habit Tracker Widget
- **Description**: Shows today's habit completion status at a glance
- **Features**:
  - Displays completed vs total habits count
  - Shows progress bar visualization
  - Lists up to 5 habits with checkmark indicators (✓ = completed, ○ = pending)
  - Black background with 30% transparency
  - Tap to open habits page
  - Auto-updates every 15 minutes
- **Size**: Medium (resizable)

### 3. Quick Note Widget
- **Description**: Quick access button to create a new note
- **Features**:
  - Shows total note count
  - Large + icon for easy access
  - Black background with 30% transparency
  - Tap to create a new note instantly
  - Auto-updates every hour
- **Size**: Small (1x1 or 2x2)

## How to Add Widgets (Android)

1. Long-press on your home screen
2. Tap "Widgets" from the menu
3. Scroll to find "skadoosh_app"
4. Choose from:
   - Note Widget
   - Habit Tracker Widget
   - Quick Note Widget
5. Drag the widget to your desired location
6. Resize if needed (Note and Habit widgets are resizable)

## How to Add Widgets (iOS)

1. Long-press on your home screen until icons jiggle
2. Tap the "+" button in the top corner
3. Search for "skadoosh"
4. Choose from the available widget sizes
5. Tap "Add Widget"
6. Position the widget and tap "Done"

## Widget Design

All widgets feature:
- **Background**: Black with 70% opacity (30% transparent) for a sleek, modern look
- **Text Colors**: White primary text, gray secondary text for readability
- **Rounded Corners**: 16dp border radius for modern aesthetics
- **Automatic Updates**: Widgets update automatically at different intervals
- **Click Actions**: Each widget opens relevant sections of the app

## Updating Widgets

Widgets automatically update when:
- Notes are created, modified, or deleted
- Habits are completed or uncompleted
- App is opened or closed
- At regular intervals (15-60 minutes depending on widget type)

You can also manually update by:
- Opening the app (updates all widgets)
- Tapping on a widget (updates that specific widget)

## Technical Details

- Built using the `home_widget` Flutter package (v0.6.0)
- Widget data is stored locally and synchronized with the app
- Minimal battery impact with efficient update scheduling
- Works offline - displays last known data when offline
