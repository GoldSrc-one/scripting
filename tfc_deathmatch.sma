#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_tfc;

new bool:g_active = true;

public plugin_init() {
    register_plugin("TFC deathmatch", "0.0", "GoldSrc.one");

    if(GetEntityOwner(0) == GetGameIndex("cstrike")) {
        new mapname[64];
        get_mapname(mapname, 64);
        if(!equal(mapname, "fy_", 3) || equal(mapname, "fy_nuketown")) {
            g_active = false;
            return;
        }
    }

    g_tfc = GetGameIndex("tfc");

    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPre", 0);
}

new bool:g_suppress_equip;
new g_player_id;

public PrePlayerSpawn(player_id) {
    if(!g_active)
        return;

    if(GetEntityOwner(player_id) != g_tfc)
        return;
    
    g_suppress_equip = true;
    g_player_id = player_id;
}

public StripPlayer() {
    //remove grenades
    set_pdata_int(g_player_id, 14, 0);
    set_pdata_int(g_player_id, 15, 0);
    //remove detpack
    set_pdata_int(g_player_id, 51, 0);

    //remove armor
    set_pev(g_player_id, pev_armorvalue, 0.0);
}

public PostPlayerSpawn(player_id) {
    if(!g_active)
        return;

    g_suppress_equip = false;

    if(GetEntityOwner(player_id) != g_tfc)
        return;

    g_player_id = player_id;
    GameContext(g_tfc, "StripPlayer");
}

public CreateNamedEntityPre(iClassname) {
    if(!g_suppress_equip)
        return FMRES_IGNORED;

    new classname[32];
    fm_eng_get_string(iClassname, classname, 32);

    if(!equal(classname, "tf_weapon_", 10)) {
        return FMRES_IGNORED;
    }

    if(equal(classname, "tf_weapon_axe") || equal(classname, "tf_weapon_medikit") || equal(classname, "tf_weapon_knife") || equal(classname, "tf_weapon_spanner")) {
        return FMRES_HANDLED;
    }

    if(equal(classname, "tf_weapon_shotgun") || equal(classname, "tf_weapon_tranq") || equal(classname, "tf_weapon_railgun") ||
        (pev(g_player_id, pev_playerclass) == 2 && equal(classname, "tf_weapon_ng"))) {
        client_cmd(g_player_id, "use %s", classname);
        return FMRES_HANDLED;
    }

    forward_return(FMV_CELL, FM_NULLENT);
    return FMRES_SUPERCEDE;
}