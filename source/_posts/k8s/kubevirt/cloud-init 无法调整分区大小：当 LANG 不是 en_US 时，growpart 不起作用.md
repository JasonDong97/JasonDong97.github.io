---
title: cloud-init 无法调整分区大小：当 LANG 不是 en_US 时，growpart 不起作用
date: 2023-06-14
updated:
tags:
  - k8s
  - kubevirt
categories: 容器/虚拟化
keywords:
  - k8s
  - NetworkPolicy
copyright: false
---

## 起因

起初是想验证一下 kubevirt 动态扩展磁盘功能，发现在 kubevirt 资源定义上已经配置了 `ExpandDisks` 功能门，
且 cephfs 的动态存储的 pvc 也已经配置了 `allowVolumeExpansion: true`，但是在 kubevirt 虚拟机中的 cloud-init 执行 `growpart` 报错，发现并没有生效。
kubevirt 的版本是 0.56.0
cr 资源定义如下：

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
    name: kubevirt
    namespace: kubevirt
spec:
  ...
  configuration:
    developerConfiguration:
      featureGates:
      - LiveMigration
      - DataVolumes
      - ExpandDisks
      - GPU
    imagePullPolicy: IfNotPresent
    permittedHostDevices:
      pciHostDevices:
      - externalResourceProvider: true
        pciVendorSelector: 10DE:1DB4
        resourceName: nvidia.com/GV100GL_TESLA_V100_PCIE_16GB
      - externalResourceProvider: true
        pciVendorSelector: 10DE:20F1
        resourceName: nvidia.com/GA100_A100_PCIE_40GB
      - externalResourceProvider: true
        pciVendorSelector: 10DE:1EB8
        resourceName: nvidia.com/TU104GL_TESLA_T4
  imagePullPolicy: IfNotPresent
    ...

```

cephfs 的动态存储的 pvc 的定义如下：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: drug
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 120Gi
  storageClassName: csi-cephfs-sc-delete
```

## 排查

经过排查，发现kubevirt 虚拟机中的 cloud-init 服务有个日志报错：

![image-20230614205248005](https://jason-dong-blog-1259058668.cos.ap-nanjing.myqcloud.com/img/image-20230614205248005.png)

于是 google 了一下，在 Red Hat 官网中找到了答案：

![image-20230614205357544](https://jason-dong-blog-1259058668.cos.ap-nanjing.myqcloud.com/img/image-20230614205357544.png)

链接地址为：https://access.redhat.com/solutions/5775351

也就是说, 当虚拟机中的 `/etc/default/locale` 中的LANG 不为 `en_US`， 则 cloud-init 无法修改磁盘分区大小。。。。

发现果然 `/etc/default/locale` 的 LANG 属性值不是 `en_US`, 而是：

![image-20230614210156279](https://jason-dong-blog-1259058668.cos.ap-nanjing.myqcloud.com/img/image-20230614210156279.png)





于是我把 `LANG` 属性改为 `en_US.UTF-8`

![image-20230614210257832](https://jason-dong-blog-1259058668.cos.ap-nanjing.myqcloud.com/img/image-20230614210257832.png)

最后重启虚拟机，看了下 `cloud-init` 服务，发现已经正常了。 kubevirt 虚拟机磁盘也可以正常扩容了

![image-20230614210503666](https://jason-dong-blog-1259058668.cos.ap-nanjing.myqcloud.com/img/image-20230614210503666.png)

 
