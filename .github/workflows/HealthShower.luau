local fill = script.Parent
local ts = game:GetService("TweenService")
local tsinfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local player = game.Players.LocalPlayer
local info = script.Parent.Parent.Info
-- 🔁 Função para conectar o evento de vida
local function conectarHumanoid(hum)
    if not hum then return end
    
    local oldHealth = hum.Health
    info.Text = oldHealth .. "/" .. hum.MaxHealth
    -- Atualiza o tamanho inicial
    fill.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)
    
    -- Quando a vida mudar
    hum.HealthChanged:Connect(function(newHealth)
        local porcentagem = newHealth / hum.MaxHealth
        local tween = ts:Create(fill, tsinfo, {
        Size = UDim2.new(porcentagem, 0, 1, 0)
        })
        tween:Play()
        oldHealth = newHealth
        info.Text = newHealth .. "/" .. hum.MaxHealth
    end)
end

-- 🔹 Detecta o personagem atual
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
conectarHumanoid(hum)

-- 🔁 Detecta quando o player renascer
player.CharacterAdded:Connect(function(newChar)
    local newHum = newChar:WaitForChild("Humanoid")
    conectarHumanoid(newHum)
end)

