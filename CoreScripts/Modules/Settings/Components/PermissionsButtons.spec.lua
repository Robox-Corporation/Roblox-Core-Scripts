local CorePackages = game:GetService("CorePackages")
local Roact = require(CorePackages.Roact)
local CoreGui = game:GetService("CoreGui")
local Modules = CoreGui.RobloxGui.Modules

local PermissionsButtons = require(script.Parent.PermissionsButtons)
local GetFFlagSelfViewSettingsEnabled = require(Modules.Settings.Flags.GetFFlagSelfViewSettingsEnabled)

return function()
	if GetFFlagSelfViewSettingsEnabled() then
		it("should mount and unmount without errors", function()
			local element = Roact.createElement(PermissionsButtons, {
				isPortrait = true,
				isSmallTouchScreen = true,
				isTenFootInterface = false,
				ZIndex = -1,
				LayoutOrder = 1,
				shouldFillScreen = true,
				selfViewOpen = true,
			})

			local instance = Roact.mount(element)
			Roact.unmount(instance)
		end)
	end
end