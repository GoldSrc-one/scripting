#include <amxmodx>
#include <fun>

#include "crossplay"

new g_valve = -1;
new g_cstrike = -1;

public plugin_init() {
    register_plugin("Equip", "0.0", "GoldSrc.one");
    register_logevent("logevent_round_start", 2, "1=Round_Start");

    for(new i = 0; i < GetNumGames(); i++) {
        new gameName[16];
        GetGameName(i, gameName, 16);

        if(strcmp(gameName, "valve") == 0)
            g_valve = i;

        if(strcmp(gameName, "cstrike") == 0)
            g_cstrike = i;
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

    if(strcmp(player_team, "TERRORIST") == 0)
        equip_cstrike_t();

    if(strcmp(player_team, "CT") == 0)
        equip_cstrike_ct();

    if(random(2))
        give_item(g_player_id, "weapon_hegrenade");
    if(random(2))
        give_item(g_player_id, "weapon_flashbang");
    if(random(2))
        give_item(g_player_id, "weapon_flashbang");

    give_item(g_player_id, "weapon_knife");
}

public PostPlayerSpawn(player_id) {
    g_player_id = player_id;

    new game = GetEntityOwner(player_id);
    if(game == g_valve)
        GameContext(game, "equip_valve");
    
    if(game == g_cstrike)
        GameContext(game, "equip_cstrike");
        
    if((g_round % 6) == 0) 
        client_print(player_id, print_chat, "ARMORED + LONG JUMP ROUND!");
    else if((g_round % 2) == 0) 
        client_print(player_id, print_chat, "ARMORED ROUND");
    else if((g_round % 3) == 0) 
        client_print(player_id, print_chat, "LONG JUMP ROUND");
    else
        client_print(player_id, print_chat, "unarmored round");
}