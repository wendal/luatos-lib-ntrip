
local ntrip = {}

-- 编写ntrip客户端

local opts = {}

function ntrip.setup(user_opts) 
    -- if user_opts["host"] == nil then
    --     log.error("ntrip", "必须设置host")
    --     return
    -- end
    -- if user_opts["port"] == nil then
    --     log.error("ntrip", "必须设置port")
    --     return
    -- end
    -- if user_opts["user"] == nil then
    --     log.error("ntrip", "必须设置用户名user")
    --     return
    -- end
    -- if user_opts["password"] == nil then
    --     log.error("ntrip", "必须设置密码password")
    --     return
    -- end
    -- if user_opts["mount"] == nil then
    --     log.error("ntrip", "必须设置挂载点mount")
    --     return
    -- end
    -- if user_opts["cb"] == nil then
    --     log.error("ntrip", "必须设置数据回调cb")
    --     return
    -- end
    opts = user_opts
    return true
end

function ntrip.task()

    -- 准备好所需要的接收缓冲区
    local rxbuff = zbuff.create(1024)
    local netc = socket.create(opts.adapter, function(sc, event)
        log.info("ntrip", "socket event", sc, event)
        -- 收到数据, 或者连接断开
        if event == socket.EVENT then
            log.info("ntrip", "收到数据EVENT")
            while 1 do
                local succ, data_len = socket.rx(sc, rxbuff)
                log.info("ntrip", "接收", succ, data_len)
                if not succ then
                    ntrip.keep = nil
                    break
                end
                if data_len and data_len > 0 then
                    log.info("ntrip", "接收数据", data_len, rxbuff:query())
                    if ntrip.cb then
                        ntrip.cb(rxbuff)
                        rxbuff.del()
                    end
                else
                    break
                end
            end
        end
        -- 连接成功
        if event == socket.ON_LINE then
            log.info("ntrip", "连接成功")
            -- 写入ntrip协议头
            local data = string.format("GET %s HTTP/1.0\r\nUser-Agent: NTRIP NtripClientPOSIX/1.50\r\nAccept: */*\r\n", opts.mount)
            data = data .. string.format("Host: %s:%d\r\n", opts.host, opts.port)
            data = data .. string.format("Connection: close\r\n")
            local auth = string.format("Authorization: Basic %s\r\n\r\n", (opts.user .. ":" .. opts.password):toBase64())
            log.info("ntrip", "发送请求头", data .. auth)
            if not socket.tx(sc, data .. auth) then
                log.error("ntrip", "发送auth失败")
                return
            end
            ntrip.keep = true
        end
    end)
    socket.config(netc, nil)
    ntrip.netc = netc
    while true do
        -- 连接服务器, 15秒超时
        log.info("ntrip", "开始连接服务器", opts.host, opts.port)
        if socket.connect(netc, opts.host, opts.port) then
            sys.wait(3000)
            while ntrip.keep do
                sys.wait(3000)
            end
        end
        log.info("ntrip", "连接失败")
        -- 能到这里, 要么服务器断开连接, 要么上报(tx)失败, 或者是主动退出
		socket.close(netc)
		-- log.info(rtos.meminfo("sys"))
		sys.wait(5000) -- 这是重连时长, 自行调整
    end
end


function ntrip.start()
    if ntrip.task_id == nil then
        ntrip.task_id = sys.taskInit(ntrip.task)
    end
end

function ntrip.gga(str)
    if ntrip.netc then
        -- TODO 仅发送gga数据
        socket.tx(ntrip.netc, str)
    end
end

return ntrip
