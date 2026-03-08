---
# 【必需】文章标题
title: k8s 创建 ubuntu22.04 并暴露22端口
# 【必需】文章创建日期
date: 2023-06-12
# 【可选】文章更新日期
updated: 2023-06-12
# 【可选】文章标签
tags: k8s
# 【可选】文章分类
categories: 容器/虚拟化
# 【可选】文章关键字
keywords: Java 面试
# 【可选】文章描述
description: Java 精选
copyright: false
---

要在Kubernetes中创建一个Ubuntu 20.04容器暴露22端口并在后台永久运行，可以按照以下步骤进行操作：

## 创建一个名为`ubuntu-ssh`的Deployment：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ubuntu-ssh
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ubuntu-ssh
  template:
    metadata:
      labels:
        app: ubuntu-ssh
    spec:
      containers:
      - name: ubuntu-ssh
        image: ubuntu:20.04
        command: ["/bin/bash"]
        args: ["-c", "while true; do sleep 30; done"]
        ports:
        - containerPort: 22
```

这将创建一个名为`ubuntu-ssh`的Deployment，该Deployment将在单个Pod中运行一个名为`ubuntu-ssh`的容器。容器将使用`ubuntu:20.04`作为基本镜像，运行一个无限循环的`sleep`命令来保持容器运行，并暴露22端口。

## 创建一个名为`ubuntu-ssh`的Service：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ubuntu-ssh
spec:
  selector:
    app: ubuntu-ssh
  ports:
  - name: ssh
    protocol: TCP
    port: 22
    targetPort: 22
  type: ClusterIP
```



这将创建一个名为`ubuntu-ssh`的Service，并将其连接到Deployment。Service将使用`ClusterIP`类型，并在22端口上公开SSH服务。

## 在容器中安装SSH服务器：

```bash
kubectl exec -it <ubuntu-ssh-pod> -- /bin/bash
apt-get update
apt-get install -y openssh-server
```

这将在运行`ubuntu-ssh`容器的Pod中打开一个shell，并安装SSH服务器。

## 在容器中配置SSH服务器：

```bash
echo 'root:password' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    service ssh restart
```

这将设置root用户的密码为`password`，启用root用户的SSH登录，并重新启动SSH服务器。

现在，您已经在Kubernetes中创建了一个Ubuntu 20.04容器，该容器暴露22端口并在后台永久运行。您可以使用SSH客户端连接到该容器，例如：

```bash
ssh root@<service-ip>
```

其中，`<service-ip>`是在步骤2中创建的Service的IP地址。