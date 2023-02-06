# Description
This project is for a UART module.

------------------------------
# Rules

- 1: When a party finishes a stream of data they automatically lose control.
- 2: The Client has priority. If both Request bits are set the Client wins.
- 3: If A party is Streaming then the stream must complete before anything is recognized, including Key-Signals.

# Client
The Client can either send a single Key-code (Mode-Key) or a Stream (Mode-Stream). The Client can send a KEY signal anytime except when it is streaming.

Example of sending a keycode.
```
|KEY|Byte|
```
See **System** for an example of a stream. It is the same for both.

The Client should always be waiting for at least one byte. That byte contains a signal and optionally trailing data bytes.

## Protocol to send
The Client can send streams of data or Key-codes when it has control. It can't send Key-codes while it is streaming. *Once the EOS signal is sent it loses control.*

To send a stream:
1) Send **CRC** signal to request control.
    - The Client may not need to send **CRC** if it got an **RFC** from the Device when the System lost control prior
2) Wait for **CGT** granted signal
3) Begin streaming data chunks. Note: Sending data is the same as it is for the System.
4) When complete the last chunk should have the **EOS** signal

The Client will lose control once the **EOS** signal is sent.

### Parallel Key Process (Byte-code)
As seen down in the System description the "Parallel process" also detects a CRC Signal where the Client is requesting control. The Client will only send this when it **hasn't** received a **SHC** signal from the Device.

Keep in mind the Client will always receive a request from the Device when the System has lost control. So the Client will know that it could possibly request control.



# System
The System can only send a stream of bytes. The minimum is two bytes: Signal+byte.

If just one chunk of data is sent, that is smaller than the buffer, then the EOS signal accompanies the data at the same time. For example:
```
|EOS+Count|Byte|Byte|...|
```

If more bytes of data need to be sent that exceed the buffer then a Data (DAT) signal is sent except on the last chunk. For example:
```
|DAT|Byte|Byte|...|DAT|Byte|Byte|...|EOS+Count|Byte|Byte|...|
     Chunk           Chunk             End Chunk
```

## Protocol to send
In order for the System to send data it must first gain control.

1) Set CTL_SYS_SRC 
2) Poll CTL_SYS_GRNT
3) Device sends **SHC** signal to indicate System has control
4) Write data to buffer
5) Set CTL_TX_BUFF_RDY
6) Device transmits buffer
    - If the buffer has the **EOS** signal then when the buffer is sent the device follows up by sending a **RFC** signal.
    - Return to Device idle.
7) Otherwise repeat back to 4) until **EOS** signal detected.


## Key-code interruptions
While the System has control and streaming, the Client has the option of sending a 2 byte Key sequence. Thus during the System streaming state sequence, the Device can detect the **KEY** code signals independently.

### Parallel Key Process (Key-code)
This is a separate process (i.e. domain) that detects KEY signals but only if the Client isn't streaming, however, this isn't this case since the System has control. Once the signal is detected:

- The next data byte is stored in the Key-code register
- Then an interrupt is sent to the System (if interrupts are enabled)
    - Otherwise the System must poll.
- The System can read the Key-code register and determine what it will do
    - If the Key-code was "**Ctrl-C**" then the System aborts the stream by setting the CTL_SYS_ABORT
- The Device is monitoring that bit, it let's the current chunk complete
- and then sends the **ABT** Signal to the Client
- The Client should be waiting for the signal. This lets the Client know the stream has stopped as a result of its Key-code
 
# Modes

## Mode-Key
If the Client isn't streaming then a single Key-code (2 bytes) is immediately recognized and the code is stored in the Key-code register. If interrupts are enabled then an interrupt is generated. Otherwise the System should check the CTL_KEY_RDY flag (True if a key is available).

The Key-code is routed to the Key-code register and the System is interrupted if Interrupts are enabled.

Key-code are special because they need to handle quickly for good user response.

## Mode-Stream
Once a Party has gained control it can send streams of bytes. The streams are broken down into chunks the size of the buffer (31 + 1). A stream is end when the End-of-Stream (EOS) signal is sent.

# Signals
Each signal is a byte and can be followed by 0 or more bytes with in a chunk.
```
| 3 bit signal | 5 bit byte count |
```

- **EOS**: End of Stream.
- **KEY**: Key-Code was sent and the next byte is a key code. This signal can only be sent when the Client is not streaming. This prevents confusion between a Key-Code signal and actual data.
- **ABT**: An abort signal sent to the Client to let it know the current stream has been aborted.
- **CRC**: The Client is requesting control.
- **CGT**: The Client has been granted control.
- **RFC**: The Device is asking the Client if it wants control.
- **SHC**: Device is telling Client System has control

# Control bits

## Control Register 1
- **CTL_SYS_SRC**: System-Request-Control (**SRC**)
- **CTL_SYS_GRNT**: If Set the System has been granted control
- **CTL_TX_BUFF_RDY**: The System is ready for loaded buffer to be sent
- **CTL_SYS_ABORT**: The System is cancelling the current stream.
- **CTL_CLI_CRC**: Client-Request-Control (**CRC**)
