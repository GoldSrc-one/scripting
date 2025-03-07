#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_valve = -1;

public plugin_init() {
    register_plugin("fy_pool_nightmare", "0.0", "GoldSrc.one");

    new mapName[16]
    get_mapname(mapName, 16);
    if(!equal(mapName, "fy_pool_day"))
        set_fail_state("Only on fy_pool_day!");

    set_cvar_num("mp_allowmonsters", 1);

    for(new i = 0; i < GetNumGames(); i++) {
        new gameName[16];
        GetGameName(i, gameName, 16);

        if(equal(gameName, "valve"))
            g_valve = i;
    }
    
    if(g_valve == -1)
        set_fail_state("Half-Life not loaded!");

    GameContext(g_valve, "spawn_monsters");
}

public spawn_monsters() {
    new Float:origin[3];
    new Float:angles[3];

    new headcrab = fm_create_entity("monster_headcrab");
    origin[0] = 326.5;
    origin[1] = 1021.7;
    origin[2] = 72.1;
    angles[1] = 181.4;
    set_pev(headcrab, pev_origin, origin);
    set_pev(headcrab, pev_angles, angles);
    set_pev(headcrab, pev_spawnflags, 0x80000000);
    fm_DispatchSpawn(headcrab);

    new barnacle = fm_create_entity("monster_barnacle");
    origin[0] = 313.4;
    origin[1] = 1154.8;
    origin[2] = 160.0;
    set_pev(barnacle, pev_origin, origin);
    set_pev(barnacle, pev_spawnflags, 0x80000000);
    fm_DispatchSpawn(barnacle);

    for(new x = 368; x <= 464; x += 24) {
        for(new y = 560; y <= 656; y += 24) {
            new leech = fm_create_entity("monster_leech");
            origin[0] = float(x);
            origin[1] = float(y);
            origin[2] = 0.0;
            set_pev(leech, pev_origin, origin);
            set_pev(leech, pev_spawnflags, 0x80000000);
            fm_DispatchSpawn(leech);
        }
    }

    new ichthyosaur = fm_create_entity("monster_ichthyosaur");
    origin[0] = -117.2;
    origin[1] = 534.3;
    origin[2] = -42.9;
    set_pev(ichthyosaur, pev_origin, origin);
    set_pev(ichthyosaur, pev_spawnflags, 0x80000000);
    fm_DispatchSpawn(ichthyosaur);
}