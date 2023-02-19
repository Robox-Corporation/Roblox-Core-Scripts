--!nonstrict
local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Modules = CoreGui.RobloxGui.Modules
local UIBlox = require(CorePackages.UIBlox)
local Images = UIBlox.App.ImageSet.Images

local Rhodium = require(CorePackages.Rhodium)
local VirtualInput = Rhodium.VirtualInput
local Element = Rhodium.Element
local XPath = Rhodium.XPath

local InGameMenu = Modules.InGameMenu
local SetCurrentPage = require(InGameMenu.Actions.SetCurrentPage)
local SetMenuOpen = require(InGameMenu.Actions.SetMenuOpen)
local SetMainPageMoreMenuOpen = require(InGameMenu.Actions.SetMainPageMoreMenuOpen)
local SetRespawning = require(InGameMenu.Actions.SetRespawning)
local SetInputType = require(InGameMenu.Actions.SetInputType)


local Constants = require(InGameMenu.Resources.Constants)

local act = require(Modules.act)

local Flags = InGameMenu.Flags
local GetFFlagIGMGamepadSelectionHistory = require(Flags.GetFFlagIGMGamepadSelectionHistory)
local GetFFlagUseIGMControllerBar = require(Flags.GetFFlagUseIGMControllerBar)
local GetFFlagSideNavControllerBar = require(Flags.GetFFlagSideNavControllerBar)

local TestConstants = require(script.Parent.TestConstants)

return function()
	beforeEach(function(c)
		for _, child in ipairs(CoreGui:GetChildren()) do
			if child.Name == "IGMControllerBar" then
				child:Destroy()
			end
		end

		GuiService.SelectedCoreObject = nil
		Players.LocalPlayer.PlayerGui:ClearAllChildren()
		local path, store, cleanup, gamepad = c.mountIGM() -- add arguments to this in init file if needed
		c.path = path
		c.store = store
		c.cleanup = cleanup

		c.storeUpdate = function(action)
			act(function()
				store:dispatch(action)
				store:flush()
			end)
		end

		c.gamepadInput = function(input)
			act(function()
				gamepad:hitButton(input)
				VirtualInput.waitForInputEventsProcessed()
			end)
			act(function()
				wait()
			end)
		end

		c.mouseClick = function(target)
			act(function()
				target:click()
				VirtualInput.waitForInputEventsProcessed()
			end)
			act(function()
				wait()
			end)
		end

		c.keyboardInput = function(input)
			act(function()
				Rhodium.VirtualInput.Keyboard.hitKey(input)
				VirtualInput.waitForInputEventsProcessed()
			end)
			act(function()
				wait()
			end)
		end
	end)

	afterEach(function(c)
		c.cleanup()
	end)

	-- Test that focus is handed off correctly navigating between pages
	describe("In-Game Menu main page focus handoffs", function()
		it("Should select the Players menu item when main page is opened with gamepad", function(c)
			local path = c.path

			-- Input device is set to Gamepad when receiving its first gamepad input
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			local rootPath = XPath.new(path)
			local playersButtonPath = rootPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".PageNavigation.PagePlayers"))
			local playersButtonElement = Element.new(playersButtonPath)

			expect(playersButtonElement:waitForRbxInstance(1)).to.be.ok()
			expect(GuiService.SelectedCoreObject).to.equal(playersButtonElement.rbxInstance)
		end)

		it("Should gain and lose focus when user transitions between gamepad and keyboard", function(c)
			local path = c.path

			-- The last input device when getting to the page is MouseAndKeyboard
			c.keyboardInput(Enum.KeyCode.Down)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			local rootPath = XPath.new(path)
			local playersButtonPath = rootPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".PageNavigation.PagePlayers"))
			local playersButtonElement = Element.new(playersButtonPath)

			-- Nothing is selected as user gets to the page after using keyboard
			expect(GuiService.SelectedCoreObject).to.equal(nil)

			-- Input device is set to Gamepad and the menu item is focused
			c.gamepadInput(Enum.KeyCode.DPadUp)
			expect(playersButtonElement:waitForRbxInstance(1)).to.be.ok()
			expect(GuiService.SelectedCoreObject).to.equal(playersButtonElement:getRbxInstance())

			c.keyboardInput(Enum.KeyCode.Down)
			-- Nothing is selected as user goes back to using keyboard
			expect(GuiService.SelectedCoreObject).to.equal(nil)
		end)

		it("Should select the first player when moving to the Players page", function(c)
			local path = c.path

			-- Make sure the last used input device is gamepad
			c.gamepadInput(Enum.KeyCode.ButtonA)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
			act(function()
				wait()
			end)

			local originalPath = XPath.new(path)
			local playersButtonPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".PageNavigation.PagePlayers"))

			local playersButtonElement = Element.new(playersButtonPath)
			expect(playersButtonElement:waitForRbxInstance(1)).to.be.ok()

			c.gamepadInput(Enum.KeyCode.ButtonA)
			--[[
				TODO APPFDN-693: when running in studio, different mock data is being
				provided than when running in roblox-cli.
			]]
			local playerString = "player_1"
			if game:GetFastFlag("LuaMenuPerfImprovements") then
				playerString = "player_12345678"
			end
			expect(tostring(GuiService.SelectedCoreObject)).to.equal(playerString)
		end)

		it("Should select the Camera Mode dropdown when opening the settings page", function(c)
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")
		end)

		it("Should remember to select Settings option when navigating back from Settings page", function(c)
			if GetFFlagIGMGamepadSelectionHistory() then
				-- Send an input to update currently used input device
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				c.gamepadInput(Enum.KeyCode.DPadDown) -- Invite Friends
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Settings

				c.gamepadInput(Enum.KeyCode.ButtonA) -- Settings
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton") -- Focus captured on Settings

				c.gamepadInput(Enum.KeyCode.ButtonB) -- Go back
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("PageGameSettings")
			end
		end)

		it("Should move selection to Friends menu item when pushing lever down", function(c)
			local path = c.path
			-- Make sure the last used input device is gamepad
			c.gamepadInput(Enum.KeyCode.ButtonA)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			local rootPath = XPath.new(path)
			local friendsButtonPath = rootPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".PageNavigation.PageInviteFriends"))
			local friendsButtonElement = Element.new(friendsButtonPath)

			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(friendsButtonElement:waitForRbxInstance(1)).to.be.ok()
			expect(GuiService.SelectedCoreObject).to.equal(friendsButtonElement.rbxInstance)
		end)

		it("should switch between the page and SideNavigation", function(c)
			local store = c.store
			-- Make sure the last used input device is gamepad
			c.gamepadInput(Enum.KeyCode.ButtonA)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			act(function()
				wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
			end)

			expect(store:getState().currentZone).to.equal(1)

			c.gamepadInput(Enum.KeyCode.DPadLeft)
			expect(store:getState().currentZone).to.equal(0)

			c.gamepadInput(Enum.KeyCode.DPadRight)
			expect(store:getState().currentZone).to.equal(1)
		end)

		it("Forgets previous selection when menu is closed", function(c)
			if GetFFlagIGMGamepadSelectionHistory() then
				local store = c.store
				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				c.gamepadInput(Enum.KeyCode.DPadDown) -- Players option
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Invite Friends option
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("PageInviteFriends")

				c.gamepadInput(Enum.KeyCode.ButtonB) -- Close menu

				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("PagePlayers")
			end
		end)
	end)

	describe("MainPage's 'more' menu", function(c)
		it("Should open/close with mouse clicks", function(c)
			local store = c.store
			local path = c.path
			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
			act(function()
				wait(TestConstants.PageAnimationDuration)
			end)

			local originalPath = XPath.new(path)
			local moreMenuButtonPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".BottomButtons.MoreButton"))
			local moreMenuButtonElement = Element.new(moreMenuButtonPath)
			local contextualMenuPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".ContextualMenu"))
			local contextualMenuElement = Element.new(contextualMenuPath)
			local contextualMenu = contextualMenuElement:waitForRbxInstance(1)

			expect(contextualMenu.Visible).to.equal(false)

			-- Open the menu
			c.mouseClick(moreMenuButtonElement)
			expect(contextualMenu.Visible).to.equal(true)

			-- Close the menu
			c.mouseClick(moreMenuButtonElement)

			local DELAY_FOR_ANIMATION_AND_REFOCUS = 1 -- closing menu takes longer to animate
			act(function()
				wait(DELAY_FOR_ANIMATION_AND_REFOCUS)
			end)
			expect(contextualMenu.Visible).to.equal(false)

			-- Reopen menu
			c.mouseClick(moreMenuButtonElement)
			expect(contextualMenu.Visible).to.equal(true)
		end)

		it("Should open when clicking the ellipsis button, and close when pressing B", function(c)
			local store = c.store
			local path = c.path

			if GetFFlagIGMGamepadSelectionHistory() then
				-- Make sure the last used input device is gamepad
				c.gamepadInput(Enum.KeyCode.ButtonA)
			end

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
			act(function()
				wait()
			end)

			local originalPath = XPath.new(path)
			local moreMenuButtonPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".BottomButtons.MoreButton"))
			local moreMenuButtonElement = Element.new(moreMenuButtonPath)
			local moreMenuButton = moreMenuButtonElement:waitForRbxInstance(1)

			local contextualMenuPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".ContextualMenu"))
			local contextualMenuElement = Element.new(contextualMenuPath)
			local firstMenuButton = contextualMenuElement:waitForRbxInstance(1)
				:FindFirstChild("cell 1", true)
				:FindFirstChildWhichIsA("ImageButton", true)

			GuiService.SelectedCoreObject = moreMenuButton
			act(function()
				wait(0.2)
			end)

			-- Opening the menu
			c.gamepadInput(Enum.KeyCode.ButtonA)

			expect(GuiService.SelectedCoreObject).to.never.equal(nil)
			expect(GuiService.SelectedCoreObject).to.equal(firstMenuButton)

			c.gamepadInput(Enum.KeyCode.ButtonB)

			expect(GuiService.SelectedCoreObject).to.never.equal(nil)
			expect(GuiService.SelectedCoreObject).to.equal(moreMenuButton)
		end)

		it("Should close when navigating to another page", function(c)
			local store = c.store
			local path = c.path
			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
			act(function()
				wait()
			end)

			local originalPath = XPath.new(path)
			local moreMenuButtonPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".BottomButtons.MoreButton"))
			local moreMenuButtonElement = Element.new(moreMenuButtonPath)
			local moreMenuButton = moreMenuButtonElement:waitForRbxInstance(1)

			local contextualMenuPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".ContextualMenu"))
			local contextualMenuElement = Element.new(contextualMenuPath)
			local contextualMenu = contextualMenuElement:waitForRbxInstance(1)

			-- Menu starts off closed
			expect(contextualMenu.Visible).to.equal(false)
			-- Opening the menu
			GuiService.SelectedCoreObject = moreMenuButton
			act(function()
				wait(0.2)
			end)
			c.gamepadInput(Enum.KeyCode.ButtonA)

			expect(contextualMenu.Visible).to.equal(true)

			-- Switching page closes the menu
			c.gamepadInput(Enum.KeyCode.ButtonX)

			--  UI change is delayed by an animation
			act(function()
				wait(1)
			end)
			expect(contextualMenu.Visible).to.equal(false)
		end)

		it("Should close when Respawn opens", function(c)
			local store = c.store
			local path = c.path
			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
			act(function()
				wait()
			end)

			local originalPath = XPath.new(path)
			local moreMenuButtonPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".BottomButtons.MoreButton"))
			local moreMenuButtonElement = Element.new(moreMenuButtonPath)
			local moreMenuButton = moreMenuButtonElement:waitForRbxInstance(1)

			local contextualMenuPath = originalPath:cat(XPath.new(
				"PageContainer.MainPage.Page" ..
				".ContextualMenu"))
			local contextualMenuElement = Element.new(contextualMenuPath)
			local contextualMenu = contextualMenuElement:waitForRbxInstance(1)

			-- Opening the menu
			GuiService.SelectedCoreObject = moreMenuButton
			act(function()
				wait(0.2)
			end)
			c.gamepadInput(Enum.KeyCode.ButtonA)

			expect(contextualMenu.Visible).to.equal(true)

			-- Switching page closes the menu
			c.gamepadInput(Enum.KeyCode.ButtonY)

			--  UI change is delayed by an animation
			act(function()
				wait(1)
			end)
			expect(contextualMenu.Visible).to.equal(false)
		end)
	end)

	describe("In-Game Menu Shortcuts", function(c)
		it("Should open the Leave game page when pressing X", function(c)
			local store = c.store

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			c.gamepadInput(Enum.KeyCode.ButtonX)
			expect(tostring(store:getState().menuPage)).to.equal("LeaveGamePrompt")
		end)

		it("Should open the Respawn dialog when pressing Y", function(c)
			local store = c.store

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			c.gamepadInput(Enum.KeyCode.ButtonY)
			expect(store:getState().respawn.dialogOpen).to.equal(true)
		end)

		it("Should not bumper switch if menu closed", function(c)
			local store = c.store

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetMenuOpen(false))

			c.gamepadInput(Enum.KeyCode.ButtonL1)
			expect(store:getState().currentZone).to.equal(1)
			c.gamepadInput(Enum.KeyCode.ButtonR1)
			expect(store:getState().currentZone).to.equal(1)
		end)

		it("Should bumper switch", function(c)
			local store = c.store

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

			c.gamepadInput(Enum.KeyCode.ButtonL1)
			expect(store:getState().currentZone).to.equal(0)
			c.gamepadInput(Enum.KeyCode.ButtonR1)
			expect(store:getState().currentZone).to.equal(1)
		end)

		if GetFFlagUseIGMControllerBar() then
			it("Should open and close more menu when clicking left stick", function(c)
				local originalPath = XPath.new(c.path)

				-- Send an input to update currently used input device
				c.gamepadInput(Enum.KeyCode.DPadDown)

				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				local contextualMenuPath = originalPath:cat(XPath.new(
					"PageContainer.MainPage.Page" ..
					".ContextualMenu"))
				local contextualMenuElement = Element.new(contextualMenuPath)
				local contextualMenu = contextualMenuElement:waitForRbxInstance(1)

				-- Menu starts off closed
				expect(contextualMenu.Visible).to.equal(false)

				c.gamepadInput(Enum.KeyCode.ButtonL3)

				expect(contextualMenu.Visible).to.equal(true)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("Cell") -- Highlights more menu
				wait(3) -- wait for animation
				c.gamepadInput(Enum.KeyCode.ButtonL3)
				wait(3) -- wait for animation
				expect(contextualMenu.Visible).to.equal(false)
				if GetFFlagIGMGamepadSelectionHistory() then
					-- Remembers to highlight previously highlighted Players option
					expect(tostring(GuiService.SelectedCoreObject)).to.equal("PagePlayers")
				end
			end)
		end
	end)

	describe("Controller Bar", function()
		if GetFFlagUseIGMControllerBar() then
			it("Should render ControllerBar when menu is open", function(c)
				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				-- Send an input to update currently used input device
				c.gamepadInput(Enum.KeyCode.DPadDown)


				local controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
				expect(controllerBarElement).to.be.ok()
				expect(#controllerBarElement:GetChildren()).to.equal(3)

				-- ensure correct text is rendered
				local leftFrame = controllerBarElement:FindFirstChild("LeftFrame")
				local rightFrame = controllerBarElement:FindFirstChild("RightFrame")

				expect(leftFrame:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Back")

				expect(rightFrame:GetChildren()[1]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Open More Menu")
				expect(rightFrame:GetChildren()[2]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Respawn Character")
				expect(rightFrame:GetChildren()[3]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Leave")
			end)
			it("Should change text when more menu is opened", function(c)
				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				-- Send an input to update currently used input device
				c.gamepadInput(Enum.KeyCode.DPadDown)


				local controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
				expect(controllerBarElement).to.be.ok()
				expect(#controllerBarElement:GetChildren()).to.equal(3)

				c.gamepadInput(Enum.KeyCode.ButtonL3)

				-- ensure correct text is rendered
				local leftFrame = controllerBarElement:FindFirstChild("LeftFrame")
				local rightFrame = controllerBarElement:FindFirstChild("RightFrame")

				expect(leftFrame:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Back")

				expect(rightFrame:GetChildren()[1]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Close More Menu")
				expect(rightFrame:GetChildren()[2]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Respawn Character")
				expect(rightFrame:GetChildren()[3]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Leave")
			end)
			it("Should change text when respawn dialog is opened", function(c)
				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))
				c.storeUpdate(SetRespawning(true))

				-- Send an input to update currently used input device
				c.gamepadInput(Enum.KeyCode.DPadDown)


				local controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
				expect(controllerBarElement).to.be.ok()
				expect(#controllerBarElement:GetChildren()).to.equal(3)

				-- ensure correct text is rendered
				local leftFrame = controllerBarElement:FindFirstChild("LeftFrame")
				local rightFrame = controllerBarElement:FindFirstChild("RightFrame")

				expect(leftFrame:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Cancel")

				expect(rightFrame:GetChildren()[1]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Respawn")
			end)
			it("Should show and hide ControllerBar depending on last used input", function(c)
				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				-- Should not display controllerbar when MouseAndKeyboard are last used input
				c.storeUpdate(SetInputType(Constants.InputType.MouseAndKeyboard))

				local controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
				expect(controllerBarElement).never.to.be.ok()

				-- Should appear when we use gamepad
				c.storeUpdate(SetInputType(Constants.InputType.Gamepad))

				controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
				expect(controllerBarElement).to.be.ok()

				-- Should disappear when we use keyboard again
				c.storeUpdate(SetInputType(Constants.InputType.MouseAndKeyboard))

				controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
				expect(controllerBarElement).never.to.be.ok()
			end)
			if GetFFlagSideNavControllerBar() then
				it("Should render ControllerBar when selecting side navigation", function(c)
					c.storeUpdate(SetMenuOpen(true))
					c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

					act(function()
						wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
					end)

					-- Send an input to update currently used input device
					c.gamepadInput(Enum.KeyCode.DPadDown)
					c.gamepadInput(Enum.KeyCode.DPadLeft)

					expect(tostring(GuiService.SelectedCoreObject)).to.equal("CloseMenuButton")

					local controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
					expect(controllerBarElement).to.be.ok()
					expect(#controllerBarElement:GetChildren()).to.equal(3)

					-- ensure correct text is rendered
					local leftFrame = controllerBarElement:FindFirstChild("LeftFrame")
					local rightFrame = controllerBarElement:FindFirstChild("RightFrame")

					expect(leftFrame:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Back")

					expect(rightFrame:GetChildren()[1]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Open More Menu")
					expect(rightFrame:GetChildren()[2]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Respawn Character")
					expect(rightFrame:GetChildren()[3]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Leave")
				end)

				it("Should open more menu with left stickfrom side navigation", function(c)
					local originalPath = XPath.new(c.path)

					c.storeUpdate(SetMenuOpen(true))
					c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

					local contextualMenuPath = originalPath:cat(XPath.new(
						"PageContainer.MainPage.Page" ..
						".ContextualMenu"))
					local contextualMenuElement = Element.new(contextualMenuPath)
					local contextualMenu = contextualMenuElement:waitForRbxInstance(1)

					act(function()
						wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
					end)

					-- Send an input to update currently used input device
					c.gamepadInput(Enum.KeyCode.DPadDown)
					c.gamepadInput(Enum.KeyCode.DPadLeft)

					expect(tostring(GuiService.SelectedCoreObject)).to.equal("CloseMenuButton")

					-- Menu starts off closed
					expect(contextualMenu.Visible).to.equal(false)

					c.gamepadInput(Enum.KeyCode.ButtonL3)
					wait(TestConstants.OpenMoreMenuAnimationDuration) -- wait for animation
					expect(contextualMenu.Visible).to.equal(true)

					local controllerBarElement = CoreGui:FindFirstChild("ControllerBar", true)
					expect(controllerBarElement).to.be.ok()
					expect(#controllerBarElement:GetChildren()).to.equal(3)

					-- ensure correct text is rendered
					local leftFrame = controllerBarElement:FindFirstChild("LeftFrame")
					local rightFrame = controllerBarElement:FindFirstChild("RightFrame")

					expect(leftFrame:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Back")

					expect(rightFrame:GetChildren()[1]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Close More Menu")
					expect(rightFrame:GetChildren()[2]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Respawn Character")
					expect(rightFrame:GetChildren()[3]:FindFirstChild("ControllerBarHintText", true).Text).to.equal("Leave")

					c.gamepadInput(Enum.KeyCode.ButtonL3)
					wait(TestConstants.CloseMoreMenuAnimationDuration) -- wait for animation
					expect(contextualMenu.Visible).to.equal(false)
				end)
			end
		end
	end)

	it("should toggle keyboard-specific UI elements on user input", function(c)
		local path = XPath.new(c.path)

		c.storeUpdate(SetMenuOpen(true))
		c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

		local mainPagePath = path:cat(XPath.new("PageContainer.MainPage.Page"))

		local leaveGameKeyLabelPath_Gamepad = mainPagePath:cat(XPath.new("BottomButtons.LeaveGame.KeyLabel"))
		local leaveGameKeyLabelPath_Keyboard = leaveGameKeyLabelPath_Gamepad:cat(XPath.new("LabelContent"))

		local respawnKeyLabelPath_Gamepad
		local respawnKeyLabelPath_Keyboard
		if game:GetFastFlag("TakeAScreenshotOfThis") then
			respawnKeyLabelPath_Gamepad = mainPagePath:cat(XPath.new("ContextualMenu.PositionFrame.BaseMenu.ClippingFrame.ScrollingFrame.cell 3.Cell.RightAlignedContent.KeyLabel"))
			respawnKeyLabelPath_Keyboard = respawnKeyLabelPath_Gamepad:cat(XPath.new("LabelContent"))
		else
			respawnKeyLabelPath_Gamepad = mainPagePath:cat(XPath.new("ContextualMenu.PositionFrame.BaseMenu.ClippingFrame.ScrollingFrame.cell 1.Cell.RightAlignedContent.KeyLabel"))
			respawnKeyLabelPath_Keyboard = respawnKeyLabelPath_Gamepad:cat(XPath.new("LabelContent"))
		end

		c.keyboardInput(Enum.KeyCode.A)

		do
			local leaveGameKeyLabel = Element.new(leaveGameKeyLabelPath_Keyboard):getRbxInstance()
			expect(leaveGameKeyLabel).to.be.ok()
			expect(leaveGameKeyLabel.Text).to.equal("L")

			local respawnKeyLabel = Element.new(respawnKeyLabelPath_Keyboard):getRbxInstance()
			expect(respawnKeyLabel).to.be.ok()
			expect(respawnKeyLabel.Text).to.equal("R")
		end

		c.gamepadInput(Enum.KeyCode.DPadDown)

		local ButtonX = Images["icons/controls/keys/xboxX"]
		local leaveGameKeyLabel = Element.new(leaveGameKeyLabelPath_Gamepad):getRbxInstance()
		expect(leaveGameKeyLabel).to.be.ok()
		expect(leaveGameKeyLabel.Image).to.equal(ButtonX.Image)
		expect(leaveGameKeyLabel.ImageRectOffset).to.equal(ButtonX.ImageRectOffset)
		expect(leaveGameKeyLabel.ImageRectSize).to.equal(ButtonX.ImageRectSize)

		local ButtonY = Images["icons/controls/keys/xboxY"]
		local respawnKeyLabel = Element.new(respawnKeyLabelPath_Gamepad):getRbxInstance()
		expect(respawnKeyLabel).to.be.ok()
		expect(respawnKeyLabel.Image).to.equal(ButtonY.Image)
		expect(respawnKeyLabel.ImageRectOffset).to.equal(ButtonY.ImageRectOffset)
		expect(respawnKeyLabel.ImageRectSize).to.equal(ButtonY.ImageRectSize)

		c.keyboardInput(Enum.KeyCode.A)

		do
			local leaveGameKeyLabel = Element.new(leaveGameKeyLabelPath_Keyboard):getRbxInstance()
			expect(leaveGameKeyLabel).to.be.ok()
			expect(leaveGameKeyLabel.Text).to.equal("L")

			local respawnKeyLabel = Element.new(respawnKeyLabelPath_Keyboard):getRbxInstance()
			expect(respawnKeyLabel).to.be.ok()
			expect(respawnKeyLabel.Text).to.equal("R")
		end
	end)
end
