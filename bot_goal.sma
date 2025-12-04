#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include "crossplay"

public plugin_init() {
    register_plugin("Bot goal", "0.0", "GoldSrc.one");

    new mapname[64];
    get_mapname(mapname, 64);
    if(equal(mapname, "crossfire")) {
        set_task(5.0, "crossfire_think", _, _, _, "b");
    }

    if(GetEntityOwner(0) == GetGameIndex("tfc")) {
        set_task(1.0, "tfc_think", _, _, _, "b");
    }
}

GetEntityCenter(entity, Float:center[3]) {
    new Float:mins[3];
    new Float:maxs[3];
    pev(entity, pev_mins, mins);
    pev(entity, pev_maxs, maxs);
    pev(entity, pev_origin, center);
    center[0] += (mins[0] + maxs[0]) / 2;
    center[1] += (mins[1] + maxs[1]) / 2;
    center[2] += (mins[2] + maxs[2]) / 2;
}

new g_new_goal;
public CreateGoalInContext() {
    g_new_goal = fm_create_entity("info_target");
}

CreateGoal() {
    g_new_goal = 0;
    GameContext(GetEntityOwner(0), "CreateGoalInContext");
    set_pev(g_new_goal, pev_classname, "bot_goal");
    ClassnameChanged(g_new_goal);
    return g_new_goal;
}

new g_crossfire_goal;
public crossfire_think() {
    new bool:active = false;

    new greenlight = 0;
    greenlight = engfunc(EngFunc_FindEntityByString, greenlight, "targetname", "towers_greenlight");
    if(greenlight && (pev(greenlight, pev_spawnflags) & SF_LIGHT_START_OFF) == 0)
        active = true; //strike ready

    new button = 0;
    button = engfunc(EngFunc_FindEntityByString, button, "target", "fire_button_texture");
    if(!button)
        active = false; //button not found

    if(active && !g_crossfire_goal) {
        g_crossfire_goal = CreateGoal();
        new Float:origin[3];
        GetEntityCenter(button, origin);
        set_pev(g_crossfire_goal, pev_origin, origin);
    }
    if(!active && g_crossfire_goal) {
        fm_remove_entity(g_crossfire_goal);
        g_crossfire_goal = 0;
    }
}

FindByNetnames(const netnames[][]) {
    new iName = 0;
    while(netnames[iName][0]) {
        new entity = 0;
        entity = engfunc(EngFunc_FindEntityByString, entity, "netname", netnames[iName]);
        if(entity)
            return entity;

        iName++;
    }
    return 0;
}

new g_player_goals[33];
new flagnames[][][] = {
    {"team two flag", "Red Flag", ""},
    {"team one flag", "Blue Flag", ""}
};
new dropoffnames[][][] = {
    {"team one dropoff", "Team 1 dropoff", ""},
    {"team two dropoff", "Team 2 dropoff", ""}
};

bool:tfc_find_goal(iPlayer, Float:origin[3]) {
    new iTeam = pev(iPlayer, pev_team) - 1;
    if(iTeam < 0 || iTeam >= 2)
        return false;

    new flag = FindByNetnames(flagnames[iTeam]);
    if(flag) {
        new holder = pev(flag, pev_aiment);
        if(!holder) {
            GetEntityCenter(flag, origin);
            //server_print("%d flag %f %f %f", iPlayer, origin[0], origin[1], origin[2]);
            return true;
        }
        if(holder != iPlayer)
            return false;

        new dropoff = FindByNetnames(dropoffnames[iTeam]);
        if(!dropoff)
            return false;

        GetEntityCenter(dropoff, origin);
        //server_print("%d dropoff %f %f %f", iPlayer, origin[0], origin[1], origin[2]);
        return true;
    }

    return false;
}

public tfc_think() {
    for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
        if(!is_user_connected(iPlayer) || !is_user_bot(iPlayer)) {
            if(g_player_goals[iPlayer]) {
                fm_remove_entity(g_player_goals[iPlayer]);
                g_player_goals[iPlayer] = 0;
            }
            continue;
        }

        new Float:origin[3];
        if(tfc_find_goal(iPlayer, origin)) {
            if(!g_player_goals[iPlayer]) {
                g_player_goals[iPlayer] = CreateGoal();
                set_pev(g_player_goals[iPlayer], pev_owner, iPlayer);
            }
            set_pev(g_player_goals[iPlayer], pev_origin, origin);
        }
        else if(g_player_goals[iPlayer]) {
            fm_remove_entity(g_player_goals[iPlayer]);
            g_player_goals[iPlayer] = 0;
        }
    }
}