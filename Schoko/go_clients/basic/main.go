package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"go.bug.st/serial"
)

func main() {
	args := os.Args[1:]

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

	fmt.Println("Running...")
	// Scan incomming bytes for Null. The monitor will send a Null
	// when it completes
	// for i := 0; i < 4; i++ {
	// 	buf := fetchByte(port)
	// 	rxBuf = append(rxBuf, buf)
	// }
	// fmt.Println("Got:", string(rxBuf))

	byteToSend, err := StringHexToInt(args[0])
	if err != nil {
		fmt.Println("can't convert string to hex")
		log.Fatal(err)
	}
	uartSend(byte(byteToSend), port)
	// uartSend(0x0d, port)
	// uartSend(0x04, port) // End of Transmission (EoT) = exit

	// uartSend(0x31, port)
	// time.Sleep(time.Millisecond)
	// uartSend(0x32, port)
	// time.Sleep(time.Millisecond)
	// uartSend(0x33, port)
	// time.Sleep(time.Millisecond)
	// uartSend(0x0D, port)
	// time.Sleep(time.Millisecond)
	// uartSend(0x0A, port)
	// time.Sleep(time.Millisecond)

	// for i := 97; i < 97+10; i++ {
	// uartSend(byte(i), port)
	// time.Sleep(time.Second)
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

func StringHexToInt(hex string) (value int64, err error) {
	hex = strings.Replace(hex, "0x", "", 1)

	value, err = strconv.ParseInt(hex, 16, 64)
	if err != nil {
		return 0, err
	}
	return value, nil
}
