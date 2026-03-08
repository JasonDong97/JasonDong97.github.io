---
title: mysql 查看表字段注释
date: 2023-12-27
updated: 2023-12-27
tags:
  - mysql
categories: mysql
keywords:
copyright: false
---

1. **查看列注释**：

   - 您可以通过两种方式查看 MySQL 列的注释：

     - 使用`SHOW FULL COLUMNS`查询：

       ```sql
       SHOW FULL COLUMNS FROM employee_designation;
       ```
     - 使用 MySQL Workbench：
       - 在 SCHEMAS 部分选择表，然后点击信息图标。
       - 切换到 COLUMNS 标签，即可查看列的注释。