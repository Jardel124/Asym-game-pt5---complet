local button = script.Parent
local framename = button.Name .. "Frame"
local frame = button.Parent:WaitForChild(framename)

button.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)
 
 
 
 
 
 
