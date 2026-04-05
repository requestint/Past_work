# Signal

#### Example: 
 Let's say you want to have a signal to act as your debug logger, and whenever it log's it posts to a discord webhook.
  with the given webhook Url 

  DO NOT PUT SENSITIVE INFORMATION AND/OR CODE ANYWHERE WHERE THE PLAYER CAN SEE (ex ReplicatedStorage, Workspace, e.g).
  typically these would be put in ServerScriptService
### 

## Event Script
```lua
--------------------
--- [ Services ] ---
local HttpService = game:GetService("HttpService")

--------------------
--- [ Modules ] ---
local SignalModule = require(path.to.Signal)

--------------------
--- [ Varibles ] ---
local Connection: SignalModule.Listener
local Signal = SignalModule.new("Log")

---------------------
--- [ Functions ] ---

--- Enabling HTTP
game.HttpEnabled = true

--- Creating Connection
Connection = Signal:AddListener(function(Wehbook: string, Log: {[string]: any})
   --- Varibles
   local Json = HttpService:JSONEncode(Log)
   local success, result 

   --- Wrap the PostAsync In a Pcall incase it fails
   success, result = Pcall(function()
      HttpService:PostAsync(Wehbook, Json)
   end)

   if success then
      print("Successfully sent Log to Destination")
   end
end)

```
## Logger Script


#### The Script that will fire the log to mention whenever a player joined
```lua
--------------------
--- [ Services ] ---
local Players = game:GetService("Players")

--------------------
--- [ Modules ] ---
local SignalModule = require(path.to.Signal)

--------------------
--- [ Varibles ] ---
local webhookURL = "YOUR-URL"
local Connection: SignalModule.Listener
local Signal = SignalModule.new("Log")

---------------------
--- [ Functions ] ---
Players.PlayerAdded:Connect(function(player: Player)
   --- Varibles
   local Content = {
      ['content'] = player.Name.. " Has Joined The Game!"
   }

   Signal:Fire(webhookURL, Content)
end)
```