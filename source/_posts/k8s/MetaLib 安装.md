---
title: MetalLB 安装
date: 2023-12-28
updated: 2023-12-28
categories: k8s
---
## MetalLB 安装

### 下载 release 版本

```bash
wget https://github.com/metallb/metallb/archive/refs/tags/v0.12.1.tar.gz
tar -zxvf v0.12.1.tar.gz
cd metallb-0.12.1/manifests

kubectl apply -f namespace.yaml
kubectl apply -f metallb.yaml

```

### 查看 pod 状态

```bash
kubectl -n metallb-system get pods 
```

### 查看 Deploy 状态

```bash
kubectl -n metallb-system get deploy
```

目前还没有宣布任何内容，因为我们没有提供ConfigMap，也没有提供负载均衡地址的服务。接下来要生成一个 Configmap 文件，为 Metallb 设置网址范围以及协议相关的选择和配置，这里以一个简单的二层配置为例。

修改ip地址池，从集群IP地址段中为MetalLB分配部分IP地址：

```bash
vim example-layer2-config.yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.72.200-192.168.72.250
---
kubectl apply -f example-layer2-config.yaml
```



### 创建后端应用和服务测试

```bash
kubectl apply -f tutorial-2.yaml 
```

查看yaml文件配置，包含了一个deployment和一个LoadBalancer类型的service，默认即可。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - name: http
          containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
```

### 查看service分配的EXTERNAL-IP

```bash
kubectl get service 
```

