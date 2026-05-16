This mod adds a settings tab to Noctalia (a customizable desktop panel/shell for Linux) that lets you change the look of two things right from one place:

1. Your terminal colors (the background, text, and 16 ANSI colors) — with a color picker and preset system

2. Your window manager theme — specifically the focus rings, borders, and tab indicator colors used by Niri
It also adds a toggle for rounded window corners and a gradient effect on the active window border, with scripts that apply the changes live.


Noctalia Extended — v003


File |	Purpose

.config/niri/noctalia.kdl	Niri theme: focus ring, borders, shadows, tab indicators — GitHub Dark-inspired blue/black palette with optional gradient

.config/niri/noctalia-windows.kdl	Applies 12px rounded corners and clipping to all Niri windows

.config/noctalia/settings.json	Main Noctalia shell config: bar layout, widgets, dock, launcher, notifications, OSD, audio, wallpaper, color schemes, desktop widgets, lock screen, idle, keybinds

quickshell/.../shell.qml	Noctalia shell entry point — initializes all services and loads UI components

quickshell/.../Commons/Settings.qml	Settings engine: loads/saves settings.json, runs versioned migrations, per-screen bar overrides, widget validation

quickshell/.../Services/RoundingService.qml	Polls noctalia-windows.kdl to sync window rounding state

quickshell/.../Scripts/toggle-niri-gradient.sh	Toggles Niri focus ring gradient on/off by editing noctalia.kdl

quickshell/.../Scripts/toggle-niri-window-rounding.sh	Toggles window corner rounding by adding/removing the window rule include

quickshell/.../Settings/.../ExtendedTab.qml	Extended settings tab with sub-tabs (Terminal Colors, Niri, Colors)

quickshell/.../Settings/.../NiriColorsSubTab.qml	GUI to edit Niri colors (focus ring, borders, indicators) from the settings panel

quickshell/.../Settings/.../ColorsSubTab.qml	GUI to edit Noctalia UI accent/theme colors

quickshell/.../Settings/.../TerminalColorsSubTab.qml	GUI to edit terminal colors — currently writes Alacritty TOML

quickshell/.../Settings/.../PlaceholderSubTab.qml	Toggle for Niri Focus Ring Gradient + placeholder for future settings
