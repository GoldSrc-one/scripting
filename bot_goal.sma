#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include "crossplay"

new g_tfc = -1;
new g_cstrike = -1;
new g_map_owner = -1;

new bool:g_as_map = false;
new bool:g_cs_map = false;
new bool:g_de_map = false;

new bool:g_cz2 = false;
new g_czFreeFlags[2][3];
new g_czCarryFlags[2][3];
new g_czCapFlags[2][6];

new g_player_goals[33];

public plugin_precache() {
    register_plugin("Bot goal", __DATE__, "GoldSrc.one");
    register_forward(FM_KeyValue, "KeyValuePre");
}

public plugin_init() {
    new mapname[64];
    get_mapname(mapname, 64);
    if(equal(mapname, "crossfire")) {
        set_task(5.0, "crossfire_think", _, _, _, "b");
    }
    
    g_tfc = GetGameIndex("tfc");
    g_cstrike = GetGameIndex("cstrike");
    g_map_owner = GetEntityOwner(0);

    if(g_map_owner == g_cstrike || g_map_owner == g_tfc)
        set_task(1.0, "goal_think", _, _, _, "b");

    if(g_map_owner == g_cstrike) {
        g_as_map = equal(mapname, "as_", 3) != 0;
        g_cs_map = equal(mapname, "cs_", 3) != 0;
        g_de_map = equal(mapname, "de_", 3) != 0;
    }

    if(g_map_owner == g_tfc) {
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
    if(!entity1)
        entity1 = iPlayer;
    if(!entity2)
        entity2 = iPlayer;

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

CountEntities(const classname[]) {
    new count = 0;
    new ent = 0;
    while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname))) {
        count++;
    }
    return count;
}

FindRandom(const classnames[][], numClassnames) {
    new count = 0;
    for(new iClassname = 0; iClassname < numClassnames; iClassname++)
        count += CountEntities(classnames[iClassname]);

    new pick = random(count);
    for(new iClassname = 0; iClassname < numClassnames; iClassname++) {
        new ent = 0;
        while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classnames[iClassname]))) {
            pick--;
            if(pick < 0)
                return ent;
        }
    }
    return 0;
}

bool:FindDistantRandom(iPlayer, Float:origin[3], const classnames[][], numClassnames) {
    // keep the current goal if we are still far away from it
    if(g_player_goals[iPlayer]) {
        new Float:player_origin[3];
        pev(iPlayer, pev_origin, player_origin);
        pev(g_player_goals[iPlayer], pev_origin, origin);
        new Float:dist = get_distance_f(player_origin, origin);
        if(dist > 256)
            return true;
    }

    new random_target = FindRandom(classnames, numClassnames);
    if(!random_target)
        return false;

    GetMoreDistantCenter(iPlayer, g_player_goals[iPlayer], random_target, origin);
    return true;
}

new g_vip;
public GetVip() {
    for(new i = 1; i <= get_maxplayers(); i++) {
        if(!is_user_alive(i) || GetEntityOwner(i) == g_cstrike)
            continue;
        
        new vipBools = get_pdata_int(i, 209);
        if(vipBools & 0xFF00) //m_bIsVIP
            return i;
    }
    return 0;
}

const MAX_HOSTAGES = 8;
new g_hostages[MAX_HOSTAGES];
new g_hostage_escorts[MAX_HOSTAGES];
new g_num_hostages;
public FindHostages(){
    g_num_hostages = 0;
    new classnames[][] = {"hostage_entity", "monster_scientist"};
    for(new iClassname = 0; iClassname < sizeof(classnames); iClassname++) {
        new ent = 0;
        while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classnames[iClassname]))) {
            if(!pev(ent, pev_solid) || g_num_hostages >= MAX_HOSTAGES)
                continue;
            
            g_hostages[g_num_hostages] = ent;
            new escort = get_pdata_ent(ent, 344);
            g_hostage_escorts[g_num_hostages] = escort < 0 ? 0 : escort;
            g_num_hostages++;
        }
    }
}

new g_ct_alive;
bool:cstrike_find_goal(iPlayer, Float:origin[3]) {
    new team = pev(iPlayer, pev_team);
    if(g_as_map) {
        new as_classnames[][] = {"func_vip_safetyzone"};
        if(team == 2)
            return FindDistantRandom(iPlayer, origin, as_classnames, sizeof(as_classnames));
            
        GameContext(g_cstrike, "GetVip");
        if(!g_vip)
            return FindDistantRandom(iPlayer, origin, as_classnames, sizeof(as_classnames));
        
        pev(g_vip, pev_origin, origin);
        return true;
    }
    if(g_cs_map) {
        if(team == 1) {
            new cs_rescue_classnames[][] = {"func_hostage_rescue", "info_hostage_rescue", "info_player_start"};
            
            new freeHostages = 0;
            new escortingHostages = 0;
            for(new i = 0; i < g_num_hostages; i++){
                if(g_hostage_escorts[i] == 0)
                    freeHostages++;
                if(g_hostage_escorts[i] == iPlayer)
                    escortingHostages++;
            }

            new maxEscortHostages = max(1, g_num_hostages / g_ct_alive);
            if(freeHostages && escortingHostages < maxEscortHostages) {
                new hostage;
                if(g_player_goals[iPlayer])
                    hostage = pev(g_player_goals[iPlayer], pev_aiment);

                new bool:isHostageFree = false;
                for(new i = 0; i < g_num_hostages; i++)
                    if(g_hostages[i] == hostage && g_hostage_escorts[i] == 0)
                        isHostageFree = true;

                if(!isHostageFree) {
                    new pick = random(freeHostages);
                    for(new i = 0; i < g_num_hostages; i++){
                        if(g_hostage_escorts[i] == 0) {
                            pick--;
                            if(pick < 0) {
                                hostage = g_hostages[i];
                                break;
                            }
                        }
                    }
                }

                if(g_player_goals[iPlayer]) {
                    set_pev(g_player_goals[iPlayer], pev_aiment, hostage);
                    set_pev(g_player_goals[iPlayer], pev_button, IN_USE);
                }

                pev(hostage, pev_origin, origin);
                return true;
            }

            if(g_player_goals[iPlayer])
                set_pev(g_player_goals[iPlayer], pev_aiment, 0);

            return FindDistantRandom(iPlayer, origin, cs_rescue_classnames, sizeof(cs_rescue_classnames));
        }
        if(team == 2) {
            new cs_t_classnames[][] = {"func_hostage_rescue", "info_hostage_rescue", "info_player_start"};
            return FindDistantRandom(iPlayer, origin, cs_t_classnames, sizeof(cs_t_classnames));
        }
    }
    if(g_de_map) {
        if(g_player_goals[iPlayer])
            set_pev(g_player_goals[iPlayer], pev_aiment, 0);
            
        new c4 = engfunc(EngFunc_FindEntityByString, 0, "model", "models/w_c4.mdl");
        if(c4) {
            new Float:player_origin[3];
            pev(iPlayer, pev_origin, player_origin);
            pev(c4, pev_origin, origin);
            new Float:dist = get_distance_f(player_origin, origin);
            if(dist <= 1250) {
                if(team == 1 && g_player_goals[iPlayer]) {
                    set_pev(g_player_goals[iPlayer], pev_aiment, c4);
                    set_pev(g_player_goals[iPlayer], pev_button, IN_USE | IN_DUCK);
                }
                return true;
            }
        }
        if(team == 1) {
            new de_ct_classnames[][] = {"func_bomb_target", "info_bomb_target", "info_player_deathmatch"};
            return FindDistantRandom(iPlayer, origin, de_ct_classnames, c4 ? sizeof(de_ct_classnames) - 1 : sizeof(de_ct_classnames));
        }
        if(team == 2) {
            new de_t_classnames[][] = {"func_bomb_target", "info_bomb_target"};
            return FindDistantRandom(iPlayer, origin, de_t_classnames, sizeof(de_t_classnames));
        }
    }
    //fy map
    {
        new fy_classnames[][] = {"info_player_start", "info_player_deathmatch"};
        return FindDistantRandom(iPlayer, origin, fy_classnames, sizeof(fy_classnames));
    }
}

public goal_think() {
    if(g_cs_map) {
        GameContext(g_cstrike, "FindHostages");
        g_ct_alive = 0;
        for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
            if(is_user_alive(iPlayer) && pev(iPlayer, pev_team) == 1)
                g_ct_alive++;
    }
    for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
        if(!is_user_connected(iPlayer) || !is_user_bot(iPlayer) || GetEntityOwner(iPlayer) == g_map_owner) {
            if(g_player_goals[iPlayer]) {
                fm_remove_entity(g_player_goals[iPlayer]);
                g_player_goals[iPlayer] = 0;
            }
            continue;
        }

        
        if(g_player_goals[iPlayer])
            set_pev(g_player_goals[iPlayer], pev_button, 0);

        new Float:origin[3];
        new bool:goalFound = false;
        if(g_map_owner == g_cstrike)
            goalFound = cstrike_find_goal(iPlayer, origin);
        if(g_map_owner == g_tfc)
            goalFound = tfc_find_goal(iPlayer, origin);

        if(goalFound) {
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

public KeyValuePre(entity, kvd) {
    new key[32];
    get_kvd(kvd, KV_KeyName, key, 32);
    if(!equal(key, "classname"))
        return FMRES_IGNORED;

    new value[32];
    get_kvd(kvd, KV_Value, value, 32);
    if(!equal(value, "bot_goal"))
        return FMRES_IGNORED;

    set_kvd(kvd, KV_Value, "info_target");
    set_task(0.0, "HandleBotGoalEntity", entity);
    return FMRES_HANDLED;
}

public HandleBotGoalEntity(entity) {
    set_pev(entity, pev_classname, "bot_goal");
    ClassnameChanged(entity);

    new targetString[64];
    pev(entity, pev_target, targetString, 64);
    server_print("map bot_goal %d target %s", entity, targetString);
    if(targetString[0]) {
        new target = engfunc(EngFunc_FindEntityByString, 0, "targetname", targetString);
        if(target) {
            set_pev(entity, pev_aiment, entity);
            set_pev(entity, pev_button, pev(entity, pev_button) | IN_USE);
        }
    }
}