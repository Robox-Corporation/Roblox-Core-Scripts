local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")

local Roact = require(CorePackages.Roact)
local t = require(CorePackages.Packages.t)
local VerifiedBadges = require(CorePackages.Workspace.Packages.VerifiedBadges)

local PlayerList = script.Parent.Parent.Parent
local Connection = PlayerList.Components.Connection
local LayoutValues = require(Connection.LayoutValues)
local WithLayoutValues = LayoutValues.WithLayoutValues

local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local playerInterface = require(RobloxGui.Modules.Interfaces.playerInterface)

local FFlagShowVerifiedBadgeOnPlayerList = require(PlayerList.Flags.FFlagShowVerifiedBadgeOnPlayerList)

local PlayerNameTag = Roact.PureComponent:extend("PlayerNameTag")

PlayerNameTag.validateProps = t.strictInterface({
	player = playerInterface,
	isTitleEntry = t.boolean,
	isHovered = t.boolean,
	layoutOrder = t.integer,

	textStyle = t.strictInterface({
		Color = t.Color3,
		Transparency = t.number,
		StrokeColor = t.optional(t.Color3),
		StrokeTransparency = t.optional(t.number),
	}),
	textFont = t.strictInterface({
		Size = t.number,
		MinSize = t.number,
		Font = t.enum(Enum.Font),
	}),
})

function PlayerNameTag:render()
	return WithLayoutValues(function(layoutValues)
		local iconColor = layoutValues.IconUnSelectedColor
		if self.props.isHovered then
			iconColor = layoutValues.IconSelectedColor
		end

		local playerNameFont = self.props.textFont.Font
		local textSize = self.props.textFont.Size
		local minTextSize = self.props.textFont.MinSize

		local playerNameChildren = {}
		local platformName = self.props.player.PlatformName

		local showVerifiedBadgeOnPlayerList = FFlagShowVerifiedBadgeOnPlayerList()
		local hasVerifiedBadge = if showVerifiedBadgeOnPlayerList then VerifiedBadges.isPlayerVerified(self.props.player) else false

		if layoutValues.IsTenFoot and platformName ~= "" then
			playerNameChildren["VerticalLayout"] = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
			})

			playerNameChildren["PlayerPlatformName"] = Roact.createElement("TextLabel", {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0.35, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.SourceSans,
				TextSize = textSize,
				TextColor3 = self.props.textStyle.Color,
				TextTransparency = self.props.textStyle.Transparency,
				TextStrokeColor3 = self.props.textStyle.StrokeColor,
				TextStrokeTransparency = self.props.textStyle.StrokeTransparency,
				BackgroundTransparency = 1,
				Text = platformName,
				LayoutOrder = 2,
			})

			playerNameChildren["RobloxNameFrame"] = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0.45, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Layout = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 6),
				}),

				RobloxIcon = Roact.createElement("ImageButton", {
					Size = UDim2.new(0, 24, 0, 24),
					Image = layoutValues.RobloxIconImage,
					BackgroundTransparency = 1,
					Selectable = false,
					ImageColor3 = iconColor,
					LayoutOrder = 1,
				}),

				PlayerName = not showVerifiedBadgeOnPlayerList and Roact.createElement("TextLabel", {
					Size = UDim2.new(1, -30, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = playerNameFont,
					TextSize = textSize,
					TextColor3 = self.props.textStyle.Color,
					TextTransparency = self.props.textStyle.Transparency,
					TextStrokeColor3 = self.props.textStyle.StrokeColor,
					TextStrokeTransparency = self.props.textStyle.StrokeTransparency,
					BackgroundTransparency = 1,
					Text = self.props.player.Name,
					ClipsDescendants = false,
					LayoutOrder = 2,
				}),

				PlayerNameContainer = showVerifiedBadgeOnPlayerList
					and Roact.createElement(VerifiedBadges.EmojiWrapper, {
						emoji = if hasVerifiedBadge then VerifiedBadges.emoji.verified else "",
						layoutOrder = 2,
						mockIsEnrolled = true,
						size = UDim2.new(1, -30, 0, 0),
						automaticSize = Enum.AutomaticSize.Y,
						verticalAlignment = Enum.VerticalAlignment.Center,
					}, {
						PlayerName = Roact.createElement("TextLabel", {
							AutomaticSize = Enum.AutomaticSize.X,
							ClipsDescendants = false,
							Size = UDim2.fromScale(0, 1),
							Font = playerNameFont,
							Text = self.props.player.Name,
							TextSize = textSize,
							TextColor3 = self.props.textStyle.Color,
							TextTransparency = self.props.textStyle.Transparency,
							TextStrokeColor3 = self.props.textStyle.StrokeColor,
							TextStrokeTransparency = self.props.textStyle.StrokeTransparency,
							TextTruncate = Enum.TextTruncate.AtEnd,
							TextXAlignment = Enum.TextXAlignment.Left,
							BackgroundTransparency = 1,
						}),
					}),
			})
		else
			playerNameChildren["PlayerName"] = not showVerifiedBadgeOnPlayerList
				and Roact.createElement("TextLabel", {
					Position = UDim2.new(0, 0, 0.28, 0),
					Size = UDim2.new(1, 0, 0.44, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = playerNameFont,
					TextSize = textSize,
					TextColor3 = self.props.textStyle.Color,
					TextTransparency = self.props.textStyle.Transparency,
					TextStrokeColor3 = self.props.textStyle.StrokeColor,
					TextStrokeTransparency = self.props.textStyle.StrokeTransparency,
					BackgroundTransparency = 1,
					Text = self.props.player.DisplayName,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextScaled = true,
				}, {
					SizeConstraint = Roact.createElement("UITextSizeConstraint", {
						MaxTextSize = textSize,
						MinTextSize = minTextSize,
					}),
				})

			playerNameChildren["PlayerNameContainer"] = showVerifiedBadgeOnPlayerList
				and Roact.createElement(VerifiedBadges.EmojiWrapper, {
					emoji = if hasVerifiedBadge then VerifiedBadges.emoji.verified else "",
					anchorPoint = Vector2.new(0, 0.5),
					position = UDim2.fromScale(0, 0.5),
					mockIsEnrolled = true,
					verticalAlignment = Enum.VerticalAlignment.Center,
					automaticSize = Enum.AutomaticSize.X,
					size = UDim2.new(0, 0, 0, textSize),
				}, {
					PlayerName = Roact.createElement("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.fromScale(0, 1),
						Font = playerNameFont,
						Text = self.props.player.DisplayName,
						TextSize = textSize,
						TextColor3 = self.props.textStyle.Color,
						TextTransparency = self.props.textStyle.Transparency,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextScaled = true,
						TextStrokeColor3 = self.props.textStyle.StrokeColor,
						TextStrokeTransparency = self.props.textStyle.StrokeTransparency,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundTransparency = 1,
					}, {
						SizeConstraint = Roact.createElement("UITextSizeConstraint", {
							MaxTextSize = textSize,
							MinTextSize = minTextSize,
						}),
					}),
				})
		end

		return Roact.createElement("Frame", {
			LayoutOrder = self.props.layoutOrder,
			Size = layoutValues.PlayerNameSize,
			BackgroundTransparency = 1,
		}, playerNameChildren)
	end)
end

return PlayerNameTag
