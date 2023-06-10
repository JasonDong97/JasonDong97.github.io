---
# 【必需】文章标题
title: HashMap 与 TreeMap
# 【必需】文章创建日期
date:
# 【可选】文章更新日期
updated:
# 【可选】文章标签
tags: Java 笔记
# 【可选】文章分类
categories: Java
# 【可选】文章关键字
keywords: HashMap TreeMap
# 【可选】文章描述
description: Java 常见面试题汇总 - 基础篇
copyright: true
---

## HashMap 和 TreeMap 的实现

**HashMap**：基于**哈希表**实现。使用 `HashMap` 要求添加的键类明确定义了 `hashCode()`和 `equals()` _[可以重写 hashCode()和 equals()]_ ，为了优化 `HashMap` 空间的使用，您可以调优**初始容量**和**负载因子**。

- `HashMap()`: 构建一个空的哈希映像
- `HashMap(Map m)`: 构建一个哈希映像，并且添加映像 m 的所有映射
- `HashMap(int initialCapacity)`: 构建一个拥有特定容量的空的哈希映像
- `HashMap(int initialCapacity, float loadFactor)`: 构建一个拥有特定容量和加载因子的空的哈希映像

**TreeMap**：基于红黑树实现。`TreeMap` 没有调优选项，因为该树总处于平衡状态。

- `TreeMap()`：构建一个空的映像树
- `TreeMap(Map m)`: 构建一个映像树，并且添加映像 m 中所有元素
- `TreeMap(Comparator c)`: 构建一个映像树，并且使用特定的比较器对关键字进行排序
- `TreeMap(SortedMap s)`: 构建一个映像树，添加映像树 s 中所有映射，并且使用与有序映像 s 相同的比较器排序

## HashMap 和 TreeMap 都是非线程安全

`HashMap` 继承 `AbstractMap` 抽象类，`TreeMap` 继承自 `SortedMap` 接口。

`AbstractMap` 抽象类：覆盖了 `equals()`和 `hashCode()`方法以确保两个相等映射返回相同的哈希码。**如果两个映射大小相等、包含同样的键且每个键在这两个映射中对应的值都相同，则这两个映射相等**。映射的哈希码是映射元素哈希码的总和，其中每个元素是 `Map.Entry` 接口的一个实现。因此，不论映射内部顺序如何，两个相等映射会报告相同的哈希码。

`SortedMap` 接口：它用来保持键的**有序顺序**。`SortedMap` 接口为映像的视图(子集)，包括两个端点提供了访问方法。除了排序是作用于映射的键以外，处理 `SortedMap` 和处理 `SortedSet` 一样。添加到 `SortedMap` 实现类的元素必须实现 `Comparable` 接口，否则您必须给它的构造函数提供一个 `Comparator` 接口的实现。`TreeMap` 类是它的唯一一个实现。
