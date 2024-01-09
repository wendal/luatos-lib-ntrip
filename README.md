# luatos-lib-ntrip

ntrip协议客户端 for LuatOS, 兼容千寻SDK/中移Cors/腾讯Cors/全国Cors等一众ntrip协议服务器

## 介绍

本客户端基于socket库, 兼容所有支持网络功能的LuatOS模块, 包括但不限于:

1. EC618系列, 如 Air780E/Air780EG/Air700E/Air780EX等等
2. EC718P系列, 如 Air780EP, Air780EPV等等
3. ESP32系列, 如 ESP32C3/ESP32S3等等
4. XT804系列, 如 Air601-12F
5. 需要搭配W5500联网的, 例如 Air101/Air103/Air105等

均需要**外接RTK模块**

均需要**外接RTK模块**

均需要**外接RTK模块**

截止2024.1.6号, 以上合宙相关的模块均没有内置RTK模块, 均需要外接

## 已测试过的RTK模块

1. 芯与物 UM626N

## 支持的平台

1. 千寻CORS, 直接给账户密码的方式
2. [中移Cors](https://pnt.10086.cn/v1/mallportal/#/home)
3. [腾讯Cors](https://lbs.qq.com/rtk/), 腾讯网络RTK
4. 全国Cors
5. 其他一切支持NTRIP协议的服务器, 支持加密和非加密端口

## 安装和使用

本协议库使用纯lua编写, 所以不需要编译, 将库文件的源码(ntrip.lua)拷贝到项目即可

1. 请先确认ntrip账户, demo中的账户是演示用户, 通常已经过期
2. 将支持RTK解算的GPS/GNSS设备连接到UART1(或者其他串口,修改gnss_uart_id值)
3. 如果是wifi设备, 请先配置ssid和password,连接wifi
4. 如果是Cat.1设备,请插好卡, 并确定能联网
5. 参考demo中的代码, 初始化ntrip客户端, 传入ntrip账户信息
6. 刷机, 并观察日志输出

## 目录说明

1. lib 库文件目录, 存放ntrip.lua库文件
2. demo 示例代码目录, 包含demo.lua等示例文件, 搭配lib目录组成完整luatos演示代码
3. fireware 固件目录, 包含验证过的固件文件, 方便测试, 但并非只能使用该固件

## 获取免费的ntrip账户

1. 微信小程序搜 `cors账户` , 部分商城支持1分钱购买/看广告获取 `30分钟` 的中移Cors账户
2. 广东地区(公众号gdcors)支持专网访问省内的Cors服务器, 专网卡10元/月

## 变更日志

[changelog](changelog.md)

## LIcense

[MIT License](https://opensource.org/licenses/MIT)
