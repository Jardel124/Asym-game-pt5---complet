local button1 = script.Parent.open2
local button2 = script.Parent.open2skin
 
local frame1 = script.Parent.ShopF
local frame2 = script.Parent.ShopSF
 
local color1 = Color3.fromRGB(0,0,0)
local color2 = Color3.fromRGB(255,255,255)
 
local function ChangeColor(newColor, button)
    button.BackgroundColor3 = newColor
end
 
button1.MouseButton1Click:Connect(function()  
    frame2.Visible = false
    frame1.Visible = true
    ChangeColor(color1, button2)
    ChangeColor(color2, button1) 
end)
 
button2.MouseButton1Click:Connect(function()
    frame2.Visible = true  
    frame1.Visible = false
    ChangeColor(color1, button1)
    ChangeColor(color2, button2)
end)
