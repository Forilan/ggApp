console = console or {}

local function console_main_loop()
    local stdin = socket.stdin()
    if not stdin then
        return
    end
    socket.lock(stdin)
    while true do
        local cmdline = socket.readline(stdin, "\n")
        if cmdline ~= "" then
            local func,err = load(cmdline)
            if not func then
                if cmdline == "reload" then
                    -- 内网测试允许reload所有模块
                    local skynet = require "skynet"
                    skynet.cache.clear()
                    for k,v in pairs(package.loaded) do
                        if string.startswith(k,"app.") then
                            package.loaded[k] = nil
                        end
                    end
                    print("reload ok")
                else
                    print(err)
                end
            else
                -- 防止控制台被阻塞住
                skynet.timeout(0,function ()
                    local ok,errmsg = xpcall(func,debug.traceback)
                    if not ok then
                        print(errmsg)
                    end
                end)
            end
        end
    end
    --socket.unlock(stdin)
end

function console.init()
    skynet.fork(console_main_loop)
end
return console
