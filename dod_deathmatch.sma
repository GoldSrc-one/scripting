#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
//#include <messages>

#include "crossplay"
#include "crossplay_util"

new bool:g_active = true;
new g_dod = -1;
new g_maxplayers;

public plugin_init() {
    register_plugin("DoD deathmatch", __DATE__, "GoldSrc.one");

    g_active = IsMapDeathmatchOrFy();
    if(!g_active)
        return;

    g_dod = GetGameIndex("dod");
    g_maxplayers = get_maxplayers();
    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPre", 0);
    register_forward(FM_AddToFullPack, "AddToFullPackPost", 1);
}

new bool:g_suppress_equip;

public PrePlayerSpawn(player_id) {
    if(!g_active)
        return;

    g_suppress_equip = GetEntityOwner(player_id) == g_dod;
}

public PostPlayerSpawn(player_id) {
    if(!g_active)
        return;

    g_suppress_equip = false;
}

public CreateNamedEntityPre(iClassname) {
    if(!g_suppress_equip)
        return FMRES_IGNORED;

    new classname[32];
    fm_eng_get_string(iClassname, classname, 32);

    if(equal(classname, "weapon_amerknife") || equal(classname, "weapon_colt") || equal(classname, "weapon_gerknife") || equal(classname, "weapon_luger") || equal(classname, "weapon_spade") || equal(classname, "weapon_webley"))
        return FMRES_IGNORED;

    forward_return(FMV_CELL, FM_NULLENT);
    return FMRES_SUPERCEDE;
}

public AddToFullPackPost(es_handle, e, ent, host, hostflags, player, pSet[]) {
    if(ent <= 0 && ent > g_maxplayers)
        return FMRES_IGNORED;
    
    if(ent != host)
        set_es(es_handle, ES_Team, 0);
    
    return FMRES_HANDLED;
}