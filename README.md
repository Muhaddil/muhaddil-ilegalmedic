# muhaddil-ilegalmedic

A simple and highly configurable illegal medic system for FiveM servers using ESX. This script allows players to be revived or healed by both legal and illegal medics (NPCs), with different payment methods and fully dynamic configuration. All NPC locations and types can be managed directly in-game through admin commands, without the need to edit configuration files. You can add, remove, or list medic NPCs (legal or illegal) at any time, making it easy to adapt the system to your server's needs. Additionally, you can configure prices, payment methods, progress bar usage, EMS requirements, and more, all from the config file or in-game, providing maximum flexibility and control.

## Features

- Legal and illegal medic NPCs that can revive or heal players.
- Configurable prices for legal (money/bank) and illegal (black money) services.
- Progress bar support for immersive revival.
- EMS (ambulance job) online check: if enough EMS are online, NPCs will not revive.
- Discord webhook logging for illegal revives.
- Multi-language support (English, Spanish, French).
- Easy configuration for NPC behavior and parameters.

## Requirements

- [ESX Legacy](https://github.com/esx-framework/esx-legacy)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [esx_ambulancejob](https://github.com/esx-framework/esx_ambulancejob)

## Installation

1. Download or clone this repository into your server's `resources` folder.
2. Ensure the following dependencies are started before this resource in your `server.cfg`:  
ensure ox_lib  
ensure ox_target  
ensure es_extended  
ensure esx_ambulancejob  
ensure muhaddil-ilegalmedic  
3. Configure the script as needed (see below).

## Configuration

Edit `config.lua` to customize the script:

- `Config.ReviveInvoice`: Price for legal revive/heal (money or bank).
- `Config.ReviveInvoiceIlegal`: Price for illegal revive/heal (black money).
- `Config.UseProgressBar`: Enable/disable progress bar during revive.
- `Config.EMSJobName`: Name of the EMS job (default: 'ambulance').
- `Config.MaxEMS`: Minimum number of EMS online to disable NPC revive.
- `Config.PedModel`: Model used for medic NPCs.
- `Config.PedSpawnCheckInterval`: Interval (ms) to check and manage NPCs.

> **Important:**  
> Medic NPCs (legal and illegal) are **not configured in the config file anymore**.  
> **You must place them manually using in-game commands.**

## Admin Commands

- `/addnpccoords legal` — Add a legal medic NPC at your current position.
- `/addnpccoords illegal` — Add an illegal medic NPC at your current position.
- `/delnpccoords legal` — Open a menu to delete legal medic NPCs.
- `/delnpccoords illegal` — Open a menu to delete illegal medic NPCs.
- `/listnpccoords` — Print all saved NPC coordinates (legal and illegal) to the console.

Only administrators can use these commands.

## Localization
The script supports multiple languages. Edit or add files in the `locales` folder (en.json, es.json, fr.json) to customize messages.

## Usage
- Approach a legal or illegal medic NPC and interact using the target system (ox_target).
- Pay the required amount (money, bank, or black money) to be revived or healed.
- If enough EMS are online, NPCs will not offer revive services.
- Use the admin commands to add or remove NPCs as needed.

## Discord Webhook
To enable Discord logging for illegal revives, set your webhook URL in `server/main.lua`:

```lua
local webhook = 'YOUR-WEBHOOK-GOES-HERE'
```

## File Structure
- client/main.lua : Client-side logic for NPCs and interactions.
- server/main.lua : Server-side callbacks, payment, and logging.
- config.lua : Configuration file.
- locales/ : Localization files.
- fxmanifest.lua : Resource manifest.

## License
MIT License. See LICENSE for details.