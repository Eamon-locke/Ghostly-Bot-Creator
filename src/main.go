package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func clear() {
	fmt.Print("\033[2J\033[H")
}

func pause() {
	fmt.Print("\n\033[1;33mPress Enter to continue...\033[0m")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func showMenu() string {
	clear()
	fmt.Println("\033[1;36m==================================\033[0m")
	fmt.Println("\033[1;35m       Ghostly Bot Creator        \033[0m")
	fmt.Println("\033[1;36m==================================\033[0m")
	fmt.Println("\033[0;37mAn app that generates custom Discord bot code in your favorite language,")
	fmt.Println("letting you pick features and get ready-to-run scripts—giving you full")
	fmt.Println("control without hosting.\033[0m\n")
	fmt.Println("\033[1;32mAvailable Features:\033[0m")
	fmt.Println("\033[1;34m1.\033[0m Custom Commands")
	fmt.Println("\033[1;34m2.\033[0m Tickets\n")
	fmt.Print("\033[1;33mSelect a feature (1-2): \033[0m")
	reader := bufio.NewReader(os.Stdin)
	choice, _ := reader.ReadString('\n')
	return strings.TrimSpace(choice)
}

func runFeature(script string) {
	fmt.Printf("\033[1;32m\nRunning %s...\033[0m\n", script)
	exec.Command("chmod", "+x", script).Run()
	exec.Command(script).Run()
}

func main() {
	choice := showMenu()
	switch choice {
	case "1":
		runFeature("features/Custom-Commands-Bot.sh")
	case "2":
		runFeature("features/Ticket-Bot.sh")
	default:
		fmt.Println("\033[1;31mInvalid selection!\033[0m")
		pause()
	}
}
