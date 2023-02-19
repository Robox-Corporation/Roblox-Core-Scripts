--!nonstrict
--!nolint DeprecatedApi
local Root = script.Parent.Parent
local CorePackages = game:GetService("CorePackages")
local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local PlatformService = nil
pcall(function()
	PlatformService = game:GetService("PlatformService")
end)

local PurchasePromptDeps = require(CorePackages.PurchasePromptDeps)
local UrlBuilder = PurchasePromptDeps.UrlBuilder.UrlBuilder

local BASE_URL = string.gsub(ContentProvider.BaseUrl:lower(), "/m.", "/www.")

local PlatformInterface = {}

function PlatformInterface.new()
	local service = {}

	setmetatable(service, {
		__tostring = function()
			return "Service(PlatformInterface)"
		end,
	})

	function service.signalMockPurchasePremium()
		MarketplaceService:SignalMockPurchasePremium()
	end

	function service.startPremiumUpsell(productId)
		local url = ("%supgrades/paymentmethods?ap=%d"):format(BASE_URL, productId)

		GuiService:OpenBrowserWindow(url)
	end

	function service.startRobuxUpsellWeb(productId: string?)
		if productId then
			GuiService:OpenBrowserWindow(("%supgrades/paymentmethods?ap=%s"):format(BASE_URL, productId))
		else
			GuiService:OpenBrowserWindow(("%sUpgrades/Robux.aspx"):format(BASE_URL))
		end
	end

	function service.openSecuritySettings()
		local url = ("%smy/account#!/security"):format(BASE_URL)

		GuiService:OpenBrowserWindow(url)
	end

	function service.openTermsOfUse()
		local url = UrlBuilder.static.about.terms()

		GuiService:OpenBrowserWindow(url)
	end

	function service.openRobuxStore()
		GuiService:OpenBrowserWindow(("%sUpgrades/Robux.aspx"):format(BASE_URL))
	end

	function service.promptNativePurchaseWithLocalPlayer(mobileProductId)
		return MarketplaceService:PromptNativePurchaseWithLocalPlayer(mobileProductId)
	end

	function service.promptNativePurchase(player, mobileProductId)
		return MarketplaceService:PromptNativePurchase(player, mobileProductId)
	end

	function service.beginPlatformStorePurchase(xboxProductId)
		return PlatformService:BeginPlatformStorePurchase(xboxProductId)
	end

	return service
end

return PlatformInterface
