-- VELCORE GUI-only GitHub Loader.
-- This package is configured for DezZzY1337/VELCORE-UI.
-- Raw GitHub downloads work only when the repository is public.
-- Upload all Lua files in this ZIP to the root of your GitHub repository.
local OWNER  = "DezZzY1337"
local REPO   = "VELCORE-UI"
local BRANCH = "main"

assert(OWNER ~= "", "Edit OWNER in Loader.lua")
local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(OWNER, REPO, BRANCH)

local ok, source = pcall(function()
    return game:HttpGet(BASE_URL .. "Menu.lua", true)
end)
assert(ok and type(source)=="string" and #source>0,
    "Cannot download Menu.lua: "..tostring(source).." (is your repo Public?)")

local main, errorMessage = loadstring(source)
assert(main, "Menu.lua syntax error: "..tostring(errorMessage))
local build = main()
assert(type(build)=="function", "Menu.lua must return a function(BASE_URL)")
return build(BASE_URL)
