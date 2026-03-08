---
title: "Ceph集群部署"
tags: ceph
categories: Ceph 学习
toc: true
cover:
date: 2021-10-01 16:00:00
updated: 2021-10-01 16:00:00
---

# 一、Ceph 简介

> 一个 Ceph 存储集群需要至少一个 Ceph 监视器、Ceph 管理器和 Ceph OSD(对象存储守护进程)。在运行 Ceph 文件系统客户端时，也需要 Ceph 元数据服务器。

<!-- more -->

- **Monitors**:

  - Ceph 监视器(`ceph-mon`)维护着展示集群状态的各种图表，包括监视器图、管理器图、OSD 图、MDS 图和 CRUSH 图。这些图是 Ceph 守护进程相互协调所必需的关键集群状态。
  - 监视器还负责管理守护进程和客户端之间的身份验证。为了实现冗余和高可用性，通常需要至少三个监视器。

- **Managers**: [Ceph Manager](https://docs.ceph.com/en/latest/glossary/#term-Ceph-Manager)守护程序(`ceph-mgr`)

  - 负责跟踪运行时指标和 Ceph 群集的当前状态，包括存储利用率、当前性能指标和系统负载。
  - Ceph Manager 守护程序还托管基于 python 的模块来管理和公开 Ceph 群集信息，包括基于 Web 的[Ceph 仪表板和](https://docs.ceph.com/en/latest/mgr/dashboard/#mgr-dashboard) [REST API](https://docs.ceph.com/en/latest/mgr/restful)。高可用性通常需要至少两个管理器。

- **OSDs**: [Ceph OSD](https://docs.ceph.com/en/latest/glossary/#term-Ceph-OSD) (object storage daemon, `ceph-osd`)存储数据，处理数据复制，恢复，重新平衡，并提供一些监视信息到 Ceph 监视器和管理器,通过检查其他 Ceph OSD 守护进程检测信号.冗余和高可用性通常需要至少 3 个 Ceph OSD。
- **MDSs**: [Ceph 元数据服务器](https://docs.ceph.com/en/latest/glossary/#term-Ceph-Metadata-Server)（MDS, `ceph-mds`）代表[Ceph 文件系统](https://docs.ceph.com/en/latest/glossary/#term-Ceph-File-System)存储元数据（即 Ceph 块设备和 Ceph 对象存储不使用 MDS）。Ceph 元数据服务器允许 POSIX 文件系统用户执行基本命令 (如`ls`, `find`, `etc`等)，而不会给 Ceph 存储群集带来巨大负担。

> Ceph 将数据存储为逻辑存储池中的对象。使用[CRUSH 算法](https://docs.ceph.com/en/latest/glossary/#term-CRUSH)，Ceph 计算哪个放置组应包含对象，并进一步计算哪个 Ceph OSD 守护程序应存储该放置组。CRUSH 算法使 Ceph 存储群集能够动态扩展、重新平衡和恢复。

参考链接：

- [https://mp.weixin.qq.com/s/TWXPPk7hE1D4AGsHg7CIMg](https://mp.weixin.qq.com/s/TWXPPk7hE1D4AGsHg7CIMg)
- [https://www.jianshu.com/p/cc3ece850433](https://www.jianshu.com/p/cc3ece850433)
- [https://mp.weixin.qq.com/s/QXRdyYKSKIa1aLNI8dOGcQ](https://mp.weixin.qq.com/s/QXRdyYKSKIa1aLNI8dOGcQ)
- [https://blog.csdn.net/xiaoquqi/article/details/43055031](https://blog.csdn.net/xiaoquqi/article/details/43055031)

# 二、Cephadm 部署集群

简单，简述，详细参考：[https://docs.ceph.com/en/latest/cephadm/#cephadm](https://docs.ceph.com/en/latest/cephadm/#cephadm)

## 1.环境规划

| 主机名 | 内网 IP         | 操作系统 | 角色                | 配置                         |
| ------ | --------------- | -------- | ------------------- | ---------------------------- |
| ceph1  | 192.168.200.128 | Debian11 | cephadm,mon,mgr,osd | 2C,2G,20G 系统盘，20G 数据盘 |
| ceph2  | 192.168.200.131 | Debian11 | cephadm,mon         | 2C,2G,20G 系统盘，20G 数据盘 |
| ceph3  | 192.168.200.132 | Debian11 | cephadm,mon         | 2C,2G,20G 系统盘，20G 数据盘 |

> 典型的 Ceph 集群有三个或五个监视器守护程序，分布在不同的主机上。如果群集中有五个或更多节点，我们建议部署五个监视器。

当 Ceph 知道 mon 应该使用什么 IP 子网时，它可以随着群集的增长（或收缩）自动部署和缩放 mon。默认情况下，Ceph 假定其他 mon 使用与第一个 mon 的 IP 相同的子网。

在单个子网的情况下，如果向集群中添加主机，默认最多只会添加 5 个 mon 如果有特定的 IP 子网给 mon 使用，可以使用 CIDR 格式配置该子网。

## 2.前置(所有节点)

> [https://docs.ceph.com/en/pacific/cephadm/install/](https://docs.ceph.com/en/pacific/cephadm/install/)

各节点配置 hosts

```conf
10.200.10.31 ceph-pro-1-10-200-10-31
10.200.10.32 ceph-pro-2-10-200-10-32
10.200.10.33 ceph-pro-3-10-200-10-33
10.200.10.34 ceph-pro-4-10-200-10-34
10.200.10.35 ceph-pro-5-10-200-10-35
```

## 3.安装 CEPHADM(所有节点)

```bash
#下载cephadm
curl --remote-name --location https://hub.shutcm.cf/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm
#设置源
./cephadm add-repo --release pacific
sed -i 's#https://download.ceph.com#https://mirrors.aliyun.com/ceph#g' /etc/apt/sources.list.d/ceph.list
apt-get update
#安装cephadm命令
./cephadm install
#确认在PATH中
which cephadm
rm -fr cephadm
#安装ceph命令
cephadm install ceph-common
```

## 4.引导新群集(第一台)

> 创建新的 Ceph 集群的第一步是在 Ceph 集群的第一台主机上运行 cephadm bootstrap 命令，运行此命令的操作将创建 Ceph 集群的第一个“监视程序守护程序”。

而该监视程序守护程序需要一个 IP 地址，必须将 Ceph 集群的第一个主机的 IP 地址传递给 ceph bootstrap 命令。

```bash
cephadm bootstrap --mon-ip 10.200.10.31
#设置addr
#ceph orch host set-addr ceph1 192.168.200.128
#检查
ceph orch host ls
ceph -s
```

此命令将会：

```
1) 在本地主机上为新集群创建监视和管理器守护程序
2) 为Ceph集群生成一个新的SSH密钥，并将其添加到root用户的/root/.ssh/authorized_keys文件中
3) 将最小配置文件写入/etc/ceph/ceph.conf
4) 将client.admin管理特权密钥写入/etc/ceph/ceph.client.admin.keyring
5) 将公钥写入/etc/ceph/ceph.pub
```

## 5.向群集添加主机

> 在解析主机名等方面，cephadm 的要求非常低, 通过以下命令可以明确 IP 与主机名之间的解析：ceph orch host add

**注意**：添加主机时会自动创建 mon 服务，先按照 禁用监视器自动部署( 5.4 (1) ) 或 调整默认值监视器数量 (5.2 节)，再添加主机。

在新主机 root 用户的 authorized_keys 文件中安装集群的公共 SSH 密钥

```bash
#ssh-copy-id -f -i /etc/ceph/ceph.pub root@*<new-host>*
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-pro-1-10-200-10-31
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-pro-2-10-200-10-32
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-pro-3-10-200-10-33
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-pro-4-10-200-10-34
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-pro-5-10-200-10-35
```

添加方式两种：

- 命令方式添加

```bash
#ceph orch host add *<newhost>* [*<ip>*] [*<label1> ...*]
ceph orch host add ceph-pro-2-10-200-10-32 10.200.10.32 --labels _admin
```

- yaml 方式添加

`host.yml`

```yaml
---
service_type: host
addr: 192.168.200.131
hostname: ceph2
labels:
  - mon
---
service_type: host
addr: 192.168.200.132
hostname: ceph3
labels:
  - mon
```

## 3.检查状态

```bash
ceph orch host ls
ceph -s
```

## 6.部署 OSD

**[https://docs.ceph.com/en/pacific/cephadm/services/osd/#](https://docs.ceph.com/en/pacific/cephadm/services/osd/#)**

> 当有新的 osd 加入集群或者移除了 osd，就会把状态上报给 Monitor，Monitor 知道了 osd map 发生了变化就会触发 rebalancing，确保 pg 能够平滑的移动到各个 osd 上，以 pg 为整体进行数据重平衡，重平衡的过程中可能会影响性能，一次性加入的 osd 越多，数据 rebalancing 就越频繁。

> 当在做 rebalance 的时候，每个 osd 都会按照 osd_max_backfills 指定数量的线程来同步，如果该数值比较大，同步会比较快，但是会影响部分性能；为了避免 rebalance 带来的性能影响，可以对 rebalance 进行关闭；添加完 osd 后再打开。

### 1).rebalance 关闭

```bash
# 设置标志位
ceph osd set norebalance

# 关闭数据填充
ceph osd set nobackfill

# 查看集群状态
ceph -s
  cluster:
    id:     87cdd3b2-987b-11eb-989e-000c29b12ae1
    health: HEALTH_WARN
            nobackfill,norebalance flag(s) set  # 有此信息
```

### 2).rebalance 开启

```bash
#开启数据填充
ceph osd unset nobackfill
#开启rebalance
ceph osd unset norebalance
# 查看集群状态
ceph -s
  cluster:
    id:     87cdd3b2-987b-11eb-989e-000c29b12ae1
    health: HEALTH_OK
```

### 3).列出节点可用设备

```bash
#ceph orch device ls [--wide]
ceph orch device ls --wide
```

如果满足以下所有条件，则认为存储设备可用

```
1) 设备必须没有分区
2) 设备不得具有任何LVM状态
3) 设备不得挂载
4) 设备不得包含文件系统
5) 设备不得包含Ceph BlueStore OSD
6) 设备必须大于5 GB
```

### 4).创建 osd

```bash
#需要至少 3 个 Ceph OSD 以实现冗余和高可用性
ceph orch daemon add osd ceph-pro-1-10-200-10-31:/dev/sdb
ceph orch daemon add osd ceph-pro-2-10-200-10-32:/dev/sdb
ceph orch daemon add osd ceph-pro-3-10-200-10-33:/dev/sdb
```

## 7.集群高可用

```bash
#需要至少三个监视器才能实现冗余和高可用性
ceph orch apply mon 3
# 部署mon到指定节点
ceph orch host label add *<host>* mon
#至少需要两个管理器才能实现高可用性
ceph orch apply mgr 3
#
```

## 8.CephFS 部署

## 9.部署 RGW

[https://docs.ceph.com/en/pacific/cephadm/services/rgw/](https://docs.ceph.com/en/pacific/cephadm/services/rgw/)

# 三、运维

[https://www.cnblogs.com/royaljames/p/9807532.html](https://www.cnblogs.com/royaljames/p/9807532.html)

## 1.向群集添加主机

```bash
#1.在新主机的根用户文件中安装群集的公共 SSH 密钥
ssh-copy-id -f -i /etc/ceph/ceph.pub root@host2
#2.告诉 Ceph 新节点是群集的一部分：
ceph orch host add host2
```

## 2.部署其他监视器(monitor)

> 典型的 Ceph 群集具有分布在不同主机的三个或五个监视器守护程序。如果群集中有五个或更多节点，我们建议部署五个监视器。

当 Ceph 知道监视器应该使用什么 IP 子网时，它可以随着群集的增长（或收缩）自动部署和缩放监视器。默认情况下，Ceph 假定其他监视器应使用与第一个监视器的 IP 相同的子网。

如果您的 Ceph 监视器（或整个群集）住在单个子网中，则在向群集添加新主机时，默认情况下，cephadm 会自动添加多达 5 个监视器。无需进一步步骤。

```bash
#如果有特定的 IP 子网应该由监视器使用，您可以用CIDR格式（例如 ） 配置该子网，Cephadm 仅在配置的子网中配置了 IP 的主机上部署新的监视器守护程序。
ceph config set mon public_network 10.1.2.0/24
#如果要调整 5 个监视器的默认值：
ceph orch apply mon *<number-of-monitors>*
#若要在一组特定的主机上部署监视器，请确保在此列表中包括第一个（引导）主机。
ceph orch apply mon *<host1,host2,host3,...>*
#您可以通过使用主机标签来控制监视器运行的主机。要将标签设置为相应的主机，请：mon
ceph orch host label add *<hostname>* mon
#要查看当前主机和标签：
ceph orch host ls
#例如：
# ceph orch host label add host1 mon
# ceph orch host label add host2 mon
# ceph orch host label add host3 mon
# ceph orch host ls
HOST   ADDR   LABELS  STATUS
host1         mon
host2         mon
host3         mon
host4
host5
#告诉 cephadm 根据标签部署监视器：
ceph orch apply mon label:mon
#您可以显式指定每个监视器的 IP 地址或 CIDR 网络，并控制其放置位置。要禁用自动监视器部署：
ceph orch apply mon --unmanaged
#要部署每个附加监视器：
ceph orch daemon add mon *<host1:ip-or-network1> [<host1:ip-or-network-2>...]*
#例如，要在使用 IP 地址上部署第二个监视器，在网络上部署第三个监视器
# ceph orch apply mon --unmanaged
# ceph orch daemon add mon newhost1:10.1.2.123
# ceph orch daemon add mon newhost2:10.1.2.0/24

#若要确保监视器应用于这三台主机中的每一个主机，请运行以下命令：
ceph orch apply mon "host1,host2,host3"
```

# 使用 YAML 规范

```bash
ceph orch apply -i file.yaml
```

```yaml
service_type: mon
placement:
  hosts:
    - host1
    - host2
    - host3
```

## 3.部署 OSD

### 1.所有群集主机上的存储设备清单可以显示

```bash
ceph orch device ls
```

- 设备必须没有分区。
- 设备不得具有任何 LVM 状态。
- 不得安装设备。
- 设备不能包含文件系统。
- 设备不得包含 Ceph BlueStore OSD。
- 设备必须大于 5 GB。

### 2.创建新 OSD 的方法

```bash
# 1.告诉 Ceph 使用任何可用和未使用的存储设备：
ceph orch apply osd --all-available-devices
# 2.从特定主机上的特定设备创建 OSD：ceph orch daemon add osd *<host>*:*<device-path>*
ceph orch daemon add osd host1:/dev/sdb
# 3.使用OSD 服务规范描述设备，根据设备属性、此类设备类型（SSD 或 HDD）、设备型号名称、大小或设备存在的主机使用：
ceph orch apply osd -i spec.yml
```

## 4.部署 MDS

使用 CephFS 文件系统需要一个或多个 MDS 守护程序。如果使用较新的接口创建新文件系统，则会自动创建这些接口。有关详细信息，请参阅 FS 卷和子卷。

```bash
ceph orch apply mds *<fs-name>* --placement="*<num-daemons>* [*<host1>* ...]"
```

## 5.部署 RGW

## 6.管理 Monitor map

### 1).多 Monitor 同步机制

> 在生产环境建议最少三节点 monitor，以确保 cluster map 的高可用性和冗余性,monitor 节点不应该过多甚至操作 9 节点的行为,会导致数据读写时间下降，影响系统集群的性能。

- monitor 使用 paxos 算法作为集群状态上达成一致的机制。paxos 是一种分布式一致性算法。每当 monitor 修改 map 时，它会通过 paxos 发送更新到其他 monitor。Ceph 只有在大多数 monitor 就更新达成一致时提交 map 的新版本。
- cluster map 的更新操作需要 Paxos 确认，但是读操作不经由 Paxos，而是直接访问本地的 kv 存储。

### 2).Monitor 选举机制

- 多个 monitor 之间需要建立仲裁并选择出一个 leader，其他节点则作为工作节点（peon）。
- 在选举完成并确定 leader 之后，leader 将从所有其他 monitor 请求最新的 map epoc，以确保 leader 具有集群的最新视图。
- 要维护 monitor 集群的正常工作，必须有超过半数的节点正常。

### 3).Monitor 租约

- 在 Monitor 建立仲裁后，leader 开始分发短期的租约到所有的 monitors。让它们能够分发 cluster map 到 OSD 和 client。
- Monitor 租约默认每 3s 续期一次。
- 当 peon monitor 没有确认它收到租约时，leader 假定该 monitor 异常，它会召集新的选举以建立仲裁。
- 如果 peon monitor 的租约到期后没有收到 leader 的续期，它会假定 leader 异常，并会召集新的选举。
- 所以如果生产环境中存在多个 monitor 时候某个节点的超时会猝发节点的重新选举导致 client 无法第一时间拿到最新的 crushmap 图像也就无法去对应的 osd 上的 pv 写入数据了。

### 4).常用的 monitor 管理

```bash
#打印monitor map信息
ceph mon dump

#将monitor map导出为一个二进制文件
ceph mon getmap -o ./monmap

#打印导出的二进制文件的内容
monmaptool --print ./monmap

#修改二进制文件，从monmap删除某个monitor
monmaptool ./monmap --rm <id>

#修改二进制文件，往monmap中添加一个monitor
monmaptool ./monmap --add <id> <ip:port>

#导入一个二进制文件，在导入之前，需要先停止monitor
ceph-mon -i <id> --inject-monmap ./monmap
```

## 7.管理 OSD Map

- 每当 OSD 加入或离开集群时，Ceph 都会更新 OSD map。
- OSD 不使用 leader 来管理 OSD map，它们会在自身之间传播同步 map。OSD 会利用 OSD map epoch 标记它们交换的每一条信息，当 OSD 检测到自己已落后时，它会使用其对等 OSD 执行 map 更新。
- 在大型集群中 OSD map 更新会非常频繁，节点会执行递增 map 更新。
- Ceph 也会利用 epoch 来标记 OSD 和 client 之间的消息。当 client 连接到 OSD 时 OSD 会检查 epoch。如果发现 epoch 不匹配，则 OSD 会以正确的 epoch 响应，以便客户端可以更新其 OSD map。
- OSD 定期向 monitor 报告自己的状态，OSD 之间会交换心跳，以便检测对等点的故障，并报告给 monitor。
- leader monitor 发现 OSD 故障时，它会更新 map，递增 epoch，并使用 Paxos 更新协议来通知其他 monitor，同时撤销租约，并发布新的租约，以使 monitor 以分发最新的 OSD map。

### 1).OSD 状态解读

- 1.正常状态的 OSD 为 up 且 in
- 2.当 OSD 故障时，守护进程 offline，在 5 分钟内，集群仍会将其标记为 up 和 in，这是为了防止网络抖动
- 3.如果 5 分钟内仍未恢复，则会标记为 down 和 out。此时该 OSD 上的 PG 开始迁移。这个 5 分钟的时间间隔可以通过 mon_osd_down_out_interval 配置项修改
- 4.当故障的 OSD 重新上线以后，会触发新的数据再平衡
- 5.当集群有 noout 标志位时，则 osd 下线不会导致数据恢复
- 6.OSD 每隔 6s 会互相验证状态。并每隔 120s 向 mon 报告一次状态。

### 2).OSD map 命令

```bash
ceph osd dump
ceph osd getmap -o binfile
osdmaptool --print binfile
osdmaptool --export-crush crushbinfile binfile
osdmaptool --import-crush crushbinfile binfile
osdmaptool --test-map-pg pgid binfile
```

### 3.)OSD 的状态

- OSD 运行状态

  - up
  - down
  - out
  - in

- OSD 容量状态

  - nearfull
  - full

常用指令

```bash
#显示OSD状态
ceph osd stat

#报告osd使用量
ceph osd df

#查找指定osd位置
ceph osd find
```

### 4.)OSD 容量

- 当集群容量达到 mon_osd_nearfull_ratio 的值时，集群会进入 HEALTH_WARN 状态。这是为了在达到 full_ratio 之前，提醒添加 OSD。默认设置为 0.85，即 85%
- 当集群容量达到 mon_osd_full_ratio 的值时，集群将停止写入，但允许读取。集群会进入到 HEALTH_ERR 状态。默认为 0.95，即 95%。这是为了防止当一个或多个 OSD 故障时仍留有余地能重平衡数据

设置方法：

```bash
ceph osd set-full-ratio 0.95
ceph osd set-nearfull-ratio 0.85
ceph osd dump
```

### 5).OSD 状态参数

```bash
# osd之间传递心跳的间隔时间
osd_heartbeat_interval

# 一个osd多久没心跳，就会被集群认为它down了
osd_heartbeat_grace

# 确定一个osd状态为down的最少报告来源osd数
mon_osd_min_down_reporters

# 一个OSD必须重复报告一个osd状态为down的次数
mon_osd_min_down_reports

# 当osd停止响应多长时间，将其标记为down和out
mon_osd_down_out_interval

# monitor宣布失败osd为down前的等待时间
mon_osd_report_timeout

# 一个新的osd加入集群时，等待多长时间，开始向monitor报告
osd_mon_report_interval_min

# monitor允许osd报告的最大间隔，超时就认为它down了
osd_mon_report_interval_max

# osd向monitor报告心跳的时间
osd_mon_heartbeat_interval
```

## 8.管理 PG

### 1).管理文件到 PG 映射

test 对象所在 pg id 为 10.35，存储在三个 osd 上，分别为 osd.2、osd.1 和 osd.8，其中 osd.2 为 primary osd

```bash
rados -p test put test /etc/ceph/ceph.conf
ceph osd map test test
    osdmap e201 pool 'test' (10) object 'test' -> pg 10.40e8aab5 (10.35) -> up ([2,1,8], p2) acting ([2,1,8], p2)

#处于up状态的osd会一直留在PG的up set和acting set中，一旦主osd down，它首先会从up set中移除
#然后从acting set中移除，之后从OSD将被升级为主。Ceph会将故障OSD上的PG恢复到一个新OSD上
#然后再将这个新OSD加入到up和acting set中来维持集群的高可用性
```

### 2).管理 struck 状态的 PG

- 如果 PG 长时间（mon_pg_stuck_threshold，默认为 300s）出现如下状态时，MON 会将该 PG 标记为 stuck：

  - inactive：pg 有 peering 问题
  - unclean：pg 在故障恢复时遇到问题
  - stale：pg 没有任何 OSD 报告，可能其所有的 OSD 都是 down 和 out
  - undersized：pg 没有充足的 osd 来存储它应具有的副本数

- 默认情况下，Ceph 会自动执行恢复，但如果未能自动恢复，则集群状态会一直处于 HEALTH_WARN 或者 HEALTH_ERR

- 如果特定 PG 的所有 osd 都是 down 和 out 状态，则 PG 会被标记为 stale。要解决这一情况，其中一个 OSD 必须要重生，且具有可用的 PG 副本，否则 PG 不可用

- Ceph 可以声明 osd 或 PG 已丢失，这也就意味着数据丢失。需要说明的是，osd 的运行离不开 journal，如果 journal 丢失，则 osd 停止

### 3).struck 状态操作

```bash
# 检查处于stuck状态的pg
ceph pg dump_stuck
# 检查导致pg一致阻塞在peering状态的osd
ceph osd blocked-by
# 检查某个pg的状态
ceph pg dump all|grep pgid
# 声明pg丢失
ceph pg pgid mark_unfound_lost revert|delete
# 声明osd丢失（需要osd状态为down且out）
ceph osd lost osdid --yes-i-really-mean-it
```

### 4).手动控制 PG 的 Primary OSD

可以通过手动修改 osd 的权重以提升 特定 OSD 被选为 PG Primary OSD 的概率，避免将速度慢的磁盘用作 primary osd。

需要先在配置文件中配置如下参数：

```bash
mon_osd_allow_primary_affinity = true
```

### 5).调整权重示例

```bash
1. 查看现在有多少PG的主OSD是osd.0
ceph pg dump |grep active+clean |egrep "\[0," |wc -l

2. 修改osd.0的权重
ceph osd primary-affinity osd.0 0  # 权重范围从0.0到1.0

3. 再次查看现在有多少PG的主OSD是osd.0
ceph pg dump |grep active+clean |egrep "\[0," |wc -l
```

## 9.Pool(存储池)管理

[https://blog.csdn.net/weixin_42440345/article/details/81118964](https://blog.csdn.net/weixin_42440345/article/details/81118964)

### PG 和 PGP 的区别

[https://www.cnblogs.com/zphj1987/p/13575377.html](https://www.cnblogs.com/zphj1987/p/13575377.html)

PG 是指定存储池存储对象的目录有多少个，PGP 是存储池 PG 的 OSD 分布组合个数

PG 的增加会引起 PG 内的数据进行分裂，分裂到相同的 OSD 上新生成的 PG 当中

PGP 的增加会引起部分 PG 的分布进行变化，但是不会引起 PG 内对象的变动

### 4.)限制 pool 配置更改

```bash
#禁止池被删除
osd_pool_default_flag_nodelete

#禁止池的pg_num和pgp_num被修改
osd_pool_default_flag_nopgchange

#禁止修改池的size和min_size
osd_pool_default_flag_nosizechange
```

### 1.查看 pool

```bash
#查看所有pool
ceph osd lspools
#获取集群内所有POOL的概况信息,集群内POOL的个数、对应的POOL id、POOL名称、副本数、最小副本数，ruleset及POOL snap等信息
ceph osd pool ls detail
#查看POOL的统计信息
```

### 2.创建 pool

```bash
#创建一个副本类型的POOL
ceph osd pool create {pool-name} {pg-num} [{pgp-num}] [{pgp-num}] [replicated] [ruleset]
#举例：
ceph osd pool create rbd  32 32
#创建一个纠删码类型的POOL
ceph osd pool create {pool-name} {pg-num} {pgp-num} erasure [erasure-code-profile] [ruleset]
```

在`{}`内的参数为必选项,`[]`内的参数均设有默认值,如果没有更改设计,可以不添加。

参数的含义如下:

- **pool-name**: POOL 的名字；必须添加。
- **pg-num**: POOL 拥有的 PG 总数；必须添加。
- **pgp-num**: POOL 拥有的 PGP 总数；非必须添加。默认与 pg-num 相同。
- **replicated|erasure**: POOL 类型；非必须添加。如不指定为 erasure,则默认为 replicated 类型。
- **ruleset**: POOL 所用的 CRUSH 规则 ID。非必须添加。默认为 0,若需指定其他 ruleset,需确保 ruleset 必须存在。
- **erasure-code-profile**: 仅用于纠删码类型的 POOL。指定纠删码配置框架,此配置必须已由 osd erasure-code-profile set 定义

这里强制选择 pg_num 和 pgp_num，因为 ceph 集群不能自动计算 pg 数量。下面有一些官方建议的 pg 使用数量：

- 小于 5 个 osd 设置 pg_num 为 128
- 5 到 10 个 osd 设置 pg_num 为 512
- 10 到 50 个 osd 设置 pg_num 为 1024
- 如果超过 50 个 osd 你需要自己明白权衡点，并且能自行计算 pg_num 的数量

pg_num 通用计算方法:

(OSDs \* 100)

Total PGs =  ------------

pool size

### 3.修改 pool

```bash
ceph osd pool set {pool-name} {key} {value}
size：设置存储池中的对象副本数，详情参见设置对象副本数。仅适用于副本存储池。
min_size：设置 I/O 需要的最小副本数，详情参见设置对象副本数。仅适用于副本存储池。
pg_num：计算数据分布时的有效 PG 数。只能大于当前 PG 数。
pgp_num：计算数据分布时使用的有效 PGP 数量。小于等于存储池的 PG 数。
hashpspool：给指定存储池设置/取消 HASHPSPOOL 标志。
target_max_bytes：达到 max_bytes 阀值时会触发 Ceph 冲洗或驱逐对象。
target_max_objects：达到 max_objects 阀值时会触发 Ceph 冲洗或驱逐对象。
scrub_min_interval：在负载低时，洗刷存储池的最小间隔秒数。如果是 0 ，就按照配置文件里的 osd_scrub_min_interval 。
scrub_max_interval：不管集群负载如何，都要洗刷存储池的最大间隔秒数。如果是 0 ，就按照配置文件里的 osd_scrub_max_interval 。
deep_scrub_interval：“深度”洗刷存储池的间隔秒数。如果是 0 ，就按照配置文件里的 osd_deep_scrub_interval 。
```

### 4.删除存储池

```bash
ceph osd pool delete {pool-name} [{pool-name} --yes-i-really-really-mean-it]
```

### 5.重命名存储池

```bash
ceph osd pool rename {current-pool-name} {new-pool-name}
```

### 6.查看存储池统计信息

```bash
rados df
```

### 7.给存储池做快照

```bash
ceph osd pool mksnap {pool-name} {snap-name}
```

### 8.删除存储池的快照

```bash
ceph osd pool rmsnap {pool-name} {snap-name}
```

### 9.获取存储池选项值

```bash
ceph osd pool get {pool-name} {key}
```

### 10.获取对象副本数

```bash
ceph osd dump | grep 'replicated size'
```

### 11.设置存储池配额

```bash
命令格式：
# ceph osd pool set-quota {pool-name} [max_objects {obj-count}] [max_bytes {bytes}]
命令举例：
# ceph osd pool set-quota rbd max_objects 10000
```

## 10.自定义 Crush Map

> crush map 决定了客户端数据最终写入的 osd 的位置，在某些情况下存在 hdd 和 ssd 两种盘想让某些数据写入到指定的 osd 中这个时候就是需要去人为的手动编译 crush-map，编辑要修改的部分，再导入集群中达到我们特定的目的

### 1).Crush 的放置策略

- Ceph 使用 CRUSH 算法（Controlled Replication Under Scalable Hashing 可扩展哈希下的受控复制）来计算哪些 OSD 存放哪些对象
- 对象分配到 PG 中，CRUSH 决定这些 PG 使用哪些 OSD 来存储对象。理想情况下，CRUSH 会将数据均匀的分布到存储中
- 当添加新 OSD 或者现有的 OSD 出现故障时，Ceph 使用 CRUSH 在活跃的 OSD 上重平衡数据 CRUSH map 是 CRUSH 算法的中央配置机制，可通过调整 CRUSHmap 来优化数据存放位置默认情况下，CRUSH 将一个对象的多个副本放置到不同主机上的 0SD 中。可以配置 CRUSH map 和 CRUSH rules，使一个对象的多个副本放置到不同房间或者不同机柜的主机上的 0SD 中。
- 也可以将 SSD 磁盘分配给需要高速存储的池

### 2).编译与翻译和更新

```bash
#导出CRUSH map
ceph osd getcrushmap -o ./crushmap.bin
#解译CRUSH map
crushtool -d ./crushmap.bin ./crushmap.txt
#修改后的CRUSH map重新编译
crushtool -c ./crushmap.txt-o ./crushmap-new.bin
#更新CRUSH map
ceph osd setcrushmap-i./crushmap-new.bin
#查询crush map的内容（返回json）
ceph osd crush dump
```

例子

```bash
root default {
    id-1           # do not change unnecessarily
    id-2 class hdd #do not change unnecessarily
    #weiqht 0.166
    alg straw2
    hash 0#rjenkins1
    item rackl weight 0.055
    item rack2 weiqht 0.055
    item rack3 weight 0.055
}

#rules
rule replicated rule{
    id 0
    type replicated
    min size 1
    max size 10
    step take default  #只要是应用这个rule的都把数据写入到defaults下
    step chooseleaf firstn 0 type host  #定义故障的故障域为物理集机器级别（rack为机柜级别）
    step emit #结尾符号
}
```

## 11.admin sockets 管理守护进程

- 通过 admin sockets，管理员可以直接与守护进程交互。如查看和修改守护进程的配置参数。
- 守护进程的 socket 文件一般是/var/run/ceph/cluster-cluster−type.$id.asok
- 基于 admin sockets 的操作：

```bash
ceph daemon $type.$id command
#或者
ceph --admin-daemon /var/run/ceph/$cluster-$type.$id.asok command
#常用command如下：
help
config get parameter
config set parameter
config show
perf dump
```

## 12.用户管理

> Ceph 把数据以对象的形式存于各存储池中。Ceph 用户必须具有访问存储池的权限才能够读写数据。另外，Ceph 用户必须具有执行权限才能够使用 Ceph 的管理命令。

### 1、查看用户信息

```bash
查看所有用户信息
# ceph auth list
获取所有用户的key与权限相关信息
# ceph auth get client.admin
如果只需要某个用户的key信息，可以使用pring-key子命令
# ceph auth print-key client.admin
```

### 2、添加用户

```bash
# ceph auth add client.john mon 'allow r' osd 'allow rw pool=liverpool'
# ceph auth get-or-create client.paul mon 'allow r' osd 'allow rw pool=liverpool'
# ceph auth get-or-create client.george mon 'allow r' osd 'allow rw pool=liverpool' -o george.keyring
# ceph auth get-or-create-key client.ringo mon 'allow r' osd 'allow rw pool=liverpool' -o ringo.key
```

### 3、修改用户权限

```bash
# ceph auth caps client.john mon 'allow r' osd 'allow rw pool=liverpool'
# ceph auth caps client.paul mon 'allow rw' osd 'allow rwx pool=liverpool'
# ceph auth caps client.brian-manager mon 'allow *' osd 'allow *'
# ceph auth caps client.ringo mon ' ' osd ' '
```

### 4、删除用户

```bash
# ceph auth del {TYPE}.{ID}
其中， {TYPE} 是 client，osd，mon 或 mds 的其中一种。{ID} 是用户的名字或守护进程的 ID 。
```

## 13.增加和删除 Monitor

> 一个集群可以只有一个 monitor，推荐生产环境至少部署 3 个。 Ceph 使用 Paxos 算法的一个变种对各种 map 、以及其它对集群来说至关重要的信息达成共识。建议（但不是强制）部署奇数个 monitor 。Ceph 需要 mon 中的大多数在运行并能够互相通信，比如单个 mon，或 2 个中的 2 个，3 个中的 2 个，4 个中的 3 个等。初始部署时，建议部署 3 个 monitor。后续如果要增加，请一次增加 2 个.

### 1、新增一个 monitor

```bash
# ceph-deploy mon create $hostname
注意：执行ceph-deploy之前要进入之前安装时候配置的目录。/my-cluster
```

### 2、删除 Monitor

```bash
# ceph-deploy mon destroy $hostname
注意： 确保你删除某个 Mon 后，其余 Mon 仍能达成一致。如果不可能，删除它之前可能需要先增加一个。
```

# 四、集群监控管理

## 1.集群整体运行状态

```bash
[root@cephnode01 ~]# ceph -s
cluster:
    id:     8230a918-a0de-4784-9ab8-cd2a2b8671d0
    health: HEALTH_WARN
            application not enabled on 1 pool(s)

  services:
    mon: 3 daemons, quorum cephnode01,cephnode02,cephnode03 (age 27h)
    mgr: cephnode01(active, since 53m), standbys: cephnode03, cephnode02
    osd: 4 osds: 4 up (since 27h), 4 in (since 19h)
    rgw: 1 daemon active (cephnode01)

  data:
    pools:   6 pools, 96 pgs
    objects: 235 objects, 3.6 KiB
    usage:   4.0 GiB used, 56 GiB / 60 GiB avail
    pgs:     96 active+clean

    id：集群ID
    health：集群运行状态，这里有一个警告，说明是有问题，意思是pg数大于pgp数，通常此数值相等。
    mon：Monitors运行状态。
    osd：OSDs运行状态。
    mgr：Managers运行状态。
    mds：Metadatas运行状态。
    pools：存储池与PGs的数量。
    objects：存储对象的数量。
    usage：存储的理论用量。
    pgs：PGs的运行状态

~]$ ceph -w
~]$ ceph health detail
```

## 2.PG 状态

> 查看 pg 状态查看通常使用下面两个命令即可，dump 可以查看更详细信息

```bash
~]$ ceph pg dump
~]$ ceph pg stat
```

## 3.Pool 状态

```bash
~]$ ceph osd pool stats
~]$ ceph osd pool stats
```

## 4.OSD 状态

```bash
~]$ ceph osd stat
~]$ ceph osd dump
~]$ ceph osd tree
~]$ ceph osd df
```

## 5.Monitor 状态和查看仲裁状态

```bash
~]$ ceph mon stat
~]$ ceph mon dump
~]$ ceph quorum_status
```

## 6.集群空间用量

```bash
~]$ ceph df
~]$ ceph df detail
```

# 五、集群配置管理(临时和全局，服务平滑重启)

> 有时候需要更改服务的配置，但不想重启服务，或者是临时修改。这时候就可以使用 tell 和 daemon 子命令来完成此需求。

## 1.查看运行配置

```bash
命令格式：
# ceph daemon {daemon-type}.{id} config show

命令举例：
# ceph daemon osd.0 config show
```

## 2.tell 子命令格式

> 使用 tell 的方式适合对整个集群进行设置，使用 \* 号进行匹配，就可以对整个集群的角色进行设置。而出现节点异常无法设置时候，只会在命令行当中进行报错，不太便于查找。

```bash
命令格式：
# ceph tell {daemon-type}.{daemon id or *} injectargs --{name}={value} [--{name}={value}]
命令举例：
# ceph tell osd.0 injectargs --debug-osd 20 --debug-ms 1
```

- daemon-type：为要操作的对象类型如 osd、mon、mds 等。
- daemon id：该对象的名称，osd 通常为 0、1 等，mon 为 ceph -s 显示的名称，这里可以输入\*表示全部。
- injectargs：表示参数注入，后面必须跟一个参数，也可以跟多个

## 3.daemon 子命令

- 使用 daemon 进行设置的方式就是一个个的去设置，这样可以比较好的反馈，此方法是需要在设置的角色所在的主机上进行设置。

```bash
命令格式：
# ceph daemon {daemon-type}.{id} config set {name}={value}
命令举例：
# ceph daemon mon.ceph-monitor-1 config set mon_allow_pool_delete false
```

## 4.集群操作

- 命令包含 start、restart、status

```bash
#1.启动所有守护进程
systemctl start ceph.target

#2.按类型启动守护进程
systemctl start ceph-mgr.target
systemctl start ceph-osd@id
systemctl start ceph-mon.target
systemctl start ceph-mds.target
systemctl start ceph-radosgw.target
```

## 5.添加和删除 OSD

### 1).添加 OSD

- 纵向扩容(会导致数据的重分布)
- 生产环境下最好的做法就是不要一次性添加大量的 osd，最好逐步添加等待数据同步后再进行添加操作

  - 当影响生产数据时候临时可以停止同步：ceph osd set [nobackfill|norebalance],unset 取消对应的参数

```bash
#1.格式化磁盘
ceph-volume lvm zap /dev/sd<id>

#2.进入到ceph-deploy执行目录/my-cluster，添加OSD
ceph-deploy osd create --data /dev/sd<id> $hostname
```

### 2).删除 OSD

- 如果机器有盘坏了可以使用 dmdsg 查看坏盘
- 存在一种情况就是某 osd 的写入延迟大盘有坏道很大可能会拖垮 ceph 集群：

  - ceph osd tree: 查看当前集群的 osd 状态
  - ceph osd perf: 查看当前的 OSD 的延迟

- 当某一快 osd 踢出集群时候立即做数据重分布(默认 10 分钟)

```bash
1、调整osd的crush weight为 0
ceph osd crush reweight osd.<ID> 0.0

2、将osd进程stop
systemctl stop ceph-osd@<ID>

3、将osd设置out(将会出发数据重分布)
ceph osd out <ID>

4、从crushmap中踢出osd
# 查看运行视图的osd状态
ceph osd crush dump|less
ceph osd crush rm <osd>.id

5、从tree树中删除osd
ceph osd rm <osd>.id

6、(选用)立即执行删除OSD中数据
ceph osd purge osd.<ID> --yes-i-really-mean-it

7、卸载磁盘
umount /var/lib/ceph/osd/ceph-？

8.从认证中删除磁盘对应的key
# 查看认证的列表
ceph auth list
ceph auth rm <osd>.id
```

## 6.扩容 PG

- 扩容大小取跟它接近的 2 的 N 次方
- 在更改 pool 的 PG 数量时，需同时更改 PGP 的数量。PGP 是为了管理 placement 而存在的专门的 PG，它和 PG 的数量应该保持一致。如果你增加 pool 的 pg_num，就需要同时增加 pgp_num，保持它们大小一致，这样集群才能正常 rebalancing。

```bash
ceph osd pool set {pool-name} pg_num 128
ceph osd pool set {pool-name} pgp_num 128
```

# 六、调优

## 1.系统层面调优

- 选择正确的 CPU 和内存。OSD、MON 和 MDS 节点具有不同的 CPU 和内存需求

  - mon 的需求和 osd 的总个数有关需要的是计算力
  - mds 对 CPU 和内存要求很高，会将大量的元数据缓存到自己的内存中，存储元数据的尽量的使用 ssd
  - osd 最低要求 1H2G 的配置例如：24 块硬盘最少是 24H36G,磁盘方面必须高 I/O 有多好上多好

- 尽可能关闭 NUMA
- 规划好存储节点的数据以及各节点的磁盘要求（不考虑钱忽略）
- 磁盘的选择尽可能在成本、吞吐量和延迟之间找到良好的平衡
- journal 日志应该使用 SSD
- 如果交换机支持（MTU 9000），则启用巨型帧(减少数据的分片)，前提是 ceph 在一个单独的网络环境中切有独立交换机。
- 启用 ntp。Ceph 对时间敏感,集群网络至少 10GB 带宽

### 1).系统调优工具

- 使用 tuned-admin 工具，它可帮助系统管理员针对不同的工作负载进行系统调优
- tuned-admin 使用的 profile 默认存放在/usr/lib/tuned/目录中，可以参考其模板来自定义 profile
- 对于 ceph 而言，network-latency 可以改进全局系统延迟，network-throughput 可以改进全局系统吞吐量,如果两个都开启可以使用 Custom 自定义模式

```bash
# 列出现有可用的profile
tuned-adm list

# 查看当前生效的profile
tuned-adm active

# 使用指定的profile
tuned-admin profile profile-name

# 禁用所有的profile
tuned-admin off
```

### 2).I/O 调度算法

- noop：电梯算法，实现了一个简单的 FIFO 队列。基于 SSD 的磁盘，推荐使用这种调度方式
- Deadline：截止时间调度算法，尽力为请求提供有保障的延迟。对于 Ceph，基于 sata 或者 sas 的驱动器，应该首选这种调度方式
- cfq：完全公平队列，适合有许多进程同时读取和写入大小不等的请求的磁盘，也是默认的通用调度算法

```bash
#查看当前系统支持的调度算法：
    dmesg|grep -I scheduler

#查看指定磁盘使用的调度算法：
    cat /sys/block/磁盘设备号/queue/scheduler

#修改调度算法
    echo "deadline" > /sys/block/vdb/queue/scheduler
    vim /etc/default/grub
        GRUB_CMDLINE_LINUX="elevator=deadline numa=off"
```

### 3).网络 IO 子系统调优

- 用于集群的网络建议尽可能使用 10Gb 网络

以下参数用于缓冲区内存管理

```bash
#设置OS接收缓冲区的内存大小，第一个值告知内核一个TCP socket的最小缓冲区空间，第二值为默认缓冲区空间，第三个值是最大缓冲区空间
net.ipv4.tcp_wmem

#设置Os发送缓冲区的内存大小
net.ipv4.tcp_rmem

#定义TCP stack如何反应内存使用情况
net.ipv4.tcp_mem
```

- 交换机启用大型帧

> 默认情况下，以太网最大传输数据包大小为 1500 字节。为提高吞吐量并减少处理开销，一种策略是将以太网网络配置为允许设备发送和接收更大的巨型帧。

- 在使用巨型帧的要谨慎，因为需要硬件支持，且全部以太网口配置为相同的巨型帧 MTU 大小。

### 4).虚拟内存调优

设置较低的比率会导致高频但用时短的写操作，这适合 Ceph 等 I/O 密集型应用。设置较高的比率会导致低频但用时长的写操作，这会产生较小的系统开销，但可能会造成应用响应时间变长

```bash
#脏内存占总系统总内存的百分比，达到此比率时内核会开始在后台写出数据
vm.dirty_background_ratio

#脏内存占总系统总内存的百分比，达到此比率时写入进程停滞，而系统会将内存页清空到后端存储
vm.dirty_ratio

#控制交换分区的使用,生产中建议完全关闭，会拖慢系统运行速度
vm.swappiness

#系统尽力保持可用状态的RAM大小。在一个RAM大于48G的系统上，建议设置为4G
vm.min_free_kbytes
```

## 2.Ceph 本身调优

### 1).最佳实践

- MON 的性能对集群总体性能至关重要，应用部署于专用节点，为确保正确仲裁，数量应为奇数个
- 在 OSD 节点上，操作系统、OSD 数据、OSD 日志应当位于独立的磁盘上，以确保满意的吞吐量
- 在集群安装后，需要监控集群、排除故障并维护，尽管 Ceph 具有自愈功能。如果发生性能问题，首先在磁盘、网络和硬件层面上调查。然后逐步转向 RADOS 块设备和 Ceph 对象网关

### 2).影响 I/O 的 6 大操作

- 业务数据写入
- 数据恢复
- 数据回填
- 数据重平衡
- 数据一致性校验
- 快照清理

### 3).OSD 生产建议

- 更快的日志性能可以改进响应时间，建议将单独的低延迟 SSD 或者 NVMe 设备用于 OSD 日志。
- 多个日志可以共享同一 SSD，以降低存储基础架构的成本。但是不能将过多 OSD 日志放在同一设备上。
- 建议每个 SATA OSD 设备不超过 6 个 OSD 日志，每个 NVMe 设备不超过 12 个 OSD 日志。
- 需要说明的是，当用于托管日志的 SSD 或者 NVMe 设备故障时，使用它托管其日志的所有 OSD 也都变得不可用

### 4).硬件建议

- 将一个 raid1 磁盘用于 ceph 操作系统
- 每个 OSD 一块硬盘，尽量将 SSD 或者 NVMe 用于日志
- 使用多个 10Gb 网卡，每个网络一个双链路绑定（建议生产环境 2 个网卡 4 个光模块，2 个万兆口做为数据的交换，2 个万兆口做业务流量）
- 每个 OSD 预留 1 个 CPU,每个逻辑核心 1GHz，分配 16GB 内存，外加每个 OSD 2G 内存

### 5).RBD 生产建议

- 块设备上的工作负载通常是 I/O 密集型负载，例如在 OpenStack 中虚拟机上运行数据库。
- 对于 RBD,OSD 日志应当位于 SSD 或者 NVMe 设备上
- 对后端存储，可以使用不同的存储设备以提供不同级别的服务

### 6).对象网关生产建议

- Ceph 对象网关工作负载通常是吞吐密集型负载。但是其 bucket 索引池为 I/O 密集型工作负载模式。应当将这个池存储在 SSD 设备上
- Ceph 对象网关为每个存储桶维护一个索引。Ceph 将这一索引存储在 RADOS 对象中。当存储桶存储数量巨大的对象时（超过 100000 个），索引性能会降低，因为只有一个 RADOS 对象参与所有索引操作。
- Ceph 可以在多个 RADOS 对象或分片中保存大型索引。可以在 ceph.conf 中设置 rgw_override_bucket_index_max_shards 配置参数来启用该功能。此参数的建议值是存储桶中预计对象数量除以 10000
- 当索引变大，Ceph 通常需要重新划分存储桶。rgw_dynamic_resharding 配置控制该功能，默认为 true

### 7).CephFS 生产建议

- 存放目录结构和其他索引的元数据池可能会成为 CephFS 的瓶颈。因此，应该将 SSD 设备用于这个池
- 每个 MDS 维护一个内存中缓存 ，用于索引节点等不同类型的项目。Ceph 使用 mds_cache_memory_limit 配置参数限制这一缓存的大小。其默认值为 1GB，可以在需要时调整，得不得超过系统总内存数

### 8).Monitor 生产建议

- 最好为每个 MON 一个独立的服务器/虚拟机
- 小型和中型集群，使用 10000RPM 的磁盘，大型集群使用 SSD
- CPU 使用方面：使用一个多核 CPU，最少 16G 内存，最好不要和 osd 存放在同一个服务器上

### 9).将 OSD 日志迁移到 SSD

强烈建议生产中千万不要这么干，一定在集群初始化的时候就定制好

```bash
#集群中设置标志位停止指定的osd使用
ceph osd set noout

#停止osd的进程
systemctl stop ceph-osd@3

#将所有的日志做刷盘处理，刷盘到osd中
ceph-osd -i 3 --flush-journal

#删除该osd现有的日志
rm -f /var/lib/ceph/osd/ceph-3/journal

#/dev/sdc1为SSD盘创建一个软连接
ln -s /dev/sdc1 /var/lib/ceph/osd/ceph-3/journal

#刷出日志
ceph-osd -i 3 --mkjournal

#启动osd
systemctl start ceph-osd@3

#移除标志位
ceph osd unset noout
```

### 10).存储池中 PG 的计算方法

- 通常，计算一个池中应该有多少个归置组的计算方法 = 100 \* OSDs(个数) / size(副本数)

- 一种比较通用的取值规则：

  - 少于 5 个 OSD 时可把 pg_num 设置为 128
  - OSD 数量在 5 到 10 个时，可把 pg_num 设置为 512
  - OSD 数量在 10 到 50 个时，可把 pg_num 设置为 4096
  - OSD 数量大于 50 时，建议自行计算

- 自行计算 pg_num 聚会时的工具

  - pgcalc：[https://ceph.com/pgcalc/](https://ceph.com/pgcalc/)
  - cephpgc：[https://access.redhat.com/labs/cephpgc/](https://access.redhat.com/labs/cephpgc/)

- 注意：在实际的生产环境中我们很难去预估需要多少个 pool，每个 pool 所占用的数据大小的百分百。所以正常情况下需要在特定的情况选择动态扩缩容 pg 的大小

### 11).PG 与 PGP

> 通常而言，PG 与 PGP 是相同的当我们为一个池增加 PG 时，PG 会开始分裂，这个时候，OSD 上的数据开始移动到新的 PG，但总体而言，此时，数据还是在一个 OSD 的不同 PG 中迁移而我们一旦同时增加了 PGP，则 PG 开始在多个 OSD 上重平衡，这时会出现跨 OSD 的数据迁移

- ceph osd pool create poolName PgNum PgpNum
- 当变动 pg 数量只是针对当前的特定池中的 osd 发生变动影响范围只是一个池的 pg 平衡
- 正常情况下一个 osd 最多承载 100 个 pg
- 当 pgp 发生大变动的时候会导致原本这个池中的 pg 变动导致池中 osd，过载或者有很大剩余性能，ceph 集群会将过大的性能均衡到各个性能使用小的 osd 上，这个时候就会发生数据的大规模迁移，大量的 i/O 写入会占有网络带宽会严重影响使用中的 pg 性能导致阻塞发生。
- 建议的做法是将 pg_num 直接设置为希望作为最终值的 PG 数量，而 PGP 的数量应当慢慢增加，以确保集群不会因为一段时间内的大量数据重平衡而导致的性能下降

### 12).Ceph 生产网络建议

- 尽可能使用 10Gb 网络带宽以上的万兆带宽(内网)
- 尽可能使用不同的 cluster 网络和 public 网络
- 做好必要的网络设备监控防止网络过载

### 13).OSD 和数据一致性校验

> 清理会影响 ceph 集群性能，但建议不要禁用此功能，因为它能提供完数据的完整性

- 清理：检查对象的存在性、校验和以及大小
- 深度清理：检查对象的存在性和大小，重新计算并验证对象的校验和。(最好不开严重影响性能)

```bash
#清理调优参数
osd_scrub_begin_hour =                    #取值范围0-24
osd_scrub_end_hour = end_hbegin_hour our  #取值范围0-24
osd_scrub_load_threshold                  #当系统负载低于多少的时候可以清理，默认为0.5
osd_scrub_min_interval                    #多久清理一次，默认是一天一次（前提是系统负载低于上一个参数的设定）
osd_scrub_interval_randomize_ratio        #在清理的时候，随机延迟的值，默认是0.5
osd_scrub_max_interval                    #清理的最大间隔时间，默认是一周（如果一周内没清理过，这次就必须清理，不管负载是多少）
osd_scrub_priority                        #清理的优先级，默认是5
osd_deep_scrub_interal                    #深度清理的时间间隔，默认是一周
osd_scrub_sleep                           #当有磁盘读取时，则暂停清理，增加此值可减缓清理的速度以降低对客户端的影响，默认为0,范围0-1
```

```bash
#显示最近发生的清理和深度清理
ceph pg dump all  # 查看LAST_SCRUB和LAST_DEEP_SCRUB
#-将清理调度到特定的pg
ceph pg scrub pg-id
#将深度清理调度到特定的pg
ceph pg deep-scrub pg-id
#为设定的池设定清理参数
ceph osd pool set <pool-name> <parameter> <value>
    noscrub # 不清理，默认为false
    nodeep-scrub # 不深度清理，默认为false
    scrub_min_interval # 如果设置为0，则应用全局配置osd_scrub_min_interval
    scrub_max_interval # 如果设置为0，则应用全局配置osd_scrub_max_interval
    deep_scrub_interval # 如果设置为0，则应用全局配置osd_scrub_interval
```

### 14).快照的生产建议

- 快照在池级别和 RBD 级别上提供。当快照被移除时，ceph 会以异步操作的形式删除快照数据，称为快照修剪进程
- 为减轻快照修剪进程会影响集群总体性能。可以通过配置`osd_snap_trim_sleep`来在有客户端读写操作的时候暂停修剪，参数的值范围是`0`到`1`
- 快照修剪的优先级通过使用`osd_snap_trim_priority`参数控制，默认为`5`

### 15).保护数据和 osd

- 需要控制回填和恢复操作，以限制这些操作的影响
- 回填发生于新的 osd 加入集群时，或者 osd 死机并且 ceph 将其 pg 分配到其他 osd 时。在这种场景中，ceph 必须要在可用的 osd 之间复制对象副本
- 恢复发生于新的 osd 已有数据时，如出现短暂停机。在这种情形下，ceph 会简单的重放 pg 日志

  - 管理回填和恢复操作的配置项

```bash
#用于限制每个osd上用于回填的并发操作数，默认为1
osd_max_backfills

#用于限制每个osd上用于恢复的并发操作数，默认为3
osd_recovery_max_active

#恢复操作的优先级，默认为3
osd_recovery_op_priority
```

### 16).OSD 数据存储后端

> BlueStore 管理一个，两个或（在某些情况下）三个存储设备。在最简单的情况下，BlueStore 使用单个（主）存储设备。存储设备通常作为一个整体使用，BlueStore 直接占用完整设备。该主设备通常由数据目录中的块符号链接标识。数据目录挂载成一个 tmpfs，它将填充（在启动时或 ceph-volume 激活它时）所有常用的 OSD 文件，其中包含有关 OSD 的信息，例如：其标识符，它所属的集群，以及它的私钥。还可以使用两个额外的设备部署 BlueStore

- WAL 设备（在数据目录中标识为 block.wal）可用于 BlueStore 的内部日志或预写日志。只有设备比主设备快（例如，当它在 SSD 上并且主设备是 HDD 时），使用 WAL 设备是有用的。
- 数据库设备（在数据目录中标识为 block.db）可用于存储 BlueStore 的内部元数据。 BlueStore（或者更确切地说，嵌入式 RocksDB）将在数据库设备上放置尽可能多的元数据以提高性能。如果数据库设备填满，元数据将写到主设备。同样，数据库设备要比主设备更快，则提供数据库设备是有帮助的。
- 如果只有少量快速存储可用（例如，小于 1GB），我们建议将其用作 WAL 设备。如果还有更多，配置数据库设备会更有意义。 BlueStore 日志将始终放在可用的最快设备上，因此使用数据库设备将提供与 WAL 设备相同的优势，同时还允许在其中存储其他元数据。
- 正常 L 版本推荐使用 filestore，M 版本可以考虑使用 bluestore
- 推荐优化文章：[https://www.cnblogs.com/luxiaodai/p/10006036.html#\_lab2_1_9](https://www.cnblogs.com/luxiaodai/p/10006036.html#_lab2_1_9)

### 17).关于性能测试

- 推荐使用 fio 参考阿里云文档：[https://help.aliyun.com/document_detail/95501.html?spm=a2c4g.11174283.6.659.38b44da2KZr2Sn](https://help.aliyun.com/document_detail/95501.html?spm=a2c4g.11174283.6.659.38b44da2KZr2Sn)
- dd

```bash
echo 3 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=/var/lib/ceph/osd/ceph-0/test.img bs=4M count=1024 oflag=direct
dd if=/var/lib/ceph/osd/ceph-0/test.img of=/dev/null bs=4M count=1024 oflag=direct
```

- rados bench 性能测试

```bash
rados bench -p <pool_name> <seconds> <write|seq|rand> -b <block size> -t --no-cleanup
    pool_name 测试所针对的池
    seconds 测试所持续的时间，以秒为单位
    <write|seq|rand> 操作模式，分别是写、顺序读、随机读
    -b <block_size> 块大小，默认是4M
    -t 读/写的并行数，默认为16
    --no-cleanup 表示测试完成后不删除测试用的数据。在做读测试之前，需要使用该参数来运行一遍写测试来产生测试数据，在全部测试完成以后，可以行rados -p <pool_name> cleanup来清理所有测试数据

#示例：
rados bench -p rbd 10 write --no-cleanup
rados bench -p rbd 10 seq
```

- rbd bench 性能测试

```bash
rbd bench -p <pool_name> <image_name> --io-type <write|read> --io-size <size> --io-threads <num> --io-total <size> --io-pattern <seq|rand>
    --io-type 测试类型，读/写
    --io-size 字节数，默认4096
    --io-threads 线程数，默认16
    --io-total  读/写的总大小，默认1GB
    --io-pattern  读/写的方式，顺序还是随机

#示例：
https://edenmal.moe/post/2017/Ceph-rbd-bench-Commands/
```

## 3.设置集群的标志

**flag 操作**

- 只能对整个集群操作，不能针对单个 osd

  - ceph osd set
  - ceph osd unset

```bash
#示例：
ceph osd set nodown
ceph osd unset nodown
ceph -s
```

| 标志名称     | 含义用法详解                                                                                                                                                     |
| :----------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| noup         | OSD 启动时，会将自己在 MON 上标识为 UP 状态，设置该标志位，则 OSD 不会被自动标识为 up 状态                                                                       |
| nodown       | OSD 停止时，MON 会将 OSD 标识为 down 状态，设置该标志位，则 MON 不会将停止的 OSD 标识为 down 状态，设置 noup 和 nodown 可以防止网络抖动                          |
| noout        | 设置该标志位，则 mon 不会从 crush 映射中删除任何 OSD。对 OSD 作维护时，可设置该标志位，以防止 CRUSH 在 OSD 停止时自动重平衡数据。OSD 重新启动时，需要清除该 flag |
| noin         | 设置该标志位，可以防止数据被自动分配到 OSD 上                                                                                                                    |
| norecover    | 设置该 flag，禁止任何集群恢复操作。在执行维护和停机时，可设置该 flag                                                                                             |
| nobackfill   | 禁止数据回填                                                                                                                                                     |
| noscrub      | 禁止清理操作。清理 PG 会在短期内影响 OSD 的操作。在低带宽集群中，清理期间如果 OSD 的速度过慢，则会被标记为 down。可以该标记来防止这种情况发生                    |
| nodeep-scrub | 禁止深度清理                                                                                                                                                     |
| norebalance  | 禁止重平衡数据。在执行集群维护或者停机时，可以使用该 flag                                                                                                        |
| pause        | 设置该标志位，则集群停止读写，但不影响 osd 自检                                                                                                                  |
| full         | 标记集群已满，将拒绝任何数据写入，但可读                                                                                                                         |

# 参考文档

[https://poph163.com/category/分布式存储/](https://poph163.com/category/%e5%88%86%e5%b8%83%e5%bc%8f%e5%ad%98%e5%82%a8/)
