--!nonstrict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGuiService = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local FFlagEnableKeyboardUINavigationNotification = game:DefineFastFlag("EnableKeyboardUINavigationNotification", false)
local FFlagSendKeyboardUINavigationNotificationOnEnable = game:DefineFastFlag("SendKeyboardUINavigationNotificationOnEnable", false)

local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local SendNotification = RobloxGui:WaitForChild("SendNotificationInfo")
local RobloxTranslator = require(RobloxGui:WaitForChild("Modules"):WaitForChild("RobloxTranslator"))

local function LocalizedGetString(key, rtv)
	pcall(function()
		rtv = RobloxTranslator:FormatByKey(key)
	end)
	return rtv
end

local function ScrollSelectedElement(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	local selectedObject = GuiService.SelectedObject
	-- If no selected object, ignore
	if selectedObject == nil then
		return Enum.ContextActionResult.Pass
	end

	local scrollingFrame = nil
	if selectedObject.ClassName == "ScrollingFrame" then
		scrollingFrame = selectedObject
	else
		local scrollingFrameAncestor = selectedObject:FindFirstAncestorOfClass("ScrollingFrame")
		if scrollingFrameAncestor ~= nil then
			scrollingFrame = scrollingFrameAncestor
		end
	end

	-- If selected object is not a scrolling frame, or a descendant of one, ignore
	if scrollingFrame == nil then
		return Enum.ContextActionResult.Pass
	end

	local scrollDistance = 0
	if inputObject.KeyCode == Enum.KeyCode.PageUp or inputObject.KeyCode == Enum.KeyCode.Home then
		scrollDistance = -100
	elseif inputObject.KeyCode == Enum.KeyCode.PageDown or inputObject.KeyCode == Enum.KeyCode.End then
		scrollDistance = 100
	end

	local x = scrollingFrame.CanvasPosition.X
	local y = scrollingFrame.CanvasPosition.Y
	if inputObject.KeyCode == Enum.KeyCode.PageUp or inputObject.KeyCode == Enum.KeyCode.PageDown then
		-- Scroll vertically
		y = math.max(0, math.min(y + scrollDistance, scrollingFrame.AbsoluteCanvasSize.Y))
	elseif inputObject.KeyCode == Enum.KeyCode.Home or inputObject.KeyCode == Enum.KeyCode.End then
		-- Scroll horizontally
		x = math.max(0, math.min(x + scrollDistance, scrollingFrame.AbsoluteCanvasSize.X))
	end
	scrollingFrame.CanvasPosition = Vector2.new(x, y)

	-- No need to sink input for scrolling, let it propagate
	return Enum.ContextActionResult.Pass
end

local function EnableKeyboardNavigation(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if not GuiService.AutoSelectGuiEnabled then
		return Enum.ContextActionResult.Pass
	end

	-- The selected object is already active, disable
	if GuiService.SelectedObject then
		GuiService.SelectedObject = nil
		return Enum.ContextActionResult.Sink
	end

	GuiService:Select(PlayerGui)

	-- Only send a notification if we found an element to select
	if FFlagEnableKeyboardUINavigationNotification then
		if not FFlagSendKeyboardUINavigationNotificationOnEnable or GuiService.SelectedObject then
			local notificationTitle = LocalizedGetString("NotificationScript2.UINavigation.Title")
			local notificationText = LocalizedGetString("NotificationScript2.UINavigation.Text")

			SendNotification:Fire({
				Title = notificationTitle,
				Text = notificationText,
				Duration = 3
			})
		end
	end

	return Enum.ContextActionResult.Sink
end

local KeyboardUINavigation = {}
KeyboardUINavigation.__index = KeyboardUINavigation
function KeyboardUINavigation.new()
	local self = setmetatable({}, KeyboardUINavigation)
	ContextActionService:BindAction("EnableKeyboardUINavigation", EnableKeyboardNavigation, false, Enum.KeyCode.BackSlash)
	ContextActionService:BindAction("ScrollSelectedElement", ScrollSelectedElement, false, Enum.KeyCode.PageUp, Enum.KeyCode.PageDown, Enum.KeyCode.Home, Enum.KeyCode.End)
	return self
end
return KeyboardUINavigation.new()
