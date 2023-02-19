return function()
	local Root = script.Parent.Parent

	local CorePackages = game:GetService("CorePackages")
	local PurchasePromptDeps = require(CorePackages.PurchasePromptDeps)
	local Rodux = PurchasePromptDeps.Rodux

	local RequestType = require(Root.Enums.RequestType)
	local PurchaseError = require(Root.Enums.PurchaseError)
	local PromptState = require(Root.Enums.PromptState)
	local Constants = require(Root.Misc.Constants)
	local Reducer = require(Root.Reducers.Reducer)
	local Network = require(Root.Services.Network)
	local Analytics = require(Root.Services.Analytics)
	local ExternalSettings = require(Root.Services.ExternalSettings)
	local MockNetwork = require(Root.Test.MockNetwork)
	local MockAnalytics = require(Root.Test.MockAnalytics)
	local MockExternalSettings = require(Root.Test.MockExternalSettings)
	local Thunk = require(Root.Thunk)

	local function getDefaultState()
		return {
			productInfo = {
				productId = 50,
			},
			requestType = RequestType.Asset,
			accountInfo = {
				AgeBracket = 0,
			},
			promptRequest = {
				id = 50,
				requestType = RequestType.Product,
				infoType = Enum.InfoType.Product
			},
		}
	end

	local purchaseItem = require(script.Parent.purchaseItem)

	it("should run without errors", function()
		local store = Rodux.Store.new(Reducer, getDefaultState())

		local network = MockNetwork.new()
		local analytics = MockAnalytics.new()

		Thunk.test(purchaseItem(), store, {
			[Network] = network,
			[Analytics] = analytics.mockService,
			[ExternalSettings] = MockExternalSettings.new(false, false, {}),
		})

		local state = store:getState()

		expect(analytics.spies.signalProductPurchaseConfirmed.callCount).to.equal(1)
		expect(analytics.spies.signalPurchaseSuccess.callCount).to.equal(1)
		expect(state.promptState).to.equal(PromptState.PurchaseInProgress)
	end)

	it("should resolve to an error state if a network error occurs", function()
		local store = Rodux.Store.new(Reducer, getDefaultState())

		local network = MockNetwork.new(nil, "Network Failure")
		local analytics = MockAnalytics.new()

		Thunk.test(purchaseItem(), store, {
			[Network] = network,
			[Analytics] = analytics.mockService,
			[ExternalSettings] = MockExternalSettings.new(false, false, {}),
		})

		local state = store:getState()

		expect(analytics.spies.signalPurchaseSuccess.callCount).to.equal(0)
		expect(state.promptState).to.equal(PromptState.Error)
	end)

	local function checkDesktop2SV(platform)
		local store = Rodux.Store.new(Reducer, getDefaultState())

		local analytics = MockAnalytics.new()

		Thunk.test(purchaseItem(), store, {
			[Analytics] = analytics.mockService,
			[Network] = MockNetwork.new({
				purchased = false,
				transactionStatus = 24, -- REMOVE WITH FFlagPPRefactorPerformPurchase
				reason = Constants.PurchaseFailureReason.TwoStepVerificationRequired,
			}),
			[ExternalSettings] = MockExternalSettings.new(false, false, {}, platform)
		})

		local state = store:getState()

		expect(analytics.spies.signalTwoSVSettingsErrorShown.callCount).to.equal(1)
		expect(state.promptState).to.equal(PromptState.Error)
		expect(state.purchaseError).to.equal(PurchaseError.TwoFactorNeededSettings)
	end

	it("should handle reason TwoStepVerificationRequired and return correct PurchaseError on Windows", function()
		checkDesktop2SV(Enum.Platform.Windows)
	end)

	it("should handle reason TwoStepVerificationRequired and return correct PurchaseError on OSX", function()
		checkDesktop2SV(Enum.Platform.OSX)
	end)

	local function checkMobile2SV(platform)
		local store = Rodux.Store.new(Reducer, getDefaultState())

		local analytics = MockAnalytics.new()

		Thunk.test(purchaseItem(), store, {
			[Analytics] = analytics.mockService,
			[Network] = MockNetwork.new({
				purchased = false,
				transactionStatus = 24, -- REMOVE WITH FFlagPPRefactorPerformPurchase
				reason = Constants.PurchaseFailureReason.TwoStepVerificationRequired,
			}),
			[ExternalSettings] = MockExternalSettings.new(false, false, {}, platform)
		})

		local state = store:getState()

		expect(analytics.spies.signalTwoSVSettingsErrorShown.callCount).to.equal(1)
		expect(state.promptState).to.equal(PromptState.Error)
		expect(state.purchaseError).to.equal(PurchaseError.TwoFactorNeeded)
	end

	it("should handle reason TwoStepVerificationRequired and return correct PurchaseError on IOS", function()
		checkMobile2SV(Enum.Platform.IOS)
	end)

	it("should handle reason TwoStepVerificationRequired and return correct PurchaseError on Android", function()
		checkMobile2SV(Enum.Platform.Android)
	end)

	it("should handle reason TwoStepVerificationRequired and return correct PurchaseError on UWP", function()
		checkMobile2SV(Enum.Platform.UWP)
	end)

	it("should handle reason TwoStepVerificationRequired and return correct PurchaseError on XBoxOne", function()
		checkMobile2SV(Enum.Platform.XBoxOne)
	end)
end
