--!nonstrict
local Root = script.Parent.Parent.Parent
local GuiService = game:GetService("GuiService")

local CorePackages = game:GetService("CorePackages")
local PurchasePromptDeps = require(CorePackages.PurchasePromptDeps)
local Roact = PurchasePromptDeps.Roact

local PurchaseFlow = require(Root.Enums.PurchaseFlow)

local completeRequest = require(Root.Thunks.completeRequest)
local purchaseItem = require(Root.Thunks.purchaseItem)
local launchRobuxUpsell = require(Root.Thunks.launchRobuxUpsell)
local openRobuxStore = require(Root.Thunks.openRobuxStore)
local openSecuritySettings = require(Root.Thunks.openSecuritySettings)
local openTermsOfUse = require(Root.Thunks.openTermsOfUse)
local initiatePurchasePrecheck = require(Root.Thunks.initiatePurchasePrecheck)
local sendEvent = require(Root.Thunks.sendEvent)
local isMockingPurchases = require(Root.Utils.isMockingPurchases)
local getPlayerPrice = require(Root.Utils.getPlayerPrice)
local isLinksAllowed = require(Root.Utils.isLinksAllowed)
local connectToStore = require(Root.connectToStore)

local ExternalEventConnection = require(Root.Components.Connection.ExternalEventConnection)

local RobuxUpsellOverlay = require(script.Parent.RobuxUpsellOverlay)

local RobuxUpsellContainer = Roact.Component:extend(script.Name)

function RobuxUpsellContainer:init()
	self.state = {
		screenSize = Vector2.new(0, 0),
	}

	self.changeScreenSize = function(rbx)
		if self.state.screenSize ~= rbx.AbsoluteSize then
			self:setState({
				screenSize = rbx.AbsoluteSize,
			})
		end
	end
end

function RobuxUpsellContainer:render()
	local props = self.props
	local state = self.state

	if props.purchaseFlow ~= PurchaseFlow.RobuxUpsellV2 and props.purchaseFlow ~= PurchaseFlow.LargeRobuxUpsell then
		return nil
	end

	local allowLinks = isLinksAllowed()

	local imageIcon = props.productInfo.imageUrl
	if string.find(props.productInfo.imageUrl, "assetid=0") then
		imageIcon = nil
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		[Roact.Change.AbsoluteSize] = self.changeScreenSize,
		BackgroundTransparency = 1,
	}, {
		Prompt = Roact.createElement(RobuxUpsellOverlay, {
			screenSize = state.screenSize,

			requestType = props.requestType,

			promptState = props.promptState,
			purchaseFlow = props.purchaseFlow,
			purchaseError = props.purchaseError,

			robuxProviderId = props.nativeUpsell.robuxProductId,
			robuxProductId = props.nativeUpsell.productId,

			itemIcon = imageIcon,
			itemName = props.productInfo.name,
			itemRobuxCost = getPlayerPrice(props.productInfo, props.accountInfo.membershipType == 4),
			iapRobuxAmount = props.nativeUpsell.robuxPurchaseAmount or 0,
			beforeRobuxBalance = props.accountInfo.balance,

			isTestPurchase = props.isTestPurchase,
			isGamepadEnabled = props.isGamepadEnabled,

			purchaseItem = props.purchaseItem,
			promptRobuxPurchase = props.promptRobuxPurchase,
			openRobuxStore = props.openRobuxStore,
			openTermsOfUse = allowLinks and props.openTermsOfUse or nil,
			openSecuritySettings = allowLinks and props.openSecuritySettings or nil,
			dispatchFetchPurchaseWarning = props.dispatchFetchPurchaseWarning,
			endPurchase = props.completeRequest,

			onAnalyticEvent = props.onAnalyticEvent,
		}),
		-- UIBlox components do not have Modal == true to fix FPS interaction with modals
		ModalFix = Roact.createElement("ImageButton", {
			BackgroundTransparency = 0,
			Modal = true,
			Size = UDim2.new(0, 0, 0, 0),
		}),
		OnCoreGuiMenuOpened = Roact.createElement(ExternalEventConnection, {
			event = GuiService.MenuOpened,
			callback = function()
				props.completeRequest()
			end,
		})
	})
end

RobuxUpsellContainer = connectToStore(
	function(state)
		return {
			purchaseFlow = state.purchaseFlow,
			requestType = state.promptRequest.requestType,

			promptState = state.promptState,
			purchaseError = state.purchaseError,

			productInfo = state.productInfo,
			accountInfo = state.accountInfo,
			nativeUpsell = state.nativeUpsell,

			isTestPurchase = isMockingPurchases(),
			isGamepadEnabled = state.gamepadEnabled,
		}
	end,
	function(dispatch)
		return {
			purchaseItem = function()
				return dispatch(purchaseItem())
			end,
			promptRobuxPurchase = function()
				return dispatch(launchRobuxUpsell())
			end,
			openRobuxStore = function()
				return dispatch(openRobuxStore())
			end,
			openSecuritySettings = function()
				return dispatch(openSecuritySettings())
			end,
			openTermsOfUse = function()
				return dispatch(openTermsOfUse())
			end,
			dispatchFetchPurchaseWarning = function()
				return dispatch(initiatePurchasePrecheck())
			end,
			completeRequest = function()
				return dispatch(completeRequest())
			end,
			onAnalyticEvent = function(name, data)
				return dispatch(sendEvent(name, data))
			end,
		}
	end
)(RobuxUpsellContainer)

return RobuxUpsellContainer
