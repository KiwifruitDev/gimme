#pragma semicolon 1
#include <tf_econ_data>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.9"

public const int warpaintedWeps[45] = { 
	37, 172, 194, 197, 199, 200, 201, 202, 203, 205, 206, 207, 208, 209, 210,
	211, 214, 215, 220, 221, 228, 304, 305, 308, 312, 326, 327, 329, 351, 401,
	402, 404, 415, 424, 425, 447, 448, 449, 740, 996, 997, 1104, 1151, 1153, 1178 };

public const int festiveWeps[224] = { 
	35, 37, 41, 44, 130, 172, 192, 193, 194, 196, 197, 200, 201, 202, 203,
	205, 206, 207, 208, 209, 210, 211, 214, 215, 220, 221, 228, 304, 305, 308,
	312, 326, 327, 329, 351, 401, 402, 404, 411, 415, 424, 425, 447, 448, 449, 
	649, 740, 996, 997, 1104, 1151, 1153, 1178, 15000, 15001, 15002, 15003, 15004, 15005, 15006,
	15007, 15008, 15009, 15010, 15011, 15012, 15013, 15013, 15014, 15015, 15016, 15017, 15018, 15019, 15020,
	15021, 15022, 15023, 15024, 15025, 15026, 15027, 15028, 15029, 15030, 15031, 15032, 15033, 15034, 15035,
	15035, 15036, 15037, 15038, 15039, 15040, 15041, 15041, 15042, 15043, 15044, 15045, 15046, 15046, 15047,
	15048, 15049, 15050, 15051, 15052, 15053, 15054, 15055, 15056, 15056, 15057, 15058, 15059, 15060, 15060,
	15061, 15061, 15062, 15062, 15063, 15064, 15065, 15066, 15067, 15068, 15069, 15070, 15071, 15072, 15073,
	15074, 15075, 15076, 15077, 15078, 15079, 15081, 15082, 15083, 15084, 15085, 15086, 15087, 15088, 15089,
	15090, 15091, 15092, 15094, 15095, 15096, 15097, 15098, 15099, 15100, 15100, 15101, 15101, 15102, 15102,
	15103, 15104, 15105, 15106, 15107, 15108, 15109, 15110, 15111, 15112, 15113, 15114, 15115, 15116, 15117,
	15118, 15119, 15121, 15122, 15123, 15123, 15124, 15125, 15126, 15126, 15128, 15129, 15129, 15130, 15131,
	15132, 15133, 15134, 15135, 15136, 15137, 15138, 15139, 15140, 15141, 15142, 15143, 15144, 15145, 15146,
	15147, 15148, 15148, 15149, 15150, 15151, 15152, 15153, 15154, 15155, 15156, 15157, 15158 };

public Plugin myinfo =
{
	name = "[TF2] Gimme",
	author = "PC Gamer",
	description = "Give yourself or others an item. Clone players.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

ConVar g_hWeaponEffects;
ConVar g_hEnforceClassWeapons;
ConVar g_hEnforceClassCosmetics;
ConVar g_hEnforceClassCloning;
ConVar g_hAllowPermanentItems;
Handle g_hEquipWearable;
StringMap g_hItemInfoTrie;
bool g_bMedieval;
int g_iHasPermItems[MAXPLAYERS + 1];
int g_iPermClass[MAXPLAYERS + 1];
int ga_iPermItems[MAXPLAYERS + 1][12][3];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_hWeaponEffects = CreateConVar("sm_gimme_effects_enabled", "0", "Enables/disables unusual effects on gimme weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnforceClassWeapons = CreateConVar("sm_gimme_enforce_class_weapons", "1", "Enables/disables enforcement of class specific weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnforceClassCosmetics = CreateConVar("sm_gimme_enforce_class_cosmetics", "1", "Enables/disables enforcement of class specific cosmetics", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnforceClassCloning = CreateConVar("sm_gimme_enforce_class_cloning", "1", "Enables/disables enforcement of class specific cloning", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAllowPermanentItems = CreateConVar("sm_gimme_permanent_items_enabled", "0", "Enables/disables unusual effects on gimme weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegAdminCmd("sm_gimme", Command_GetItem, ADMFLAG_SLAY, "Get an item");
	RegAdminCmd("sm_gimmep", Command_Permanent_Items, ADMFLAG_SLAY, "Get a permanent item");
	RegAdminCmd("sm_resetp", Command_Permanent_Items_Off, ADMFLAG_SLAY, "Turn off permanent items");
	
	RegAdminCmd("sm_giveitem", Command_GiveItem, ADMFLAG_SLAY, "Give target player an item");
	RegAdminCmd("sm_giveitemp", Command_GiveItemPerm, ADMFLAG_SLAY, "Give target player a permanent item");
	RegAdminCmd("sm_removep", Command_RemoveItemPerm, ADMFLAG_SLAY, "Remove target permanent item status");
	
	RegAdminCmd("sm_clone", Command_CloneTarget, ADMFLAG_SLAY, "Duplicate targets equipped items");
	RegAdminCmd("sm_cloneothers", Command_CloneMulipleTargets, ADMFLAG_SLAY, "Duplicate targets equipped items");	

	RegConsoleCmd("sm_index", Command_ShowIndex, "Gives Index URL" );
	RegConsoleCmd("sm_listitems", Command_ListItems, "Show list of targets equipped items");

	RegAdminCmd("sm_listp", Command_Permanent_Items_List, ADMFLAG_SLAY, "List permanent items");
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2;
	
	if (g_hItemInfoTrie != null)
	{
		delete g_hItemInfoTrie;
	}
	g_hItemInfoTrie = new StringMap();
	char strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	if (FileExists(strBuffer))
	{
		CustomItemsTrieSetup(g_hItemInfoTrie);
	}
	
	HookEvent("post_inventory_application", player_inv);	
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMedieval"))
	{
		g_bMedieval = true;
	}	
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (g_iHasPermItems[client])
	{
		CreateTimer(0.2, GivePermItems, userd);
	}
}

public Action GivePermItems(Handle timer, int userd)
{
	int client = GetClientOfUserId(userd);
	if (g_iPermClass[client] == view_as<int>(TF2_GetPlayerClass(client)))
	{
		for (int i = 0; i < g_iHasPermItems[client]+1; i++)
		{
			if (ga_iPermItems[client][i][0] > 0)
			{
				int itemindex = ga_iPermItems[client][i][0];
				int wpaint = ga_iPermItems[client][i][1];
				int effect = ga_iPermItems[client][i][2];

				int trieweaponSlot;
				char formatBuffer[32];
				Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
				bool isValidItem = GetTrieValue(g_hItemInfoTrie, formatBuffer, trieweaponSlot);
				if(isValidItem)
				{
					GiveWeaponCustom(client, itemindex);
				}
				else
				{
					EquipItemByItemIndex(client, itemindex, wpaint, effect);
				}
			}
		}
	}
	if (g_iPermClass[client] != view_as<int>(TF2_GetPlayerClass(client)))
	{
		g_iHasPermItems[client] = 0;
		g_iPermClass[client] = -1;
	}
}

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrMax) 
{
	CreateNative("giveitem", Native_GiveItem);
	CreateNative("givewp", Native_GiveWP);	
	RegPluginLibrary("gimme");
	return APLRes_Success;
}

stock int Native_GiveItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int itemindex = GetNativeCell(2);
	int warpaint = GetNativeCell(3);
	int effect = GetNativeCell(4);	
	if (!IsValidClient(client) || !IsPlayerAlive(client)) 
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Target %N is invalid or dead at the moment.", client);		
	}
	if (warpaint < 1)
	{
		warpaint = 0;
	}
	if (effect < 1)
	{
		effect = 0;
	}
	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = GetTrieValue(g_hItemInfoTrie, formatBuffer, trieweaponSlot);
	if(isValidItem)
	{
		GiveWeaponCustom(client, itemindex);
		
		return true;
	}
	if (warpaint > 0)
	{
		if (!FindIfCanBeWarpainted(itemindex))
		{
			return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Weapon %i is not able to be Warpainted", itemindex);		
		}	
		if ((warpaint < 200) || (warpaint > 391) || (warpaint >297 && warpaint < 300) || (warpaint >310 && warpaint <390))
		{	
			return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Warpaint ID of  %i is invalid", warpaint);		
		}
	}
	else if(TF2Econ_IsValidItemDefinition(itemindex))	
	{
		EquipItemByItemIndex(client, itemindex, warpaint, effect);
		
		return true;
	}
	else
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Invalid item index (%d)", itemindex);
	}
	return true;	
}

stock int Native_GiveWP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int itemindex = GetNativeCell(2);
	int warpaint = GetNativeCell(3);	
	if (!IsValidClient(client) || !IsPlayerAlive(client)) 
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Target %N is invalid or dead at the moment", client);		
	}
	if (!FindIfCanBeWarpainted(itemindex))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Weapon %i is not able to be Warpainted", itemindex);		
	}	
	if ((warpaint < 200) || (warpaint > 391) || (warpaint >297 && warpaint < 300) || (warpaint >310 && warpaint <390))
	{	
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Warpaint ID of  %i is invalid", warpaint);		
	}
	EquipItemByItemIndex(client, itemindex, warpaint);
	return true;
}

public Action Command_GetItem(int client, int args)
{
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int itemindex = StringToInt(arg1);	

	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int wpaint = StringToInt(arg2);	
	
	char arg3[32];
	GetCmdArg(3, arg3, sizeof(arg3));
	int effect = StringToInt(arg3);		

	char arg4[32];
	GetCmdArg(4, arg4, sizeof(arg4));
	int paint = StringToInt(arg4);	
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !gimme <index number>");
		ReplyToCommand(client, "or gimme <index number> <0> <unusual effect number> <paint id>");		
		ReplyToCommand(client, "or gimme <warpaintable weapon id> <warpaint id>");		
		ReplyToCommand(client, "examples: !gimmme 205  or  !gimme 666  or  !gimme 205 200"); 
		ReplyToCommand(client, "for list of index numbers type: !index. Paint Ids are 1-29"); 

		return Plugin_Handled; 		
	}
	
	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = g_hItemInfoTrie.GetValue(formatBuffer, trieweaponSlot);

	if(isValidItem)
	{
		if (g_bMedieval && trieweaponSlot < 6)
		{
			if(trieweaponSlot !=2)
			{
				ReplyToCommand(client, "[SM] Gimme will only give melee weapons during Medieval mode.");
				
				return Plugin_Handled;
			}
		}

		if (trieweaponSlot < 6 && itemindex > 49999)
		{
			ReplyToCommand(client, "[SM] Gimme item index number must be under 40000.");
			
			return Plugin_Handled;
		}

		GiveWeaponCustom(client, itemindex);

		return Plugin_Handled;
	}

	if (!TF2Econ_IsValidItemDefinition(itemindex))
	{
		ReplyToCommand(client, "[SM] Unknown item index number: %i", itemindex);
		ReplyToCommand(client, "For a list of index numbers type: !index"); 	
		
		return Plugin_Handled; 		
	}

	int itemSlot = TF2Econ_GetItemDefaultLoadoutSlot(itemindex);

	if (itemSlot < 6 && g_hEnforceClassWeapons.BoolValue)
	{	
		if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
		{
			PrintToChat(client, "Item %d is an invalid weapon for your current class", itemindex);
			PrintToChat(client, "For list of valid index numbers by class type: !index"); 

			return Plugin_Handled; 			
		}
	}

	if (itemSlot > 5 && g_hEnforceClassCosmetics.BoolValue)
	{	
		if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
		{
			PrintToChat(client, "Item %d is an invalid weapon for your current class", itemindex);
			PrintToChat(client, "For list of valid index numbers by class type: !index");

			return Plugin_Handled;  			
		}
	}
	
	if (g_bMedieval && itemSlot < 6)
	{
		if(itemSlot !=2)
		{
			ReplyToCommand(client, "[SM] Gimme will only give melee weapons during Medieval mode.");
			
			return Plugin_Handled;
		}
	}

	if (itemSlot < 6 && itemindex > 49999)
	{
		ReplyToCommand(client, "[SM] Gimme item index number must be under 40000.");
		
		return Plugin_Handled;
	}

	if (paint > 29)
	{
		ReplyToCommand(client, "[SM] Invalid paint id. Valid paint ids are 0 thru 29");
	}

	if (paint < 0)
	{
		paint = 0;
	}
	
	if (effect < 0)
	{
		effect = 0;
	}

	if (wpaint > 0)
	{
		if (!FindIfCanBeWarpainted(itemindex))
		{
			ReplyToCommand(client, "[SM] That weapon is not able to be warpainted. Try another.");
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}
		if ((wpaint < 200) || (wpaint > 391) || (wpaint >297 && wpaint < 300) || (wpaint >310 && wpaint <390))
		{
			ReplyToCommand(client, "[SM] Valid warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}
		
		EquipItemByItemIndex(client, itemindex, wpaint, effect, paint);
		
		return Plugin_Handled;		
	}
	
	if (wpaint < 0)
	{
		wpaint = 0;
	}
	
	if (paint < 0)
	{
		paint = 0;
	}

	if (paint > 29)
	{
		ReplyToCommand(client, "Paint id must be a number 0 thru 29");
	}
	
	EquipItemByItemIndex(client, itemindex, wpaint, effect, paint);
	
	return Plugin_Handled;
}

public Action Command_ShowIndex(int client, int args)
{
	ReplyToCommand(client, "https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes");
	
	return Plugin_Handled;
}

public Action Command_GiveItem(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: giveitem <target> <item index number>");
		ReplyToCommand(client, "or giveitem <target> <warpaintable weapon index number> <warpaint id>");		
		ReplyToCommand(client, "or giveitem <target> <index number> <0> <unusual effect number> <paint id>");		
		ReplyToCommand(client, "examples: !giveitem @all 666  or  !giveitem robert 205 303  or !giveitem sally 666 0 13"); 
		ReplyToCommand(client, "valid paint ids are 1 thru 29. For list of index numbers type: !index   "); 		
	}
	
	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int itemindex = StringToInt(arg2);
	
	char arg3[32];
	GetCmdArg(3, arg3, sizeof(arg3));
	int wpaint = StringToInt(arg3);	
	
	char arg4[32];
	GetCmdArg(4, arg4, sizeof(arg4));
	int effect = StringToInt(arg4);		

	char arg5[32];
	GetCmdArg(5, arg5, sizeof(arg5));
	int paint = StringToInt(arg5);	

	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = g_hItemInfoTrie.GetValue(formatBuffer, trieweaponSlot);
	if(!isValidItem)
	{
		if (!TF2Econ_IsValidItemDefinition(itemindex))
		{
			ReplyToCommand(client, "[SM] Unknown item index number: %i", itemindex);
			ReplyToCommand(client, "For list of index numbers type: !index"); 	
			
			return Plugin_Handled; 
		}
	}

	if (wpaint > 0)
	{
		if (!FindIfCanBeWarpainted(itemindex))
		{
			ReplyToCommand(client, "[SM] That weapon is not able to be warpainted. Try another.");
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}

		if ((wpaint < 200) || (wpaint > 391) || (wpaint >297 && wpaint < 300) || (wpaint >310 && wpaint <390))
		{
			ReplyToCommand(client, "[SM] Valid warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}		
		
	}
	
	if (effect < 1)
	{
		effect = 0;
	}

	if (wpaint < 1)
	{
		wpaint = 0;
	}
	
	if (paint < 1)
	{
		paint = 0;
	}

	if (paint > 29)
	{
		ReplyToCommand(client, "[SM] Invalid paint id. Valid paint ids are 0 thru 29");
	}	

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if(isValidItem)
		{
			GiveWeaponCustom(target_list[i], itemindex);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" Custom Item %i", client, target_list[i], itemindex);
		}
		else
		{
			EquipItemByItemIndex(target_list[i], itemindex, wpaint, effect, paint);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" item %i with warpaint %i, effect %i, and paint %i", client, target_list[i], itemindex, wpaint, effect, paint);
			ReplyToCommand(client, "[SM] Gave %N item %i with warpaint %i, effect %i, and paint %i", target_list[i], itemindex, wpaint, effect, paint);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_GiveItemPerm(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: giveitem <target> <item index number>");
		ReplyToCommand(client, "or giveitemp <target> <warpaintable weapon index number> <warpaint id>");		
		ReplyToCommand(client, "or giveitemp <target> <index number> <0> <unusual effect number>");		
		ReplyToCommand(client, "examples: !giveitemp @all 666  or  !giveitemp robert 205 303  or !giveitemp sally 666 0 13"); 
		ReplyToCommand(client, "for list of index numbers type: !index"); 		
	}
	
	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int itemindex = StringToInt(arg2);
	
	char arg3[32];
	GetCmdArg(3, arg3, sizeof(arg3));
	int wpaint = StringToInt(arg3);	
	
	char arg4[32];
	GetCmdArg(4, arg4, sizeof(arg4));
	int effect = StringToInt(arg4);		

	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = g_hItemInfoTrie.GetValue(formatBuffer, trieweaponSlot);
	if(!isValidItem)
	{
		if (!TF2Econ_IsValidItemDefinition(itemindex))
		{
			ReplyToCommand(client, "[SM] Unknown item index number: %i", itemindex);
			ReplyToCommand(client, "For list of index numbers type: !index"); 	
			
			return Plugin_Handled; 
		}
	}

	if (wpaint > 0)
	{
		if (!FindIfCanBeWarpainted(itemindex))
		{
			ReplyToCommand(client, "[SM] That weapon is not able to be warpainted. Try another.");
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}

		if ((wpaint < 200) || (wpaint > 391) || (wpaint >297 && wpaint < 300) || (wpaint >310 && wpaint <390))
		{
			ReplyToCommand(client, "[SM] Valid warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}		
		
	}
	
	if (effect < 1)
	{
		effect = 0;
	}

	if (wpaint < 1)
	{
		wpaint = 0;
	}

	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		g_iPermClass[target_list[i]] = view_as<int>(TF2_GetPlayerClass(target_list[i]));
		if (g_iHasPermItems[target_list[i]] < 0)
		{
			g_iHasPermItems[target_list[i]] = 0;
		}
		g_iHasPermItems[target_list[i]] = g_iHasPermItems[target_list[i]] +1;
		int j = g_iHasPermItems[target_list[i]];
		ga_iPermItems[target_list[i]][j][0] = itemindex;
		ga_iPermItems[target_list[i]][j][1] = wpaint;
		ga_iPermItems[target_list[i]][j][2] = effect;

		if(isValidItem)
		{
			GiveWeaponCustom(target_list[i], itemindex);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" Custom Item %i", client, target_list[i], itemindex);
		}
		else
		{
			EquipItemByItemIndex(target_list[i], itemindex, wpaint, effect);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" weapon %i with warpaint %i and effect %i", client, target_list[i], itemindex, wpaint, effect);
			ReplyToCommand(client, "[SM] Gave %N an item %i with warpaint %i and effect %i", target_list[i], itemindex, wpaint, effect);
		}
	}
	
	return Plugin_Handled;
}

Action Command_ListItems(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";	
	}	
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_NO_IMMUNITY,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		ReplyToCommand(client, "[SM] %N has the following equipped items:", target_list[i]);
		Command_ListPlayerItems(client, target_list[i]);
	}
	return Plugin_Handled;
}

Action Command_CloneTarget(int client, int args)
{
	char arg1[32];
	if (args <1)
	{
		ReplyToCommand(client, "[SM] Usage:  !clone <target>");
		return Plugin_Handled;
	}

	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_NO_IMMUNITY,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if (target_count > 1)
	{
		ReplyToCommand(client, "[SM] You targeted %i players. You can only clone one person at a time.", target_count);
		return Plugin_Handled;
	}
	
	int target = target_list[0];

	if (client == target)
	{
		ReplyToCommand(client, "[SM] You already look fabulous.", client);
		return Plugin_Handled;
	}	

	if (g_hEnforceClassCloning.BoolValue)
	{
		if (TF2_GetPlayerClass(client) != TF2_GetPlayerClass(target))
		{
			ReplyToCommand(client, "[SM] You may only clone a player with the same class");
			return Plugin_Handled;			
		}
	}
	
	if (TF2_GetPlayerClass(client) != TF2_GetPlayerClass(target))
	{
		if(TF2_GetPlayerClass(target) == TFClass_Spy)
		{
			if (TF2_IsPlayerInCondition(target, TFCond_Disguised))
			{
				ReplyToCommand(client, "[SM] You cannot target a disguised Spy.");
				ReplyToCommand(client, "Try again when they are not disguised.");				
				return Plugin_Handled;
			}
		}
		
		TF2_RemoveAllWearables(client);
		RemoveAllWeapons(client);
		TF2_SetPlayerClass(client, TF2_GetPlayerClass(target));
		if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			TF2_RegeneratePlayer(client);
		}
	}
	
	ReplyToCommand(client, "[SM] You will now clone %N.", target);

	Command_Clone(client, target);
	
	return Plugin_Handled;
}

Action Command_CloneMulipleTargets(int client, int args)
{
	char arg1[32];

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage:  !cloneothers <source> <targets>");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_NO_IMMUNITY,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if (target_count < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !cloneothers <source> <targets>");
		return Plugin_Handled;
	}
	
	if (target_count > 1)
	{
		ReplyToCommand(client, "[SM] You tried to clone %i players. You can only clone one source person at a time.", target_count);
		return Plugin_Handled;
	}	

	int source = target_list[0];

	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	char target_name2[MAX_TARGET_LENGTH];
	int target_list2[MAXPLAYERS], target_count2;
	bool tn_is_ml2;
	
	if ((target_count2 = ProcessTargetString(
					arg2,
					client,
					target_list2,
					MAXPLAYERS,
					COMMAND_FILTER_NO_IMMUNITY,
					target_name2,
					sizeof(target_name2),
					tn_is_ml2)) <= 0)
	{
		ReplyToTargetError(client, target_count2);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count2; i++)
	{
		if (TF2_GetPlayerClass(target_list2[i]) != TF2_GetPlayerClass(source))
		{
			if(TF2_GetPlayerClass(source) == TFClass_Spy)
			{
				if (TF2_IsPlayerInCondition(source, TFCond_Disguised))
				{
					ReplyToCommand(client, "[SM] You cannot target a disguised Spy.");
					ReplyToCommand(client, "Try again when they are not disguised.");				
					return Plugin_Handled;
				}
			}

			TF2_RemoveAllWearables(target_list2[i]);
			RemoveAllWeapons(target_list2[i]);
			TF2_SetPlayerClass(target_list2[i], TF2_GetPlayerClass(source));
			if(TF2_GetPlayerClass(target_list2[i]) == TFClass_Engineer)
			{
				TF2_RegeneratePlayer(client);			
			}
		}

		ReplyToCommand(client, "[SM] %N is now a clone of %N:", target_list2[i], source);
		Command_CloneOthers(target_list2[i], source);
	}
	return Plugin_Handled;
}

Action Command_Permanent_Items(int client, int args)
{
	if (!g_hAllowPermanentItems.BoolValue)
	{
		ReplyToCommand(client, "[SM] Permanent Items are not enabled on the server.");
		return Plugin_Handled;			
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int itemindex = StringToInt(arg1);	

	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int wpaint = StringToInt(arg2);	
	
	char arg3[32];
	GetCmdArg(3, arg3, sizeof(arg3));
	int effect = StringToInt(arg3);

	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !gimme <index number>");
		ReplyToCommand(client, "or gimme <index number> <0> <unusual effect number>");		
		ReplyToCommand(client, "or gimme <warpaintable weapon id> <warpaint id>");		
		ReplyToCommand(client, "examples: !gimmme 205  or  !gimme 666  or  !gimme 205 200"); 
		ReplyToCommand(client, "for list of index numbers type: !index"); 

		return Plugin_Handled; 		
	}
	
	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = g_hItemInfoTrie.GetValue(formatBuffer, trieweaponSlot);

	if(isValidItem)
	{
		if (g_bMedieval && trieweaponSlot < 6)
		{
			if(trieweaponSlot !=2)
			{
				ReplyToCommand(client, "[SM] Gimme will only give melee weapons during Medieval mode.");
				
				return Plugin_Handled;
			}
		}

		if (trieweaponSlot < 6 && itemindex > 49999)
		{
			ReplyToCommand(client, "[SM] Gimme weapon index number must be under 40000.");
			
			return Plugin_Handled;
		}

		g_iPermClass[client] = view_as<int>(TF2_GetPlayerClass(client));
		if (g_iHasPermItems[client] < 0)
		{
			g_iHasPermItems[client] = 0;
		}
		g_iHasPermItems[client] = g_iHasPermItems[client] +1;
		int i = g_iHasPermItems[client];
		ga_iPermItems[client][i][0] = itemindex;
		ga_iPermItems[client][i][1] = wpaint;
		ga_iPermItems[client][i][2] = effect;

		GiveWeaponCustom(client, itemindex);

		return Plugin_Handled;
	}

	if (!TF2Econ_IsValidItemDefinition(itemindex))
	{
		ReplyToCommand(client, "[SM] Unknown item index number: %i", itemindex);
		ReplyToCommand(client, "For a list of index numbers type: !index"); 	
		
		return Plugin_Handled; 		
	}

	int itemSlot = TF2Econ_GetItemDefaultLoadoutSlot(itemindex);

	if (itemSlot < 6 && g_hEnforceClassWeapons.BoolValue)
	{	
		if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
		{
			PrintToChat(client, "Item %d is an invalid weapon for your current class", itemindex);
			PrintToChat(client, "For list of valid index numbers by class type: !index"); 

			return Plugin_Handled; 			
		}
	}

	if (itemSlot > 5 && g_hEnforceClassCosmetics.BoolValue)
	{	
		if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
		{
			PrintToChat(client, "Item %d is an invalid weapon for your current class", itemindex);
			PrintToChat(client, "For list of valid index numbers by class type: !index");

			return Plugin_Handled;  			
		}
	}
	
	if (g_bMedieval && itemSlot < 6)
	{
		if(itemSlot !=2)
		{
			ReplyToCommand(client, "[SM] Gimme will only give melee weapons during Medieval mode.");
			
			return Plugin_Handled;
		}
	}

	if (itemSlot < 6 && itemindex > 49999)
	{
		ReplyToCommand(client, "[SM] Gimme weapon index number must be under 40000.");
		
		return Plugin_Handled;
	}	

	if (wpaint > 0)
	{
		if (!FindIfCanBeWarpainted(itemindex))
		{
			ReplyToCommand(client, "[SM] that weapon is not able to be warpainted. Try another.");
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}
		if ((wpaint < 200) || (wpaint > 391) || (wpaint >297 && wpaint < 300) || (wpaint >310 && wpaint <390))
		{
			ReplyToCommand(client, "[SM] valid warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}
		if (effect < 0)
		{
			effect = 0;
		}
		
		g_iPermClass[client] = view_as<int>(TF2_GetPlayerClass(client));
		if (g_iHasPermItems[client] < 0)
		{
			g_iHasPermItems[client] = 0;
		}		
		g_iHasPermItems[client] = g_iHasPermItems[client] +1;
		int i = g_iHasPermItems[client];
		ga_iPermItems[client][i][0] = itemindex;
		ga_iPermItems[client][i][1] = wpaint;
		ga_iPermItems[client][i][2] = effect;
		
		EquipItemByItemIndex(client, itemindex, wpaint, effect);
		
		return Plugin_Handled;		
	}
	
	if (effect > 0)
	{
		g_iPermClass[client] = view_as<int>(TF2_GetPlayerClass(client));
		if (g_iHasPermItems[client] < 0)
		{
			g_iHasPermItems[client] = 0;
		}
		g_iHasPermItems[client] = g_iHasPermItems[client] +1;
		int i = g_iHasPermItems[client];
		ga_iPermItems[client][i][0] = itemindex;
		ga_iPermItems[client][i][1] = wpaint;
		ga_iPermItems[client][i][2] = effect;		
		
		EquipItemByItemIndex(client, itemindex, wpaint, effect);
	}
	
	else
	{
		g_iPermClass[client] = view_as<int>(TF2_GetPlayerClass(client));
		if (g_iHasPermItems[client] < 0)
		{
			g_iHasPermItems[client] = 0;
		}
		g_iHasPermItems[client] = g_iHasPermItems[client] +1;
		int i = g_iHasPermItems[client];
		ga_iPermItems[client][i][0] = itemindex;
		ga_iPermItems[client][i][1] = wpaint;
		ga_iPermItems[client][i][2] = effect;		
		
		EquipItemByItemIndex(client, itemindex);
	}
	
	return Plugin_Handled;
}

Action Command_Permanent_Items_Off(int client, int args)
{
	g_iHasPermItems[client] = 0;
	
	g_iPermClass[client] = -1;
	
	ReplyToCommand(client, "[SM] Removed Permanent status from player %N", client);

	return Plugin_Handled;
}

public Action Command_RemoveItemPerm(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: removep <target>");
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		g_iHasPermItems[target_list[i]] = 0;
		
		g_iPermClass[target_list[i]] = -1;
		
		ReplyToCommand(client, "[SM] Removed Permanent status from player %N", target_list[i]);
	}
	
	return Plugin_Handled;
}

Action Command_Permanent_Items_List(int client, int args)
{
	ReplyToCommand(client, "[SM] Player %N is Classtype %i with the following %i permanent items:", client, g_iPermClass[client], g_iHasPermItems[client]);
	
	for (int i = 1; i < g_iHasPermItems[client]+1; i++)
	{
		PrintToChat(client, "Item %i Index: %i, Warpaint: %i, Effect: %i", i, ga_iPermItems[client][i][0], ga_iPermItems[client][i][1], ga_iPermItems[client][i][2]); 
	}

	return Plugin_Handled;
}	

void EquipItemByItemIndex(int client, int itemindex, int warpaint = 0, int effect = 0, int paint = 0)
{
	if (!TF2Econ_IsValidItemDefinition(itemindex))
	{
		PrintToChat(client, "Unknown item index number: %i", itemindex);
		PrintToChat(client, "For list of index numbers type: !index"); 	
		return;
	}

	int itemSlot = TF2Econ_GetItemDefaultLoadoutSlot(itemindex);
	
	if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) !=-1)
	{
		itemSlot = TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client));
	}	
	
	int itemQuality = 6;

	char itemClassname[64];
	TF2Econ_GetItemClassName(itemindex, itemClassname, sizeof(itemClassname));
	TF2Econ_TranslateWeaponEntForClass(itemClassname, sizeof(itemClassname), TF2_GetPlayerClass(client));
	int itemLevel = GetRandomUInt(1, 100);


	if (StrContains(itemClassname, "shotgun", false) != -1)
	{
		TFClassType class = TF2_GetPlayerClass(client);
		if(class == TFClass_Unknown || class == TFClass_Scout || class == TFClass_Sniper || class == TFClass_DemoMan || class == TFClass_Medic || class == TFClass_Spy)
		{
			itemClassname = "tf_weapon_shotgun_primary";
		}
	}
	
	Items_CreateNamedItem(client, itemindex, itemClassname, itemLevel, itemQuality, itemSlot, warpaint, effect, paint);
	
	return;
}

int Items_CreateNamedItem(int client, int itemindex, const char[] classname, int level, int quality, int weaponSlot, int warpaint, int effect, int paint)
{
	int newitem = CreateEntityByName(classname);
	
	if (!IsValidEntity(newitem))
	{
		PrintToChat(client, "Item %i : %s is invalid for current class", itemindex, classname);
		return false;
	}

	if (StrEqual(classname, "tf_weapon_invis"))
	{
		weaponSlot = 4;
	}
	
	if (itemindex == 735 || itemindex == 736 || StrEqual(classname, "tf_weapon_sapper"))
	{
		weaponSlot = 1;
	}
	
	if (StrEqual(classname, "tf_weapon_revolver"))
	{
		weaponSlot = 0;
	}	

	if (TF2_GetPlayerClass(client) == TFClass_Engineer && weaponSlot > 2 && weaponSlot < 8)
	{
		return newitem;
	}
	
	if(weaponSlot < 6)
	{
		TF2_RemoveWeaponSlot(client, weaponSlot);		
	}
	
	char entclass[64];

	GetEntityNetClass(newitem, entclass, sizeof(entclass));	
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(newitem, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	switch (itemindex)
	{
	case 735, 736, 810, 831, 933, 1080, 1102:
		{
			SetEntProp(newitem, Prop_Send, "m_iObjectType", 3);
			SetEntProp(newitem, Prop_Data, "m_iSubType", 3);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}
	case 998:
		{
			SetEntData(newitem, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(newitem, "item style override", 0.0);
			TF2Attrib_SetByName(newitem, "loot rarity", 1.0);		
			TF2Attrib_SetByName(newitem, "turn to gold", 1.0);

			DispatchSpawn(newitem);
			EquipPlayerWeapon(client, newitem);

			char itemname[64];
			TF2Econ_GetItemName(itemindex, itemname, sizeof(itemname));
			PrintToChat(client, "%N received item %d (%s)", client, itemindex, itemname);
			
			return newitem; 
		}
	}

	if(quality == 9) //self made quality
	{
		TF2Attrib_SetByName(newitem, "is australium item", 1.0);
		TF2Attrib_SetByName(newitem, "item style override", 1.0);
	}

	if (warpaint > 0)
	{
		TF2Attrib_SetByDefIndex(newitem, 834, view_as<float>(warpaint));
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 15);		
	}

	if(FindIfCanBeFestive)
	{
		if(GetRandomInt(1,30) == 1) //festive check
		{
			TF2Attrib_SetByDefIndex(newitem, 2053, 1.0);
		}
	}
	
	if(quality == 11) //strange quality
	{
		if (GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 1.0);
		}
		else if (GetRandomInt(1,15) == 2)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 2.0);
			TF2Attrib_SetByDefIndex(newitem, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,15) == 3)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 3.0);
			TF2Attrib_SetByDefIndex(newitem, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(newitem, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(newitem, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30665, 30666, 30667, 30668:
			{
				TF2Attrib_RemoveByDefIndex(newitem, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(newitem, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (effect > 0 && warpaint == 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		TF2Attrib_SetByDefIndex(newitem, 134, effect + 0.0);
	}
	
	if(weaponSlot < 2)
	{
		TF2Attrib_SetByDefIndex(newitem, 725, 0.0);
	}
	
	if (paint > 0)
	{
		switch(paint)
		{
		case 1:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 3100495.0); //A color similar to slate
				TF2Attrib_SetByDefIndex(newitem, 261, 3100495.0);
			}
		case 2:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 8208497.0); //A deep commitment to purple
				TF2Attrib_SetByDefIndex(newitem, 261, 8208497.0);
			}
		case 3:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 1315860.0); //A distinctive lack of hue
				TF2Attrib_SetByDefIndex(newitem, 261, 1315860.0);
			}
		case 4:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 12377523.0); //A mann's mint
				TF2Attrib_SetByDefIndex(newitem, 261, 12377523.0);
			}
		case 5:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 2960676.0); //After eight
				TF2Attrib_SetByDefIndex(newitem, 261, 2960676.0);
			}
		case 6:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 8289918.0); //Aged Moustache Grey
				TF2Attrib_SetByDefIndex(newitem, 261, 8289918.0);
			}
		case 7:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 15132390.0); //An Extraordinary abundance of tinge
				TF2Attrib_SetByDefIndex(newitem, 261, 15132390.0);
			}
		case 8:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 15185211.0); //Australium gold
				TF2Attrib_SetByDefIndex(newitem, 261, 15185211.0);
			}
		case 9:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 14204632.0); //Color no 216-190-216
				TF2Attrib_SetByDefIndex(newitem, 261, 14204632.0);
			}
		case 10:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 15308410.0); //Dark salmon injustice
				TF2Attrib_SetByDefIndex(newitem, 261, 15308410.0);
			}
		case 11:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 8421376.0); //Drably olive
				TF2Attrib_SetByDefIndex(newitem, 261, 8421376.0);
			}
		case 12:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 7511618.0); //Indubitably green
				TF2Attrib_SetByDefIndex(newitem, 261, 7511618.0);
			}
		case 13:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 13595446.0); //Mann co orange
				TF2Attrib_SetByDefIndex(newitem, 261, 13595446.0);
			}
		case 14:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 10843461.0); //Muskelmannbraun
				TF2Attrib_SetByDefIndex(newitem, 261, 10843461.0);
			}
		case 15:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 5322826.0); //Noble hatters violet
				TF2Attrib_SetByDefIndex(newitem, 261, 5322826.0);
			}
		case 16:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 12955537.0); //Peculiarly drab tincture
				TF2Attrib_SetByDefIndex(newitem, 261, 12955537.0);
			}
		case 17:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 16738740.0); //Pink as hell
				TF2Attrib_SetByDefIndex(newitem, 261, 16738740.0);
			}
		case 18:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 6901050.0); //Radigan conagher brown
				TF2Attrib_SetByDefIndex(newitem, 261, 6901050.0);
			}
		case 19:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 3329330.0); //A bitter taste of defeat and lime
				TF2Attrib_SetByDefIndex(newitem, 261, 3329330.0);
			}
		case 20:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 15787660.0); //The color of a gentlemanns business pants
				TF2Attrib_SetByDefIndex(newitem, 261, 15787660.0);
			}
		case 21:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 8154199.0); //Ye olde rustic colour
				TF2Attrib_SetByDefIndex(newitem, 261, 8154199.0);
			}
		case 22:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 4345659.0); //Zepheniahs greed
				TF2Attrib_SetByDefIndex(newitem, 261, 4345659.0);
			}
		case 23:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 6637376.0); //An air of debonair
				TF2Attrib_SetByDefIndex(newitem, 261, 2636109.0);
			}
		case 24:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 3874595.0); //Balaclavas are forever
				TF2Attrib_SetByDefIndex(newitem, 261, 1581885.0);
			}
		case 25:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 12807213.0); //Cream spirit
				TF2Attrib_SetByDefIndex(newitem, 261, 12091445.0);
			}
		case 26:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 4732984.0); //Operators overalls
				TF2Attrib_SetByDefIndex(newitem, 261, 3686984.0);
			}
		case 27:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 12073019.0); //Team spirit
				TF2Attrib_SetByDefIndex(newitem, 261, 5801378.0);
			}
		case 28:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 8400928.0); //The value of teamwork
				TF2Attrib_SetByDefIndex(newitem, 261, 2452877.0);
			}
		case 29:
			{
				TF2Attrib_SetByDefIndex(newitem, 142, 11049612.0); //Waterlogged lab coat
				TF2Attrib_SetByDefIndex(newitem, 261, 8626083.0);
			}
		}
	}	

	DispatchSpawn(newitem);
	
	if (StrContains(classname, "tf_wearable", false) !=-1)
	{
		RemoveConflictWearables(client, itemindex);

		SDKCall(g_hEquipWearable, client, newitem);
	}	
	else
	{
		EquipPlayerWeapon(client, newitem);
	}
	
	if (g_hWeaponEffects.BoolValue && FindIfCanBeWarpainted(itemindex))
	{
		if (warpaint < 1 || effect < 1)
		{
			SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
			TF2_SwitchtoSlot(client, weaponSlot);
			int iRand = GetRandomUInt(1,4);
			if (iRand == 1)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 701.0);	
			}
			else if (iRand == 2)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 702.0);	
			}	
			else if (iRand == 3)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 703.0);	
			}
			else if (iRand == 4)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 704.0);	
			}
		}
		if (effect > 0)
		{
			switch(effect)
			{
			case 701:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 701.0);	
				}
			case 702:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 702.0);	
				}
			case 703:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 703.0);	
				}
			case 704:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 704.0);	
				}				
			default:
				{
					PrintToChat(client, "Invalid weapon effect. Valid effects are: 701, 702, 703, or 704");
				}
			}
		}
	}

	if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
	{
		if (StrEqual(classname, "tf_weapon_scattergun"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 6);
			SetNewAmmo(client, weaponSlot, 32);
		}
		if (StrEqual(classname, "tf_weapon_shortstop") || StrEqual(classname, "tf_weapon_pep_brawler_blaster"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 4);
			SetNewAmmo(client, weaponSlot, 32);
		}
		if (StrEqual(classname, "tf_weapon_pistol"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 12);
			SetNewAmmo(client, weaponSlot, 36);
		}
		if (StrContains(classname, "tf_weapon_shotgun") != -1)
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 6);
			SetNewAmmo(client, weaponSlot, 32);
		}	
		if (StrEqual(classname, "tf_weapon_handgun_scout_secondary"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 12);
			SetNewAmmo(client, weaponSlot, 36);
		}		
		if (StrEqual(classname, "tf_weapon_rocketlauncher") || StrEqual(classname, "tf_weapon_rocketlauncher_directhit") || StrEqual(classname, "tf_weapon_rocketlauncher_airstrike"))
		{
			if (itemindex == 228)
			{
				SetEntProp(newitem, Prop_Data, "m_iClip1", 3);
				SetNewAmmo(client, weaponSlot, 20);		
			}
			else
			{
				SetEntProp(newitem, Prop_Data, "m_iClip1", 4);
				SetNewAmmo(client, weaponSlot, 20);
			}
		}
		if (StrEqual(classname, "tf_weapon_minigun") || StrEqual(classname, "tf_weapon_flamethrower"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 200);
		}
		if (StrEqual(classname, "tf_weapon_rocketlauncher_fireball"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 40);
		}
		if (StrEqual(classname, "tf_weapon_grenadelauncher"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 4);
			SetNewAmmo(client, weaponSlot, 16);
		}
		if (StrEqual(classname, "tf_weapon_pipebomblauncher"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 8);
			SetNewAmmo(client, weaponSlot, 24);
		}
		if (StrEqual(classname, "tf_weapon_syringegun_medic"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 40);
			SetNewAmmo(client, weaponSlot, 150);
		}
		if (StrEqual(classname, "tf_weapon_syringegun_medic"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 40);
			SetNewAmmo(client, weaponSlot, 150);
		}
		if (StrEqual(classname, "tf_weapon_crossbow"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 1);
			SetNewAmmo(client, weaponSlot, 38);
		}
		if (StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap") || StrEqual(classname, "tf_weapon_sniperrifle_classic"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 25);
		}	
		if (StrEqual(classname, "tf_weapon_compound_bow"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 1);
			SetNewAmmo(client, weaponSlot, 25);
		}
		if (StrEqual(classname, "tf_weapon_smg"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 25);
			SetNewAmmo(client, weaponSlot, 75);
		}
		if (StrEqual(classname, "tf_weapon_charged_smg"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 20);
			SetNewAmmo(client, weaponSlot, 75);
		}
		if (StrEqual(classname, "tf_weapon_revolver"))
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 6);
			SetNewAmmo(client, weaponSlot, 24);
		}
	}
	
	TF2_SwitchtoSlot(client, 0);	

	char itemname[64];
	TF2Econ_GetItemName(itemindex, itemname, sizeof(itemname));
	PrintToChat(client, "%N received item %d, %s, warpaint: %i, effect: %i, paint: %i", client, itemindex, itemname, warpaint, effect, paint);
	
	return newitem;
} 

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

bool FindIfCanBeWarpainted(const int def)
{
	for(int i = 0; i < sizeof(warpaintedWeps); i++)
	{
		if(warpaintedWeps[i] == def)
		return true;
	}

	return false;
}

bool FindIfCanBeFestive(const int def)
{
	for(int i = 0; i < sizeof(festiveWeps); i++)
	{
		if(festiveWeps[i] == def)
		return true;
	}

	return false;
}

bool RemoveConflictWearables(int client, int newindex)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if(GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") == client)
		{
			int oldindex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
			
			if(TF2Econ_IsValidItemDefinition(oldindex))
			{
				if(TF2Econ_GetItemEquipRegionMask(oldindex) & TF2Econ_GetItemEquipRegionMask(newindex) > 0)
				{
					TF2_RemoveWearable (client, wearable);			
				}
			}
		}
	}
}

stock int CustomItemsTrieSetup(StringMap trie)
{
	char strBuffer[256], strBuffer2[256], strBuffer3[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	KeyValues kv = new KeyValues("Gimme");
	if(FileToKeyValues(kv, strBuffer) == true)
	{
		kv.GetSectionName(strBuffer, sizeof(strBuffer));
		if (StrEqual("custom_give_weapons_vlolz", strBuffer) == true)
		{
			if (kv.GotoFirstSubKey())
			{
				do
				{
					kv.GetSectionName(strBuffer, sizeof(strBuffer));
					if (strBuffer[0] != '*')
					{
						Format(strBuffer2, 32, "%s_%s", strBuffer, "classname");
						kv.GetString("classname", strBuffer3, sizeof(strBuffer3));
						trie.SetString(strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "index");
						trie.SetValue(strBuffer2, kv.GetNum("index"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "slot");
						trie.SetValue(strBuffer2, kv.GetNum("slot"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "quality");
						trie.SetValue(strBuffer2, kv.GetNum("quality"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "level");
						trie.SetValue(strBuffer2, kv.GetNum("level"));
						Format(strBuffer2, 256, "%s_%s", strBuffer, "attribs");
						kv.GetString("attribs", strBuffer3, sizeof(strBuffer3));
						trie.SetString(strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "ammo");
						trie.SetValue(strBuffer2, kv.GetNum("ammo", -1));
					}
				}
				while (kv.GotoNextKey());
				kv.GoBack();
			}
		}
	}
	delete kv;
}

public int GiveWeaponCustom(int client, int configindex)
{
	int index;
	int slot;
	int quality;
	int level;
	int ammo;
	char weaponClass[64];
	char attribs[256];
	char formatBuffer[64];
	
	Format(formatBuffer, 32, "%d_%s", configindex, "classname");
	g_hItemInfoTrie.GetString(formatBuffer, weaponClass, sizeof(weaponClass));
	Format(formatBuffer, 32, "%d_%s", configindex, "index");
	g_hItemInfoTrie.GetValue(formatBuffer, index);
	Format(formatBuffer, 32, "%d_%s", configindex, "slot");
	g_hItemInfoTrie.GetValue(formatBuffer, slot);
	Format(formatBuffer, 32, "%d_%s", configindex, "quality");
	g_hItemInfoTrie.GetValue(formatBuffer, quality);	
	Format(formatBuffer, 32, "%d_%s", configindex, "level");
	g_hItemInfoTrie.GetValue(formatBuffer, level);	
	Format(formatBuffer, 32, "%d_%s", configindex, "ammo");
	g_hItemInfoTrie.GetValue(formatBuffer, ammo);
	Format(formatBuffer, 32, "%d_%s", configindex, "attribs");
	g_hItemInfoTrie.GetString(formatBuffer, attribs, sizeof(attribs));
	char weaponAttribsArray[32][32];
	int attribCount = ExplodeString(attribs, " ; ", weaponAttribsArray, 32, 32);

	if(StrEqual(weaponClass, "tf_weapon_shotgun"))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		if(class == TFClass_Unknown || class == TFClass_Scout || class == TFClass_Sniper || class == TFClass_DemoMan || class == TFClass_Medic || class == TFClass_Spy)
		{
			strcopy(weaponClass, 64, "tf_weapon_shotgun_primary");
		}
		else if(class == TFClass_Soldier) strcopy(weaponClass, 64, "tf_weapon_shotgun_soldier");
		else if(class == TFClass_Heavy) strcopy(weaponClass, 64, "tf_weapon_shotgun_hwg");
		else if(class == TFClass_Pyro) strcopy(weaponClass, 64, "tf_weapon_shotgun_pyro");
		else if(class == TFClass_Engineer) strcopy(weaponClass, 64, "tf_weapon_shotgun_primary");
	}
	if(StrEqual(weaponClass, "saxxy"))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		switch(class)
		{
		case TFClass_Scout: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_bat");
		case TFClass_Sniper: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_club");
		case TFClass_Soldier: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_shovel");
		case TFClass_DemoMan: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_bottle");
		case TFClass_Engineer: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_wrench");
		case TFClass_Pyro: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_fireaxe");
		case TFClass_Heavy: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_fireaxe");
		case TFClass_Spy: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_knife");
		case TFClass_Medic: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_bonesaw");
		}
	}

	int newitem = CreateEntityByName(weaponClass);	
	
	if (!IsValidEntity(newitem))
	{
		return false;
	}

	if (StrEqual(weaponClass, "tf_weapon_invis"))
	{
		slot = 4;
	}
	
	if (index == 735 || index == 736 || StrEqual(weaponClass, "tf_weapon_sapper"))
	{
		slot = 1;
	}
	
	if (StrEqual(weaponClass, "tf_weapon_revolver"))
	{
		slot = 0;
	}	

	if(slot < 6)
	{
		TF2_RemoveWeaponSlot(client, slot);		
	}	
	
	char entclass[64];

	GetEntityNetClass(newitem, entclass, sizeof(entclass));	
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), index);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntProp(newitem, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		level = GetRandomUInt(1,99);
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}

	if (quality > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	}
	else
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	}	

	if (index == 735 || index == 736 || StrEqual(weaponClass, "tf_weapon_sapper"))
	{
		SetEntProp(newitem, Prop_Send, "m_iObjectType", 3);
		SetEntProp(newitem, Prop_Data, "m_iSubType", 3);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}
	
	DispatchSpawn(newitem);

	if (attribCount > 1) 
	{
		int attrIdx;
		float attrVal;
		int i2 = 0;
		for (int i = 0; i < attribCount; i+=2) {
			attrIdx = StringToInt(weaponAttribsArray[i]);
			if (attrIdx <= 0)
			{
				LogError("Tried to set attribute index to %d on item index %d, attrib string was '%s', count was %d", attrIdx, index, attribs, attribCount);
				continue;
			}
			switch (attrIdx)
			{
			case 133, 143, 147, 152, 184, 185, 186, 192, 193, 194, 198, 211, 214, 227, 228, 229, 262, 294, 302, 372, 373, 374, 379, 381, 383, 403, 420:
				{
					attrVal = float(StringToInt(weaponAttribsArray[i+1]));
				}
			default:
				{
					attrVal = StringToFloat(weaponAttribsArray[i+1]);
				}
			}
			TF2Attrib_SetByDefIndex(newitem, attrIdx, attrVal);
			i2++;
		}
	}

	if (StrContains(weaponClass, "tf_wearable", false) !=-1)
	{
		RemoveConflictWearables(client, index);

		SDKCall(g_hEquipWearable, client, newitem);
	}	
	else
	{
		EquipPlayerWeapon(client, newitem);
	}

	if (ammo > 0)
	{
		SetNewAmmo(client, slot, ammo);
	}
	
	char itemname[64];
	TF2Econ_GetItemName(index, itemname, sizeof(itemname));
	PrintToChat(client, "%N received custom item %i (%s)", client, index, itemname);
	
	return newitem;
}

stock void SetNewAmmo(int client, int wepslot, int newAmmo)
{
	int weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon)) return;
	int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

public Action Command_ListPlayerItems(int client, int target)
{
	ListWeapons(client, target);	
	ListWearables(client, target, "tf_wearable", "CTFWearable");	
	return Plugin_Handled;
}

public Action Command_Clone(int client, int target)
{
	TF2_RemoveAllWearables(client);
	CloneWeapons(client, target);	
	CloneWearables(client, target, "tf_wearable", "CTFWearable");	
	return Plugin_Handled;
}

public Action Command_CloneOthers(int target, int source)
{
	TF2_RemoveAllWearables(target);
	CloneWeapons(target, source);	
	CloneWearables(target, source, "tf_wearable", "CTFWearable");	
	return Plugin_Handled;
}

stock Action ListWeapons(int client, int target)
{
	if (IsValidClient(target))
	{
		for (int slot = 0; slot < 7; slot++)
		{
			int ent = GetPlayerWeaponSlot(target, slot);
			if (slot == 1 && ent == -1)
			{
				if (TF2_GetPlayerClass(target) == TFClass_DemoMan)
				{
					int iEntity = -1;
					while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
					{
						if (target == GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity"))
						{
							int index = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
							char itemname[64];
							TF2Econ_GetItemName(index, itemname, sizeof(itemname));
							PrintToChat(client, "slot: %i, index: %i, item name: %s", slot, index, itemname);
						}
					}
				}
				if (TF2_GetPlayerClass(target) == TFClass_Sniper)
				{
					int iEntity2 = -1;
					while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_razorback")) != -1)
					{
						if (target == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
						{
							int index = GetEntProp(iEntity2, Prop_Send, "m_iItemDefinitionIndex");
							char itemname[64];
							TF2Econ_GetItemName(index, itemname, sizeof(itemname));
							PrintToChat(client, "slot: %i, index: %i, item name: %s", slot, index, itemname);
						}
					}
				}
			}

			if (ent != -1)
			{
				float warpaint = 0.0;
				int effect = 0;
				int index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
				char itemname[64];
				TF2Econ_GetItemName(index, itemname, sizeof(itemname));
				int weapon = GetPlayerWeaponSlot(target, slot);

				Address pAttrib = TF2Attrib_GetByDefIndex(weapon, 834);
				if (IsValidAddress(view_as<Address>(pAttrib)))
				{
					warpaint = TF2Attrib_GetValue(pAttrib);
				}
				else
				{
					warpaint = TF2_GetRuntimeAttribValue(weapon, 834);
				}
				
				if (warpaint < 0)
				{
					warpaint = 0.0;
				}
				
				Address pAttrib2 = TF2Attrib_GetByDefIndex(weapon, 134);
				if (IsValidAddress(view_as<Address>(pAttrib2)))
				{
					float raweffect = TF2Attrib_GetValue(pAttrib2);
					char ConvertEffect[32];
					Format(ConvertEffect, sizeof(ConvertEffect),"%0.f", raweffect);
					effect = StringToInt(ConvertEffect);	
				}
				else
				{
					effect = view_as<int>(TF2_GetRuntimeAttribValue(weapon, 134));				
				}

				if (effect < 0)
				{
					effect = 0;
				}				

				PrintToChat(client, "slot: %i, index: %i, %s, warpaint: %i, effect: %i", slot, index, itemname, view_as<int>(warpaint), view_as<int>(effect));
			}
		}
	}
}

stock Action ListWearables(int client, int target, char[] classname, char[] networkclass)
{
	if (IsPlayerAlive(target))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == target)
				{
					int effect = 0;
					float rawpaint = 0.0;
					int paint = 0;
					int index = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
					int slot = TF2Econ_GetItemDefaultLoadoutSlot(edict);
					if (TF2Econ_GetItemLoadoutSlot(index, TF2_GetPlayerClass(target)) !=-1)
					{
						slot = TF2Econ_GetItemLoadoutSlot(index, TF2_GetPlayerClass(target));
					}
					
					char itemname[64];
					TF2Econ_GetItemName(index, itemname, sizeof(itemname));
					
					Address pAttrib = TF2Attrib_GetByDefIndex(edict, 134);
					if (IsValidAddress(view_as<Address>(pAttrib)))
					{
						float raweffect = TF2Attrib_GetValue(pAttrib);
						char ConvertEffect[32];
						Format(ConvertEffect, sizeof(ConvertEffect),"%0.f", raweffect);
						effect = StringToInt(ConvertEffect);	
					}
					else
					{
						effect = view_as<int>(TF2_GetRuntimeAttribValue(edict, 134));
					}
					
					Address pAttrib2 = TF2Attrib_GetByDefIndex(edict, 142);
					if (IsValidAddress(view_as<Address>(pAttrib2)))
					{
						rawpaint = TF2Attrib_GetValue(pAttrib2);
					}					
					else
					{
						rawpaint = TF2_GetRuntimeAttribValue(edict, 142);
					}
		
					if (rawpaint > 0)
					{
						paint = Translate_Paint(rawpaint);
					}
					
					if (effect < 0)
					{
						effect = 0;
					}
					if (paint < 0)
					{
						paint = 0;
					}					

					PrintToChat(client, "slot: %i, index: %i, %s, effect: %i, paint: %i", slot, index, itemname, view_as<int>(effect), paint);
				}
			}
		}
	}
}

stock Action CloneWeapons(int client, int target)
{
	if (IsValidClient(target))
	{
		for (int slot = 0; slot < 6; slot++)
		{
			int ent = GetPlayerWeaponSlot(target, slot);
			if (slot == 1 && ent == -1)
			{
				if (TF2_GetPlayerClass(target) == TFClass_DemoMan)
				{
					int iEntity = -1;
					while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
					{
						if (target == GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity"))
						{
							int index = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
							EquipItemByItemIndex(client, index);								
						}
					}
				}
				if (TF2_GetPlayerClass(target) == TFClass_Sniper)
				{
					int iEntity2 = -1;
					while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_razorback")) != -1)
					{
						if (target == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
						{
							int index = GetEntProp(iEntity2, Prop_Send, "m_iItemDefinitionIndex");
							EquipItemByItemIndex(client, index);								
						}
					}
				}
			}

			if (ent != -1)
			{
				float warpaint = 0.0;
				int effect = 0;
				int index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
				int weapon = GetPlayerWeaponSlot(target, slot);

				Address pAttrib = TF2Attrib_GetByDefIndex(weapon, 834);
				if (IsValidAddress(view_as<Address>(pAttrib)))
				{
					warpaint = TF2Attrib_GetValue(pAttrib);
				}
				else
				{
					warpaint = TF2_GetRuntimeAttribValue(weapon, 834);
				}
				
				if (warpaint < 0)
				{
					warpaint = 0.0;
				}
				
				Address pAttrib2 = TF2Attrib_GetByDefIndex(weapon, 134);
				if (IsValidAddress(view_as<Address>(pAttrib2)))
				{
					float raweffect = TF2Attrib_GetValue(pAttrib2);
					char ConvertEffect[32];
					Format(ConvertEffect, sizeof(ConvertEffect),"%0.f", raweffect);
					effect = StringToInt(ConvertEffect);	
				}
				else
				{
					effect = view_as<int>(TF2_GetRuntimeAttribValue(weapon, 134));				
				}
				
				if (effect < 0)
				{
					effect = 0;
				}
				
				EquipItemByItemIndex(client, index, view_as<int>(warpaint), view_as<int>(effect));	
			}
		}
	}
}

stock Action CloneWearables(int client, int target, char[] classname, char[] networkclass)
{
	if (IsPlayerAlive(target))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == target)
				{
					int index = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
					if (index != -1 && index < 65535)
					{
						float rawpaint = 0.0;
						int warpaint = 0;
						int effect = 0;
						int paint = 0;

						char itemname[64];
						TF2Econ_GetItemName(index, itemname, sizeof(itemname));
						
						Address pAttrib = TF2Attrib_GetByDefIndex(edict, 134);
						if (IsValidAddress(view_as<Address>(pAttrib)))
						{
							float raweffect = TF2Attrib_GetValue(pAttrib);
							char ConvertEffect[32];
							Format(ConvertEffect, sizeof(ConvertEffect),"%0.f", raweffect);
							effect = StringToInt(ConvertEffect);	
						}
						else
						{
							effect = view_as<int>(TF2_GetRuntimeAttribValue(edict, 134));
						}
						
						Address pAttrib2 = TF2Attrib_GetByDefIndex(edict, 142);
						if (IsValidAddress(view_as<Address>(pAttrib2)))
						{
							rawpaint = TF2Attrib_GetValue(pAttrib2);
						}					
						else
						{
							rawpaint = TF2_GetRuntimeAttribValue(edict, 142);
						}
			
						if (rawpaint > 0)
						{
							paint = Translate_Paint(rawpaint);
						}
						
						if (effect < 0)
						{
							effect = 0;
						}
						if (paint < 0)
						{
							paint = 0;
						}

						EquipItemByItemIndex(client, index, view_as<int>(warpaint), view_as<int>(effect), paint);
					}
				}
			}
		}
	}
}

stock bool IsValidAddress(Address pAddress)
{
	static Address Address_MinimumValid = view_as<Address>(0x10000);
	if (pAddress == Address_Null)
	return false;
	return unsigned_compare(view_as<int>(pAddress), view_as<int>(Address_MinimumValid)) >= 0;
}
stock int unsigned_compare(int a, int b) 
{
	if (a == b)
	return 0;
	if ((a >>> 31) == (b >>> 31))
	return ((a & 0x7FFFFFFF) > (b & 0x7FFFFFFF)) ? 1 : -1;
	return ((a >>> 31) > (b >>> 31)) ? 1 : -1;
}

stock Action TF2_RemoveAllWearables(int client)
{
	RemoveWearable(client, "tf_wearable", "CTFWearable");
	RemoveWearable(client, "tf_powerup_bottle", "CTFPowerupBottle");
}

stock Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsPlayerAlive(client))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(edict, "Kill"); 
				}
			}
		}
	}
}

stock void RemoveAllWeapons(int client)
{
	if (IsPlayerAlive(client))
	{
		int weapon;
		for (int slot = 0; slot < 6; slot++)
		{
			int ent = GetPlayerWeaponSlot(client, slot);
			if (slot == 1 && ent == -1)
			{
				if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
				{
					int iEntity = -1;
					while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
					{
						if (client == GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity"))
						{
							AcceptEntityInput(iEntity, "kill");
						}
					}
				}
				if (TF2_GetPlayerClass(client) == TFClass_Sniper)
				{
					int iEntity2 = -1;
					while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_razorback")) != -1)
					{
						if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
						{
							AcceptEntityInput(iEntity2, "kill");						
						}
					}
				}
			}

			weapon = GetPlayerWeaponSlot(client, slot);
			if (weapon != -1)
			{
				TF2_RemoveWeaponSlot(client, slot);	
			}
		}
	}
}

stock int Translate_Paint(float rawpaint) 
{
	if (rawpaint > 0.0)
	{
		switch(rawpaint)
		{
		case 3100495.0:
			{
				return 1; //"A color similar to slate";
			}
		case 8208497.0:
			{
				return 2; //A deep commitment to purple
			}
		case 1315860.0:
			{
				return 3; //A distinctive lack of hue
			}
		case 12377523.0:
			{
				return 4; //A mann's mint
			}
		case 2960676.0:
			{
				return 5; //After eight
			}
		case 8289918.0:
			{
				return 6; //Aged Moustache Grey
			}
		case 15132390.0:
			{
				return 7; //An Extraordinary abundance of tinge
			}
		case 15185211.0:
			{
				return 8; //Australium gold
			}
		case 14204632.0:
			{
				return 9; //Color no 216-190-216
			}
		case 15308410.0:
			{
				return 10; //Dark salmon injustice
			}
		case 8421376.0:
			{
				return 11; //Drably olive
			}
		case 7511618.0:
			{
				return 12; //Indubitably green
			}
		case 13595446.0:
			{
				return 13; //Mann co orange
			}
		case 10843461.0:
			{
				return 14; //Muskelmannbraun
			}
		case 5322826.0:
			{
				return 15; //Noble hatters violet
			}
		case 12955537.0:
			{
				return 16; //Peculiarly drab tincture
			}
		case 16738740.0:
			{
				return 17; //Pink as hell
			}
		case 6901050.0:
			{
				return 18; //Radigan conagher brown
			}
		case 3329330.0:
			{
				return 19; //A bitter taste of defeat and lime
			}
		case 15787660.0:
			{
				return 20; //The color of a gentlemanns business pants
			}
		case 8154199.0:
			{
				return 21; //Ye olde rustic colour
			}
		case 4345659.0:
			{
				return 22; //Zepheniahs greed
			}
		case 6637376.0:
			{
				return 23; //An air of debonair
			}
		case 3874595.0:
			{
				return 24; //Balaclavas are forever
			}
		case 12807213.0:
			{
				return 25; //Cream spirit
			}
		case 4732984.0:
			{
				return 26; //Operators overalls
			}
		case 12073019.0:
			{
				return 27; //Team spirit
			}
		case 8400928.0:
			{
				return 28; //The value of teamwork
			}
		case 11049612.0:
			{
				return 28; //Waterlogged lab coat
			}
		}
	}
	
	return -1;
}

float TF2_GetRuntimeAttribValue(int entity, int attribute) 
{
	if (!IsValidEntity(entity))
	{
		return 0.0;
	}

	int iAttribIndices[16];
	float flAttribValues[16];
	
	int nAttribs = TF2Attrib_GetSOCAttribs(entity, iAttribIndices, flAttribValues);
	
	for (int i = 0; i < nAttribs; i++) 
	{
		if (iAttribIndices[i] == attribute) 
		{
			return flAttribValues[i];
		}
	}

	return 0.00;
}