package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

// ---------------------------------------------------------
// A utility to convert a risc-v objdump text file into a
// hex file suitable for embedding into a fpga bit stream
// via $readmenh
// ---------------------------------------------------------

func main() {
	args := os.Args[1:]

	//
	// Search for the "_start" entry point. The address we find
	// is what we subtract from all instruction addresses.
	fileName := args[0]

	// Open our jsonFile
	dumpfile, err := os.Open(fileName)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	// defer the closing of our jsonFile so that we can parse it later on
	defer dumpfile.Close()

	//fmt.Printf("Successfully Opened `%s`\n", fileName)

	scanner := bufio.NewScanner(dumpfile)

	instrExpr, _ := regexp.Compile(`([0-9A-Fa-f]+):([\t]+)([0-9A-Fa-f]+)`)

	firmware, err := os.Create("../monitor/firmware.hex")
	if err != nil {
		fmt.Println(err)
		os.Exit(-4)
	}

	defer firmware.Close()

	// Start scanning instructions
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}

		fields := instrExpr.FindStringSubmatch(line)
		if len(fields) == 0 {
			continue
		}

		dataOrInstruction, err := StringHexToInt(fields[3])
		if err != nil {
			fmt.Println(err)
			os.Exit(-3)
		}

		intAddr, err := StringHexToInt(fields[1])
		if err != nil {
			fmt.Println(err)
			os.Exit(-3)
		}

		hexData := IntToHexString(dataOrInstruction)
		hexAddr := IntToHexString(intAddr)

		outLine := fmt.Sprintf("@%s %s\n", hexAddr, hexData)
		firmware.WriteString(outLine)
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

func IntToHexString(value int64) string {
	return fmt.Sprintf("%08X", value)
}
