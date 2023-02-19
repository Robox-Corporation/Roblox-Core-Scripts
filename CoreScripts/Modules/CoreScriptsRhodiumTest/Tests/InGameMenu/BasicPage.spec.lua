--!nonstrict
local CorePackages = game:GetService("CorePackages")
local Modules = game:GetService("CoreGui").RobloxGui.Modules
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local Rhodium = require(CorePackages.Rhodium)
local VirtualInput = Rhodium.VirtualInput
local Element = Rhodium.Element
local XPath = Rhodium.XPath
local act = require(Modules.act)

local InGameMenu = Modules.InGameMenu
local SetCurrentPage = require(InGameMenu.Actions.SetCurrentPage)
local SetMenuOpen = require(InGameMenu.Actions.SetMenuOpen)
local Constants = require(InGameMenu.Resources.Constants)
local Flags = InGameMenu.Flags
local GetFFlagIGMGamepadSelectionHistory = require(Flags.GetFFlagIGMGamepadSelectionHistory)

local TestConstants = require(script.Parent.TestConstants)

return function()
	beforeAll(function()
		UserGameSettings.MasterVolume = 0.5
	end)

	beforeEach(function(c)
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

		-- Because of how we process slider events using heartbeat,
		-- press and release events need to occur over at least two frames
		c.gamepadInputAcrossTwoFrames = function(input)
			act(function()
				gamepad:pressButton(input)
				VirtualInput.waitForInputEventsProcessed()
				wait()
			end)
			act(function()
				gamepad:releaseButton(input)
				VirtualInput.waitForInputEventsProcessed()
				wait()
			end)
		end
	end)

	afterEach(function(c)
		c.cleanup()
	end)

	describe("In-Game Menu Settings page focus management", function()
		it("Should select the first option when opening the Camera Mode dropdown page", function(c)
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))
			act(function()
				wait()
			end)

			c.gamepadInput(Enum.KeyCode.ButtonA)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("button1")
		end)

		it("The dropdown dismisses by pressing A (to select an option)", function(c)
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))
			act(function()
				wait()
			end)

			c.gamepadInput(Enum.KeyCode.ButtonA)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("button1")

			c.gamepadInput(Enum.KeyCode.ButtonA)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")
		end)

		it("The dropdown dismisses by pressing B, then returns focus to close the page by pressing B", function(c)
			local store = c.store
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))
			act(function()
				wait()
			end)

			c.gamepadInput(Enum.KeyCode.ButtonA)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("button1")

			c.gamepadInput(Enum.KeyCode.ButtonB)
			expect(store:getState().menuPage).to.equal("GameSettings")
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")

			c.gamepadInput(Enum.KeyCode.ButtonB)
			expect(store:getState().menuPage).to.equal(Constants.MainPagePageKey)
		end)

		it("If the respawn dialog is opened, dropdowns close", function(c)
			local path = c.path
			local store = c.store
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))
			act(function()
				wait()
			end)

			local rootPath = XPath.new(path)
			local settingsPagePath = rootPath:cat(XPath.new("PageContainer.GameSettings"))
			local settingsPage = Element.new(settingsPagePath)
			expect(settingsPage:waitForRbxInstance(1)).to.be.ok()

			-- Opens the dropdown
			c.gamepadInput(Enum.KeyCode.ButtonA)
			local shadow = settingsPage.rbxInstance:findFirstChild("DropDownShadow", true)
			expect(shadow.Visible).to.equal(true)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("button1")

			-- Opens the Respawn dialog
			c.gamepadInput(Enum.KeyCode.ButtonY)
			expect(store:getState().respawn.dialogOpen).to.equal(true)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("ConfirmButton")
			expect(shadow.Visible).to.equal(false) -- Dropdown closed

			-- Closes the Respawn dialog, focus goes back to closed dropdown
			c.gamepadInput(Enum.KeyCode.ButtonB)
			expect(store:getState().respawn.dialogOpen).to.equal(false)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")
		end)

		it("Keeps selection within a dropdown when one is focused", function(c)
			if game:GetEngineFeature("CoreGuiGamepadImprovementsEnabled") then
				-- Send an input to update UserInputService.GamepadEnabled
				c.gamepadInput(Enum.KeyCode.DPadDown)

				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage("GameSettings"))
				act(function()
					wait()
				end)

				-- Opens the dropdown
				c.gamepadInput(Enum.KeyCode.ButtonA)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("button1")

				-- Moves selection down to fourth option
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.gamepadInput(Enum.KeyCode.DPadDown)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("button3")

				-- Attempts moving selection further down, but stays put
				c.gamepadInput(Enum.KeyCode.DPadDown)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("button3")
			end
		end)

		it("Keeps selection within a dropdown when one is focused (second dropdown in the page)", function(c)
			if game:GetEngineFeature("CoreGuiGamepadImprovementsEnabled") then
				local path = c.path
				-- Send an input to update UserInputService.GamepadEnabled
				c.gamepadInput(Enum.KeyCode.DPadDown)

				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage("GameSettings"))
				act(function()
					wait()
				end)

				local rootPath = XPath.new(path)
				local movementModeDropdownPath = rootPath:cat(XPath.new(
					"PageContainer.GameSettings.Page" ..
					".PageContainer.PageContents.MovementModeEntrySelector" ..
					".Dropdown.OpenDropDownButton"))
				local movementModeDropdownElement = Element.new(movementModeDropdownPath)
				local movementModeDropdown = movementModeDropdownElement:getRbxInstance()

				-- Focus on the second dropdown in the page
				act(function()
					wait()
				end)
				GuiService.SelectedCoreObject = movementModeDropdown
				act(function()
					wait()
				end)

				-- Opens the dropdown
				c.gamepadInput(Enum.KeyCode.ButtonA)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("button1")

				-- Moves selection down to fourth option
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.gamepadInput(Enum.KeyCode.DPadDown)
				c.gamepadInput(Enum.KeyCode.DPadDown)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("button3")

				-- Attempts moving selection further down, but stays put
				c.gamepadInput(Enum.KeyCode.DPadDown)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("button3")
			end
		end)

		it("should switch between the page and SideNavigation", function(c)
			local store = c.store

			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			act(function()
				wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
			end)

			expect(store:getState().currentZone).to.equal(1)

			c.gamepadInput(Enum.KeyCode.DPadLeft)
			expect(store:getState().currentZone).to.equal(0)

			c.gamepadInput(Enum.KeyCode.DPadRight)
			expect(store:getState().currentZone).to.equal(1)
		end)

		it("Should bumper switch", function(c)
			local store = c.store

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			c.gamepadInput(Enum.KeyCode.ButtonL1)
			expect(store:getState().currentZone).to.equal(0)
			c.gamepadInput(Enum.KeyCode.ButtonR1)
			expect(store:getState().currentZone).to.equal(1)
		end)
	end)

	describe("Navigation flows as expected", function()
		it("Selection hits all list elements in expected order, top down", function(c)
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))
			act(function()
				wait()
			end)

			-- First item is CameraMode dropdown
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Camera sensitivity slider dot
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Shift lock switch
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Toggle")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Movement mode
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Volume
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Graphics quality Auto
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Toggle")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Graphics quality slider
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Full screen
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Toggle")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Advanced Settings
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("AdvancedSettings")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- bottom of the list
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("AdvancedSettings")
		end)

		it("Selection comes back to 'Advanced Settings' button when coming back from it", function(c)
			if GetFFlagIGMGamepadSelectionHistory() then
				-- Send an input to update currently used input device
				c.gamepadInput(Enum.KeyCode.DPadDown)

				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage("GameSettings"))
				act(function()
					wait()
				end)

				-- First item is CameraMode dropdown
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Camera sensitivity slider dot
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Shift lock switch
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Movement mode
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Volume
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Graphics quality Auto
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Graphics quality slider
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Full screen
				c.gamepadInput(Enum.KeyCode.DPadDown)-- Advanced Settings

				c.gamepadInput(Enum.KeyCode.DPadDown) -- bottom of the list
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("AdvancedSettings")
				c.gamepadInput(Enum.KeyCode.ButtonA) -- Open advanced settings
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("Toggle") -- Performance stats
				c.gamepadInput(Enum.KeyCode.ButtonB) -- Back out
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("AdvancedSettings")
			end
		end)

		it("Slider selection moves as expected", function(c)
			-- Send an input to update currently used input device
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))
			act(function()
				wait()
			end)

			-- First item is CameraMode dropdown
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Camera sensitivity slider dot
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadRight)

			-- Camera sensitivity slider text box
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			c.gamepadInput(Enum.KeyCode.DPadRight)

			-- Doesn't move from right
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			c.gamepadInput(Enum.KeyCode.DPadLeft)

			-- Moves back to dot with left
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Moves down from dot
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Toggle")

			c.gamepadInput(Enum.KeyCode.DPadUp)

			-- Moves back up
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadRight)

			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			c.gamepadInput(Enum.KeyCode.DPadDown)

			-- Moves down from text box
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Toggle")

			c.gamepadInput(Enum.KeyCode.DPadUp)
			c.gamepadInput(Enum.KeyCode.DPadRight)

			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")


			c.gamepadInput(Enum.KeyCode.DPadUp)

			-- Moves up from text box
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")

			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			c.gamepadInput(Enum.KeyCode.DPadUp)

			-- Moves up from slider dot
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("OpenDropDownButton")
		end)
	end)

	describe("IGM slider with gamepad", function()
		local function getSliderInstance(rootPath)
			local rootPath = XPath.new(rootPath)
			local sliderPath = rootPath:cat(XPath.new(
				"PageContainer.GameSettings.Page" ..
				".PageContainer.PageContents.VolumeSlider" ..
				".Slider.Slider.DotTrack.Dot"))

			local sliderElement = Element.new(sliderPath)
			return sliderElement:getRbxInstance()
		end

		local function getSliderTextBoxInstance(rootPath)
			local rootPath = XPath.new(rootPath)
			local sliderTextBoxPath = rootPath:cat(XPath.new(
				"PageContainer.GameSettings.Page" ..
				".PageContainer.PageContents.VolumeSlider" ..
				".Slider.TextContainer.Box"))

			local sliderTextBox = Element.new(sliderTextBoxPath)
			return sliderTextBox:getRbxInstance()
		end


		it("When selecting slider dot with gamepad, entry mode locks navigation", function(c)
			local path = c.path

			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			act(function()
				wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
			end)

			-- select the slider
			act(function()
				GuiService.SelectedCoreObject = getSliderInstance(path)
				wait()
			end)

			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			-- select slider
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- ensure that once the slider is selected, user can't navigate away
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			-- unselect, now we should be able to navigate away
			c.gamepadInput(Enum.KeyCode.ButtonA)
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).never.to.equal("Dot")

			-- Navigate back to slider
			c.gamepadInput(Enum.KeyCode.DPadUp)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			-- Now let's try entering selection mode and backing out with B
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- ensure that once the slider is selected, user can't navigate away
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")

			-- unselect, now we should be able to navigate away
			c.gamepadInput(Enum.KeyCode.ButtonB)
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).never.to.equal("Dot")
		end)

		it("When selecting slider text box with gamepad, entry mode locks navigation", function(c)
			local path = c.path

			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			act(function()
				wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
			end)

			-- select the text box
			act(function()
				GuiService.SelectedCoreObject = getSliderTextBoxInstance(path)
				wait()
			end)

			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			-- select text box
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- ensure that once the text box is selected, user can't navigate away
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			-- unselect, now we should be able to navigate away
			c.gamepadInput(Enum.KeyCode.ButtonA)
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).never.to.equal("Box")

			-- Navigate back up
			c.gamepadInput(Enum.KeyCode.DPadUp)
			c.gamepadInput(Enum.KeyCode.DPadRight)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			-- Now let's try entering selection mode and backing out with B
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- ensure that once the slider is selected, user can't navigate away
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			-- unselect, now we should be able to navigate away
			c.gamepadInput(Enum.KeyCode.ButtonB)
			c.gamepadInput(Enum.KeyCode.DPadDown)
			expect(tostring(GuiService.SelectedCoreObject)).never.to.equal("Box")
		end)

		it("Moving slider dot changes value, A confirms and B reverts", function(c)
			local path = c.path

			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			act(function()
				wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
			end)

			-- select the slider
			act(function()
				GuiService.SelectedCoreObject = getSliderInstance(path)
				wait()
			end)

			-- get reference to text box
			local sliderTextBox = getSliderTextBoxInstance(path)
			local initialValue = tonumber(sliderTextBox.Text)

			-- select slider
			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Dot")
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- increment slider value by 2
			c.gamepadInputAcrossTwoFrames(Enum.KeyCode.DPadRight)
			c.gamepadInputAcrossTwoFrames(Enum.KeyCode.DPadRight)

			-- confirm our change in value
			c.gamepadInput(Enum.KeyCode.ButtonA)

			expect(tonumber(sliderTextBox.Text)).to.equal(initialValue + 2)

			-- Now try decreasing value, and reverting change with B
			-- select slider
			c.gamepadInput(Enum.KeyCode.ButtonA)
			-- decrease slider value by 2
			c.gamepadInputAcrossTwoFrames(Enum.KeyCode.DPadLeft)
			c.gamepadInputAcrossTwoFrames(Enum.KeyCode.DPadLeft)

			-- revert our change in value
			c.gamepadInput(Enum.KeyCode.ButtonB)
			expect(tonumber(sliderTextBox.Text)).to.equal(initialValue + 2)
		end)

		it("Entering text box values changes slider value, A confirms and B reverts", function(c)
			local path = c.path
			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(SetCurrentPage("GameSettings"))

			act(function()
				wait(TestConstants.PageAnimationDuration) -- Wait for the page to finish animating in
			end)

			-- select the text box
			act(function()
				GuiService.SelectedCoreObject = getSliderTextBoxInstance(path)
				wait()
			end)

			expect(tostring(GuiService.SelectedCoreObject)).to.equal("Box")

			-- get reference to the slider
			local sliderElement = getSliderInstance(path)
			local initialValue = sliderElement.Position

			-- select text box
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- change value
			GuiService.SelectedCoreObject.Text = "1"

			-- confirm our change in value
			c.gamepadInput(Enum.KeyCode.ButtonA)
			expect(sliderElement.Position).never.to.equal(initialValue)
			local newValue = sliderElement.Position

			-- Now try decreasing value, and reverting change with B
			-- select text box
			c.gamepadInput(Enum.KeyCode.ButtonA)

			-- change value
			GuiService.SelectedCoreObject.Text = "10"

			-- revert our change in value
			c.gamepadInput(Enum.KeyCode.ButtonB)
			expect(sliderElement.Position).to.equal(newValue)
		end)
	end)
end
