--[[
  GLOOMI SNIPER V2 — optimized + black/red theme + custom text tester + submit testing lab
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
_G.SubmitAfterCount = 1  -- Multi-part count (1 to 4)
_G.SubmitAttempts = 3
_G.AnchorEnabled = false
_G.AutoBuyEnabled = false

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
local sammyLogHost = nil
local ActivityList = {}

local captureMode = nil
local captureUntil = 0
local bufferedParts = {}
local lastSammyText, lastSammyAt = "", 0
local lastQueuedAt = 0

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

local function pushSammyLog(text)
	text = tostring(text or ""):gsub("%s+", " "):sub(1, 100)
	if text == "" or not sammyLogHost then return end
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -4, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundTransparency = 1
	row.Font = FB
	row.TextSize = 9
	row.TextColor3 = Theme.Amber
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextWrapped = true
	row.Text = "• " .. text
	row.LayoutOrder = -math.floor(os.clock() * 1000)
	row.Parent = sammyLogHost
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
	["1st mutation"] = "BLOODROT", ["1st trait"] = "LIGHTNING", ["1st trait created"] = "LIGHTNING",
	["2nd machine"] = "BUBBLEGUMMACHINE", ["2nd mutation"] = "CANDY",
	["3rd machine"] = "FUSEMACHINE", ["3rd mutation"] = "LAVA",
	["4th machine"] = "CRAFTMACHINE", ["4th mutation"] = "GALAXY",
	["5th machine"] = "WITCHFUSE", ["5th mutation"] = "YINYANG",
	["67"] = "67", ["6th machine"] = "BRAINROTDEALER", ["6th mutation"] = "RADIOACTIVE",
	["7th machine"] = "BRAINROTTRADER", ["7th mutation"] = "CURSED",
	["8th machine"] = "SANTASFUSE", ["8th mutation"] = "DIVINE",
	["9th machine"] = "SANTASSHOP", ["9th mutation"] = "CYBER",
	["age"] = "24", ["angelic"] = "DIVINE", ["angelic mutation"] = "DIVINE",
	["best brainrot"] = "STRAWBERRYELEPHANT", ["best mutation"] = "DIVINE",
	["birth day"] = "FRIDAY", ["birth month"] = "FEBRUARY", ["birth year"] = "2002",
	["birthday"] = "FRIDAY", ["birthplace"] = "ALGERIA",
	["black and white"] = "GALAXY", ["black mutation"] = "GALAXY",
	["born on"] = "FRIDAY", ["born year"] = "2002",
	["city"] = "SAOPAULO", ["color"] = "BLUE", ["color is blue"] = "BLUE",
	["common rarity"] = "COMMON", ["country"] = "BRAZIL", ["created on"] = "FRIDAY",
	["creator"] = "SAMMY", ["creator name"] = "SAMMY", ["creator real name"] = "SAMMY",
	["creator twice"] = "SAMMYSAMMY", ["cursed mutation"] = "CURSED",
	["date made"] = "MAY162025", ["day born"] = "FRIDAY", ["day i was born"] = "FRIDAY",
	["day sab was made"] = "FRIDAY", ["day sab was released"] = "FRIDAY",
	["divine mutation"] = "DIVINE", ["eighteenth machine"] = "LOSTRADERS",
	["eighth machine"] = "SANTASFUSE", ["eleventh machine"] = "DUELSMACHINE",
	["evil"] = "CURSED", ["evil mutation"] = "CURSED",
	["fav animal"] = "SPIDER", ["fav color"] = "BLUE", ["fav color is blue"] = "BLUE",
	["fav food"] = "PIZZA", ["fav football player"] = "FOOTBALL", ["fav game"] = "ROBLOX",
	["fav player"] = "FOOTBALL", ["fav sport"] = "FOOTBALL",
	["favorite animal"] = "SPIDER", ["favorite color"] = "BLUE", ["favorite color twice"] = "BLUEBLUE",
	["favorite food"] = "PIZZA", ["favorite food twice"] = "PIZZAPIZZA",
	["favorite game"] = "ROBLOX", ["favorite player"] = "FOOTBALL",
	["favorite sport"] = "FOOTBALL", ["favorite sport twice"] = "FOOTBALLFOOTBALL",
	["favourite color"] = "BLUE", ["fifteenth machine"] = "EGGINCUBATOR",
	["fifth machine"] = "WITCHFUSE", ["first machine"] = "RAINBOWMACHINE",
	["first mutation"] = "BLOODROT", ["first trait"] = "LIGHTNING", ["first trait created"] = "LIGHTNING",
	["food"] = "PIZZA", ["football player"] = "FOOTBALL",
	["fourteenth machine"] = "DIVINEFUSE", ["fourth machine"] = "CRAFTMACHINE",
	["full name"] = "STEALABRAINROT", ["funny number"] = "67",
	["game created on"] = "FRIDAY", ["game creation day"] = "FRIDAY", ["game made on"] = "FRIDAY",
	["game name"] = "STEALABRAINROT", ["game release"] = "MAY162025",
	["game release date"] = "MAY162025", ["game released"] = "MAY162025",
	["good mutation"] = "DIVINE", ["green"] = "RADIOACTIVE", ["green mutation"] = "RADIOACTIVE",
	["headless horseman"] = "LOSTRADERS", ["highest rarity"] = "OG",
	["how old am i"] = "24", ["how old is sammy"] = "24",
	["latest mutation"] = "CRYSTAL", ["lightning"] = "LIGHTNING", ["lightning trait"] = "LIGHTNING",
	["lowest rarity"] = "COMMON", ["molten"] = "MOLTEN", ["molten mutation"] = "MOLTEN",
	["month born"] = "FEBRUARY", ["month i was born"] = "FEBRUARY", ["month sab was made"] = "MAY",
	["most recent"] = "CRYSTAL", ["most recent mutation"] = "CRYSTAL",
	["my age"] = "24", ["my age 2 times"] = "2424", ["my age 3 times"] = "242424", ["my age twice"] = "2424",
	["my animal"] = "SPIDER", ["my cat's name"] = "NOVA", ["my cats name"] = "NOVA",
	["my city"] = "SAOPAULO", ["my color"] = "BLUE", ["my color is blue"] = "BLUE",
	["my country"] = "BRAZIL", ["my food"] = "PIZZA",
	["my name"] = "SAMMY", ["what is my name"] = "SAMMY", ["whats my name"] = "SAMMY", ["what's my name"] = "SAMMY",
	["my name 2 times"] = "SAMMYSAMMY", ["my name 3 times"] = "SAMMYSAMMYSAMMY", ["my name twice"] = "SAMMYSAMMY",
	["my nationality"] = "BRAZILIAN", ["my pet"] = "SPIDER", ["my real name"] = "SAMMY",
	["my roblox username"] = "SPYDERSAMMY", ["my sport"] = "FOOTBALL", ["my state"] = "SAOPAULO",
	["my username"] = "SPYDERSAMMY", ["my youtube"] = "SPYDERSAMMY",
	["name of the game"] = "STEALABRAINROT", ["name twice"] = "SAMMYSAMMY",
	["nationality"] = "BRAZILIAN", ["newest mutation"] = "CRYSTAL", ["ninth machine"] = "SANTASSHOP",
	["orange"] = "MOLTEN", ["orange mutation"] = "MOLTEN",
	["owner"] = "SAMMY", ["owner real name"] = "SAMMY", ["owner twice"] = "SAMMYSAMMY",
	["purple"] = "GALAXY", ["purple mutation"] = "GALAXY",
	["rarest"] = "LOSTRADERS", ["rarest brainrot"] = "LOSTRADERS", ["rarest rarity"] = "OG",
	["real name"] = "SAMMY", ["red"] = "CURSED", ["red mutation"] = "CURSED",
	["release date"] = "MAY162025", ["release month"] = "MAY", ["release year"] = "2025",
	["roblox name"] = "SPYDERSAMMY", ["roblox username"] = "SPYDERSAMMY", ["ronaldo"] = "FOOTBALL",
	["sab"] = "STEALABRAINROT", ["sab made on"] = "FRIDAY", ["sab release"] = "MAY162025",
	["sab release day"] = "FRIDAY", ["sab release month"] = "MAY", ["sab released"] = "MAY162025",
	["sab stands for"] = "STEALABRAINROT",
	["sammy age"] = "24", ["sammy city"] = "SAOPAULO", ["sammy color"] = "BLUE",
	["sammy color is blue"] = "BLUE", ["sammy country"] = "BRAZIL", ["sammy location"] = "BRAZIL",
	["sammy nationality"] = "BRAZILIAN", ["sammy real name"] = "SAMMY",
	["sammy roblox name"] = "SPYDERSAMMY", ["sammy state"] = "SAOPAULO",
	["sammy username"] = "SPYDERSAMMY", ["sammy youtube"] = "SPYDERSAMMY", ["sammys real name"] = "SAMMY",
	["second machine"] = "BUBBLEGUMMACHINE", ["second mutation"] = "CANDY",
	["seventeenth machine"] = "SUMMERFUSE", ["seventh machine"] = "BRAINROTTRADER",
	["sixteenth machine"] = "CYBERCRAFTMACHINE", ["sixth machine"] = "BRAINROTDEALER",
	["social media"] = "YOUTUBE", ["special number"] = "67", ["sport"] = "FOOTBALL", ["state"] = "SAOPAULO",
	["struck by lightning"] = "LIGHTNING", ["tenth machine"] = "NEWYEARSMACHINE",
	["third machine"] = "FUSEMACHINE", ["third mutation"] = "LAVA", ["thirteenth machine"] = "TRADEMACHINE",
	["top mutation"] = "DIVINE", ["top rarity"] = "OG", ["trait from lightning"] = "LIGHTNING",
	["turns black"] = "GALAXY", ["turns green"] = "RADIOACTIVE", ["turns orange"] = "MOLTEN",
	["turns purple"] = "GALAXY", ["turns red"] = "CURSED", ["turns yellow"] = "DIVINE",
	["twelfth machine"] = "CUPIDSMACHINE", ["unobtainable"] = "STRAWBERRYELEPHANT",
	["username"] = "SPYDERSAMMY", ["what is my cats name"] = "NOVA",
	["when made"] = "MAY162025", ["when was sab created"] = "MAY162025",
	["when was sab made"] = "MAY162025", ["when was sab released"] = "MAY162025",
	["where am i from"] = "BRAZIL", ["where do i live"] = "BRAZIL", ["where does sammy live"] = "BRAZIL",
	["where i was born"] = "ALGERIA", ["where is sammy from"] = "BRAZIL",
	["where was i born"] = "ALGERIA", ["where was i born at"] = "ALGERIA",
	["who created sab"] = "SAMMY", ["who is the owner"] = "SAMMY", ["who made sab"] = "SAMMY", ["who owns sab"] = "SAMMY",
	["year born"] = "2002", ["year created"] = "2025", ["year i was born"] = "2002",
	["year made"] = "2025", ["year of sab"] = "2025", ["year sab was created"] = "2025", ["year sab was made"] = "2025",
	["year we are on"] = "2026", ["year we're on"] = "2026", ["year were on"] = "2026",
	["yellow"] = "DIVINE", ["yellow mutation"] = "DIVINE", ["youtube channel"] = "SPYDERSAMMY",
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
			local repeatCount = 1
			if after:sub(1, 5) == "twice" then
				repeatCount = 2
				after = after:sub(6)
			else
				local amount = after:match("^(%d+)times")
				if amount then
					repeatCount = tonumber(amount) or 1
					after = after:gsub("^%d+times", "", 1)
				end
			end
			table.insert(pieces, string.rep(answer, repeatCount))
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
	if low == "code" or low == "riddle" or low == "the" or low == "is" or low == "use" or low == "answer" then
		return false
	end
	return token:match("^[%w%-%_]+$") ~= nil
end

local function extractCodesFromText(text)
	local found = {}
	if not text then return found end
	local trimmed = (text:match("^%s*(.-)%s*$") or ""):gsub("<[^>]->", "")
	local stripped = trimmed
		:gsub("^[Tt]he%s+[Cc]ode%s+[Ii]s%s*", "")
		:gsub("^[Cc]ode%s+[Ii]s%s*", "")
		:gsub("^[Uu]se%s+[Cc]ode%s*", "")
		:gsub("^[Tt]he%s+[Aa]nswer%s+[Ii]s%s*", "")
		:gsub("^[Aa]nswer%s+[Ii]s%s*", "")
		:gsub("^%s+", "")
	if looksLikeCode(stripped) and not stripped:find("%s") then
		table.insert(found, stripped:upper())
		return found
	end
	if looksLikeCode(trimmed) and not trimmed:find("%s") then
		table.insert(found, trimmed:upper())
		return found
	end
	for token in stripped:gmatch("[%w%-%_]+") do
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
	if hint:find("code") or hint:find("redeem") or hint:find("enter") or hint:find("type") or hint:find("here") then
		return true
	end
	local sz = obj.AbsoluteSize
	return sz.X >= 80 and sz.Y >= 20 and sz.Y <= 80
end

local function findCodeTextBox()
	if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then return _cachedBox end
	_cachedBox = nil
	local focused = UIS:GetFocusedTextBox()
	if focused and _isCodeBox(focused) then
		_cachedBox = focused
		return focused
	end
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
				if c.Function then pcall(c.Function) end
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
	return hint:find("redeem") or hint:find("submit") or hint:find("claim")
		or hint:find("confirm") or hint:find("enter")
end

local _cachedSubmitBtn = nil
local function fireSubmitButton(nearObj)
	local target = nil
	if _cachedSubmitBtn and _cachedSubmitBtn.Parent and isSubmitButton(_cachedSubmitBtn) then
		target = _cachedSubmitBtn
	else
		_cachedSubmitBtn = nil
		local container, levels = nearObj and nearObj.Parent, 0
		while container and levels < 8 do
			for _, ch in ipairs(container:GetChildren()) do
				if isSubmitButton(ch) then target = ch; break end
				for _, g in ipairs(ch:GetChildren()) do
					if isSubmitButton(g) then target = g; break end
				end
				if target then break end
			end
			if target then break end
			container = container.Parent
			levels += 1
		end
		if not target then
			local pg = LP:FindFirstChild("PlayerGui")
			if pg then
				for _, ch in ipairs(pg:GetDescendants()) do
					if isSubmitButton(ch) then target = ch; break end
				end
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
	end)

	pcall(function()
		textBox:CaptureFocus()
		textBox.Text = fullText
		textBox.CursorPosition = #fullText + 1
	end)

	if ready and _G.AutoSubmitEnabled then
		setStatus("● SUBMIT", fullText, "wait")
		local attempts = math.clamp(tonumber(_G.SubmitAttempts) or 3, 1, 6)
		for _ = 1, attempts do
			pcall(function()
				textBox.Text = fullText
				textBox:CaptureFocus()
			end)
			fireSubmitButton(textBox)
			task.wait(0.05)
		end
		redeemViaRF(fullText)
		setStatus("✓ SUCCESS", "Submitted " .. fullText, "ok")
		pushActivity("Submitted " .. fullText, Theme.Green)
		table.clear(collectedCodes)
		table.clear(collectedSeen)
		updateCounters()
		task.delay(0.8, function()
			setStatus("● ONLINE", "Waiting for trigger", "ok")
		end)
	elseif ready then
		setStatus("● READY", "Full code ready", "ok")
	else
		setStatus("● ONLINE", "Typed " .. code, "ok")
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
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	s = s:gsub("%.+$", ""):gsub("…+$", "")
	return s
end

local function detectTrigger(message)
	local n = normalize(message)
	if n == "the riddle is" or n:find("the riddle is", 1, true) then return "riddle" end
	if n == "riddle is" or n:find("riddle is", 1, true) then return "riddle" end
	if n == "the code is" or n:find("the code is", 1, true) then return "code" end
	if n == "code is" or n:find("code is", 1, true) then return "code" end
	if n == "use code" or n:find("use code", 1, true) then return "code" end
	if n == "the answer is" or n:find("the answer is", 1, true) then return "riddle" end
	if n == "answer is" or n:find("answer is", 1, true) then return "riddle" end
	if n == "riddle" then return "riddle" end
	if n == "code" then return "code" end
	return nil
end

local function isArmed()
	return captureMode ~= nil and tick() < captureUntil
end

local function armCapture(mode)
	captureMode = mode
	captureUntil = tick() + 15
	table.clear(bufferedParts)
	setStatus("● ARMED", mode:upper() .. " — waiting…", "arm")
	pushActivity("Armed: " + mode, Theme.Amber)
end

local function clearArm()
	captureMode = nil
	captureUntil = 0
	table.clear(bufferedParts)
end

local function processArmedPayload(raw)
	if not isArmed() then return false end
	raw = stripRich(raw)
	local mode = captureMode

	if mode == "riddle" then
		if not _G.RiddleSolverEnabled then return true end
		local ans = solveRiddle(raw)
		if ans then
			clearArm()
			setStatus("✓ RIDDLE", ans, "ok")
			pushActivity("Riddle → " .. ans, Theme.Crimson)
			if _G.AutoWriteEnabled then
				queueCode(ans, "Riddle")
			else
				local box = findCodeTextBox()
				if box then
					pcall(function()
						box:CaptureFocus()
						box.Text = ans
					end)
					if _G.AutoSubmitEnabled then
						task.wait(0.03)
						fireSubmitButton(box)
						redeemViaRF(ans)
					end
				end
			end
			return true
		end
		return true
	end

	if mode == "code" then
		if not _G.AutoWriteEnabled then return true end
		local codes = extractCodesFromText(raw)
		if #codes > 0 then
			clearArm()
			for _, c in ipairs(codes) do
				queueCode(c, "Code")
			end
			return true
		end
		local cleaned = raw:gsub("%s+", "")
		if cleaned ~= "" then
			queueCode(cleaned, "Part")
			clearArm()
			return true
		end
		return true
	end
	return false
end

local function processText(text)
	if not text or text == "" then return end
	text = stripRich(text)

	local trig = detectTrigger(text)
	if trig then
		if trig == "riddle" and (_G.RiddleSolverEnabled or _G.AutoWriteEnabled) then
			armCapture("riddle")
		elseif trig == "code" and _G.AutoWriteEnabled then
			armCapture("code")
		end

		if captureMode == "code" then
			local codes = extractCodesFromText(text)
			for _, c in ipairs(codes) do
				local low = c:lower()
				if low ~= "code" and low ~= "riddle" and #c >= 2 then
					clearArm()
					queueCode(c, "Inline")
					return
				end
			end
		elseif captureMode == "riddle" then
			local rest = text
				:gsub("[Tt]he%s+[Rr]iddle%s+[Ii]s%s*", "")
				:gsub("[Rr]iddle%s+[Ii]s%s*", "")
				:gsub("[Tt]he%s+[Aa]nswer%s+[Ii]s%s*", "")
				:gsub("[Aa]nswer%s+[Ii]s%s*", "")
			if rest ~= text and #rest > 2 then
				local ans = solveRiddle(rest)
				if ans then
					clearArm()
					setStatus("✓ RIDDLE", ans, "ok")
					pushActivity("Riddle → " .. ans, Theme.Crimson)
					if _G.AutoWriteEnabled then queueCode(ans, "Riddle") end
					return
				end
			end
		end
		return
	end

	if isArmed() then
		processArmedPayload(text)
		return
	end
end

-- Direct simulation testing pipeline bypassing filter
local function testAnnouncementString(text)
	text = tostring(text or "The code is TEST99")
	pushSammyLog("[TESTER] " .. text)
	pushActivity("Testing custom announcement", Theme.Amber)
	
	-- Force trigger processing for testing
	local codes = extractCodesFromText(text)
	if #codes > 0 then
		for _, c in ipairs(codes) do
			queueCode(c, "TestQ")
		end
	else
		queueCode(text:gsub("%s+", ""), "TestPart")
	end
	if _G.AutoWriteEnabled then
		triggerWrite()
	end
end
getgenv().TestAnnouncement = testAnnouncementString

local targetUserId = nil
task.spawn(function()
	local ok, id = pcall(function()
		return Players:GetUserIdFromNameAsync("SpyderSammy")
	end)
	if ok then targetUserId = id end
end)

local _sammyCache = {}
local ANNOUNCE_KEYS = {
	"sammy", "spydersammy", "announcement", "announce", "notify", "notification",
	"codeevent", "broadcast", "message", "tip", "live",
}

local function verifySourceIsSammy(textObj)
	if not textObj or not textObj.Parent then return false end
	if ScreenGui and textObj:IsDescendantOf(ScreenGui) then return false end
	local container = textObj.Parent
	local depth = 0
	while container and depth < 12 do
		if container:IsA("ScreenGui") or container.Name == "PlayerGui" then break end
		if _sammyCache[container] ~= nil then return _sammyCache[container] end
		local cname = string.lower(container.Name or "")
		for _, k in ipairs(ANNOUNCE_KEYS) do
			if cname:find(k, 1, true) then
				_sammyCache[container] = true
				return true
			end
		end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("TextLabel") or item:IsA("TextButton") then
				local t = string.lower(item.Text or "")
				if t:find("spydersammy", 1, true) or t:find("sammy", 1, true) then
					_sammyCache[container] = true
					return true
				end
			elseif (item:IsA("ImageLabel") or item:IsA("ImageButton")) and item.Visible and item.Image ~= "" then
				if targetUserId and string.find(string.lower(item.Image), tostring(targetUserId), 1, true) then
					_sammyCache[container] = true
					return true
				end
			end
		end
		container = container.Parent
		depth += 1
	end
	return false
end

local function handleIncomingText(textObj)
	if not _G.ScriptEnabled then return end
	if not textObj or not textObj.Parent then return end
	local text = textObj.Text
	if not text or text == "" or #text > 300 then return end

	if _G.SammyFilterEnabled then
		if not verifySourceIsSammy(textObj) then return end
	else
		if ScreenGui and textObj:IsDescendantOf(ScreenGui) then return end
	end

	local now = tick()
	if text ~= lastSammyText or (now - lastSammyAt) > 0.35 then
		lastSammyText = text
		lastSammyAt = now
		pushSammyLog(text)
	end
	processText(text)
end

local hooked = setmetatable({}, { __mode = "k" })
local function hookUiTextObject(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
	if ScreenGui and obj:IsDescendantOf(ScreenGui) then return end
	if hooked[obj] then return end
	hooked[obj] = true
	task.defer(function()
		if obj.Parent then handleIncomingText(obj) end
	end)
	obj:GetPropertyChangedSignal("Text"):Connect(function()
		handleIncomingText(obj)
	end)
end

local function startPlayerGuiScanner()
	local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
	if not pg then return end
	task.spawn(function()
		local n = 0
		for _, d in ipairs(pg:GetDescendants()) do
			hookUiTextObject(d)
			n += 1
			if n % 120 == 0 then task.wait() end
		end
	end)
	pg.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			hookUiTextObject(obj)
		elseif obj:IsA("TextBox") and _isCodeBox(obj) then
			_cachedBox = obj
			triggerWrite()
		end
	end)
end

-- GUI Setup with Submission & Announcement Testing Lab
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
	MainFrame.Size = UDim2.new(0, 290, 0, 516)
	MainFrame.Position = UDim2.new(0.5, -145, 0.5, -258)
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
	title.Size = UDim2.new(1, -20, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = FT
	title.TextSize = 13
	title.TextColor3 = Theme.RedBright
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "gloomi sniper v2"
	title.Parent = topBar

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

	-- Main Toggle Builder Function
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

	createToggle("Auto Write Codes", 152, _G.AutoWriteEnabled, function(v)
		_G.AutoWriteEnabled = v
		if v then triggerWrite() end
	end)

	createToggle("Auto Submit", 180, _G.AutoSubmitEnabled, function(v)
		_G.AutoSubmitEnabled = v
	end)

	createToggle("Riddle Solver", 208, _G.RiddleSolverEnabled, function(v)
		_G.RiddleSolverEnabled = v
	end)

	createToggle("Sammy Filter Only", 236, _G.SammyFilterEnabled, function(v)
		_G.SammyFilterEnabled = v
	end)

	-- Multi-Part Selector Bar
	local partsLabel = Instance.new("TextLabel")
	partsLabel.Size = UDim2.new(1, -24, 0, 13)
	partsLabel.Position = UDim2.new(0, 12, 0, 267)
	partsLabel.BackgroundTransparency = 1
	partsLabel.Font = FM
	partsLabel.TextSize = 10
	partsLabel.TextColor3 = Theme.Muted
	partsLabel.TextXAlignment = Enum.TextXAlignment.Left
	partsLabel.Text = "Code Parts Split (Buffer count):"
	partsLabel.Parent = MainFrame

	local partsBar = Instance.new("Frame")
	partsBar.Size = UDim2.new(1, -24, 0, 24)
	partsBar.Position = UDim2.new(0, 12, 0, 283)
	partsBar.BackgroundTransparency = 1
	partsBar.Parent = MainFrame

	local partBtns = {}
	local function createPartBtn(countNum, xPos)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.23, 0, 1, 0)
		btn.Position = UDim2.new(xPos, 0, 0, 0)
		btn.BackgroundColor3 = (_G.SubmitAfterCount == countNum) and Theme.RedDark or Theme.Card
		btn.BorderSizePixel = 0
		btn.Font = FM
		btn.TextSize = 9
		btn.TextColor3 = Theme.Text
		btn.Text = countNum .. " Part" .. (countNum > 1 and "s" or "")
		btn.Parent = partsBar
		corner(btn, 6)
		stroke(btn, (_G.SubmitAfterCount == countNum) and Theme.RedBright or Theme.Muted, 1, 0.5)

		btn.MouseButton1Click:Connect(function()
			_G.SubmitAfterCount = countNum
			for _, b in ipairs(partBtns) do
				b.BackgroundColor3 = Theme.Card
			end
			btn.BackgroundColor3 = Theme.RedDark
			pushActivity("Set parts to: " .. countNum, Theme.Amber)
			updateCounters()
		end)
		table.insert(partBtns, btn)
	end

	createPartBtn(1, 0)
	createPartBtn(2, 0.25)
	createPartBtn(3, 0.50)
	createPartBtn(4, 0.75)

	-- Custom Announcement & Submit Lab Section
	local testerLabel = Instance.new("TextLabel")
	testerLabel.Size = UDim2.new(1, -24, 0, 13)
	testerLabel.Position = UDim2.new(0, 12, 0, 313)
	testerLabel.BackgroundTransparency = 1
	testerLabel.Font = FM
	testerLabel.TextSize = 10
	testerLabel.TextColor3 = Theme.Muted
	testerLabel.TextXAlignment = Enum.TextXAlignment.Left
	testerLabel.Text = "Test Announcement & Submit Lab:"
	testerLabel.Parent = MainFrame

	local customBox = Instance.new("TextBox")
	customBox.Size = UDim2.new(1, -24, 0, 26)
	customBox.Position = UDim2.new(0, 12, 0, 328)
	customBox.BackgroundColor3 = Theme.Card
	customBox.BorderSizePixel = 0
	customBox.Font = FB
	customBox.TextSize = 10
	customBox.TextColor3 = Theme.Text
	customBox.PlaceholderColor3 = Theme.Muted
	customBox.PlaceholderText = "Type code/part to test..."
	customBox.Text = ""
	customBox.ClearTextOnFocus = false
	customBox.Parent = MainFrame
	corner(customBox, 6)
	stroke(customBox, Theme.RedDark, 1, 0.5)

	local fireTestBtn = Instance.new("TextButton")
	fireTestBtn.Size = UDim2.new(0.48, 0, 0, 26)
	fireTestBtn.Position = UDim2.new(0, 12, 0, 358)
	fireTestBtn.BackgroundColor3 = Theme.RedDark
	fireTestBtn.BorderSizePixel = 0
	fireTestBtn.Font = FT
	fireTestBtn.TextSize = 9
	fireTestBtn.TextColor3 = Theme.Text
	fireTestBtn.Text = "▶ Simulate Text"
	fireTestBtn.Parent = MainFrame
	corner(fireTestBtn, 6)
	stroke(fireTestBtn, Theme.RedBright, 1, 0.4)

	local fireSubmitBtn = Instance.new("TextButton")
	fireSubmitBtn.Size = UDim2.new(0.48, 0, 0, 26)
	fireSubmitBtn.Position = UDim2.new(0.51, 0, 0, 358)
	fireSubmitBtn.BackgroundColor3 = Theme.Green
	fireSubmitBtn.BorderSizePixel = 0
	fireSubmitBtn.Font = FT
	fireSubmitBtn.TextSize = 9
	fireSubmitBtn.TextColor3 = Theme.Void
	fireSubmitBtn.Text = "⚡ Test Submit / Buffer"
	fireSubmitBtn.Parent = MainFrame
	corner(fireSubmitBtn, 6)
	stroke(fireSubmitBtn, Theme.Text, 1, 0.4)

	fireTestBtn.MouseButton1Click:Connect(function()
		local val = customBox.Text ~= "" and customBox.Text or "The code is TEST99"
		testAnnouncementString(val)
	end)

	fireSubmitBtn.MouseButton1Click:Connect(function()
		local val = customBox.Text ~= "" and customBox.Text or "DIRECTTESTCODE"
		pushActivity("Direct Submit Test", Theme.Green)
		writeAndSubmit(val)
	end)

	-- Footer Counters
	local footer = Instance.new("Frame")
	footer.Size = UDim2.new(1, -24, 0, 25)
	footer.Position = UDim2.new(0, 12, 0, 434)
	footer.BackgroundTransparency = 1
	footer.Parent = MainFrame

	QueueLabel = Instance.new("TextLabel")
	QueueLabel.Size = UDim2.new(0.5, 0, 1, 0)
	QueueLabel.BackgroundTransparency = 1
	QueueLabel.Font = FB
	QueueLabel.TextSize = 10
	QueueLabel.TextColor3 = Theme.Muted
	QueueLabel.TextXAlignment = Enum.TextXAlignment.Left
	QueueLabel.Text = "Queue: 0"
	QueueLabel.Parent = footer

	CollectedLabel = Instance.new("TextLabel")
	CollectedLabel.Size = UDim2.new(0.5, 0, 1, 0)
	CollectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
	CollectedLabel.BackgroundTransparency = 1
	CollectedLabel.Font = FB
	CollectedLabel.TextSize = 10
	CollectedLabel.TextColor3 = Theme.Muted
	CollectedLabel.TextXAlignment = Enum.TextXAlignment.Right
	CollectedLabel.Text = "Parts: 0 / 1"
	CollectedLabel.Parent = footer

	-- Draggable Script Setup
	local dragging, dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
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
print("[Gloomi Sniper V2] Loaded with Testing Lab UI.")
