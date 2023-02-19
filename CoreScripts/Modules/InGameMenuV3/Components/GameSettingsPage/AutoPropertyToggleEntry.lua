local CorePackages = game:GetService("CorePackages")

local InGameMenuDependencies = require(CorePackages.InGameMenuDependencies)
local Roact = InGameMenuDependencies.Roact
local t = InGameMenuDependencies.t

local InGameMenu = script.Parent.Parent.Parent

local ExternalEventConnection = require(InGameMenu.Utility.ExternalEventConnectionMemo)

local ToggleEntry = require(script.Parent.ToggleEntry)

local SendAnalytics = require(InGameMenu.Utility.SendAnalytics)
local Constants = require(InGameMenu.Resources.Constants)

local AutoPropertyToggleEntry = Roact.PureComponent:extend("AutoPropertyToggleEntry")
AutoPropertyToggleEntry.validateProps = t.strictInterface({
	instance = t.Instance,
	valueKey = t.string,
	lockedToOff = t.optional(t.boolean),
	onValue = t.optional(t.any),
	offValue = t.optional(t.any),
	labelKey = t.string,
	LayoutOrder = t.integer,
	subtextEnabled = t.optional(t.boolean),
	subtextKey = t.optional(t.string),
})

AutoPropertyToggleEntry.defaultProps = {
	onValue = true,
	offValue = false,
	lockedToOff = false,
	subtextEnabled = false,
	subtextKey = "",
}

function AutoPropertyToggleEntry:init(props)
	local currentValue = props.instance[props.valueKey]
	self.changeEvent = props.instance:GetPropertyChangedSignal(props.valueKey)

	self:setState({
		checked = not props.lockedToOff and currentValue == props.onValue,
	})

	self.onExternalChange = function()
		local newValue = props.instance[props.valueKey]
		self:setState({
			checked = newValue == props.onValue
		})
	end

	self.onToggled = function()
		if self.props.lockedToOff then
			return
		end

		local isOn = props.instance[props.valueKey] == props.onValue

		if isOn then
			props.instance[props.valueKey] = props.offValue
		else
			props.instance[props.valueKey] = props.onValue
		end

		SendAnalytics(Constants.AnalyticsSettingsChangeName, nil, {}, true)
	end
end

function AutoPropertyToggleEntry:render()
	local props = self.props

	return Roact.createFragment({
		Toggle = Roact.createElement(ToggleEntry, {
			checked = self.state.checked,
			lockedToOff = props.lockedToOff,
			labelKey = props.labelKey,
			LayoutOrder = props.LayoutOrder,
			onToggled = self.onToggled,
			subtextEnabled = props.subtextEnabled,
			subtextKey = props.subtextKey,
		}),

		Listener = Roact.createElement(ExternalEventConnection, {
			event = self.changeEvent,
			callback = self.onExternalChange,
		}),
	})
end

return AutoPropertyToggleEntry
