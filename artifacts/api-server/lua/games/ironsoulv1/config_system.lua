--------------------------------------------------------------------------------
--// config_system.lua — S05 Config System
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local Services     = H.Services
local EngineConfig = H.EngineConfig
local CustomNotify = H.CustomNotify

-- [S05] CONFIG SYSTEM
--------------------------------------------------------------------------------
local HttpService = Services.HttpService
local FOLDER_NAME = "XiFilHub_Configs"
if not isfolder(FOLDER_NAME) then pcall(makefolder,FOLDER_NAME) end

local ConfigSystem = {}
function ConfigSystem.GetAutoLoadPointer()
    local p=FOLDER_NAME.."/autoload_pointer.txt"
    if isfile(p) then local ok,c=pcall(readfile,p); if ok and c then return c end end
    return "None"
end
function ConfigSystem.SaveAutoLoadPointer(n) pcall(writefile,FOLDER_NAME.."/autoload_pointer.txt",tostring(n)) end
function ConfigSystem.GetConfigList()
    local list={"None"}; local ok,files=pcall(listfiles,FOLDER_NAME)
    if ok and files then for _,f in ipairs(files) do
        local n=f:match("([^\\/]+)%.json$")
        if n and n~="autoload_pointer" then table.insert(list,n) end
    end end; return list
end
function ConfigSystem.SaveNew(name)
    if name=="" or name=="None" then return false,"Nama tidak valid!" end
    local ok,encoded=pcall(HttpService.JSONEncode,HttpService,EngineConfig)
    if not ok then return false,"Gagal encode." end
    if pcall(writefile,FOLDER_NAME.."/"..name..".json",encoded) then return true else return false,"I/O Error." end
end
function ConfigSystem.OverwriteExisting(name) return ConfigSystem.SaveNew(name) end
function ConfigSystem.Load(name,callback)
    if name=="None" then return false end
    local path=FOLDER_NAME.."/"..name..".json"
    if isfile(path) then
        local rok,content=pcall(readfile,path)
        if rok and content then
            local dok,data=pcall(HttpService.JSONDecode,HttpService,content)
            if dok and type(data)=="table" then
                for k,v in pairs(data) do if EngineConfig[k]~=nil then EngineConfig[k]=v end end
                if callback then callback() end; return true
            end
        end
    end; return false
end
function ConfigSystem.Delete(name)
    if name=="None" then return false end
    local p=FOLDER_NAME.."/"..name..".json"
    if isfile(p) then return pcall(delfile,p) end; return false
end
function ConfigSystem.ExecuteAutoLoad(callback)
    local target=ConfigSystem.GetAutoLoadPointer()
    if target and target~="None" then
        task.spawn(function()
            task.wait(0.5)
            if ConfigSystem.Load(target,callback) then CustomNotify("⚡ AUTOLOAD","Profil: "..target,3) end
        end)
    end
end


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.ConfigSystem = ConfigSystem
H.HttpService  = HttpService
H.FOLDER_NAME  = FOLDER_NAME
