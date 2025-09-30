-- Ghostly Bot Creator

local function clear()
  os.execute("clear || cls")
end

local function pause()
  io.write("\nPress Enter to continue...")
  io.read()
end

local function showMenu()
  clear()
  print("==================================")
  print("       Ghostly Bot Creator        ")
  print("==================================")
  print("An app that generates custom Discord bot code in your favorite language,")
  print("letting you pick features and get ready-to-run scripts—giving you full")
  print("control without hosting.\n")
  print("Available Features:")
  print("1. Custom Commands\n")
  io.write("Select a feature (1): ")
  local choice = io.read()
  return choice
end

local function runCustomCommands()
  print("\nSetting executable permission and running Custom-Commands-Bot.sh...")
  os.execute("chmod +x Custom-Commands-Bot.sh")
  os.execute("./Custom-Commands-Bot.sh")
end

local function main()
  local choice = showMenu()
  if choice == "1" then
    runCustomCommands()
  else
    print("\nInvalid selection!")
    pause()
  end
end

main()