local CharacterPrices = {
["Dignity"] = 0,
["Zombie"] = 1000,
["Phantom"] = 1500,
["Shadow"] = 2000,
["Reaper"] = 2500,
["Bacon"] = 0,
["Bob"] = 800,
["Soldier"] = 500,
["Engineer"] = 1500,
["Veteran"] = 2000,
}
 
local event = Instance.new("RemoteEvent", game.ReplicatedStorage.Core.Network)
event.Name = "BuyCharEvent"
 
event.OnServerEvent:Connect(function(plr, charName, isBuying, charType)
    if not charName or type(charName) ~= "string" or not plr then return end
    if type(isBuying) ~= "boolean" then return end
    if not charType or (charType ~= "Killer" and charType ~= "Survivor") then return end
    
    local flags = plr:FindFirstChild("OwnedCharacters")
    local leaderstats = plr:FindFirstChild("leaderstats")
    if not flags or not leaderstats then return end
    
    if isBuying then
        if flags:FindFirstChild(charName) then 
            warn("Player " .. plr.Name .. " already owns " .. charName) 
            return 
        end
        
        local price = CharacterPrices[charName]
        if not price then
            warn("Character '" .. charName .. "' doesn't exist in price table")
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
        flag.Parent = flags
        flag.Name = charName
        flag.Value = true
        
        print("✅ Player " .. plr.Name .. " bought '" .. charName .. "' for " .. price .. " points!")
    else
        if not flags:FindFirstChild(charName) then
            warn("Player " .. plr.Name .. " doesn't own " .. charName)
            return
        end
        
        if charType == "Killer" then
            leaderstats.KillerSelected.Value = charName
            print("✅ Player " .. plr.Name .. " equipped Killer: " .. charName)
        elseif charType == "Survivor" then
            leaderstats.SurvivorSelected.Value = charName
            print("✅ Player " .. plr.Name .. " equipped Survivor: " .. charName)
        end
    end
end)
