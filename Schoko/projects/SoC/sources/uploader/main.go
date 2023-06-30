package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"go.bug.st/serial"
)

// ---------------------------------------------------------
// A utility for uploading RISC-V programs via UART into
// the Ranger Retro SoC
// ---------------------------------------------------------
//
// The file format is:
// @00000000 00A00513
// @00000001 00100073
// ...
// OR
// @00000000
// 00A00513 00000001 00000001 00000001
// @00000001
// 00100073 00A00513 00000001 00000001
// 00A00513 00000001 00000001 00000001
// 00A00513 00000001 00000001 00000001
// 00A00513 00000001 00000001 00000001
// ...

// go run . /media/RAMDisk/filename.hex

const (
	SOT_Signal byte = 0x01
	DAT_Signal byte = 0x02
	EOT_Signal byte = 0x03
	ADR_Signal byte = 0x04
)

// Anything < 10 is too small of a delay between bytes
var interByteDelay = 1500

func main() {
	args := os.Args[1:]

	fileName := args[0]

	// Open the app text file that contains code
	appfile, err := os.Open(fileName)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	defer appfile.Close()

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

	//fmt.Printf("Successfully Opened `%s`\n", fileName)

	scanner := bufio.NewScanner(appfile)

	addrExpr, _ := regexp.Compile(`@(([0-9a-zA-Z]{2,2})([0-9a-zA-Z]{2,2})([0-9a-zA-Z]{2,2})([0-9a-zA-Z]{2,2}))`)
	instrExpr, _ := regexp.Compile(`(([0-9a-zA-Z]{2,2})([0-9a-zA-Z]{2,2})([0-9a-zA-Z]{2,2})([0-9a-zA-Z]{2,2}))`)

	// First send signal SoT. These signals are defined in monitor.s
	uartSend(SOT_Signal, port)

	// Give target time to process byte
	time.Sleep(time.Microsecond * time.Duration(interByteDelay))

	// The address is in word-addressing format.
	// For example,
	// --- Word addressing little-endian format ---
	// @00000400
	// 00A00513 00500593 00B502B3 00100073

	// Verses byte-addressing form
	// --- Byte addressing big-endian format ---
	// @00001000
	// 13 05 A0 00 93 05 50 00 B3 02 B5 00 73 00 10 00

	// Start scanning instructions
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}

		fields := addrExpr.FindStringSubmatch(line)
		if len(fields) > 0 {
			fmt.Println("Address")
			// We hit an address
			uartSend(ADR_Signal, port)
			time.Sleep(time.Microsecond * time.Duration(interByteDelay))

			sendData(fields[5], port)
			time.Sleep(time.Microsecond * time.Duration(interByteDelay))

			sendData(fields[4], port)
			time.Sleep(time.Microsecond * time.Duration(interByteDelay))

			sendData(fields[3], port)
			time.Sleep(time.Microsecond * time.Duration(interByteDelay))

			sendData(fields[2], port)
			time.Sleep(time.Microsecond * time.Duration(interByteDelay))
		} else {
			// If the Makefile's objcopy parm verilog-data-width is
			// set to 4 then each line has 4 words on it.
			words := strings.Split(line, " ")
			for _, word := range words {
				fields = instrExpr.FindStringSubmatch(word)
				if len(fields) == 0 {
					continue
				}
				// Group 1 is address
				// Group 3,4,5,6 are the bytes

				sendData(fields[5], port) // MSB
				sendData(fields[4], port)
				sendData(fields[3], port)
				sendData(fields[2], port) // LSB
			}
		}
	}

	fmt.Println("EOT")

	uartSend(EOT_Signal, port)

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

func sendData(b string, port serial.Port) {
	byte4, err := StringHexToInt(b)
	if err != nil {
		fmt.Println(err)
		os.Exit(-4)
	}

	uartSend(DAT_Signal, port)
	time.Sleep(time.Microsecond * time.Duration(interByteDelay))

	hex := UintToHexString(uint64(byte4), true)
	fmt.Printf("Byte: %s\n", hex)

	uartSend(byte(byte4), port)
	time.Sleep(time.Microsecond * time.Duration(interByteDelay))
}

func StringHexToInt(hex string) (value int64, err error) {
	hex = strings.Replace(hex, "0x", "", 1)

	value, err = strconv.ParseInt(hex, 16, 64)
	if err != nil {
		return 0, err
	}
	return value, nil
}

func UintToHexString(value uint64, with0x bool) string {
	if with0x {
		return fmt.Sprintf("0x%08X", value)
	} else {
		return fmt.Sprintf("%08X", value)
	}

}
