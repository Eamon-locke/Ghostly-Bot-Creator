package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

var shells = []string{"bash", "zsh", "fish", "csh", "tcsh", "ksh"}

func clear() {
	fmt.Print("\033[2J\033[H")
}

func pause() {
	fmt.Print("\n\033[1;33mPress Enter to continue...\033[0m")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func checkDependency(dep string) bool {
	_, err := exec.LookPath(dep)
	return err == nil
}

func installShell(shell string) {
	fmt.Printf("\033[1;33mInstalling %s...\033[0m\n", shell)
	cmd := exec.Command("sh", "-c", "sudo apt-get update && sudo apt-get install -y "+shell)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("\033[1;31mFailed to install %s. Please install manually.\033[0m\n", shell)
		pause()
		os.Exit(1)
	}
}

func ensureShells() {
	for _, sh := range shells {
		if !checkDependency(sh) {
			fmt.Printf("\033[1;31m%s not found!\033[0m\n", sh)
			installShell(sh)
		}
	}
}

func ensurePythonPackages() {
	if !checkDependency("python3") {
		fmt.Println("\033[1;31mPython3 not found! Installing...\033[0m")
		cmd := exec.Command("sh", "-c", "sudo apt-get update && sudo apt-get install -y python3 python3-pip")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Run()
	}
	fmt.Println("\033[1;32mInstalling Python Discord packages...\033[0m")
	exec.Command("python3", "-m", "pip", "install", "--upgrade", "discord.py").Run()
	exec.Command("python3", "-m", "pip", "install", "--upgrade", "py-cord").Run()
}

func ensureNodePackages() {
	if !checkDependency("node") {
		fmt.Println("\033[1;31mNode.js not found! Installing...\033[0m")
		cmd := exec.Command("sh", "-c", "sudo apt-get update && sudo apt-get install -y nodejs npm")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Run()
	}
	fmt.Println("\033[1;32mInstalling Node.js Discord packages...\033[0m")
	exec.Command("npm", "install", "-g", "discord.js", "dotenv").Run()
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

func runFeature(script string, shellDeps []string, python bool, node bool) {
	for _, sh := range shellDeps {
		if !checkDependency(sh) {
			installShell(sh)
		}
	}
	if python {
		ensurePythonPackages()
	}
	if node {
		ensureNodePackages()
	}
	fmt.Printf("\033[1;32m\nRunning %s...\033[0m\n", script)
	exec.Command("chmod", "+x", script).Run()
	exec.Command(script).Run()
}

func main() {
	choice := showMenu()
	switch choice {
	case "1":
		runFeature("features/Custom-Commands-Bot.sh", shells, true, true)
	case "2":
		runFeature("features/Ticket-Bot.sh", shells, true, true)
	default:
		fmt.Println("\033[1;31mInvalid selection!\033[0m")
		pause()
	}
}