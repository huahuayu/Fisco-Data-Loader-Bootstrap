# Fisco-Data-Loader-Bootstrap

Fisco-Data-Loader-Bootstrap 是一个基于[fisco-bcos](https://github.com/FISCO-BCOS/FISCO-BCOS)的平台数据导出脚本，主要是为了方便多群组数据导出。

## 1. 解决的问题

下图是一个简单的 fisco-bcos 区块链网络，组织 3 和组织 4 都加入了多个群组，所以在节点 3 和节点 4 上就有多个群组的数据，如何方便的将多个群组的数据从链上导出？

![](https://raw.githubusercontent.com/huahuayu/img/master/20200618221809.png)

如果只是导单个群组的数据，fisco 官方提供了[数据导出系统](https://webasedoc.readthedocs.io/zh_CN/latest/docs/WeBASE-Collect-Bee/index.html)可以导出节点中某一个群组的数据。

但如果想要导出多个群组的数据，就要运行多个数据导出系统实例。实际情况中，如果不对各个实例的配置进行手工修改，实例间的端口号、数据库表名都会冲突；另外在实例比较多的情况下，服务的批量启停也是一个要关注的问题。

本项目就是为了解决以上问题，对多群组的数据导出进行了非常友好的支持。

## 2. 快速开始

环境要求参考[官方说明](https://github.com/WeBankFinTech/WeBASE-Collect-Bee#%E7%8E%AF%E5%A2%83%E8%A6%81%E6%B1%82)

克隆项目

```bash
git clone git@github.com:huahuayu/Fisco-Data-Loader-Bootstrap.git
cd Fisco-Data-Loader-Bootstrap
```

目录结构如下

```
├── config
│   ├── contract  # 放solidity转换后的java智能合约文件
│   │   └── HelloWorld.java
│   └── resources
│       ├── application.properties # 数据导出系统配置
│       ├── ca.crt  # 将节点ca.crt, node.crt, node.key 放到这里
│       ├── node.crt
│       ├── node.key
│       └── web3j.def
├── group.conf  # 多群组配置
├── startall.sh # 首次启动或需要重新加载配置文件时使用
├── restart.sh  # 非首次启动（不加载配置文件）
└── stopall.sh  # 停止所有的数据导出实例
```

### 2.1 配置合约文件

找到你的业务工程（你要导出数据的那条区块链中，往区块链写数据的工程），复制合约产生的 Java 文件：请将 Java 文件**复制到./config/contract 目录**下（请先删除目录结构中的合约示例 HelloWorld.java 文件）。

如果你的业务工程并非 Java 工程，那就先找到你所有的合约代码。不清楚如何将 Solidity 合约生成为 Java 文件，请参考： [利用控制台将合约代码转换为 java 代码](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/console.html)

### 2.2 配置证书文件

将节点 sdk 目录下的相关的证书文件：请将你的配置文件**复制到./config/resources 目录**下。配置文件包括：

-     ca.crt
-     node.crt
-     node.key

### 2.3 配置应用

修改`application.properties`文件：该文件包含了所有的配置信息。以下配置信息是必须要修改的，否则跑不起来：

```
# 节点的IP及通讯端口、组号。
## NODE_NAME可以是任意字符和数字的组合，IP为节点运行的IP，PORT为节点运行的channel_port，默认为20200。
system.nodeStr=[NODE_NAME]@[IP]:[PORT]
### 加密类型，根据FISCO BCOS链的加密类型配置，0-ECC, 1-gm。默认为非国密类型。
system.encryptType=0

# 数据库的信息，暂时只支持mysql； serverTimezone 用来设置时区
system.dbUrl=jdbc:mysql://[IP]:[PORT]/[database]?useSSL=false&serverTimezone=GMT%2b8&useUnicode=true&characterEncoding=UTF-8
system.dbUser=[user_name]
system.dbPassword=[password]

# 合约Java文件的包名
system.contractPackName=[编译Solidity合约时指定的包名]
```

更多配置详情可参考[附录 1：配置参数](appendix.html#id1)。

**以下配置是不要动的**，因为有占位符在占用了，这些配置将在`group.conf`里面配置，动态传入

```
## GROUP_ID必须与FISCO-BCOS中配置的groupId一致。
system.groupId=[groupId]
## Springboot server config
server.port=[port
## 数据库表后缀
system.tablePostfix=_[groupId]
```

配置`group.conf`

```
# 群组列表，想要同步哪个群组的数据就填哪个，英文逗号分隔
groupIds=1,2,3
# 数据导出项目springboot端口（不能重复，且和群组列表数量一致）
ports=5200,5201,5202
```

### 2.4 一键启动

首次启动，或修改了配置之后重新加载配置

```
bash startall.sh
```

后续重启

```
bash restart.sh
```

一键停止

```
bash stopall.sh
```

## License

![license](http://img.shields.io/badge/license-Apache%20v2-blue.svg)

开源协议为[Apache License 2.0](http://www.apache.org/licenses/). 详情参考[LICENSE](../LICENSE)。
