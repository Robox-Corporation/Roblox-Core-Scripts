local CorePackages = game:GetService("CorePackages")
local AppTempCommon = CorePackages.AppTempCommon

local Requests = require(CorePackages.Workspace.Packages.Http).Requests
local GetCanSendAndCanCustomizeInvites = Requests.GetCanSendAndCanCustomizeInvites

local HttpRbxApiService = game:GetService("HttpRbxApiService")
local httpRequest = require(AppTempCommon.Temp.httpRequest)

return function(trigger: string, inviteUserId: number?)
	local requestImpl = httpRequest(HttpRbxApiService :: any)

	local success, result = GetCanSendAndCanCustomizeInvites(requestImpl :: any, trigger, inviteUserId):await()
	if success and result and result.responseBody then
		return result.responseBody.canPrompt, result.responseBody.canCustomize
	end
	return false, false
end
