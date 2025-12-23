local survivorsFolder = game.Workspace.Game.Teams.Survivors
local killersFolder = game.Workspace.Game.Teams.Killer
local charactersFolder = game.ReplicatedStorage.Core:WaitForChild("Characters")
local skinsFolder = game.ReplicatedStorage.Core:WaitForChild("Skins")
local Players = game:GetService("Players")

local morphedPlayers = {}
local processingMorph = {}
local playersInFolder = {}

local function RemoveMorph(player)
    if not morphedPlayers[player] then return end
    
    processingMorph[player] = true
    
    if player.Backpack then
        player.Backpack:ClearAllChildren()
    end
    
    if player.Character then
        player:LoadCharacter()
    end
    
    morphedPlayers[player] = nil
    
    task.wait()
    processingMorph[player] = nil
end

local function GiveBackpackItems(player, morphModel)
    local backpackFolder = morphModel:FindFirstChild("Backpack")
    
    if not backpackFolder then
        return
    end
    
    for _, item in ipairs(backpackFolder:GetChildren()) do
        if item:IsA("Tool") or item:IsA("HopperBin") then
            local itemClone = item:Clone()
            itemClone.Parent = player.Backpack
        elseif item:IsA("LocalScript") then
            if item.Name == "1" then
                local itemClone = item:Clone()
                itemClone.Parent = player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("1")
                player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("1").Visible = true
            elseif item.Name == "2" then
                local itemClone = item:Clone()
                itemClone.Parent = player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("2")
                player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("2").Visible = true
            elseif item.Name == "3" then
                local itemClone = item:Clone()
                itemClone.Parent = player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("3")
                player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("3").Visible = true
            elseif item.Name == "4" then
                local itemClone = item:Clone()
                itemClone.Parent = player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("4")  
                player.PlayerGui.MainUI.AbilityContainer:FindFirstChild("4").Visible = true
            else
                warn("No button for this script:)")    
            end
        end
    end
end

local function MorphPlayer(player, morphType, targetFolder)
    if processingMorph[player] then
        return
    end
    
    if morphedPlayers[player] then
        return
    end
    
    processingMorph[player] = true
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        processingMorph[player] = nil
        return
    end
    
    local selectedValue
    local characterTypeFolder
    local skinTypeFolder
    
    if morphType == "Killer" then
        selectedValue = leaderstats:FindFirstChild("KillerSelected")
        characterTypeFolder = charactersFolder:FindFirstChild("Killers")
        skinTypeFolder = skinsFolder:FindFirstChild("Killers")
    elseif morphType == "Survivor" then
        selectedValue = leaderstats:FindFirstChild("SurvivorSelected")
        characterTypeFolder = charactersFolder:FindFirstChild("Survivors")
        skinTypeFolder = skinsFolder:FindFirstChild("Survivors")
    else
        processingMorph[player] = nil
        return
    end
    
    if not characterTypeFolder or not selectedValue then
        processingMorph[player] = nil
        return
    end
    
    local morphName = selectedValue.Value
    
    if morphName == "" or morphName == nil then
        processingMorph[player] = nil
        return
    end
    
    -- SISTEMA DE SKINS - BUSCA APENAS
    local skinValue = leaderstats:FindFirstChild("Skin_" .. morphType)
    local morphModel
    
    -- Tenta buscar skin customizada
    if skinValue and skinValue.Value ~= "" and skinValue.Value ~= "Default" and skinTypeFolder then
        local characterSkinFolder = skinTypeFolder:FindFirstChild(morphName)
        if characterSkinFolder then
            morphModel = characterSkinFolder:FindFirstChild(skinValue.Value)
        end
    end
    
    -- Se não achou skin, usa o personagem padrão
    if not morphModel then
        morphModel = characterTypeFolder:FindFirstChild(morphName)
    end
    
    if not morphModel then
        processingMorph[player] = nil
        return
    end
    
    local clone = morphModel:Clone()
    clone.Name = player.Name
    
    local backpackInClone = clone:FindFirstChild("Backpack")
    if backpackInClone then
        backpackInClone:Destroy()
    end
    
    local oldChar = player.Character
    local hrp = oldChar and oldChar:FindFirstChild("HumanoidRootPart")
    local pos = hrp and hrp.CFrame or CFrame.new(0, 5, 0)
    
    clone:WaitForChild("HumanoidRootPart").CFrame = pos
    
    -- CORREÇÃO: Pega o som mas NÃO toca ainda
    local chaseSound = clone:FindFirstChild("Chase")
    local ostClone = nil
    
    if chaseSound then
        ostClone = chaseSound:Clone()
        chaseSound:Destroy() -- Remove do clone original
    end
    
    if oldChar then
        for _, item in ipairs(oldChar:GetChildren()) do
            if item:IsA("Tool") or item:IsA("LuaSourceContainer") then
                item.Parent = clone
            end
        end
    end
    
    player.Character = clone
    clone.Parent = targetFolder
    
    morphedPlayers[player] = true
    
    local humanoid = clone:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            morphedPlayers[player] = nil
        end)
    end
    
    task.wait()
    GiveBackpackItems(player, morphModel)
    
    if morphType == "Killer" then
        -- CORREÇÃO: Agora coloca o som no HumanoidRootPart DEPOIS e toca
        if ostClone and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            ostClone.Parent = player.Character.HumanoidRootPart
            
            -- Espera um frame para garantir que está no workspace
            task.wait()
            
            -- Configura propriedades do som para área
            ostClone.RollOffMode = Enum.RollOffMode.Linear
            ostClone.RollOffMaxDistance = 80 -- Distância máxima que ouve
            ostClone.RollOffMinDistance = 10 -- Distância mínima (volume máximo)
            ostClone.Volume = 0.7 -- Volume base
            ostClone.Looped = true -- Loop infinito
            
            -- Agora sim toca
            ostClone:Play()
            
            print("✓ Som de chase tocando em:", player.Name)
        end
        
        player.PlayerGui.MainUI.StatsFrame.Visible = true
        player:SetAttribute("IsKiller", true)
        
        local scs, err = pcall(function() 
            local cs = script.Killer:Clone()
            cs.Parent = player.PlayerGui.MainUI
        end)
        
        if err then
            print(err)
        end
        
        humanoid.WalkSpeed = 6
        humanoid.JumpHeight = 0
    else
        player:SetAttribute("IsKiller", false)
        player.PlayerGui.MainUI.StatsFrame.Visible = true
        local scs, err = pcall(function()
            local cs = script.Survivor:Clone()
            cs.Parent = player.PlayerGui.MainUI  
        end)
        if err then
            print(err)
        end
        humanoid.WalkSpeed = 6
        humanoid.JumpHeight = 0
    end
    
    task.wait()
    processingMorph[player] = nil
end


local function HandleChildAdded(model, morphType, parentFolder)
    if not model:IsA("Model") then return end
    
    local player = Players:FindFirstChild(model.Name)
    
    if player then
        playersInFolder[player] = true
        
        if processingMorph[player] then
            return
        end
        
        if morphedPlayers[player] then
            return
        end
        
        task.wait()
        
        MorphPlayer(player, morphType, parentFolder)
    end
end

local function HandleChildRemoved(model)
    if not model:IsA("Model") then return end
    
    local player = Players:FindFirstChild(model.Name)
    
    if player then
        playersInFolder[player] = nil
        
        if morphedPlayers[player] then
            RemoveMorph(player)
        end
    end
end

survivorsFolder.ChildAdded:Connect(function(model)
    HandleChildAdded(model, "Survivor", survivorsFolder)
end)

survivorsFolder.ChildRemoved:Connect(function(model)
    HandleChildRemoved(model)
end)

killersFolder.ChildAdded:Connect(function(model)
    HandleChildAdded(model, "Killer", killersFolder)
end)

killersFolder.ChildRemoved:Connect(function(model)
    HandleChildRemoved(model)
end)

task.spawn(function()
    while true do
        task.wait(2)     
        for player, _ in pairs(morphedPlayers) do
            if player and player.Parent then
                if not playersInFolder[player] then
                    RemoveMorph(player)
                end
            else
                morphedPlayers[player] = nil
                processingMorph[player] = nil
                playersInFolder[player] = nil
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    morphedPlayers[player] = nil
    processingMorph[player] = nil
    playersInFolder[player] = nil
end)

