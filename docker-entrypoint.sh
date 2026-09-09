#!/bin/sh
set -e
# 先起 nginx 反代（后台），再前台跑 dsh：dsh 崩了容器就退出，交给 restart 策略自愈
nginx
exec pnpm dsh web --no-open