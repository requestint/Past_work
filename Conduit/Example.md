# Signal

#### Example: 
 Let's say you want one script to constantly post, and then one to possibly do a get request but once data found in the body of the URL
  you'll commit to an action with the provided decoded data of the body.
### 

## POST REQUESTING
```lua
-----------------------
----- [ Services ] ----
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

----------------------
----- [ Modules ] ----
local Conduit = require(path.to.your.Conduit)

--------------------
--- [ Variables ] --
local Destination = "YOUR-URL"
local Partition = Conduit.CreatePartition {
	Url = Destination,
	Method = "POST",
	ListenerName = "PostToPage",
}

local Connection = Conduit.new(Partition)

--------------------
--- [ Functions ] --
Players.PlayerAdded:Connect(function(plr)
	
	Connection:SetContent({
		['Content'] = plr.Name.." || Has Joined The Game 👋"
	})
	
	Connection:Post()
end)

Connection.Signals.OnSend:AddListener(function(response)
	print('Sent Response', response)
	
end)
```

## ON ACTION ON GET REQUEST:
```lua
-----------------------
----- [ Services ] ----
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

----------------------
----- [ Modules ] ----
local Conduit = require(path.to.your.Conduit)

--------------------
--- [ Variables ] --
local Destination = "YOUR-URL"
local Partition = Conduit.CreatePartition {
	Url = Destination,
	Method = "GET",
	ListenerName = "ReadPage",
}

local Connection = Conduit.new(Partition)

--------------------
--- [ Functions ] --
Connection.Signals.OnReceive:AddListener(function(...)
	--print('[Stream] -> PACKETS: ', ...)
	
	
	for index, packet in ... do
		
		print('[Stream] -> PACKET: ', packet)
	end
	
	Connection:SetCacheToBeRecycled(...)
end)

Connection.Signals.OnCacheRemoved:AddListener(function(...)
	print('[Stream] -> Cache Removed: ', ...)
end)

Connection.Signals.OnYield:AddListener(function()
	print('[Stream] -> Yielding')
end)

Connection:Start()

```