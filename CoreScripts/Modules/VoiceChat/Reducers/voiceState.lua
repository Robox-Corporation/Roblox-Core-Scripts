--!nonstrict
local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local FFlagEnableVoiceChatStorybookFix = require(RobloxGui.Modules.Flags.FFlagEnableVoiceChatStorybookFix)

local Cryo = require(CorePackages.Packages.Cryo)
local Rodux = require(CorePackages.Packages.Rodux)
local VOICE_STATE
if FFlagEnableVoiceChatStorybookFix() then
	VOICE_STATE = require(CorePackages.AppTempCommon.VoiceChat.Constants).VOICE_STATE
else
	VOICE_STATE = require(script.Parent.Parent.VoiceChatServiceManager).default.VOICE_STATE
end

local ParticipantAdded = require(script.Parent.Parent.Actions.ParticipantAdded)
local ParticipantRemoved = require(script.Parent.Parent.Actions.ParticipantRemoved)
local VoiceStateChanged = require(script.Parent.Parent.Actions.VoiceStateChanged)
local VoiceEnabledChanged = require(script.Parent.Parent.Actions.VoiceEnabledChanged)

local RobloxGui = game:GetService("CoreGui"):WaitForChild("RobloxGui")

local voiceState = Rodux.createReducer({
	-- [userId] = voiceChatState,
}, {
	-- Tells us that voice chat is enabled
	[VoiceEnabledChanged.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			voiceEnabled = action.enabled,
		})
	end,
	-- Add the new user with the default voice chat state.
	[ParticipantAdded.name] = function(state, action)
		local userId = action.userId
		local voiceState = state[userId] or VOICE_STATE.HIDDEN

		return Cryo.Dictionary.join(state, {
			[userId] = voiceState,
		})
	end,

	-- Remove player from the voice chat list
	[ParticipantRemoved.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			[action.userId] = Cryo.None,
		})
	end,

	-- Change the current voice state for a specific player.
	[VoiceStateChanged.name] = function(state, action)
		-- Ignore state changes for users not already in the list
		if state[action.userId] then
			return Cryo.Dictionary.join(state, {
				[action.userId] = action.newState,
			})
		else
			return state
		end
	end,
})

return voiceState
