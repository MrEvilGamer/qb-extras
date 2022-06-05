QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('just-poop-it', function()
    Wait(500)
    QBCore.Functions.Notify('The situation is getting shitty! Find some private place soon!', 'primary', 7000)
    Wait(10000)
    QBCore.Functions.Notify('You need to get moving! or it could get worse', 'primary', 7000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "fart", 0.1)
    Wait(10000)
    QBCore.Functions.Notify('Any time now', 'primary', 7000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "fart", 0.1)
    Wait(10000)
    QBCore.Functions.Notify('This can get more embarrassing!', 'primary', 7000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "fart", 0.1)
    Wait(10000)
    QBCore.Functions.Notify('It doesn\'t look good', 'primary', 7000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "fart", 0.1)
    Wait(10000)
    QBCore.Functions.Notify('Oh God!', 'primary', 7000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "fart", 0.1)
    Wait(10000)
    QBCore.Functions.Notify('Shit just got real!', 'primary', 7000)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "poop", 0.1)
  local particleDictionary = "scr_amb_chop"
  local particleName = "ent_anim_dog_poo"
  local animDictionary = 'switch@trevor@on_toilet'
  local animName = 'trev_on_toilet_exit'

  RequestNamedPtfxAsset(particleDictionary)
  while not HasNamedPtfxAssetLoaded(particleDictionary) do
     Wait(0)
  end

  RequestAnimDict(animDictionary)

  while not HasAnimDictLoaded(animDictionary) do
    Wait(0)
  end

  SetPtfxAssetNextCall(particleDictionary)
  bone   = GetPedBoneIndex(PlayerPedId(), 11816)

  TaskPlayAnim(PlayerPedId(), animDictionary, animName, 8.0, -8.0, -1, 0, 0, false, false, false)
  effect = StartParticleFxLoopedOnPedBone(particleName, PlayerPedId(), 0.0, -0.9, -0.5, 0.0, 0.0, 20.0, bone, 2.0, false, false, false);
  Wait(10000)
  StopParticleFxLooped(effect, 0)
  QBCore.Functions.Notify('Take warning signs more seriously or you would be embarrassed again', 'primary', 7000)
end)