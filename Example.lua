--[[
    Example usage of UILibrary (redesigned: icon-rail sidebar + Home tab).
    Replace the loadstring URL with wherever you host UILibrary.lua.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/yourrepo/main/UILibrary.lua"))()

local function buildMainWindow()
    local Window = Library:CreateWindow({
        Title = "Hex Scripts",
        SubTitle = "v1.0.0",
        Logo = "rbxassetid://0",           -- your uploaded logo decal id
        ToggleKey = Enum.KeyCode.RightControl,
    })

    -- ===== Home tab: profile, server info, executor status, Discord, friends =====
    Library:CreateHomeTab(Window, {
        HubName = "Hex Scripts",
        DiscordInvite = ".gg/yourinvite", -- set to nil to hide the Discord card
    })

    -- ===== Main tab =====
    local MainTab = Window:CreateTab("Main") -- pass an rbxassetid as a 2nd arg for a custom icon
    local GeneralSection = MainTab:CreateSection("General")

    GeneralSection:AddButton({
        Text = "Print Hello",
        Callback = function() print("Hello from UILibrary!") end,
    })

    GeneralSection:AddToggle({
        Text = "Enable Feature",
        Default = false,
        Flag = "EnableFeature",
        Callback = function(state) print("Feature enabled:", state) end,
    })

    GeneralSection:AddSlider({
        Text = "Walk Speed",
        Min = 16, Max = 200, Default = 16,
        Flag = "WalkSpeed",
        Callback = function(value)
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = value
            end
        end,
    })

    GeneralSection:AddTextbox({
        Text = "Custom Message",
        Placeholder = "Type here...",
        Flag = "CustomMessage",
        Callback = function(text, enterPressed)
            print("Textbox value:", text, "Enter pressed:", enterPressed)
        end,
    })

    GeneralSection:AddKeybind({
        Text = "Execute Action",
        Default = Enum.KeyCode.E,
        Flag = "ExecuteKey",
        OnPress = function() print("Execute key pressed!") end,
    })

    local PlayerDropdown
    PlayerDropdown = GeneralSection:AddDropdown({
        Text = "Select Player",
        Options = {},
        Flag = "SelectedPlayer",
        Callback = function(selection) print("Selected:", selection) end,
    })

    local function refreshPlayerList()
        local names = {}
        for _, plr in ipairs(game.Players:GetPlayers()) do
            table.insert(names, plr.Name)
        end
        PlayerDropdown:Refresh(names)
    end
    refreshPlayerList()
    game.Players.PlayerAdded:Connect(refreshPlayerList)
    game.Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        refreshPlayerList()
    end)

    GeneralSection:AddDropdown({
        Text = "Multi Select Example",
        Options = {"Option A", "Option B", "Option C"},
        Multi = true,
        Flag = "MultiSelect",
        Callback = function(selection) print("Multi selection changed") end,
    })

    -- ===== Settings tab (theme/gradient customizer) =====
    Library:CreateSettingsTab(Window)
end

local function startKeySystem()
    Library:CreateKeySystem({
        Title = "Hex Scripts",
        Subtitle = "Enter your key to continue",
        GetKeyLink = "https://linkvertise.com/your-link-here", -- set to nil to hide "Get Key"
        CheckKey = function(key)
            local validKeys = {"HEX-DEMO-KEY"} -- replace with a real check (HTTP request, etc)
            for _, k in ipairs(validKeys) do
                if key == k then return true end
            end
            return false
        end,
        OnSuccess = buildMainWindow,
    })
end

Library:PlayIntro({
    Image = "rbxassetid://0", -- your uploaded logo decal id
    Text = "Hex Scripts",
    OnComplete = startKeySystem,
})
