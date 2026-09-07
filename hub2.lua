getgenv() = game:getservice("CoreGui"):FindFirstChild("LOL Hub") or Instance.new("ScreenGui", game:GetService("CoreGui"))
getgenv().__LOL_ToggleHub = function()
    hubOpen = not hubOpen
    if hubOpen then
        hub:Show()
    else
        hub:Hide()
    end
     game:getservice("Players").LocalPlayer.PlayerGui:FindFirstChild("LOL Hub").Enabled = hubOpen
end