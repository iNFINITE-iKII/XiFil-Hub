--------------------------------------------------------------------------------
--// notify.lua — S04 Notification Engine
--------------------------------------------------------------------------------
local H           = getgenv().Hub
local LocalPlayer = H.LocalPlayer
local TweenService = H.TweenService
local RuntimeMaid  = H.RuntimeMaid

-- [S04] NOTIFICATION ENGINE
--------------------------------------------------------------------------------
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name="XiFil_Notif"; NotifGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
NotifGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; NotifGui.ResetOnSpawn=false
RuntimeMaid:GiveTask(NotifGui)

local NC = Instance.new("Frame")
NC.Name="Container"; NC.Parent=NotifGui; NC.BackgroundTransparency=1
NC.Size=UDim2.new(0,260,1,-120); NC.Position=UDim2.new(1,-280,0,0); NC.ZIndex=99999
local NL = Instance.new("UIListLayout",NC)
NL.SortOrder=Enum.SortOrder.LayoutOrder; NL.Padding=UDim.new(0,10)
NL.VerticalAlignment=Enum.VerticalAlignment.Bottom; NL.HorizontalAlignment=Enum.HorizontalAlignment.Right

local function CustomNotify(title, text, duration)
    local VC = H.VisualConfig
    if VC and VC.NotifEnabled == false then return end
    duration = duration or 3
    local notifSize = (VC and VC.FontSize) or 8
    local notifH = math.max(60, notifSize * 3 + 6)
    local W = Instance.new("Frame"); W.Parent=NC; W.BackgroundTransparency=1; W.Size=UDim2.new(0,260,0,notifH)
    local NF = Instance.new("Frame"); NF.Parent=W; NF.BackgroundColor3=Color3.fromRGB(20,20,27)
    NF.Size=UDim2.new(1,0,1,0); NF.Position=UDim2.new(1,50,0,0); NF.BackgroundTransparency=1
    Instance.new("UICorner",NF).CornerRadius=UDim.new(0,6)
    local Stroke=Instance.new("UIStroke",NF); Stroke.Color=Color3.fromRGB(96,205,255); Stroke.Thickness=1.2; Stroke.Transparency=1
    local Accent=Instance.new("Frame",NF); Accent.BackgroundColor3=Color3.fromRGB(96,205,255)
    Accent.Size=UDim2.new(0,3,0,0); Accent.Position=UDim2.new(0,12,0.5,0); Accent.AnchorPoint=Vector2.new(0,0.5)
    Accent.BackgroundTransparency=1; Instance.new("UICorner",Accent).CornerRadius=UDim.new(1,0)
    local TL=Instance.new("TextLabel",NF); TL.BackgroundTransparency=1; TL.Size=UDim2.new(1,-34,0,notifSize+8); TL.Position=UDim2.new(0,24,0,8)
    TL.Font=Enum.Font.GothamBold; TL.Text=string.upper(title); TL.TextColor3=Color3.fromRGB(96,205,255); TL.TextSize=notifSize; TL.TextXAlignment=Enum.TextXAlignment.Left; TL.TextTransparency=1; TL.TextWrapped=true
    local BL=Instance.new("TextLabel",NF); BL.BackgroundTransparency=1; BL.Size=UDim2.new(1,-34,0,notifSize+6); BL.Position=UDim2.new(0,24,0,8+notifSize+10)
    BL.Font=Enum.Font.Gotham; BL.Text=text; BL.TextColor3=Color3.fromRGB(200,200,200); BL.TextSize=math.max(6, notifSize - 2); BL.TextXAlignment=Enum.TextXAlignment.Left; BL.TextTransparency=1; BL.TextWrapped=true
    local ti=TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    TweenService:Create(NF,ti,{Position=UDim2.new(0,0,0,0),BackgroundTransparency=0.1}):Play()
    TweenService:Create(Stroke,ti,{Transparency=0}):Play()
    TweenService:Create(TL,ti,{TextTransparency=0}):Play()
    TweenService:Create(BL,ti,{TextTransparency=0}):Play()
    TweenService:Create(Accent,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,3,1,-24),BackgroundTransparency=0}):Play()
    task.delay(duration,function()
        local to=TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        TweenService:Create(NF,to,{Position=UDim2.new(1,50,0,0),BackgroundTransparency=1}):Play()
        TweenService:Create(Stroke,to,{Transparency=1}):Play()
        TweenService:Create(TL,to,{TextTransparency=1}):Play()
        TweenService:Create(BL,to,{TextTransparency=1}):Play()
        TweenService:Create(W,to,{Size=UDim2.new(0,260,0,0)}):Play()
        task.wait(0.4); W:Destroy()
    end)
end


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.CustomNotify = CustomNotify
H.NC           = NC    -- notification container (dibutuhkan ui_core S16b patch)
getgenv().XiFil_CustomNotify = CustomNotify   -- backward-compat
