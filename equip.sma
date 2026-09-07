#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_valve;
new g_gearbox;
new g_dmc;
new g_cstrike;
new g_tfc;
new g_dod;
new g_ricochet;
new g_map_owner = -1;

#include "equip_gen"

new bool:g_wish_granted[33];
new g_wish[33][MAX_CATEGORIES];

new g_valve_category_names[][32] = { "Pistol", "Primary", "Special", "Grenade" };
new g_cstrike_category_names[][32] = { "T Pistol", "CT Pistol", "T Primary", "CT Primary" };
new g_gearbox_category_names[][32] = { "Melee", "Primary", "Special", "PowerUp" };
new g_dmc_category_names[][32] = { "Nailgun", "Special", "PowerUp" };
new g_dod_category_names[][32] = { "Allies", "Axis" };
new g_ricochet_category_names[][32] = { "PowerUp" };

new Float:g_dmc_powerup_durations[] = {3.0, 15.0, 10.0};

new bool:g_active = true;
new bool:g_pistol_only = false;

new g_gpes[MAX_GAMES];
new Float:g_wish_ad_interval = 120.0;
new Float:g_last_wish_ad[33];

public plugin_init() {
    register_plugin("Equip", __DATE__, "GoldSrc.one");

    register_clcmd("say wish", "wish_menu");
    register_clcmd("say /wish", "wish_menu");
    register_clcmd("say !wish", "wish_menu");
    register_clcmd("say guns", "wish_menu");
    register_clcmd("say /guns", "wish_menu");
    register_clcmd("say !guns", "wish_menu");

    if(IsMapDeathmatch()) {
        g_active = false;
        return;
    }

    g_valve = GetGameIndex("valve");
    g_gearbox = GetGameIndex("gearbox");
    g_dmc = GetGameIndex("dmc");
    g_cstrike = GetGameIndex("cstrike");
    g_tfc = GetGameIndex("tfc");
    g_dod = GetGameIndex("dod");
    g_ricochet = GetGameIndex("ricochet");

    g_map_owner = GetEntityOwner(0);

    new mapname[64];
    get_mapname(mapname, 64);
    if(g_map_owner == g_cstrike && equal(mapname, "fy_", 3) && !equal(mapname, "fy_nuketown"))
        g_pistol_only = true;

    set_task(g_wish_ad_interval, "wish_advertise_all", _, _, _, "b");

    for(new iGame = 0; iGame < GetNumGames(); iGame++)
        GameContext(iGame, "create_gpe");
        
    register_forward(FM_FindEntityByString, "FindEntityByStringPre", 0);

    if(g_gearbox != -1) {
        register_forward(FM_PlayerPostThink, "PlayerPostThinkPre", 0);
        register_forward(FM_PlayerPostThink, "PlayerPostThinkPost", 1);
        register_forward(FM_SetPhysicsKeyValue, "SetPhysicsKeyValuePost", 1);
        register_forward(FM_EmitSound, "EmitSoundPre", 0);
        register_logevent("remove_gearbox_ctf_items", 3, "2=drop_Damage_Powerup");
        register_logevent("remove_gearbox_ctf_items", 3, "2=drop_Ammo_Powerup");
        register_logevent("remove_gearbox_ctf_items", 3, "2=drop_Jump_Powerup");
        register_logevent("remove_gearbox_ctf_items", 3, "2=drop_Shield_Powerup");
        register_logevent("remove_gearbox_ctf_items", 3, "2=drop_Health_Powerup");

        GameContext(g_gearbox, "precache_gearbox_ctf_items");
    }

    if(g_dmc != -1) {
        register_forward(FM_CmdStart, "CmdStartPre", 0)
        GameContext(g_dmc, "precache_dmc_items");
    }

    if(g_dod != -1 && g_map_owner != g_dod) {
        register_forward(FM_ClientCommand, "ClientCommandPre", 0);
        register_forward(FM_ClientCommand, "ClientCommandPost", 1);
        register_forward(FM_Touch, "TouchPre", 0);
        register_forward(FM_Touch, "TouchPost", 1);
    }
}

public create_gpe() {
    new gpe = fm_create_entity("game_player_equip");
    if(gpe)
        g_gpes[GetEntityOwner(gpe)] = gpe;
}

precache_items(const items[][], count) {
    for(new i = 0; i < count; i++) {
        new item = fm_create_entity(items[i]);
        fm_DispatchSpawn(item);
        fm_remove_entity(item);
    }
}

public precache_gearbox_ctf_items() {
    precache_items(g_gearbox_powerups, sizeof g_gearbox_powerups);
}

public precache_dmc_items() {
    precache_items(g_dmc_nailguns, sizeof g_dmc_nailguns);
    precache_items(g_dmc_specials, sizeof g_dmc_specials);
    precache_items(g_dmc_powerups, sizeof g_dmc_powerups);
    new others[][] = {"item_armor1", "item_shells", "item_spikes", "item_rockets", "item_cells"};
    precache_items(others, sizeof others);
}

give_item_times(player_id, const item[], times, bool:remove = false) {
    for(new i = 0; i < times; i++) {
        new entity = fm_give_item(player_id, item);
        if(entity > 0 && remove)
            fm_remove_entity(entity);
    }
}

new g_player_id = -1;

public add_equip_prevention() {
    if(is_user_alive(g_player_id))
        fm_strip_user_weapons(g_player_id);
}

public PrePlayerSpawn(player_id) {
    g_player_id = player_id;
    if(!g_active)
        return;

    new game = GetEntityOwner(player_id);
    if(game == g_cstrike && !is_user_connected(player_id))
        return;

    if(game != g_dmc && game != g_tfc && game != g_ricochet)
        GameContext(game, "add_equip_prevention");
    
    if(game == g_dod)
        EnterDodTeam(player_id);
}

get_wish_or_random_index(game, category) {
    new index = g_wish[g_player_id][category];
    if(index != -1)
        g_wish_granted[g_player_id] = true;
    if(index == -1)
        index = random(get_game_category_items(game, category));

    return index;
}

get_wish_or_random(game, category) {        
    new item[64];
    copy(item, 64, get_game_category_item(game, category, get_wish_or_random_index(game, category)));
    return item;
}

public equip_valve() {
    give_item_times(g_player_id, get_wish_or_random(g_valve, e_valve_pistols), 3);

    if(!g_pistol_only) {
        new primary[32];
        copy(primary, 32, get_wish_or_random(g_valve, e_valve_primaries));
        give_item_times(g_player_id, primary, 3);

        fm_give_item(g_player_id, get_wish_or_random(g_valve, e_valve_specials));

        new grenadeIndex = g_wish[g_player_id][e_valve_grenades];
        if(grenadeIndex == -1) {
            grenadeIndex = equal(primary, "weapon_9mmAR") ? 0 : (random(get_game_category_items(g_valve, e_valve_grenades) - 1) + 1);
        } else {
            g_wish_granted[g_player_id] = true;
        }
        fm_give_item(g_player_id, get_game_category_item(g_valve, e_valve_grenades, grenadeIndex));

        give_item_times(g_player_id, "item_battery", 7);
    }

    fm_give_item(g_player_id, "weapon_crowbar");
}

public equip_cstrike() {
    new team = pev(g_player_id, pev_team);
    if(team < 1 || team > 2)
        return;

    new vipBools = get_pdata_int(g_player_id, 209);
    if(vipBools & 0xFF00) //m_bIsVIP
        return;

    fm_strip_user_weapons(g_player_id);

    new nvBools = get_pdata_int(g_player_id, 129);
    nvBools |= 1; //m_bHasNightVision
    set_pdata_int(g_player_id, 129, nvBools);
    
    message_begin(MSG_ONE, get_user_msgid("ItemStatus"), {0, 0, 0}, g_player_id);
    write_byte(1); //ITEM_STATUS_NIGHTVISION
    message_end();

    new pistolCategory = -1;
    new primaryCategory = -1;
    if(team == 2){
        pistolCategory = e_cstrike_t_pistols;
        primaryCategory = e_cstrike_t_primaries;
    }

    if(team == 1) {
        if(g_map_owner == g_cstrike)
            fm_give_item(g_player_id, "item_thighpack");

        pistolCategory = e_cstrike_ct_pistols;
        primaryCategory = e_cstrike_ct_primaries;        
    }
    
    if(pistolCategory != -1)
        give_item_times(g_player_id, get_wish_or_random(g_cstrike, pistolCategory), 4);
    
    if(!g_pistol_only) {
        if(primaryCategory != -1)
            give_item_times(g_player_id, get_wish_or_random(g_cstrike, primaryCategory), 4);

        fm_give_item(g_player_id, "weapon_hegrenade");
        give_item_times(g_player_id, "weapon_flashbang", 2);
        fm_give_item(g_player_id, "item_assaultsuit");
    }

    fm_give_item(g_player_id, "weapon_knife");
}

new bool:g_equip_gearbox[33];
new g_gearbox_ctf_items[33];

public PlayerPostThinkPre(player_id) {
    if(!g_equip_gearbox[player_id])
        return FMRES_HANDLED;

    if(pev(player_id, pev_impulse))
        return FMRES_HANDLED;

    set_pev(player_id, pev_impulse, 205);
    return FMRES_HANDLED;
}

public PlayerPostThinkPost(player_id) {
    if(!g_equip_gearbox[player_id])
        return FMRES_HANDLED;

    if(pev(player_id, pev_impulse) == 205)
        set_pev(player_id, pev_impulse, 0);

    g_player_id = player_id;
    GameContext(g_gearbox, "equip_gearbox_ctf_item");

    return FMRES_HANDLED;
}

public remove_gearbox_ctf_item(player_id){
    new item = g_gearbox_ctf_items[player_id];
    if(!item)
        return;
    
    new itemName[64];
    pev(item, pev_classname, itemName, 64);
    
    new itemOwner = pev(item, pev_owner);
    if(itemOwner)
        return;

    server_print("Deleted gearbox ctf item %d (%s) (player: %d)", item, itemName, player_id);
    fm_remove_entity(item);
    g_gearbox_ctf_items[player_id] = 0;
}

public remove_gearbox_ctf_items() {
    for(new i = 1; i <= 32; i++)
        remove_gearbox_ctf_item(i);
}

public equip_gearbox_ctf_item() {
    if(g_gearbox_ctf_items[g_player_id]) {
        remove_gearbox_ctf_item(g_player_id);
        return;
    }
    
    new item = 0;
    if(!g_pistol_only) {
        item = fm_give_item(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_powerups));
    }
    
    if(item > 0) {
        server_print("Equiped player %d with gearbox ctf item %d", g_player_id, item);
        g_gearbox_ctf_items[g_player_id] = item;
    }

    g_equip_gearbox[g_player_id] = false;
}

public SetPhysicsKeyValuePost(entity, const key[], const value[]) {
	if(equal(key, "jpj"))
		engfunc(EngFunc_SetPhysicsKeyValue, entity, "slj", value);
}

public equip_gearbox() {
    if(!g_pistol_only) {
        give_item_times(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_primaries), 5);
        give_item_times(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_specials), 5);
        fm_give_item(g_player_id, "weapon_penguin");
        give_item_times(g_player_id, "item_battery", 7);
    }

    give_item_times(g_player_id, "weapon_eagle", 7);

    fm_give_item(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_melees));

    return FMRES_HANDLED;
}

public FindEntityByStringPre(entity, const key[], const value[]) {
    if(equal(key, "classname")) {
        if(g_player_id != -1 && equal(value, "game_player_equip")) {
            new playerOwner = GetEntityOwner(g_player_id);
            if(playerOwner == -1 || playerOwner == g_dmc || playerOwner == g_tfc) {
                forward_return(FMV_CELL, 0);
            } else {
                forward_return(FMV_CELL, entity < g_gpes[playerOwner] ? g_gpes[playerOwner] : 0);
            }
            return FMRES_SUPERCEDE;
        }

        for(new i = 0; i < sizeof g_gearbox_powerups; i++) {
            if(equal(value, g_gearbox_powerups[i])) {
                do {
                    entity = engfunc(EngFunc_FindEntityByString, entity, key, value);
                    if(!entity)
                        break;

                    new owner = pev(entity, pev_owner);
                    if(!owner)
                        break;

                    new Float:ownerHealth;
                    pev(owner, pev_health, ownerHealth);
                    if(ownerHealth <= 0.0)
                        break;

                    new ownerImpulse = pev(owner, pev_impulse);
                    if(ownerImpulse == 205)
                        break;

                } while(entity);

                forward_return(FMV_CELL, entity);
                return FMRES_SUPERCEDE;
            }
        }
    }
    return FMRES_HANDLED;
}

public EmitSoundPre(entity, channel, sample[], Float:volume, Float:attenuation, fFlags, pitch) {
    if(equal(sample, "ctf/pow_armor_charge.wav") || equal(sample, "ctf/pow_health_charge.wav") || equal(sample, "ctf/pow_backpack.wav"))
        return FMRES_SUPERCEDE;
    return FMRES_HANDLED;
}

new g_dmc_powerup[33];
public equip_dmc() {
    g_dmc_powerup[g_player_id] = -1;

    for(new iAmmo = 388; iAmmo <= 391; iAmmo++)
        set_pdata_int(g_player_id, iAmmo, 0);

    if(!g_pistol_only) {
        give_item_times(g_player_id, "weapon_supershotgun", 1, true);
        give_item_times(g_player_id, get_wish_or_random(g_dmc, e_dmc_nailguns), 1, true);
        new special[32];
        copy(special, 32, get_wish_or_random(g_dmc, e_dmc_specials));
        give_item_times(g_player_id, special, 1, true);
        if(equal(special, "weapon_grenadelauncher"))
            give_item_times(g_player_id, "item_rockets", 1, true);

        g_dmc_powerup[g_player_id] = get_wish_or_random_index(g_dmc, e_dmc_powerups);
        client_print(g_player_id, print_chat, "You got %s, double tap the use key to activate for %.0f seconds!", get_game_category_item(g_dmc, e_dmc_powerups, g_dmc_powerup[g_player_id]), g_dmc_powerup_durations[g_dmc_powerup[g_player_id]]);

        give_item_times(g_player_id, "item_armor1", 1, true);
    }
    give_item_times(g_player_id, "item_shells", 4, true);
    give_item_times(g_player_id, "item_spikes", 7, true);
    give_item_times(g_player_id, "item_cells", 1, true);
    return FMRES_HANDLED;
}

public equip_defuser() {
    new bools = get_pdata_int(g_player_id, 193);
    bools |= 1 << 16; //m_bHasDefuser
    set_pdata_int(g_player_id, 193, bools);
}

public PostPlayerSpawn(player_id) {
    if(!g_active)
        return;

    new game = GetEntityOwner(player_id);
    if(game == g_cstrike && !is_user_connected(player_id))
        return;

    g_wish_granted[player_id] = false;

    g_player_id = player_id;

    if(game != g_dmc && game != g_tfc)
        GameContext(game, "remove_equip_prevention");

    if(game == g_valve)
        GameContext(game, "equip_valve");

    if(game == g_dmc)
        GameContext(game, "equip_dmc");
    
    if(game == g_cstrike)
        GameContext(game, "equip_cstrike");

    if(game == g_gearbox){
        GameContext(game, "equip_gearbox");
        g_equip_gearbox[player_id] = true;
    }

    if(game != g_cstrike && pev(g_player_id, pev_team) == 1 && g_map_owner == g_cstrike)
        GameContext(g_cstrike, "equip_defuser");
        
    if(game == g_dod)
        ExitDodTeam();
    
    wish_advertise(player_id);
}

new bool:g_use_down[33];
new Float:g_use_time[33];
public CmdStartPre(player, cmd, random_seed)
{
    if(!is_user_alive(player))
        return FMRES_IGNORED;

    //set_pev(player, pev_oldbuttons, pev(player, pev_oldbuttons) & ~IN_JUMP);

    if(g_dmc_powerup[player] == -1)
        return FMRES_IGNORED;

    if(!(get_uc(cmd, UC_Buttons) & IN_USE)) {
        g_use_down[player] = false;
        return FMRES_IGNORED;
    }
    
    if(g_use_down[player])
        return FMRES_IGNORED;
    
    g_use_down[player] = true;

    if(g_use_time[player] >= get_gametime() - 0.5) {
        g_player_id = player;
        GameContext(g_dmc, "ActivateDmcPowerup");
        g_dmc_powerup[player] = -1;
    }

    g_use_time[player] = get_gametime();

    return FMRES_HANDLED;
}

public ActivateDmcPowerup() {
    new powerup = fm_create_entity(get_game_category_item(g_dmc, e_dmc_powerups, g_dmc_powerup[g_player_id]));
    if(!powerup)
        return FMRES_HANDLED;

    new Float:origin[3];
    pev(g_player_id, pev_origin, origin);
    set_pev(powerup, pev_origin, origin);

    fm_DispatchSpawn(powerup);

    for(new i = 14; i <= 17; i++) {
        new Float:finished = get_pdata_float(powerup, i);
        if(finished > 0.0)
            set_pdata_float(powerup, i, g_dmc_powerup_durations[g_dmc_powerup[g_player_id]]);
    }

    fm_fake_touch(powerup, g_player_id);
    fm_remove_entity(powerup);
    return FMRES_HANDLED;
}

menu_addwishcategory(player_id, menu, name[]){
    if(g_pistol_only && !equal(name, "Pistol") && !equal(name, "T Pistol") && !equal(name, "CT Pistol") && !equal(name, "Melee") && !equal(name, "Allies") && !equal(name, "Axis"))
        return;

    new category = menu_items(menu);
    new title[64];
    if(g_wish[player_id][category] != -1) {
        format(title, 64, "%s (%s)", name, get_game_category_item(GetEntityOwner(player_id), category, g_wish[player_id][category]));
    } else {
        copy(title, 64, name);
    }
    menu_additem(menu, title);
}

get_game_category_name(game, category) {
    if(game == g_valve) return g_valve_category_names[category];
    if(game == g_cstrike) return g_cstrike_category_names[category];
    if(game == g_gearbox) return g_gearbox_category_names[category];
    if(game == g_dmc) return g_dmc_category_names[category];
    if(game == g_dod) return g_dod_category_names[category];
    if(game == g_ricochet) return g_ricochet_category_names[category];
    new emptyString[32] = "";
    return emptyString;
}

public wish_menu(player_id) {
    if(!g_active) {
        client_print(player_id, print_chat, "/wish is unavailable on deathmatch maps");
        return PLUGIN_HANDLED;
    }

    new game = GetEntityOwner(player_id);
    if(game == g_dod && g_map_owner == g_dod) {
        client_print(player_id, print_chat, "/wish is unavailable for DoD players on DoD maps");
        return PLUGIN_HANDLED;
    }
    
    new menu = menu_create("Wish menu", "wish_menu_handler");

    for(new iCategory = 0; iCategory < get_game_categories(game); iCategory++)
        menu_addwishcategory(player_id, menu, get_game_category_name(game, iCategory));

    menu_display(player_id, menu);
    return PLUGIN_HANDLED;
}

new g_wish_submenu[33];
public wish_menu_handler(player_id, menu, item) {
    new title[64]
    new dummy[1];
    menu_item_getinfo(menu, item, dummy[0], dummy, 0, title, 64, dummy[0]);
    menu_destroy(menu);

    if(item < 0)
        return PLUGIN_HANDLED;

    new menu = menu_create(title, "wish_submenu_handler");
    
    new game = GetEntityOwner(player_id);
    new category = item;
    for(new iGameItem = 0; iGameItem < get_game_category_items(game, category); iGameItem++) {
        new gameItem[64];
        copy(gameItem, 64, get_game_category_item(game, category, iGameItem));
        menu_additem(menu, gameItem);
    }

    if(game != g_dod)
        menu_additem(menu, "(random)");

    g_wish_submenu[player_id] = category;
    menu_display(player_id, menu);

    return PLUGIN_HANDLED;
}

public wish_submenu_handler(player_id, menu, item) {
    menu_destroy(menu);

    if(item >= 0) {
        new category = g_wish_submenu[player_id];
        new game = GetEntityOwner(player_id);
        if(item >= get_game_category_items(game, category))
            item = -1;
        g_wish[player_id][category] = item;
        
        if(game == g_dod)
            engclient_cmd(player_id, "cls_random");
    }

    return wish_menu(player_id);
}

public client_connect(player_id) {
    g_wish_granted[player_id] = false;
    for(new iCategory = 0; iCategory < MAX_CATEGORIES; iCategory++) {
        g_wish[player_id][iCategory] = -1;
    }
    return PLUGIN_CONTINUE;
}

new bool:g_resetDodBools = false;
EnterDodTeam(player_id) {
    if(GetEntityOwner(player_id) != g_dod || g_map_owner == g_dod)
        return;

    new alliesWish = g_wish[player_id][e_dod_allies];
    new axisWish = g_wish[player_id][e_dod_axis];
    if(alliesWish == 1)
        SetDodGamePlayBool(2, true);
    else if(alliesWish == 2)
        SetDodGamePlayBool(4, true);
    if(axisWish == 1)
        SetDodGamePlayBool(3, true);

    g_resetDodBools = true;
}

ExitDodTeam() {
    if(!g_resetDodBools)
        return;

    SetDodGamePlayBool(2, false);
    SetDodGamePlayBool(3, false);
    SetDodGamePlayBool(4, false);
    g_resetDodBools = false;
}

public ClientCommandPre(player_id) {
    if(GetEntityOwner(player_id) != g_dod)
        return FMRES_HANDLED;

    EnterDodTeam(player_id);    
    return FMRES_HANDLED;
}

public ClientCommandPost(player_id) {
    ExitDodTeam();
    return FMRES_HANDLED;
}

public TouchPre(touched, other) {
    if(other <= 0 || other > get_maxplayers() || GetEntityOwner(other) != g_dod)
        return FMRES_HANDLED;

    EnterDodTeam(other);    
    return FMRES_HANDLED;
}

public TouchPost(touched, other) {
    ExitDodTeam();
    return FMRES_HANDLED;
}

wish_advertise(player_id) {
    if(!is_user_connected(player_id) || is_user_alive(player_id) || g_wish_granted[player_id] || GetEntityOwner(player_id) == g_tfc || g_last_wish_ad[player_id] + g_wish_ad_interval > get_gametime())
        return;

    client_print(player_id, print_chat, "Say /wish to pick guns you would like to get in the next round.");
    g_last_wish_ad[player_id] = get_gametime();
}

public wish_advertise_all() {
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++)
        wish_advertise(player_id);
        
    return PLUGIN_CONTINUE;
}