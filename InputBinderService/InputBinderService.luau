------------------------
----- [ Services ] -----
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

------------------------
----- [ Varibles ] -----

-----------------------
----- [ Modules ] -----
local Signal = require(path.to.Signal)

----------------------
----- [ Tables ] -----
local InputBinderService = {}

InputBinderService.__index = InputBinderService
InputBinderService.Gobal = {}

----------------------
----- [ Types ] -----
type Alias = {
	Combination: { Enum.KeyCode },
	Fired: boolean,
	OnBegan: Signal.Signal,
	OnEnded: Signal.Signal,
}

type self = typeof(setmetatable(
	{} :: {
		Aliases: { [string]: Alias },
		KeyLogs: { [Enum.KeyCode]: boolean },
		LastInputTime: number?,
		runtime_thread: RBXScriptConnection,
	},

	InputBinderService
))

------------------------
----- [ Functions ] ----
local function ParseKeybind(keybind: string): { Enum.KeyCode }
	--- Varibles
	local inner = keybind:match("^<(.+)>$") -- < Strips the angle brackets: "<One+Ctrl>" -> "One+Ctrl"
	local keycodes = {} -- < Making a List of KeyCodes
	local aliases = { --< Normalizing known shorthand aliases / modern short term abbrivations
		--- PC
		LCtrl = "LeftControl",
		RCtrl = "RightControl",

		LShift = "LeftShift",
		RShift = "RightShift",

		Esc = "Escape",

		RAlt = "RightAlt",
		LAlt = "LeftAlt",

		--- Xbox Controller
		A1 = "ButtonA",
		B1 = "ButtonB",
		X1 = "ButtonX",
		Y1 = "ButtonY",

		LB = "ButtonL1",
		RB = "ButtonR1",

		LT = "ButtonL2",
		RT = "ButtonR2",

		Select = "ButtonSelect",
		Start = "ButtonStart",
	}

	--- Vaildation
	assert(inner, "Cannot Parse Format: " .. keybind .. " Expected Format: <One+Ctrl>")

	-- Going through Each Key Characters in the string that mentions the fallowing
	-- "[]", "+", and "^"; This tells me there's a possible Key Combination In the string
	for key in inner:gmatch("[^+]+") do
		--- Varibles
		local resolved = aliases[key] or key -- < Checking if the key is an alias or not if it's not we'll just return the raw key
		local keycode = Enum.KeyCode[resolved] -- < Getting the keycode

		--- Vaildation
		assert(keycode, "Unknown KeyCode: " .. key) -- Checking if we have a keycode, if not we'll throw an error to the console

		table.insert(keycodes, keycode) -- < Adding the keycode to the list
	end

	--[[ essentially doing | if InputBinderService.Gobal[{YOURKEYS}] | ]]
	--
	if InputBinderService.Gobal[keycodes] then
		return error(
			"Attempted to overlap keybinds " .. table.concat(keycodes, "+") .. " Please set different key combination"
		)
	end

	return keycodes
end

function InputBinderService.new(): self
	--- Varibles
	local self = setmetatable(
		{} :: {
			Aliases: { [string]: Alias },
			LastInputTime: number?,
			runtime_thread: RBXScriptConnection,
		},
		InputBinderService
	)

	--- Adding Index's Within self
	self.Aliases = {}

	self.runtime_thread = RunService.Heartbeat:Connect(function(dt)
		--- Getting the total elapsed time since the last input
		self.LastInputTime = self.LastInputTime ~= nil and tick() - self.LastInputTime or tick()

		--- Checking if we have any key binds set or not
		if not self:ControllerIsEmpty() then
			self:Update()
		end
	end)

	--- Returning
	return self
end

function InputBinderService:Update()
	--- Varibles
	local BestMatch: Alias? = nil
	local BestMatchSize: number = 0

	--- Going through each Alias / Keybind and making a series of conditions
	-- to confirm what Alias / subset to Execute, when registering inputs.
	for identification, alias: Alias in self.Aliases do
		local CombinationPressed = true

		for _, bind: Enum.KeyCode in alias.Combination do
			if not UserInputService:IsKeyDown(bind) then
				CombinationPressed = false
				break
			end
		end

		if CombinationPressed then
			--- Vaildation
			if alias.Fired then --[[REMOVE THIS STATMENT IF YOU WANT UR ONBEGAN SIGNAL TO FIRE FOR HOWEVER LONG IT IS PRESSED]]
				continue
			end

			--- Firing Alias
			alias.Fired = true
			alias.OnBegan:Fire()
		else
			-- Changing State Of Alias
			alias.Fired = false
		end
	end
end

function InputBinderService:ControllerIsEmpty()
	--- Varibles
	local Aliases = self.Aliases

	--- Checking if the controller is empty or not
	return if next(Aliases) then false else true
end

function InputBinderService:CreateInputConnection(Name: string, Keybind: string): Alias
	--- Varibles
	local Info: Alias = {
		Combination = ParseKeybind(Keybind),
		Fired = false,

		OnBegan = Signal.new("OnBegan"),
		OnEnded = Signal.new("OnEnded"),
	}

	--- Index's Under self.Aliases To allow the
	-- Info to be retained and reused for future input when the input is recieved
	self.Aliases[Name] = Info

	return Info :: Alias
end

function InputBinderService:Disconnect()
	--- Closes all connections that we're made to
	-- Update the status of inputs, and the key logs
	self.runtime_thread:Disconnect()

	for _, alias in self.Aliases do
		alias.OnBegan:Disconnect()
		alias.OnEnded:Disconnect()
	end

	--- Emptying the key logs and aliases
	-- This will also clear the connections within them
	-- as they'll be garbage collected by the taskschedular
	self.Aliases = {}
end

return InputBinderService :: typeof(InputBinderService)
