--!nonstrict
--[[
		Filename: ExitModal.lua
		Written by: relkhattabi
		Version 1.0
		Description: Shows when the window's close button is pressed
--]]

-------------- CONSTANTS -------------

local LEAVE_GAME_ACTION = "LeaveGameAction"
local DONT_LEAVE_ACTION = "DontLeaveAction"
local LEAVE_GAME_FRAME_WAITS = 2

local EducationalAnalytics = {
	EventContext = "educational_popup",
	ConfirmName = "educational_confirmed",
	CancelName = "educational_close_app",
	DismissName = "educational_dismiss_prompt",
}

local LOCAL_STORAGE_KEY_NATIVE_CLOSE = "NativeCloseLuaPromptDisplayCount"

-------------- SERVICES --------------

local CoreGui = game:GetService("CoreGui")
local ContextActionService = game:GetService("ContextActionService")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local CorePackages = game:GetService("CorePackages")
local LocalizationService = game:GetService("LocalizationService")

----------- UTILITIES --------------

local NotificationType = GuiService:GetNotificationTypeList()
local Roact = require(CorePackages.Roact)
local LinkingProtocol = require(CorePackages.UniversalApp.Linking.LinkingProtocol)
local Localization = require(RobloxGui.Modules.InGameMenu.Localization.Localization)
local SendAnalytics = require(RobloxGui.Modules.InGameMenu.Utility.SendAnalytics)
local UserLocalStore = require(RobloxGui.Modules.InGameMenu.Utility.UserLocalStore)
local GetDefaultQualityLevel = require(RobloxGui.Modules.Common.GetDefaultQualityLevel)

----------- COMPONENTS --------------

local InGameMenuDependencies = require(CorePackages.InGameMenuDependencies)
local UIBlox = InGameMenuDependencies.UIBlox
local Images = UIBlox.App.ImageSet.Images
local StyleProvider = UIBlox.Core.Style.Provider
local EducationalModal = UIBlox.App.Dialog.Modal.EducationalModal

local AppDarkTheme = require(CorePackages.Workspace.Packages.Style).Themes.DarkTheme
local AppFont = require(CorePackages.Workspace.Packages.Style).Fonts.Gotham

------------ VARIABLES -------------------

local PageInstance = nil

------------ FLAGS -------------------

local GetFFlagInGameMenuV1LeaveToHome = require(RobloxGui.Modules.Flags.GetFFlagInGameMenuV1LeaveToHome)
local GetFIntEducationalPopupDisplayMaxCount = require(RobloxGui.Modules.Flags.GetFIntEducationalPopupDisplayMaxCount)
local FFlagLuaAppExitModalDoNotShow = game:DefineFastFlag("LuaAppExitModalDoNotShow", false)

----------- CLASS DECLARATION --------------
local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	this.LeaveAppFunc = function(fromNative)
		GuiService.SelectedCoreObject = nil -- deselects the button and prevents spamming the popup to save in studio when using gamepad

		SendAnalytics(EducationalAnalytics.EventContext, EducationalAnalytics.CancelName, {
			source = if fromNative then "Native" else "Button",
		})

		-- need to wait for render frames so on slower devices the leave button highlight will update
		-- otherwise, since on slow devices it takes so long to leave you are left wondering if you pressed the button
		for i = 1, LEAVE_GAME_FRAME_WAITS do
			RunService.RenderStepped:wait()
		end

		settings().Rendering.QualityLevel = GetDefaultQualityLevel()

		GuiService:BroadcastNotification("", NotificationType.NATIVE_EXIT)
	end
	this.LeaveGameFunc = function(isUsingGamepad)
		GuiService.SelectedCoreObject = nil -- deselects the button and prevents spamming the popup to save in studio when using gamepad

		SendAnalytics(EducationalAnalytics.EventContext, EducationalAnalytics.ConfirmName, {
			source = if isUsingGamepad then "Gamepad" else "Button",
		})

		if GetFFlagInGameMenuV1LeaveToHome() then
			LinkingProtocol.default:detectURL("roblox://navigation/home")
		end

		-- need to wait for render frames so on slower devices the leave button highlight will update
		-- otherwise, since on slow devices it takes so long to leave you are left wondering if you pressed the button
		for i = 1, LEAVE_GAME_FRAME_WAITS do
			RunService.RenderStepped:wait()
		end

		game:Shutdown()

		settings().Rendering.QualityLevel = GetDefaultQualityLevel()
	end
	this.LeaveGameFromHotkey = function(name, state, input)
		if state == Enum.UserInputState.Begin then
			local isUsingGamepad = input.UserInputType == Enum.UserInputType.Gamepad1
				or input.UserInputType == Enum.UserInputType.Gamepad2
				or input.UserInputType == Enum.UserInputType.Gamepad3
				or input.UserInputType == Enum.UserInputType.Gamepad4

			this.LeaveGameFunc(isUsingGamepad)
		end
	end
	this.DontLeaveFunc = function(isUsingGamepad)
		PageInstance.dismissedFrom = if isUsingGamepad then "Gamepad" else "Button"

		if this.HubRef then
			this.HubRef:PopMenu(isUsingGamepad, true)
		end
	end
	this.DontLeaveFromHotkey = function(name, state, input)
		if state == Enum.UserInputState.Begin then
			local isUsingGamepad = input.UserInputType == Enum.UserInputType.Gamepad1
				or input.UserInputType == Enum.UserInputType.Gamepad2
				or input.UserInputType == Enum.UserInputType.Gamepad3
				or input.UserInputType == Enum.UserInputType.Gamepad4

			this.DontLeaveFunc(isUsingGamepad)
		end
	end

	this.DontShowAgain = function()
		local userStore = UserLocalStore.new()
		userStore:SetItem(LOCAL_STORAGE_KEY_NATIVE_CLOSE, tostring(math.huge))
		userStore:Flush()
	end

	-- increments the counter and checks if it's smaller than the max value (flag)
	this.ShouldShow = function()
		local userStore = UserLocalStore.new()
		local displayCount = tonumber(userStore:GetItem(LOCAL_STORAGE_KEY_NATIVE_CLOSE))
		if displayCount > GetFIntEducationalPopupDisplayMaxCount() then
			return false
		else
			userStore:SetItem(LOCAL_STORAGE_KEY_NATIVE_CLOSE, tostring(displayCount + 1))
			userStore:Flush()
			return true
		end
	end

	------ TAB CUSTOMIZATION -------
	this.TabHeader = nil -- no tab for this page

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "ExitModalPage"
	this.ShouldShowBottomBar = false
	this.ShouldShowHubBar = false
	this.IsPageClipped = false

	------ PAGE CONTENTS -------

	this.Page.Size = UDim2.new(1, 0, 0, 1)

	local localization = Localization.new(LocalizationService.RobloxLocaleId)

	local function ExitModal()
		localization:SetLocale(LocalizationService.RobloxLocaleId)
		local localized = {
			title = localization:Format("CoreScripts.InGameMenu.ExitModal.Title"),
			subtitle = localization:Format("CoreScripts.InGameMenu.ExitModal.Subtitle"),
			bodyTextOpenMenu = localization:Format("CoreScripts.InGameMenu.ExitModal.BodyTextOpenMenu"),
			bodyTextClickHome = localization:Format("CoreScripts.InGameMenu.ExitModal.BodyTextClickHome"),
			optionDontShow = if FFlagLuaAppExitModalDoNotShow
				then localization:Format("CoreScripts.InGameMenu.ExitModal.OptionDontShow")
				else nil,
			actionExit = localization:Format("CoreScripts.InGameMenu.ExitModal.ActionExit"),
			actionHome = localization:Format("CoreScripts.InGameMenu.ExitModal.ActionHome"),
		}

		return Roact.createElement(StyleProvider, {
			style = {
				Theme = AppDarkTheme,
				Font = AppFont,
			},
		}, {
			Roact.createElement(EducationalModal, {
				bodyContents = {
					{
						text = localized.bodyTextOpenMenu,
						isSystemMenuIcon = true,
					},
					{
						icon = Images["icons/menu/home_off"],
						text = localized.bodyTextClickHome,
					},
				},
				hasDoNotShow = if FFlagLuaAppExitModalDoNotShow then true else nil,
				cancelText = localized.actionExit,
				confirmText = localized.actionHome,
				doNotShowText = if FFlagLuaAppExitModalDoNotShow then localized.optionDontShow else nil,
				titleBackgroundImageProps = {
					image = "rbxasset://textures/ui/LuaApp/graphic/Auth/GridBackground.jpg",
					imageHeight = 200,
					text = [[<font face="GothamBlack" size="42">]]
						.. localized.title
						.. [[</font><font size="4"><br /></font><br />]]
						.. localized.subtitle,
				},
				screenSize = CoreGui.RobloxGui.AbsoluteSize,
				onDismiss = function()
					this.DontLeaveFunc(false)
				end,
				onCancel = function(doNotShow)
					if FFlagLuaAppExitModalDoNotShow and doNotShow then
						this.DontShowAgain()
					end
					this.LeaveAppFunc(false)
				end,
				onConfirm = function(doNotShow)
					if FFlagLuaAppExitModalDoNotShow and doNotShow then
						this.DontShowAgain()
					end
					this.LeaveGameFunc(false)
				end,
			}),
		})
	end

	local exitModalTree = Roact.mount(ExitModal(), this.Page, "ExitModal")

	local debounced = false
	local updateTree = function()
		if not debounced then
			debounced = true
			task.delay(1, function()
				debounced = false
				exitModalTree = Roact.update(exitModalTree, ExitModal())
			end)
		end
	end
	LocalizationService:GetPropertyChangedSignal("RobloxLocaleId"):Connect(updateTree)
	CoreGui.RobloxGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTree)

	return this
end

----------- Public Facing API Additions --------------
PageInstance = Initialize()

PageInstance.Displayed.Event:connect(function()
	if FFlagLuaAppExitModalDoNotShow and not PageInstance.ShouldShow() then
		PageInstance.LeaveAppFunc(true)
	end

	PageInstance.dismissedFrom = "Menu"
	ContextActionService:BindCoreAction(
		LEAVE_GAME_ACTION,
		PageInstance.LeaveGameFromHotkey,
		false,
		Enum.KeyCode.ButtonA
	)
	ContextActionService:BindCoreAction(
		DONT_LEAVE_ACTION,
		PageInstance.DontLeaveFromHotkey,
		false,
		Enum.KeyCode.ButtonB
	)
end)

PageInstance.Hidden.Event:connect(function()
	if PageInstance.dismissedFrom then
		SendAnalytics(EducationalAnalytics.EventContext, EducationalAnalytics.DismissName, {
			source = PageInstance.dismissedFrom,
		})
		PageInstance.dismissedFrom = nil
	end

	ContextActionService:UnbindCoreAction(LEAVE_GAME_ACTION)
	ContextActionService:UnbindCoreAction(DONT_LEAVE_ACTION)
end)

return PageInstance
