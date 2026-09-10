--[[
    ===================================================================
    🦘 JUMP FOR ANIMALS! - ULTIMATE AUTO HUB (FAST LOADER V1.0)
    ===================================================================
--]]
pcall(function()
    local container = (gethui and gethui()) or game:GetService("CoreGui")
    if container and container:FindFirstChild("JumpForAnimalsGui") then
        container.JumpForAnimalsGui:Destroy()
    end
    local pl = game:GetService("Players").LocalPlayer
    if pl and pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("JumpForAnimalsGui") then
        pl.PlayerGui.JumpForAnimalsGui:Destroy()
    end
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/khahuynh963/jump_for_animals/main/script.lua?" .. math.random(1, 999999)))()
