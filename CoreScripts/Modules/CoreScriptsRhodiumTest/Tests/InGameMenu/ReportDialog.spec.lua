--!nonstrict
local CorePackages = game:GetService("CorePackages")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Modules = game:GetService("CoreGui").RobloxGui.Modules

local Rhodium = require(CorePackages.Rhodium)
local VirtualInput = Rhodium.VirtualInput
local act = require(Modules.act)

local InGameMenu = Modules.InGameMenu
local OpenReportDialog = require(InGameMenu.Actions.OpenReportDialog)
local OpenReportSentDialog = require(InGameMenu.Actions.OpenReportSentDialog)

local Constants = require(InGameMenu.Resources.Constants)
local SetMenuOpen = require(InGameMenu.Actions.SetMenuOpen)
local SetCurrentPage = require(InGameMenu.Actions.SetCurrentPage)

local Flags = InGameMenu.Flags
local GetFFlagIGMGamepadSelectionHistory = require(Flags.GetFFlagIGMGamepadSelectionHistory)

return function()
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
	end)

	afterEach(function(c)
		c.cleanup()
	end)

	describe("ReportDialog gamepad focus management", function()
		it("Should not bumper switch on ReportDialog", function(c)
			local store = c.store

			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(OpenReportDialog(12, "mr f"))

			c.gamepadInput(Enum.KeyCode.ButtonL1)
			expect(store:getState().currentZone).to.equal(1)
			c.gamepadInput(Enum.KeyCode.ButtonR1)
			expect(store:getState().currentZone).to.equal(1)
		end)

        it("Should not bumper switch on ReportSentDialog", function(c)
			local store = c.store

			-- Send an input to update UserInputService.GamepadEnabled
			c.gamepadInput(Enum.KeyCode.DPadDown)

			c.storeUpdate(SetMenuOpen(true))
			c.storeUpdate(OpenReportSentDialog(12, "mr f"))

			c.gamepadInput(Enum.KeyCode.ButtonL1)
			expect(store:getState().currentZone).to.equal(1)
			c.gamepadInput(Enum.KeyCode.ButtonR1)
			expect(store:getState().currentZone).to.equal(1)
		end)

		it("Should not remember the last highligted element when opened", function(c)
			if GetFFlagIGMGamepadSelectionHistory() then
				local store = c.store


				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				c.gamepadInput(Enum.KeyCode.DPadDown) -- Players
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Friends
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Settings
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Report

				c.gamepadInput(Enum.KeyCode.ButtonA) -- Open Report
				c.gamepadInput(Enum.KeyCode.ButtonA) -- Report game
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("TextBox")

				c.gamepadInput(Enum.KeyCode.DPadDown)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("CancelButton")

				c.gamepadInput(Enum.KeyCode.ButtonB) -- Close dialog
				c.gamepadInput(Enum.KeyCode.ButtonA) -- Report game
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("TextBox")
			end
		end)

		it("Should remember the last highligted element when coming back from another dialog", function(c)
			if GetFFlagIGMGamepadSelectionHistory() then
				local store = c.store

				c.storeUpdate(SetMenuOpen(true))
				c.storeUpdate(SetCurrentPage(Constants.MainPagePageKey))

				c.gamepadInput(Enum.KeyCode.DPadDown) -- Players
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Friends
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Settings
				c.gamepadInput(Enum.KeyCode.DPadDown) -- Report

				c.gamepadInput(Enum.KeyCode.ButtonA) -- Open Report
				c.gamepadInput(Enum.KeyCode.ButtonA) -- Report game
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("TextBox")

				c.gamepadInput(Enum.KeyCode.DPadDown)
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("CancelButton")

				c.gamepadInput(Enum.KeyCode.ButtonY) -- Respawn dialog
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("ConfirmButton")

				c.gamepadInput(Enum.KeyCode.ButtonB) -- Report game
				expect(tostring(GuiService.SelectedCoreObject)).to.equal("CancelButton")
			end
		end)
	end)
end
