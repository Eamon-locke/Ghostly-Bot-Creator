#!/bin/sh

echo "Enter your Discord bot token:"
read BOT_TOKEN
echo "Enter your guild ID:"
read GUILD_ID
echo "Enter your category ID:"
read CATEGORY_ID
echo "Enter your logs channel ID:"
read LOGS_CHANNEL_ID
echo "Choose programming language (Python/JavaScript):"
read LANGUAGE
echo "Enter the directory name for your bot:"
read DIR_NAME

mkdir -p "$DIR_NAME"
cd "$DIR_NAME" || exit

cat > config.json <<EOF
{
  "token": "$BOT_TOKEN",
  "guild_id": "$GUILD_ID",
  "category_id": "$CATEGORY_ID",
  "logs_channel_id": "$LOGS_CHANNEL_ID"
}
EOF

if [ "$LANGUAGE" = "Python" ] || [ "$LANGUAGE" = "python" ]; then
    echo "py-cord" > requirements.txt
    cat > bot.py <<'EOF'
import discord
from discord.ui import Select, View
import json

intents = discord.Intents.default()
intents.message_content = True

with open("config.json") as f:
    config = json.load(f)

bot = discord.Bot(intents=intents)

class TicketSelect(Select):
    def __init__(self):
        options = [
            discord.SelectOption(label="Open a Ticket", description="Get support from the team.", emoji="🎟️"),
            discord.SelectOption(label="Bug Report", description="Report a bug or issue.", emoji="🐞"),
            discord.SelectOption(label="Feature Request", description="Suggest a new feature.", emoji="💡")
        ]
        super().__init__(placeholder="Choose a ticket type...", min_values=1, max_values=1, options=options)
    async def callback(self, interaction):
        category = interaction.guild.get_channel(int(config["category_id"]))
        ticket_channel = await interaction.guild.create_text_channel(
            f'ticket-{interaction.user.name}',
            category=category,
            overwrites={
                interaction.guild.default_role: discord.PermissionOverwrite(read_messages=False),
                interaction.user: discord.PermissionOverwrite(read_messages=True, send_messages=True)
            }
        )
        await ticket_channel.send(f"Hello {interaction.user.mention}, how can we assist you today?")
        await interaction.response.send_message(f"Your ticket has been created: {ticket_channel.mention}", ephemeral=True)

class TicketView(View):
    def __init__(self):
        super().__init__()
        self.add_item(TicketSelect())

@bot.event
async def on_ready():
    print(f'Logged in as {bot.user}')

@bot.slash_command(name="ticket", description="Open a support ticket")
async def ticket(ctx):
    await ctx.send("Please select a ticket type:", view=TicketView())

@bot.event
async def on_raw_message_delete(payload):
    if payload.channel_id == int(config["logs_channel_id"]):
        return
    channel = bot.get_channel(payload.channel_id)
    if isinstance(channel, discord.TextChannel) and channel.category_id == int(config["category_id"]):
        logs_channel = bot.get_channel(int(config["logs_channel_id"]))
        await logs_channel.send(f"Ticket {channel.name} was deleted.")

bot.run(config["token"])
EOF
else
    cat > package.json <<'EOF'
{
  "name": "discord-bot",
  "version": "1.0.0",
  "main": "bot.js",
  "type": "module",
  "dependencies": {
    "discord.js": "^14.0.0"
  }
}
EOF

    cat > bot.js <<'EOF'
import { Client, GatewayIntentBits, Partials, ActionRowBuilder, StringSelectMenuBuilder, PermissionsBitField, Events } from "discord.js";
import { token, guild_id, category_id, logs_channel_id } from "./config.json";

const client = new Client({
    intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent],
    partials: [Partials.Channel]
});

client.once(Events.ClientReady, () => {
    console.log(`Logged in as ${client.user.tag}`);
});

client.on(Events.InteractionCreate, async interaction => {
    if (interaction.isChatInputCommand() && interaction.commandName === "ticket") {
        const select = new StringSelectMenuBuilder()
            .setCustomId("ticket_select")
            .setPlaceholder("Choose a ticket type...")
            .addOptions([
                { label: "Open a Ticket", description: "Get support from the team.", emoji: "🎟️", value: "open_ticket" },
                { label: "Bug Report", description: "Report a bug or issue.", emoji: "🐞", value: "bug_report" },
                { label: "Feature Request", description: "Suggest a new feature.", emoji: "💡", value: "feature_request" }
            ]);
        const row = new ActionRowBuilder().addComponents(select);
        await interaction.reply({ content: "Please select a ticket type:", components: [row], ephemeral: true });
    }

    if (interaction.isStringSelectMenu() && interaction.customId === "ticket_select") {
        const category = interaction.guild.channels.cache.get(category_id);
        const channelName = `ticket-${interaction.user.username.toLowerCase()}`;
        const ticketChannel = await interaction.guild.channels.create({
            name: channelName,
            type: 0,
            parent: category_id,
            permissionOverwrites: [
                { id: interaction.guild.id, deny: [PermissionsBitField.Flags.ViewChannel] },
                { id: interaction.user.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] }
            ]
        });
        await ticketChannel.send(`Hello ${interaction.user}, how can we assist you today?`);
        await interaction.reply({ content: `Your ticket has been created: ${ticketChannel}`, ephemeral: true });
    }
});

client.on(Events.ChannelDelete, async channel => {
    if (channel.parentId === category_id) {
        const logsChannel = await client.channels.fetch(logs_channel_id);
        logsChannel.send(`Ticket ${channel.name} was deleted.`);
    }
});

client.login(token);
EOF
fi
