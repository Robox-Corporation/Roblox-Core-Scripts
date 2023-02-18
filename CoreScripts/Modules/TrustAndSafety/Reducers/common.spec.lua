return function()
	local TnsModule = script.Parent.Parent
	local ShowToast = require(TnsModule.Actions.ShowToast)

	local common = require(script.Parent.common)

	describe("toastTitle", function()
		it("should update", function()
			local testText = "test text"
			local oldState = common(nil, {})
			local newState = common(oldState, ShowToast(testText))
			expect(oldState).to.never.equal(newState)
			expect(newState.toastTitle).to.equal(testText)
		end)
	end)
end
