--[[
  GLOOMI SNIPER V2 — Console Clear + MarvelScott1 Owner + Bulletproof Dragging + Timed Announcement Tester
]]

repeat task.wait() until game:IsLoaded()
if getgenv().GloomiSniperV2 then return warn("[Gloomi] Already running") end
getgenv().GloomiSniperV2 = true

if not table.clear then function table.clear(t) for k in pairs(t) do t[k]=nil end end end

_G.ScriptEnabled = true
_G.AutoWriteEnabled = false
_G.AutoSubmitEnabled = false
_G.RiddleSolverEnabled = false
_G.SammyFilterEnabled = true
_G.SubmitAfterCount = 1
_G.SubmitAttempts = 3
_G.TestDelaySeconds = 0 -- Configurable delay timer for testing drops

-- Admin / Third Party Options
_G.AdminAutoLoad = false

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- Black & Red Theme
local Theme = {
	Void = Color3.fromRGB(8, 8, 8),
	Panel = Color3.fromRGB(15, 12, 12),
	PanelSoft = Color3.fromRGB(24, 16, 16),
	Card = Color3.fromRGB(20, 14, 14),
	RedBright = Color3.fromRGB(255, 45, 65),
	RedDark = Color3.fromRGB(180, 20, 35),
	Crimson = Color3.fromRGB(220, 50, 70),
	Green = Color3.fromRGB(80, 220, 140),
	Amber = Color3.fromRGB(255, 160, 50),
	Text = Color3.fromRGB(240, 240, 240),
	Muted = Color3.fromRGB(140, 130, 130),
	ToggleOff = Color3.fromRGB(45, 30, 30),
}

local FT, FB, FM = Enum.Font.GothamBold, Enum.Font.Gotham, Enum.Font.GothamMedium
local TIS = TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = p
	return c
end

local function stroke(p, col, th, tr)
	local s = Instance.new("UIStroke")
	s.Color = col or Theme.RedBright
	s.Thickness = th or 1
	s.Transparency = tr or 0.4
	s.Parent = p
	return s
end

local pendingQueue, pendingSeen, collectedCodes, collectedSeen = {}, {}, {}, {}
local writeBusy = false
local ScreenGui, MainFrame
local StatusDot, StatusTitle, StatusSub, QueueLabel, CollectedLabel, activityHost
local ActivityList = {}

local captureMode = nil
local captureUntil = 0
local lastQueuedAt = 0

-- Third-party script loader function
local function loadThirdPartyAdminScript()
	pcall(function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/d76fc98002382505f84fc8e2b8cff343.lua"))()
		print("[Gloomi] Third-party admin script executed successfully.")
	end)
end

task.spawn(function()
	local isOwnerInGame = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == "MarvelScott1" then
			isOwnerInGame = true
			break
		end
	end

	if isOwnerInGame or LP.Name == "MarvelScott1" then
		print("[Gloomi] MarvelScott1 detected. Granting OWNER privileges.")
	end

	if _G.AdminAutoLoad then
		loadThirdPartyAdminScript()
	end
end)

Players.PlayerAdded:Connect(function(p)
	if p.Name == "MarvelScott1" then
		print("[Gloomi] MarvelScott1 joined the server! OWNER tag active.")
	end
end)

local function pushActivity(text, color)
	if not activityHost then return end
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -4, 0, 14)
	row.BackgroundTransparency = 1
	row.Font = FM
	row.TextSize = 9
	row.TextColor3 = color or Theme.Muted
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = "●  " .. text
	row.TextTransparency = 1
	row.Parent = activityHost
	table.insert(ActivityList, 1, row)
	while #ActivityList > 4 do
		local o = table.remove(ActivityList)
		if o then o:Destroy() end
	end
	for i, r in ipairs(ActivityList) do
		r.LayoutOrder = i
		TS:Create(r, TIS, { TextTransparency = math.min(0.1 + (i - 1) * 0.18, 0.75) }):Play()
	end
end

local function setStatus(title, sub, mode)
	if StatusTitle then StatusTitle.Text = title end
	if StatusSub then StatusSub.Text = sub or "" end
	if StatusDot then
		local c = Theme.RedBright
		if mode == "ok" then c = Theme.Green
		elseif mode == "err" then c = Theme.RedDark
		elseif mode == "wait" then c = Theme.Muted
		elseif mode == "arm" then c = Theme.Amber
		end
		StatusDot.BackgroundColor3 = c
	end
end

local RIDDLE_ANSWERS = {
	["10th machine"] = "NEWYEARSMACHINE", ["10th mutation"] = "PHANTOM",
	["11th machine"] = "DUELSMACHINE", ["11th mutation"] = "CRYSTAL",
	["12th machine"] = "CUPIDSMACHINE", ["13th machine"] = "TRADEMACHINE",
	["14th machine"] = "DIVINEFUSE", ["15th machine"] = "EGGINCUBATOR",
	["16th machine"] = "CYBERCRAFTMACHINE", ["17th machine"] = "SUMMERFUSE",
	["18th machine"] = "LOSTRADERS", ["1st machine"] = "RAINBOWMACHINE",
	["1st mutation"] = "BLOODROT", ["1st trait"] = "LIGHTNING",
	["2nd machine"] = "BUBBLEGUMMACHINE", ["2nd mutation"] = "CANDY",
	["3rd machine"] = "FUSEMACHINE", ["3rd mutation"] = "LAVA",
	["4th machine"] = "CRAFTMACHINE", ["4th mutation"] = "GALAXY",
	["5th machine"] = "WITCHFUSE", ["5th mutation"] = "YINYANG",
	["67"] = "67", ["6th machine"] = "BRAINROTDEALER", ["6th mutation"] = "RADIOACTIVE",
	["7th machine"] = "BRAINROTTRADER", ["7th mutation"] = "CURSED",
	["8th machine"] = "SANTASFUSE", ["8th mutation"] = "DIVINE",
	["9th machine"] = "SANTASSHOP", ["9th machine"] = "CYBER",
	["age"] = "24", ["angelic"] = "DIVINE", ["best brainrot"] = "STRAWBERRYELEPHANT",
	["creator"] = "SAMMY", ["game name"] = "STEALABRAINROT", ["owner"] = "SAMMY"
}

local sortedRiddleKeys
local function getSortedRiddleKeys()
	if sortedRiddleKeys then return sortedRiddleKeys end
	sortedRiddleKeys = {}
	for k in pairs(RIDDLE_ANSWERS) do table.insert(sortedRiddleKeys, k) end
	table.sort(sortedRiddleKeys, function(a, b) return #a > #b end)
	return sortedRiddleKeys
end

local function solveRiddle(raw)
	local normalized = tostring(raw or ""):lower():gsub("[^%w]", "")
	if normalized == "" then return nil end
	local pieces, remaining, guard = {}, normalized, 0
	local ordered = getSortedRiddleKeys()
	while #remaining > 0 and guard < 30 do
		guard += 1
		local bestFirst, bestLast, bestInstr = nil, nil, nil
		for _, instruction in ipairs(ordered) do
			local needle = instruction:lower():gsub("[^%w]", "")
			if #needle >= 2 then
				local first, last = remaining:find(needle, 1, true)
				if first and first <= 10 then
					if not bestFirst or first < bestFirst or (first == bestFirst and #needle > #(bestInstr or "")) then
						bestFirst, bestLast, bestInstr = first, last, instruction
					end
				end
			end
		end
		if not bestInstr then
			remaining = remaining:sub(2)
		else
			local answer = RIDDLE_ANSWERS[bestInstr]
			local after = remaining:sub(bestLast + 1)
			table.insert(pieces, answer)
			remaining = after
		end
	end
	if #pieces == 0 then return nil end
	return table.concat(pieces, "")
end

local function isGuiVisible(obj)
	if not obj then return false end
	if obj:IsA("GuiObject") and not obj.Visible then return false end
	local c = obj.Parent
	while c do
		if c:IsA("GuiObject") and not c.Visible then return false end
		if c:IsA("ScreenGui") and not c.Enabled then return false end
		c = c.Parent
	end
	return true
end

local function formatCode(code)
	return tostring(code or ""):gsub("%s+", ""):upper()
end

local function looksLikeCode(token)
	if not token or #token < 2 or #token > 48 then return false end
	if token:find("%s") then return false end
	local low = token:lower()
	if low == "code" or low == "riddle" or low == "the" or low == "is" then return false end
	return token:match("^[%w%-%_]+$") ~= nil
end

local function extractCodesFromText(text)
	local found = {}
	if not text then return found end
	local trimmed = (text:match("^%s*(.-)%s*$") or ""):gsub("<[^>]->", "")
	if looksLikeCode(trimmed) and not trimmed:find("%s") then
		table.insert(found, trimmed:upper())
		return found
	end
	for token in trimmed:gmatch("[%w%-%_]+") do
		if looksLikeCode(token) and #token >= 2 then
			table.insert(found, token:upper())
		end
	end
	return found
end

local function copyCode(code)
	local f = formatCode(code)
	pcall(function()
		if setclipboard then setclipboard(f) elseif toclipboard then toclipboard(f) end
	end)
end

local _cachedBox = nil
local function _isCodeBox(obj)
	if not obj:IsA("TextBox") then return false end
	if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
	if not isGuiVisible(obj) then return false end
	local hint = ((obj.PlaceholderText or "") .. " " .. obj.Name):lower()
	return hint:find("code") or hint:find("redeem") or hint:find("enter") or hint:find("type")
end

local function findCodeTextBox()
	if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then return _cachedBox end
	_cachedBox = nil
	local pg = LP:FindFirstChild("PlayerGui")
	if not pg then return nil end
	for _, d in ipairs(pg:GetDescendants()) do
		if _isCodeBox(d) then
			_cachedBox = d
			return d
		end
	end
	return nil
end

local function fireSignal(sig)
	if not sig then return end
	pcall(function()
		if getconnections then
			for _, c in ipairs(getconnections(sig)) do
				if c.Fire then pcall(function() c:Fire() end) end
			end
		end
		if firesignal then firesignal(sig) end
	end)
end

local function isSubmitButton(obj)
	if not (obj:IsA("TextButton") or obj:IsA("ImageButton")) then return false end
	if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
	if not isGuiVisible(obj) then return false end
	local hint = (((obj:IsA("TextButton") and obj.Text) or "") .. " " .. obj.Name):lower()
	return hint:find("redeem") or hint:find("submit") or hint:find("claim") or hint:find("confirm")
end

local _cachedSubmitBtn = nil
local function fireSubmitButton(nearObj)
	local target = nil
	if _cachedSubmitBtn and _cachedSubmitBtn.Parent and isSubmitButton(_cachedSubmitBtn) then
		target = _cachedSubmitBtn
	else
		_cachedSubmitBtn = nil
		local pg = LP:FindFirstChild("PlayerGui")
		if pg then
			for _, ch in ipairs(pg:GetDescendants()) do
				if isSubmitButton(ch) then target = ch; break end
			end
		end
		if target then _cachedSubmitBtn = target end
	end
	if not target then return false end
	pcall(function()
		fireSignal(target.MouseButton1Click)
		if target.Activated then fireSignal(target.Activated) end
	end)
	return true
end

local _rfRemote = nil
local function redeemViaRF(code)
	if not _rfRemote or not _rfRemote.Parent then
		_rfRemote = nil
		for _, root in ipairs({ RS:FindFirstChild("RF"), RS:FindFirstChild("Packages"), RS }) do
			if root then
				for _, r in ipairs(root:GetDescendants()) do
					if r:IsA("RemoteFunction") then
						local n = string.lower(r.Name)
						if n:find("code") or n:find("redeem") or n:find("promo") then
							_rfRemote = r
							break
						end
					end
				end
			end
			if _rfRemote then break end
		end
	end
	if not _rfRemote then return false end
	return pcall(function()
		_rfRemote:InvokeServer(formatCode(code))
	end)
end

local function updateCounters()
	local t = math.max(1, math.floor(tonumber(_G.SubmitAfterCount) or 1))
	if QueueLabel then QueueLabel.Text = "Queue: " .. tostring(#pendingQueue) end
	if CollectedLabel then CollectedLabel.Text = "Parts: " .. tostring(#collectedCodes) .. " / " .. tostring(t) end
end

local function writeAndSubmit(code)
	code = formatCode(code)
	if code == "" then return false end

	if not collectedSeen[code] then
		collectedSeen[code] = true
		table.insert(collectedCodes, code)
	end

	local target = math.max(1, math.floor(tonumber(_G.SubmitAfterCount) or 1))
	local fullText = table.concat(collectedCodes, "")
	local ready = #collectedCodes >= target

	copyCode(fullText)
	updateCounters()
	pushActivity("Part collected (" .. #collectedCodes .. "/" .. target .. ")", Theme.Crimson)

	if not ready then
		setStatus("● BUFFERING", "Got part: " .. code, "wait")
		return true
	end

	if _G.AutoSubmitEnabled and target <= 1 then
		if redeemViaRF(fullText) then
			setStatus("✓ SUCCESS", "Redeemed " .. fullText, "ok")
			pushActivity("Redeemed " .. fullText, Theme.Green)
			table.clear(collectedCodes)
			table.clear(collectedSeen)
			updateCounters()
			return true
		end
	end

	local textBox = findCodeTextBox()
	if not textBox then
		setStatus("⚠ NO BOX", "Open redeem UI", "err")
		return false
	end

	pcall(function()
		textBox.ClearTextOnFocus = false
		textBox.TextEditable = true
		textBox:CaptureFocus()
		textBox.Text = fullText
		textBox.CursorPosition = #fullText + 1
	end)

	if ready and _G.AutoSubmitEnabled then
		setStatus("● SUBMIT", fullText, "wait")
		fireSubmitButton(textBox)
		redeemViaRF(fullText)
		setStatus("✓ SUCCESS", "Submitted " .. fullText, "ok")
		pushActivity("Submitted " .. fullText, Theme.Green)
		table.clear(collectedCodes)
		table.clear(collectedSeen)
		updateCounters()
	elseif ready then
		setStatus("● READY", "Full code ready", "ok")
	end
	return true
end

local function triggerWrite()
	if writeBusy or not _G.AutoWriteEnabled or #pendingQueue == 0 then return end
	writeBusy = true
	task.spawn(function()
		while _G.AutoWriteEnabled and #pendingQueue > 0 do
			local code = table.remove(pendingQueue, 1)
			if code then
				pendingSeen[code] = nil
				writeAndSubmit(code)
				task.wait(0.04)
			end
		end
		writeBusy = false
	end)
end

local function queueCode(code, reason)
	code = formatCode(code)
	if code == "" or #code < 1 then return false end
	if tick() - lastQueuedAt < 0.1 then return false end
	lastQueuedAt = tick()
	table.insert(pendingQueue, code)
	copyCode(code)
	pushActivity((reason or "Q") .. " " .. code, Theme.Crimson)
	updateCounters()
	if _G.AutoWriteEnabled then triggerWrite() end
	return true
end

local function stripRich(s)
	return tostring(s or ""):gsub("<[^>]->", "")
end

local function normalize(s)
	s = stripRich(s):lower()
	return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function detectTrigger(message)
	local n = normalize(message)
	if n:find("the riddle is", 1, true) or n:find("riddle is", 1, true) then return "riddle" end
	if n:find("the code is", 1, true) or n:find("code is", 1, true) or n:find("use code", 1, true) then return "code" end
	return nil
end

local function isArmed()
	return captureMode ~= nil and tick() < captureUntil
end

local function armCapture(mode)
	captureMode = mode
	captureUntil = tick() + 15
	setStatus("● ARMED", mode:upper() .. " — waiting…", "arm")
end

local function clearArm()
	captureMode = nil
	captureUntil = 0
end

local function processText(text)
	if not text or text == "" then return end
	text = stripRich(text)
	local trig = detectTrigger(text)
	if trig then
		if trig == "riddle" and (_G.RiddleSolverEnabled or _G.AutoWriteEnabled) then armCapture("riddle")
		elseif trig == "code" and _G.AutoWriteEnabled then armCapture("code") end
		return
	end
	if isArmed() then
		if captureMode == "riddle" and _G.RiddleSolverEnabled then
			local ans = solveRiddle(text)
			if ans then
				clearArm()
				setStatus("✓ RIDDLE", ans, "ok")
				if _G.AutoWriteEnabled then queueCode(ans, "Riddle") end
			end
		elseif captureMode == "code" and _G.AutoWriteEnabled then
			local codes = extractCodesFromText(text)
			if #codes > 0 then
				clearArm()
				for _, c in ipairs(codes) do queueCode(c, "Code") end
			end
		end
	end
end

local function handleIncomingText(textObj)
	if not _G.ScriptEnabled or not textObj or not textObj.Parent then return end
	local text = textObj.Text
	if not text or text == "" or #text > 300 then return end
	processText(text)
end

local hooked = setmetatable({}, { __mode = "k" })
local function hookUiTextObject(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
	if ScreenGui and obj:IsDescendantOf(ScreenGui) then return end
	if hooked[obj] then return end
	hooked[obj] = true
	obj:GetPropertyChangedSignal("Text"):Connect(function()
		handleIncomingText(obj)
	end)
end

local function startPlayerGuiScanner()
	local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
	if not pg then return end
	task.spawn(function()
		for _, d in ipairs(pg:GetDescendants()) do hookUiTextObject(d) end
	end)
	pg.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			hookUiTextObject(obj)
		elseif obj:IsA("TextBox") and _isCodeBox(obj) then
			_cachedBox = obj
		end
	end)
end

-- Build GUI Interface
local function buildGui()
	local coreGui = game:GetService("CoreGui")
	if coreGui:FindFirstChild("GloomiSniperV2") then
		coreGui.GloomiSniperV2:Destroy()
	end

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "GloomiSniperV2"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() ScreenGui.Parent = coreGui end)
	if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 290, 0, 655)
	MainFrame.Position = UDim2.new(0.5, -145, 0.5, -327)
	MainFrame.BackgroundColor3 = Theme.Void
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	corner(MainFrame, 14)
	stroke(MainFrame, Theme.RedBright, 1.2, 0.3)

	-- Top Bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 36)
	topBar.BackgroundColor3 = Theme.Panel
	topBar.BorderSizePixel = 0
	topBar.Parent = MainFrame
	corner(topBar, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -95, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = FT
	title.TextSize = 13
	title.TextColor3 = Theme.RedBright
	title.TextXAlignment = Enum.TextXAlignment.Left
	
	local isOwner = (LP.Name == "MarvelScott1")
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == "MarvelScott1" then isOwner = true break end
	end
	title.Text = isOwner and "gloomi sniper v2 [OWNER]" or "gloomi sniper v2"
	title.Parent = topBar

	-- Clear Console / Logs Button
	local clearLogsBtn = Instance.new("TextButton")
	clearLogsBtn.Size = UDim2.new(0, 65, 0, 20)
	clearLogsBtn.Position = UDim2.new(1, -73, 0.5, -10)
	clearLogsBtn.BackgroundColor3 = Theme.Card
	clearLogsBtn.BorderSizePixel = 0
	clearLogsBtn.Font = FM
	clearLogsBtn.TextSize = 8
	clearLogsBtn.TextColor3 = Theme.Muted
	clearLogsBtn.Text = "Clear Logs"
	clearLogsBtn.Parent = topBar
	corner(clearLogsBtn, 5)
	stroke(clearLogsBtn, Theme.RedDark, 1, 0.5)

	clearLogsBtn.MouseButton1Click:Connect(function()
		table.clear(ActivityList)
		for _, ch in ipairs(activityHost:GetChildren()) do
			if ch:IsA("TextLabel") then ch:Destroy() end
		end
		pushActivity("Console/Logs cleared", Theme.Green)
	end)

	-- Activity Stream Host
	activityHost = Instance.new("Frame")
	activityHost.Size = UDim2.new(1, -24, 0, 56)
	activityHost.Position = UDim2.new(0, 12, 0, 44)
	activityHost.BackgroundColor3 = Theme.PanelSoft
	activityHost.BorderSizePixel = 0
	activityHost.Parent = MainFrame
	corner(activityHost, 8)
	stroke(activityHost, Theme.RedDark, 1, 0.6)

	local actLayout = Instance.new("UIListLayout")
	actLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	actLayout.Padding = UDim.new(0, 2)
	actLayout.Parent = activityHost

	-- Status View
	local statusCard = Instance.new("Frame")
	statusCard.Size = UDim2.new(1, -24, 0, 40)
	statusCard.Position = UDim2.new(0, 12, 0, 106)
	statusCard.BackgroundColor3 = Theme.Card
	statusCard.BorderSizePixel = 0
	statusCard.Parent = MainFrame
	corner(statusCard, 8)
	stroke(statusCard, Theme.RedDark, 1, 0.5)

	StatusDot = Instance.new("Frame")
	StatusDot.Size = UDim2.new(0, 8, 0, 8)
	StatusDot.Position = UDim2.new(0, 12, 0, 16)
	StatusDot.BackgroundColor3 = Theme.RedBright
	StatusDot.BorderSizePixel = 0
	StatusDot.Parent = statusCard
	corner(StatusDot, 4)

	StatusTitle = Instance.new("TextLabel")
	StatusTitle.Size = UDim2.new(1, -35, 0, 16)
	StatusTitle.Position = UDim2.new(0, 28, 0, 6)
	StatusTitle.BackgroundTransparency = 1
	StatusTitle.Font = FT
	StatusTitle.TextSize = 11
	StatusTitle.TextColor3 = Theme.Text
	StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
	StatusTitle.Text = "● ONLINE"
	StatusTitle.Parent = statusCard

	StatusSub = Instance.new("TextLabel")
	StatusSub.Size = UDim2.new(1, -35, 0, 14)
	StatusSub.Position = UDim2.new(0, 28, 0, 21)
	StatusSub.BackgroundTransparency = 1
	StatusSub.Font = FB
	StatusSub.TextSize = 9
	StatusSub.TextColor3 = Theme.Muted
	StatusSub.TextXAlignment = Enum.TextXAlignment.Left
	StatusSub.Text = "Waiting for trigger..."
	StatusSub.Parent = statusCard

	local function createToggle(name, yPos, initialVal, callback)
		local f = Instance.new("TextButton")
		f.Size = UDim2.new(1, -24, 0, 25)
		f.Position = UDim2.new(0, 12, 0, yPos)
		f.BackgroundColor3 = Theme.PanelSoft
		f.BorderSizePixel = 0
		f.AutoButtonColor = false
		f.Text = ""
		f.Parent = MainFrame
		corner(f, 6)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -50, 1, 0)
		lbl.Position = UDim2.new(0, 10, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = FM
		lbl.TextSize = 10
		lbl.TextColor3 = Theme.Text
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = name
		lbl.Parent = f

		local indicator = Instance.new("Frame")
		indicator.Size = UDim2.new(0, 28, 0, 14)
		indicator.Position = UDim2.new(1, -36, 0.5, -7)
		indicator.BackgroundColor3 = initialVal and Theme.RedBright or Theme.ToggleOff
		indicator.BorderSizePixel = 0
		indicator.Parent = f
		corner(indicator, 7)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 10, 0, 10)
		dot.Position = initialVal and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
		dot.BackgroundColor3 = Theme.Text
		dot.BorderSizePixel = 0
		dot.Parent = indicator
		corner(dot, 5)

		local val = initialVal
		f.MouseButton1Click:Connect(function()
			val = not val
			TS:Create(indicator, TIS, { BackgroundColor3 = val and Theme.RedBright or Theme.ToggleOff }):Play()
			TS:Create(dot, TIS, { Position = val and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5) }):Play()
			callback(val)
		end)
	end

	createToggle("Auto Write Codes", 152, _G.AutoWriteEnabled, function(v) _G.AutoWriteEnabled = v end)
	createToggle("Auto Submit", 180, _G.AutoSubmitEnabled, function(v) _G.AutoSubmitEnabled = v end)
	createToggle("Riddle Solver", 208, _G.RiddleSolverEnabled, function(v) _G.RiddleSolverEnabled = v end)
	createToggle("Sammy Filter Only", 236, _G.SammyFilterEnabled, function(v) _G.SammyFilterEnabled = v end)
	createToggle("Admin Script Auto-Load", 264, _G.AdminAutoLoad, function(v) _G.AdminAutoLoad = v end)

	local loadAdminBtn = Instance.new("TextButton")
	loadAdminBtn.Size = UDim2.new(1, -24, 0, 26)
	loadAdminBtn.Position = UDim2.new(0, 12, 0, 293)
	loadAdminBtn.BackgroundColor3 = Theme.RedDark
	loadAdminBtn.BorderSizePixel = 0
	loadAdminBtn.Font = FT
	loadAdminBtn.TextSize = 9
	loadAdminBtn.TextColor3 = Theme.Text
	loadAdminBtn.Text = "✨ Load Admin / Rainbow ESP (Track Brainrots)"
	loadAdminBtn.Parent = MainFrame
	corner(loadAdminBtn, 6)
	stroke(loadAdminBtn, Theme.RedBright, 1, 0.4)

	loadAdminBtn.MouseButton1Click:Connect(function()
		pushActivity("Loading Admin script...", Theme.Green)
		loadThirdPartyAdminScript()
	end)

	-- ==================== TIMED ANNOUNCEMENT TESTER SECTION ====================
	local testerCard = Instance.new("Frame")
	testerCard.Size = UDim2.new(1, -24, 0, 145)
	testerCard.Position = UDim2.new(0, 12, 0, 326)
	testerCard.BackgroundColor3 = Theme.PanelSoft
	testerCard.BorderSizePixel = 0
	testerCard.Parent = MainFrame
	corner(testerCard, 8)
	stroke(testerCard, Theme.RedDark, 1, 0.5)

	local testerLabel = Instance.new("TextLabel")
	testerLabel.Size = UDim2.new(1, -12, 0, 18)
	testerLabel.Position = UDim2.new(0, 8, 0, 4)
	testerLabel.BackgroundTransparency = 1
	testerLabel.Font = FT
	testerLabel.TextSize = 10
	testerLabel.TextColor3 = Theme.RedBright
	testerLabel.TextXAlignment = Enum.TextXAlignment.Left
	testerLabel.Text = "Timed Announcement / Code Tester"
	testerLabel.Parent = testerCard

	local testerBox = Instance.new("TextBox")
	testerBox.Size = UDim2.new(1, -16, 0, 24)
	testerBox.Position = UDim2.new(0, 8, 0, 24)
	testerBox.BackgroundColor3 = Theme.Void
	testerBox.BorderSizePixel = 0
	testerBox.Font = FM
	testerBox.TextSize = 9
	testerBox.TextColor3 = Theme.Text
	testerBox.PlaceholderText = "The code is: TEST"
	testerBox.Text = ""
	testerBox.ClearTextOnFocus = false
	testerBox.Parent = testerCard
	corner(testerBox, 5)
	stroke(testerBox, Theme.RedDark, 1, 0.6)

	-- Delay Input Box Label
	local delayLabel = Instance.new("TextLabel")
	delayLabel.Size = UDim2.new(0, 95, 0, 20)
	delayLabel.Position = UDim2.new(0, 8, 0, 52)
	delayLabel.BackgroundTransparency = 1
	delayLabel.Font = FM
	delayLabel.TextSize = 9
	delayLabel.TextColor3 = Theme.Muted
	delayLabel.TextXAlignment = Enum.TextXAlignment.Left
	delayLabel.Text = "Delay (Seconds):"
	delayLabel.Parent = testerCard

	local delayBox = Instance.new("TextBox")
	delayBox.Size = UDim2.new(0, 40, 0, 20)
	delayBox.Position = UDim2.new(0, 102, 0, 52)
	delayBox.BackgroundColor3 = Theme.Void
	delayBox.BorderSizePixel = 0
	delayBox.Font = FM
	delayBox.TextSize = 10
	delayBox.TextColor3 = Theme.Text
	delayBox.Text = "0"
	delayBox.ClearTextOnFocus = false
	delayBox.Parent = testerCard
	corner(delayBox, 4)
	stroke(delayBox, Theme.RedDark, 1, 0.6)

	delayBox:GetPropertyChangedSignal("Text"):Connect(function()
		_G.TestDelaySeconds = tonumber(delayBox.Text) or 0
	end)

	-- Parts Count Selector Button (1, 2, or 3 parts)
	local partsToggleBtn = Instance.new("TextButton")
	partsToggleBtn.Size = UDim2.new(0, 110, 0, 24)
	partsToggleBtn.Position = UDim2.new(0, 8, 0, 78)
	partsToggleBtn.BackgroundColor3 = Theme.Card
	partsToggleBtn.BorderSizePixel = 0
	partsToggleBtn.Font = FM
	partsToggleBtn.TextSize = 9
	partsToggleBtn.TextColor3 = Theme.Text
	partsToggleBtn.Text = "Parts Target: 1"
	partsToggleBtn.Parent = testerCard
	corner(partsToggleBtn, 5)
	stroke(partsToggleBtn, Theme.RedDark, 1, 0.5)

	partsToggleBtn.MouseButton1Click:Connect(function()
		_G.SubmitAfterCount = (_G.SubmitAfterCount % 3) + 1
		partsToggleBtn.Text = "Parts Target: " .. tostring(_G.SubmitAfterCount)
		updateCounters()
	end)

	-- Clear Buffer Button
	local clearBufBtn = Instance.new("TextButton")
	clearBufBtn.Size = UDim2.new(0, 110, 0, 24)
	clearBufBtn.Position = UDim2.new(1, -118, 0, 78)
	clearBufBtn.BackgroundColor3 = Theme.Card
	clearBufBtn.BorderSizePixel = 0
	clearBufBtn.Font = FM
	clearBufBtn.TextSize = 9
	clearBufBtn.TextColor3 = Theme.Amber
	clearBufBtn.Text = "Clear Buffer"
	clearBufBtn.Parent = testerCard
	corner(clearBufBtn, 5)
	stroke(clearBufBtn, Theme.Amber, 1, 0.6)

	clearBufBtn.MouseButton1Click:Connect(function()
		table.clear(collectedCodes)
		table.clear(collectedSeen)
		updateCounters()
		pushActivity("Buffer cleared manually", Theme.Amber)
	end)

	-- Fire Test Broadcast Button with Delay Support
	local fireTestBtn = Instance.new("TextButton")
	fireTestBtn.Size = UDim2.new(1, -16, 0, 26)
	fireTestBtn.Position = UDim2.new(0, 8, 0, 110)
	fireTestBtn.BackgroundColor3 = Theme.RedDark
	fireTestBtn.BorderSizePixel = 0
	fireTestBtn.Font = FT
	fireTestBtn.TextSize = 10
	fireTestBtn.TextColor3 = Theme.Text
	fireTestBtn.Text = "Simulate Drop (With Delay)"
	fireTestBtn.Parent = testerCard
	corner(fireTestBtn, 5)
	stroke(fireTestBtn, Theme.RedBright, 1, 0.4)

	fireTestBtn.MouseButton1Click:Connect(function()
		local content = testerBox.Text
		if content == "" then
			content = "The code is: TESTCODE123"
		end
		local delay = math.max(0, tonumber(_G.TestDelaySeconds) or 0)
		
		if delay > 0 then
			pushActivity("Waiting " .. delay .. "s before test drop...", Theme.Amber)
			setStatus("● WAITING", delay .. "s timer started", "wait")
			task.delay(delay, function()
				pushActivity("TEST (Delayed): " .. content, Theme.Amber)
				processText(content)
			end)
		else
			pushActivity("TEST: " .. content, Theme.Amber)
			processText(content)
		end
	end)
	-- =====================================================================

	-- Footer Counters
	QueueLabel = Instance.new("TextLabel")
	QueueLabel.Size = UDim2.new(0.5, 0, 0, 25)
	QueueLabel.Position = UDim2.new(0, 12, 0, 595)
	QueueLabel.BackgroundTransparency = 1
	QueueLabel.Font = FB
	QueueLabel.TextSize = 10
	QueueLabel.TextColor3 = Theme.Muted
	QueueLabel.TextXAlignment = Enum.TextXAlignment.Left
	QueueLabel.Text = "Queue: 0"
	QueueLabel.Parent = MainFrame

	CollectedLabel = Instance.new("TextLabel")
	CollectedLabel.Size = UDim2.new(0.5, 0, 0, 25)
	CollectedLabel.Position = UDim2.new(0.5, 0, 0, 595)
	CollectedLabel.BackgroundTransparency = 1
	CollectedLabel.Font = FB
	CollectedLabel.TextSize = 10
	CollectedLabel.TextColor3 = Theme.Muted
	CollectedLabel.TextXAlignment = Enum.TextXAlignment.Right
	CollectedLabel.Text = "Parts: 0 / 1"
	CollectedLabel.Parent = MainFrame

	-- Draggable UI (Bulletproof global release version)
	local dragging, dragStart, startPos = false, nil, nil

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

buildGui()
startPlayerGuiScanner()
print("[Gloomi Sniper V2] Fully loaded with Timed Announcement Tester!")
