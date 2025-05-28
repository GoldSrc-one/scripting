#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_valve;
new g_gearbox;
new g_dmc;
new g_cstrike;

#include "equip_gen"

new bool:g_should_grant_wish[33];
new bool:g_wish_granted[33];
new bool:g_has_wish[33];
new g_wish[33][MAX_CATEGORIES];

new g_valve_category_names[][32] = { "Pistol", "Primary", "Special", "Grenade" };
new g_cstrike_category_names[][32] = { "T Pistol", "CT Pistol", "T Primary", "CT Primary" };
new g_gearbox_category_names[][32] = { "Melee", "Primary", "Special", "PowerUp" };
new g_dmc_category_names[][32] = { "Primary", "Special", "PowerUp" };

new bool:g_active = true;
new bool:g_pistol_only = false;

public plugin_init() {
    register_plugin("Equip", "0.0", "GoldSrc.one");

    if(GetEntityOwner(0) != GetGameIndex("cstrike")) {
        g_active = false;
        return;
    }

    new mapname[64];
    get_mapname(mapname, 64);
    if(equal(mapname, "fy_", 3) && !equal(mapname, "fy_nuketown"))
        g_pistol_only = true;

    register_clcmd("say wish", "wish_menu");
    register_clcmd("say /wish", "wish_menu");
    register_clcmd("say !wish", "wish_menu");
    register_clcmd("say guns", "wish_menu");
    register_clcmd("say /guns", "wish_menu");
    register_clcmd("say !guns", "wish_menu");
    register_logevent("logevent_round_start", 2, "1=Round_Start");
    register_event("TeamScore", "TeamScore", "a");
    set_task(120.0, "wish_advertise", _, _, _, "b");

    g_valve = GetGameIndex("valve");
    g_gearbox = GetGameIndex("gearbox");
    g_dmc = GetGameIndex("dmc");
    g_cstrike = GetGameIndex("cstrike");

    if(g_gearbox != -1) {
        register_forward(FM_PlayerPostThink, "PlayerPostThinkPre", 0);
        register_forward(FM_PlayerPostThink, "PlayerPostThinkPost", 1);
        register_forward(FM_SetPhysicsKeyValue, "SetPhysicsKeyValuePost", 1);
        register_forward(FM_FindEntityByString, "FindEntityByStringPre", 0);
        register_forward(FM_EmitSound, "EmitSoundPre", 0);

        GameContext(g_gearbox, "precache_gearbox_ctf_items");
    }
    if(g_dmc != -1) {
        register_forward(FM_CmdStart, "CmdStartPre", 0)
        GameContext(g_dmc, "precache_dmc_items");
    }
}

precache_items(const items[][], count) {
    for(new i = 0; i < count; i++) {
        new item = fm_create_entity(items[i]);
        fm_DispatchSpawn(item);
        fm_remove_entity(item);
    }
}

public precache_gearbox_ctf_items(){
    new ctfItems[][] = {"item_ctfaccelerator", "item_ctfbackpack", "item_ctfregeneration", "item_ctfportablehev", "item_ctflongjump"};
    precache_items(ctfItems, sizeof ctfItems);
}

public precache_dmc_items() {
    precache_items(g_dmc_primaries, sizeof g_dmc_primaries);
    precache_items(g_dmc_specials, sizeof g_dmc_specials);
    precache_items(g_dmc_powerups, sizeof g_dmc_powerups);
    new others[][] = {"item_armor1"};
    precache_items(others, sizeof others);
}

new g_round = 0;
public logevent_round_start() {
    g_round++;
}

give_item_times(player_id, const item[], times, bool:remove = false) {
    for(new i = 0; i < times; i++) {
        new entity = fm_give_item(player_id, item);
        if(entity > 0 && remove)
            fm_remove_entity(entity);
    }
}

new g_player_equip = -1;

public add_equip_prevention() {
    if(g_player_equip != -1)
        fm_remove_entity(g_player_equip);

    g_player_equip = fm_create_entity("game_player_equip");
}

public PrePlayerSpawn(player_id) {
    if(!g_active)
        return;

    if(!is_user_connected(player_id))
        return;

    new game = GetEntityOwner(player_id);
    if(game != g_dmc)
        GameContext(game, "add_equip_prevention");
}

public remove_equip_prevention() {
    if(g_player_equip != -1)
        fm_remove_entity(g_player_equip);

    g_player_equip = -1;
}

new g_player_id;

get_wish_index(category) {
    return g_should_grant_wish[g_player_id] ? g_wish[g_player_id][category] : -1;
}

get_wish_or_random(game, category) {
    new index = get_wish_index(category);
    if(index != -1)
        g_wish_granted[g_player_id] = true;
    if(index == -1)
        index = random(get_game_category_items(game, category));
        
    new item[64];
    copy(item, 64, get_game_category_item(game, category, index));
    return item;
}

wish_granted(player_id) {
    if(!g_should_grant_wish[player_id])
        return;

    if(g_wish_granted[player_id]) {
        client_print(player_id, print_chat, "Your wish has been granted!");
    } else {
        //no wish granted
        client_print(player_id, print_chat, "Say /wish to pick guns you would like to get in the next round.");
    }
    g_should_grant_wish[player_id] = false;
}

public equip_valve() {
    fm_strip_user_weapons(g_player_id);

    if((g_round % 2) == 0) 
        give_item_times(g_player_id, "item_battery", 7);

    if((g_round % 3) == 0) 
        fm_give_item(g_player_id, "item_longjump");

    give_item_times(g_player_id, get_wish_or_random(g_valve, e_valve_pistols), 3);

    if(!g_pistol_only) {
        new primary[32];
        copy(primary, 32, get_wish_or_random(g_valve, e_valve_primaries));
        give_item_times(g_player_id, primary, 3);

        fm_give_item(g_player_id, get_wish_or_random(g_valve, e_valve_specials));

        new grenadeIndex = get_wish_index(e_valve_grenades);
        if(grenadeIndex == -1) {
            grenadeIndex = equal(primary, "weapon_9mmAR") ? 0 : (random(get_game_category_items(g_valve, e_valve_grenades) - 1) + 1);
        } else {
            g_wish_granted[g_player_id] = true;
        }
        fm_give_item(g_player_id, get_game_category_item(g_valve, e_valve_grenades, grenadeIndex));
    }

    fm_give_item(g_player_id, "weapon_crowbar");

    wish_granted(g_player_id);
}

public equip_cstrike() {
    fm_strip_user_weapons(g_player_id);

    if((g_round % 2) == 0)
        fm_give_item(g_player_id, "item_assaultsuit");

    if((g_round % 3) == 0)
        fm_give_item(g_player_id, "item_longjump");

    new player_team[16];
    get_user_team(g_player_id, player_team, 16);

    new pistolCategory = -1;
    new primaryCategory = -1;
    if(equal(player_team, "TERRORIST")){
        pistolCategory = e_cstrike_t_pistols;
        primaryCategory = e_cstrike_t_primaries;
    }

    if(equal(player_team, "CT")){
        fm_give_item(g_player_id, "item_thighpack");

        pistolCategory = e_cstrike_ct_pistols;
        primaryCategory = e_cstrike_ct_primaries;        
    }
    
    if(pistolCategory != -1)
        give_item_times(g_player_id, get_wish_or_random(g_cstrike, pistolCategory), 4);
    
    if(!g_pistol_only) {
        if(primaryCategory != -1)
            give_item_times(g_player_id, get_wish_or_random(g_cstrike, primaryCategory), 4);

        if(g_should_grant_wish[g_player_id] || random(2))
            fm_give_item(g_player_id, "weapon_hegrenade");
        if(g_should_grant_wish[g_player_id] || random(2))
            fm_give_item(g_player_id, "weapon_flashbang");
        if(g_should_grant_wish[g_player_id] || random(2))
            fm_give_item(g_player_id, "weapon_flashbang");
    }

    fm_give_item(g_player_id, "weapon_knife");

    wish_granted(g_player_id);
}

new g_equip_gearbox[33];
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

    set_pev(player_id, pev_impulse, 0);
    
    g_player_id = player_id;
    GameContext(g_gearbox, "equip_gearbox");

    g_equip_gearbox[g_player_id] = 0;

    return FMRES_HANDLED;
}

public remove_gearbox_ctf_item() {
    new newItems[33];
    for(new i = 1; i <= 32; i++) {
        new item = g_gearbox_ctf_items[i];
        if(!item)
            continue;

        dllfunc(DLLFunc_Think, item);
        
        new itemName[64];
        pev(item, pev_classname, itemName, 64);
        
        new itemOwner = pev(item, pev_owner);
        if(!itemOwner) {
            server_print("Deleted gearbox ctf item %d (%s) (player: %d)", item, itemName, i);
            fm_remove_entity(item);
        } else {
            server_print("Reassigned gearbox ctf item %d (%s) (old: %d; new: %d)", item, itemName, i, itemOwner);
            newItems[itemOwner] = item;
        }
    }

    for(new i = 1; i <= 32; i++)
        g_gearbox_ctf_items[i] = newItems[i];
}

public equip_gearbox_ctf_item() {
    if(g_gearbox_ctf_items[g_player_id]) {
        server_print("Player %d still has a gearbox ctf item %d! WHAT?", g_player_id, g_gearbox_ctf_items[g_player_id]);
        return;
    }
    
    new item = 0;
    if((g_equip_gearbox[g_player_id] % 6) == 0) {
        fm_give_item(g_player_id, "item_longjump");
        item = fm_give_item(g_player_id, "item_ctfportablehev");
    } else if((g_equip_gearbox[g_player_id] % 3) == 0) {
        item = fm_give_item(g_player_id, "item_ctflongjump");
    } else if((g_equip_gearbox[g_player_id] % 2) == 0) {
        item = fm_give_item(g_player_id, "item_ctfportablehev");
    } else if(!g_pistol_only) {
        item = fm_give_item(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_powerups));
    }
    
    if(item > 0) {
        server_print("Equiped player %d with gearbox ctf item %d", g_player_id, item);
        g_gearbox_ctf_items[g_player_id] = item;
    }
}

public SetPhysicsKeyValuePost(entity, const key[], const value[]) {
	if(equal(key, "jpj"))
		engfunc(EngFunc_SetPhysicsKeyValue, entity, "slj", value);
}

public equip_gearbox() {
    remove_gearbox_ctf_item();
    fm_strip_user_weapons(g_player_id);
    equip_gearbox_ctf_item();

    if(!g_pistol_only) {
        give_item_times(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_primaries), 5);
        give_item_times(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_specials), 5);

        if(g_should_grant_wish[g_player_id] || random(2))
            fm_give_item(g_player_id, "weapon_penguin");
    }

    give_item_times(g_player_id, "weapon_eagle", 7);

    fm_give_item(g_player_id, get_wish_or_random(g_gearbox, e_gearbox_melees));

    wish_granted(g_player_id);
    return FMRES_HANDLED;
}

public FindEntityByStringPre(entity, const key[], const value[]) {
    if(equal(key, "classname")) {
        new ctfItems[][] = {"item_ctfaccelerator", "item_ctfbackpack", "item_ctfregeneration", "item_ctfportablehev", "item_ctflongjump"};
        for(new i = 0; i < sizeof ctfItems; i++) {
            if(equal(value, ctfItems[i])) {
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
const Float:dmc_powerup_duration = 5.0;
public equip_dmc() {
    g_dmc_powerup[g_player_id] = -1;

    if(!g_pistol_only) {
        give_item_times(g_player_id, get_wish_or_random(g_dmc, e_dmc_primaries), 4, true);
        give_item_times(g_player_id, get_wish_or_random(g_dmc, e_dmc_specials), 1, true);
        g_dmc_powerup[g_player_id] = get_wish_index(e_dmc_powerups);
        if(g_dmc_powerup[g_player_id] == -1) {
            g_dmc_powerup[g_player_id] = random(get_game_category_items(g_dmc, e_dmc_powerups));
        } else {
            g_wish_granted[g_player_id] = true;
        }
        client_print(g_player_id, print_chat, "You got %s, double tap the use key to activate for %.0f seconds!", get_game_category_item(g_dmc, e_dmc_powerups, g_dmc_powerup[g_player_id]), dmc_powerup_duration);
    }

    if((g_round % 2) == 0) {
        give_item_times(g_player_id, "item_armor1", 1, true);
    }

    wish_granted(g_player_id);
    return FMRES_HANDLED;
}

public PostPlayerSpawn(player_id) {
    if(!g_active)
        return;
        
    if(!is_user_connected(player_id))
        return;

    g_wish_granted[player_id] = false;

    g_player_id = player_id;

    new game = GetEntityOwner(player_id);
    if(game != g_dmc)
        GameContext(game, "remove_equip_prevention");

    if(game == g_valve)
        GameContext(game, "equip_valve");

    if(game == g_dmc)
        GameContext(game, "equip_dmc");
    
    if(game == g_cstrike)
        GameContext(game, "equip_cstrike");

    if(game == g_gearbox)
        g_equip_gearbox[player_id] = g_round;
    
    if(game != g_dmc) {
        if((g_round % 6) == 0) 
            client_print(player_id, print_chat, "ARMORED + LONG JUMP ROUND!");
        else if((g_round % 2) == 0) 
            client_print(player_id, print_chat, "ARMORED ROUND");
        else if((g_round % 3) == 0) 
            client_print(player_id, print_chat, "LONG JUMP ROUND");
        else
            client_print(player_id, print_chat, "unarmored round");
    } else {
        if((g_round % 2) == 0) 
            client_print(player_id, print_chat, "ARMORED ROUND");
        else
            client_print(player_id, print_chat, "unarmored round");
    }
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

    fm_DispatchSpawn(powerup);

    for(new i = 14; i <= 17; i++) {
        new Float:finished = get_pdata_float(powerup, i);
        if(finished > 0.0)
            set_pdata_float(powerup, i, dmc_powerup_duration);
    }

    fm_fake_touch(powerup, g_player_id);
    fm_remove_entity(powerup);
    return FMRES_HANDLED;
}

menu_addwishcategory(player_id, menu, name[]){
    if(g_pistol_only && !equal(name, "Pistol") && !equal(name, "T Pistol") && !equal(name, "CT Pistol") && !equal(name, "Melee"))
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
    new emptyString[32] = "";
    return emptyString;
}

public wish_menu(player_id) {
    new menu = menu_create("Wish menu", "wish_menu_handler");

    new game = GetEntityOwner(player_id);
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

    g_wish_submenu[player_id] = category;
    menu_display(player_id, menu);

    return PLUGIN_HANDLED;
}

public wish_submenu_handler(player_id, menu, item) {
    menu_destroy(menu);

    if(item >= 0) {
        new category = g_wish_submenu[player_id];
        g_wish[player_id][category] = item;
        g_has_wish[player_id] = true;
    }

    return wish_menu(player_id);
}

new g_terrorist_score;
new g_ct_score;
public TeamScore() {
    new team[16];
    read_data(1, team, 16);
    new score = read_data(2);
    new bool:eligible = false;

    if(equal(team, "TERRORIST")) {
        if(score > g_terrorist_score) {
            eligible = true;
        }
        g_terrorist_score = score;
    }
    if(equal(team, "CT")) {
        if(score > g_ct_score) {
            eligible = true;
        }
        g_ct_score = score;
    }

    if(eligible) {
        for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
            if(!is_user_connected(player_id) || !is_user_alive(player_id))
                continue;

            new player_team[16];
            get_user_team(player_id, player_team, 16);
            if(!equal(team, player_team))
                continue;

            g_should_grant_wish[player_id] = true;
        }
    }
}

public client_connect(player_id) {
    g_has_wish[player_id] = false;
    for(new iCategory = 0; iCategory < MAX_CATEGORIES; iCategory++) {
        g_wish[player_id][iCategory] = -1;
    }
    return PLUGIN_CONTINUE;
}

public wish_advertise() {
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || is_user_alive(player_id) || g_has_wish[player_id])
            continue;

        client_print(player_id, print_chat, "Say /wish to pick guns you would like to get in the next round.");
    }
    return PLUGIN_CONTINUE;
}