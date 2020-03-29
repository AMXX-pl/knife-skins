#include <amxmodx>
#include <colorchat>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <cstrike>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#pragma semicolon 1

#define ForArray(%1,%2) for(new %1 = 0; %1 < sizeof %2; %1++)
#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)

// Jailbreak friendly required jail_api_jailbreak to be edited.
//#define JAILBREAK_FRIENDLY
//#define DEBUG_MODE

#define VIP_FLAG "t"
#define SUPER_VIP_FLAG "n"

#define ONLY_TT 1
#define ONLY_CT 2
#define BOTH_TEAMS (ONLY_TT | ONLY_CT)

enum (+= 1)
{
	sd_v,
	sd_p,
	sd_name,
	sd_flags,
	sd_team
};

/*
	{
		(STR) "V_",
		(STR) "P_",
		(STR) "Name",
		(STR) "Flags",
		(INT) team
	}
*/
static const SkinsData[][][] =
{
	{ "models/v_knife.mdl", "models/p_knife.mdl", "Domyslny", "", ONLY_TT }
};

static const WeaponEntityNames[][] =
{
	"", "weapon_p228", "", "weapon_scout",
	"weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", 
	"weapon_ump45", "weapon_sg550","weapon_galil", "weapon_famas", 
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", 
	"weapon_m249", "weapon_m3",  "weapon_m4a1",  "weapon_tmp", 
	"weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90"
};

static const menu_commands[][] =
{
	"/skiny",
	"/skins",
	"/kosy",
	"/knife",
	"/noze",
	"/noz"
};

new user_knife[33] = {-1, ...},
	current_weapon[33],
	vault_handle;

/*
	[ Forwards ]
*/
public plugin_init()
{
	register_plugin("Skiny do kosy", "v1.2", AUTHOR);

	registerCommands(menu_commands, sizeof(menu_commands), "knife_menu");

	RegisterHam(Ham_Spawn, "player", "player_spawned", true);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_knife", "add_knife", true);

	ForRange(i, 1, sizeof(WeaponEntityNames) - 1)
	{
		if(!WeaponEntityNames[i][0])
		{
			continue;
		}
		
		RegisterHam(Ham_Item_Deploy, WeaponEntityNames[i], "weapon_deploy", true);
	}

	vault_handle = nvault_open("knife_skins.nvault");
}

public plugin_precache()
{
	ForArray(i, SkinsData)
	{
		precache_model(SkinsData[i][sd_v]);
		precache_model(SkinsData[i][sd_p]);
	}
}

public client_putinserver(index)
{
	if(is_user_hltv(index))
	{
		return;
	}

	load_knife_data(index);
}

public client_disconnect(index)
{
	if(is_user_hltv(index))
	{
		return;
	}

	save_knife_data(index);
}

public player_spawned(index)
{
	if(!is_user_alive(index))
	{
		return;
	}

	static const OFFSET_ACTIVE_ITEM = 41;
	static const OFFSET_LINUX = 5;

	static weapon_ent;
	weapon_ent = get_pdata_cbase(index, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);

	if(!pev_valid(weapon_ent))
	{
		return;
	}
	
	update_model(index);
}

public add_knife(const item, const index)
{
	if(!pev_valid(item))
	{
		return;
	}

	update_model(index);
}

public weapon_deploy(weapon)
{
	static const OFFSET_WEAPONOWNER = 41;
	static const OFFSET_LINUX_WEAPONS = 4;

	static index,
		weapon_index;

	index = get_pdata_cbase(weapon, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
	weapon_index = cs_get_weapon_id(weapon);

	current_weapon[index] = weapon_index;

	if(current_weapon[index] != CSW_KNIFE || !can_wear_skin(index, user_knife[index]))
	{
		return;
	}

	update_model(index);
}

#if defined JAILBREAK_FRIENDLY
public OnFight(status)
{
	if(status)
	{
		return;
	}

	#define ForPlayers(%1) for(new %1 = 1; %1 <= 32; %1++)

	ForPlayers(i)
	{
		if(is_user_hltv(i))
		{
			continue;
		}

		update_model(i);
	}
}
#endif

public knife_menu(index)
{
	new menu_index = menu_create("\r[\dWybor Kosy\r]", "knife_menu_handler"),
		menu_item[64],
		bool:wear;

	ForArray(i, SkinsData)
	{
		wear = can_wear_skin(index, i);

		// Get the knife name.
		formatex(menu_item, charsmax(menu_item), "\r[%s%s\r]", wear ? "\w" : "\d", SkinsData[i][sd_name]);

		// Format VIP & SVIP postfix.
		if(is_vip_skin(i) && is_super_vip_skin(i))
		{
			format(menu_item, charsmax(menu_item), "%s\r | [%sVIP & SVIP\r]", menu_item, wear ? "\w" : "\d");
		}

		// Format VIP postfix.
		else if(is_vip_skin(i))
		{
			format(menu_item, charsmax(menu_item), "%s\r | [%sVIP\r]", menu_item, wear ? "\w" : "\d");
		}

		// Format SVIP postfix.
		else if(is_super_vip_skin(i))
		{
			format(menu_item, charsmax(menu_item), "%s\r | [%sSVIP\r]", menu_item, wear ? "\w" : "\d");
		}

		menu_additem(menu_index, menu_item);
	}

	menu_display(index, menu_index);

	return PLUGIN_HANDLED;
}

public knife_menu_handler(index, menu_index, item)
{
	menu_destroy(menu_index);

	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}

	set_model(index, item);

	return PLUGIN_HANDLED;
}

/*
	[ Functions ]
*/
stock set_model(index, skin)
{
	static skin_flags;

	skin_flags = get_skin_access(skin);

	// Player has no access to that knife.
	if(skin_flags && !(get_user_flags(index) & skin_flags))
	{
		static message[200];

		formatex(message, charsmax(message), "[SKINY KOSY]^x01 Nie mozesz wybrac tej kosy.");

		if(is_super_vip_skin(skin) && is_vip_skin(skin))
		{
			add(message, charsmax(message), "Kup^x04 Super VIPa^x01 lub^x04 VIPa^x01, jesli chcesz jej uzywac.");
		}
		else if(is_super_vip_skin(skin))
		{
			add(message, charsmax(message), "Kup^x04 Super VIPa^x01, jesli chcesz jej uzywac.");
		}
		else
		{
			add(message, charsmax(message), "Kup^x04 VIPa^x01, jesli chcesz jej uzywac.");
		}

		ColorChat(index, RED, message);
	
		return;
	}
	
	user_knife[index] = skin;
	
	ColorChat(index, RED, "[SKINY KOSY]^x01 Wybrany skin:^x04 %s^x01.", SkinsData[skin][sd_name]);

	// Player not alive, don't change the models.
	if(!is_user_alive(index) || current_weapon[index] != CSW_KNIFE)
	{
		return;
	}

	// Apply the models.
	set_pev(index, pev_viewmodel2, SkinsData[skin][sd_v]);
	set_pev(index, pev_weaponmodel2, SkinsData[skin][sd_p]);
}

stock update_model(index)
{
	if(!is_user_alive(index) || current_weapon[index] != CSW_KNIFE || !can_wear_skin(index, user_knife[index]))
	{
		return;
	}

	set_pev(index, pev_viewmodel2, SkinsData[user_knife[index]][sd_v]);
	set_pev(index, pev_weaponmodel2, SkinsData[user_knife[index]][sd_p]);
}

bool:is_vip_skin(skin)
{
	return bool:(get_skin_access(skin) & read_flags(VIP_FLAG));
}

bool:is_super_vip_skin(skin)
{
	return bool:(get_skin_access(skin) & read_flags(SUPER_VIP_FLAG));
}

bool:can_wear_skin(index, skin)
{
	if(skin == -1)
	{
		return false;
	}

	static skin_flags;

	skin_flags = get_skin_access(skin);

	// Flags missing.
	if(skin_flags && !(get_user_flags(index) & skin_flags))
	{
		return false;
	}

	// Team not matching.
	if(!(get_user_team(index) & SkinsData[skin][sd_team][0]))
	{
		return false;
	}

	return true;
}

load_knife_data(index)
{
	static key[64],
		skin;

	get_user_name(index, key, charsmax(key));

	format(key, charsmax(key), "knife-%s", key);

	skin = nvault_get(vault_handle, key);

	#if defined DEBUG_MODE

	log_amx("[Load knife data] User: #%i (%s), Data: %i", index, key, skin);

	#endif

	if(can_wear_skin(index, skin))
	{
		user_knife[index] = -1;
	}
	else
	{
		user_knife[index] = skin;
	}
}

save_knife_data(index)
{
	static key[64],
		value[20];
	
	get_user_name(index, key, charsmax(key));

	format(key, charsmax(key), "knife-%s", key);
	formatex(value, charsmax(value), "%i", user_knife[index]);

	nvault_set(vault_handle, key, value);

	#if defined DEBUG_MODE

	log_amx("[Save knife data] User: #%i (%s), Data: %s", index, key, value);

	#endif
}

stock get_skin_access(skin)
{
	if(strlen(SkinsData[skin][sd_flags]))
	{
		return read_flags(SkinsData[skin][sd_flags]);
	}
	
	return 0;
}

stock registerCommands(const array[][], arraySize, function[], include_say = true)
{
	#if !defined ForRange

		#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)

	#endif

	#if AMXX_VERSION_NUM > 183
	
	ForRange(i, 0, arraySize - 1)
	{
		ForRange(j, 0, 1)
		{
			if (include_say)
			{
				register_clcmd(fmt("%s %s", !j ? "say" : "say_team", array[i]), function);
			}
			else
			{
				register_clcmd(array[i], function);
			}
		}
	}

	#else

	new newCommand[33];

	ForRange(i, 0, arraySize - 1)
	{
		ForRange(j, 0, 1)
		{
			if (include_say)
			{
				formatex(newCommand, charsmax(newCommand), "%s %s", !j ? "say" : "say_team", array[i]);
				register_clcmd(newCommand, function);
			}
			else
			{
				register_clcmd(array[i], function);
			}
		}
	}

	#endif
}