-- Optimization --
local bit_bxor = bit.bxor
local coroutine_makef = coroutine.makef
local coroutine_running = coroutine.running
local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield
local encode_getPasswordHash = encode.getPasswordHash
local enum_validate = enum._validate
local math_normalizePoint = math.normalizePoint
local os_exit = os.exit
local string_byte = string.byte
local string_fixEntity = string.fixEntity
local string_format = string.format
local string_gsub = string.gsub
local string_split = string.split
local string_sub = string.sub
local string_toNickname = string.toNickname
local table_copy = table.copy
local table_remove = table.remove
local table_setNewClass = table.setNewClass
local table_writeBytes = table.writeBytes
local timer_clearInterval = timer.clearInterval
local timer_clearTimeout = timer.clearTimeout
local timer_setInterval = timer.setInterval
local timer_setTimeout = timer.setTimeout
local uv_signal_start = uv.signal_start
local uv_new_signal = uv.new_signal
------------------

local Client = table.setNewClass()

local playerListMeta = {
	__len = function(this)
		return this.count or -1
	end,
	__pairs = function(this)
		local indexes = { }
		for i = 1, #this do
			indexes[i] = this[i].playerName
		end

		local i, tmp = 0
		return function()
			i = i + 1
			tmp = this[indexes[i]]
			if tmp then
				return tmp.playerName, tmp
			end
		end
	end
}

--[[@
	@name new
	@desc Creates a new instance of Client. Alias: `client()`.
	@desc The function @see start is automatically called if you pass its arguments.
	@param tfmId?<string,int> The Transformice ID of your account. If you don't know how to obtain it, go to the room **#bolodefchoco0id** and check your chat.
	@param token?<string> The API Endpoint token to get access to the authentication keys.
	@param hasSpecialRole?<boolean> Whether the bot has the game's special role bot or not.
	@param updateSettings?<boolean> Whether the IP/Port settings should be updated by the endpoint or not when the @hasSpecialRole is true.
	@returns client The new Client object.
	@struct {
		playerName = "", -- The nickname of the account that is attached to this instance, if there's any.
		language = 0, -- The language enum where the object is set to perform the login. Default value is EN.
		main = { }, -- The main connection object, handles the game server.
		bulle = { }, -- The bulle connection object, handles the room server.
		event = { }, -- The event emitter object, used to trigger events.
		cafe = { }, -- The cached Café structure. (topics and messages)
		playerList = { }, -- The room players data.
		-- The fields below must not be edited, since they are used internally in the api.
		_mainLoop = { }, -- (userdata) A timer that retrieves the packets received from the game server.
		_bulleLoop = { }, -- (userdata) A timer that retrieves the packets received from the room server.
		_receivedAuthkey = 0, -- Authorization key, used to connect the account.
		_gameVersion = 0, -- The game version, used to connect the account.
		_gameConnectionKey = "", -- The game connection key, used to connect the account.
		_gameIdentificationKeys = { }, -- The game identification keys, used to connect the account.
		_gameMsgKeys = { }, -- The game message keys, used to connect the account.
		_connectionTime = 0, -- The timestamp of when the player logged in. It will be 0 if the account is not connected.
		_isConnected = false, -- Whether the player is connected or not.
		_hbTimer = { }, -- (userdata) A timer that sends heartbeats to the server.
		_whoFingerprint = 0, -- A fingerprint to identify the chat where the command /who was used.
		_whoList = { }, -- A list of chat names associated to their own fingerprints.
		_processXml = false, -- Whether the event "newGame" should decode the XML packet or not. (Set as false to save process)
		_cafeCachedMessages = { }, -- A set of message IDs to cache the read messages at the Café.
		_handlePlayers = false, -- Whether the player-related events should be handled or not. (Set as false to save process)
		_encode = { }, -- The encode object, used to encryption.
		_hasSpecialRole = false, -- Whether the bot has the game's special role bot or not.
		_updateSettings = false -- Whether the IP/Port settings should be updated by the endpoint or not when the @hasSpecialRole is true.
	}
]]
Client.new = function(self, tfmId, token, hasSpecialRole, updateSettings)
	local eventEmitter = event:new()

	local obj = setmetatable({
		playerName = nil,
		language = enum.language.en,
		main = connection:new("main", eventEmitter),
		bulle = nil,
		event = eventEmitter,
		cafe = { },
		playerList = setmetatable({ }, playerListMeta),
		-- Private
		_mainLoop = nil,
		_bulleLoop = nil,
		_receivedAuthkey = 0,
		_gameVersion = 666,
		_gameConnectionKey = "",
		_gameAuthkey = 0,
		_gameIdentificationKeys = { },
		_gameMsgKeys = { },
		_connectionTime = 0,
		_isConnected = false,
		_hbTimer = nil,
		_whoFingerprint = 0,
		_whoList = { },
		_processXml = false,
		_cafeCachedMessages = { },
		_handlePlayers = false,
		_encode = encode:new(hasSpecialRole),
		_hasSpecialRole = hasSpecialRole,
		_updateSettings = updateSettings,
		_isListeningSigint = false
	}, self)

	if tfmId and token then
		obj:start(tfmId, token)
	end

	return obj
end

return Client