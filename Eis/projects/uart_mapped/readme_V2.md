# Description
This project is for a UART module.

The module has a Tx and Rx (Server) buffer and a control register.

You control the Tx and Rx via the register's bits.


------------------------------
# Protocol
Each party (aka end-point: Client or System) must check that the other is ready to receive data before attempting to send anything. However, in order to check the party must have gained control first. Control is managed via a mutex (1 bit).

For example, if the System wants to send data it must gain ownership of the mutex first. It does this by "Requesting control" via the System-Request-Control (**SRC**) bit. Once SRC is set the System can begin polling the System-Control-Granted (**SCG**) bit. When SCG is sets then the System has gained control of the device. At the same time the device sends a Status byte to the Client informing it that a party has control.

The System can write bytes to the Tx buffer. Once the System is done it clears the mutex via another signal Relinquish-Control (**RQC**). <**important**> The device then sends a Status byte to the Client informing it that the mutex is free. The Client can respond with request or denial for control.

At this point if the Client wants control it must send a Client-Request-Control (**CRC**) signal.

### **Device Round-Robin**
The Device (aka Arbiter) always checks with the *other* party if they want control after the current party has relinqished control. If neither wants control then the device idles. The first to request control wins.

At the end of every relinquish the other party is queried for control. The other party can reject causing the device to idle. If interrupts are enabled then the System can be notified via an interrupt otherwise the System must poll.

An example, the client won't request control while the System has it because the Client was notified that the System has control prior. The opposite isn't true, the System isn't notified because the System can query in parallel while the Client has control.

If the mutex is set then a party has control. The "device" has highest priority. When the Device is in control both the Client and System are locked out.

### **Lock out**
(Optional) In order to prevent any party from locking the device by perpetually holding the mutex a watchdog timer is used.

## Protocol (Client to System)
The Client knows when the System has control because it was notified when the System was given control. The client won't request control until it is notified by the device. Hopefully the System doesn't crash while it has control otherwise the client will never be able to gain control and send data.

If the client hasn't been notified yet it can send Client-Request-Control (**CRC**) signal. If the System has control it won't be notified until the system relinquishes control. If the System didn't have control it will get a response indicating it has now has control. So the Client will get either get a signal indicating it has gained control or it will get a signal asking if it was control.

## Client
The Client is always expecting at least one byte. If it was in the process of requesting control (via **CRC**) it will expect a byte in return. If the System happens to have control the client already knows because it received a Device-Is-Owned (**DIO**) byte prior. If the System doesn't have control it will get Request-Granted-Control (**RGC**) byte instead. Either way it always gets a byte.

The Client will only send Data or Normal Key-codes when it has control.

# System
The System first checks if a party has the mutex. If not it can request control by setting System-Request-Control (SRC) bit. The Device recognizes the bit and sends the DIO signal to the Client.

While the System has control it can only read the Rx buffer when told to do so.

# End of Transmission (EOT)
At the end of every transmission--unless it is a signal with no data--a EOT is required to relinquish control.

# Control Break (Ctrl-C)
The Client can send the key-code for Ctr-C at any time. The device will generate an interrupt. The System knows that if an interrupt was generated while it has the mutex then it was an interrupt generate as a result of the Ctr-C key-code sent and the System won't bother reading the Rx buffer. Otherwise any otherwise any other Key-codes sent are done when the Client has the mutex and the System would then read the Rx buffer for the code.

# Streams
To send a stream of data the System or Client must be the Source (i.e. mutex owner). For example, for the System to send a stream of data to the Client it first gains the mutex.

The Source is responsible for sending the EOT signal and monitoring the Destination's handshaking signals. For every *buffer* sent by the Source the Destination sends a Buffer-Data-Acknowledge (**BDA**) signal. The Device recognizes that signal and sets the corresponding bit in the control register.

## System to Client (Stream)
The System requests control. Once obtained it sends Begin-Data-Stream (**BDS**) signal to the destination (aka Client). When ready, the Client send the Acknowledge-Data-Stream (**ADS**) signal. The System then begins sending buffers and once complete sends EOT signal. The System then automatically looses the mutex. As before, once a party (i.e. System) looses control the Destination (i.e. Client) is sent a Control-Available-Offer (**CAO**).

# Send Key code
Key codes need to be handled efficiently. So the Client can send a Key-code byte sequence (2 bytes) at any time. The Device inspects the byte for only one Key-code (Ctrl-C)

# Dialogs

# Hardware Implementation


### Client RTS received
????The UART-Rx's rx_complete is active high. When rising-edge rx_complete is detected the state machine checks the upper 3-bits for the RTS signal. If detected than the next state checks if the device is busy (i.e. the system is reading the Rx buffer) This is done by checking the Rx Buffer Reading (**RBR**) signal). The RBR bit is sent back via the next states. This can be done in parallel. While the device is responding the 
????

????The client can only send data if the Device (aka UART component) is ready to receive, for example, the System may be in the process of reading the Rx buffer. This means the device must "listen" to the incoming Rx byte for signals. One of those signals is sss = "RTS" ==> |sssnnnnn|.?????


-----------------
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
