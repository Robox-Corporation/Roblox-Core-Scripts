local CorePackages = game:GetService("CorePackages")
local AppTempCommon = CorePackages.AppTempCommon

local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local ShareGame = RobloxGui.Modules.Settings.Pages.ShareGame
local InviteEvents = require(ShareGame.Analytics.InviteEvents)

local Promise = require(AppTempCommon.LuaApp.Promise)

local ReceivedUserInviteStatus = require(ShareGame.Actions.ReceivedUserInviteStatus)
local Constants = require(ShareGame.Constants)
local InviteStatus = Constants.InviteStatus

local Requests = require(CorePackages.Workspace.Packages.Http).Requests
local PostSendExperienceInvite = Requests.PostSendExperienceInvite

local EMPTY_PLACE_ID = "0"

return function(
	requestImpl: any,
	userId: string,
	placeId: string,
	analytics: any,
	trigger: string,
	inviteMessageId: string?,
	launchData: string?
)
	return function(store)
		if placeId == EMPTY_PLACE_ID then
			warn("Game Invite failed to send. Cannot send invite to unpublished Place.")
			store:dispatch(ReceivedUserInviteStatus(userId, InviteStatus.Failed))
			return Promise.reject()
		end

		local latestState = store:getState()

		return Promise.new(function(resolve, reject)
			-- Check that we haven't already invited this user
			if latestState.Invites[userId] == InviteStatus.Pending then
				reject()
			else
				resolve()
			end
		end)
			:andThen(function()
				store:dispatch(ReceivedUserInviteStatus(userId, InviteStatus.Pending))
				return PostSendExperienceInvite(requestImpl, userId, placeId, trigger, inviteMessageId, launchData)
			end)
			:andThen(function(results)
				store:dispatch(ReceivedUserInviteStatus(userId, InviteStatus.Success))
				return results
			end, function()
				analytics:sendEvent(trigger, InviteEvents.ErrorShown)
				store:dispatch(ReceivedUserInviteStatus(userId, InviteStatus.Failed))
			end)
	end
end
