local template = script.Parent.Template
local RP = game.ReplicatedStorage
local killersFolder = RP.Core.Skins.Killers
local survivorsFolder = RP.Core.Skins.Survivors
local player = game.Players.LocalPlayer
local ownedSkins = player:WaitForChild("OwnedSkins")
local buySkinEvent = RP.Core.Network:WaitForChild("BuySkinEvent")

local buttons = {}

local function HaveSkin(skinFullName)
    return ownedSkins:FindFirstChild(skinFullName) ~= nil
end

local function UpdateButton(button, skinFullName)
    local owned = HaveSkin(skinFullName)
    local status = owned and "Already have" or "Buy"
    button.Text = skinFullName .. " : " .. status
end

local function CreateButton(skinFullName)
    local button = template:Clone()
    button.Name = skinFullName
    button.Parent = script.Parent
    button.Visible = true
    
    UpdateButton(button, skinFullName)
    
    button.MouseButton1Click:Connect(function()
        if not HaveSkin(skinFullName) then
            buySkinEvent:FireServer(skinFullName, true)
        end
    end)
    
    table.insert(buttons, {button = button, skinFullName = skinFullName})
end

for _, charFolder in ipairs(killersFolder:GetChildren()) do
    for _, skin in ipairs(charFolder:GetChildren()) do
        local skinFullName = charFolder.Name .. "_" .. skin.Name
        CreateButton(skinFullName)
    end
end

for _, charFolder in ipairs(survivorsFolder:GetChildren()) do
    for _, skin in ipairs(charFolder:GetChildren()) do
        local skinFullName = charFolder.Name .. "_" .. skin.Name
        CreateButton(skinFullName)
    end
end

ownedSkins.ChildAdded:Connect(function(newSkin)
    for _, data in ipairs(buttons) do
        if data.skinFullName == newSkin.Name then
            UpdateButton(data.button, data.skinFullName)
        end
    end
end)

ownedSkins.ChildRemoved:Connect(function(removedSkin)
    for _, data in ipairs(buttons) do
        if data.skinFullName == removedSkin.Name then
            UpdateButton(data.button, data.skinFullName)
        end
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
