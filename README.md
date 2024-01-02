# luatos-lib-ntrip

ntrip协议客户端 for LuatOS

## 介绍

本客户端基于socket库, 兼容所有LuatOS平台, 只要该平台实现socket库即可.

## 安装

本协议库使用纯lua编写, 所以不需要编译, 直接将源码拷贝到项目即可

## 使用

1. 请先确认ntrip账户, demo中的账户是演示用户, 通常已经过期
2. 参考demo中的代码, 初始化ntrip客户端, 传入ntrip账户信息
3. 调用ntrip.start()启动客户端

## 变更日志

[changelog](changelog.md)

## LIcense

[MIT License](https://opensource.org/licenses/MIT)
