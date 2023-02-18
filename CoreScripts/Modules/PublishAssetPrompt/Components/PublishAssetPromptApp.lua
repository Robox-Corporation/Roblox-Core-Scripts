--[[
	This component displays an on-screen prompt when AssetService:PromptPublishAssetAsync is called,
	so that a player can publish assets from within an experience. The appearance of this prompt varies depending
	on the AssetType. In addition to PromptPublishAssetSingleStep, eventually we may add multi-step prompts.
]]
local CorePackages = game:GetService("CorePackages")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Roact = require(CorePackages.Roact)
local RoactRodux = require(CorePackages.RoactRodux)
local RoactGamepad = require(CorePackages.Packages.RoactGamepad)
local t = require(CorePackages.Packages.t)
local ExternalEventConnection = require(CorePackages.Workspace.Packages.RoactUtils).ExternalEventConnection
local InputType = require(CorePackages.Workspace.Packages.InputType)

local LocalPlayer = Players.LocalPlayer

local Components = script.Parent
local PublishAssetPromptSingleStep = require(Components.PublishAssetPromptSingleStep)

--Displays behind the InGameMenu so that developers can't block interaction with the InGameMenu by constantly prompting.
local DISPLAY_ORDER = 0

local PublishAssetPromptApp = Roact.PureComponent:extend("PublishAssetPromptApp")

PublishAssetPromptApp.validateProps = t.strictInterface({
	--Dispatch
	screenSizeUpdated = t.callback,
	assetType = t.enum(Enum.AssetType),
	assetInstance = t.instanceOf("Model"),
})

local function isGamepadInput(inputType)
	return InputType[inputType] == InputType.InputTypeConstants.Gamepad
end

function PublishAssetPromptApp:init()
	self:setState({
		isGamepad = isGamepadInput(UserInputService:GetLastInputType()),
	})

	self.absoluteSizeChanged = function(rbx)
		-- TODO fix
		--self.props.screenSizeUpdated(rbx.AbsoluteSize)
	end

	self.focusController = RoactGamepad.createFocusController()

	self.selectedCoreGuiObject = nil
	self.selectedGuiObject = nil
end

function PublishAssetPromptApp:render()
	local promptElement
	if self.props.assetInstance then
		promptElement = Roact.createElement(PublishAssetPromptSingleStep, {
			model = self.props.assetInstance,
			assetType = self.props.assetType,
		})
	end

	return Roact.createElement("ScreenGui", {
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		AutoLocalize = false,
		DisplayOrder = DISPLAY_ORDER,

		[Roact.Change.AbsoluteSize] = self.absoluteSizeChanged,
	}, {
		LastInputTypeConnection = Roact.createElement(ExternalEventConnection, {
			event = UserInputService.LastInputTypeChanged,
			callback = function(lastInputType)
				self:setState({
					isGamepad = isGamepadInput(lastInputType),
				})
			end,
		}) or nil,

		PromptFrame = Roact.createElement(RoactGamepad.Focusable.Frame, {
			focusController = self.focusController,

			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Prompt = promptElement,
		}) or nil,
	})
end

function PublishAssetPromptApp:revertSelectedGuiObject()
	local PlayerGui = nil
	if LocalPlayer then
		PlayerGui = LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
	end

	if self.selectedCoreGuiObject and self.selectedCoreGuiObject:IsDescendantOf(CoreGui) then
		GuiService.SelectedCoreObject = self.selectedCoreGuiObject
	elseif self.selectedGuiObject and self.selectedGuiObject:IsDescendantOf(PlayerGui) then
		GuiService.SelectedObject = self.selectedGuiObject
		GuiService.SelectedCoreObject = nil
	else
		GuiService.SelectedCoreObject = nil
	end

	self.selectedCoreGuiObject = nil
	self.selectedGuiObject = nil
end

function PublishAssetPromptApp:didUpdate(prevProps, prevState)
	local shouldCaptureFocus = self.state.isGamepad and self.props.assetInstance ~= nil
	local lastShouldCaptureFocus = prevState.isGamepad and prevProps.assetInstance ~= nil

	if shouldCaptureFocus ~= lastShouldCaptureFocus then
		if shouldCaptureFocus then
			self.selectedCoreGuiObject = GuiService.SelectedCoreObject
			self.selectedGuiObject = GuiService.SelectedObject
			GuiService.SelectedObject = nil
			self.focusController.captureFocus()
		else
			self.focusController.releaseFocus()
			if self.state.isGamepad then
				self:revertSelectedGuiObject()
			end
		end
	end
end

function PublishAssetPromptApp:willUnmount()
	if self.state.isGamepad then
		self:revertSelectedGuiObject()
	end
end

local function mapStateToProps(state)
	return {
		assetInstance = state.assetInstance,
		assetType = state.assetType,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		-- TODO: do we need to handle resizing on ScreenSizeUpdated?
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(PublishAssetPromptApp)
