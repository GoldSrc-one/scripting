#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_valve = -1;
new g_cstrike = -1;
new g_gearbox = -1;

public plugin_init() {
    register_plugin("Equip", "0.0", "GoldSrc.one");
    register_logevent("logevent_round_start", 2, "1=Round_Start");

    for(new i = 0; i < GetNumGames(); i++) {
        new gameName[16];
        GetGameName(i, gameName, 16);

        if(equal(gameName, "valve"))
            g_valve = i;

        if(equal(gameName, "cstrike") || equal(gameName, "czero"))
            g_cstrike = i;

        if(equal(gameName, "gearbox"))
            g_gearbox = i;
    }

    if(g_gearbox != -1) {
        register_forward(FM_PlayerPostThink, "PlayerPostThinkPre", 0);
        register_forward(FM_PlayerPostThink, "PlayerPostThinkPost", 1);
        register_forward(FM_SetPhysicsKeyValue, "SetPhysicsKeyValuePost", 1);
        register_forward(FM_FindEntityByString, "FindEntityByStringPre", 0);
        register_forward(FM_EmitSound, "EmitSoundPre", 0);

        GameContext(g_gearbox, "precache_gearbox_ctf_items");
    }
}

public precache_gearbox_ctf_items(){
    new ctfItems[][] = {"item_ctfaccelerator", "item_ctfbackpack", "item_ctfregeneration", "item_ctfportablehev", "item_ctflongjump"};
    for(new i = 0; i < sizeof ctfItems; i++) {
        new item = fm_create_entity(ctfItems[i]);
        fm_DispatchSpawn(item);
        fm_remove_entity(item);
    }
}

new g_round = 0;
public logevent_round_start() {
    g_round++;
}

give_item_times(player_id, const item[], times) {
    for(new i = 0; i < times; i++)
        give_item(player_id, item);
}

new g_player_equip = -1;

public add_equip_prevention() {
    if(g_player_equip != -1)
        fm_remove_entity(g_player_equip);

    g_player_equip = fm_create_entity("game_player_equip");
}

public PrePlayerSpawn(player_id) {
    if(!is_user_connected(player_id))
        return;

    GameContext(GetEntityOwner(player_id), "add_equip_prevention");
}

public remove_equip_prevention() {
    if(g_player_equip != -1)
        fm_remove_entity(g_player_equip);

    g_player_equip = -1;
}

new g_player_id;

public equip_valve() {
    strip_user_weapons(g_player_id);

    if((g_round % 2) == 0) 
        give_item_times(g_player_id, "item_battery", 7);

    if((g_round % 3) == 0) 
        give_item(g_player_id, "item_longjump");

    new specials[][] = {"weapon_gauss", "weapon_rpg", "weapon_egon", "weapon_hornetgun"};
    new specialIndex = random(sizeof specials);
    give_item(g_player_id, specials[specialIndex]);

    new primaries[][] = {"weapon_shotgun", "weapon_9mmAR", "weapon_crossbow"};
    new primaryIndex = random(sizeof primaries);
    give_item_times(g_player_id, primaries[primaryIndex], 3);

    new pistols[][] = {"weapon_9mmhandgun", "weapon_357"};
    new pistolIndex = random(sizeof pistols);
    give_item_times(g_player_id, pistols[pistolIndex], 3);

    if(primaryIndex != 1) {
        new grenades[][] = {"weapon_tripmine", "weapon_satchel", "weapon_handgrenade", "weapon_snark"};
        new grenadeIndex = random(sizeof grenades);
        give_item(g_player_id, grenades[grenadeIndex]);
    } else {
        give_item(g_player_id, "ammo_ARgrenades");
    }

    give_item(g_player_id, "weapon_crowbar");
}

equip_cstrike_t() {
    new primaries[][] = {"weapon_awp", "weapon_g3sg1", "weapon_ak47", "weapon_scout", "weapon_m249", "weapon_sg552", "weapon_m3", "weapon_xm1014", "weapon_mac10", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_galil"};
    new primaryIndex = random(sizeof primaries);
    give_item_times(g_player_id, primaries[primaryIndex], 4);

    new secondaries[][] = {"weapon_usp", "weapon_deagle", "weapon_p228", "weapon_glock18", "weapon_elite"};
    new secondaryIndex = random(sizeof secondaries);
    give_item_times(g_player_id, secondaries[secondaryIndex], 4);
}

equip_cstrike_ct() {
    new primaries[][] = {"weapon_awp", "weapon_scout", "weapon_m249", "weapon_m4a1", "weapon_aug", "weapon_sg550", "weapon_m3", "weapon_xm1014", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_tmp", "weapon_famas", "weapon_shield"};
    new primaryIndex = random(sizeof primaries);
    give_item_times(g_player_id, primaries[primaryIndex], 4);

    new secondaries[][] = {"weapon_usp", "weapon_fiveseven", "weapon_deagle", "weapon_p228", "weapon_glock18"};
    new secondaryIndex = random(sizeof secondaries);
    give_item_times(g_player_id, secondaries[secondaryIndex], 4);

    give_item(g_player_id, "item_thighpack");
}

public equip_cstrike() {
    strip_user_weapons(g_player_id);

    if((g_round % 2) == 0)
        give_item(g_player_id, "item_assaultsuit");

    if((g_round % 3) == 0)
        give_item(g_player_id, "item_longjump");

    new player_team[16];
    get_user_team(g_player_id, player_team, 16);

    if(equal(player_team, "TERRORIST"))
        equip_cstrike_t();

    if(equal(player_team, "CT"))
        equip_cstrike_ct();

    if(random(2))
        give_item(g_player_id, "weapon_hegrenade");
    if(random(2))
        give_item(g_player_id, "weapon_flashbang");
    if(random(2))
        give_item(g_player_id, "weapon_flashbang");

    give_item(g_player_id, "weapon_knife");
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
        give_item(g_player_id, "item_longjump");
        item = give_item(g_player_id, "item_ctfportablehev");
    } else if((g_equip_gearbox[g_player_id] % 3) == 0) {
        item = give_item(g_player_id, "item_ctflongjump");
    } else if((g_equip_gearbox[g_player_id] % 2) == 0) {
        item = give_item(g_player_id, "item_ctfportablehev");
    } else {
        new ctfItems[][] = {"item_ctfaccelerator", "item_ctfbackpack", "item_ctfregeneration"};
        new ctfItemIndex = random(sizeof ctfItems);
        item = give_item(g_player_id, ctfItems[ctfItemIndex]);
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
    strip_user_weapons(g_player_id);
    equip_gearbox_ctf_item();

    new specials[][] = {"weapon_m249", "weapon_displacer", "weapon_sniperrifle"};
    new specialIndex = random(sizeof specials);
    give_item_times(g_player_id, specials[specialIndex], 5);

    new xrace[][] = {"weapon_sporelauncher", "weapon_shockrifle"};
    new xraceIndex = random(sizeof xrace);
    give_item_times(g_player_id, xrace[xraceIndex], 5);

    if(random(2))
        give_item(g_player_id, "weapon_penguin");

    give_item_times(g_player_id, "weapon_eagle", 7);

    new melees[][] = {"weapon_pipewrench", "weapon_pipewrench", "weapon_knife", "weapon_grapple"};
    new meleeIndex = random(sizeof melees);
    give_item(g_player_id, melees[meleeIndex]);

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

public PostPlayerSpawn(player_id) {
    if(!is_user_connected(player_id))
        return;

    g_player_id = player_id;

    new game = GetEntityOwner(player_id);
    GameContext(game, "remove_equip_prevention");

    if(game == g_valve)
        GameContext(game, "equip_valve");
    
    if(game == g_cstrike)
        GameContext(game, "equip_cstrike");

    if(game == g_gearbox)
        g_equip_gearbox[player_id] = g_round;
        
    if((g_round % 6) == 0) 
        client_print(player_id, print_chat, "ARMORED + LONG JUMP ROUND!");
    else if((g_round % 2) == 0) 
        client_print(player_id, print_chat, "ARMORED ROUND");
    else if((g_round % 3) == 0) 
        client_print(player_id, print_chat, "LONG JUMP ROUND");
    else
        client_print(player_id, print_chat, "unarmored round");
}