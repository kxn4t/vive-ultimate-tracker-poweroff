;==============================================================================
; PowerOffViveTrackers.ahk  (AutoHotkey v2)
;
; Turns off all VIVE Ultimate Trackers in one action by automating VIVE Hub
; via UI Automation. VIVE Hub has no public API or command line for this,
; so the script opens the settings window, selects the
; "VIVE Tracker (Ultimate)" tab, clicks "Turn off all", and accepts the
; confirmation dialog. Run it directly (double-click) or launch it from a
; Stream Deck "System: Open" action.
;
; Flow:
;   1. Find the VIVE Hub window (launch it if not running)
;   2. Open the settings window from the gear menu if it is not already open
;   3. Select the "VIVE Tracker (Ultimate)" tab
;   4. Click "Turn off all" (if disabled, all trackers are already off)
;   5. Click "Turn off" in the confirmation dialog
;   6. Close the settings window again if this script opened it
;
; Buttons are located by AutomationId (e.g. oetTurnOffAllBtn), not screen
; coordinates, so window position, size, and DPI do not matter.
;
; If a VIVE Hub update changes the UI and elements can no longer be found,
; run the script with the argument "dump" to export all UI elements of
; VIVE Hub, then update the AutomationIds / regexes in the settings below.
;==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\UIA.ahk

;========================= Settings (edit if needed) =========================

; Path to the VIVE Hub executable (VHConsole.exe)
EXE_PATH := A_ProgramFiles "\VIVE Hub\VIVE Hub\VHConsole\VHConsole.exe"

; AutomationIds of UI elements (verified with VIVE Hub 2.5.6)
ID_MAIN_WINDOW     := "VHConsoleMainWindow"   ; main window
ID_SETTINGS_WINDOW := "SettingsWindow"        ; settings window
ID_MENU_GEAR       := "menuBtn"               ; gear button
ID_MENU_SETTINGS   := "mainMenuSettings"      ; "Settings" in the gear menu
ID_SETTINGS_TABS   := "Settings_TabControl"   ; left navigation in settings
ID_TURN_OFF_ALL    := "oetTurnOffAllBtn"      ; "Turn off all" button
ID_TRACKER_COUNTER := "oetCounterTb"          ; "Currently tracking n / m"
ID_SETTINGS_CLOSE  := "Settings_Close_Button" ; close button of the settings window

; Name-based fallback regexes (match both Japanese and English UI)
TRACKER_TAB_REGEX  := "VIVE\s*(トラッカー|Tracker)\s*\(Ultimate\)"
TURN_OFF_ALL_REGEX := "i)^(すべてオフにする|全てオフにする|Turn\s*off\s*all.*)$"
CONFIRM_REGEX      := "i)^(オフにする|Turn\s*off|Power\s*off|OK)$"

; Timeouts (milliseconds)
LAUNCH_TIMEOUT   := 30000  ; waiting for VIVE Hub to launch
SETTINGS_TIMEOUT := 10000  ; waiting for the settings window to open
BUTTON_TIMEOUT   := 8000   ; waiting for "Turn off all" to appear
ENABLED_TIMEOUT  := 4000   ; grace period for the button to become enabled
CONFIRM_TIMEOUT  := 8000   ; waiting for the confirmation dialog
VERIFY_TIMEOUT   := 12000  ; waiting for the tracking count to reach 0

;============================================================================

; User-facing messages: Japanese on a Japanese OS, English otherwise
if (A_Language = "0411") {
    T := Map(
        "title",          "VIVEトラッカー電源オフ",
        "hubNotFound",    "VIVE Hub が見つかりませんでした。`nスクリプト内の EXE_PATH を確認してください。",
        "hubNoWindow",    "VIVE Hub を起動しましたが、ウィンドウが表示されませんでした。",
        "mainWinFail",    "VIVE Hub のメインウィンドウが取得できませんでした。",
        "menuFail",       "設定メニューを開けませんでした。`ndump モードでUI要素を確認してください。",
        "settingsFail",   "設定ウィンドウが開きませんでした。",
        "offBtnFail",     "「すべてオフにする」ボタンが見つかりませんでした。`ndump モードでUI要素を確認してください。",
        "alreadyOff",     "接続中のトラッカーがありません（すでにすべてオフ）",
        "confirmFail",    "確認ダイアログの「オフにする」ボタンが見つかりませんでした。`nダイアログが表示されたままの場合は手動で操作してください。",
        "done",           "全トラッカーの電源をオフにしました",
        "doneUnverified", "電源オフを実行しました（完了確認はタイムアウト）"
    )
} else {
    T := Map(
        "title",          "VIVE Tracker Power Off",
        "hubNotFound",    "VIVE Hub was not found.`nCheck EXE_PATH in the script.",
        "hubNoWindow",    "VIVE Hub was launched, but its window did not appear.",
        "mainWinFail",    "Could not get the VIVE Hub main window.",
        "menuFail",       "Could not open the settings menu.`nRun in dump mode to inspect the UI elements.",
        "settingsFail",   "The settings window did not open.",
        "offBtnFail",     "The `"Turn off all`" button was not found.`nRun in dump mode to inspect the UI elements.",
        "alreadyOff",     "No trackers are connected (everything is already off)",
        "confirmFail",    "The `"Turn off`" button in the confirmation dialog was not found.`nIf the dialog is still open, please confirm it manually.",
        "done",           "All trackers have been powered off",
        "doneUnverified", "Power-off was executed (verification timed out)"
    )
}

SetTitleMatchMode 2
APP_EXE := "ahk_exe VHConsole.exe"

Fail(msg) {
    MsgBox msg, T["title"], "Iconx"
    ExitApp 1
}

; Find the VHConsole window whose root element has the given AutomationId
FindWindowByRootId(autoId) {
    for w in WinGetList(APP_EXE) {
        try {
            root := UIA.ElementFromHandle(w)
            if (root.AutomationId = autoId)
                return {hwnd: w, el: root}
        }
    }
    return ""
}

; Search all VHConsole windows for a matching button (for the confirm dialog)
FindButtonAnywhere(nameRegex) {
    for w in WinGetList(APP_EXE) {
        try {
            root := UIA.ElementFromHandle(w)
            btn := root.FindElement({Type: "Button", Name: nameRegex, matchmode: "RegEx"})
            if btn
                return btn
        }
    }
    return ""
}

;--- 1. Ensure the VIVE Hub main window exists -------------------------------
if !WinExist("VIVE Hub " APP_EXE) {
    ; Hidden in the tray or not running -> running the exe shows the window
    if !FileExist(EXE_PATH)
        Fail(T["hubNotFound"] "`n" EXE_PATH)
    Run '"' EXE_PATH '"'
    if !WinWait("VIVE Hub " APP_EXE, , LAUNCH_TIMEOUT / 1000)
        Fail(T["hubNoWindow"])
}

;--- Dump mode: export the UI element tree of every VIVE Hub window ----------
if A_Args.Length && (A_Args[1] = "dump") {
    out := A_ScriptDir "\vivehub_elements.txt"
    try FileDelete out
    for w in WinGetList(APP_EXE) {
        FileAppend "===== hwnd=" w " title=" WinGetTitle(w) " =====`n", out, "UTF-8"
        try FileAppend UIA.ElementFromHandle(w).DumpAll() "`n", out, "UTF-8"
    }
    Run 'notepad.exe "' out '"'
    ExitApp
}

;--- 2. Ensure the settings window is open (open it via the menu if not) -----
settingsWasOpen := true
settings := FindWindowByRootId(ID_SETTINGS_WINDOW)
if !settings {
    settingsWasOpen := false
    mainWin := FindWindowByRootId(ID_MAIN_WINDOW)
    if !mainWin
        Fail(T["mainWinFail"])
    WinActivate mainWin.hwnd
    WinWaitActive mainWin.hwnd, , 3

    ; The menu items live in the UIA tree permanently, so Invoke works directly
    opened := false
    try {
        mainWin.el.FindElement({AutomationId: ID_MENU_SETTINGS}).Click()
        opened := true
    }
    if !opened {
        ; Fallback: open the gear menu first, then click "Settings"
        try {
            mainWin.el.FindElement({AutomationId: ID_MENU_GEAR}).Click()
            Sleep 400
            mainWin.el.FindElement({AutomationId: ID_MENU_SETTINGS}).Click()
        } catch {
            Fail(T["menuFail"])
        }
    }
    deadline := A_TickCount + SETTINGS_TIMEOUT
    while !(settings := FindWindowByRootId(ID_SETTINGS_WINDOW)) {
        if (A_TickCount > deadline)
            Fail(T["settingsFail"])
        Sleep 200
    }
}
WinActivate settings.hwnd
WinWaitActive settings.hwnd, , 3

;--- 3. Select the "VIVE Tracker (Ultimate)" tab -----------------------------
try {
    tabs := settings.el.FindElement({AutomationId: ID_SETTINGS_TABS})
    tabs.FindElement({Type: "TabItem", Name: TRACKER_TAB_REGEX, matchmode: "RegEx"}).Click()
    Sleep 400
} catch {
    ; Even if the tab cannot be selected, the button exists in the tree, so continue
}

;--- 4. Click "Turn off all" -------------------------------------------------
offBtn := ""
try offBtn := settings.el.WaitElement({AutomationId: ID_TURN_OFF_ALL}, BUTTON_TIMEOUT)
if !offBtn {
    ; Fall back to a name-based search in case the AutomationId changed
    try offBtn := settings.el.WaitElement(
        {Type: "Button", Name: TURN_OFF_ALL_REGEX, matchmode: "RegEx"}, 2000)
}
if !offBtn
    Fail(T["offBtnFail"])

; The button is disabled when no trackers are connected. It can also be
; disabled briefly right after the page is shown, so wait and re-check
deadline := A_TickCount + ENABLED_TIMEOUT
while !offBtn.IsEnabled {
    if (A_TickCount > deadline) {
        if !settingsWasOpen {
            try settings.el.FindElement({AutomationId: ID_SETTINGS_CLOSE}).Click()
        }
        TrayTip T["alreadyOff"], T["title"], "Mute"
        Sleep 2000
        ExitApp
    }
    Sleep 250
    try offBtn := settings.el.FindElement({AutomationId: ID_TURN_OFF_ALL})
}

try
    offBtn.Click()          ; click via the UIA Invoke pattern
catch
    offBtn.ControlClick()   ; fall back to a physical click

;--- 5. Click "Turn off" in the confirmation dialog --------------------------
confirmed := false
deadline := A_TickCount + CONFIRM_TIMEOUT
while (A_TickCount < deadline) {
    confirmBtn := FindButtonAnywhere(CONFIRM_REGEX)
    if confirmBtn {
        try {
            confirmBtn.Click()
            confirmed := true
        } catch {
            try {
                confirmBtn.ControlClick()
                confirmed := true
            }
        }
        break
    }
    Sleep 200
}
if !confirmed
    Fail(T["confirmFail"])

;--- 6. Verify power-off (wait until the tracking count reaches 0) -----------
verified := false
deadline := A_TickCount + VERIFY_TIMEOUT
while (A_TickCount < deadline) {
    try {
        counter := settings.el.FindElement({AutomationId: ID_TRACKER_COUNTER})
        if RegExMatch(counter.Name, "^\s*0\s*/") {
            verified := true
            break
        }
    }
    Sleep 500
}

; Close the settings window again if this script opened it
if !settingsWasOpen {
    try settings.el.FindElement({AutomationId: ID_SETTINGS_CLOSE}).Click()
}

if verified
    TrayTip T["done"], T["title"], "Mute"
else
    TrayTip T["doneUnverified"], T["title"], "Mute"
Sleep 2500
ExitApp
