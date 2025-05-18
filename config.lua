Config = {}

Config.ReviveInvoice = 100          -- Invoice for Revive & Heal
Config.ReviveInvoiceIlegal = 250    -- Invoice for Revive & Heal on Ilegal Medicers (black money)
Config.UseProgressBar = true        -- Disable if you want to revive instantly
Config.EMSJobName = 'ambulance'
Config.MaxEMS = 10                  -- Number of EMS that the bot revives with
Config.PedModel = "s_m_m_doctor_01" -- The model used for the NPCs.
Config.PedSpawnCheckInterval = 5000 -- The interval (in milliseconds) at which the script checks if NPCs need to be spawned.
Config.EnableWebhook = true         -- Enable if you want to send a webhook when a player is revived. (Add the webhook URL to the local in the server.lua file)