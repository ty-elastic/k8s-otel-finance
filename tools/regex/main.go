package main

import (
	"fmt"
	"regexp"
)

func main() {
	logLine := "2025-06-26 14:09:20.513 UTC [68] LOG:  execute S_1: ROLLBACK"

	// Define a regular expression to capture timestamp, log level, username, and IP address.
	// The parentheses create capturing groups.
	re := regexp.MustCompile(`^(?P<timestamp_field>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} [A-z]+)\s\[\d{2}\]\s(?P<level_field>[A-Z]+):.*$`)

	// Find all submatches in the string. The first element of the slice will be the full match,
	// followed by the content of each capturing group.
	matches := re.FindStringSubmatch(logLine)

	if len(matches) > 0 {
		fmt.Println("Full Match:", matches[0])
		fmt.Println("Timestamp:", matches[1])
		fmt.Println("Log Level:", matches[2])
	} else {
		fmt.Println("No match found.")
	}
}
