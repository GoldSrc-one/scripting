#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_tfc;
new g_cstrike;

public plugin_init() {
    register_plugin("TFC sentry", "0.0", "GoldSrc.one");

    g_tfc = GetGameIndex("tfc");
    if(g_tfc == -1)
        return;

    g_cstrike = GetGameIndex("cstrike");

    register_forward(FM_Think, "ThinkPre", 0);
    register_forward(FM_Think, "ThinkPost", 1);
    register_forward(FM_FindEntityByString, "FindEntityByStringPre", 0);
}

new g_sentry = 0;
public ThinkPre(entity) {
    new classname[24];
    pev(entity, pev_classname, classname, 24);
    if(equal(classname, "building_sentrygun")) {
        g_sentry = entity;
    }
    return FMRES_HANDLED;
}

public ThinkPost(entity) {
    g_sentry = 0;
    return FMRES_HANDLED;
}

public FindEntityByStringPre(entity, const key[], const value[]) {
    if(g_sentry && equal(key, "classname") && equal(value, "building_teleporter")) {
        new Float:origin[3];
        pev(g_sentry, pev_origin, origin);
        do {
            entity = engfunc(EngFunc_FindEntityInSphere, entity, origin, 1000.0);
            if(!entity)
                break;
            
            new flags = pev(entity, pev_flags)
            if(!(flags & FL_MONSTER) || (flags & FL_NOTARGET) || pev(entity, pev_takedamage) == DAMAGE_NO || pev(entity, pev_deadflag) != DEAD_NO || pev(entity, pev_solid) == SOLID_NOT)
                continue;

            new owner = GetEntityOwner(entity);
            if(owner != -1 && (owner == g_tfc || owner == g_cstrike))
                continue;
            
            /*new classname[24];
            pev(entity, pev_classname, classname, 24);
            server_print("sentry target: %s", classname);*/

            break;
        } while(entity);

        //make it easier for bots from other games
        set_pev(g_sentry, pev_team, get_pdata_int(g_sentry, 74));
        set_pev(g_sentry, pev_owner, get_pdata_ent(g_sentry, 332));

        forward_return(FMV_CELL, entity);
        return FMRES_SUPERCEDE;
    }
    return FMRES_HANDLED;
}