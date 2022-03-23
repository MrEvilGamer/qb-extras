
-- START Kort i hånden ved ESC menu
local inMenuMode = false
local Animation = false
CreateThread(function()
	while true do
		Wait(500)
		if IsPauseMenuActive() then
			
			AnimMode()
		else
			if Animation then
				Animation = false
				ClearPedTasks(PlayerPedId())
			end
			inMenuMode = false
			DestroyAllProps()
		end
	end
	
end)

function AnimMode()
	if not inMenuMode then
		if not IsPedInAnyVehicle(PlayerPedId()) then
			Animation = true
			inMenuMode = true
			local Player = PlayerPedId()
			local AnimDict = "amb@world_human_tourist_map@male@idle_b"
			local Anim = "idle_d"
			LoadAnim(AnimDict)
			local Prop = 'p_tourist_map_01_s'
			local PropBone = 28422
			AddPropToPlayer(Prop, PropBone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
			TaskPlayAnim(PlayerPedId(), AnimDict, Anim, 2.0, 8.0, -1, 53, 0, false, false, false)
		end
	else
	
	end
end

function LoadAnim(dict)
  while not HasAnimDictLoaded(dict) do
    RequestAnimDict(dict)
    Wait(10)
  end
end

function LoadPropDict(model)
  while not HasModelLoaded(GetHashKey(model)) do
    RequestModel(GetHashKey(model))
    Wait(10)
  end
end

local PlayerHasProp = false
local PlayerProps = {}
function AddPropToPlayer(prop1, bone, off1, off2, off3, rot1, rot2, rot3)
  local Player = PlayerPedId()
  local x,y,z = table.unpack(GetEntityCoords(Player))

  if not HasModelLoaded(prop1) then
    LoadPropDict(prop1)
  end

  prop = CreateObject(GetHashKey(prop1), x, y, z+0.2,  true,  true, true)
  AttachEntityToEntity(prop, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
  table.insert(PlayerProps, prop)
  PlayerHasProp = true
  SetModelAsNoLongerNeeded(prop1)
end

function DestroyAllProps()
  for _,v in pairs(PlayerProps) do
    DeleteEntity(v)
  end
  PlayerHasProp = false
end


-- END Kort i hånden ved ESC menu


