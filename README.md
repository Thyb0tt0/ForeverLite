# ForeverLite

ForeverLite is a lightweight collection of optional UI and quality-of-life improvements for WoW Forever.

The addon is designed around a simple rule: features should be useful, unobtrusive, and opt-in wherever practical.

## Features

### Nameplates

- Optional health text on hostile and attackable nameplates
- Remaining health, percentage, or both
- Left or centered health text
- Option to keep the selected nameplate at normal size instead of the default enlarged scale

### Experience

- Lightweight movable XP tracker
- Session XP per hour
- Estimated time to level
- Session duration
- Option to always show Blizzard's XP bar text

### Vendor

- Automatically repair equipment using your own money
- Automatically sell gray-quality junk

### Tooltips

- Optional class coloring for player names in tooltips

### Buff Reminders

Optional missing-buff reminders for supported classes.

Reminders are intentionally simple and only show when a relevant buff, weapon imbue, pet, or similar class maintenance effect is missing.

## Commands

`/fl`  
Open or close the ForeverLite menu.

`/fl settings`  
Open ForeverLite in Blizzard's AddOn Settings.

`/fl help`  
Show available commands.

`/fl health`  
Toggle nameplate health text.

`/fl xp`  
Toggle the XP tracker.

`/fl xp reset`  
Reset the current XP session.

`/fl xp unlock`  
Unlock the XP tracker for movement.

`/fl xp lock`  
Lock the XP tracker.

`/fl xp center`  
Reset the XP tracker position.

`/fl reminders unlock`  
Unlock the reminder display for movement.

`/fl reminders lock`  
Lock the reminder display.

`/fl reminders center`  
Reset the reminder display position.

## Configuration

ForeverLite can be configured through either:

- `/fl`
- Blizzard's AddOn Settings menu

Most features are disabled by default.

## Installation

1. Download ForeverLite.
2. Extract the `ForeverLite` folder into:

   `World of Warcraft\_classic_beta_\Interface\AddOns\`

3. Restart WoW or reload the UI.

## Compatibility

ForeverLite is developed for WoW Forever.

It is designed to cooperate with Blizzard's UI systems rather than replace them. Some features may also work alongside UI addons such as ClassicUI Forever.

## Notes

WoW Forever restricts access to some aura information during combat. ForeverLite's buff reminders are designed around those restrictions and avoid repeatedly showing incorrect warnings while combat is in progress.

## License

ForeverLite is released under the MIT License.
