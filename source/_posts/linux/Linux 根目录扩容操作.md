---
title: Linux 根目录扩容操作
tags: linux
categories: linux
date: 2023-12-29
---

# Linux 根目录扩容操作

## 需求描述

由于测试环境需要，虚拟机根目录需要扩容至120G。

## 查看本机磁盘环境

```bash
[root@localhost ~]# df -h
文件系统                 容量  已用  可用 已用% 挂载点
/dev/mapper/centos-root   35G  5.5G   30G   16% /
devtmpfs                 3.9G     0  3.9G    0% /dev
tmpfs                    3.9G     0  3.9G    0% /dev/shm
tmpfs                    3.9G   11M  3.9G    1% /run
tmpfs                    3.9G     0  3.9G    0% /sys/fs/cgroup
/dev/sda1               1014M  275M  740M   28% /boot
tmpfs                    783M   52K  783M    1% /run/user/0
[root@localhost ~]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0               2:0    1    4K  0 disk
sda               8:0    0  500G  0 disk
├─sda1            8:1    0    1G  0 part /boot
└─sda2            8:2    0   39G  0 part
  ├─centos-root 253:0    0   35G  0 lvm  /
  └─centos-swap 253:1    0    4G  0 lvm  [SWAP]
```

可以看到根目录总容量为35G, 设备sda 的总容量为500G。

## 添加磁盘分区

需要120G 容量，已有35G, 还需添加85G 容量。

```bash
[root@localhost ~]# fdisk /dev/sda
欢迎使用 fdisk (util-linux 2.23.2)。

更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。

命令(输入 m 获取帮助)：n
Partition type:
   p   primary (2 primary, 0 extended, 2 free)
   e   extended
Select (default p):
Using default response p
分区号 (3,4，默认 3)：
起始 扇区 (83886080-1048575999，默认为 83886080)：
将使用默认值 83886080
Last 扇区, +扇区 or +size{K,M,G} (83886080-1048575999，默认为 1048575999)：+85G
分区 3 已设置为 Linux 类型，大小设为 85 GiB

命令(输入 m 获取帮助)：w
The partition table has been altered!

Calling ioctl() to re-read partition table.

[root@localhost ~]# partprobe
```

然后查看分区是否创建：

```bash
[root@localhost ~]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0               2:0    1    4K  0 disk
sda               8:0    0  500G  0 disk
├─sda1            8:1    0    1G  0 part /boot
├─sda2            8:2    0   39G  0 part
│ ├─centos-root 253:0    0   35G  0 lvm  /
│ └─centos-swap 253:1    0    4G  0 lvm  [SWAP]
└─sda3            8:3    0   85G  0 part
sr0              11:0    1 1024M  0 rom
```

可以看到sda2 分区已创建。

## 开始扩容

### 创建物理卷

```bash
[root@localhost ~]# lvm
lvm> pvcreate /dev/sda3
  Physical volume "/dev/sda3" successfully created.
```

### 查看物理卷和卷组

```bash
lvm> pvdisplay
  --- Physical volume ---
  PV Name               /dev/sda2
  VG Name               centos
  PV Size               <39.00 GiB / not usable 3.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              9983
  Free PE               0
  Allocated PE          9983
  PV UUID               twmUZh-Vnqq-W5Pd-v3ms-6OkH-sSTs-nv8aA8

  "/dev/sda3" is a new physical volume of "85.00 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/sda3
  VG Name
  PV Size               85.00 GiB
  Allocatable           NO
  PE Size               0
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               vTD91f-b28E-GgL0-XsqI-ipQ5-rscT-GcQbT6

lvm> vgdisplay
  --- Volume group ---
  VG Name               centos
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <39.00 GiB
  PE Size               4.00 MiB
  Total PE              9983
  Alloc PE / Size       9983 / <39.00 GiB
  Free  PE / Size       0 / 0
  VG UUID               238Yz8-MEQa-NT6a-3aHC-J3TZ-mGux-e9vqPf
```

### 将物理卷加入到卷组

```bash
lvm> vgextend centos /dev/sda3
  Volume group "centos" successfully extended
lvm> vgdisplay
  --- Volume group ---
  VG Name               centos
  System ID
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               123.99 GiB
  PE Size               4.00 MiB
  Total PE              31742
  Alloc PE / Size       9983 / <39.00 GiB
  Free  PE / Size       21759 / <85.00 GiB
  VG UUID               238Yz8-MEQa-NT6a-3aHC-J3TZ-mGux-e9vqPf
```

可以看到卷组的Free size 增加了
将卷组剩余空间(刚添加的85G)添加到逻辑卷/dev/centos/root :

```bash
lvm> lvextend -l +100%FREE /dev/centos/root
  Size of logical volume centos/root changed from <35.00 GiB (8959 extents) to 119.99 GiB (30718 extents).
  Logical volume centos/root successfully resized.
```

### 同步到文件系统

之前只是对逻辑卷扩容，还要同步到文件系统，实现对根目录的扩容。

```bash
[root@localhost ~]# xfs_growfs /dev/centos/root
meta-data=/dev/mapper/centos-root isize=512    agcount=4, agsize=2293504 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=9174016, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=4479, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 9174016 to 31455232
```

debian/ubuntu 系统则使用以下命令对根目录扩容

```bash
resize2fs /dev/debian-vg/root
```

然后再查看挂载情况：

```bash
[root@localhost ~]# df -h
文件系统                 容量  已用  可用 已用% 挂载点
/dev/mapper/centos-root  120G  5.5G  115G    5% /
devtmpfs                 3.9G     0  3.9G    0% /dev
tmpfs                    3.9G     0  3.9G    0% /dev/shm
tmpfs                    3.9G   11M  3.9G    1% /run
tmpfs                    3.9G     0  3.9G    0% /sys/fs/cgroup
/dev/sda1               1014M  275M  740M   28% /boot
tmpfs                    783M   52K  783M    1% /run/user/0
```

可以发现有120G的空间挂载在根目录上。
over !!!
参考内容
<https://blog.csdn.net/harryxxxxx/article/details/81114613>
<https://blog.csdn.net/nimasike/article/details/53729499>
[
](https://blog.csdn.net/qq_24871519/article/details/86243571)
