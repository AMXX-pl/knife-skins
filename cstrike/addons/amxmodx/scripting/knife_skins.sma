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
#define ForSkins(%1) for(new %1 = 0; %1 < ArraySize(skins_data); %1++)

// Jailbreak friendly requires jail_api_jailbreak to be edited.
//#define JAILBREAK_FRIENDLY
#define DISPLAY_TEAMS_IN_MENU
#define DISPLAY_DEBUG

#define VIP_FLAG "t"
#define SUPER_VIP_FLAG "n"

#define ONLY_TT 1
#define ONLY_CT 2
#define BOTH_TEAMS (ONLY_TT | ONLY_CT)

#define MAX_MODEL_LENGTH 90
#define MAX_MODEL_NAME 32

enum _:SkinsDataEnumerator (+= 1)
{
	sd_v[MAX_MODEL_LENGTH + 1],
	sd_p[MAX_MODEL_LENGTH + 1],
	sd_name[MAX_MODEL_NAME + 1],
	sd_flags[33],
	sd_team
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

static const ConfigFile[] = "addons/amxmodx/configs/knife_skins.cfg";

static const ChatPrefix[] = "[SKINY KOSY]";

static const PluginDictionary[] = "knife_skins.txt";

static const MenuCommands[][] =
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
	vault_handle,
	Array:skins_data;

/*
	[ Forwards ]
*/
public plugin_init()
{
	register_plugin("Skiny do kosy", "v1.5", AUTHOR);

	registerCommands(MenuCommands, sizeof(MenuCommands), "knife_menu");

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

	register_dictionary(PluginDictionary);
}

public plugin_precache()
{
	load_config();

	static v[MAX_MODEL_LENGTH + 1],
		p[MAX_MODEL_LENGTH + 1];

	ForSkins(i)
	{
		get_skin_v(i, v, charsmax(v));
		get_skin_p(i, p, charsmax(p));

		precache_model(v);
		precache_model(p);
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

#if AMXX_VERSION_NUM >= 190
public client_disconnected(index)
#else
public client_disconnect(index)
#endif
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
	if(!ArraySize(skins_data))
	{
		ColorChat(index, RED, "%s^x01 %L", ChatPrefix, LANG_PLAYER, "NO_SKINS_LOADED");

		return PLUGIN_HANDLED;
	}

	new menu_index,
		menu_title[64],
		menu_item[64],
		skin_name[MAX_MODEL_NAME + 1],
		skin_team[33],
		bool:wear,
		team;
	
	formatex(menu_title, charsmax(menu_title), "%L", LANG_PLAYER, "MENU_TITLE");

	menu_index = menu_create(menu_title, "knife_menu_handler");
	
	ForSkins(i)
	{
		wear = can_wear_skin(index, i);

		get_skin_name(i, skin_name, charsmax(skin_name));

		#if defined DISPLAY_TEAMS_IN_MENU
		
		team = get_skin_team(i);

		switch(team)
		{
			case ONLY_TT: { formatex(skin_team, charsmax(skin_team), "TT"); }
			case ONLY_CT: { formatex(skin_team, charsmax(skin_team), "CT"); }
			case BOTH_TEAMS: { formatex(skin_team, charsmax(skin_team), "CT & TT"); }
		}
		
		formatex(menu_item, charsmax(menu_item), "\r[%s%s\r] (%s)", wear ? "\w" : "\d", skin_name, skin_team);
		
		#else

		formatex(menu_item, charsmax(menu_item), "\r[%s%s\r]", wear ? "\w" : "\d", skin_name);
		
		#pragma unused team
		#pragma unused skin_team

		#endif

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
load_config()
{
	// File not found.
	if(!file_exists(ConfigFile))
	{
		static error[128];

		formatex(error, charsmax(error), "%L ^"%s^"", LANG_PLAYER, "MISSING_FILE", ConfigFile);

		set_fail_state(error);
	}

	// Init dynamic array.
	skins_data = ArrayCreate(SkinsDataEnumerator);

	new line_content[(MAX_MODEL_LENGTH + MAX_MODEL_NAME) * 2],
		line_length,
		skin_data[SkinsDataEnumerator];

	for(new i; read_file(ConfigFile, i, line_content, charsmax(line_content), line_length); i++)
	{
		// Skip commented lines.
		if(!line_content[0] || line_content[0] == ';' || !line_length)
		{
			continue;
		}

		parse(line_content,
			skin_data[sd_v], MAX_MODEL_LENGTH,
			skin_data[sd_p], MAX_MODEL_LENGTH,
			skin_data[sd_name], MAX_MODEL_NAME,
			skin_data[sd_flags], 32,
			skin_data[sd_team], 2);

		// Validate V_ and P_ models.		
		if(!validate_model(skin_data[sd_v], MAX_MODEL_LENGTH, false))
		{
			continue;
		}
		
		if(!validate_model(skin_data[sd_p], MAX_MODEL_LENGTH, true))
		{
			continue;
		}

		skin_data[sd_team] = str_to_num(skin_data[sd_team]);

		// Make sure 'team' stays in the range of actual teams.
		if(skin_data[sd_team] <= 0)
		{
			skin_data[sd_team] = 1;
		}
		else if(skin_data[sd_team] > BOTH_TEAMS)
		{
			skin_data[sd_team] = BOTH_TEAMS;
		}
		
		// Save the data.
		ArrayPushArray(skins_data, skin_data);
	}
}

bool:validate_model(model[], length, bool:is_p_model)
{
	static raw_model[MAX_MODEL_LENGTH + 1];

	// Make a copy of original model for debuging.
	copy(raw_model, charsmax(raw_model), model);

	// If P_ model was not supplied, we take the default one.
	if(is_p_model && !strlen(model))
	{
		copy(model, length, "models/p_knife.mdl");

		return true;
	}

	// Missing .mdl?
	if(!equal(model[strlen(model) - 4], ".mdl"))
	{
		add(model, length, ".mdl");
	}

	// Missing models/.
	if(containi(model, "models/") == -1)
	{
		format(model, length, "models/%s", model);
	}

	// File doesn't exist.
	if(!file_exists(model))
	{
		return false;
	}

	return true;
}

stock set_model(index, skin)
{
	static skin_flags,
		skin_name[MAX_MODEL_NAME + 1 + 1],
		team;

	skin_flags = get_skin_access(skin);
	team = get_skin_team(skin);
	get_skin_name(skin, skin_name, charsmax(skin_name));

	// Player has no access to that knife.
	if(skin_flags && !(get_user_flags(index) & skin_flags))
	{
		static message[200];

		formatex(message, charsmax(message), "%s^x01 %L. ", ChatPrefix, LANG_PLAYER, "CANT_CHOOSE_THAT_KNIFE");

		if(is_super_vip_skin(skin) && is_vip_skin(skin))
		{
			format(message, charsmax(message), "%s%L", message, LANG_PLAYER, "BUY_SVIP_OR_VIP");
		}
		else if(is_super_vip_skin(skin))
		{
			format(message, charsmax(message), "%s%L", message, LANG_PLAYER, "BUY_SVIP");
		}
		else
		{
			format(message, charsmax(message), "%s%L", message, LANG_PLAYER, "BUY_VIP");
		}

		ColorChat(index, RED, message);

		return;
	}

	if(team != BOTH_TEAMS && team != get_user_team(index))
	{
		static message[200];

		formatex(message, charsmax(message), "%s^x01 %L^x04 %s^x01.", ChatPrefix, LANG_PLAYER, "SKIN_ONLY_FOR_TEAM", team == ONLY_CT ? "CT" : "TT");

		ColorChat(index, RED, message);

		return;
	}
	
	user_knife[index] = skin;
	
	ColorChat(index, RED, "%s^x01 %L:^x04 %s^x01.", ChatPrefix, LANG_PLAYER, "CHOSEN_SKIN", skin_name);

	// Player not alive, don't change the models.
	if(!is_user_alive(index) || current_weapon[index] != CSW_KNIFE)
	{
		return;
	}

	static v[MAX_MODEL_LENGTH + 1],
		p[MAX_MODEL_LENGTH + 1];
	
	get_skin_v(skin, v, charsmax(v));
	get_skin_p(skin, p, charsmax(p));

	// Apply the models.
	set_pev(index, pev_viewmodel2, v);
	set_pev(index, pev_weaponmodel2, p);
}

stock update_model(index)
{
	if(!is_user_alive(index) || current_weapon[index] != CSW_KNIFE || !can_wear_skin(index, user_knife[index]))
	{
		return;
	}

	static v[MAX_MODEL_LENGTH + 1],
		p[MAX_MODEL_LENGTH + 1];
	
	get_skin_v(user_knife[index], v, charsmax(v));
	get_skin_p(user_knife[index], p, charsmax(p));

	set_pev(index, pev_viewmodel2, v);
	set_pev(index, pev_weaponmodel2, p);
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
	if(!(get_user_team(index) & get_skin_team(skin)))
	{
		return false;
	}

	return true;
}

get_skin_name(skin, output[], length)
{
	static skin_data[SkinsDataEnumerator];

	ArrayGetArray(skins_data, skin, skin_data);

	copy(output, length, skin_data[sd_name]);
}

get_skin_v(skin, output[], length)
{
	static skin_data[SkinsDataEnumerator];

	ArrayGetArray(skins_data, skin, skin_data);

	copy(output, length, skin_data[sd_v]);
}

get_skin_p(skin, output[], length)
{
	static skin_data[SkinsDataEnumerator];

	ArrayGetArray(skins_data, skin, skin_data);

	copy(output, length, skin_data[sd_p]);
}

get_skin_team(skin)
{
	static skin_data[SkinsDataEnumerator];

	ArrayGetArray(skins_data, skin, skin_data);

	return skin_data[sd_team];
}

get_skin_access(skin)
{
	static skin_data[SkinsDataEnumerator];

	ArrayGetArray(skins_data, skin, skin_data);

	if(strlen(skin_data[sd_flags]))
	{
		return read_flags(skin_data[sd_flags]);
	}
	
	return 0;
}

load_knife_data(index)
{
	static key[64],
		skin,
		flags;

	get_user_name(index, key, charsmax(key));

	format(key, charsmax(key), "knife-%s", key);

	skin = nvault_get(vault_handle, key);
	flags = get_user_flags(index);

	if(!(flags & get_skin_access(skin)))
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