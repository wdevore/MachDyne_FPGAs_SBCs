# Description
This project is for a UART module.

The module has a Tx and Rx (Server) buffer and a control register.

You control the Tx and Rx via the register's bits.

## CPU to UART
The CPU interfaces with the component via a control register and 2 data ports.


## Protocol (client to server)
```
|--action byte--|--------- data ------------|
```

The FPGA UART Rx has a fixed sized buffer no larger than 256 bytes.

## Client
A client can query the FPGA Rx  (aka server) for it buffer size via an action.

### Actions
- **0x01**

  Send data that is smaller than the server's buffer

  ```
  | 0x01 | byte count | ------ data -------- |
  ```

- **0x02**

  Send data that is exactly the size of the server's buffer.

  ```
  | 0x02 | ------ data -------- |
  ```

- **0x03** = (optional) End of transmission.

  Tell the server the client is done sending data. Use this if you are terminating payload prior to sending all bytes.

- **0x04** = RTS.

  Ask the server if data can be sent. The server may still be processing the current buffer. This means the client needs to poll the server. The server can respond with:
  - 0x00 = Still processing
  - 0x01 = Ready to accept data.  

- **0x05** = Ask server for its buffer size.
  - A byte value is returned immediately

## Protocol (server to client)
- **0x01**

  Send data that is smaller than the client's buffer

  ```
  | 0x01 | byte count | ------ data -------- |
  ```

- **0x02**

  Send data that is exactly the size of the client's buffer.

  ```
  | 0x02 | ------ data -------- |
  ```

- **0x04** = RTS.

  Ask the client if data can be sent. The client may still be processing the current buffer. This means the server needs to poll the client. The client can respond with:
  - 0x00 = Still processing
  - 0x01 = Ready to accept data.  

- **0x05** = Ask client for its buffer size.

  If the client's buffer is smaller than the server then the server sends data at it client's maximum buffer size, plus any remaining  data using action **0x01**

  - A byte value is returned immediately


## Control Register

### **Bit 0**: Start Tx
Enable transmission. Once all bytes have been loaded into the buffer you enable this bit. The module will then begin controlling this bit for each byte until the last byte is sent where upon the bit is cleared.

### **Bit 1**: Bytes-sent complete indicator
Once all bytes are sent this bit is set. When a new transmission is started it is cleared and then sets again when the last byte has completed sending.

### **Bit 2**: Control Granted

If the CPU is attempting to get control it first notifies that it wants control by setting Bit-7. When the device has completed its work, for example transmitting data, it checks the Request-Control bit and if set  grants control by setting Bit-2 and clearing Bit-7

Who takes control must relinquish control (Clearing Bit-2) when done otherwise the device is hung must be reset.

When the CPU has control it can read/write from the buffer and Control register. Both Tx and Rx UARTs are non-respondent.

If data is to be transmitted the CPU first fills the Tx buffer, also if data is present in the Rx buffer it reads that too. When done it Sets Bit-0, if data to transmit and relinquishes control by clearing Bit-2.

### **Bit 3**: Stop bit count (1,2)
0 : = 1 Stop bit, 1 : = 2 Stop bits

### **Bit 4**: Enable/Disable interrupts
When the last byte is received an interrupt is generated if enabled.
- 1 : = Enable
- 0 : = Disable

### **Bit 5**: Reset Tx Address
Clearing this bit clears the address counter to zero. The bit is Set automatically.

### **Bit 6**: Reset Rx Address
Clearing this bit clears the address counter to zero. The bit is Set automatically.

### **Bit 7**: Request Control
If the device wants control then it checks Bit-7, if cleared it sets Bit-2 immediately in order to gain control.

---

???The Rx channel is allowed complete but remain active in order to service certains actions, for example, "Buffer size query", "Status" or "Request to send (RTS)".

To Tx data or read Rx data the CPU first obtains control. Once it has control it can read or write to the buffer or Control register.

???When data comes in, the Stop-bit on the Rx channel is recongnized and the Busy bit is set.
When the Bit-0 is set then this bit is set. It is cleared when Tx is complete.

Basically when the device is busy doing:
- Transmitting
- Receiving
- Clear address counters
- Setting/Clear control bits

# Module
The module operates on the system core clock which means it is most likely in a separate clock domain than the softcore.

The module IO ports are:
- input Reset
- output IRQ
- input Wr
- input Rd
- input Enable
- input [1:0] Addr
- input [7:0] InData
- output [7:0] OutData

## Transmit data
- First you store a bytes for Tx
- Set Tx Bit-0 to begin transmitting buffer
- Either Poll Tx_complete Bit-1 to detect buffer completion.
  - Or Enable interrupts


# Misc
Note: Remember to cross the Tx and Rx signals.

# Summary
- protocol: 8N1
- baud: 115200 or 921600

# Minicom client (aka trasnmitter)
Turn off "flow control" [Ctrl-a x o]

```$ minicom -o -D /dev/ttyUSB0 -b 921600```

# Inout port
- https://stackoverflow.com/questions/40902637/how-to-write-to-inout-port-and-read-from-inout-port-of-the-same-module
- https://support.xilinx.com/s/question/0D52E00006hpek4SAA/verilog-bidirectional-mux?language=en_US
- https://stackoverflow.com/questions/50821122/inout-with-reg-type-in-verilog

```

module my_top (
  input  data_tri,
  input  data_tx,
  output data_rx,
  inout  data_io
  );

assign data_io = (data_tri) ? 1'bZ : data_tx;
assign data_rx = data_io;

endmodule
```

# buses
Wishbone bus
- https://phisch.org/wp/wb_switch-a-wishbone-bus-interconnect-for-fpgas/
- Nihongo/Hardware/RISC-V/TopReference/zipcup buses wishbone pipeline.pdf

# Delete (it is just draft stuff)
### Bit 7: Store data (UNUSED)
Data is stored on the rising edge of this bit (i.e. from 0->1). Thus Setting bit writes data from port to buffer at the current address. The bit is automatically cleared.

## Incoming byte register
Prior to writing first byte toggle Bit-5 to reset address. Each write to the port stores the byte in the buffer and increments the address.

## Output register.
Prior to reading first byte toggle Bit-5 to reset address.

On falling-edge of Read signal the port is read just like reading from memory.

On the rising-edge the module proceeds to increment address and copies a byte from buffer to port. It does this by sending a signal to the module's internal system.
