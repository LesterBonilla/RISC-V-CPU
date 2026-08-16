# UART Module

The UART module's register map is based on the PC16550D register map. The datasheet can be found [here.](https://media.digikey.com/pdf/Data%20Sheets/Texas%20Instruments%20PDFs/PC16550D.pdf)

| Offset | Register | Bits | Field | Access | Reset Value | Description |
|:------:|---|:----:|---|:------:|:-----------:|---|
| `0x00` | `RX_BUFFER` | `[7:0]` | | RO | `8'h00` | Read-only RX_Buffer when DLAB == 0
| `0x00` | `TX_HOLDING` | `[7:0]` |  | WO | `8'h00` | Write-only TX_Holding when DLAB == 0 |
| `0x00` | `DIV_LOW` | `[7:0]` | | RW | `8'h00` | Low byte of Divisor when DLAB == 1
| `0x04` | `INTERRUPT_EN` | `[7:4]` | `RESERVED` | - | `4'h0` | Write-only interrupt enable when DLAB == 0 |
| | | `[3]` | `MODEM_STATUS_IE` | WO | `1'b0` | Enables interrupts from Modem Status (Not implemented)|
| | | `[2]` | `RX_LINE_STATUS_IE` | WO | `1'b0` | Enables interrupts from the line status register|
| | | `[1]` | `TX_HOLDING_EMPTY_IE` | WO | `1'b0` | Enables interrupt when TX_Holding is ready for data|
| | | `[0]` | `RX_DATA_AVAILABLE_IE` | WO | `1'b0` | Enables interrupts when RX_Buffer has data|
| `0x04` | `DIV_HIGH` | `[7:0]` || RW | `8h00` | Top byte of Divisor when DLAB == 1 |
|`0x08`| `INTERRUPT_IDENT` | `[7:6]` | `FIFOs Enabled` | RO | `2'b11` | Set when FIFOs are active. Always true in this implementation |
||| `[5:4]` | `RESERVED` | - | `2'b11` | Not used |
||| `[3:1]` | `Interrupt ID` | RO | `3'b000` | Encodes priority based interrupt source |
||| `[0]` | `Interrupt Pending` | RO | `1'b0` | High when an interrupt is pending |
| `0x08` | `FIFO Control` | `[7:6]` | `RX Trigger` | WO | `2'b00` | Selects RX FIFO level that triggers interrupt |
||| `[5:3]` | `RESERVED` | - | `3'b000` | Unused |
||| `[2]` | `TX FIFO Reset` | WO | `1'b0` | Flush TX FIFO entries |
||| `[1]` | `RX FIFO Reset` | WO | `1'b0` | Flush RX FIFO entries |
||| `[0]` | `FIFO Enable` | WO | `1'b1` | Enables FIFO mode, always true in this implementation |
| `0x12` | `Line Control` | `[7]` | `Divisor Latch (DLAB)` | RW | `1'b0` | Selects between RX_Buffer/TX_Holding and DIV_LOW and Interrupt_En and DIV_High |
||| `[6]` | `Break Control` | RW | `1'b0` | Sends a break signal (not implemented) |
||| `[5:4]` | `Parity Type` | RW | `2'b00` | 00 = ODD, 01 = EVEN, 10 = STICK_1, 11 = STICK 0 |
||| `[3]` | `Parity Enable` | RW | `1'b0` | Setting this bit enables parity checking and sending |
||| `[2]` | `Stop bits` | RW | `1'b0` | 0 = 1 stop bit, 1 = two stop bits |
||| `[1:0]` | `Character Length` | RW | `2'b11` | Selects number of characters: 00 = 5, 01 = 6, 10 = 7, 11 = 8 |
| `0x20` | `Line Status` | `[7]` | `RX Error` | RW | `1'b0` | Set if there is an error in an entry in the RX FIFO |
||| `[6]` | `TX Empty` | RW | `1'b0` | Set if the TX Holding register is empty and the FIFO is empty |
||| `[5]` | `TX Holding Empty` | RW | `1'b0` | Set if the TX Holding register is empty and ready for a new entry to be written |
||| `[4]` | `Break Interrupt` | RW | `1'b0` | Set if a break sequence is detected |
||| `[3]` | `Framing Error` | RW | `1'b0` | Set if the current RX did not receive a valid stop bit. |
||| `[2]` | `Parity Error` | RW | `1'b0` | Set if the current RX had the incorrect parity bit |
||| `[1]` | `Overrun Error` | RW | `1'b0` | Set if RX FIFO was full when a new character was read. The new character is lost. |
||| `[0]` | `RX Data Ready` | RW | `1'b0` | Set when RX has data available. |
| `0x28` | `Scratch` | `[7:0]` | - | RW | `8h00` | Used for generic storage |