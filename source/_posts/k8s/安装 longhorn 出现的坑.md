---
title: 安装 longhorn 出现的坑
date: 2023-11-03 13:00:00
updated:
tags: k8s
categories: 容器/虚拟化
keywords: k8s
copyright: false
---

# 安装 longhorn 出现的坑
## 安装 longhorn
```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/deploy/longhorn.yaml
```
观察安装情况
```bash
kubectl get pods \
--namespace longhorn-system \
--watch
```
## 出现的坑
![Alt text](/img/image.png)
longhorn-manager 一直处于 CrashLoopBackOff 状态，查看日志
```bash
kubectl logs longhorn-manager-6f8c6f4f5f-8q9q8 -n longhorn-system
```
发现是因为缺少 iscsiadm/open-iscsi
```bash
root@dev:~/k8s/kubevirt# kubectl logs -f longhorn-manager-4xgcq -n longhorn-system 
time="2023-11-03T05:41:17Z" level=fatal msg="Error starting manager: Failed environment check, please make sure you have iscsiadm/open-iscsi installed on the host: failed to execute: nsenter [--mount=/host/proc/53233/ns/mnt --net=/host/proc/53233/ns/net iscsiadm --version], output , stderr nsenter: failed to execute iscsiadm: No such file or directory\n: exit status 127"
```

## 解决办法
```bash
apt install open-iscsi -y
```
解决后，longhorn-manager 会自动重启，然后就可以正常使用了
再次查看状态
```bash
root@dev:~/k8s/kubevirt# kubectl get po -n longhorn-system -o wide
NAME                                                READY   STATUS    RESTARTS        AGE     IP              NODE   NOMINATED NODE   READINESS GATES
csi-attacher-759f487c5-46wrf                        1/1     Running   0               3m19s   10.233.113.63   dev    <none>           <none>
csi-attacher-759f487c5-bpdvw                        1/1     Running   0               3m19s   10.233.113.64   dev    <none>           <none>
csi-attacher-759f487c5-zmdhw                        1/1     Running   0               3m19s   10.233.113.62   dev    <none>           <none>
csi-provisioner-6df8547696-gxp2d                    1/1     Running   0               3m19s   10.233.113.66   dev    <none>           <none>
csi-provisioner-6df8547696-mljmk                    1/1     Running   0               3m19s   10.233.113.67   dev    <none>           <none>
csi-provisioner-6df8547696-x2ght                    1/1     Running   0               3m19s   10.233.113.65   dev    <none>           <none>
csi-resizer-6bf6dbcb4-6t6wt                         1/1     Running   0               3m19s   10.233.113.69   dev    <none>           <none>
csi-resizer-6bf6dbcb4-hcwvg                         1/1     Running   0               3m19s   10.233.113.70   dev    <none>           <none>
csi-resizer-6bf6dbcb4-shqnc                         1/1     Running   0               3m19s   10.233.113.68   dev    <none>           <none>
csi-snapshotter-69d7b7b84-5hspz                     1/1     Running   0               3m18s   10.233.113.72   dev    <none>           <none>
csi-snapshotter-69d7b7b84-892jt                     1/1     Running   0               3m18s   10.233.113.73   dev    <none>           <none>
csi-snapshotter-69d7b7b84-nv6rx                     1/1     Running   0               3m18s   10.233.113.71   dev    <none>           <none>
engine-image-ei-74783864-5b96k                      1/1     Running   0               3m27s   10.233.113.59   dev    <none>           <none>
instance-manager-9ef5cfc110a5361efb832fc0c716ace1   1/1     Running   0               3m27s   10.233.113.60   dev    <none>           <none>
longhorn-csi-plugin-xfmsg                           3/3     Running   0               3m18s   10.233.113.74   dev    <none>           <none>
longhorn-driver-deployer-794f4fb6bb-nwdgt           1/1     Running   0               15m     10.233.113.55   dev    <none>           <none>
longhorn-manager-4xgcq                              1/1     Running   7 (8m46s ago)   15m     10.233.113.56   dev    <none>           <none>
longhorn-ui-79fbb99d7d-hh9ml                        1/1     Running   0               15m     10.233.113.58   dev    <none>           <none>
longhorn-ui-79fbb99d7d-kd7mk                        1/1     Running   0               15m     10.233.113.57   dev    <none>           <none>
```
正常了