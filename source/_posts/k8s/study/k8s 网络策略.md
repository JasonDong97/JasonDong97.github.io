---
title: k8s 网络策略
date: 2023-06-12
updated:
tags:
  - k8s
  - 学习
categories:
  - 虚拟化
keywords:
  - k8s
  - NetworkPolicy
copyright: false
---

如果你希望在 IP 地址或端口层面（OSI 第 3 层或第 4 层）控制网络流量， 则你可以考虑为集群中特定应用使用 Kubernetes 网络策略（NetworkPolicy）。 NetworkPolicy 是一种以应用为中心的结构，允许你设置如何允许 [Pod](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/) 与网络上的各类网络“实体” （我们这里使用实体以避免过度使用诸如“端点”和“服务”这类常用术语， 这些术语在 Kubernetes 中有特定含义）通信。 NetworkPolicy 适用于一端或两端与 Pod 的连接，与其他连接无关。

Pod 可以通信的 Pod 是通过如下三个标识符的组合来辩识的：

1. 其他被允许的 Pods（例外：Pod 无法阻塞对自身的访问）
2. 被允许的名字空间
3. IP 组块（例外：与 Pod 运行所在的节点的通信总是被允许的， 无论 Pod 或节点的 IP 地址）

在定义基于 Pod 或名字空间的 NetworkPolicy 时， 你会使用[选择算符](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/labels/)来设定哪些流量可以进入或离开与该算符匹配的 Pod。 另外，当创建基于 IP 的 NetworkPolicy 时，我们基于 IP 组块（CIDR 范围）来定义策略。

## 前置条件

网络策略通过[网络插件](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)来实现。 要使用网络策略，你必须使用支持 NetworkPolicy 的网络解决方案。 创建一个 NetworkPolicy 资源对象而没有控制器来使它生效的话，是没有任何作用的。

## Pod 隔离的两种类型

Pod 有两种隔离: 出口的隔离和入口的隔离。它们涉及到可以建立哪些连接。 这里的“隔离”不是绝对的，而是意味着“有一些限制”。 另外的，“非隔离方向”意味着在所述方向上没有限制。这两种隔离（或不隔离）是独立声明的， 并且都与从一个 Pod 到另一个 Pod 的连接有关。

默认情况下，一个 Pod 的出口是非隔离的，即所有外向连接都是被允许的。如果有任何的 NetworkPolicy 选择该 Pod 并在其 `policyTypes` 中包含 “Egress”，则该 Pod 是出口隔离的， 我们称这样的策略适用于该 Pod 的出口。当一个 Pod 的出口被隔离时， 唯一允许的来自 Pod 的连接是适用于出口的 Pod 的某个 NetworkPolicy 的 `egress` 列表所允许的连接。 这些 `egress` 列表的效果是相加的。

默认情况下，一个 Pod 对入口是非隔离的，即所有入站连接都是被允许的。如果有任何的 NetworkPolicy 选择该 Pod 并在其 `policyTypes` 中包含 “Ingress”，则该 Pod 被隔离入口， 我们称这种策略适用于该 Pod 的入口。当一个 Pod 的入口被隔离时，唯一允许进入该 Pod 的连接是来自该 Pod 节点的连接和适用于入口的 Pod 的某个 NetworkPolicy 的 `ingress` 列表所允许的连接。这些 `ingress` 列表的效果是相加的。

网络策略是相加的，所以不会产生冲突。如果策略适用于 Pod 某一特定方向的流量， Pod 在对应方向所允许的连接是适用的网络策略所允许的集合。 因此，评估的顺序不影响策略的结果。

要允许从源 Pod 到目的 Pod 的连接，源 Pod 的出口策略和目的 Pod 的入口策略都需要允许连接。 如果任何一方不允许连接，建立连接将会失败。

## NetworkPolicy 资源

参阅 [NetworkPolicy](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#networkpolicy-v1-networking-k8s-io) 来了解资源的完整定义。

下面是一个 NetworkPolicy 的示例:

[`service/networking/networkpolicy.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/networkpolicy.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: 172.17.0.0/16
            except:
              - 172.17.1.0/24
        - namespaceSelector:
            matchLabels:
              project: myproject
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 6379
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24
      ports:
        - protocol: TCP
          port: 5978
```

**说明：**

除非选择支持网络策略的网络解决方案，否则将上述示例发送到API服务器没有任何效果。

**必需字段**：与所有其他的 Kubernetes 配置一样，NetworkPolicy 需要 `apiVersion`、 `kind` 和 `metadata` 字段。关于配置文件操作的一般信息， 请参考[配置 Pod 以使用 ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/) 和[对象管理](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/object-management)。

**spec**：NetworkPolicy [规约](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#spec-and-status) 中包含了在一个名字空间中定义特定网络策略所需的所有信息。

**podSelector**：每个 NetworkPolicy 都包括一个 `podSelector`， 它对该策略所适用的一组 Pod 进行选择。示例中的策略选择带有 "role=db" 标签的 Pod。 空的 `podSelector` 选择名字空间下的所有 Pod。

**policyTypes**：每个 NetworkPolicy 都包含一个 `policyTypes` 列表，其中包含 `Ingress` 或 `Egress` 或两者兼具。`policyTypes` 字段表示给定的策略是应用于进入所选 Pod 的入站流量还是来自所选 Pod 的出站流量，或两者兼有。 如果 NetworkPolicy 未指定 `policyTypes` 则默认情况下始终设置 `Ingress`； 如果 NetworkPolicy 有任何出口规则的话则设置 `Egress`。

**ingress**：每个 NetworkPolicy 可包含一个 `ingress` 规则的白名单列表。 每个规则都允许同时匹配 `from` 和 `ports` 部分的流量。示例策略中包含一条简单的规则： 它匹配某个特定端口，来自三个来源中的一个，第一个通过 `ipBlock` 指定，第二个通过 `namespaceSelector` 指定，第三个通过 `podSelector` 指定。

**egress**：每个 NetworkPolicy 可包含一个 `egress` 规则的白名单列表。 每个规则都允许匹配 `to` 和 `port` 部分的流量。该示例策略包含一条规则， 该规则将指定端口上的流量匹配到 `10.0.0.0/24` 中的任何目的地。

所以，该网络策略示例:

1. 隔离 `default` 名字空间下 `role=db` 的 Pod （如果它们不是已经被隔离的话）。
2. （Ingress 规则）允许以下 Pod 连接到 `default` 名字空间下的带有 `role=db` 标签的所有 Pod 的 6379 TCP 端口：
   - `default` 名字空间下带有 `role=frontend` 标签的所有 Pod
   - 带有 `project=myproject` 标签的所有名字空间中的 Pod
   - IP 地址范围为 172.17.0.0–172.17.0.255 和 172.17.2.0–172.17.255.255 （即，除了 172.17.1.0/24 之外的所有 172.17.0.0/16）
3. （Egress 规则）允许 `default` 名字空间中任何带有标签 `role=db` 的 Pod 到 CIDR 10.0.0.0/24 下 5978 TCP 端口的连接。

参阅[声明网络策略](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/declare-network-policy/)演练了解更多示例。

## 选择器 `to` 和 `from` 的行为

可以在 `ingress` 的 `from` 部分或 `egress` 的 `to` 部分中指定四种选择器：

**podSelector**：此选择器将在与 NetworkPolicy 相同的名字空间中选择特定的 Pod，应将其允许作为入站流量来源或出站流量目的地。

**namespaceSelector**：此选择器将选择特定的名字空间，应将所有 Pod 用作其入站流量来源或出站流量目的地。

**namespaceSelector 和 podSelector**：一个指定 `namespaceSelector` 和 `podSelector` 的 `to`/`from` 条目选择特定名字空间中的特定 Pod。 注意使用正确的 YAML 语法；下面的策略：

```yaml
  ...
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
      podSelector:
        matchLabels:
          role: client
  ...
```

此策略在 `from` 数组中仅包含一个元素，只允许来自标有 `role=client` 的 Pod 且该 Pod 所在的名字空间中标有 `user=alice` 的连接。但是**这项**策略：

```yaml
  ...
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
    - podSelector:
        matchLabels:
          role: client
  ...
```

它在 `from` 数组中包含两个元素，允许来自本地名字空间中标有 `role=client` 的 Pod 的连接，**或**来自任何名字空间中标有 `user=alice` 的任何 Pod 的连接。

如有疑问，请使用 `kubectl describe` 查看 Kubernetes 如何解释该策略。

**ipBlock**：此选择器将选择特定的 IP CIDR 范围以用作入站流量来源或出站流量目的地。 这些应该是集群外部 IP，因为 Pod IP 存在时间短暂的且随机产生。

集群的入站和出站机制通常需要重写数据包的源 IP 或目标 IP。 在发生这种情况时，不确定在 NetworkPolicy 处理之前还是之后发生， 并且对于网络插件、云提供商、`Service` 实现等的不同组合，其行为可能会有所不同。

对入站流量而言，这意味着在某些情况下，你可以根据实际的原始源 IP 过滤传入的数据包， 而在其他情况下，NetworkPolicy 所作用的 `源IP` 则可能是 `LoadBalancer` 或 Pod 的节点等。

对于出站流量而言，这意味着从 Pod 到被重写为集群外部 IP 的 `Service` IP 的连接可能会或可能不会受到基于 `ipBlock` 的策略的约束。

## 默认策略

默认情况下，如果名字空间中不存在任何策略，则所有进出该名字空间中 Pod 的流量都被允许。 以下示例使你可以更改该名字空间中的默认行为。

### 默认拒绝所有入站流量

你可以通过创建选择所有 Pod 但不允许任何进入这些 Pod 的入站流量的 NetworkPolicy 来为名字空间创建 “default” 隔离策略。

[`service/networking/network-policy-default-deny-ingress.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/network-policy-default-deny-ingress.yaml) 

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

这确保即使没有被任何其他 NetworkPolicy 选择的 Pod 仍将被隔离以进行入口。 此策略不影响任何 Pod 的出口隔离。

### 允许所有入站流量

如果你想允许一个名字空间中所有 Pod 的所有入站连接，你可以创建一个明确允许的策略。

[`service/networking/network-policy-allow-all-ingress.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/network-policy-allow-all-ingress.yaml) 

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
spec:
  podSelector: {}
  ingress:
  - {}
  policyTypes:
  - Ingress
```

有了这个策略，任何额外的策略都不会导致到这些 Pod 的任何入站连接被拒绝。 此策略对任何 Pod 的出口隔离没有影响。

### 默认拒绝所有出站流量

你可以通过创建选择所有容器但不允许来自这些容器的任何出站流量的 NetworkPolicy 来为名字空间创建 “default” 隔离策略。

[`service/networking/network-policy-default-deny-egress.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/network-policy-default-deny-egress.yaml) 

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
```

此策略可以确保即使没有被其他任何 NetworkPolicy 选择的 Pod 也不会被允许流出流量。 此策略不会更改任何 Pod 的入站流量隔离行为。

### 允许所有出站流量

如果要允许来自名字空间中所有 Pod 的所有连接， 则可以创建一个明确允许来自该名字空间中 Pod 的所有出站连接的策略。

[`service/networking/network-policy-allow-all-egress.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/network-policy-allow-all-egress.yaml) 

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-egress
spec:
  podSelector: {}
  egress:
  - {}
  policyTypes:
  - Egress
```

有了这个策略，任何额外的策略都不会导致来自这些 Pod 的任何出站连接被拒绝。 此策略对进入任何 Pod 的隔离没有影响。

### 默认拒绝所有入站和所有出站流量

你可以为名字空间创建“默认”策略，以通过在该名字空间中创建以下 NetworkPolicy 来阻止所有入站和出站流量。

[`service/networking/network-policy-default-deny-all.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/network-policy-default-deny-all.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

此策略可以确保即使没有被其他任何 NetworkPolicy 选择的 Pod 也不会被允许入站或出站流量。

## SCTP 支持

**特性状态：** `Kubernetes v1.20 [stable]`

作为一个稳定特性，SCTP 支持默认是被启用的。 要在集群层面禁用 SCTP，你（或你的集群管理员）需要为 API 服务器指定 `--feature-gates=SCTPSupport=false,...` 来禁用 `SCTPSupport` [特性门控](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/feature-gates/)。 启用该特性门控后，用户可以将 NetworkPolicy 的 `protocol` 字段设置为 `SCTP`。

**说明：**

你必须使用支持 SCTP 协议 NetworkPolicy 的 [CNI](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) 插件。

## 针对某个端口范围

**特性状态：** `Kubernetes v1.25 [stable]`

在编写 NetworkPolicy 时，你可以针对一个端口范围而不是某个固定端口。

这一目的可以通过使用 `endPort` 字段来实现，如下例所示：

[`service/networking/networkpolicy-multiport-egress.yaml`](https://raw.githubusercontent.com/kubernetes/website/main/content/zh-cn/examples/service/networking/networkpolicy-multiport-egress.yaml) 

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: multi-port-egress
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24
      ports:
        - protocol: TCP
          port: 32000
          endPort: 32768
```

上面的规则允许名字空间 `default` 中所有带有标签 `role=db` 的 Pod 使用 TCP 协议与 `10.0.0.0/24` 范围内的 IP 通信，只要目标端口介于 32000 和 32768 之间就可以。

使用此字段时存在以下限制：

- `endPort` 字段必须等于或者大于 `port` 字段的值。
- 只有在定义了 `port` 时才能定义 `endPort`。
- 两个字段的设置值都只能是数字。

**说明：**

你的集群所使用的 [CNI](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) 插件必须支持在 NetworkPolicy 规约中使用 `endPort` 字段。 如果你的[网络插件](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)不支持 `endPort` 字段，而你指定了一个包含 `endPort` 字段的 NetworkPolicy， 策略只对单个 `port` 字段生效。

## 按标签选择多个命名空间

在这种情况下，你的 `Egress` NetworkPolicy 使用名字空间的标签名称来将多个名字空间作为其目标。 为此，你需要为目标名字空间设置标签。例如：

```shell
 kubectl label namespace frontend namespace=frontend
 kubectl label namespace backend namespace=backend
```

在 NetworkPolicy 文档中的 namespaceSelector 下添加标签。例如：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-namespaces
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Egress
  egress:
   - to:
     - namespaceSelector:
       matchExpressions:
       - key: namespace
         operator: In
         values: ["frontend", "backend"]
```

**说明：**

你不可以在 NetworkPolicy 中直接指定命名空间的名称。 你必须使用带有 `matchLabels` 或 `matchExpressions` 的 `namespaceSelector` 来根据标签选择命名空间。

## 基于名字指向某名字空间

**特性状态：** `Kubernetes 1.22 [stable]`

只要 `NamespaceDefaultLabelName` [特性门控](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/feature-gates/)被启用， Kubernetes 控制面会在所有名字空间上设置一个不可变更的标签 `kubernetes.io/metadata.name`。该标签的值是名字空间的名称。

如果 NetworkPolicy 无法在某些对象字段中指向某名字空间， 你可以使用标准的标签方式来指向特定名字空间。

## 通过网络策略（至少目前还）无法完成的工作

到 Kubernetes 1.27 为止，NetworkPolicy API 还不支持以下功能， 不过你可能可以使用操作系统组件（如 SELinux、OpenVSwitch、IPTables 等等） 或者第七层技术（Ingress 控制器、服务网格实现）或准入控制器来实现一些替代方案。 如果你对 Kubernetes 中的网络安全性还不太了解，了解使用 NetworkPolicy API 还无法实现下面的用户场景是很值得的。

- 强制集群内部流量经过某公用网关（这种场景最好通过服务网格或其他代理来实现）；
- 与 TLS 相关的场景（考虑使用服务网格或者 Ingress 控制器）；
- 特定于节点的策略（你可以使用 CIDR 来表达这一需求不过你无法使用节点在 Kubernetes 中的其他标识信息来辩识目标节点）；
- 基于名字来选择服务（不过，你可以使用 [标签](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/labels/) 来选择目标 Pod 或名字空间，这也通常是一种可靠的替代方案）；
- 创建或管理由第三方来实际完成的“策略请求”；

- 实现适用于所有名字空间或 Pods 的默认策略（某些第三方 Kubernetes 发行版本或项目可以做到这点）；
- 高级的策略查询或者可达性相关工具；
- 生成网络安全事件日志的能力（例如，被阻塞或接收的连接请求）；
- 显式地拒绝策略的能力（目前，NetworkPolicy 的模型默认采用拒绝操作， 其唯一的能力是添加允许策略）；
- 禁止本地回路或指向宿主的网络流量（Pod 目前无法阻塞 localhost 访问， 它们也无法禁止来自所在节点的访问请求）。