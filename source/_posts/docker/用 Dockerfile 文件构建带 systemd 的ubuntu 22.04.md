---
title: 用 Dockerfile 文件构建带 systemd 的ubuntu 22.04
date: 2023-10-20
updated:
tags: [Dockerfile]
categories: Docker
copyright: false
---

# 用 Dockerfile 文件构建带 systemd 的ubuntu 22.04

## Dockerfile 文件
```Dockerfile
FROM ubuntu:22.04
WORKDIR /root
# noninteractive 配置时不需要输入任何信息
ENV DEBIAN_FRONTEND="noninteractive"
# 配置时区
ENV TZ=Asia/Shanghai
# 配置apt源
RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
# 安装必要的软件
RUN apt update && apt install -y init locales
# 配置语言环境
RUN locale-gen en_US.UTF-8
# 配置 entrypoint 为 init, 是 init 可以作为 pid 1 运行, 并且可以启动 systemd
ENTRYPOINT ["/usr/sbin/init"]
```

## 构建镜像
```bash
docker build -t ubuntu:22.04-systemd .
```

## 运行容器
```bash
docker run -it --privileged --name ubuntu -h ubuntu ubuntu:22.04-systemd
```
