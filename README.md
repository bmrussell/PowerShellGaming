# POWERSHELL GAMING UTILITIES

## Play-Game
Temporarily optimise Windows to launch a game and return to previous settings when done. Useful when running games over nVidia or Sunshine streaming at different resolutions.

1. Sets power plan
2. Changes screen resolution (I'm looking at you Starfield 👀)
3. Turnms HDR on ([HDR Switch](Needs https://github.com/bradgearon/hdr-switch))
3. Stops useless services (Needs for the user to have the rights. See `Grant-ServiceStopStart.ps1`)
4. Waits for game to finish
5. Returns settings to previous values

### Example
```powershell
pwsh -Command "Play-Game.ps1 -Launch '"C:\Users\brian\OneDrive\Desktop\Starfield.lnk"' -Name 'Starfield' -Plan 'GameTurbo (High Performance)' -Wait 10 -Width 1920 -Height 1080 -HDR -Trace - StopServices"
```

## Get-Powerplan
Get the power plans configured for the local machine. Either the active  plan or a list of all plans

## Set-Powerplan
Sets the power plan for the local machine given the name

## Grant-ServiceStopStart.ps1
Grants the curent user Start/Stop on selected services. Run elevated. Services are pipe seperate list of service names in `USER_STOPPABLE_SERVICES` environment variable. e.g. `AdobeARMservice|AdobeUpdateService|ClickToRunSvc`