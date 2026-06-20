# SLLC_TX_BUFFER 设计说明

## 模块拆分

代码拆成两个可独立维护的 RTL 文件：

- `rtl/sllc_tx_buffer.v`：顶层发送缓冲模块，负责 CHI flit 接收、cbusy 域段替换、bypass 判定和下游发送控制。
- `rtl/sllc_tx_fifo.v`：同步 FIFO 小模块，负责普通缓存、满空状态和同周期 push/pop。

编译文件顺序写在 `rtl/filelist.f` 中，先编译 FIFO，再编译顶层。

## 顶层参数和端口

顶层对外保留端口位宽相关参数：

- `CHANNEL`：通道类型编码，`0=req`、`1=rsp`、`2=snp`、`3=dat`。
- `FLIT_W`：输入 CHI flit 位宽。
- `PLD_W`：输出 payload 位宽，默认等于 `FLIT_W`。

内部固定配置用 `localparam` 管理：

- `FIFO_DEPTH`：顶层例化 FIFO 的深度。
- `CBUSY_W`：cbusy 域段宽度。
- `CBUSY_LSB`：cbusy 域段最低位位置。

## 数据路径

输入 `flit` 先根据 `FLIT_W` 和 `PLD_W` 做宽度适配，形成内部 `rx_pld`。若输出 payload 更宽，则高位补零；若更窄，则截取低 `PLD_W` 位。

cbusy 替换发生在进入 FIFO 之前。`replace_cbusy` 会读取 `rx_pld` 中的 cbusy 域段，并在 `cfg_sky_rx_cbusy_rsp_en` 打开时与 `sllc_utl_sky_rx` 比较，取较大值写回，形成 `rx_pld_cbusy`。这样 FIFO 内保存的数据和 bypass 输出的数据都是已替换后的版本。

## FIFO 和 Bypass

当 FIFO 为空、输入 `flitv` 有效、下游本拍满足发送条件时，模块走 bypass：`rx_pld_cbusy` 直接作为 `tx_pld` 输出，不写入 FIFO。

当不能 bypass 时，输入有效报文写入 FIFO。FIFO 非空时，输出优先来自 FIFO 头部。FIFO 支持同周期 pop 和 push；即使 FIFO 已满，只要同周期 pop 释放一个 entry，本拍 push 仍可被接受。

## 发送控制

`tx_vld` 只有在下游 credit 存在时才可能拉高：

```verilog
tx_vld = phy_tx_crd_exist & (~fifo_empty | flitv)
```

真正完成发送的条件是 `tx_vld & sllc_tx_en`。其中 `sllc_tx_en` 作为下游 ready 使用。

## 当前约束

当前端口没有上游 ready/backpressure 信号。如果 FIFO 已满且下游不能消费，而上游仍持续拉高 `flitv`，顶层无法从接口层面反压上游；这需要系统级协议保证，或后续扩展输入 ready 端口。
