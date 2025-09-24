---
title: mysql 创建用户并赋予管理员权限
date: 2023-12-29
updated: 2023-12-29
tags:
  - mysql
categories: mysql
keywords:
copyright: false
---

# mysql 创建用户并赋予管理员权限

```sql
-- 创建新用户，将new_username替换为你想要创建的新用户名，将password替换为用户的密码。
CREATE USER 'new_username'@'localhost' IDENTIFIED BY 'password';

-- 授予new_username用户在所有数据库和所有表上的所有权限，并且WITH GRANT OPTION选项允许该用户授予其他用户权限
GRANT ALL PRIVILEGES ON *.* TO 'new_username'@'localhost' WITH GRANT OPTION;

-- 刷新权限以使更改生效
FLUSH PRIVILEGES;
```