# vive-ultimate-tracker-poweroff

![Platform: Windows](https://img.shields.io/badge/platform-Windows-0078D6)
![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-334455)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

[日本語](README.ja.md)

Turn off **all your VIVE Ultimate Trackers at once** — just run a single file.

VIVE Hub has no official API or command line to power off trackers, so this
AutoHotkey v2 script automates VIVE Hub through UI Automation and clicks the
power-off button for you. Assign it to a Stream Deck button and it becomes a
true one-press "trackers off" switch.

## How it works

Running the script performs all of the following automatically, regardless of
the current window state of VIVE Hub:

1. Finds the VIVE Hub window. **If VIVE Hub is not running, no trackers can
   be connected, so the script just notifies you and exits**
2. If the settings window is not open, **opens it via the gear menu**
3. Selects the "VIVE Tracker (Ultimate)" tab
4. Clicks "Turn off all"
   - If the button is disabled (= no trackers connected), notifies you that
     everything is already off and exits normally
5. **Accepts the confirmation dialog automatically**
6. Waits until the tracking count reaches 0 and shows a notification
7. Closes the settings window again if the script opened it itself

Buttons are located by AutomationId (e.g. `oetTurnOffAllBtn`), not screen
coordinates, so window position, size, and DPI do not matter (verified with
VIVE Hub 2.5.6). Both the Japanese and English VIVE Hub UI are supported.

## Requirements

- Windows
- [VIVE Hub](https://www.vive.com/) with VIVE Ultimate Trackers set up
  (verified with VIVE Hub 2.5.6)
- [AutoHotkey](https://www.autohotkey.com/) **v2** — only for the script
  version; the pre-built exe needs no AutoHotkey installation

## Setup

### Option A: pre-built exe (easiest)

1. Download the latest `vive-ultimate-tracker-poweroff-vX.Y.Z.zip` from
   [Releases](https://github.com/kxn4t/vive-ultimate-tracker-poweroff/releases)
2. Extract it and place the folder anywhere you like

> [!NOTE]
> Compiled AutoHotkey executables are occasionally flagged by antivirus
> software or SmartScreen as false positives. The full source code is public
> in this repository — if in doubt, use the script version below instead.

### Option B: run the script directly

1. Install AutoHotkey **v2** from https://www.autohotkey.com/ (v1 will not
   work)
2. Download this repository (Code → Download ZIP and extract it, or
   `git clone`) and place the folder anywhere you like. Keep `UIA.ahk` in
   the same folder as `PowerOffViveTrackers.ahk`

## Usage

With your trackers powered on, double-click `PowerOffViveTrackers.exe`
(or `PowerOffViveTrackers.ahk` for the script version). It proceeds through
the confirmation dialog automatically; if the trackers turn off, you are
done.

### Optional: pin it to the taskbar

- **exe version**: right-click `PowerOffViveTrackers.exe` → "Pin to taskbar"
  (on Windows 11 it is under "Show more options")
- **script version**: `.ahk` files cannot be pinned directly. Create a
  shortcut whose target is
  `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Tools\vive-ultimate-tracker-poweroff\PowerOffViveTrackers.ahk"`
  and pin that shortcut instead

### Optional: assign it to a Stream Deck button

1. In the Stream Deck app, drag a **"System" → "Open"** action onto a button
2. Set "App/File" to the full path of `PowerOffViveTrackers.exe`
   (for the script version, use the `.ahk` path; if the `.ahk` file
   association does not work, launch it via AutoHotkey64.exe as shown in the
   taskbar section above)
3. Set an icon and title as you like — done

## Troubleshooting (dump mode)

A VIVE Hub update may change AutomationIds or label texts, causing elements
to no longer be found. In that case:

1. Run it with the `dump` argument from a command prompt:
   ```
   PowerOffViveTrackers.exe dump
   ```
   (script version:
   `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Tools\vive-ultimate-tracker-poweroff\PowerOffViveTrackers.ahk" dump`)
2. `vivehub_elements.txt` opens in Notepad. Search for the target button's
   `AutomationId:` or `Name:` (searching for "off" with Ctrl+F is a quick way)
3. Update the corresponding ID / regex in the "Settings" section at the top
   of the script and run the script version. If you use the exe, please open
   an issue so a fixed release can be published

Note: dump mode exports every VIVE Hub window (main + settings). To inspect
the settings window, run it while the settings screen is open.

## Configuration

All settings live at the top of the script:

- `ID_*` … AutomationIds of the UI elements (verified with VIVE Hub 2.5.6)
- `*_REGEX` … name-based fallback regexes (match both Japanese and English UI)
- `*_TIMEOUT` … timeout for each step

## Notes

- This is UI automation, so a VIVE Hub update that changes the UI may require
  adjustments (re-check with dump mode)
- The VIVE Hub window briefly comes to the foreground while the script runs
- When no trackers are connected, the "Turn off all" button itself is
  disabled; in that case the script only shows a notification and exits
- Notifications and error messages are shown in Japanese on a Japanese OS and
  in English otherwise

## License

MIT License — see [LICENSE](LICENSE).

The bundled `UIA.ahk` is a third-party library
([Descolada/UIA-v2](https://github.com/Descolada/UIA-v2)) and is licensed
separately under the MIT License — see [LICENSE-UIA](LICENSE-UIA).

The pre-built exe on the Releases page additionally embeds the AutoHotkey v2
runtime, which is licensed under the GNU General Public License v2 — see
[LICENSE-AutoHotkey](LICENSE-AutoHotkey).
