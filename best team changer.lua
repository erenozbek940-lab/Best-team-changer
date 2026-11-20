if getgenv().BTF_FULL then pcall(getgenv().BTF_FULL_Cleanup) end
getgenv().BTF_FULL = true

local Players    = game:GetService("Players")
local Teams      = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer
local conns      = {}
local function track(c) table.insert(conns,c) return c end

-- ═══════════════════════════════════════
-- KALICI DURUM
-- ═══════════════════════════════════════
local selTeam     = nil   -- seçili team objesi
local selTeamName = ""    -- seçili team adı

-- ═══════════════════════════════════════
-- OVERHEAD TAG (Guest | RütbeAdı)
-- ═══════════════════════════════════════
local function getRankColor(name)
    local n = name:lower()
    if n:match("sivil") or n:match("civilian") then return Color3.fromRGB(220,220,220) end
    if n:match("inzibat") then return Color3.fromRGB(20,20,20) end
    if n:match("özel kuvvet") or n:match("ozel kuvvet") or n:match("ökk") then return Color3.fromRGB(180,0,0) end
    if n:match("komutan") or n:match("general") or n:match("paşa") then return Color3.fromRGB(255,180,0) end
    if n:match("albay") then return Color3.fromRGB(220,160,0) end
    if n:match("yarbay") then return Color3.fromRGB(200,140,0) end
    if n:match("binbaşı") or n:match("binbasi") then return Color3.fromRGB(0,160,80) end
    if n:match("yüzbaşı") or n:match("yuzbasi") then return Color3.fromRGB(0,140,70) end
    if n:match("üsteğmen") or n:match("ustegmen") then return Color3.fromRGB(0,120,60) end
    if n:match("teğmen") or n:match("tegmen") then return Color3.fromRGB(0,100,50) end
    if n:match("çavuş") or n:match("cavus") then return Color3.fromRGB(80,120,200) end
    if n:match("onbaşı") or n:match("onbasi") then return Color3.fromRGB(60,100,180) end
    if n:match("er") or n:match("asker") then return Color3.fromRGB(50,80,160) end
    if n:match("pilot") then return Color3.fromRGB(0,100,255) end
    if n:match("deniz") then return Color3.fromRGB(0,50,200) end
    return Color3.fromRGB(100,100,120)
end

local function setOverhead(char, rankName)
    if not char then return end
    local head = char:WaitForChild("Head", 5)
    if not head then return end

    -- Mevcut oyun tag'larını gizle (üsttekini sil)
    for _, v in ipairs(head:GetChildren()) do
        if v:IsA("BillboardGui") and v.Name ~= "BTF_Tag" then
            v.Enabled = false
        end
    end

    -- BTF_Tag oluştur veya güncelle
    local tag = head:FindFirstChild("BTF_Tag")
    if not tag then
        tag = Instance.new("BillboardGui")
        tag.Name = "BTF_Tag"
        tag.AlwaysOnTop = false
        tag.Size = UDim2.new(0, 200, 0, 50)
        tag.StudsOffset = Vector3.new(0, 2.8, 0)
        tag.Parent = head

        -- Üst satır: Guest (beyaz)
        local line1 = Instance.new("TextLabel")
        line1.Name = "Line1"
        line1.Size = UDim2.new(1, 0, 0.5, 0)
        line1.BackgroundTransparency = 1
        line1.Text = "Guest"
        line1.TextColor3 = Color3.fromRGB(230, 230, 230)
        line1.TextSize = 13
        line1.Font = Enum.Font.GothamBold
        line1.TextStrokeTransparency = 0.3
        line1.TextStrokeColor3 = Color3.new(0,0,0)
        line1.Parent = tag

        -- Alt satır: Rütbe adı (rütbe rengi)
        local line2 = Instance.new("TextLabel")
        line2.Name = "Line2"
        line2.Size = UDim2.new(1, 0, 0.5, 0)
        line2.Position = UDim2.new(0, 0, 0.5, 0)
        line2.BackgroundTransparency = 1
        line2.Text = rankName
        line2.TextColor3 = getRankColor(rankName)
        line2.TextSize = 13
        line2.Font = Enum.Font.GothamBold
        line2.TextStrokeTransparency = 0.3
        line2.TextStrokeColor3 = Color3.new(0,0,0)
        line2.Parent = tag
    else
        local l1 = tag:FindFirstChild("Line1")
        local l2 = tag:FindFirstChild("Line2")
        if l1 then l1.Text = "Guest" end
        if l2 then
            l2.Text = rankName
            l2.TextColor3 = getRankColor(rankName)
        end
        tag.Enabled = true
    end
end

-- ═══════════════════════════════════════
-- KIYAFETLERİ UYGULA
-- Önce aynı takımdaki oyuncudan kopyala,
-- bulamazsa varsayılan askeri kıyafet
-- ═══════════════════════════════════════
local function applyClothing(rankName)
    local char = LP.Character if not char then return end

    -- Aynı takımdan birinin kıyafetini kopyala
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if selTeam and p.Team == selTeam and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local desc = hum and hum:FindFirstChildOfClass("HumanoidDescription")
            if desc then
                pcall(function()
                    local myHum = char:FindFirstChildOfClass("Humanoid")
                    if myHum then
                        local myDesc = myHum:GetAppliedDescription()
                        -- Sadece kıyafet kopyala, yüz/saç vs değil
                        myDesc.Shirt = desc.Shirt
                        myDesc.Pants = desc.Pants
                        myDesc.GraphicTShirt = desc.GraphicTShirt
                        myHum:ApplyDescription(myDesc)
                    end
                end)
                return
            end
        end
    end

    -- Yoksa oyundan yükle (Shirt/Pants objelerini bul)
    for _, p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        if selTeam and p.Team==selTeam and p.Character then
            local shirt = p.Character:FindFirstChildOfClass("Shirt")
            local pants = p.Character:FindFirstChildOfClass("Pants")
            pcall(function()
                local myShirt = char:FindFirstChildOfClass("Shirt")
                local myPants = char:FindFirstChildOfClass("Pants")
                if shirt then
                    if myShirt then myShirt.ShirtTemplate=shirt.ShirtTemplate
                    else
                        local s=Instance.new("Shirt",char)
                        s.ShirtTemplate=shirt.ShirtTemplate
                    end
                end
                if pants then
                    if myPants then myPants.PantsTemplate=pants.PantsTemplate
                    else
                        local p2=Instance.new("Pants",char)
                        p2.PantsTemplate=pants.PantsTemplate
                    end
                end
            end)
            return
        end
    end
end

-- ═══════════════════════════════════════
-- TOOLS VER
-- Oyundaki tüm tool'ları bul ve ver
-- ═══════════════════════════════════════
local function giveTools(rankName)
    local bp = LP.Backpack if not bp then return end
    local char = LP.Character if not char then return end

    -- Zaten elimdeki tool'ları temizle
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") then t:Destroy() end
    end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then t.Parent = bp end
    end

    -- Oyunun ServerStorage / ReplicatedStorage / Tool klasörlerinden tool'ları bul
    local sources = {
        game:GetService("ReplicatedStorage"),
        workspace,
    }
    pcall(function()
        table.insert(sources, game:GetService("ServerStorage"))
    end)

    local toolsGiven = {}

    local function giveFromFolder(folder)
        for _, v in ipairs(folder:GetDescendants()) do
            if v:IsA("Tool") and not toolsGiven[v.Name] then
                -- Rütbeye göre filtrele (hepsini ver ya da rütbeye özel)
                local n = v.Name:lower()
                local rank = rankName:lower()

                -- Silahlar: herkese ver
                local isWeapon = n:match("gun") or n:match("rifle") or n:match("pistol")
                    or n:match("silah") or n:match("sniper") or n:match("mp5")
                    or n:match("ak") or n:match("m4") or n:match("weapon")

                -- Araçlar / Özel: sadece yetkililere
                local isSpecial = n:match("detain") or n:match("cuff") or n:match("arrest")
                    or n:match("taser") or n:match("baton")

                local isAdmin = rank:match("komutan") or rank:match("general")
                    or rank:match("paşa") or rank:match("inzibat")
                    or rank:match("özel kuvvet") or rank:match("albay")

                if isWeapon or (isSpecial and isAdmin) or isAdmin then
                    pcall(function()
                        local clone = v:Clone()
                        clone.Parent = bp
                        toolsGiven[v.Name] = true
                    end)
                end
            end
        end
    end

    for _, src in ipairs(sources) do
        pcall(function() giveFromFolder(src) end)
    end

    -- Elimindeki takımdaşların tool'larını kopyala
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LP and selTeam and p.Team==selTeam then
            pcall(function()
                local pBP = p:FindFirstChildOfClass("Backpack")
                if pBP then
                    for _, t in ipairs(pBP:GetChildren()) do
                        if t:IsA("Tool") and not toolsGiven[t.Name] then
                            t:Clone().Parent = bp
                            toolsGiven[t.Name] = true
                        end
                    end
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════
-- KAPI ERİŞİMİ
-- Proximity prompt ve dokunma kapılarını aç
-- ═══════════════════════════════════════
local function setupDoorAccess()
    -- Proximity prompt'ları otomatik tetikle (kapı açma)
    track(workspace.DescendantAdded:Connect(function(v)
        if v:IsA("ProximityPrompt") then
            pcall(function()
                local n=(v.ObjectText..v.ActionText):lower()
                if n:match("kap") or n:match("door") or n:match("open") or n:match("ac") or n:match("gir") then
                    -- Yakınımızda mı?
                    local char=LP.Character
                    local hrp=char and char:FindFirstChild("HumanoidRootPart")
                    local part=v.Parent
                    if hrp and part:IsA("BasePart") then
                        local dist=(hrp.Position-part.Position).Magnitude
                        if dist < 10 then
                            fireproximityprompt(v)
                        end
                    end
                end
            end)
        end
    end))

    -- Mevcut proximity prompt'ları da tara
    track(RunService.Heartbeat:Connect(function()
        local char=LP.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                pcall(function()
                    local n=(v.ObjectText..v.ActionText):lower()
                    if n:match("kap") or n:match("door") or n:match("open") or n:match("ac") or n:match("lock") then
                        local part=v.Parent
                        if part:IsA("BasePart") then
                            local dist=(hrp.Position-part.Position).Magnitude
                            if dist < 8 then
                                fireproximityprompt(v)
                            end
                        end
                    end
                end)
            end

            -- ClickDetector kapılar
            if v:IsA("ClickDetector") then
                pcall(function()
                    local part=v.Parent
                    if part:IsA("BasePart") then
                        local n=part.Name:lower()
                        if n:match("kap") or n:match("door") or n:match("gate") then
                            local dist=(hrp.Position-part.Position).Magnitude
                            if dist < 8 then
                                fireclickdetector(v)
                            end
                        end
                    end
                end)
            end
        end
    end))
end

-- ═══════════════════════════════════════
-- ARABA ERİŞİMİ
-- VehicleSeat'e otomatik otur
-- ═══════════════════════════════════════
local autoCarEnabled = false

track(RunService.Heartbeat:Connect(function()
    if not autoCarEnabled then return end
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") and not v.Occupant then
            local dist=(hrp.Position-v.Position).Magnitude
            if dist < 6 then
                pcall(function() v:Sit(char:FindFirstChildOfClass("Humanoid")) end)
                break
            end
        end
    end
end))

-- ═══════════════════════════════════════
-- ANA UYGULAMA FONKSİYONU
-- ═══════════════════════════════════════
local function applyRank(team)
    selTeam = team
    selTeamName = team.Name

    -- 1. Takım değiştir
    pcall(function() LP.Team = team end)

    -- 2. Remote'ları ateşle
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n=v.Name:lower()
            if n:match("team") or n:match("spawn") or n:match("class") or n:match("rank") then
                pcall(function() v:FireServer(team) end)
                pcall(function() v:FireServer(team.Name) end)
            end
        end
    end

    -- 3. Overhead tag
    setOverhead(LP.Character, team.Name)

    -- 4. Kıyafet
    task.spawn(function()
        task.wait(0.5)
        applyClothing(team.Name)
    end)

    -- 5. Tools
    task.spawn(function()
        task.wait(0.8)
        giveTools(team.Name)
    end)

    -- 6. Spawn'a ışınla
    task.spawn(function()
        task.wait(0.3)
        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, sp in ipairs(workspace:GetDescendants()) do
            if sp:IsA("SpawnLocation") and sp.TeamColor==team.TeamColor then
                hrp.CFrame=CFrame.new(sp.Position+Vector3.new(0,5,0))
                break
            end
        end
    end)
end

-- Respawn'da her şeyi koru
local function onCharAdded(char)
    if selTeamName == "" then return end
    task.wait(1.5)
    pcall(function() LP.Team = selTeam end)
    setOverhead(char, selTeamName)
    task.wait(0.5)
    applyClothing(selTeamName)
    task.wait(0.3)
    giveTools(selTeamName)
end
LP.CharacterAdded:Connect(onCharAdded)

-- Overhead tag'ı her zaman koru
track(RunService.Heartbeat:Connect(function()
    if selTeamName == "" then return end
    local char=LP.Character if not char then return end
    local head=char:FindFirstChild("Head") if not head then return end
    local tag=head:FindFirstChild("BTF_Tag")
    if not tag then
        setOverhead(char, selTeamName)
    end
end))

-- ═══════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name="BTF_FULL" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=1000
pcall(function()
    if gethui then gui.Parent=gethui()
    else gui.Parent=LP:WaitForChild("PlayerGui") end
end)

-- Toggle butonu
local tog = Instance.new("TextButton")
tog.Size=UDim2.new(0,70,0,70) tog.Position=UDim2.new(0,8,0.4,-35)
tog.BackgroundColor3=Color3.fromRGB(150,0,0) tog.BorderSizePixel=0
tog.Text="🪖\nRÜTBE" tog.TextColor3=Color3.new(1,1,1) tog.TextScaled=true
tog.Active=true tog.Draggable=true tog.Parent=gui
Instance.new("UICorner",tog).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",tog).Color=Color3.new(1,1,1)

-- Panel
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,240,0,540) panel.Position=UDim2.new(0,86,0.5,-270)
panel.BackgroundColor3=Color3.fromRGB(13,13,20) panel.BorderSizePixel=0
panel.Active=true panel.Draggable=true panel.Visible=false panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local pStr=Instance.new("UIStroke",panel) pStr.Color=Color3.fromRGB(150,0,0) pStr.Thickness=2

-- Başlık
local hdr=Instance.new("Frame")
hdr.Size=UDim2.new(1,0,0,42) hdr.BackgroundColor3=Color3.fromRGB(150,0,0)
hdr.BorderSizePixel=0 hdr.Parent=panel
Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,12)
local hdrL=Instance.new("TextLabel")
hdrL.Size=UDim2.new(1,-42,1,0) hdrL.BackgroundTransparency=1
hdrL.Text="🪖 RÜTBE & YETKİ PANELI" hdrL.TextColor3=Color3.new(1,1,1)
hdrL.TextSize=12 hdrL.Font=Enum.Font.GothamBold hdrL.Parent=hdr
local closeB=Instance.new("TextButton")
closeB.Size=UDim2.new(0,38,0,38) closeB.Position=UDim2.new(1,-40,0,2)
closeB.BackgroundColor3=Color3.fromRGB(100,0,0) closeB.BorderSizePixel=0
closeB.Text="✕" closeB.TextColor3=Color3.new(1,1,1) closeB.TextSize=15 closeB.Font=Enum.Font.GothamBold closeB.Parent=hdr
Instance.new("UICorner",closeB).CornerRadius=UDim.new(0,8)
closeB.MouseButton1Click:Connect(function() panel.Visible=false end)

-- Mevcut rütbe önizlemesi (Guest | RütbeAdı)
local previewF=Instance.new("Frame")
previewF.Size=UDim2.new(1,-12,0,52) previewF.Position=UDim2.new(0,6,0,48)
previewF.BackgroundColor3=Color3.fromRGB(20,20,30) previewF.BorderSizePixel=0 previewF.Parent=panel
Instance.new("UICorner",previewF).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",previewF).Color=Color3.fromRGB(50,50,70)

local prevTitle=Instance.new("TextLabel")
prevTitle.Size=UDim2.new(1,0,0.4,0) prevTitle.BackgroundTransparency=1
prevTitle.Text="Üst Yazı:" prevTitle.TextColor3=Color3.fromRGB(100,100,120)
prevTitle.TextSize=10 prevTitle.Font=Enum.Font.Gotham prevTitle.Parent=previewF

local prevGuest=Instance.new("TextLabel")
prevGuest.Size=UDim2.new(0.5,0,0.5,0) prevGuest.Position=UDim2.new(0,8,0.4,0)
prevGuest.BackgroundTransparency=1 prevGuest.Text="Guest"
prevGuest.TextColor3=Color3.fromRGB(220,220,220) prevGuest.TextSize=12
prevGuest.Font=Enum.Font.GothamBold prevGuest.TextXAlignment=Enum.TextXAlignment.Left prevGuest.Parent=previewF

local prevRank=Instance.new("TextLabel")
prevRank.Size=UDim2.new(1,-8,0.5,0) prevRank.Position=UDim2.new(0,8,0.5,0)
prevRank.BackgroundTransparency=1 prevRank.Text="— seçilmedi —"
prevRank.TextColor3=Color3.fromRGB(150,150,170) prevRank.TextSize=12
prevRank.Font=Enum.Font.GothamBold prevRank.TextXAlignment=Enum.TextXAlignment.Left prevRank.Parent=previewF

-- Hızlı togglelar (araba + tools)
local quickF=Instance.new("Frame")
quickF.Size=UDim2.new(1,-12,0,36) quickF.Position=UDim2.new(0,6,0,106)
quickF.BackgroundTransparency=1 quickF.Parent=panel
local qLayout=Instance.new("UIListLayout",quickF)
qLayout.FillDirection=Enum.FillDirection.Horizontal qLayout.Padding=UDim.new(0,4)

local function mkQuick(txt, onClick)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,0,1,0) b.AutomaticSize=Enum.AutomaticSize.X
    b.BackgroundColor3=Color3.fromRGB(30,30,45) b.BorderSizePixel=0
    b.Text=txt b.TextColor3=Color3.new(1,1,1) b.TextSize=11 b.Font=Enum.Font.GothamBold
    b.Parent=quickF
    local p=Instance.new("UIPadding",b) p.PaddingLeft=UDim.new(0,8) p.PaddingRight=UDim.new(0,8)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(onClick) return b
end

local carBtn=mkQuick("🚗 Araba OFF",function()
    autoCarEnabled=not autoCarEnabled
    carBtn.Text="🚗 Araba "..(autoCarEnabled and "ON" or "OFF")
    carBtn.BackgroundColor3=autoCarEnabled and Color3.fromRGB(0,100,50) or Color3.fromRGB(30,30,45)
end)

mkQuick("🛠 Tool Ver",function()
    if selTeamName~="" then
        giveTools(selTeamName)
    end
end)

mkQuick("👕 Kıyafet",function()
    if selTeamName~="" then
        applyClothing(selTeamName)
    end
end)

-- Arama kutusu
local srchF=Instance.new("Frame")
srchF.Size=UDim2.new(1,-12,0,30) srchF.Position=UDim2.new(0,6,0,148)
srchF.BackgroundColor3=Color3.fromRGB(24,24,36) srchF.BorderSizePixel=0 srchF.Parent=panel
Instance.new("UICorner",srchF).CornerRadius=UDim.new(0,8)
local srchBox=Instance.new("TextBox")
srchBox.Size=UDim2.new(1,-8,1,0) srchBox.Position=UDim2.new(0,4,0,0)
srchBox.BackgroundTransparency=1 srchBox.PlaceholderText="🔍 Rütbe ara..."
srchBox.PlaceholderColor3=Color3.fromRGB(80,80,100)
srchBox.Text="" srchBox.TextColor3=Color3.new(1,1,1)
srchBox.TextSize=11 srchBox.Font=Enum.Font.Gotham srchBox.ClearTextOnFocus=false srchBox.Parent=srchF

-- Scroll listesi
local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,-12,1,-220) scroll.Position=UDim2.new(0,6,0,184)
scroll.BackgroundColor3=Color3.fromRGB(16,16,24) scroll.BorderSizePixel=0
scroll.ScrollBarThickness=4 scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0) scroll.Parent=panel
Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,8)
local lL=Instance.new("UIListLayout",scroll) lL.Padding=UDim.new(0,3)
local lP=Instance.new("UIPadding",scroll)
lP.PaddingTop=UDim.new(0,4) lP.PaddingLeft=UDim.new(0,4) lP.PaddingRight=UDim.new(0,4)

-- Durum
local statL=Instance.new("TextLabel")
statL.Size=UDim2.new(1,-12,0,22) statL.Position=UDim2.new(0,6,1,-28)
statL.BackgroundTransparency=1 statL.Text="Rütbe seç →"
statL.TextColor3=Color3.fromRGB(100,100,120) statL.TextSize=10
statL.Font=Enum.Font.Gotham statL.TextXAlignment=Enum.TextXAlignment.Left statL.Parent=panel

-- ═══════════════════════════════════════
-- TAKIM LİSTESİ
-- ═══════════════════════════════════════
local teamBtns={}

local function getIcon(name)
    local n=name:lower()
    if n:match("sivil") then return "👔" end
    if n:match("inzibat") then return "🚔" end
    if n:match("özel kuvvet") or n:match("ozel kuvvet") or n:match("ökk") then return "⚡" end
    if n:match("komutan") then return "🎖" end
    if n:match("general") or n:match("paşa") then return "⭐" end
    if n:match("albay") then return "🦅" end
    if n:match("yarbay") then return "🔰" end
    if n:match("binbaşı") or n:match("binbasi") then return "💠" end
    if n:match("yüzbaşı") or n:match("yuzbasi") then return "🔷" end
    if n:match("üsteğmen") or n:match("ustegmen") then return "🔹" end
    if n:match("teğmen") or n:match("tegmen") then return "▪" end
    if n:match("çavuş") or n:match("cavus") then return "🔺" end
    if n:match("onbaşı") or n:match("onbasi") then return "▫" end
    if n:match("er") or n:match("asker") then return "🪖" end
    if n:match("pilot") then return "✈" end
    if n:match("deniz") then return "⚓" end
    return "🔫"
end

local function buildList(filter)
    for _,b in ipairs(teamBtns) do if b and b.Parent then b:Destroy() end end
    teamBtns={}

    local allTeams=Teams:GetTeams()
    table.sort(allTeams,function(a,b2) return a.Name<b2.Name end)

    for _,team in ipairs(allTeams) do
        local name=team.Name
        if filter and filter~="" and not name:lower():find(filter:lower()) then continue end

        local rankColor=getRankColor(name)
        local isActive=(selTeam==team)

        -- Satır frame
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,52) row.BackgroundColor3=Color3.fromRGB(22,22,34)
        row.BorderSizePixel=0 row.Parent=scroll
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        if isActive then
            local str=Instance.new("UIStroke",row) str.Color=Color3.fromRGB(0,200,80) str.Thickness=1.5
        end

        -- Sol renk çizgisi
        local bar=Instance.new("Frame")
        bar.Size=UDim2.new(0,4,1,0) bar.BackgroundColor3=rankColor
        bar.BorderSizePixel=0 bar.Parent=row
        Instance.new("UICorner",bar).CornerRadius=UDim.new(0,4)

        -- Üst: Guest (beyaz küçük)
        local guestL=Instance.new("TextLabel")
        guestL.Size=UDim2.new(1,-20,0.45,0) guestL.Position=UDim2.new(0,12,0,2)
        guestL.BackgroundTransparency=1 guestL.Text="Guest"
        guestL.TextColor3=Color3.fromRGB(180,180,200) guestL.TextSize=10
        guestL.Font=Enum.Font.Gotham guestL.TextXAlignment=Enum.TextXAlignment.Left guestL.Parent=row

        -- Alt: Rütbe adı (rütbe rengi)
        local rankL=Instance.new("TextLabel")
        rankL.Size=UDim2.new(1,-20,0.5,0) rankL.Position=UDim2.new(0,12,0.45,0)
        rankL.BackgroundTransparency=1
        rankL.Text=(isActive and "✅ " or getIcon(name).." ")..name
        rankL.TextColor3=isActive and Color3.fromRGB(100,255,100) or rankColor
        rankL.TextSize=12 rankL.Font=Enum.Font.GothamBold
        rankL.TextXAlignment=Enum.TextXAlignment.Left rankL.Parent=row

        -- Tıkla butonu
        local clickB=Instance.new("TextButton")
        clickB.Size=UDim2.new(1,0,1,0) clickB.BackgroundTransparency=1
        clickB.Text="" clickB.Parent=row

        clickB.MouseButton1Click:Connect(function()
            prevRank.Text=name prevRank.TextColor3=rankColor

            statL.Text="⏳ "..name.." uygulanıyor..."
            statL.TextColor3=Color3.fromRGB(255,200,0)

            task.spawn(function()
                applyRank(team)
                task.wait(1)
                local ok=(LP.Team==team)
                if ok then
                    statL.Text="✅ "..name.." — kıyafet + tool + tag uygulandı"
                    statL.TextColor3=Color3.fromRGB(100,255,100)
                else
                    statL.Text="⚠ Denendi — reset at ya da spawn'a git"
                    statL.TextColor3=Color3.fromRGB(255,180,0)
                end
                buildList(srchBox.Text)
            end)
        end)

        table.insert(teamBtns,row)
    end

    if #teamBtns==0 then
        local empty=Instance.new("TextLabel")
        empty.Size=UDim2.new(1,0,0,36) empty.BackgroundTransparency=1
        empty.Text="⚠ Oyunda takım bulunamadı"
        empty.TextColor3=Color3.fromRGB(150,150,150) empty.TextSize=11 empty.Font=Enum.Font.Gotham
        empty.Parent=scroll table.insert(teamBtns,empty)
    end
end

-- ═══════════════════════════════════════
-- OLAYLAR
-- ═══════════════════════════════════════
tog.MouseButton1Click:Connect(function()
    panel.Visible=not panel.Visible
    if panel.Visible then buildList("") end
end)
srchBox:GetPropertyChangedSignal("Text"):Connect(function() buildList(srchBox.Text) end)
track(LP:GetPropertyChangedSignal("Team"):Connect(function()
    if panel.Visible then buildList(srchBox.Text) end
end))

-- Kapı erişimi başlat
setupDoorAccess()

-- Cleanup
getgenv().BTF_FULL_Cleanup=function()
    for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end

buildList("")
warn("✅ BTF Tam Paket yüklendi — 🪖 RÜTBE butonuna bas")