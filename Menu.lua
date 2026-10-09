-- VELCORE · GitHub Wave GUI-only package (no gameplay functions).
-- Menu.lua is downloaded by Loader.lua; it downloads the four UI modules.
-- Do not upload private tokens or execute unrelated game code here.
return function(BASE_URL)
    assert(type(BASE_URL) == "string" and BASE_URL:match("^https://raw%.githubusercontent%.com/"),
        "Menu.lua must be called by Loader.lua with a GitHub raw base URL")

    local Players = game:GetService("Players")
    assert(Players.LocalPlayer, "This GUI must run on the client")
    local global = (type(getgenv)=="function" and getgenv()) or _G
    if type(global.__VELCORE_GUI_ONLY_DESTROY)=="function" then
        pcall(global.__VELCORE_GUI_ONLY_DESTROY)
    end

    local function withUIThread(callback)
        local getter = getthreadidentity or get_thread_identity or getthreadcontext
        local setter = setthreadidentity or set_thread_identity or setthreadcontext
        local old
        if type(getter)=="function" then pcall(function() old=getter() end) end
        if type(setter)=="function" then pcall(setter,8) end
        local ok,result = pcall(callback)
        if old ~= nil and type(setter)=="function" then pcall(setter,old) end
        if not ok then warn("[VELCORE GUI] "..tostring(result)) end
        return ok and result or nil
    end

    local function remoteModule(filename)
        -- Only these explicitly named repository files are downloaded.
        local allowed = { ["Wave.lua"]=true, ["Layout.lua"]=true,
                          ["SaveManager.lua"]=true, ["InterfaceManager.lua"]=true }
        assert(allowed[filename], "Unexpected module name")
        local url = BASE_URL .. filename
        local ok, source = pcall(function() return game:HttpGet(url, true) end)
        assert(ok and type(source)=="string" and #source > 0,
            "Cannot download "..filename.." from GitHub: "..tostring(source))
        local chunk, compileError = loadstring(source)
        assert(chunk, "Cannot compile "..filename..": "..tostring(compileError))
        return chunk()
    end

    local FluentLib = withUIThread(function() return remoteModule("Wave.lua") end)
    assert(FluentLib and type(FluentLib.CreateWindow)=="function", "Wave UI did not initialize")

    local SaveManager, InterfaceManager
    local fileApiAvailable = type(readfile)=="function" and type(writefile)=="function"
        and type(isfile)=="function" and type(isfolder)=="function"
        and type(makefolder)=="function" and type(listfiles)=="function"
        and type(delfile)=="function"
    if fileApiAvailable then
        SaveManager = withUIThread(function() return remoteModule("SaveManager.lua") end)
        InterfaceManager = withUIThread(function() return remoteModule("InterfaceManager.lua") end)
    else
        warn("[VELCORE GUI] File API unavailable; profile and interface persistence disabled")
    end
    local Definitions = remoteModule("Layout.lua")
    assert(type(Definitions)=="table", "Layout.lua must return an array of UI controls")

    local Window=withUIThread(function()
        return FluentLib:CreateWindow{
            Title="VELCORE", SubTitle="Wave UI | GUI only",
            TabWidth=150,Size=UDim2.fromOffset(860,560),Resize=true,
            MinSize=Vector2.new(560,420), Acrylic=false,
            Theme="Dark",MinimizeKey=Enum.KeyCode.RightShift
        }
    end)
    assert(Window,"Cannot create GUI window")
    local Tabs={}
    withUIThread(function()
        Window:Divider("Combat")
        Tabs.Aimbot=Window:CreateTab{Title="Aimbot",Icon="phosphor-target-bold"}
        Tabs.SilentRage=Window:CreateTab{Title="Silent / Rage",Icon="phosphor-skull-bold"}
        Tabs.Weapon=Window:CreateTab{Title="Weapon",Icon="phosphor-wrench-bold"}
        Window:Divider("Visuals")
        Tabs.Visuals=Window:CreateTab{Title="Visuals",Icon="phosphor-eye-bold"}
        Tabs.World=Window:CreateTab{Title="World",Icon="phosphor-sun-bold"}
        Window:Divider("Player")
        Tabs.Player=Window:CreateTab{Title="Player",Icon="phosphor-person-simple-run-bold"}
        Window:Divider("Misc")
        Tabs.Config=Window:CreateTab{Title="Config",Icon="settings"}
    end)
    for alias, actual in pairs({Silent="SilentRage",Rage="SilentRage",Trigger="SilentRage",Target="Aimbot",
        GunMods="Weapon",ESP="Visuals",Chams="Visuals",Crosshair="Visuals",Viewmodel="World",
        Camera="Player",Movement="Player",Debug="Config",Server="Config",Settings="Config"}) do
        Tabs[alias]=Tabs[actual]
    end

    local sections={}
    local function sectionOf(row)
        local key=table.concat({row.tab,row.side,row.section},"/")
        local s=sections[key]
        if not s then
            local tab=Tabs[row.tab]
            if not tab then warn("Unknown tab: "..row.tab);return nil end
            s=tab[row.side](tab,row.section)
            sections[key]=s
        end
        return s
    end
    local function buildRow(row)
        local section=sectionOf(row)
        if not section then return end
        local opt={Title=row.title,Description=row.desc,Content=row.content,Default=row.default,
                   Min=row.min,Max=row.max,Rounding=row.rounding,Values=row.values,Placeholder=row.placeholder}
        -- Game-related callbacks are deliberately removed.
        opt.Callback=function() end
        if row.kind=="Button" then
            if row.title=="Unload Script" then
                opt.Callback=function() pcall(function() FluentLib:Unload() end) end
            end
            section:CreateButton(opt)
        elseif row.kind=="Paragraph" then
            section:CreateParagraph(row.id,opt)
        elseif row.kind=="Colorpicker" then
            section:CreateColorpicker(row.id,opt)
        elseif row.kind=="Toggle" then
            section:CreateToggle(row.id,opt)
        elseif row.kind=="Slider" then
            section:CreateSlider(row.id,opt)
        elseif row.kind=="Dropdown" then
            section:CreateDropdown(row.id,opt)
        elseif row.kind=="Input" then
            section:CreateInput(row.id,opt)
        elseif row.kind=="Keybind" then
            section:CreateKeybind(row.id,opt)
        end
    end
    withUIThread(function()
        for i,row in ipairs(Definitions) do
            local ok,err=pcall(buildRow,row)
            if not ok then warn("[VELCORE GUI] menu item #"..i.." failed: "..tostring(err)) end
        end
        if SaveManager then
            pcall(function()
                SaveManager:SetLibrary(FluentLib)
                SaveManager:IgnoreThemeSettings()
                SaveManager:SetIgnoreIndexes({})
                SaveManager:SetFolder("VELCORE/UI")
                SaveManager:BuildConfigSection(Tabs.Config)
            end)
        end
        if InterfaceManager then
            pcall(function()
                InterfaceManager:SetLibrary(FluentLib)
                InterfaceManager:SetFolder("VELCORE")
                InterfaceManager:BuildInterfaceSection(Tabs.Config)
            end)
        end
        Window:SelectTab(1)
    end)
    global.__VELCORE_GUI_ONLY_DESTROY=function()
        pcall(function() FluentLib:Unload() end)
        global.__VELCORE_GUI_ONLY_DESTROY=nil
    end
    print("[VELCORE GUI] Menu built; gameplay callbacks intentionally disabled")

    return { Window = Window, Library = FluentLib, Tabs = Tabs, Controls = Definitions }
end
