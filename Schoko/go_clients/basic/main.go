package main

import (
	"fmt"
	"log"

	"go.bug.st/serial"
)

func main() {
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

	// Read "Ok\r\n" from UART Rx
	// rxBuf := make([]byte, 4)

	fmt.Println("Reading...")
	// for i := 0; i < 4; i++ {
	// 	buf := fetchByte(port)
	// 	rxBuf = append(rxBuf, buf)
	// }
	// fmt.Println("Got:", string(rxBuf))

	// for i := 0; i < 100000; i++ {
	uartSend(0x62, port)
	// }

	fmt.Println("Good bye")
}

// ---------------------------------------------------------
// Functions
// ---------------------------------------------------------
func fetchByte(port serial.Port) byte {
	rxBuf := make([]byte, 1)

	_, err := port.Read(rxBuf)
	if err != nil {
		fmt.Printf("UART port read error: %v\n", err)
	}

	return rxBuf[0]
}

func fetchBytes(port serial.Port, count int) []byte {
	rxBuf := make([]byte, count)

	_, err := port.Read(rxBuf)
	if err != nil {
		fmt.Printf("UART port read error: %v\n", err)
	}

	return rxBuf
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
