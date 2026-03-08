---
title: "Ceph 安装记录"
tags: ceph
categories: Ceph 学习
date: 2021-09-30 16:00:00
updated: 2021-09-30 16:00:00
cover:
---

ceph 安装记录
<!-- more -->
```bash bash
sudo su
apt install -y python-is-python3 systemd chrony

chronyc sources

172.31.18.113 ceph-01
172.31.26.40 ceph-02
172.31.24.19 ceph-03



# 安装 docker
sudo apt-get install -y apt-transport-https  ca-certificates  curl  software-properties-common gnupg1 gnupg2
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce


# 下载
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm

./cephadm add-repo --release quincy

./cephadm install
which cephadm

cephadm shell
cephadm shell -- ceph -s

cephadm bootstrap --mon-ip *<mon-ip>*
cephadm add-repo --release quincy
cephadm install ceph-common
ceph -v
ceph status

ceph orch host label add *<host>* _admin

ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-02
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-03

ceph orch host add ip-172-31-26-40 172.31.26.40 --labels _admin
ceph orch host add ip-172-31-24-19 172.31.24.19 --labels _admin

ceph orch apply osd --all-available-devices


ceph fs volume create fs-01 --placement="ip-172-31-18-113"
stat /sbin/mount.ceph

mount -t ceph cephuser@.fs-01=/ -o secret=AQCR52Rjyuu7ChAAzZs+tBmFrp3bGvYAHZHwJg==

# 挂载cephfs 前提条件
ssh {user}@{mon-host} "sudo ceph config generate-minimal-conf" | sudo tee /etc/ceph/ceph.conf
chmod 644 /etc/ceph/ceph.conf
ssh {user}@{mon-host} "sudo ceph fs authorize cephfs client.djx / rw" | sudo tee /etc/ceph/ceph.client.foo.keyring
chmod 600 /etc/ceph/ceph.client.foo.keyring

# 挂载 cephfs
mount -t ceph djx@f97eeb7c-5bed-11ed-9dfb-05518952193e.fs-01=/ /mnt/fs-01 -o mon_addr=172.31.18.113:6789/172.31.26.40:6789/172.31.24.19:6789,secret=AQCR52Rjyuu7ChAAzZs+tBmFrp3bGvYAHZHwJg==


# 操作服务
ceph orch <start|stop|restart|redeploy|reconfig> <service_name>

```
