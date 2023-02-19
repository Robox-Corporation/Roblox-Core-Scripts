local CorePackages = game:GetService("CorePackages")
local Roact = require(CorePackages.Roact)

local Components = script.Parent.Parent.Parent.Components
local HeaderButton = require(Components.HeaderButton)
local ProfilerViewEntry = require(script.Parent.ProfilerViewEntry)

local Constants = require(script.Parent.Parent.Parent.Constants)

local LINE_WIDTH = Constants.GeneralFormatting.LineWidth
local LINE_COLOR = Constants.GeneralFormatting.LineColor
local HEADER_HEIGHT = Constants.GeneralFormatting.HeaderFrameHeight
local ENTRY_HEIGHT = Constants.GeneralFormatting.EntryFrameHeight
local NO_RESULT_SEARCH_STR = Constants.GeneralFormatting.NoResultSearchStr
local HEADER_NAMES = Constants.ScriptProfilerFormatting.HeaderNames
local VALUE_CELL_WIDTH = Constants.ScriptProfilerFormatting.ValueCellWidth
local CELL_PADDING = Constants.ScriptProfilerFormatting.CellPadding
local VALUE_PADDING = Constants.ScriptProfilerFormatting.ValuePadding

local ProfilerView = Roact.PureComponent:extend("ProfilerView")

function ProfilerView:renderChildren()
	local data = self.props.data
	return Roact.createElement(ProfilerViewEntry, {
		layoutOrder = 0,
		depth = 0,
		data = data,
		percentageRatio = if self.props.showAsPercentages
			then data.TotalDuration / 100
			else nil
	})
end

function ProfilerView:render()
	
	local layoutOrder = self.props.layoutOrder
	local size = self.props.size
	local label = nil

	if self.props.profiling then
		label = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			Text =  "Press Stop to Finish Profiling",
			TextColor3 = Constants.Color.Text,
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder,
		})
	elseif not self.props.data then
		label = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			Text =  "Start Profiling to View Data",
			TextColor3 = Constants.Color.Text,
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder,
		})
	end

	return Roact.createElement("Frame", {
		Size = size,
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	}, {
		Header = 	Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
			BackgroundTransparency = 1,
		}, {
			Name = Roact.createElement(HeaderButton, {
				text = HEADER_NAMES[1],
				size = UDim2.new(1 - VALUE_CELL_WIDTH * 2, -VALUE_PADDING - CELL_PADDING, 0, HEADER_HEIGHT),
				pos = UDim2.new(0, CELL_PADDING, 0, 0),
				sortfunction = self.onSortChanged,
			}),
			Inclusive = Roact.createElement(HeaderButton, {
				text = HEADER_NAMES[2],
				size = UDim2.new( VALUE_CELL_WIDTH, -CELL_PADDING, 0, HEADER_HEIGHT),
				pos = UDim2.new(1 - VALUE_CELL_WIDTH * 2, VALUE_PADDING, 0, 0),
				sortfunction = self.onSortChanged,
			}),
			Self = Roact.createElement(HeaderButton, {
				text = HEADER_NAMES[3],
				size = UDim2.new( VALUE_CELL_WIDTH, -CELL_PADDING, 0, HEADER_HEIGHT),
				pos = UDim2.new(1 - VALUE_CELL_WIDTH, VALUE_PADDING, 0, 0),
				sortfunction = self.onSortChanged,
			}),
			TopHorizontal = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = LINE_COLOR,
				BorderSizePixel = 0,
			}),
			LowerHorizontal = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, LINE_WIDTH),
				Position = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = LINE_COLOR,
				BorderSizePixel = 0,
			}),
			Vertical1 = Roact.createElement("Frame", {
				Size = UDim2.new(0, LINE_WIDTH, 1, 0),
				Position = UDim2.new(1 - VALUE_CELL_WIDTH, 0, 0, 0),
				BackgroundColor3 = LINE_COLOR,
				BorderSizePixel = 0,
			}),
			Vertical2 = Roact.createElement("Frame", {
				Size = UDim2.new(0, LINE_WIDTH, 1, 0),
				Position = UDim2.new(1 - VALUE_CELL_WIDTH * 2, 0, 0, 0),
				BackgroundColor3 = LINE_COLOR,
				BorderSizePixel = 0,
			}),
		}),

		Entries = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
			Position = UDim2.new(0, 0, 0, HEADER_HEIGHT),
			BackgroundTransparency = 1,
			VerticalScrollBarInset = Enum.ScrollBarInset.None,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical
			}),
			Children = if label then label else Roact.createFragment(self:renderChildren())
		}),
	})

end

return ProfilerView
