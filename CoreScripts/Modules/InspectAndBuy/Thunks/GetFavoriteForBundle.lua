local CorePackages = game:GetService("CorePackages")
local PerformFetch = require(CorePackages.Workspace.Packages.Http).PerformFetch
local InspectAndBuyFolder = script.Parent.Parent
local Thunk = require(InspectAndBuyFolder.Thunk)
local Network = require(InspectAndBuyFolder.Services.Network)
local SetFavoriteBundle = require(InspectAndBuyFolder.Actions.SetFavoriteBundle)
local createInspectAndBuyKeyMapper = require(InspectAndBuyFolder.createInspectAndBuyKeyMapper)

local requiredServices = {
	Network,
}

local keyMapper = createInspectAndBuyKeyMapper("getFavoriteForBundle")

--[[
	Gets the favorite count of an asset.
]]
local function GetFavoriteForBundle(bundleId)
	return Thunk.new(script.Name, requiredServices, function(store, services)
		local network = services[Network]

		local key = keyMapper(store:getState().storeId, bundleId)

		return PerformFetch.Single(key, function(fetchSingleStore)
			return network.getFavoriteForBundle(bundleId):andThen(
				function(results)
					-- Endpoint returns 'null' if item isn't favorited.
					if results == "null" then
						store:dispatch(SetFavoriteBundle(tostring(bundleId), false))
					else
						store:dispatch(SetFavoriteBundle(tostring(bundleId), true))
					end
				end)
		end)(store):catch(function(err)

		end)
	end)
end

return GetFavoriteForBundle