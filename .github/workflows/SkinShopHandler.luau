local SkinPrices = {
["Dignity_Default"] = 0,
["Dignity_Christmas"] = 500,
["Dignity_Gold"] = 1000,
["Ripper_Default"] = 0,
["Ripper_Shadow"] = 800,
["Bacon_Default"] = 0,
["Bacon_Christmas"] = 500,
["Bacon_Old"] = 100,
["Bob_Fan"] = 250,
}

local RP = game.ReplicatedStorage
local killersFolder = RP.Core.Skins.Killers
local survivorsFolder = RP.Core.Skins.Survivors

local function GetCharacterFromSkin(skinFullName)
    local parts = string.split(skinFullName, "_")
    return parts[1]
end

local function GetSkinName(skinFullName)
    local parts = string.split(skinFullName, "_")
    return parts[2]
end

local function IsKillerSkin(skinFullName)
    local charName = GetCharacterFromSkin(skinFullName)
    return killersFolder:FindFirstChild(charName) ~= nil
end

local event = Instance.new("RemoteEvent", RP.Core.Network)
event.Name = "BuySkinEvent"

event.OnServerEvent:Connect(function(plr, skinFullName, isBuying, isUnequipping)
    if not skinFullName or type(skinFullName) ~= "string" or not plr then return end
    if type(isBuying) ~= "boolean" then return end
    
    local skins = plr:FindFirstChild("OwnedSkins")
    local leaderstats = plr:FindFirstChild("leaderstats")
    if not skins or not leaderstats then return end
    
    local charName = GetCharacterFromSkin(skinFullName)
    local skinName = GetSkinName(skinFullName)
    local isKiller = IsKillerSkin(skinFullName)
    
    if isBuying then
        if skins:FindFirstChild(skinFullName) then 
            warn("Player " .. plr.Name .. " already owns " .. skinFullName) 
            return 
        end
        
        local price = SkinPrices[skinFullName]
        if not price then
            warn("Skin '" .. skinFullName .. "' doesn't exist in price table")
            return
        end
        
        local points = leaderstats:FindFirstChild("Points")
        if not points then return end
        
        if points.Value < price then
            warn("Player " .. plr.Name .. " doesn't have enough points. Needs " .. price .. ", has " .. points.Value)
            return
        end
        
        if price > 0 then
            points.Value = points.Value - price
        end
        
        local flag = Instance.new("BoolValue")
        flag.Parent = skins
        flag.Name = skinFullName
        flag.Value = true
        
        print("✅ Player " .. plr.Name .. " bought skin '" .. skinFullName .. "' for " .. price .. " points!")
    else
        if isUnequipping then
            if isKiller then
                leaderstats.Skin_Killer.Value = "Default"
                print("✅ Player " .. plr.Name .. " unequipped Killer Skin")
            else
                leaderstats.Skin_Survivor.Value = "Default"
                print("✅ Player " .. plr.Name .. " unequipped Survivor Skin")
            end
        else
            if not skins:FindFirstChild(skinFullName) then
                warn("Player " .. plr.Name .. " doesn't own " .. skinFullName)
                return
            end
            
            if isKiller then
                leaderstats.Skin_Killer.Value = skinName
                print("✅ Player " .. plr.Name .. " equipped Killer Skin: " .. skinName)
            else
                leaderstats.Skin_Survivor.Value = skinName
                print("✅ Player " .. plr.Name .. " equipped Survivor Skin: " .. skinName)
            end
        end
    end
end)
