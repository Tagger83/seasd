local ENV = getgenv and getgenv() or _G

if ENV.__ATLANTA_DETECTOR_RUNNING then
    return
end

ENV.__ATLANTA_DETECTOR_RUNNING = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local WEBHOOK_URL =
"https://discord.com/api/webhooks/1481433215398056087/5yiYW_g6HGoAcxig9zy0YQYX1Ciu3H_5AehQxZk_j0NxnrcWU8Uf7ev5-XmerOix7JGa"
local WORKSPACE_FILE = "Atlanta.txt"

local SCAN_BATCH = 100
local SECURITY_CHECK_INTERVAL = 5

local connections = {}
local containers = {}
local detected = setmetatable({}, { __mode = "k" })
local kicked = false

local cachedGameName = "Unknown Game"

task.spawn(function()
    pcall(function()
        local MarketplaceService = game:GetService("MarketplaceService")
        local info = MarketplaceService:GetProductInfo(game.PlaceId)

        if info and info.Name then
            cachedGameName = info.Name
        end
    end)
end)

local DETECT_NAMES = {
    "cobalt", "cobaltui", "cobaltwindow",
    "remotespy", "remotelogger",
    "simplespy", "simplespyv3",
    "hydroxide", "turtlespy", "adonisspy",
    "ketamine", "cspy", "cherryspy", "cherrysspy",
    "httpspy", "httpspygui", "httpspyui",
    "httplogs", "http_spy",
    "iy_gui", "iygui", "iy_fe", "iycommands"
}

local DETECT_TEXTS = {
    "remote spy", "simple spy",
    "cobalt", "hydroxide",
    "copy remote", "fired remote",
    "ignore remote", "block remote",
    "remote logger", "http spy",
    "ketamine", "cherry spy",
    "edge#1337", "iy_loaded", "iy fly"
}

local DETECT_GLOBALS = {
    "IY_LOADED", "IYMouse",
    "InfiniteYield", "iycommands", "IY_FE", "currentPrefix",
    "SimpleSpy", "SimpleSpyV3", "Cobalt",
    "Hydroxide", "RemoteSpy",
    "HttpSpy", "Ketamine", "CSpy"
}

local DEX_NAMES = {
    "dex",
    "dexexplorer",
    "dex explorer"
}

local DEX_TEXTS = {
    "ultimate debugging suite",
    "save instance",
    "script viewer"
}

local DEX_COMPONENTS = {
    "explorer",
    "properties",
    "scriptviewer",
    "saveinstance",
    "notebook"
}

local CONSOLE_ROOTS = {
    RobloxOutput = true,
    RobloxConsole = true,
    DevConsole = true,
    PerformanceStatsToggle = true,
    PerformanceStats = true,
    RobloxGui = true
}

local SCRIPT_HUB_KEYWORDS = {
    "check out this script",
    "an admin script dedicated to provide",
    "necessities of exploiting",
    "featured script",
    "script hub",
    "cloud script",
    "cloud scripts",
    "search script",
    "search scripts",
    "execute script"
}

local SCRIPT_HUB_NAMES = {
    "delta", "scripthub", "script_hub",
    "cloudscript", "cloudscripts",
    "scriptcatalog", "catalog",
    "hubframe", "scriptlibrary"
}

local trustedNamecall = ENV._AtlantaNamecall

local function isTextObject(obj)
    return obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox")
end

local function containsAny(value, keywords)
    value = tostring(value):lower()

    for i = 1, #keywords do
        if value:find(keywords[i], 1, true) then
            return keywords[i]
        end
    end

    return nil
end

local function isScriptHubObject(obj)
    if not obj then
        return false
    end

    if isTextObject(obj) then
        local text = obj.Text:lower()

        for i = 1, #SCRIPT_HUB_KEYWORDS do
            if text:find(SCRIPT_HUB_KEYWORDS[i], 1, true) then
                return true
            end
        end
    end

    local current = obj

    while current and current ~= CoreGui and current ~= game do
        local cName = tostring(current.Name):lower()

        for i = 1, #SCRIPT_HUB_NAMES do
            if cName:find(SCRIPT_HUB_NAMES[i], 1, true) then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function isConsoleObject(obj)
    local current = obj

    while current and current ~= CoreGui do
        if CONSOLE_ROOTS[current.Name] then
            return true
        end

        current = current.Parent
    end

    return false
end

local function isRobloxOutputText(obj)
    if not isTextObject(obj) then
        return false
    end

    local text = obj.Text:lower()

    return text:find("infinite yield possible", 1, true)
        or text:find("waitforchild", 1, true)
end

local function sendWebhook(reason)
    pcall(function()
        local fileContent = "No Atlanta.txt found"

        if isfile and isfile(WORKSPACE_FILE) then
            local success, content = pcall(readfile, WORKSPACE_FILE)

            if success and content and #content > 0 then
                fileContent = content
            end
        end

        if #fileContent > 1000 then
            fileContent = fileContent:sub(1, 1000) .. "\n... (truncated)"
        end

        local payload = HttpService:JSONEncode({
            username = "Atlanta Detector",

            embeds = {
                {
                    title = "🚨 Exploit Detected",

                    fields = {
                        {
                            name = "👤 Player",
                            value = LocalPlayer.Name .. " (`" .. LocalPlayer.UserId .. "`)",
                            inline = true
                        },

                        {
                            name = "🎮 Game",
                            value = cachedGameName,
                            inline = true
                        },

                        {
                            name = "🆔 Place ID",
                            value = tostring(game.PlaceId),
                            inline = true
                        },

                        {
                            name = "🔑 Job ID",
                            value = tostring(game.JobId),
                            inline = false
                        },

                        {
                            name = "⚠️ Kick Reason",
                            value = reason,
                            inline = false
                        },

                        {
                            name = "📄 Atlanta.txt Content",
                            value = "```\n" .. fileContent .. "\n```",
                            inline = false
                        }
                    },

                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
        })

        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end)
end

local function cleanup()
    ENV.__ATLANTA_DETECTOR_RUNNING = false

    for i = 1, #connections do
        local connection = connections[i]

        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    table.clear(connections)
    table.clear(containers)
end

local function kick(reason)
    if kicked then
        return
    end

    kicked = true

    task.spawn(function()
        sendWebhook(reason)
    end)

    cleanup()

    LocalPlayer:Kick("Dont Use any Spy Or key will be gone Wh01am001")
end

local function detect(obj)
    if kicked or detected[obj] then
        return
    end

    detected[obj] = true

    if isConsoleObject(obj) or isScriptHubObject(obj) then
        return
    end

    local name = obj.Name

    if containsAny(name, DETECT_NAMES) then
        kick("Name: " .. name)
        return
    end

    if isTextObject(obj) then
        if isRobloxOutputText(obj) then
            return
        end

        local text = obj.Text

        if containsAny(text, DETECT_TEXTS) then
            kick("UI Text: " .. text)
        end
    end
end

local function inspectDexObject(obj, state)
    if kicked then
        return
    end

    local name = obj.Name:lower()

    if containsAny(name, DEX_NAMES) then
        state.hasDexName = true
    end

    for i = 1, #DEX_COMPONENTS do
        local keyword = DEX_COMPONENTS[i]

        if name == keyword then
            state.components[keyword] = true
        end
    end

    if isTextObject(obj) then
        local text = obj.Text:lower()

        if containsAny(text, DEX_TEXTS) then
            state.hasDexText = true
        end

        if text == "dex" then
            state.hasDexName = true
        end

        local normalized = text:gsub("%s+", "")

        for i = 1, #DEX_COMPONENTS do
            local keyword = DEX_COMPONENTS[i]

            if normalized == keyword then
                state.components[keyword] = true
            end
        end
    end
end

local function detectDex(root)
    if kicked or not root or isConsoleObject(root) or isScriptHubObject(root) then
        return
    end

    local state = {
        components = {},
        hasDexName = false,
        hasDexText = false
    }

    inspectDexObject(root, state)

    local descendants = root:GetDescendants()

    for i = 1, #descendants do
        inspectDexObject(descendants[i], state)

        if kicked then
            return
        end
    end

    local componentCount = 0

    for _ in pairs(state.components) do
        componentCount = componentCount + 1
    end

    if state.hasDexText and (state.hasDexName or componentCount >= 2) then
        kick("Dex Explorer UI")
        return
    end

    if state.hasDexName and componentCount >= 2 then
        kick("Dex Explorer components")
    end
end

local function detectIY(root)
    if kicked or not root or isConsoleObject(root) or isScriptHubObject(root) then
        return
    end

    local hasCmdBar = false
    local hasIYSignature = false

    local descendants = root:GetDescendants()
    for i = 1, #descendants do
        local desc = descendants[i]
        local dName = desc.Name:lower()

        if desc:IsA("TextBox") and (dName == "cmdbar" or dName == "commandbar") then
            hasCmdBar = true
        end

        if isTextObject(desc) then
            local text = desc.Text:lower()
            if text:find("infinite yield", 1, true) or text:find("iy fe", 1, true) or text:find("edge#1337", 1, true) then
                hasIYSignature = true
            end
        end
    end

    if hasCmdBar and hasIYSignature then
        kick("Infinite Yield Executed UI")
    end
end

local function initialScan(container)
    local descendants = container:GetDescendants()

    for i = 1, #descendants do
        if kicked then
            return
        end

        detect(descendants[i])

        if i % SCAN_BATCH == 0 then
            task.wait()
        end
    end

    local children = container:GetChildren()

    for i = 1, #children do
        local child = children[i]

        if child:IsA("ScreenGui") or child:IsA("Folder") then
            detectDex(child)
            detectIY(child)
        end
    end
end

local function getTopLevelRoot(obj, container)
    local root = obj

    while root.Parent and root.Parent ~= container do
        root = root.Parent
    end

    return root
end

local dexPending = setmetatable({}, { __mode = "k" })

local function scheduleStructureScan(root)
    if dexPending[root] then
        return
    end

    dexPending[root] = true

    task.delay(0.15, function()
        dexPending[root] = nil

        if not kicked and root and root.Parent then
            detectDex(root)
            detectIY(root)
        end
    end)
end

local function register(container)
    if not container then
        return
    end

    if table.find(containers, container) then
        return
    end

    table.insert(containers, container)

    local connection = container.DescendantAdded:Connect(function(obj)
        if kicked then
            return
        end

        detect(obj)

        local root = getTopLevelRoot(obj, container)

        if root:IsA("ScreenGui") or root:IsA("Folder") then
            scheduleStructureScan(root)
        end
    end)

    table.insert(connections, connection)

    task.spawn(initialScan, container)
end

local function scanGlobals()
    if kicked then
        return
    end

    local environments = { _G }

    if ENV ~= _G then
        environments[#environments + 1] = ENV
    end

    if type(shared) == "table" then
        environments[#environments + 1] = shared
    end

    for i = 1, #environments do
        local env = environments[i]

        for j = 1, #DETECT_GLOBALS do
            local key = DETECT_GLOBALS[j]

            if rawget(env, key) ~= nil then
                kick("Global: " .. key)
                return
            end
        end
    end
end

local function checkRemoteHooks()
    if kicked or not getrawmetatable then
        return
    end

    pcall(function()
        local mt = getrawmetatable(game)

        if not mt then
            return
        end

        local current = mt.__namecall

        if type(current) ~= "function" then
            kick("Invalid __namecall")
            return
        end

        if trustedNamecall then
            if not rawequal(current, trustedNamecall) then
                kick("Unauthorized __namecall modification")
            end

            return
        end

        if islclosure and islclosure(current) then
            kick("Unknown Lua __namecall hook")
            return
        end

        if isexecutorclosure and isexecutorclosure(current) then
            kick("Unknown executor __namecall hook")
        end
    end)
end

register(CoreGui)
register(LocalPlayer:WaitForChild("PlayerGui"))

pcall(function()
    if gethui then
        register(gethui())
    end
end)

pcall(function()
    if gethiddenui then
        register(gethiddenui())
    end
end)

scanGlobals()
checkRemoteHooks()

task.spawn(function()
    while ENV.__ATLANTA_DETECTOR_RUNNING and not kicked do
        task.wait(SECURITY_CHECK_INTERVAL)

        scanGlobals()
        checkRemoteHooks()
    end
end)
