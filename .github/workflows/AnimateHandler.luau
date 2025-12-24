local RunSvc = game:GetService("RunService")
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")

local DEBUG = false

-- Cria RemoteEvent se não existir
local PlayAnimationState = RepStorage:FindFirstChild("PlayAnimationState")
if not PlayAnimationState then
    PlayAnimationState = Instance.new("RemoteEvent")
    PlayAnimationState.Name = "PlayAnimationState"
    PlayAnimationState.Parent = RepStorage
end

-- Configurações
local RUN_THRESHOLD = 15
local WALK_THRESHOLD = 1
local INJURED_THRESHOLD = 50
local STATE_CHANGE_COOLDOWN = 0.08 -- Cooldown menor para transições mais suaves
local VELOCITY_SAMPLES = 3 -- Número de amostras para suavização

local CharacterData = {}

local function debugPrint(...)
    if DEBUG then
        print("[AnimServer]", ...)
    end
end

-- Envia estado para todos os jogadores
local function FireToAll(targetPlayer, newState)
    for _, player in ipairs(Players:GetPlayers()) do
        PlayAnimationState:FireClient(player, targetPlayer, newState)
    end
    debugPrint("Estado enviado para todos:", targetPlayer.Name, "=>", newState)
end

-- Calcula média das velocidades recentes
local function getAverageSpeed(data)
    if #data.VelocityHistory == 0 then return 0 end
    
    local sum = 0
    for _, speed in ipairs(data.VelocityHistory) do
        sum = sum + speed
    end
    return sum / #data.VelocityHistory
end

-- Muda estado de animação
local function changeState(player, data, newState)
    if not data.Humanoid or not data.RootPart then return end
    if data.CurrentState == newState then return end
    
    -- Respeita cooldown
    local currentTick = tick()
    if data.LastStateChange and (currentTick - data.LastStateChange) < STATE_CHANGE_COOLDOWN then
        return
    end
    
    debugPrint("Mudando estado de", player.Name, ":", data.CurrentState, "=>", newState)
    
    data.CurrentState = newState
    data.LastStateChange = currentTick
    FireToAll(player, newState)
end

-- Determina estado baseado na velocidade e saúde
local function determineState(data, avgSpeed)
    local isInjured = data.Humanoid.Health < INJURED_THRESHOLD
    local currentState = data.CurrentState
    
    -- Thresholds com histerese para evitar flicker
    local runMin = RUN_THRESHOLD
    local runMax = RUN_THRESHOLD - 3
    local walkMin = WALK_THRESHOLD
    local walkMax = WALK_THRESHOLD + 0.3
    
    -- Se já está correndo, precisa cair mais para mudar
    if currentState == "Run" or currentState == "Run_Injured" then
        if avgSpeed >= runMax then
            return isInjured and "Run_Injured" or "Run"
        elseif avgSpeed > walkMin then
            return isInjured and "Walk_Injured" or "Walk"
        else
            return isInjured and "Idle_Injured" or "Idle"
        end
        -- Se já está andando
    elseif currentState == "Walk" or currentState == "Walk_Injured" then
        if avgSpeed >= runMin then
            return isInjured and "Run_Injured" or "Run"
        elseif avgSpeed > walkMax then
            return isInjured and "Walk_Injured" or "Walk"
        else
            return isInjured and "Idle_Injured" or "Idle"
        end
        -- Se está parado
    else
        if avgSpeed >= runMin then
            return isInjured and "Run_Injured" or "Run"
        elseif avgSpeed > walkMin then
            return isInjured and "Walk_Injured" or "Walk"
        else
            return isInjured and "Idle_Injured" or "Idle"
        end
    end
end

-- Setup do personagem
local function handleCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    debugPrint("======================================")
    debugPrint("Configurando personagem:", player.Name)
    
    local humanoid = character:WaitForChild("Humanoid", 10)
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)
    
    if not humanoid or not rootPart then
        warn("[AnimServer] Humanoid ou RootPart não encontrado!")
        return
    end
    
    -- Desabilita sentar
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    local data = {
    Character = character,
    Humanoid = humanoid,
    RootPart = rootPart,
    CurrentState = "Idle",
    IsJumping = false,
    LastStateChange = 0,
    VelocityHistory = {},
    WasMoving = false,
    }
    CharacterData[player] = data
    
    -- Estado inicial
    task.wait(0.2)
    local initialState = humanoid.Health < INJURED_THRESHOLD and "Idle_Injured" or "Idle"
    changeState(player, data, initialState)
    
    -- Detecta pulos e estados especiais
    humanoid.StateChanged:Connect(function(oldState, newState)
        debugPrint(player.Name, "- State:", oldState.Name, "=>", newState.Name)
        
        if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
            data.IsJumping = true
            debugPrint(player.Name, "- Pulando/Caindo")
        elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
            if data.IsJumping then
                data.IsJumping = false
                debugPrint(player.Name, "- Pousou")
                -- Força atualização após pousar
                task.wait(0.05)
                local velocity = data.RootPart.AssemblyLinearVelocity
                local speed = math.sqrt(velocity.X^2 + velocity.Z^2)
                local newAnimState = determineState(data, speed)
                changeState(player, data, newAnimState)
            end
        end
    end)
    
    debugPrint("Personagem configurado:", player.Name)
    debugPrint("======================================")
end

-- Remove dados ao sair
local function onPlayerRemoving(player)
    CharacterData[player] = nil
    debugPrint("Jogador removido:", player.Name)
end

-- Setup do jogador
local function onPlayerAdded(player)
    debugPrint("Jogador entrou:", player.Name)
    
    player.CharacterAdded:Connect(handleCharacterAdded)
    player.CharacterRemoving:Connect(function()
        CharacterData[player] = nil
    end)
    
    if player.Character then
        handleCharacterAdded(player.Character)
    end
end

-- Conecta eventos
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Setup jogadores existentes
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Loop principal de detecção de movimento
RunSvc.Heartbeat:Connect(function()
    for player, data in pairs(CharacterData) do
        -- Verifica se dados são válidos
        if not data.Character or not data.Humanoid or data.Humanoid.Health <= 0 or not data.RootPart then
            -- Não faz nada se inválido
        else
            -- Durante pulo, não muda animação
            if not data.IsJumping then
                -- Calcula velocidade atual
                local velocity = data.RootPart.AssemblyLinearVelocity
                local horizontalSpeed = math.sqrt(velocity.X^2 + velocity.Z^2)
                
                -- Adiciona à história de velocidades
                table.insert(data.VelocityHistory, horizontalSpeed)
                if #data.VelocityHistory > VELOCITY_SAMPLES then
                    table.remove(data.VelocityHistory, 1)
                end
                
                -- Calcula velocidade média
                local avgSpeed = getAverageSpeed(data)
                
                -- Determina novo estado
                local newState = determineState(data, avgSpeed)
                
                -- Detecta se parou completamente (colidiu com parede)
                local isMoving = avgSpeed > 0.1
                if data.WasMoving and not isMoving then
                    -- Forçar estado Idle quando parar
                    local isInjured = data.Humanoid.Health < INJURED_THRESHOLD
                    newState = isInjured and "Idle_Injured" or "Idle"
                    debugPrint(player.Name, "- Parou completamente, forçando Idle")
                end
                data.WasMoving = isMoving
                
                -- Muda se for diferente
                if newState ~= data.CurrentState then
                    changeState(player, data, newState)
                end
            end
        end
    end
end)

debugPrint("Sistema de animação do servidor inicializado!")
