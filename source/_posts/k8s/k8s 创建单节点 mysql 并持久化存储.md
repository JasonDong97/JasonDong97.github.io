---
title: k8s 创建单节点 mysql 并持久化存储
date: 2023-10-10 13:00:00
updated:
tags: k8s
categories: 容器/虚拟化
keywords: k8s
copyright: false
---

# k8s 创建单节点 mysql 并持久化存储

## 配置示例

1. 创建 pvc

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-data
  namespace: dev
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: csi-cephfs-sc-retain
  resources:
    requests:
      storage: 50Gi
```

2. mysql 的一些资源配置

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
  namespace: dev
data:
  rootPwd: "d72a3dpe"
  config.cnf: ""

---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.1.0
          imagePullPolicy: IfNotPresent
          args:
            - --character-set-server=utf8mb4
            - --collation-server=utf8mb4_unicode_ci
          ports:
            - containerPort: 3306
            - containerPort: 33060
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: rootPwd
          volumeMounts:
            - name: config-dir
              mountPath: /etc/mysql/conf.d
              readOnly: true
            - name: data-dir
              mountPath: /var/lib/mysql
      volumes:
        - name: config-dir
          configMap:
            name: mysql-config
            items:
              # name 是对应 secret 中的 key, path 是挂载 secret 后的子文件路径
              - key: config.cnf
                path: config.cnf
        - name: data-dir
          persistentVolumeClaim:
            claimName: mysql-data
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: dev
spec:
  selector:
    app: mysql
  ports:
    - name: mysql
      protocol: TCP
      port: 3306
      targetPort: 3306
  type: NodePort
```
