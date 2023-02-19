return function()
	local CorePackages = game:GetService("CorePackages")

	local InGameMenuDependencies = require(CorePackages.InGameMenuDependencies)
	local Roact = InGameMenuDependencies.Roact
	local Rodux = InGameMenuDependencies.Rodux
	local RoactRodux = InGameMenuDependencies.RoactRodux
	local UIBlox = InGameMenuDependencies.UIBlox

	local InGameMenu = script.Parent.Parent.Parent.Parent
	local reducer = require(InGameMenu.reducer)

	local AppDarkTheme = require(CorePackages.Workspace.Packages.Style).Themes.DarkTheme
	local AppFont = require(CorePackages.Workspace.Packages.Style).Fonts.Gotham

	local appStyle = {
		Theme = AppDarkTheme,
		Font = AppFont,
	}

	local FocusHandlerContextProvider = require(
		script.Parent.Parent.Parent.Connection.FocusHandlerUtils.FocusHandlerContextProvider
	)
	local LeavePrompt = require(script.Parent.LeavePrompt)

	it("should create and destroy without errors", function()
		local leavePrompt = Roact.createElement(LeavePrompt, {
			titleText = "Title",
			bodyText = "BodyText",
			confirmText = "confirmText",
			cancelText = "cancelText",
			onConfirm = function() end,
			onCancel = function() end,
		})

		local element = Roact.createElement(RoactRodux.StoreProvider, {
			store = Rodux.Store.new(reducer),
		}, {
			ThemeProvider = Roact.createElement(UIBlox.Core.Style.Provider, {
				style = appStyle,
			}, {
				FocusHandlerContextProvider = Roact.createElement(FocusHandlerContextProvider, {}, {
					LeavePrompt = leavePrompt,
				}),
			}),
		})

		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)
end
