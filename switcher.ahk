#persistent
#usehook
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetBatchLines -1
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SLEEP_VAL := 500
DEBUG := false

;hotkey LWin & Left, take_me_home, on
;hotkey LWin & LAlt, take_me_home, on
;hotkey LControl & LShift, take_me_home, on
;hotkey LControl & 1, take_me_home, on
;hotkey XButton1, take_me_home, on
;hotkey XButton2, take_me_home, on

main()
bind()
return

Switch:
    Debug(A_ThisHotKey)

    if WinActive("ahk_class TscShellContainerClass") {
    	send {Ctrl down}{Alt down}{Home}{Alt up}{Ctrl up}
        sleep 500
    }

    switchToDesktop(SubStr(A_ThisHotKey, StrLen(A_ThisHotKey) - 1) - 1)
    unbind()
    bind()
Return

Debug(msg) {
    global DEBUG
    if (DEBUG) {
        tooltip %msg%
        settimer, TooltipClear, 2000
    }
}

switchToDesktop(idx)
{
	Debug(idx)
	global ppDesktopManager, IID_IVirtualDesktop

	DllCall(vtable(ppDesktopManager, 7), "Ptr", ppDesktopManager, "Ptr*", pDesktops)
	if (pDesktops) {
		DllCall(vtable(pDesktops, 4), "Ptr", pDesktops, "UInt", idx, "Ptr", &IID_IVirtualDesktop, "Ptr*", VirtualDesktop)
		if (VirtualDesktop) {
			DllCall(vtable(ppDesktopManager, 9), "Ptr", ppDesktopManager, "Ptr", VirtualDesktop)
			ObjRelease(VirtualDesktop) ; I assume these should be freed
		}
		ObjRelease(pDesktops)
	}
}

main()
{
	OnExit, cleanup

	OnMessage(DllCall("RegisterWindowMessage", Str, "TaskbarCreated"), "WM_TASKBARCREATED")

	static ImmersiveShell := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}")
	global IID_IVirtualDesktop, ppDesktopManager
	
	try ppDesktopManager := ComObjQuery(ImmersiveShell, "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}", "{f31574d6-b682-4cdc-bd56-1827860abec6}")
	if (!ppDesktopManager)
		ppDesktopManager := ComObjQuery(ImmersiveShell, "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}", "{AF8DA486-95BB-4460-B3B7-6E7A6B2962B5}")

	GUID(IID_IVirtualDesktop, "{FF72FFDD-BE7E-43FC-9C03-AD81681E88E4}")
	ObjRelease(ImmersiveShell)

	return

cleanup:
	if (ppDesktopManager)
		ObjRelease(ppDesktopManager)
	ExitApp
}

unbind()
{
	Debug("Unbind")
	Loop 9
		Hotkey LWin & %A_Index%, Switch, off
		;Hotkey LControl & %A_Index%, Switch, off
}
bind() {
	Debug("Bind")
	Loop 9
		Hotkey LWin & %A_Index%, Switch, on
		;Hotkey LControl & %A_Index%, Switch, on
}

WM_TASKBARCREATED()
{
    Reload
}

vtable(ptr, n) {
    ; NumGet(ptr+0) returns the address of the object's virtual function
    ; table (vtable for short). The remainder of the expression retrieves
    ; the address of the nth function's address from the vtable.
    return NumGet(NumGet(ptr+0), n*A_PtrSize)
}

GUID(ByRef GUID, sGUID) ; Converts a string to a binary GUID
{
    VarSetCapacity(GUID, 16, 0)
    DllCall("ole32\CLSIDFromString", "Str", sGUID, "Ptr", &GUID)
}

TooltipClear:
    tooltip
    settimer, TooltipClear, off
Return