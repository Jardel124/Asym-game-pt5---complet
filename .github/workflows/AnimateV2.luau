local RunSvc = game:GetService("RunService")
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
 
local DEBUG = false
 
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
 
-- Event para receber comandos de animação do servidor
local PlayAnimationState = RepStorage:WaitForChild("PlayAnimationState", 10)
 
if not PlayAnimationState then
    warn("[AnimClient] PlayAnimationState não encontrado!")
    return
end
 
-- Pasta de animações
local AnimationsFolder = RepStorage:WaitForChild("Animations", 10)
if not AnimationsFolder then
    warn("[AnimClient] Pasta Animations não encontrada!")
    return
end
 
local AnimSequences = {
Idle = AnimationsFolder:FindFirstChild("Idle"),
Walk = AnimationsFolder:FindFirstChild("Walk"),
Run = AnimationsFolder:FindFirstChild("Run"),
Idle_Injured = AnimationsFolder:FindFirstChild("Idle_Injured"),
Walk_Injured = AnimationsFolder:FindFirstChild("Walk_Injured"),
Run_Injured = AnimationsFolder:FindFirstChild("Run_Injured"),
}
 
local EasingStyles = {
[Enum.PoseEasingStyle.Linear] = Enum.EasingStyle.Linear,
[Enum.PoseEasingStyle.Constant] = Enum.EasingStyle.Linear,
[Enum.PoseEasingStyle.Elastic] = Enum.EasingStyle.Elastic,
[Enum.PoseEasingStyle.Cubic] = Enum.EasingStyle.Cubic,
[Enum.PoseEasingStyle.Bounce] = Enum.EasingStyle.Bounce,
}
 
local EasingDirections = {
[Enum.PoseEasingDirection.In] = Enum.EasingDirection.In,
[Enum.PoseEasingDirection.Out] = Enum.EasingDirection.Out,
[Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut,
}
 
local function debugPrint(...)
    if DEBUG then
        print("[AnimClient]", ...)
    end
end
 
-- Remove Animate padrão
local animate = character:FindFirstChild("Animate")
if animate then
    animate:Destroy()
    debugPrint("Script Animate removido")
end
 
local animator = humanoid:FindFirstChild("Animator")
if animator then
    animator:Destroy()
    debugPrint("Animator removido")
end
 
-- Variáveis de controle
local currentState = "Idle"
local currentPlayer = nil
local activeTweens = {}
local motors = {}
local isTransitioning = false
local transitionStartTime = 0
 
-- Função para parar animação atual com limpeza completa
local function stopCurrentAnimation()
    if currentPlayer then
        debugPrint("Parando animação atual:", currentState)
        currentPlayer.isPlaying = false
        
        -- Cancela e destrói todos os tweens
        for _, tween in pairs(activeTweens) do
            pcall(function()
                tween:Cancel()
                tween:Destroy()
            end)
        end
        activeTweens = {}
        
        currentPlayer = nil
    end
end
 
-- Sistema de animação
local AnimPlayer = {}
AnimPlayer.__index = AnimPlayer
 
function AnimPlayer.new(sequence, isLooping)
    local self = setmetatable({}, AnimPlayer)
    self.sequence = sequence
    self.isLooping = isLooping
    self.isPlaying = false
    self.keyframes = {}
    self.motors = {}
    self.animationThread = nil
    return self
end
 
function AnimPlayer:load()
    local allKeyframes = {}
    for _, kf in pairs(self.sequence:GetKeyframes()) do
        table.insert(allKeyframes, kf)
    end
    table.sort(allKeyframes, function(a, b) return a.Time < b.Time end)
        
        self.keyframes = allKeyframes
        
        -- Mapeia motors
        if #allKeyframes > 0 then
            for _, pose in pairs(allKeyframes[1]:GetDescendants()) do
                if pose:IsA("Pose") and pose.Weight > 0 then
                    for _, motor in pairs(character:GetDescendants()) do
                        if motor:IsA("Motor6D") and motor.Part1 and motor.Part1.Name == pose.Name then
                            self.motors[pose.Name] = motor
                            motors[pose.Name] = motor
                            break
                        end
                    end
                end
            end
        end
    end
    
    function AnimPlayer:play()
        if self.isPlaying then return end
        self.isPlaying = true
        
        debugPrint("Tocando animação:", self.sequence.Name)
        
        -- Para thread anterior se existir
        if self.animationThread then
            task.cancel(self.animationThread)
            self.animationThread = nil
        end
        
        -- Aplica Frame 0 instantaneamente
        if #self.keyframes > 0 then
            for _, pose in pairs(self.keyframes[1]:GetDescendants()) do
                if pose:IsA("Pose") and pose.Weight > 0 and self.motors[pose.Name] then
                    local motor = self.motors[pose.Name]
                    if motor and motor.Parent then
                        motor.Transform = pose.CFrame
                    end
                end
            end
        end
        
        self.animationThread = task.spawn(function()
            while self.isPlaying do
                for i = 1, #self.keyframes - 1 do
                    if not self.isPlaying then break end
                    
                    local kf1 = self.keyframes[i]
                    local kf2 = self.keyframes[i + 1]
                    local duration = kf2.Time - kf1.Time
                    
                    -- Cria tweens para o próximo keyframe
                    local tweenGroup = {}
                    
                    for _, pose in pairs(kf2:GetDescendants()) do
                        if pose:IsA("Pose") and pose.Weight > 0 and self.motors[pose.Name] then
                            local motor = self.motors[pose.Name]
                            
                            -- Verifica se motor ainda existe
                            if motor and motor.Parent then
                                local style = EasingStyles[pose.EasingStyle] or Enum.EasingStyle.Linear
                                local direction = EasingDirections[pose.EasingDirection] or Enum.EasingDirection.Out
                                
                                local tweenInfo = TweenInfo.new(duration, style, direction)
                                local tween = TweenService:Create(motor, tweenInfo, {Transform = pose.CFrame})
                                
                                table.insert(tweenGroup, tween)
                                table.insert(activeTweens, tween)
                                tween:Play()
                            end
                        end
                    end
                    
                    task.wait(duration)
                    
                    -- Limpa tweens completados
                    for _, tween in pairs(tweenGroup) do
                        pcall(function()
                            tween:Destroy()
                        end)
                    end
                end
                
                if not self.isLooping then
                    break
                end
            end
            
            if self.isPlaying then
                self.isPlaying = false
            end
            
            self.animationThread = nil
        end)
    end
    
    function AnimPlayer:stop()
        self.isPlaying = false
        
        -- Cancela thread se existir
        if self.animationThread then
            task.cancel(self.animationThread)
            self.animationThread = nil
        end
    end
    
    -- Carrega todas as animações
    local loadedAnimations = {}
    for name, sequence in pairs(AnimSequences) do
        if sequence then
            local isLooping = (name ~= "Jump")
            local animPlayer = AnimPlayer.new(sequence, isLooping)
            animPlayer:load()
            loadedAnimations[name] = animPlayer
            debugPrint("Animação carregada:", name)
        end
    end
    
    -- Recebe comandos do servidor
    PlayAnimationState.OnClientEvent:Connect(function(targetPlayer, newState)
        if not targetPlayer or not targetPlayer.Character then return end
        
        -- Só processa se for o próprio jogador
        if targetPlayer ~= player then return end
        
        -- Verifica se já está em transição
        local currentTime = tick()
        if isTransitioning and (currentTime - transitionStartTime) < 0.15 then
            debugPrint("Ainda em transição, aguardando...")
            return
        end
        
        if newState ~= currentState then
            isTransitioning = true
            transitionStartTime = currentTime
            
            debugPrint("===================================")
            debugPrint("Mudança de estado:", currentState, "=>", newState)
            
            -- Para animação atual completamente
            stopCurrentAnimation()
            
            -- Pequeno delay para garantir limpeza
            task.wait(0.03)
            
            -- Toca nova animação
            local animToPlay = loadedAnimations[newState]
            if animToPlay then
                currentState = newState
                currentPlayer = animToPlay
                animToPlay:play()
            else
                debugPrint("Animação não encontrada:", newState)
            end
            
            debugPrint("===================================")
            
            -- Libera transição após delay
            task.wait(0.05)
            isTransitioning = false
        end
    end)
    
    debugPrint("Sistema de animação inicializado para:", player.Name)
