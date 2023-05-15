package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"time"

	"go.bug.st/serial"
)

const (
	CRC_Signal byte = 0x00
	RGC_Signal byte = 0x10
	DAT_Signal byte = 0x30
	BOS_Signal byte = 0x40
	EOS_Signal byte = 0x50
	REJ_Signal byte = 0x60
	ACK_Signal byte = 0x70
	KEY_Signal byte = 0x80
)

func main() {

	// Two channels: one from the keyboard and other from uart.
	chKey := make(chan string)

	// ---------------------------------------------------------
	// UART port
	// ---------------------------------------------------------
	mode := &serial.Mode{
		BaudRate: 115200,
	}
	port, err := serial.Open("/dev/ttyUSB2", mode)
	if err != nil {
		fmt.Println("Difficulty opening serial port")
		log.Fatal(err)
	}
	defer port.Close()

	fmt.Println("Reading buf")
	buf := fetchByte(port)
	fmt.Println("buf1: ", buf)
	buf = fetchByte(port)
	fmt.Println("buf2: ", buf)
	buf = fetchByte(port)
	fmt.Println("buf3: ", buf)
	buf = fetchByte(port)
	fmt.Println("buf4: ", buf)
	// os.Exit(1)

	// ---------------------------------------------------------
	// Co-routines
	// ---------------------------------------------------------
	go keyboard(chKey)

	// ---------------------------------------------------------
	// Loop
	// ---------------------------------------------------------
	fmt.Println("Client is ready")
	fmt.Print("]")

mainloop:
	for {
		select {
		case termIn, ok := <-chKey:
			if !ok {
				break mainloop
			}

			if termIn == "quit" {
				// Close the serial port so uartScan completes.
				port.Close()

				break mainloop
			} else {
				granted := requestControl(port)

				if granted {
					// Send string to device
					sendString(termIn, port)

					// Print whatever is returned
					showResponse(port)
				}
			}
		}
	}

	fmt.Println("Good bye")
}

// ---------------------------------------------------------
// Functions
// ---------------------------------------------------------
func requestControl(port serial.Port) (granted bool) {
	// Request control from device and wait
	granted = false
	for !granted {
		uartSend(CRC_Signal, port)

		// Either we were granted or denied
		buf := fetchByte(port)

		granted = buf == RGC_Signal

		time.Sleep(time.Millisecond * 10)
	}

	return granted
}

func sendString(data string, port serial.Port) {
	// Begin sending byte characters
	// -------- BOS ---------------------------
	uartSend(BOS_Signal, port)
	ack := fetchByte(port)

	if ack != ACK_Signal {
		fmt.Println("Expected BOS/ACK_Signal pair")
		return
	}

	bytes := []byte(data)

	for _, b := range bytes {
		// -------- DAT ---------------------------
		uartSend(DAT_Signal, port)

		ack = fetchByte(port)

		if ack != ACK_Signal {
			fmt.Println("Expected DAT/ACK_Signal pair")
			return
		}

		// -------- Byte ---------------------------
		uartSend(b, port)

		ack = fetchByte(port)

		if ack != ACK_Signal {
			fmt.Println("Expected Byte/ACK_Signal pair")
			return
		}
	}

	// -------- EOS ---------------------------
	uartSend(EOS_Signal, port)
	ack = fetchByte(port)

	if ack != ACK_Signal {
		fmt.Println("Expected EOS/ACK_Signal pair")
		return
	}

}

func fetchByte(port serial.Port) byte {
	rxBuf := make([]byte, 1)

	_, err := port.Read(rxBuf)
	if err != nil {
		fmt.Printf("UART port read error: %v\n", err)
	}

	return rxBuf[0]
}

func showResponse(port serial.Port) {
	// The device is sending a stream of pairs

	// -------- BOS ---------------------------
	res := fetchByte(port)

	if res != BOS_Signal {
		fmt.Println("Expected BOS_Signal")
		return
	}

	uartSend(ACK_Signal, port)

	eos := false

	for !eos {
		// -------- DAT or EOS ---------------------------
		res = fetchByte(port)

		if res != DAT_Signal || res != EOS_Signal {
			fmt.Println("Expected either DAT_Signal or EOS_Signal")
			break
		}

		if res == EOS_Signal {
			uartSend(ACK_Signal, port)
			eos = true
			continue // Effectively exits
		}

		// -------- Byte ---------------------------
		res = fetchByte(port)

		fmt.Print(res)

		uartSend(ACK_Signal, port)
	}
}

// ---------------------------------------------------------
// UART port
// ---------------------------------------------------------
func uartSend(data byte, port serial.Port) {
	_, err := port.Write([]byte{data})
	if err != nil {
		fmt.Println("UART port write error")
		log.Fatal(err)
	}
}

// ---------------------------------------------------------
// Stdin
// ---------------------------------------------------------
func keyboard(ch chan string) {
	reader := bufio.NewReader(os.Stdin)

keyLoop:
	for {
		input, _, err := reader.ReadLine()

		if err != nil {
			fmt.Printf("could not process input %v\n", input)
			close(ch)
			break keyLoop
		}

		switch string(input) {
		case "`":
			fmt.Println("Quit requested")

			ch <- "quit"
			break keyLoop
		default:
			ch <- ""
		}
	}

	fmt.Println("Leaving key scan")
}
