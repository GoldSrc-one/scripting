#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include "crossplay"

public plugin_init() {
    register_plugin("Displacer", __DATE__, "GoldSrc.one");

    register_forward(FM_Think, "ThinkPre", 0);
    register_forward(FM_Think, "ThinkPost", 1);
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_Touch, "TouchPost", 1);
    
    register_forward(FM_FindEntityByString, "FindEntityByStringPre", 0);
    register_forward(FM_FindEntityInSphere, "FindEntityInSpherePre", 0);

    GameContext(GetEntityOwner(0), "CreateTarget");
}

new g_target;
public CreateTarget() {
    g_target = fm_create_entity("info_target");
    set_pev(g_target, pev_classname, "displacer_target");
}

new Float:g_lastSpawn[33][3];
public PostPlayerSpawn(player_id) {
    pev(player_id, pev_origin, g_lastSpawn[player_id]);
}

new bool:g_displacer = false;
public ThinkPre(entity) {
    new owner = pev(entity, pev_owner);
    if(owner <= 0 || owner > get_maxplayers())
        return FMRES_IGNORED;

    new classname[24]
    pev(entity, pev_classname, classname, 24);
    if(!equal(classname, "weapon_displacer"))
        return FMRES_IGNORED;
        
    g_displacer = true;
    set_pev(g_target, pev_origin, g_lastSpawn[owner]);
    return FMRES_HANDLED;
}

public ThinkPost(entity) {
    g_displacer = false;
    return FMRES_HANDLED;
}

public TouchPre(touched, other) {
    if(!pev_valid(touched) || other <= 0 || other > get_maxplayers())
        return FMRES_IGNORED;

    new classname[24];
    pev(touched, pev_classname, classname, 24);
    if(!equal(classname, "displacer_ball"))
        return FMRES_IGNORED;

    g_displacer = true;
    set_pev(g_target, pev_origin, g_lastSpawn[other]);
    return FMRES_HANDLED;
}

public TouchPost(touched, other) {
    g_displacer = false;
    return FMRES_HANDLED;
}

public FindEntityByStringPre(entity, const key[], const value[]) {
    if(g_displacer && equal(key, "classname") && equal(value, "info_player_deathmatch")) {
        forward_return(FMV_CELL, g_target);
        return FMRES_SUPERCEDE;
    }
    return FMRES_HANDLED;
}

public FindEntityInSpherePre(entity, const Float:origin[], Float:radius) {
    if(g_displacer && radius == 128.0) {
        //reduce the spawn kill radius
        entity = engfunc(EngFunc_FindEntityInSphere, entity, origin, 37.0);
        forward_return(FMV_CELL, entity);
        return FMRES_SUPERCEDE;
    }
    return FMRES_HANDLED;
}