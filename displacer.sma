#include <amxmodx>
#include <fakemeta>

public plugin_init() {
    register_plugin("Displacer", "0.0", "GoldSrc.one");

    register_forward(FM_Think, "ThinkPre", 0);
    register_forward(FM_Think, "ThinkPost", 1);
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_Touch, "TouchPost", 1);
    
    register_forward(FM_FindEntityByString, "FindEntityByStringPre", 0);
}

new g_displacer = false;
new g_player_id = 0;
public ThinkPre(entity) {
    new classname[24]
    pev(entity, pev_classname, classname, 24);
    if(equal(classname, "weapon_displacer")) {
        g_displacer = true;
        g_player_id = pev(entity, pev_owner);
    }
    return FMRES_HANDLED;
}

public ThinkPost(entity) {
    g_displacer = false;
    g_player_id = 0;
    return FMRES_HANDLED;
}

public TouchPre(touched, other) {
    if(!pev_valid(touched))
        return FMRES_IGNORED;

    new classname[24];
    pev(touched, pev_classname, classname, 24);
    if(!equal(classname, "displacer_ball"))
        return FMRES_IGNORED;

    g_displacer = true;
    g_player_id = other;
    return FMRES_HANDLED;
}

public TouchPost(touched, other) {
    g_displacer = false;
    g_player_id = 0;
    return FMRES_HANDLED;
}

public FindEntityByStringPre(entity, const key[], const value[]) {
    if(g_displacer && equal(key, "classname") && equal(value, "info_player_deathmatch")) {
        new player_team[16];
        get_user_team(g_player_id, player_team, 16);
        if(equal(player_team, "TERRORIST")) {
            new newEntity = engfunc(EngFunc_FindEntityByString, entity, "classname", "info_player_start");
            forward_return(FMV_CELL, newEntity);
            return FMRES_SUPERCEDE;
        }
    }
    return FMRES_HANDLED;
}