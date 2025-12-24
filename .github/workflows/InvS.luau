local template = script.Parent.Template
local killers = game.ReplicatedStorage.Core.Characters.Killers
local survivors = game.ReplicatedStorage.Core.Characters.Survivors
local player = game.Players.LocalPlayer
local flags = player:WaitForChild("OwnedCharacters")
local leaderstats = player:WaitForChild("leaderstats")
local buyEvent = game.ReplicatedStorage.Core.Network:WaitForChild("BuyCharEvent")
 
local buttons = {}
 
local function IsKiller(charName)
    return killers:FindFirstChild(charName) ~= nil
end
 
local function IsEquipped(charName)
    if IsKiller(charName) then
        return leaderstats.KillerSelected.Value == charName
    else
        return leaderstats.SurvivorSelected.Value == charName
    end
end
 
local function UpdateButton(button, charName, charType)
    local equipped = IsEquipped(charName)
    local status = equipped and "Equipped" or "Equip"
    button.Text = charName .. " : " .. status
end
 
local function CreateButton(charName, charType)
    local button = template:Clone()
    button.Name = charName
    button.Parent = script.Parent
    button.Visible = true
    
    UpdateButton(button, charName, charType)
    
    button.MouseButton1Click:Connect(function()
        if not IsEquipped(charName) then
            buyEvent:FireServer(charName, false, charType)
        end
    end)
    
    table.insert(buttons, {button = button, charName = charName, charType = charType})
end
 
local function RefreshInventory()
    for _, data in ipairs(buttons) do
        if data.button then
            data.button:Destroy()
        end
    end
    buttons = {}
    
    for _, flag in ipairs(flags:GetChildren()) do
        if flag:IsA("BoolValue") and flag.Value then
            local charType = IsKiller(flag.Name) and "Killer" or "Survivor"
            CreateButton(flag.Name, charType)
        end
    end
end
 
RefreshInventory()
 
flags.ChildAdded:Connect(function()
    task.wait(0.1)
    RefreshInventory()
end)
 
flags.ChildRemoved:Connect(function()
    task.wait(0.1)
    RefreshInventory()
end)
 
leaderstats.KillerSelected:GetPropertyChangedSignal("Value"):Connect(function()
    for _, data in ipairs(buttons) do
        if data.charType == "Killer" then
            UpdateButton(data.button, data.charName, data.charType)
        end
    end
end)
 
leaderstats.SurvivorSelected:GetPropertyChangedSignal("Value"):Connect(function()
    for _, data in ipairs(buttons) do
        if data.charType == "Survivor" then
            UpdateButton(data.button, data.charName, data.charType)
        end
    end
end)
 
task.spawn(function()
    while true do
        task.wait(2)
        for _, data in ipairs(buttons) do
            if data.button and data.button.Parent then
                UpdateButton(data.button, data.charName, data.charType)
            end
        end
    end
end)
