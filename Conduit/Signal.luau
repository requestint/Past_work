----------------------
---- [ Services ] ----

----------------------
---- [ Varibles ] ----

----------------------
---- [ Modules ] ----

--------------------
---- [ Tables ] ----
local Signal = {}
local Listener = {}

Listener.__index = Listener

Signal.__index = Signal
Signal.Storage = {}

-------------------
---- [ Types ] ----
export type Signal = typeof(Signal) & {
	Id: string,
	_Listeners: { Listener },
	HasConnections: boolean,
}

export type Listener = typeof(Listener) & {
	func: (...any) -> any,
	Signal: Signal,
}

-----------------------
---- [ Functions ] ----
function Signal.new(SignalID: string): Signal
	--- Varibles
	local NewSignal: Signal

	--- Now I'll search for any existing signal matching the Id
	-- If the signal does not exist, then i'll create a new signal otherwise i'll return the existing signal.
	if Signal.Storage[SignalID] then
		NewSignal = Signal.Storage[SignalID]
	else
		NewSignal = setmetatable({
			Id = SignalID,
			HasConnections = false,
			_Listeners = {},
		}, Signal)

		Signal.Storage[SignalID] = NewSignal
	end

	return NewSignal
end

function Signal:AddListener(func: (...any) -> any)
	--- Vaildation

	-- checks if the provided argument is a function, if not it will throw an error.
	if type(func) ~= "function" then
		error("Expected a function, got " .. typeof(func))
	end

	-- Checking if we're calling this function using the self method, if not it will throw an error.
	if getmetatable(self) ~= Signal then
		warn("Expected self to be a Signal, got " .. typeof(self))
	end

	--- Varibles
	local NewListener: Listener = setmetatable({ func = func, Signal = self }, Listener)

	--- adding the listener object to the signal's Listeners
	table.insert(self._Listeners, NewListener)

	self.HasConnections = true

	return NewListener
end

function Listener:Disconnect()
	--- Checking if we're calling this function using the self method, if not it will throw an error.
	if getmetatable(self) ~= Listener then
		error("Expected self to be a Listener, got " .. typeof(self))
	end

	for key: number, Listener in pairs(self.Signal._Listeners) do
		if type(key) ~= "number" then
			continue
		end

		table.remove(self.Signal._Listeners, key)
	end

	--- Updating the HasConnections state / status of the current signal
	if #self.Signal._Listeners == 0 then
		self.Signal.HasConnections = false
	end
end

function Signal:Fire(...: any)
	--- Vaildation
	if getmetatable(self) ~= Signal then
		error("Expected self to be a Signal, got " .. typeof(self))
	end

	if not self.HasConnections then
		warn("[Signal] Discarded Event:" .. self.Id .. " No Connections found.")

		return false, "Discarded Event"
	end

	--- firing each listener within the signal
	for _, Listener in pairs(self._Listeners) do
		Listener.func(...)
	end
end

return Signal
