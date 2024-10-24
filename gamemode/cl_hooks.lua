hook.Add("NetworkEntityCreated", "SetRagdollColors", function(ent)
    if ent:GetClass() == "prop_ragdoll" and IsValid(ent:GetNW2Entity("RagdollOwner")) then
        local col = ent:GetNW2Entity("RagdollOwner"):GetPlayerColor()
        ent.GetPlayerColor = function()
            return col
        end
    end
end)


-- Disable weapon switching
local key_blacklist = {
    ["invnext"] = true,
    ["invprev"] = true,
    ["lastinv"] = true,
    ["slot1"] = true,
    ["slot2"] = true,
    ["slot3"] = true,
    ["slot4"] = true,
    ["slot5"] = true,
    ["slot6"] = true,
    ["slot7"] = true,
    ["slot8"] = true,
    ["slot9"] = true,
    ["slot0"] = true,
}

hook.Add("PlayerBindPress", "", function(_, bind)
    if key_blacklist[bind] then
        return true
    end
end)

local shouldJumpscareSnd = false

local lastJumpscare = 0

hook.Add("RenderScreenspaceEffects", "DrawRoundTime", function()
    local nearbyNextbots = ents.FindInSphere(LocalPlayer():GetPos(), 800)
    nearbyNextbots = FilterTable(nearbyNextbots, function(v) return v:IsNextBot() end)
    table.sort(nearbyNextbots, function(a, b) return LocalPlayer():GetPos():DistToSqr(a:GetPos()) < LocalPlayer():GetPos():DistToSqr(b:GetPos()) end)

    local grayAmount = 0

    if #nearbyNextbots > 0 and not shouldJumpscareSnd and CurTime() - lastJumpscare > 10 and nearbyNextbots[1]:GetPos():DistToSqr(LocalPlayer():GetPos()) < 500^2 then
        lastJumpscare = CurTime()
        LocalPlayer():EmitSound("ambient/levels/labs/electric_explosion1.wav", nil, 75, 1)
        LocalPlayer():EmitSound("ambient/levels/labs/electric_explosion1.wav", nil, 75, 1)
        LocalPlayer():EmitSound("ambient/levels/labs/electric_explosion1.wav", nil, 75, 1)
        LocalPlayer():EmitSound("ambient/levels/labs/electric_explosion1.wav", nil, 75, 1)

        shouldJumpscareSnd = true
    elseif #nearbyNextbots == 0 and shouldJumpscareSnd then
        shouldJumpscareSnd = false
    end

    for i, nextbot in ipairs(nearbyNextbots) do
        local dist = LocalPlayer():GetPos():DistToSqr(nextbot:GetPos())
        grayAmount = math.max(grayAmount, 1 - (dist / 800^2))
    end

    util.ScreenShake(LocalPlayer():GetPos(), grayAmount * 3, 100, 0.1, 10, true)
    if LocalPlayer():Alive() then
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1 - grayAmount,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    end
end)