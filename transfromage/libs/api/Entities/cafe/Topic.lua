local Message = require("./Message")

------------------------------------------- Optimization -------------------------------------------
local os_time      = os.time
local setmetatable = setmetatable
----------------------------------------------------------------------------------------------------

local Topic = table.setNewClass()

Topic.new = function(self, packet, id)
	local data = { }

	if packet then
		data.id = packet:read32()
		Topic.update(data, packet)
	elseif id then
		data.id = id
	end

	return setmetatable(data, self)
end

Topic.update = function(self, packet)
	self.title = packet:readUTF()
	self.authorId = packet:read32()
	self.posts = packet:read32()
	self.lastUserName = packet:readUTF()
	self.timestamp = os_time() - packet:read32()

	return self
end

Topic.retrieveMessages = function(self, packet)
	local messages, totalMessages = { }, 0

	while packet.stackLen > 0 do
		totalMessages = totalMessages + 1
		messages[totalMessages] = Message:new(self.id, packet)
	end

	self.messages = messages
	self.author = messages[1].author

	return self
end

return Topic