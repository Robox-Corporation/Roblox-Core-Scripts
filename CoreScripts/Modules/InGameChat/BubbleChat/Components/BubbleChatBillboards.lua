--!nonstrict
--[[
	Handles rendering of each BubbleChatBillboard depending on if a user has any
	messages.
]]

local Chat = game:GetService("Chat")
local CoreGui = game:GetService("CoreGui")
local CorePackages = game:GetService("CorePackages")
local Players = game:GetService("Players")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local Roact = require(CorePackages.Packages.Roact)
local RoactRodux = require(CorePackages.Packages.RoactRodux)
local t = require(CorePackages.Packages.t)
local Cryo = require(CorePackages.Packages.Cryo)

local Constants = require(script.Parent.Parent.Constants)
local log = require(script.Parent.Parent.Logger)(script.Name)

local BubbleChatBillboard = require(script.Parent.BubbleChatBillboard)
local VoiceIndicator = require(RobloxGui.Modules.VoiceChat.Components.VoiceIndicator)

local VoiceChatServiceManager = require(RobloxGui.Modules.VoiceChat.VoiceChatServiceManager).default

local GetFFlagBubbleVoiceIndicatorSetting = require(RobloxGui.Modules.Flags.GetFFlagBubbleVoiceIndicatorSetting)

local ChatBillboards = Roact.Component:extend("ChatBillboards")

ChatBillboards.validateProps = t.strictInterface({
	userMessages = t.map(t.string, t.array(t.string)),
	bubbleChatEnabled = t.boolean,
	voiceEnabled = t.boolean,
	participants = t.map(t.string, t.string),
})

function ChatBillboards.getDerivedStateFromProps(nextProps, lastState)
	return {
		-- We need to keep in memory userMessages' keys to allow the fade out animations to play, otherwise the child
		-- billboards would be unmounted right away. It is their responsibility to clean up by triggering
		-- the function self.onBillboardFadeOut
		userMessages = Cryo.Dictionary.join(lastState.userMessages or {}, nextProps.userMessages)
	}
end

function ChatBillboards:init()
	log:debug("Initializing")
	self:setState({
		userMessages = {},
	})

	self.onBillboardFadeOut = function(userId)
		self:setState({
			userMessages = Cryo.Dictionary.join(self.state.userMessages, { [userId] = Cryo.None })
		})
	end
end

function ChatBillboards:render()
	if not self.props.voiceEnabled and not self.props.bubbleChatEnabled then
		-- No voice or bubble chat, so nothing to render
		return
	end

	local userIds = {}
	for userId, _ in pairs(self.state.userMessages) do
		-- Disable voice inserts for non-player messages
		userIds[userId] = false
	end
	for userId, userState in pairs(self.props.participants) do
		-- Enable them for player messages
		if userState ~= Constants.VOICE_STATE.HIDDEN then
			userIds[userId] = true
		end
	end

	local billboards = {}
	for userId, isParticipant in pairs(userIds) do
		log:trace("Rendering billboard for ...{}", string.sub(tostring(userId), -4))
		billboards["BubbleChat_" .. userId] = Roact.createElement(BubbleChatBillboard, {
			userId = userId,
			onFadeOut = self.onBillboardFadeOut,
			voiceEnabled = self.props.voiceEnabled and isParticipant,
			bubbleChatEnabled = self.props.bubbleChatEnabled,
		})
	end

	-- Wrapped in a ScreenGui so all of the billboards don't clog up
	-- PlayerGui. Specifically need to use a ScreenGui so we can set
	-- ResetOnSpawn. Folders would be a better alternative, but those
	-- are always destroyed when respawning.
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
	}, billboards)
end

function ChatBillboards:willUnmount()
	for _, conn in pairs(self.connections) do
		conn:Disconnect()
	end
end

local function mapStateToProps(state)
	local voiceEnabled = state.components.voiceEnabled
	if GetFFlagBubbleVoiceIndicatorSetting() then
		voiceEnabled = state.components.voiceEnabled and state.chatSettings.Voice.ShowIndicator
	end

	return {
		userMessages = state.userMessages,
		voiceEnabled = voiceEnabled,
		bubbleChatEnabled = state.components.bubbleChatEnabled,
		participants = state.voiceState,
	}
end

return RoactRodux.connect(mapStateToProps)(ChatBillboards)
