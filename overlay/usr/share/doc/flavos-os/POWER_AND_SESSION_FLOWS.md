# Power, Logout, Suspend & Recovery Flows

This document details the architecture and operational flow for power and session management within Flavos OS.

## 1. Objective
Ensure a secure, consistent, and visually cohesive experience when locking, suspending, rebooting, or shutting down the system, across both X11 and future Wayland environments.

## 2. Component Roles

### 2.1 `flavos-shellctl` (The Middleware)
Centralizes all session-related commands. No frontend application should call `systemctl` or `loginctl` directly.
- **Routes:**
  - `session lock`: Delegates entirely to `flavos-lock`.
  - `session suspend`: Implements the `lock-before-suspend` logic.
  - `session logout`: Triggers `loginctl terminate-session` with a fallback to `openbox --exit` or `kill -TERM -1`.
  - `session reboot`: Calls `systemctl reboot`.
  - `session poweroff`: Calls `systemctl poweroff`.
- **Logs:** Records all session actions in `~/.local/share/flavos/logs/session-actions.log` using a strict `umask 077` for privacy.

### 2.2 `flavos-power` (The UI)
Provides the interactive GUI for the user.
- Contains inline confirmations for destructive actions (Logout, Reboot, Poweroff) to prevent accidental execution without creating multiple window popups.
- Routes all actions to `flavos-shellctl`.

### 2.3 `flavos-lock` (The Lock Guard)
Handles the visual locking mechanism.
- Provides an immediate visual block before suspension.

### 2.4 `flavos-settings` (The Control Panel)
Allows the user to trigger actions like "Suspender" from the graphical settings panel.
- Binds actions directly to `flavos-shellctl`.

## 3. Flow: Lock-Before-Suspend
To ensure the system is securely locked before the kernel enters the suspend state:
1. User or system triggers suspend (e.g., via `flavos-power` or ACPI button).
2. Action routed to `flavos-shellctl session suspend`.
3. `flavos-shellctl` invokes `flavos-lock &` (in the background).
4. `flavos-shellctl` sleeps for `1.5s` to allow the lock screen (X11 + compositor + screensaver) to fully render.
5. `flavos-shellctl` checks the `PID` of the lock process. If it failed prematurely, the suspend is aborted.
6. `flavos-shellctl` calls `systemctl suspend`.

## 4. How to Verify
- **Suspend:** Use `flavos-settings` -> Energia -> "Suspender" or press `XF86Sleep`. Observe the lock screen appearing before the system actually suspends.
- **Logout/Reboot/Poweroff:** Open the power menu via `Ctrl+Alt+Del`, click a destructive action, verify the inline confirmation appears, and then confirm or cancel via button or `Esc`.
- **Logs:** Check `~/.local/share/flavos/logs/session-actions.log` for execution records.
