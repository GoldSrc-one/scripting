#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_dod = -1;

const Float:probe_distance = 24.0;
const Float:probe_z_start = 20.0;
const Float:probe_z_end = 4.0;
const Float:min_z_normal = 0.9;
const Float:max_air_angle = 45.0;

public plugin_init() {
    register_plugin("dod_trigger_sandbag", "0.0", "GoldSrc.one");

    g_dod = GetGameIndex("dod");
    if(g_dod == -1 || GetEntityOwner(0) == g_dod)
        return;

    set_task(0.1, "all_think", _, _, _, "b");
}

Float:normalize_angle(Float:angle) {
    while(angle > 180.0)
        angle -= 360.0;
    while(angle < -180.0)
        angle += 360.0;
    return angle;
}

new Float:gSandbagAngles[33];
set_sandbag(iPlayer, bool:isSandbag, Float:sandbagAngle) {
    new Float:vuser1[3];
    pev(iPlayer, pev_vuser1, vuser1);
    if(isSandbag) {
        gSandbagAngles[iPlayer] = sandbagAngle;
        if(vuser1[0] != 2.0) {
            vuser1[0] = 1.0;
        }
    }
    else {
        if(vuser1[0] != 2.0) {
            vuser1[0] = 0.0;
        }
        else {
            new Float:angles[3];
            pev(iPlayer, pev_angles, angles);
            new Float:playerAngle = normalize_angle(angles[1]);
            if(xs_fabs(playerAngle - gSandbagAngles[iPlayer]) > max_air_angle) {
                vuser1[0] = 0.0;
            }
        }
    }
    set_pev(iPlayer, pev_vuser1, vuser1);
}

bool:is_sandbag(iPlayer, &Float:angle) {
    if(!is_user_alive(iPlayer) || !(pev(iPlayer, pev_flags) & FL_ONGROUND) || (pev(iPlayer, pev_flags) & FL_DUCKING))
        return false;

    new Float:start[3];
    pev(iPlayer, pev_origin, start);
    start[2] += probe_z_start;
    
    new Float:dir[3];
    pev(iPlayer, pev_angles, dir);
    angle = normalize_angle(dir[1]);
    engfunc(EngFunc_MakeVectors, dir);
    global_get(glb_v_forward, dir);
    dir[2] = 0.0;
    xs_vec_mul_scalar(dir, probe_distance, dir);

    xs_vec_add(start, dir, start);

    new Float:end[3];
    xs_vec_copy(start, end);
    end[2] = end[2] - probe_z_start + probe_z_end;

    engfunc(EngFunc_TraceLine, start, end, 1, iPlayer, 0);
    
    if (get_tr2(0, TR_StartSolid))
        return false;

    new Float:fraction;
    get_tr2(0, TR_flFraction, fraction);
    if (fraction >= 1.0)
        return false;
        
    new ent = get_tr2(0, TR_pHit);
    if(pev_valid(ent) && (pev(ent, pev_solid) != SOLID_BSP || pev(ent, pev_movetype) != MOVETYPE_NONE))
        return false;

    new Float:normal[3];
    get_tr2(0, TR_vecPlaneNormal, normal);
    if(normal[2] < min_z_normal)
        return false;
    
    return true;
}

public all_think(){
    for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
        if(GetEntityOwner(iPlayer) != g_dod)
            continue;
        
        new Float:sandbagAngle;
        new bool:isSandbag = is_sandbag(iPlayer, sandbagAngle);
        set_sandbag(iPlayer, isSandbag, sandbagAngle);
    }
}