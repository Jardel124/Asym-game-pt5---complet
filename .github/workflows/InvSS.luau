local template = script.Parent.Template
local RP = game.ReplicatedStorage
local killersFolder = RP.Core.Skins.Killers
local survivorsFolder = RP.Core.Skins.Survivors
local player = game.Players.LocalPlayer
local ownedSkins = player:WaitForChild("OwnedSkins")
local leaderstats = player:WaitForChild("leaderstats")
local buySkinEvent = RP.Core.Network:WaitForChild("BuySkinEvent")

local buttons = {}

local function GetSkinName(skinFullName)
    local parts = string.split(skinFullName, "_")
    return parts[2]
end

local function GetCharName(skinFullName)
    local parts = string.split(skinFullName, "_")
    return parts[1]
end

local function IsKillerSkin(skinFullName)
    local charName = GetCharName(skinFullName)
    return killersFolder:FindFirstChild(charName) ~= nil
end

local function IsEquipped(skinFullName)
    local skinName = GetSkinName(skinFullName)
    if IsKillerSkin(skinFullName) then
        return leaderstats.Skin_Killer.Value == skinName
    else
        return leaderstats.Skin_Survivor.Value == skinName
    end
end

local function UpdateButton(button, skinFullName)
    local equipped = IsEquipped(skinFullName)
    local status = equipped and "Equipped" or "Equip"
    button.Text = skinFullName .. " : " .. status
end

local function CreateButton(skinFullName)
    local button = template:Clone()
    button.Name = skinFullName
    button.Parent = script.Parent
    button.Visible = true
    
    UpdateButton(button, skinFullName)
    
    button.MouseButton1Click:Connect(function()
        if IsEquipped(skinFullName) then
            buySkinEvent:FireServer(skinFullName, false, true)
        else
            buySkinEvent:FireServer(skinFullName, false, false)
        end
    end)
    
    table.insert(buttons, {button = button, skinFullName = skinFullName})
end

local function RefreshInventory()
    for _, data in ipairs(buttons) do
        if data.button then
            data.button:Destroy()
        end
    end
    buttons = {}
    
    for _, skin in ipairs(ownedSkins:GetChildren()) do
        if skin:IsA("BoolValue") and skin.Value then
            CreateButton(skin.Name)
        end
    end
end

RefreshInventory()

ownedSkins.ChildAdded:Connect(function()
    task.wait(0.1)
    RefreshInventory()
end)

ownedSkins.ChildRemoved:Connect(function()
    task.wait(0.1)
    RefreshInventory()
end)

leaderstats.Skin_Killer:GetPropertyChangedSignal("Value"):Connect(function()
    for _, data in ipairs(buttons) do
        UpdateButton(data.button, data.skinFullName)
    end
end)

leaderstats.Skin_Survivor:GetPropertyChangedSignal("Value"):Connect(function()
    for _, data in ipairs(buttons) do
        UpdateButton(data.button, data.skinFullName)
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        for _, data in ipairs(buttons) do
            if data.button and data.button.Parent then
                UpdateButton(data.button, data.skinFullName)
            end
        end
    end
end)
print("Executed")
