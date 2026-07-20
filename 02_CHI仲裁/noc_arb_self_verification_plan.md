# NOC_ARB 验证方案

## 1. 验证目标

验证 `NOC_ARB` 在六个 CHI 通道上都满足以下要求：

- `noc0/noc1` 到 `sllc` 方向实现 2 对 1 公平仲裁。
- `sllc` 到 `noc0/noc1` 方向实现 1 对 2 公平分发。
- RXBUF/TXBUF 完成 credit 隔离，上游不会因为另一侧出队而误收 credit。
- 建链/断链控制信号正确接入各通道缓冲。
- `patag/nocinfo/flit` 打包与解包关系正确。
- 六个通道之间互不串扰。

## 2. 建议验证环境

建议建立一个轻量 SystemVerilog testbench：

- DUT：`NOC_ARB`。
- Stub/模型：为 `SKY_LINK_CTRL_ACTIVE`、`SKY_RXBUF`、`SKY_TXBUF` 提供可观测模型。
- Driver：分别驱动 `noc0`、`noc1`、`sllc` 三组 CHI 端口。
- Monitor：采集每个通道的输入、输出、credit 和 ready。
- Scoreboard：按通道、方向记录期望出队顺序。

如果后续已有正式 `SKY_RXBUF/SKY_TXBUF` 实现，应优先使用真实模块进行集成验证，再用 stub 模型做单元级异常场景补充。

## 3. 基础用例

### 3.1 单路 NOC 到 SLLC

每个通道分别只从 `noc0` 或只从 `noc1` 输入 flit：

- 检查 SLLC 对应 `rx*` 输出是否出现相同 `flit/patag`。
- 检查只有发送侧收到 credit 返回。
- 检查另一侧无输出、无误 credit。

### 3.2 双路 NOC 到 SLLC

`noc0` 和 `noc1` 同时持续输入：

- 检查输出无丢包、无重复。
- 检查仲裁在两路都有数据时轮转。
- 检查 `txbuf_rdy_sllc=0` 时两个 RXBUF 都不 pop。

### 3.3 SLLC 到单路 NOC

只让 `noc0` 或只让 `noc1` TXBUF ready：

- 检查 SLLC 输入只发往 ready 的 NOC 侧。
- 检查未 ready 的 NOC 侧不接收数据。
- 检查 SLLC RXBUF 只在目标侧 ready 时 pop。

### 3.4 SLLC 到双路 NOC

`noc0` 和 `noc1` TXBUF 同时 ready：

- 检查输出在两侧之间轮转。
- 检查每次成功发送后优先级切换。
- 检查其中一路临时 backpressure 时，另一侧可继续接收。

## 4. Credit 与建链用例

### 4.1 上游 credit 隔离

在 `noc0` 和 `noc1` 都有数据时，只允许其中一路被仲裁出队：

- 被选中一路应产生对应 credit 返回。
- 未选中一路不得产生 credit 返回。

### 4.2 下游 backpressure

拉低目标 TXBUF 的 `txbuf_rdy`：

- 上游 RXBUF 不应 pop。
- 输出 flit 不应被错误接受。
- 当 `txbuf_rdy` 恢复后，数据继续传输。

### 4.3 链路控制

分别改变三组链路控制模型输出：

- `rxlcrdhold=1` 时，对应上游 credit 发放受阻。
- `txlcrdreturn=1` 时，TXBUF 应进入 credit 返还行为。
- `txlcrdreceive=0` 时，TXBUF 不应错误接收下游 credit。
- `txflitenable=0` 时，对应 TX 输出应被抑制。

## 5. 打包/解包检查

### 5.1 NOC 到 SLLC

对每个通道、每个 NOC 端口遍历 `flit` 和 `patag`：

- 输入 `{rx_flitpatag*, rx_flit*}`。
- 期望 SLLC 输出 `rx_flitpatag/rx_flit` 一致。
- `nocinfo` 中间 bit 在该方向固定为 0，不应影响可见输出。

### 5.2 SLLC 到 NOC

遍历 SLLC 输入 `{tx_flitpatag, tx_nocinfo, tx_flit}`：

- 检查被选中 NOC 侧 `tx_flitpatag*/tx_nocinfo*/tx_flit*` 完全一致。
- 检查未选中 NOC 侧不出现同一拍误输出。

## 6. 多通道独立性

同时在多个通道施加不同数据模式：

- `req` 输入只应从 `req` 输出观察到。
- `dat/rsp/reqext/datext/rspext` 同理。
- 任意通道 backpressure 不应阻塞其它通道，除非共享链路控制明确要求。

## 7. 覆盖点

建议至少覆盖以下情况：

- 六个通道均发生 NOC0 到 SLLC 传输。
- 六个通道均发生 NOC1 到 SLLC 传输。
- 六个通道均发生 SLLC 到 NOC0 传输。
- 六个通道均发生 SLLC 到 NOC1 传输。
- 两路 NOC 同时 valid 时，仲裁选择 0 和选择 1 都出现。
- 两路 NOC TXBUF 同时 ready 时，分发选择 0 和选择 1 都出现。
- `txbuf_rdy` 为 0 到 1 的 backpressure 恢复。
- 每组链路控制信号至少触发一次有效行为。

## 8. 通过标准

验证通过需要满足：

- 所有 directed case 通过。
- Scoreboard 无丢包、重包、乱通道、错误目的端。
- Credit 检查无误返回。
- 打包/解包检查无 mismatch。
- 基础功能覆盖和关键分支覆盖达到计划要求。
- RTL 语法检查通过；若使用的工具不支持宏或当前封装 stub，需要在验证报告中记录限制。

