#!/bin/sh

echo "Enter programming language (Python or JavaScript):"
read lang
while [ "$lang" != "Python" ] && [ "$lang" != "JavaScript" ]; do
    echo "Invalid input. Please type 'Python' or 'JavaScript':"
    read lang
done

echo "Enter your Discord bot token:"
read token

echo "Enter custom commands in the format COMMAND RESPONSE:Your response"
echo "Type :fexit when done."

custom_commands=""
while true; do
    read line
    if [ "$line" = ":fexit" ]; then
        break
    fi
    custom_commands="$custom_commands
$line"
done

echo "Enter directory name to create the bot in:"
read dir_name

mkdir -p "$dir_name"
cd "$dir_name" || exit

echo "DISCORD_TOKEN=$token" > .env

json="{"
first=1
while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    command_name=$(echo "$cmd" | cut -d' ' -f1)
    response=$(echo "$cmd" | sed "s/^$command_name RESPONSE://")
    if [ $first -eq 1 ]; then
        json="$json\"$command_name\":\"$response\""
        first=0
    else
        json="$json, \"$command_name\":\"$response\""
    fi
done <<EOF
$custom_commands
EOF
json="$json}"
echo "$json" > custom_responses.json

if [ "$lang" = "JavaScript" ]; then
cat > index.js << 'EOF'
require('dotenv').config();
const { Client, GatewayIntentBits } = require('discord.js');
const fs = require('fs');

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent]
});

let customResponses = {};
function loadResponses() {
  try {
    const data = fs.readFileSync('custom_responses.json', 'utf8');
    customResponses = JSON.parse(data);
  } catch (err) {
    console.error('Error loading responses:', err);
  }
}
function saveResponses() {
  try {
    fs.writeFileSync('custom_responses.json', JSON.stringify(customResponses, null, 4));
  } catch (err) {
    console.error('Error saving responses:', err);
  }
}

client.once('ready', () => {
  console.log(`${client.user.tag} has logged in!`);
  loadResponses();
});

client.on('messageCreate', message => {
  if (message.author.bot) return;
  const content = message.content.toLowerCase();
  if (content.startsWith('!')) {
    const command = content.slice(1).split(' ')[0];
    if (customResponses[command]) message.channel.send(customResponses[command]);
  }
});

client.on('messageCreate', message => {
  if (message.content === '!hello') message.reply(`Hello ${message.author.username}!`);
  else if (message.content === '!ping') message.reply(`Pong! ${Math.round(client.ws.ping)}ms`);
  else if (message.content === '!info') message.reply(`Bot Info: ${client.user.tag}`);
});

client.login(process.env.DISCORD_TOKEN);
EOF

else
cat > bot.py << 'EOF'
import discord
from discord.ext import commands
import json
import os
from dotenv import load_dotenv

load_dotenv()
intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix='!', intents=intents)

def load_responses():
    try:
        with open('custom_responses.json','r') as f:
            return json.load(f)
    except FileNotFoundError:
        return {}

def save_responses(responses):
    with open('custom_responses.json','w') as f:
        json.dump(responses,f,indent=4)

custom_responses = load_responses()

@bot.event
async def on_ready():
    print(f'{bot.user.name} has logged in!')

@bot.event
async def on_message(message):
    if message.author.bot:
        return
    content_lower = message.content.lower()
    if content_lower.startswith('!'):
        cmd = content_lower[1:].split()[0]
        if cmd in custom_responses:
            await message.channel.send(custom_responses[cmd])
            return
    await bot.process_commands(message)

@bot.command()
async def hello(ctx):
    await ctx.send(f'Hello {ctx.author.mention}!')

@bot.command()
async def ping(ctx):
    await ctx.send(f'Pong! {round(bot.latency*1000)}ms')

@bot.command()
async def info(ctx):
    embed = discord.Embed(title="Bot Info", color=0x00ff00)
    embed.add_field(name="Guilds", value=len(bot.guilds))
    embed.add_field(name="Commands", value=len(bot.commands))
    await ctx.send(embed=embed)

if __name__ == '__main__':
    bot.run(os.getenv('DISCORD_TOKEN'))
EOF
fi
