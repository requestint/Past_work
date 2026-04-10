# InputBinderService

#### Example:
Let's say you're building a combat game and you want a player to trigger a **Dash** 
when pressing `LB + RT`, and a **Heavy Attack** when pressing `LB + A` — without 
writing nested `IsKeyDown` checks on every frame yourself.

> **Note:** Input handling should always be done on the **client**.
> Place your script inside `StarterPlayerScripts` or a `LocalScript`.
###

## Ability Script

#### A LocalScript that registers InputBindings and responds when they're activated
```lua
------------------------
----- [ Services ] -----
local Players = game:GetService("Players")

-----------------------
----- [ Modules ] -----
local InputBinderService = require(path.to.InputBinderService)

------------------------
----- [ Variables ] ----
local Player = Players.LocalPlayer
local Controller = InputBinderService.new()

------------------------
----- [ Bindings ] -----

--- Single input — Light Attack
Controller:CreateInputConnection("LightAttack", "<A1>").OnBegan:AddListener(function()
   print(Player.Name .. " used Light Attack!")
end)

--- Two-key chord — Dash
Controller:CreateInputConnection("Dash", "<LB+RT>").OnBegan:AddListener(function()
   print(Player.Name .. " Dashed!")
end)

--- Three-key chord — Ultimate Ability
Controller:CreateInputConnection("Ultimate", "<LB+RB+A1>").OnBegan:AddListener(function()
   print(Player.Name .. " activated Ultimate!")
end)
```

## Cleanup Script

#### Disconnecting the controller when the player leaves or a round ends
```lua
-----------------------
----- [ Modules ] -----
local InputBinderService = require(path.to.InputBinderService)

------------------------
----- [ Variables ] ----
local Controller = InputBinderService.new()

------------------------
----- [ Functions ] ----

--- When the round ends, cleanly disconnect all bindings
local function OnRoundEnd()
   Controller:Disconnect()
   print("All input bindings disconnected.")
end
```
