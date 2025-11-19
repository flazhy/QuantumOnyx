local loader = {}
loader.cache = {}
local moduleURLs = {
    Fire = "https://raw.githubusercontent.com/username/repo/branch/Fire.lua",
}

function loader.require(moduleName)
    if loader.cache[moduleName] then
        return loader.cache[moduleName]
    end

    local url = moduleURLs[moduleName]
    if not url then
        error("Module not found: " .. moduleName)
    end

    local code = game:HttpGet(url)
    local module = loadstring(code)()
    loader.cache[moduleName] = module
    return module
end

return loader
