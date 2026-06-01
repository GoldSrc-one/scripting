#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_dod = -1;
const Float:thinkDelay = 0.25;
const Float:fadeTime = 0.125;

const maxPoints = 21;
new g_points[maxPoints];
new g_numPoints = 0;
new g_areas[maxPoints];
new g_prefixLen = 0;

new g_teams[][] = {"Neutral", "Allies", "Axis"};

public plugin_precache() {
    register_plugin("DoD objective UI", __DATE__, "GoldSrc.one");

    g_dod = GetGameIndex("dod");
    if(g_dod == -1 || GetEntityOwner(0) != g_dod)
        return;

    register_forward(FM_KeyValue, "KeyValuePost", true);
    set_task(thinkDelay, "think", _, _, _, "b");
}

public KeyValuePost(entity, kvd) {
    new key[16];
    get_kvd(kvd, KV_KeyName, key, 16);
    if(!equal(key, "point_index"))
        return FMRES_IGNORED;

    new value[8];
    get_kvd(kvd, KV_Value, value, 8);
    new index = str_to_num(value);
    if(index < 0 || index >= maxPoints) {
        server_print("Bad point_index: %d (^"%s^")", index, value);
        return FMRES_IGNORED;
    }

    g_points[index] = entity;

    return FMRES_HANDLED;
}

public plugin_init() {
    if(g_dod == -1 || GetEntityOwner(0) != g_dod)
        return;
    
    new pointPrefix[64] = {};
    for(new iPoint = 0; iPoint < maxPoints; iPoint++) {
        if(!g_points[iPoint])
            continue;

        new netname[64];
        pev(g_points[iPoint], pev_netname, netname, 64);
        if(!g_numPoints) {
            copy(pointPrefix, 64, netname);
            for(new i = strlen(pointPrefix) - 1; i >= 0; i--) {
                if(pointPrefix[i] == '_'){
                    pointPrefix[i] = 0;
                    break;
                }
            }
        }
        new lastDivider = 0;
        for(new i = 0; i < strlen(pointPrefix); i++) {
            if(pointPrefix[i] != netname[i]) {
                pointPrefix[lastDivider] = 0;
                break;
            }
            
            if(pointPrefix[i] == '_')
                lastDivider = i;
        }

        new targetname[64];
        pev(g_points[iPoint], pev_targetname, targetname, 64);
        if(targetname[0]) {
            new area;
            while((area = engfunc(EngFunc_FindEntityByString, area, "target", targetname))) {
                new classname[64];
                pev(area, pev_classname, classname, 64);
                if(!equal(classname, "dod_capture_area"))
                    continue;

                break;
            }
            g_areas[g_numPoints] = area;
        }

        g_points[g_numPoints] = g_points[iPoint];
        g_numPoints++;
    }
    //server_print("g_numPoints %d", g_numPoints);
    g_prefixLen = strlen(pointPrefix);
    if(g_prefixLen)
        g_prefixLen++;
}

public init() {
    GameContext(g_dod, "dod_init");
}

public dod_think() {
    const numMsg = 3;
    new messages[numMsg][1024];
    new bool:msgUsed[numMsg];
    new msgColors[numMsg][3] = { {200, 200, 200}, {20, 140, 20}, {200, 40, 40} };
    for(new iPoint = 0; iPoint < g_numPoints; iPoint++) {
        new point = g_points[iPoint];

        new m_iTeam = get_pdata_int(point, 90);
        if(m_iTeam != 1 && m_iTeam != 2)
            m_iTeam = 0;

        new netname[64];
        pev(point, pev_netname, netname, 64);

        new line[256];
        new lineLen = copy(line, 64, netname[g_prefixLen]);

        new area = g_areas[iPoint];
        if(area) {
            new m_nNum[3] = {};
            new m_nNumCap[3] = {};
            m_nNumCap[1] = get_pdata_int(area, 129);
            m_nNumCap[2] = get_pdata_int(area, 130);
            m_nNum[1] = get_pdata_int(area, 131);
            m_nNum[2] = get_pdata_int(area, 132);

            for(new iTeam = 1; iTeam <=2; iTeam++) {
                if(m_iTeam == iTeam || m_nNumCap[iTeam] <= 1 || m_nNum[iTeam] < 1)
                    continue;

                lineLen += formatex(line[lineLen], 256 - lineLen, "^t%d / %d %s", m_nNum[iTeam], m_nNumCap[iTeam], g_teams[iTeam]);
            }

            new m_bCapturing = get_pdata_int(area, 124);
            if(m_bCapturing) {
                new Float:m_fTimeRemaining = get_pdata_float(area, 128);
                lineLen += formatex(line[lineLen], 256 - lineLen, "^t%.1fs", m_fTimeRemaining);
            }
        }

        strcat(messages[m_iTeam], line, 1024);
        for(new iMsg = 0; iMsg < numMsg; iMsg++)
            strcat(messages[iMsg], "^n", 1024);

        msgUsed[m_iTeam] = true;
    }

    for(new iMsg = 0; iMsg < numMsg; iMsg++) {
        if(!msgUsed[iMsg])
            continue;
        
        for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
            new playerOwner = GetEntityOwner(iPlayer);
            if(playerOwner == -1 || playerOwner == g_dod)
                continue;

            set_dhudmessage(msgColors[iMsg][0], msgColors[iMsg][1], msgColors[iMsg][2], 0.01, 0.01, 0, 0.0, thinkDelay, fadeTime, fadeTime);
            show_dhudmessage(iPlayer, messages[iMsg]); 
        }
    }
}

public think() {
    GameContext(g_dod, "dod_think");
}