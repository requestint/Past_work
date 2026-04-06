----------------------
---- [ Services ] ----
local HttpService = game:GetService("HttpService")

----------------------
---- [ Varibles ] ----
local CacheLifeTime = 6
local TimeBeforeCacheable = 3

----------------------
---- [ Modules ] ----
local Signal = require("./Signal")

--------------------
---- [ Tables ] ----
local Conduit = {}
local CachingPool = {}

Conduit.__index = Conduit
Conduit.Saved = {}
Conduit.Constants = {
	MaxListeners = 8,
	Total_Http_requests = 0,
}

--------------------
---- [ Types ] ----
type Listener = typeof(Conduit) & ConduitPartition
type SignalType = Signal.Signal
type HttpAcceptable = {
	[string | number]: string,
}

type HttpCache = {
	Url: string,
	PullTime: number,
	Cache: { HttpAcceptable },
}

type ConduitPartition = {
	Url: string,
	Method: string,

	Request_count: number?,
	LastRefreshTime: number?,
	Pending: boolean?,

	ListenerName: string,
	Signals: { [string]: SignalType },
}

-----------------------
---- [ Functions ] ----
local function GetListener(ListenerName: string)
	for index, listener in pairs(Conduit.Saved) do
		if listener.ListenerName:lower() == ListenerName:lower() then
			return listener
		end
	end
end

local function GetListenerCount(): number
	local Count = 0

	for index, listener in Conduit.Saved do
		Count += 1
	end

	return Count
end

local function getDef(): ConduitPartition
	return {
		Url = "",
		Method = "",
		ListenerName = "",
		Signals = {},
	}
end

local function strictArgs(ArgsToCheck, Default): boolean
	for Key, Value in Default do
		if not ArgsToCheck[Key] then
			return true
		end
	end

	return false
end

local function DeleteOldCache(Parition: ConduitPartition)
	--- Vaildation
	if not Parition then
		return error("You Forgot To Pass The Arguement For Partition")
	end
	if not CachingPool[Parition.Url] then
		return error(
			string.format(
				"Partition %s Failed To DeleteOldCache, Error: %s",
				Parition.ListenerName,
				"Failed To Find Link To Listener's Cache"
			)
		)
	end

	--- Varibles
	local InspectedCache

	--- Scaverging Through Cache
	for index: number, current_cache: HttpCache in CachingPool[Parition.Url] do
		if tick() - current_cache.PullTime >= CacheLifeTime then
			InspectedCache = table.remove(CachingPool[Parition.Url], index)

			if Parition.Method ~= "POST" and Parition.Signals.OnCacheRemoved ~= nil then
				Parition.Signals.OnCacheRemoved:Fire(InspectedCache)
			else
				print(Parition.Signals)
			end

			break
		end

		continue
	end
end

function CacheCanBeAcknowladged(Partition: Listener)
	--- Vaildation
	if not Partition then
		return error("You Forgot To Pass The Arguement For Partition")
	end
	if not CachingPool[Partition.Url] then
		return error(
			string.format(
				"Partition %s Failed To DeleteOldCache, Error: %s",
				Partition.ListenerName,
				"Failed To Find Link To Listener's Cache"
			)
		)
	end

	--- Going Through the Cache to see if there's any cache that can be re-used
	for index: number, current_cache: HttpCache in CachingPool[Partition.Url] do
		if tick() - current_cache.PullTime < 10 and tick() - current_cache.PullTime > TimeBeforeCacheable then
			return true
		end

		continue
	end

	return false
end

local function IsConduitBlocked(Partition: Listener): boolean
	--- Checking Conditions for possible issues that may arise that would
	-- suggest putting the current class / Partition on hold
	if Partition.Pending then
		Partition.Signals.OnYield:Fire("Await for pending response to complete.")

		return true, "Await for pending response, to append to partition"
	end

	if math.clamp(Conduit.Constants.Total_Http_requests, 0, math.floor(500/GetListenerCount())) == math.floor(500/GetListenerCount()) then
		Partition.Signals.OnYield:Fire(
			"We've reached the max amount of applical requests per minute. Please wait atleast a minute before making another request."
		)

		return true, "You have reached the maxiumum amount of requests per minute"
	end

	return false
end

local function getSigsViaMeth(Method: string): { [string]: SignalType }
	if string.upper(Method) == "GET" then
		return {
			OnReceive = Signal.new("OnReceive"),
			OnYield = Signal.new("OnYield"),
			OnCacheRemoved = Signal.new("OnCacheRemoved"),
		}
	else
		return {
			OnSend = Signal.new("OnSend"),
			OnYield = Signal.new("OnYield"),
		}
	end
end

function Conduit.CreatePartition(PartitionInfo: ConduitPartition): ConduitPartition
	--- Varibles
	local PartitionSignals = getSigsViaMeth(PartitionInfo.Method)
	local Partition: ConduitPartition = {
		Request_count = 0,
		LastRefreshTime = tick(),
		Pending = false,

		Url = PartitionInfo.Url,
		Method = PartitionInfo.Method,
		ListenerName = PartitionInfo.ListenerName,
		Signals = PartitionSignals,
	}

	return Partition
end

function Conduit.new(Partition: ConduitPartition): Listener
	--- Vaildation
	-- Checking for missing Arguments
	if strictArgs(Partition, getDef()) then
		return error("[Stream] -> Attempted to make an open socket with missing arguements!")
	end

	-- Seaking for a matching existing port, if there's one we'll overwrite it
	if GetListener(Partition.ListenerName) then
		return GetListener(Partition.ListenerName):Reset()
	end

	--- Checking if we have the max con-current Streams
	if GetListenerCount() >= Conduit.Constants.MaxListeners then
		error(`[Conduit] -> {table.concat({ true, "You have reached the maxiumum amount of listeners" }, " | ", 2, 2)}`)
	end

	Conduit.Saved[Partition.ListenerName] = setmetatable(Partition, Conduit)

	--- returning the new listener
	return setmetatable(Partition, Conduit)
end

function Conduit:SetContent(Content: { [string]: any })
	--- Vaildation
	if getmetatable(self) ~= Conduit then
		error("Expected self to be a Conduit, got " .. typeof(self))
	end

	if self.Method:upper() ~= "POST" then
		error("[Conduit] -> Attempted to set content on a GET request!")
	end

	--- Varibles
	local JsonContent = HttpService:JSONEncode(Content)

	--- we'll now set the content within self
	self.ContentToPush = JsonContent
end

function Conduit:PullFromCache()
	--- Varibles
	local self: Listener = self
	local Cache = CachingPool[self.Url]

	--- Checking if there's any cache
	if Cache and #Cache > 0 then
		return Cache[1]
	end
end

function Conduit:Post()
	--- Vaildation
	if getmetatable(self) ~= Conduit then
		error("Expected self to be a Conduit, got " .. typeof(self))
	end

	if self.Method:upper() ~= "POST" then
		error("[Conduit] -> Attempted to make a POST request on a GET partition!")
	end

	if IsConduitBlocked(self) then
		error("[Conduit] Current Stream Is Resting before Doing any HTTP requests. Please Try Again Later...")
	end

	--- Making a Pool for the Url If It Doesn't Exist
	if not CachingPool[self.Url] then
		CachingPool[self.Url] = {}
	end

	--- Varibles
	local success, result

	--- Now we'll wrap the HTTP Request in a pcall
	success, result = pcall(function()
		return HttpService:PostAsync(self.Url, self.ContentToPush, Enum.HttpContentType.ApplicationJson)
	end)

	--- Checking if the HTTP Request was successful
	if not success then
		error(`[Conduit] -> {table.concat({ false, result }, " | ", 2, 2)}`)
	end

	--- Firing Signals
	self.Signals.OnSend:Fire(result)

	return result
end

function Conduit:Start()
	--- Vaildation

	--- Checking if we have a url for the cachePool for this registered Url
	if not CachingPool[self.Url] then
		CachingPool[self.Url] = {}
	end

	--- Clearing any old cache in the "CachingPool"
	DeleteOldCache(self)

	--- Checking the method we're doing but first we'll check if we're blocked from doing anything
	if not IsConduitBlocked(self) then
		task.spawn(function()
			while task.wait(1) do
				--- Checking if the socket is currently blocked
				if IsConduitBlocked(self) then
					warn("Conduit Instance Is On Yield Watting for HttpService To Refresh your http request count before doing anymore")
					task.wait(3)

					continue
				end

				--- Deleting old cache before doing anything
				-- so that the cache is always up to date
				DeleteOldCache(self)

				local success, result = pcall(function()
					self.Pending = true
					
					if self.Method:upper() == "GET" then
						--- Varibles
						local Page = HttpService:GetAsync(self.Url, true)
						local LuauInterpretedPage = HttpService:JSONDecode(Page)
						local IsPageEmpty = #LuauInterpretedPage <= 0

						--- Updating ReadOnly Varibles
						Conduit.Constants.Total_Http_requests += 1
						self.Request_count += 1

						
						--- Now we'll check if it's empty
						if IsPageEmpty and not CacheCanBeAcknowladged(self) then
							return "Empty Page and No Cache To Be Acknowladged"
						elseif IsPageEmpty and CacheCanBeAcknowladged(self) then
							return self:PullFromCache(), "Cache Acknowladged"
						end

						--- Adding the defination PullTime So It Can Be Safely deleted from the cache pool
						LuauInterpretedPage.PullTime = tick()

						table.insert(CachingPool[self.Url], LuauInterpretedPage)

						return LuauInterpretedPage, #LuauInterpretedPage
					end
				end)

				self.Pending = false

				--- Now we'll check for any erros within the result
				if success then
					--- tracking how long the stream has been open for
					-- to check if we've been doing this for over a minute
					if tick() - self.LastRefreshTime >= 60 then
						Conduit.Constants.Total_Http_requests -= self.Request_count
						self.Request_count = 0
						self.LastRefreshTime = tick()
					end

					--- Checking if we've caught an empty payload
					if result == "Empty Page and No Cache To Be Acknowladged" then
						continue
					end

					--- If it was not empty then we'll double check the method to see if it was a POST request
					if self.Method:upper() == "POST" then
						self.Signals.OnSend:Fire(result)
					else
						self.Signals.OnReceive:Fire(result)
					end
				else
					warn("[Stream] -> Error During Execution: ", result)
				end
			end
		end)
	else
		error("[Stream] -> Attempted to make a request to a blocked partition!")
	end
end

function Conduit:Reset(): Listener
	--- Varibles
	local DisconnectedConnections = 0

	--- Going through each signal
	for Key, value in self.Signals ~= nil and self.Signals or {} do
		for ConnectionName, ConnectionInfo in value.Connections do
			ConnectionInfo:Disconnect()
			DisconnectedConnections += 1
		end
	end

	--- Now we'll print how many have been disconnected
	print("Disconnected", DisconnectedConnections, "connections")

	return self
end

function Conduit:SetCacheToBeRecycled(...: HttpCache)
	--- Vaildation
	if #{ ... } <= 0 then
		error("No cache to be removed! or no cache was passed to be removed!")
	end

	--- Varibles
	local Cache

	--- Going through each individual cache
	for PackedIndex, CacheToBeRemoved in { ... } do
		for index: number, saved_cache: HttpCache in CachingPool[self.Url] do
			if saved_cache == CacheToBeRemoved then
				--- Removing and fetching the cache so it can be passed one last time
				-- to a signal, before it get's decomposed
				Cache = table.remove(CachingPool[self.Url], index)

				warn("Removed Cache!: ", Cache, "From Url: ", self.Url)

				if self.Method:upper() == "GET" then
					self.Signals.OnCacheRemoved:Fire(Cache)
				end

				continue
			end
		end
	end
end

return Conduit
