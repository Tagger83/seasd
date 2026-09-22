repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

local SCRIPT_URL = "https://raw.githubusercontent.com/Tagger83/seasd/refs/heads/main/ascas"

local queue =
    queue_on_teleport
    or queueonteleport
    or (syn and syn.queue_on_teleport)

-- Esperar Remote
local target = ReplicatedStorage
    :WaitForChild("Remotes")
    :WaitForChild("Misc")
    :WaitForChild("ClaimDailyCheck")

-- Mandar Remote
local success, result = pcall(function()
    if target:IsA("RemoteEvent") then
        target:FireServer(1, "test", true)
        return "Fired Successfully"
    elseif target:IsA("RemoteFunction") then
        return target:InvokeServer(1, "test", true)
    end
end)

if success then
    print("✓ ClaimDailyCheck:", result)
else
    warn("✗ ClaimDailyCheck ERROR:", result)
end

task.wait(5)

-- Preparar ejecución después del teleport
if queue then
    queue([[
        repeat task.wait() until game:IsLoaded()
        task.wait(5)

        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Tagger83/seasd/refs/heads/main/ascas"
        ))()
    ]])

    print("✓ Script queued")
else
    warn("✗ Tu executor no tiene queue_on_teleport")
    return
end

task.wait(1)

-- Rejoin al mismo servidor
TeleportService:TeleportToPlaceInstance(
    game.PlaceId,
    game.JobId,
    player
)
