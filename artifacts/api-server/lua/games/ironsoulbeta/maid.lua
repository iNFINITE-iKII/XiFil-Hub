--------------------------------------------------------------------------------
--// maid.lua — S03 Maid
--------------------------------------------------------------------------------
local H = getgenv().Hub

-- [S03] MAID
--------------------------------------------------------------------------------
local Maid = {}; Maid.__index = Maid
function Maid.new() return setmetatable({tasks={}}, Maid) end
function Maid:GiveTask(t) table.insert(self.tasks, t); return t end
function Maid:DoCleaning()
    for _, item in ipairs(self.tasks) do
        if type(item)=="function" then item()
        elseif typeof(item)=="RBXScriptConnection" then item:Disconnect()
        elseif type(item)=="table" and item.Destroy then item:Destroy() end
    end
    table.clear(self.tasks)
end
local RuntimeMaid = Maid.new()


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.Maid       = Maid
H.RuntimeMaid = RuntimeMaid
