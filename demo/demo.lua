
local demo = {}
ntrip = require("ntrip")

local gnss_uart_id = 1

local function gnss_write(data)
    uart.tx(gnss_uart_id, data)
end

sys.taskInit(function()
    sys.waitUntil("net_ready")
    ntrip.setup({
        host = "106.55.71.75",
        port = 8002,
        user = "zhd556308",
        password = "OZ469006",
        mount = "/RTCM33_GRC",
        cb = gnss_write
    })
    ntrip.start()
    uart.setup(gnss_uart_id, 115200)
    uart.on(gnss_uart_id, "recvice", function(id, len)
        local s = ""
        repeat
            s = uart.read(id, len)
            if #s > 0 then
                log.info("uart", "receive", id, #s, s)
                ntrip.write(data)
            end
            if #s == len then
                break
            end
        until s == ""
        
    end)
    -- 

    -- 下面的代码是PC端模拟GPS数据
    if rtos.bsp() == "PC" then
        while 1 do
            sys.wait(2000)
            ntrip.gga("$GNGGA,021700.000,2324.4051578,N,11313.8597153,E,1,13,1.291,22.077,M,-6.122,M,,*6D\r\n")
        end
    end
end)

return demo
