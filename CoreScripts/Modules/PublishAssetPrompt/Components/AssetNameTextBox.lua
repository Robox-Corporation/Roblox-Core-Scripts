--[[
	A text input field used in the Upload Asset prompt that allows the user to enter an asset name.
	Validates the text input as the user types, and displays "Invalid Name" below if special characters are used.
]]
local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")

local Roact = require(CorePackages.Roact)
local t = require(CorePackages.Packages.t)
local RoactGamepad = require(CorePackages.Packages.RoactGamepad)
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local RobloxTranslator = require(RobloxGui.Modules.RobloxTranslator)

local Focusable = RoactGamepad.Focusable

local UIBlox = require(CorePackages.UIBlox)
local withStyle = UIBlox.Style.withStyle
local withSelectionCursorProvider = UIBlox.App.SelectionImage.withSelectionCursorProvider
local CursorKind = UIBlox.App.SelectionImage.CursorKind

local Images = UIBlox.App.ImageSet.Images
local ImageSetLabel = UIBlox.Core.ImageSet.Label

local TEXTBOX_HEIGHT = 30
local TEXTBOX_PADDING = 6

local MAX_NAME_LENGTH = 99 --TODO: figure out actual max name length
local BUTTON_STOKE = Images["component_assets/circle_17_stroke_1"]
local BACKGROUND_9S_CENTER = Rect.new(8, 8, 8, 8)
local WARNING_TEXT_SIZE = 12

local AssetNameTextBox = Roact.PureComponent:extend("AssetNameTextBox")

AssetNameTextBox.validateProps = t.strictInterface({
	onAssetNameUpdated = t.callback, -- function(newName, isNameInvalid)
})

local function isNameTooLong(str: string, maxLength: number)
	local utf8Length: number? = utf8.len(utf8.nfcnormalize(str))
	if utf8Length == nil then
		return true
	else
		return utf8Length > maxLength
	end
end

function AssetNameTextBox:init()
	self:setState({
		assetName = "",
		lastValidName = "",
		isNameInvalid = true,
	})

	self.textBoxRef = Roact.createRef()
	self.wasInitiallyFocused = false

	self.tryFocusTextBox = function()
		if self.wasInitiallyFocused then
			return
		end

		local textbox = self.textBoxRef:getValue()
		if textbox and textbox:IsDescendantOf(game) then
			textbox:CaptureFocus()
			self.wasInitiallyFocused = true
		end
	end

	self.onTextChanged = function(rbx)
		local assetName = rbx.Text

		if isNameTooLong(assetName, MAX_NAME_LENGTH) then
			assetName = self.state.lastValidName
			rbx.Text = assetName
		end

		local isNameInvalid = not string.match(assetName, "^[0-9a-zA-Z%s]+$")

		local lastValidName = self.state.lastValidName
		if not isNameInvalid then
			lastValidName = rbx.Text
		end

		self:setState({
			lastValidName = lastValidName,
			isNameInvalid = isNameInvalid,
			assetName = assetName,
		})

		self.props.onAssetNameUpdated(assetName, isNameInvalid)
	end
end

function AssetNameTextBox:renderWithProviders(stylePalette, getSelectionCursor)
	local font = stylePalette.Font
	local theme = stylePalette.Theme

	local isNameInvalid = self.state.isNameInvalid
	local showWarningText = isNameInvalid and self.state.assetName ~= ""

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = self.props.Size,
		Position = self.props.Position,
	}, {
		TextboxContainer = Roact.createElement(ImageSetLabel, {
			BackgroundTransparency = 1,
			Image = BUTTON_STOKE,
			ImageColor3 = theme.UIDefault.Color,
			ImageTransparency = theme.UIDefault.Transparency,
			LayoutOrder = 1,
			ScaleType = Enum.ScaleType.Slice,
			Size = UDim2.new(1, 0, 0, TEXTBOX_HEIGHT),
			SliceCenter = BACKGROUND_9S_CENTER,
		}, {
			Textbox = Roact.createElement(Focusable.TextBox, {
				Text = "",
				BackgroundTransparency = 1,
				ClearTextOnFocus = false,
				Font = font.CaptionBody.Font,
				TextSize = font.BaseSize * font.CaptionBody.RelativeSize,
				PlaceholderColor3 = theme.PlaceHolder.Color,
				PlaceholderText = RobloxTranslator:FormatByKey("CoreScripts.PublishAssetPrompt.AssetNamePlaceholder"),
				Position = UDim2.fromOffset(TEXTBOX_PADDING, 0),
				Size = UDim2.new(1, -TEXTBOX_PADDING * 2, 1, 0),
				TextColor3 = theme.TextDefault.Color,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				OverlayNativeInput = true,
				[Roact.Change.Text] = self.onTextChanged,
				SelectionImageObject = getSelectionCursor(CursorKind.InputFields),

				[Roact.Ref] = self.textBoxRef,
				[Roact.Event.AncestryChanged] = self.tryFocusTextBox,
			}),
		}),
		WarningText = showWarningText and Roact.createElement("TextLabel", {
			Position = UDim2.new(0, 0, 1, 0),

			BackgroundTransparency = 1,
			Text = RobloxTranslator:FormatByKey("CoreScripts.PublishAssetPrompt.InvalidName"),
			LayoutOrder = 2,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, 0, 0, 20),
			TextColor3 = theme.Alert.Color,
			TextWrapped = true,
			Font = font.Body.Font,
			TextSize = WARNING_TEXT_SIZE,
		}),
	})
end

function AssetNameTextBox:render()
	return withStyle(function(stylePalette)
		return withSelectionCursorProvider(function(getSelectionCursor)
			return self:renderWithProviders(stylePalette, getSelectionCursor)
		end)
	end)
end

function AssetNameTextBox:didMount()
	self.tryFocusTextBox()
end

return AssetNameTextBox
