--------------------------------------------------------------------------------
-- [MODULE] background.lua — XIFIL Hub PRO
-- Auto Skill, Weapon Switch, Auto Buy background loops
--------------------------------------------------------------------------------
local ctx = ...
local Services     = ctx.Services
local EngineConfig = ctx.EngineConfig
local LocalPlayer  = ctx.LocalPlayer
local PlayerActionRE = ctx.PlayerActionRE
local EquipmentRE    = ctx.EquipmentRE

local function getActiveSkills(preset)
    if preset=="Semua (1+2+U)"    then return {"Skill1","Skill2","SkillU"}
    elseif preset=="Skill1 Saja"  then return {"Skill1"}
    elseif preset=="Skill2 Saja"  then return {"Skill2"}
    elseif preset=="SkillU Saja"  then return {"SkillU"}
    elseif preset=="Skill1 + Skill2" then return {"Skill1","Skill2"}
    elseif preset=="Skill1 + SkillU" then return {"Skill1","SkillU"}
    elseif preset=="Skill2 + SkillU" then return {"Skill2","SkillU"}
    end
    return {"Skill1","Skill2","SkillU"}
end

-- Auto Skill
task.spawn(function()
    while true do
        if EngineConfig.AutoSkillActive then
            local skills=getActiveSkills(EngineConfig.SkillPreset)
            for _,skillName in ipairs(skills) do
                for combo=1,3 do
                    pcall(function() PlayerActionRE:FireServer("SkillAction",skillName,combo) end)
                    task.wait(EngineConfig.SkillCooldownDelay)
                end
            end
            task.wait(5)
        else task.wait(0.5) end
    end
end)

-- Auto Weapon Switch
task.spawn(function()
    while true do
        if EngineConfig.AutoWeaponSwitchActive then
            pcall(function() EquipmentRE:FireServer("ChangeWeaponSlot") end)
            task.wait(3)
        else task.wait(0.5) end
    end
end)

-- Auto Buy
task.spawn(function()
    local RS=Services.ReplicatedStorage
    local GoldShopRE=RS:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("GoldShopSystem"):WaitForChild("GoldShopUtil"):WaitForChild("RemoteEvent")
    while true do
        task.wait(0.05)
        if EngineConfig.AutoBuyActive then
            local mainGui=LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
            local sf=mainGui
                and mainGui:FindFirstChild("ScreenGoldShop")
                and mainGui.ScreenGoldShop:FindFirstChild("Content")
                and mainGui.ScreenGoldShop.Content:FindFirstChild("ScrollingFrame")
            if sf then
                for _,item in pairs(sf:GetChildren()) do
                    if EngineConfig.AutoBuyTargetList[item.Name] then
                        local stockTXT=item:FindFirstChild("StockTXT",true); local harga=0
                        for _,child in pairs(item:GetDescendants()) do
                            if child.Name=="Count" and child:IsA("TextLabel") and not child.Text:find("x") then
                                harga=tonumber(child.Text) or 0
                            end
                        end
                        if stockTXT and harga~=99 then
                            local stok=tonumber(stockTXT.Text:match("%d+")) or 0
                            if stok>=1 and stok<=9 then
                                pcall(function() GoldShopRE:FireServer("BuyGoldShopItem",item.Name) end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Forge QTE hook (always-on, fixed values)
task.spawn(function()
    local RS=Services.ReplicatedStorage
    local ForgeUtil=require(RS:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):WaitForChild("ForgeUtil"))
    if not _G.XiFil_OriginalQTE then _G.XiFil_OriginalQTE=ForgeUtil.QTE end
    ForgeUtil.QTE=function(...)
        local args={...}; local data=nil
        for _,v in pairs(args) do if type(v)=="table" and v.UUID then data=v; break end end
        if data then
            task.spawn(function()
                local RF=ctx.ForgeRF
                for _=1,1 do RF:InvokeServer("QTE",{UUID=data.UUID,Rating=15}); task.wait() end
                for _=1,1 do RF:InvokeServer("ForgeFinish"); task.wait() end
                for _=1,1 do RF:InvokeServer("ForgeResult",true); task.wait() end
            end)
        end
        return _G.XiFil_OriginalQTE(...)
    end
end)
