local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer:CharacterAdded()
local timer = game.ReplicatedStorage.Core.Game:WaitForChild("Timer")
local inter = game.ReplicatedStorage.Core.Game:WaitForChild("Inter")
local interTime = game.ReplicatedStorage.Core.Game:WaitForChild("InterTime")
local waitplr = game.ReplicatedStorage.Core.Game:WaitForChild("MinPlayers") -- BoolValue
local killer = game.Workspace.Game.Teams.Killer
local surv = game.Workspace.Game.Teams.Survivors
local ac = script.Parent.Parent.AbilityContainer
local function c()
    for _,i in pairs(ac:GetDescendants()) do
        if i:IsA("LocalScript") then
            i:Destroy()
        end
        if i:IsA("TextButton") then
            i.Visible = false
            i.Text = "PlaceHolder"
        end
    end
end 

local function v(t,v)
    t.Visible = v
end

while true do
    task.wait(0.05)
    if waitplr.Value == true then
        script.Parent.Text = "Waiting for more players!" 
        v(ac,false)
        c() 
    else
        if inter.Value == false then
            script.Parent.Text = "Round Ends in : " .. timer.Value 
            v(ac,true)
        else
            script.Parent.Text = "Round Starts in : " .. interTime.Value 
            v(ac,false)
            c()      
        end
    end
end
