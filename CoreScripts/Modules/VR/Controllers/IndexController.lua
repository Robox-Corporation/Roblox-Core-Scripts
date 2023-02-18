--!nonstrict
local VRService 	= game:GetService("VRService")
local CoreGui 		= game:GetService("CoreGui")
local CorePackages	= game:GetService("CorePackages")

local RobloxGui 	= CoreGui.RobloxGui
local CommonUtil	= require(RobloxGui.Modules.Common.CommonUtil)
local GetFFlagUIBloxVRApplyHeadScale =
	require(CorePackages.Workspace.Packages.SharedFlags).UIBlox.GetFFlagUIBloxVRApplyHeadScale

local MATERIAL = Enum.Material.Granite
local SCALE = Vector3.new(3.6, 3.6, 3.6)

local IndexController = {}
IndexController.__index = IndexController

function IndexController.new(userCFrame)
	local self = setmetatable({}, IndexController)
	self.userCFrame = userCFrame

	self.model = CommonUtil.Create("Model") {
		Name = "IndexController",
		Archivable = false
	}	

	self.origin = CommonUtil.Create("Part") {
		Parent = self.model,		
		Name = "Origin",
		Anchored = true,
		Transparency = 1,
		Size = Vector3.new(0.05, 0.05, 0.05),
		CanCollide = false,
	}
	
	self.parts = {}
	local partName = "body"
	local part = CommonUtil.Create("Part") {
		Parent = self.model,
		Name = partName,
		Anchored = true,
		Material = MATERIAL,
		Size = Vector3.new(0.05, 0.05, 0.05),
		Transparency = 0.25,
		CFrame = self.origin.CFrame,
		CanCollide = false,
	}
	local mesh = CommonUtil.Create("SpecialMesh") {
		Parent = part,
		Name = "Mesh",
		MeshId = userCFrame == Enum.UserCFrame.LeftHand and "rbxassetid://9605099531" or "rbxassetid://9605114549",
		TextureId = userCFrame == Enum.UserCFrame.LeftHand and "rbxassetid://9605099774" or "rbxassetid://9605114771",
		Scale = SCALE,
	}
	if GetFFlagUIBloxVRApplyHeadScale() then
		self.mesh = mesh
	end
	local weld = CommonUtil.Create("Weld") {
		Parent = part,
		Name = "Weld",
		Part0 = self.origin,
		Part1 = part,
	}
	self.parts[partName] = part

	self.model.PrimaryPart = self.origin

	return self
end

function IndexController:setCFrame(cframe)
	if self.userCFrame == Enum.UserCFrame.RightHand then
		self.model:SetPrimaryPartCFrame(cframe * CFrame.Angles(math.rad(20), math.rad(180), 0) * CFrame.new(-0.1, -0.03, -0.4))
	else
		self.model:SetPrimaryPartCFrame(cframe * CFrame.Angles(math.rad(20), math.rad(180), 0) * CFrame.new(0.1, -0.03, -0.4))
	end

end

function IndexController:setCFrameAndScale(cframe, scale)
	local xScaleSign = if self.userCFrame == Enum.UserCFrame.RightHand then 1 else -1
	self.model:SetPrimaryPartCFrame(cframe * CFrame.Angles(math.rad(20), math.rad(180), 0) * CFrame.new(-0.1 * scale * xScaleSign, -0.03 * scale, -0.4 * scale))
	self.mesh.Scale = SCALE * scale
end

function IndexController:onButtonInputChanged(inputObject, depressed)

end

function IndexController:onInputBegan(inputObject)
	self:onButtonInputChanged(inputObject, true)
end

function IndexController:onInputChanged(inputObject)
end

function IndexController:onInputEnded(inputObject)
	self:onButtonInputChanged(inputObject, false)
end

function IndexController:onTouchpadModeChanged(touchpad, touchpadMode)
end

return IndexController
