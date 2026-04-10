#  Magic's Portfolio

> Hello! I go by **Magic** (and sometimes **Legends**) — those are my Discord display names, past and present.  
> This is where I store my published work: modules, packages, and libraries I've built for Roblox.

Each folder in this repo is its own **Section**, containing a module or project.

---

## Sections

### Signal
A lightweight event module for same-context communication.

 Fires events within the **same run context** (Client → Client, Server → Server) Lets scripts connect to signals and act as event listeners
 Works similarly to Roblox's `BindableEvent`, but fully custom

---

### Conduit
It's a module that allow's  the user to do constant pull and Optimzed Post Requests (optimzed by taking the requests per second into account, and what not) to a specific Url or Destionation.
The Typical usecase for this would be for discord -> roblox communication to do stuff like moderate, and verifiy users' inside the game; 
there could be more usecase's but those are the typical ones. 

--- 

### InputBinderService
My attempt to Upgrade the API of UserInputService + ContextActionService
 
 To allow user's to have a series of limitless InputCombinations without having to use UserInputService:IsKeyDown For Every single check

```lua
Controller:CreateInputConnection("Dash", "").OnBegan:AddListener(function()
   -- fires only when both LB and RT are held
end)
```

### RelayNet (Unrealeased, Comming Soon!)
My first networker handles cross-context communication.

 The goal with the networker is to make the functionality of a RemoteEvent  **Server → Client** and **Client → Server** messaging
 Built from scratch without external dependencies

---

*More sections coming soon.*
