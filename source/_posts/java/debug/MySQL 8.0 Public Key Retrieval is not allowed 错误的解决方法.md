---
title: MySQL 8.0 Public Key Retrieval is not allowed 错误的解决方法
date: 2023-06-12
updated: 2023-06-12
tags: java, 遇坑记录，mysql
categories: 遇坑记录
keywords: Public Key Retrieval is not allowed
copyright: false
---

在使用 MySQL 8.0 时重启应用后提示 com.mysql.jdbc.exceptions.jdbc4.MySQLNonTransientConnectionException: Public Key Retrieval is not allowed

最简单的解决方法是在连接后面添加 `allowPublicKeyRetrieval=true`

文档中(https://mysql-net.github.io/MySqlConnector/connection-options/)给出的解释是：

如果用户使用了 sha256_password 认证，密码在传输过程中必须使用 TLS 协议保护，但是如果 RSA 公钥不可用，可以使用服务器提供的公钥；可以在连接中通过 ServerRSAPublicKeyFile 指定服务器的 RSA 公钥，或者AllowPublicKeyRetrieval=True参数以允许客户端从服务器获取公钥；但是需要注意的是 AllowPublicKeyRetrieval=True可能会导致恶意的代理通过中间人攻击(MITM)获取到明文密码，所以默认是关闭的，必须显式开启

![img](https://raw.githubusercontent.com/JasonDong97/blog_pics/master/img/20190406221957566.png)