--!nonstrict
--[[
	BottomBar quick access menu
	Roblox VR 2022, @MetaVars
]]--

local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local Roact = require(CorePackages.Roact)
local RoactRodux = require(CorePackages.RoactRodux)
local UIBlox = require(CorePackages.UIBlox)
local SystemBar = UIBlox.App.Navigation.SystemBar
local Placement = UIBlox.App.Navigation.Enum.Placement

local UIBlox = require(CorePackages.UIBlox)
local Panel3D = UIBlox.Core.VR.Panel3D
local VRConstants = UIBlox.Core.VR.Constants

local ImageSetButton = UIBlox.Core.ImageSet.Button
local Images = UIBlox.App.ImageSet.Images

local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local VRHub = require(RobloxGui.Modules.VR.VRHub)

-- accessors
local InGameMenuConstants = require(RobloxGui.Modules.InGameMenuConstants)
local GameSettings = UserSettings().GameSettings
local InGameMenu = require(RobloxGui.Modules.InGameMenuInit)
local ChatSelector = require(RobloxGui.Modules.ChatSelector)

local VRBottomBar = Roact.PureComponent:extend("TopBarApp")
local VRBarSeparator = require(script.Parent.VRBarSeparator)

local EmotesMenuMaster = require(RobloxGui.Modules.EmotesMenu.EmotesMenuMaster)
local BackpackScript = require(RobloxGui.Modules.BackpackScript)
local PlayerListMaster = require(RobloxGui.Modules.PlayerList.PlayerListManager)
local StarterPlayer = game:GetService("StarterPlayer")

local SafetyBubbleEnabled = require(RobloxGui.Modules.Flags.FFlagSafetyBubbleEnabled)

local EngineFeatureEnableVRBottomBarWorksBehindObjects = game:GetEngineFeature("EnableVRBottomBarWorksBehindObjects")
local GetFFlagUIBloxVRApplyHeadScale =
	require(CorePackages.Workspace.Packages.SharedFlags).UIBlox.GetFFlagUIBloxVRApplyHeadScale

local FFlagFixPurchasePromptInVR = game:GetEngineFeature("FixPurchasePromptInVR")
local GetFFlagBottomBarButtonBehaviorFixVR = require(RobloxGui.Modules.Flags.GetFFlagBottomBarButtonBehaviorFixVR)

-- each individual icon can either be definied as a table entry with icon and onActivate, or as a item component
local MainMenu =
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_menu.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_menu.png",
	onActivated = function()
		VRHub:SetShowTopBar(true)
		if not InGameMenu.getOpen() then
			InGameMenu.openInGameMenu(InGameMenuConstants.MainPagePageKey)
		else
			InGameMenu.closeInGameMenu()
		end
	end,
}

local ToggleGui =
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_maximize.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_minimize.png",
	onActivated = function()
		if not VRHub.ShowTopBar then
			VRHub:SetShowTopBar(false)
			VRHub:SetShowTopBar(true)
		else
			VRHub:SetShowTopBar(false)
			InGameMenu.closeInGameMenu()
		end
	end,
}

local BackpackIcon =
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon__backpack.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon__backpack.png",
	onActivated = function()
		if GetFFlagBottomBarButtonBehaviorFixVR() then
			if not VRHub.ShowTopBar then
				-- Expand UI and open backpack
				VRHub:SetShowTopBar(true)
				if not BackpackScript.IsOpen then
					BackpackScript.OpenClose()
				end
			else
				BackpackScript.OpenClose()
			end
		else
			BackpackScript.OpenClose()
		end
	end,
}

local PlayerList =
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_leaderboard.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_leaderboard.png",
	onActivated = function()
		if GetFFlagBottomBarButtonBehaviorFixVR() then
			if not VRHub.ShowTopBar then
				-- Expand UI and show playerList
				VRHub:SetShowTopBar(true)
				if not PlayerListMaster:GetSetVisible() then
					PlayerListMaster:SetVisibility(true)
				end
			else
				PlayerListMaster:SetVisibility(not PlayerListMaster:GetSetVisible())
			end
		else
			PlayerListMaster:SetVisibility(not PlayerListMaster:GetSetVisible())
		end
	end,
}

local Emotes =
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_emote.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_emote.png",
	onActivated = function()
		if GetFFlagBottomBarButtonBehaviorFixVR() then
			if not VRHub.ShowTopBar then
				-- Expand UI and show emotesMenu
				VRHub:SetShowTopBar(true)
				if not EmotesMenuMaster:isOpen() then
					EmotesMenuMaster:open()
				end
			else
				if EmotesMenuMaster:isOpen() then
					EmotesMenuMaster:close()
				else
					EmotesMenuMaster:open()
				end
			end
		else
			VRHub:SetShowTopBar(true)
			if EmotesMenuMaster:isOpen() then
				EmotesMenuMaster:close()
			else
				EmotesMenuMaster:open()
			end
		end
	end,
}

local Chat =
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_chat.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_chat.png",
	onActivated = function()
		if GetFFlagBottomBarButtonBehaviorFixVR() then
			if not VRHub.ShowTopBar then
				-- Expand UI and show chat
				VRHub:SetShowTopBar(true)
				if not ChatSelector:GetVisibility() then
					ChatSelector:ToggleVisibility()
					GameSettings.ChatVisible = ChatSelector:GetVisibility()
				end
			else
				ChatSelector:ToggleVisibility()
				GameSettings.ChatVisible = ChatSelector:GetVisibility()
			end
		else
			VRHub:SetShowTopBar(true)
			ChatSelector:ToggleVisibility()
			GameSettings.ChatVisible = ChatSelector:GetVisibility()
		end
	end,
}

local SafetyOn = 
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_safety_on.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_safety_on.png",
	onActivated = function()
		VRHub:ToggleSafetyBubble()
	end,
}

local SafetyOff = 
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_safety_off.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_safety_off.png",
	onActivated = function()
		VRHub:ToggleSafetyBubble()
	end,
}

local LeaveGame = 
{
	iconOn = "rbxasset://textures/ui/MenuBar/icon_leave.png",
	iconOff = "rbxasset://textures/ui/MenuBar/icon_leave.png",
	onActivated = function()
		VRHub:SetShowTopBar(true)
		if InGameMenu then
			if FFlagFixPurchasePromptInVR then
				-- Should open root menu to trigger InGameMenu open event before open GameLeave page
				if not InGameMenu.getOpen() then
					InGameMenu.openInGameMenu(InGameMenuConstants.MainPagePageKey)
				end
				InGameMenu.openGameLeavePage()
			else
				if InGameMenu.getOpen then
					InGameMenu.openGameLeavePage()
				end
			end
		end
	end,
}

local SeparatorIcon =
{
	iconComponent = VRBarSeparator,
	itemSize = UDim2.new(0, 28, 0, 44),
}

-- default bar init
function VRBottomBar:init()
	if SafetyBubbleEnabled then	
		self:setState({
			itemList = {MainMenu, SeparatorIcon, ToggleGui, Emotes, Chat, PlayerList, SeparatorIcon, SafetyOn, LeaveGame}
		})
	else
		self:setState({
			itemList = {MainMenu, SeparatorIcon, ToggleGui, Emotes, Chat, PlayerList, SeparatorIcon, LeaveGame}
		})
	end

	self:setState({
		vrMenuOpen = true
	})
	
	self.backpackHasItems = false
	self.emotesLoaded = false
end

function VRBottomBar:didMount()
	VRHub.ShowTopBarChanged.Event:Connect(function()
		self:setState({
			vrMenuOpen = VRHub.ShowTopBar,
		})
	end)
	
	VRHub.SafetyBubbleToggled.Event:Connect(function()
		local activeItems = self:updateItems()
		self:setState({
			itemList = activeItems
		})
	end)
	
	BackpackScript.BackpackItemAdded.Event:Connect(function()
		self.backpackHasItems = true
		local activeItems = self:updateItems()
		self:setState({
			itemList = activeItems
		})
	end)
	
	BackpackScript.BackpackEmpty.Event:Connect(function()
		self.backpackHasItems = false
		local activeItems = self:updateItems()
		self:setState({
			itemList = activeItems
		})
	end)
	
	EmotesMenuMaster.EmotesLoaded.Event:Connect(function(emotesLoaded)
		if emotesLoaded ~= self.emotesLoaded then
			self.emotesLoaded = emotesLoaded
			local activeItems = self:updateItems()
			self:setState({
				itemList = activeItems
			})
		end
	end)
end

-- the bottombar itemlist automatically tracks feature updates and scales on demand
function VRBottomBar:updateItems()
	local backpackEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
	local emotesEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu)
	local chatEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
	local playerListEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	
	local enabledItems = {MainMenu, SeparatorIcon, ToggleGui}
	if emotesEnabled and not (StarterPlayer.UserEmotesEnabled and self.emotesLoaded == false) then
		table.insert(enabledItems, Emotes)
	end
	if backpackEnabled and self.backpackHasItems then
		table.insert(enabledItems, BackpackIcon)
	end
	if chatEnabled then
		table.insert(enabledItems, Chat)
	end
	if playerListEnabled then
		table.insert(enabledItems, PlayerList)
	end

	table.insert(enabledItems, SeparatorIcon)

	if SafetyBubbleEnabled then
		if VRHub.SafetyBubble and VRHub.SafetyBubble.enabled then
			table.insert(enabledItems, SafetyOn)
		else
			table.insert(enabledItems, SafetyOff)
		end
	end

	table.insert(enabledItems, LeaveGame)

	return enabledItems
end

-- VRBottomBar implements two UIBlox components
function VRBottomBar:render()
	return Roact.createElement(Panel3D,  {
			panelName = "BottomBar",
			partSize = if GetFFlagUIBloxVRApplyHeadScale()
				then Vector2.new((table.getn(self.state.itemList) - 1) * 0.15, 0.15)
				else Vector2.new((table.getn(self.state.itemList) - 1) * 0.15 * (workspace.CurrentCamera :: Camera).HeadScale, 0.15 * (workspace.CurrentCamera :: Camera).HeadScale),
			virtualScreenSize = Vector2.new((table.getn(self.state.itemList) - 1) * 50, 50),
			offset = if GetFFlagUIBloxVRApplyHeadScale()
				then self.state.vrMenuOpen and CFrame.new(0, -1.5, 0) or CFrame.new(0, -2, 0)
				else self.state.vrMenuOpen and CFrame.new(0, -1.5 * (workspace.CurrentCamera :: Camera).HeadScale, 0) or CFrame.new(0, -2 * (workspace.CurrentCamera :: Camera).HeadScale, 0),
			lerp = true,
			tilt = 0,
			anchoring = VRConstants.AnchoringTypes.Head,
			faceCamera = true,
			alwaysOnTop = EngineFeatureEnableVRBottomBarWorksBehindObjects and true or nil,
			parent = EngineFeatureEnableVRBottomBarWorksBehindObjects and GuiService.CoreGuiFolder or nil,
		},
	{
		Roact.createElement(SystemBar, {
			itemList = self.state.itemList,
			selection = self.state.vrMenuOpen and 1 or 3,
			placement = Placement.Bottom,
			hidden = false,
			onSafeAreaChanged = function() end,
			size = UDim2.new(1, 0, 1, 0),
			position = UDim2.new(),
			layoutOrder = 1,
			roundCorners = true,
			buttonStroke = true,
			bgTransparency = 0,

			StarterGui.CoreGuiChangedSignal:connect(function(coreGuiType, enabled)
				local activeItems = self:updateItems()
				self:setState({
					itemList = activeItems
				})
			end),
		}),
	})
end

return RoactRodux.UNSTABLE_connect2(nil, nil)(VRBottomBar)
