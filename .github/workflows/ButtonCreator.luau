local template = script.Parent.Template
local killers = game.ReplicatedStorage.Core.Characters.Killers
local survivors = game.ReplicatedStorage.Core.Characters.Survivors
local player = game.Players.LocalPlayer
local flags = player:WaitForChild("OwnedCharacters")
local buyEvent = game.ReplicatedStorage.Core.Network:WaitForChild("BuyCharEvent")
 
local buttons = {}
 
local function Have(charName)
    return flags:FindFirstChild(charName) ~= nil
end
 
local function IsKiller(charName)
    return killers:FindFirstChild(charName) ~= nil
end
 
local function UpdateButton(button, charName)
    local owned = Have(charName)
    local status = owned and "Already Have" or "Buy"
    button.Text = charName .. " : " .. status
end
 
local function CreateButton(char, charType)
    local button = template:Clone()
    button.Name = char.Name
    button.Parent = script.Parent
    button.Visible = true
    
    UpdateButton(button, char.Name)
    
    button.MouseButton1Click:Connect(function()
        if not Have(char.Name) then
            buyEvent:FireServer(char.Name, true, charType)
        end
    end)
    
    table.insert(buttons, {button = button, charName = char.Name})
end
 
for _, killer in ipairs(killers:GetChildren()) do
    CreateButton(killer, "Killer")
end
 
for _, survivor in ipairs(survivors:GetChildren()) do
    CreateButton(survivor, "Survivor")
end
 
flags.ChildAdded:Connect(function(newFlag)
    for _, data in ipairs(buttons) do
        if data.charName == newFlag.Name then
            UpdateButton(data.button, data.charName)
        end
    end
end)
 
flags.ChildRemoved:Connect(function(removedFlag)
    for _, data in ipairs(buttons) do
        if data.charName == removedFlag.Name then
            UpdateButton(data.button, data.charName)
        end
    end
end)
 
task.spawn(function()
    while true do
        task.wait(2)
        for _, data in ipairs(buttons) do
            if data.button and data.button.Parent then
                UpdateButton(data.button, data.charName)
            end
        end
    end
end)
