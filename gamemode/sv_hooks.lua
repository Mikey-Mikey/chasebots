function CreateRagdollFromPlayer(ply)
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetModel(ply:GetModel())
    ragdoll:Spawn()
    ragdoll:Activate()
    ragdoll:SetNW2Entity("RagdollOwner", ply)


    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)

        local matrix = ply:GetBoneMatrix(ragdoll:TranslatePhysBoneToBone(i))
        local pos = matrix:GetTranslation()
        local ang = matrix:GetAngles()

        phys:SetPos(pos)
        phys:SetAngles(ang)

        phys:SetVelocity(ply:GetVelocity())
    end

    return ragdoll
end

hook.Add("InitPostEntity", "InitializeServerRound", function()
    local npcs = list.Get("NPC")
    for class, tbl in pairs(npcs) do
        if string.find(class, "npc_tf2_ghost") then
            continue
        end

        if scripted_ents.IsBasedOn(class, "base_nextbot") then
            GAMEMODE.NextbotClassTable[#GAMEMODE.NextbotClassTable + 1] = class
        end
    end

    navmesh.Load()

    if player.GetCount() > 0 and not GAMEMODE.RoundRunning then
        GAMEMODE:StartRound()
    end
end)

hook.Add("PlayerInitialSpawn", "PlayerFirstSpawned", function(ply)
    if GetGlobalBool("RoundRunning", false) then
        ply:KillSilent()
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(ply)
    end
end)

hook.Add("PlayerDeathThink", "PreventRespawn", function(ply)
    return true
end)

hook.Add("OnEntityCreated", "RemoveClientRagdoll", function(ent)
    if ent:GetClass() == "hl2mp_ragdoll" then
        timer.Simple(0, function()
            ent:Remove()
        end)
    end
end)

hook.Add("Tick", "RoundTimer", function()
    if GetGlobalBool("RoundRunning", false) then
        SetGlobalFloat("CurrentRoundTime", GetGlobalFloat("RoundStartTime", 0) - RealTime() + GAMEMODE.BASE_ROUND_TIME)
        if GetGlobalBool("CurrentRoundTime", 0) <= 0 then
            GAMEMODE:EndRound()
        end
    end
end)

gameevent.Listen("entity_killed")
hook.Add("entity_killed", "SpectateAttackerNextbot", function(data)
    local victim = Entity(data.entindex_killed)

    victim:Spectate(OBS_MODE_CHASE)
    victim:SpectateEntity(victim)

    local playersLeft = 0
    for k, ply in ipairs(player.GetAll()) do
        if ply:Alive() then playersLeft = playersLeft + 1 end
    end

    if playersLeft == 0 then
        GAMEMODE:EndRound()
    end
end)


gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "RemovePlayerFromAliveList", function(data)
    local playersLeft = 0
    for k, ply in ipairs(player.GetAll()) do
        if ply:Alive() then playersLeft = playersLeft + 1 end
    end

    if playersLeft == 0 then
        GAMEMODE:EndRound()
    end
end)

gameevent.Listen("player_spawn")
hook.Add("player_spawn", "AddPlayerToAliveList", function(data)
    local ply = Player(data.userid)
    if not ply:Alive() then return end
    ply:SetShouldServerRagdoll(true)
    ply:SetModel("models/player/group01/male_07.mdl")
    local plyColor = HSVToColor(util.SharedRandom(ply:SteamID64(), 0, 360), 1, 1)
    ply:SetPlayerColor(Vector(plyColor.r, plyColor.g, plyColor.b))
end)