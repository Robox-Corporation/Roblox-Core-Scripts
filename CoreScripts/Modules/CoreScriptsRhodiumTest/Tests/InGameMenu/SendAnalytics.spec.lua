--!nonstrict
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local CorePackages = game:GetService("CorePackages")
local Modules = game:GetService("CoreGui").RobloxGui.Modules

local Rhodium = require(CorePackages.Rhodium)
local VirtualInput = Rhodium.VirtualInput

local JestGlobals = require(CorePackages.JestGlobals)
local jest = JestGlobals.jest

local InGameMenu = Modules.InGameMenu
local SendAnalytics = require(InGameMenu.Utility.SendAnalytics)

local Flags = InGameMenu.Flags

return function()
	beforeAll(function()
		GuiService.SelectedCoreObject = nil
		Players.LocalPlayer.PlayerGui:ClearAllChildren()
	end)

	beforeEach(function(c)
		c.SetRBXEventStreamSpy = jest.fn()
		c.analyticsServiceImpl = {
			SetRBXEventStream = c.SetRBXEventStreamSpy
		}

		c.gamepad = Rhodium.VirtualInput.GamePad.new()
	end)

	afterEach(function(c)
		c.gamepad:disconnect()
	end)

	-- Using an integration test to use VirtualInput
	describe("SendAnalytics", function()
		it("Calls the analytics service with provided parameters", function(c)
			local analyticsServiceImpl = c.analyticsServiceImpl

			local ctx = "event_context"
			local evt = "event_name"
			local params = {testParam = "test"}

			SendAnalytics(ctx, evt, params, false, analyticsServiceImpl)

			expect(#c.SetRBXEventStreamSpy.mock.calls).to.equal(1)
			expect(c.SetRBXEventStreamSpy.mock.calls[1][2]).to.equal("client")
			expect(c.SetRBXEventStreamSpy.mock.calls[1][3]).to.equal(ctx)
			expect(c.SetRBXEventStreamSpy.mock.calls[1][4]).to.equal(evt)
			expect(c.SetRBXEventStreamSpy.mock.calls[1][5]).to.equal(params)
		end)

		it("Appends the latest used input device to the params table", function(c)
			local analyticsServiceImpl = c.analyticsServiceImpl
			local gamepad = c.gamepad

			local ctx = "event_context"
			local evt = "event_name"
			local params = {testParam = "test"}

			VirtualInput.Keyboard.pressKey(Enum.KeyCode.L)
			VirtualInput.waitForInputEventsProcessed()
			wait()

			SendAnalytics(ctx, evt, params, false, analyticsServiceImpl)

			expect(c.SetRBXEventStreamSpy.mock.calls[1][5].testParam).to.equal("test")
			expect(c.SetRBXEventStreamSpy.mock.calls[1][5].inputDevice).to.equal("MouseAndKeyboard")

			params = {testParam = "test2"}
			gamepad:hitButton(Enum.KeyCode.DPadDown)
			VirtualInput.waitForInputEventsProcessed()
			wait()

			SendAnalytics(ctx, evt, params, false, analyticsServiceImpl)
			expect(c.SetRBXEventStreamSpy.mock.calls[2][5].inputDevice).to.equal("Gamepad")
		end)

		it("Uses directly the lastUsedInput value if it's not in our mapping", function(c)
			local analyticsServiceImpl = c.analyticsServiceImpl
			local gamepad = c.gamepad

			local ctx = "event_context"
			local evt = "event_name"
			local params = {testParam = "test"}

			VirtualInput.Text.sendText("test")
			VirtualInput.waitForInputEventsProcessed()
			wait()

			SendAnalytics(ctx, evt, params, false, analyticsServiceImpl)

			expect(c.SetRBXEventStreamSpy.mock.calls[1][5].inputDevice).to.equal("Enum.UserInputType.TextInput")
		end)

		it("Appends the input even when reportSettingsForAnalytics is true", function(c)
			local analyticsServiceImpl = c.analyticsServiceImpl
			local gamepad = c.gamepad

			local ctx = "event_context"
			local evt = "event_name"
			local params = {testParam = "test"}

			VirtualInput.Keyboard.pressKey(Enum.KeyCode.L)
			VirtualInput.waitForInputEventsProcessed()
			wait()

			SendAnalytics(ctx, evt, params, true, analyticsServiceImpl)

			expect(c.SetRBXEventStreamSpy.mock.calls[1][5].camera_y_inverted).to.never.equal(nil)
			expect(c.SetRBXEventStreamSpy.mock.calls[1][5].inputDevice).to.equal("MouseAndKeyboard")
		end)

		it("Does not append setting values when reportSettingsForAnalytics is false", function(c)
			local analyticsServiceImpl = c.analyticsServiceImpl
			local gamepad = c.gamepad

			local ctx = "event_context"
			local evt = "event_name"
			local params = {testParam = "test"}

			SendAnalytics(ctx, evt, params, false, analyticsServiceImpl)

			expect(c.SetRBXEventStreamSpy.mock.calls[1][5].camera_y_inverted).to.equal(nil)
		end)
	end)
end
