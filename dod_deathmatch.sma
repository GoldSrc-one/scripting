#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
//#include <messages>

#include "crossplay"
#include "crossplay_util"

new g_dod = -1;

new bool:g_active = true;

public plugin_init() {
    register_plugin("DOD deathmatch", __DATE__, "GoldSrc.one");

    g_active = IsMapDeathmatchOrFy();
    if(!g_active)
        return;

    g_dod = GetGameIndex("dod");
    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPre", 0);

    //set_task(0.0, "RegisterVGUIMenu");
}

/*public RegisterVGUIMenu() {
    register_message(engfunc(EngFunc_RegUserMsg, "VGUIMenu", 5), "VGUIMenu");
}

public VGUIMenu(msg_id, msg_dest, entity) {
    if(GetEntityOwner(entity) != g_dod)
        return PLUGIN_CONTINUE;

    if(get_msg_arg_int(1) <= 2)
        return PLUGIN_CONTINUE;

    set_task(0.0, "PickRandomClass", entity);
    return PLUGIN_HANDLED;
}

public PickRandomClass(entity) {
    engclient_cmd(entity, "cls_random");
}*/

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

    if(equal(classname, "weapon_amerknife") || equal(classname, "weapon_colt") || equal(classname, "weapon_luger") || equal(classname, "weapon_spade"))
        return FMRES_IGNORED;

    forward_return(FMV_CELL, FM_NULLENT);
    return FMRES_SUPERCEDE;
}