# <span style='color: green;'>Description</span>
Version 4 is a simple byte-for-byte communication protocol via software handshaking.
This version the Device the absolute minimum.

------------------------------------------------------------------
# <span style='color: green;'>Protocol</span>

Each byte sent between parties is synchronized.

------------------------------------------------------------------
# <span style='color: green;'>Rules</span>

- 1: When a party finishes a stream of data they automatically lose control.
- 2: The Client has priority. If both Request bits are set the Client wins.

------------------------------------------------------------------
# <span style='color: green;'>Client</span>
The Client can either send a single Key-code (Mode-Key) or a Stream (Mode-Stream).


## Protocol to send
The Client can send streams of data or Key-codes when it has control. It **CAN NOT** send Key-codes while it is streaming. *Once the EOS signal is sent it loses control.*

## Client to System
For example, to send two bytes from Client (C) to System (S) via Device (D)

Client is Rejected
| Client  | Device | System |
| :---:   | ---    |  ---   |
|  CRC>   |        |        | 
|         |  <REJ  |        | 


Client is Granted and begins sending bytes

| Client  | Device | System |
| :---    | :---   |  :---  |
| CRC>    |        |        | 
|         |  <RGC  |        | 
| BOS>    |        |        | 
|         |        |...<ACK | 
| DAT>    |        |        | 
|         |        |...<ACK | 
| BYTE>   |        |        | 
|         |        |...<ACK | 
| DAT>    |        |        | 
|         |        |...<ACK | 
| BYTE>   |        |        | 
|         |        |...<ACK | 
| EOS>    |        |        | 
|         |        |...<ACK | 


### Key-code
Key-codes are treated special in order to improve key response time. However, there isn't a FIFO yet in V5. This requires that the System sends ACKs, and it may take time for the System to do respond. Thus the System should process the Key quickly.

The Client can buffer the keys on its side and transmit them on each ACK received.

The Client doesn't need to request control. If the System is streaming the Client can still send key-codes. Each code that is sent either an interrupt is generated or a bit is set.

Example of repeatedly sending keys
| Client  | Device | System |
| :---    | :---   |  :---  |
| KEY>    |        |        |
|         |        |...<ACK |
| CODE>   |        |        |
|         |        |...<ACK |
| KEY>    |        |        |
|         |        |...<ACK |
| CODE>   |        |        |
|         |        |...<ACK |
| KEY>    |        |        |
|         |        |...<ACK |
| CODE>   |        |        |
|         |        |...<ACK |

------------------------------------------------------------------
# <span style='color: green;'>System</span>

System sends data to Client
| Client  | Device | System |
| :---    | :---   |  :---  |
|         |        |  <SRC  |
|         |  GRT>  |        |
|         |        |  <BOS  |
| ...ACK> |        |        |
|         |        |  <BYTE |
| ...ACK> |        |        |
|         |        |  <DAT  |
| ...ACK> |        |        |
|         |        |  <BYTE |
| ...ACK> |        |        |
|         |        |  <EOS  |
| ...ACK> |        |        |

Client request control while System has it
| Client  | Device | System |
| :---    | :---   |  :---  |
|         |        |  <SRC  |
|         |  GRT>  |        |
| CRC>    |        |        |
|         |  <REJ  |        |
|         |        |  <BOS  |
| ...ACK> |        |        |
|         |        |  <BYTE |
| ...ACK> |        |        |
| ...     |        |  ...   |

System sends data to Client and Client sends Key-code.
This is **not allowed** at this time.
| Client  | Device | System |
| :---    | :---   |  :---  |
|         |        |  <SRC  |
|         |  GRT>  |        |
|         |        |  <BOS  |
| ...ACK> |        |        |
| KEY>    |        |        |
|         |        |...<ACK |
| CODE>   |        |        |
|         |        |...<ACK |
|         |        |  <BYTE |
| ...ACK> |        |        |
|         |        |  <DAT  |
| ...ACK> |        |        |
|         |        |  <BYTE |
| ...ACK> |        |        |
|         |        |  <EOS  |
| ...ACK> |        |        |


## Protocol to send
In order for the System to send data it must first gain control.

1) Set CTL_SYS_SRC for requesting control
2) Poll CTL_SYS_GRNT. Look for grant signal
3) Device sends **SHC** signal to indicate System has control
4) Begin sending DAT-byte pairs
5) Client responds with ACK
6) Send **EOS**


## Key-code interruptions
While the System has control and streaming, the Client has the option of sending a 2 byte Key sequence. Thus during the System streaming state sequence, the Device can detect the **KEY** code signals independently.

### <span style='color: blue;'>Parallel Key Process</span> (Key-code)
This is a separate process (i.e. domain) that detects KEY signals from the Client but only if the Client isn't streaming.

- The next data byte is stored in the Key-code register
- Then an interrupt is sent to the System (if interrupts are enabled)
    - Otherwise the System must poll.
- The System can read the Key-code register and determine what it will do
    - If the Key-code was "**Ctrl-C**" then the System aborts the stream by setting the CTL_SYS_ABORT
- The Device is monitoring that bit
- The Device then sends the **ABT** Signal to the Client  ??????? BAD????????
- The Client should be waiting for the signal. This lets the Client know the stream has stopped as a result of its Key-code
 
------------------------------------------------------------------
# <span style='color: green;'>Modes</span>

## Mode-Key
If the Client isn't streaming then a single Key-code (2 bytes) is immediately recognized. The code (2nd byte) is stored in the Key-code register. If interrupts are enabled then an interrupt is generated. Otherwise the System should check the CTL_KEY_RDY flag (True if a key is available).

The Key-code is routed to the Key-code register and the System is interrupted if Interrupts are enabled.

Key-codes are special because they need quick handling for good user response.

## Mode-Stream
Once a Party has gained control it can send streams of bytes. A stream ends when the End-of-Stream (**EOS**) signal is sent.

------------------------------------------------------------------
# <span style='color: green;'>Signals</span>
Each signal is 4 bits.
```
| 4 bit signal | xxxx |
```

| Signal  | Description |
| :---:   | --- |
| **RGC** | Device is telling Client it has been granted control |
| **CRC** | (Active) The Client is requesting control |
| **RFC** | (Passive) The Device is asking the Client if it wants control |
| **DAT** | Client is sending a byte |
| **BOS** | Begining of Stream |
| **EOS** | End of Stream |
| **SHC** | Device is telling Client that System has control |
| **KEY** | Key-Code was sent and the next byte is a key code. This signal can only be sent when the Client is not streaming. This prevents confusion between a Key-Code signal and actual data |
| **ACK** | Informing the destination that the byte has been received and processed |

------------------------------------------------------------------
# <span style='color: green;'>Control bits</span>

## Control register #1
| Bit               | Description |
| ---               | --- |
| **CTL_IRQ_EN**    | Enable/Disable interrupts |
| **CTL_CLI_GRNT**  | Client has been granted control. |
| **CTL_CLI_CRC**   | Client-Request-Control. Client is requesting control |
| **CTL_KEY_RDY**   | Signal that a Key-code is ready for the System to read |

## Control register #1
| Bit               | Description |
| ---               | --- |
| **CTL_SYS_SRC**   | System-Request-Control. The System is requesting control. |
| **CTL_SYS_GRNT**  | If Set the System has been granted control |
| **CTL_SYS_ABORT** | DEP The System is cancelling the current stream |
| **CTL_SYS_ARE**   | System polls this bit to identify when to send the ACK signal |
