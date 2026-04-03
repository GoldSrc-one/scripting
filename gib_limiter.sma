#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

const maxGibs = 160;
new g_gibs[maxGibs];
new g_gibIndex = 0;

public plugin_init() {
    register_plugin("Gib limiter", __DATE__, "GoldSrc.one");

    register_forward(FM_SetModel, "SetModelPost", 1);
}

public SetModelPost(entity, const model[]) {
    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(!equal(classname, "gib"))
        return FMRES_IGNORED;

    if(g_gibs[g_gibIndex] != entity && pev_valid(g_gibs[g_gibIndex])) {
        pev(g_gibs[g_gibIndex], pev_classname, classname, 32);
        if(equal(classname, "gib")) {
            fm_remove_entity(g_gibs[g_gibIndex]);
        }
    }

    g_gibs[g_gibIndex] = entity;
    
    g_gibIndex++;
    if(g_gibIndex == maxGibs)
        g_gibIndex = 0;

    return FMRES_HANDLED;
}