
--[[
@module ntrip
@summary RTK客户端
@version 1.0.2
@date    2024.01.02
@author  wendal
@tag LUAT_USE_TAG
@demo ntrip
@usage
-- 具体用法请查阅demo
]]

local ntrip = {}

--[[
配置ntrip客户端
@api ntrip.setup(opts)
@table 配置项
@return boolean 配置成功返回true, 否则返回nil
@usage
-- 实例配置, 但如下账户信息肯定是过期的, 无法连接
    gnss_uart_id = 1 -- 按实际连接的uart端口号
    function gnss_write(buff)
        uart.write(gnss_uart_id, buff)
    end
    ntrip.setup({
        host = "106.55.71.75", -- 服务器域名或者ip
        port = 8002,           -- 端口
        user = "zhd556308",    -- 用户名
        password = "OZ469006", -- 密码
        mount = "/RTCM33_GRC", -- 挂载点
        https = false,         -- 是否使用https,一般不需要
        cb = gnss_write        -- 回调函数, 用于发送数据给gnss模块
    })
    ntrip.start()

    -- 以下是连接到GNSS/GPS模块的代码
    uart.setup(gnss_uart_id, 115200)
    uart.on(gnss_uart_id, "receive", function(id, len)
        local s = ""
        repeat
            s = uart.read(id, 1024)
            if #s > 0 then
                ntrip.gga(s)
                -- 以下的是调试代码, 用于打印GNSS模块的原始数据,非必须
                local rmc = s:find("$GNRMC,")
                if rmc and s:find("\r\n", rmc) then
                    log.info("uart", s:sub(rmc, s:find("\r\n", rmc) - 1))
                end
                local gga = s:find("$GNGGA,")
                if gga and s:find("\r\n", gga) then
                    log.info("uart", s:sub(gga, s:find("\r\n", gga) - 1))
                end
                -- 传递给GNSS库解析,非必须
                if libgnss then
                    libgnss.parse(s)
                end
            end
            if #s == len then
                break
            end
        until s == ""
    end)
]]
function ntrip.setup(user_opts) 
    ntrip.host = user_opts["host"]
    ntrip.port = user_opts["port"]
    ntrip.user = user_opts["user"]
    ntrip.password = user_opts["password"]
    ntrip.mount = user_opts["mount"]
    ntrip.cb = user_opts["cb"]
    ntrip.adapter = user_opts["adapter"]
    ntrip.https = user_opts["https"]
    return true
end

function ntrip.task()
    -- 准备好所需要的接收缓冲区
    local rxbuff = zbuff.create(1024)
    local netc = socket.create(ntrip.adapter, function(sc, event)
        -- log.info("ntrip", "socket event", sc, event)
        -- 收到数据, 或者连接断开
        if event == socket.EVENT then
            -- log.info("ntrip", "收到数据EVENT")
            while 1 do
                rxbuff:del()
                local succ, data_len = socket.rx(sc, rxbuff)
                
                if not succ then
                    ntrip.ready = nil
                    break
                end
                if data_len and data_len > 0 then
                    if rxbuff:query(0, 5) == "ERROR" and not rxbuff:query():find("ICY 200 OK") then
                        log.error("ntrip", "服务器返回错误", rxbuff:query())
                        ntrip.ready = nil
                        return
                    end
                    -- log.info("ntrip", "接收数据", data_len, rxbuff:query())
                    log.info("ntrip", "接收", succ, data_len)
                    if ntrip.cb then
                        ntrip.cb(rxbuff)
                        
                    end
                else
                    break
                end
            end
        end
        -- 连接成功
        if event == socket.ON_LINE then
            -- log.info("ntrip", "连接成功")
            -- 写入ntrip协议头
            local data = string.format("GET %s HTTP/1.0\r\nUser-Agent: NTRIP NtripClientPOSIX/1.50\r\nAccept: */*\r\n", ntrip.mount)
            data = data .. string.format("Host: %s:%d\r\n", ntrip.host, ntrip.port)
            data = data .. string.format("Connection: close\r\n")
            local auth = string.format("Authorization: Basic %s\r\n\r\n", (ntrip.user .. ":" .. ntrip.password):toBase64())
            -- log.info("ntrip", "发送请求头", data .. auth)
            if not socket.tx(sc, data .. auth) then
                log.error("ntrip", "发送auth失败")
                return
            end
            ntrip.ready = true
        end
    end)
    socket.config(netc, nil, nil, ntrip.https)
    ntrip.netc = netc
    while true do
        -- 连接服务器, 15秒超时
        log.info("ntrip", "开始连接服务器", ntrip.host, ntrip.port)
        if socket.connect(netc, ntrip.host, ntrip.port) then
            sys.wait(5000)
            while ntrip.ready do
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

--[[
启动Ntrip客户端
@api ntrip.start()
@return nil 总会成功
]]
function ntrip.start()
    if ntrip.task_id == nil then
        ntrip.task_id = sys.taskInit(ntrip.task)
    end
end

--[[
写入GGA数据
@api ntrip.gga(str, send_all)
@string GGA数据
@bool 是否发送全部数据,默认false,节省流量
@return nil 无返回值
]]
function ntrip.gga(str, send_all)
    if ntrip.netc and ntrip.ready then
        -- TODO 仅发送gga数据
        if send_all then
            socket.tx(ntrip.netc, str)
        else
            local gga = str:find("$GNGGA,")
            if gga and str:find("\r\n", gga) then
                local tmp = str:sub(gga, str:find("\r\n", gga) + 1)
                -- log.info("gga", tmp:toHex())
                socket.tx(ntrip.netc, tmp)
            end
        end
    end
end

return ntrip
