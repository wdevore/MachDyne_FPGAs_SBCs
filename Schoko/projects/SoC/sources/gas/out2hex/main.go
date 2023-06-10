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

	fmt.Printf("Successfully Opened `%s`\n", fileName)

	scanner := bufio.NewScanner(dumpfile)

	startExpr, _ := regexp.Compile(`([0-9A-Fa-f]+) <_start>:`)
	instrExpr, _ := regexp.Compile(`([0-9A-Fa-f]+)([:\t]+)([0-9A-Fa-f]+)`)

	// Scan for the entry point
	v, isMatch, err := matchEntryPoint(scanner, startExpr)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	if !isMatch {
		fmt.Println(err)
		os.Exit(-2)
	}

	firmware, err := os.Create("../monitor/firmware.hex")
	if err != nil {
		fmt.Println(err)
		os.Exit(-4)
	}

	defer firmware.Close()

	entryPoint, err := StringHexToInt(v)
	fmt.Println(entryPoint)

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

		addr := fields[1]
		location, err := StringHexToInt(addr)
		if err != nil {
			fmt.Println(err)
			os.Exit(-3)
		}

		location -= entryPoint
		di := fields[3]
		dataOrInstruction, err := StringHexToInt(di)
		if err != nil {
			fmt.Println(err)
			os.Exit(-3)
		}

		hexLoc := IntToHexString(location)
		hexData := IntToHexString(dataOrInstruction)

		outLine := fmt.Sprintf("@%s %s\n", hexLoc, hexData)
		firmware.WriteString(outLine)
	}

	fmt.Println("Good bye")
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

func matchEntryPoint(scanner *bufio.Scanner, expr *regexp.Regexp) (value string, isMatch bool, err error) {
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}

		fields := expr.FindStringSubmatch(line)
		if len(fields) > 0 {
			return fields[1], true, nil
		}
	}

	return "", false, nil
}
