--!nonstrict
local VRService 	= game:GetService("VRService")
local CoreGui 		= game:GetService("CoreGui")

local RobloxGui 	= CoreGui.RobloxGui
local CommonUtil	= require(RobloxGui.Modules.Common.CommonUtil)

local MATERIAL = Enum.Material.Granite
local SCALE = Vector3.new(1, 1, 1)

local DefaultController = {}
DefaultController.__index = DefaultController

function DefaultController.new(userCFrame)
	local self = setmetatable({}, DefaultController)
	self.userCFrame = userCFrame

	self.model = CommonUtil.Create("Model") {
		Name = "TouchController",
		Archivable = false
	}	

	self.origin = CommonUtil.Create("Part") {
		Parent = self.model,		
		Name = "Origin",
		Anchored = true,
		Transparency = 1,
		Size = Vector3.new(0.05, 0.05, 0.05),
		CanCollide = false
	}

	self.parts = {}
	local partName = "body"
	local part = CommonUtil.Create("Part") {
		Parent = self.model,
		Name = partName,
		Anchored = false,
		CanCollide = false,
		Material = MATERIAL,
		Size = Vector3.new(0.05, 0.05, 0.05),
		Transparency = 0.5,
		CFrame = self.origin.CFrame
	}
	local mesh = CommonUtil.Create("SpecialMesh") {
		Parent = part,
		Name = "Mesh",
		MeshId = userCFrame == Enum.UserCFrame.LeftHand and "rbxassetid://8650168403" or "rbxassetid://8650168401",
		--TextureId = partInfo.textureId,
		Scale = SCALE
	}
	local weld = CommonUtil.Create("Weld") {
		Parent = part,
		Name = "Weld",
		Part0 = self.origin,
		Part1 = part,
		C0 = CFrame.new(0, -0.115, 0.213)
	}
	self.parts[partName] = part

	self.model.PrimaryPart = self.origin

	return self
end

function DefaultController:setCFrame(cframe)
	self.model:SetPrimaryPartCFrame(cframe * CFrame.Angles(math.rad(90), 0, 0))
end

function DefaultController:onButtonInputChanged(inputObject, depressed)

end

function DefaultController:onInputBegan(inputObject)
	self:onButtonInputChanged(inputObject, true)
end

function DefaultController:onInputChanged(inputObject)
end

function DefaultController:onInputEnded(inputObject)
	self:onButtonInputChanged(inputObject, false)
end

function DefaultController:onTouchpadModeChanged(touchpad, touchpadMode)
end

return DefaultController