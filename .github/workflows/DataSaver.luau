local DataStoreService = game:GetService("DataStoreService")
local Data = DataStoreService:GetDataStore("DerelictValues_V1")
local Players = game:GetService("Players")
 
local function CriarLeaderstats(player)
    local var2 = Instance.new("Folder")
    var2.Parent = player
    var2.Name = "leaderstats"
    
    local var3 = Instance.new("StringValue")
    var3.Parent = var2
    var3.Value = "Dignity"
    var3.Name = "KillerSelected"
    
    local var4 = Instance.new("StringValue")
    var4.Parent = var2
    var4.Value = "Bacon"
    var4.Name = "SurvivorSelected"
    
    local var5 = Instance.new("IntValue", var2)
    var5.Name = "Points"
    
    local var6 = Instance.new("IntValue", var2)
    var6.Name = "Malice"
    
    local var7 = Instance.new("StringValue")
    var7.Parent = var2
    var7.Value = "Default"
    var7.Name = "Skin_Killer"
    
    local var8 = Instance.new("StringValue")
    var8.Parent = var2
    var8.Value = "Default"
    var8.Name = "Skin_Survivor"
    
    return var2
end
 
local function CriarFlags(player)
    local f = Instance.new("Folder", player)
    f.Name = "OwnedCharacters"
    
    local f2 = Instance.new("Folder", player)
    f2.Name = "OwnedSkins"
    
    return f, f2
end
 
local function CarregarFlags(flags, dados)
    if not dados or not dados.OwnedCharacters then return end
    
    for _, charName in ipairs(dados.OwnedCharacters) do
        local flag = Instance.new("BoolValue")
        flag.Name = charName
        flag.Value = true
        flag.Parent = flags
    end
end
 
local function CarregarSkins(skins, dados)
    if not dados or not dados.OwnedSkins then return end
    
    for _, skinName in ipairs(dados.OwnedSkins) do
        local flag = Instance.new("BoolValue")
        flag.Name = skinName
        flag.Value = true
        flag.Parent = skins
    end
end
 
-- Salva TODOS os BoolValues da pasta, independente do valor (true ou false)
local function SalvarFlags(flags)
    local owned = {}
    for _, flag in ipairs(flags:GetChildren()) do
        if flag:IsA("BoolValue") then
            table.insert(owned, {
            Name = flag.Name,
            Value = flag.Value
            })
        end
    end
    return owned
end
 
local function SalvarSkins(skins)
    local owned = {}
    for _, flag in ipairs(skins:GetChildren()) do
        if flag:IsA("BoolValue") then
            table.insert(owned, {
            Name = flag.Name,
            Value = flag.Value
            })
        end
    end
    return owned
end
 
-- Carrega considerando o valor salvo (true/false)
local function CarregarFlagsCompleto(flags, dados)
    if not dados or not dados.OwnedCharacters then return end
    
    for _, flagData in ipairs(dados.OwnedCharacters) do
        local flag = Instance.new("BoolValue")
        flag.Name = flagData.Name
        flag.Value = flagData.Value
        flag.Parent = flags
    end
end
 
local function CarregarSkinsCompleto(skins, dados)
    if not dados or not dados.OwnedSkins then return end
    
    for _, skinData in ipairs(dados.OwnedSkins) do
        local flag = Instance.new("BoolValue")
        flag.Name = skinData.Name
        flag.Value = skinData.Value
        flag.Parent = skins
    end
end
 
local function ContarMalicia(player)
    local malixe = player.leaderstats.Malice
    while player.Parent do
        task.wait(30)
        if player.Parent then
            malixe.Value = malixe.Value + 1
        end
    end
end
 
Players.PlayerAdded:Connect(function(player)
    local leader = CriarLeaderstats(player)
    local flags, skins = CriarFlags(player)
    local chave = "Player_" .. player.UserId
    
    local sucesso, dados = pcall(function()
        return Data:GetAsync(chave)
    end)
    
    if sucesso and dados then
        leader.KillerSelected.Value = dados.KillerSelected or "Dignity"
        leader.SurvivorSelected.Value = dados.SurvivorSelected or "Bacon"
        leader.Skin_Killer.Value = dados.Skin_Killer or "Default"
        leader.Skin_Survivor.Value = dados.Skin_Survivor or "Default"
        leader.Points.Value = dados.Points or 300
        leader.Malice.Value = dados.Malice or 0
        
        -- Usa as funções que carregam com valor true/false
        CarregarFlagsCompleto(flags, dados)
        CarregarSkinsCompleto(skins, dados)
        
        print("✅ Carregado com sucesso:", player.Name)
    else
        leader.Points.Value = 300
        
        -- Personagens iniciais
        local digFlag = Instance.new("BoolValue")
        digFlag.Name = "Dignity"
        digFlag.Value = true
        digFlag.Parent = flags
        
        local bacFlag = Instance.new("BoolValue")
        bacFlag.Name = "Bacon"
        bacFlag.Value = true
        bacFlag.Parent = flags
        
        -- Skins iniciais
        local defSkinK = Instance.new("BoolValue")
        defSkinK.Name = "Default_Killer"
        defSkinK.Value = true
        defSkinK.Parent = skins
        
        local defSkinS = Instance.new("BoolValue")
        defSkinS.Name = "Default_Survivor"
        defSkinS.Value = true
        defSkinS.Parent = skins
        
        print("🆕 Player novo! Criando dados padrão...")
    end
    
    task.spawn(function()
        ContarMalicia(player)
    end)
end)
 
Players.PlayerRemoving:Connect(function(player)
    local chave = "Player_" .. player.UserId
    local l = player.leaderstats
    local flags = player:FindFirstChild("OwnedCharacters")
    local skins = player:FindFirstChild("OwnedSkins")
    
    local dados = {
    KillerSelected = l.KillerSelected.Value,
    SurvivorSelected = l.SurvivorSelected.Value,
    Skin_Killer = l.Skin_Killer.Value,
    Skin_Survivor = l.Skin_Survivor.Value,
    Points = l.Points.Value,
    Malice = l.Malice.Value,
    OwnedCharacters = flags and SalvarFlags(flags) or {},
    OwnedSkins = skins and SalvarSkins(skins) or {}
    }
    
    local sucesso, erro = pcall(function()
        Data:SetAsync(chave, dados)
    end)
    
    if sucesso then
        print("💾 Salvo com sucesso!", player.Name)
    else
        warn("❌ Erro ao salvar dados de", player.Name, ":", tostring(erro))
    end
end)
