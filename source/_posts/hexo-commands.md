---
title: Hexo 常用命令
date: 2026-04-23 10:30:00
categories:
  - 工具
tags:
  - Hexo
  - 博客
---

# Hexo 常用命令

## 基础命令

| 命令 | 简写 | 说明 |
|------|------|------|
| `hexo server` | `hexo s` | 启动本地服务器，预览博客 |
| `hexo generate` | `hexo g` | 生成静态文件 |
| `hexo deploy` | `hexo d` | 部署博客到服务器 |
| `hexo clean` | - | 清除缓存文件和已生成的静态文件 |

## 常用组合命令

```bash
# 本地预览
hexo server          # 启动本地服务器，默认 http://localhost:4000
hexo s --debug       # 调试模式启动

# 构建并部署
hexo clean && hexo g && hexo d   # 清除、生成、部署一条龙

# 快速部署
hexo g -d            # 生成后直接部署
```

## 文章管理

| 命令 | 说明 |
|------|------|
| `hexo new <title>` | 创建新文章（默认 Markdown） |
| `hexo new page <name>` | 创建新页面 |
| `hexo new draft <title>` | 创建草稿 |
| `hexo publish <filename>` | 发布草稿 |

## 其他命令

| 命令 | 说明 |
|------|------|
| `hexo list <type>` | 列出所有文章/页面/分类/标签 |
| `hexo version` | 查看 Hexo 版本 |
