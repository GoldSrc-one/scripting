#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include "crossplay"

const maxGibs = 320;
new g_gibs[maxGibs];
new g_gibIndex = 0;

public plugin_init() {
    register_plugin("Gib limiter", "0.0", "GoldSrc.one");

    register_forward(FM_SetModel, "SetModelPost", 1);
}

bool:IsGib(const classname[]) {
    return equal(classname, "gib") || equal(classname, "weaponbox");
}

public DeleteGib() {
    new entity = g_gibs[g_gibIndex];
    if(!pev_valid(entity))
        return;

    fm_call_think(entity);
    if(!pev_valid(entity))
        return;

    new numEntities = global_get(glb_maxEntities);
    for (new i = get_maxplayers() + 1; i < numEntities; i++) {
        if (i == entity || !pev_valid(i) || pev(i, pev_owner) != entity)
            continue;

        fm_remove_entity(i);
    }
}

public SetModelPost(entity, const model[]) {
    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(!IsGib(classname))
        return FMRES_IGNORED;

    if(g_gibs[g_gibIndex] != entity && pev_valid(g_gibs[g_gibIndex])) {
        pev(g_gibs[g_gibIndex], pev_classname, classname, 32);
        if(IsGib(classname)) {
            GameContext(GetEntityOwner(g_gibs[g_gibIndex]), "DeleteGib");
        }
    }

    g_gibs[g_gibIndex] = entity;
    
    g_gibIndex++;
    if(g_gibIndex == maxGibs)
        g_gibIndex = 0;

    return FMRES_HANDLED;
}