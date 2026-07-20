# NOC_ARB 设计说明

## 1. 模块目标

`NOC_ARB` 实现两路 NOC 端口到一路 SLLC 端口之间的 CHI 通道汇聚与分发。端口包括三组标准 CHI 接口：

- `noc0`：带 `0` 后缀的一组 NOC 端口。
- `noc1`：带 `1` 后缀的一组 NOC 端口。
- `sllc`：无后缀的一组 SLLC 端口。

当前实现覆盖六个通道：

- `req`
- `dat`
- `rsp`
- `reqext`
- `datext`
- `rspext`

六个通道使用同一套数据通路结构，顶层通过 `SKY_CHI_CHANNEL_ARB` 分别例化，避免每个通道重复手写仲裁逻辑。

## 2. 顶层结构

顶层由两部分组成：

1. 三个 `SKY_LINK_CTRL_ACTIVE` 实例，分别封装 `noc0`、`noc1`、`sllc` 的建链/断链控制。
2. 六个 `SKY_CHI_CHANNEL_ARB` 实例，分别处理一个 CHI 通道的数据缓冲、credit 隔离和公平仲裁。

每个通道实例共享对应端口的链路控制信号：

- `rxlcrdhold`：表示当前不能继续向上游发 credit。
- `txlcrdreturn`：表示需要把当前持有的下游 credit 返还。
- `txlcrdreceive`：表示可以接受下游返回的 credit。
- `txflitenable`：表示 TX 方向允许发送 flit。

## 3. 数据方向

### 3.1 NOC0/NOC1 到 SLLC

该方向是 2 对 1 汇聚：

1. `noc0` 输入先进入 `u_rxbuf_noc0`。
2. `noc1` 输入先进入 `u_rxbuf_noc1`。
3. 两个 RXBUF 的输出进入公平仲裁。
4. 仲裁获胜的数据进入 `u_txbuf_sllc`。
5. `u_txbuf_sllc` 驱动 SLLC 侧 `rx*` 输出端口。

RXBUF 的 `rxbuf_rdy` 只在对应数据被选中并且 SLLC TXBUF 可接收时拉高，因此上游 credit 只返回给真实出队的那一路。

### 3.2 SLLC 到 NOC0/NOC1

该方向是 1 对 2 分发：

1. SLLC 输入先进入 `u_rxbuf_sllc`。
2. RXBUF 输出根据两个 NOC TXBUF 的 `txbuf_rdy` 做公平选择。
3. 如果只有一个 NOC TXBUF ready，则发往 ready 的一侧。
4. 如果两个 NOC TXBUF 都 ready，则轮转优先级。
5. 被选中的数据进入 `u_txbuf_noc0` 或 `u_txbuf_noc1`。

`rxbuf_rdy_sllc` 只在某个 NOC TXBUF 确认接收时拉高，保证 SLLC 侧 RXBUF 不会提前出队。

## 4. 仲裁策略

两个方向均采用 1 bit 轮转优先级：

- `to_sllc_arb_sel`：控制 NOC0/NOC1 到 SLLC 的公平仲裁。
- `from_sllc_arb_sel`：控制 SLLC 到 NOC0/NOC1 的公平分发。

当只有一路有效或 ready 时，选择可工作的那一路；当两路同时满足条件时，按照当前优先级选择，并在成功传输后把优先级切到另一侧。

## 5. 信号打包

`SKY_RXBUF` 和 `SKY_TXBUF` 的 `flit` 端口为 3 bit。通道内部统一把 `{patag, nocinfo, flit}` 打包成 3 bit 传输。

- NOC 到 SLLC 方向：NOC RX 输入没有 `nocinfo`，打包为 `{rx_flitpatag*, 1'b0, rx_flit*}`。
- SLLC 到 NOC 方向：SLLC TX 输入带 `nocinfo`，打包为 `{tx_flitpatag, tx_nocinfo, tx_flit}`。

SLLC RX 输出没有 `nocinfo` 端口，解包时中间 bit 被接到未使用信号。

## 6. Sideband 处理

当前代码中部分 sideband 固定为 0：

- `rx_hint`
- `tx_push0`
- `tx_push1`

这些信号保留端口连接，但当前通道缓冲封装没有承载对应信息。若后续需要完整透传，需要扩展 `SKY_RXBUF/SKY_TXBUF` 的 payload 宽度或增加 sideband 缓冲字段。

## 7. 依赖模块

`NOC_ARB` 依赖 `link_ctrl.v` 中的三个模块：

- `SKY_LINK_CTRL_ACTIVE`
- `SKY_RXBUF`
- `SKY_TXBUF`

当前 `NOC_ARB` 将这些模块作为封装模块例化，不在顶层内部展开具体 FIFO 或链路状态机逻辑。

