# Dragkest Server Hopper

Lua UI script for Roblox executors (including many Android/Termux setups).

## Features

- Private server URL support (`privateServerLinkCode`) for Roblox.
- Duration sequence system:
  - add duration,
  - edit duration inline,
  - remove duration.
- Start/Stop toggle for the hopper loop.
- Animated progress bar + live countdown text for next server hop.
- Public-server fallback if private URL is missing/invalid.

## How to use

1. Execute `Main.lua` (or `hopper.lua`) in your executor.
2. Paste your Roblox private server URL in the UI.
3. Add one or more durations in seconds (minimum `5`).
4. Click **Start**.
5. Click **Stop** any time to pause the sequence.

## Notes

- Private URL format should include `privateServerLinkCode=...`.
- If private URL is not valid, the script will try a public server hop.
