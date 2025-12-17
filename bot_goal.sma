#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include "crossplay"

new bool:g_cz2 = false;
new g_czFreeFlags[2][3];
new g_czCarryFlags[2][3];
new g_czCapFlags[2][6];

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

    if(equal(mapname, "avanti")) {
        new cap4;
        cap4 = engfunc(EngFunc_FindEntityByString, cap4, "target", "cap4");
        if(cap4)
            set_pev(cap4, pev_netname, "Capture Point 4");
    }
    
    if(equal(mapname, "cz2")) {
        g_cz2 = true;

        new numFreeFlags[2];
        new numCarryFlags[2];
        new numCapFlags[2];
        new flag;
        while((flag = engfunc(EngFunc_FindEntityByString, flag, "model", "models/flag.mdl"))) {
            new team = 2 - pev(flag, pev_skin);
            if(team < 0 || team >= 2)
                continue;

            new classname[32];
            pev(flag, pev_classname, classname, 32);

            if(equal(classname, "info_tfgoal")) {
                g_czFreeFlags[team][numFreeFlags[team]++] = flag;
                continue;
            }
            if(equal(classname, "item_tfgoal")) {
                g_czCarryFlags[team][numCarryFlags[team]++] = flag;
                continue;
            }
            if(equal(classname, "info_tfgoal_timer")) {
                g_czCapFlags[team][numCapFlags[team]++] = flag;
                continue;
            }
        }
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

FindByNetname(const netname[]) {
    return engfunc(EngFunc_FindEntityByString, 0, "netname", netname);
}

new flagnames[][][] = {
    {"team two flag", "Red Flag", "Blue Flag", "flag", "Flag 1", "Flag 2", "Flag 3", "Flag 4", ""},
    {"team one flag", "Blue Flag", "Red Flag", "flag", "Flag 1", "Flag 2", "Flag 3", "Flag 4", ""}
};
new dropoffnames[][][] = {
    {"team one dropoff", "Team 1 dropoff", "Red Capture Point", "blue score trigger", "Capture Point 1", "Capture Point 2", "Capture Point 3", "Capture Point 4", ""},
    {"team two dropoff", "Team 2 dropoff", "Blue Capture Point", "red score trigger", "Capture Point 1", "Capture Point 2", "Capture Point 3", "Capture Point 4", ""}
};

bool:GetFlagAndDropoff(iTeam, &flag, &dropoff) {
    for(new iName = 0; flagnames[iTeam][iName][0] && dropoffnames[iTeam][iName][0]; iName++){
        flag = FindByNetname(flagnames[iTeam][iName]);
        if(!flag)
            continue;

        if(!pev(flag, pev_solid) && !pev(flag, pev_movetype))
            continue;

        dropoff = FindByNetname(dropoffnames[iTeam][iName]);
        if(!dropoff)
            continue;
        
        return true;
    }
    flag = 0;
    dropoff = 0;
    return false;
}

GetMoreDistantCenter(iPlayer, entity1, entity2, Float:origin[3]) {
    new Float:pc[3];
    new Float:ec[2][3];
    pev(iPlayer, pev_origin, pc);
    GetEntityCenter(entity1, ec[0]);
    GetEntityCenter(entity2, ec[1]);
    new moreDistant = get_distance_f(pc, ec[0]) >= get_distance_f(pc, ec[1]) ? 0 : 1;
    origin[0] = ec[moreDistant][0];
    origin[1] = ec[moreDistant][1];
    origin[2] = ec[moreDistant][2];
}

bool:cz2_find_goal(iPlayer, iTeam, Float:origin[3]) {
    new carryFlag;
    for(new i = 0; i < 3; i++){
        if(!g_czCarryFlags[iTeam][i])
            continue;

        if(pev(g_czCarryFlags[iTeam][i], pev_aiment) == iPlayer)
            carryFlag = g_czCarryFlags[iTeam][i];
    }

    if(!carryFlag) {
        new freeFlag;
        for(new i = 0; i < 3; i++) {
            if(!g_czFreeFlags[iTeam][i])
                continue;

            if(pev(g_czFreeFlags[iTeam][i], pev_solid))
                freeFlag = g_czFreeFlags[iTeam][i];
        }
        
        if(freeFlag) {
            pev(freeFlag, pev_origin, origin);
            return true;
        }
    }

    new Float:playerOrigin[3];
    pev(iPlayer, pev_origin, playerOrigin);
    new Float:minDist;
    new closestCap = 0;
    for(new i = 0; i < 6; i++) {
        if(!g_czCapFlags[iTeam][i])
            continue;

        if(!(pev(g_czCapFlags[iTeam][i], pev_effects) & EF_NODRAW))
            continue;

        new Float:capOrigin[3];
        pev(g_czCapFlags[iTeam][i], pev_origin, capOrigin);
        new Float:dist = get_distance_f(playerOrigin, capOrigin);
        if(!minDist || dist < minDist) {
            minDist = dist;
            closestCap = g_czCapFlags[iTeam][i];
        }
    }

    if(closestCap) {
        pev(closestCap, pev_origin, origin);
        return true;
    }

    return false;
}

bool:tfc_find_goal(iPlayer, Float:origin[3]) {
    new iTeam = pev(iPlayer, pev_team) - 1;
    if(iTeam < 0 || iTeam >= 2)
        return false;

    if(g_cz2)
        return cz2_find_goal(iPlayer, iTeam, origin);

    new flag;
    new dropoff;
    if(GetFlagAndDropoff(iTeam, flag, dropoff)) {
        new holder = pev(flag, pev_aiment);
        if(!holder) {
            //go for the flag
            GetEntityCenter(flag, origin);
            return true;
        }
        if(holder == iPlayer) {
            //go for the capture
            GetEntityCenter(dropoff, origin);
            return true;
        }
        //go for whatever is further
        GetMoreDistantCenter(iPlayer, flag, dropoff, origin);
        return true;
    }

    return false;
}

new g_player_goals[33];
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