#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_oldAllowMonsters = 0;

new g_valve;
new g_gearbox;

const maxMonsters = 32;
new g_numMonsters;
new g_monsters[maxMonsters];

public plugin_init() {
    register_plugin("fy_pool_nightmare", "0.0", "GoldSrc.one");

    g_oldAllowMonsters = get_cvar_num("mp_allowmonsters");

    new mapName[16];
    get_mapname(mapName, 16);
    if(!equal(mapName, "fy_pool_day"))
        return;

    register_logevent("OnRoundStart", 2, "1=Round_Start");

    set_cvar_num("mp_allowmonsters", 1);

    g_valve = GetGameIndex("valve");
    g_gearbox = GetGameIndex("gearbox");
    
    if(g_valve == -1 && g_gearbox == -1)
        set_fail_state("Half-Life / Opposing Force not loaded!");

    GameContext(g_gearbox != -1 ? g_gearbox : g_valve, "PrecacheMonsters");

    set_task(1.0, "OutOfBoundsCheck", _, _, _, "b");
}

public plugin_end() {
    set_cvar_num("mp_allowmonsters", g_oldAllowMonsters);
}

public plugin_precache() {
    new mapName[16];
    get_mapname(mapName, 16);
    if(!equal(mapName, "fy_pool_day"))
        return;

    register_forward(FM_KeyValue, "KeyValuePre")
}

public KeyValuePre(entity, kvd) {
    if(!pev_valid(entity))
        return FMRES_IGNORED;

    new classname[32];
    get_kvd(kvd, KV_ClassName, classname, 32);
    if(!equal(classname, "func_door_rotating"))
        return FMRES_IGNORED;

    new keyname[32];
    get_kvd(kvd, KV_KeyName, keyname, 32);
    if(!equal(keyname, "model"))
        return FMRES_IGNORED;

    fm_set_kvd(entity, "spawnflags", "18", "func_door_rotating");
    return FMRES_IGNORED;
}

PrecacheEntity(const classname[]) {
    new entity = fm_create_entity(classname);
    if(!entity)
        return;
    
    fm_DispatchSpawn(entity);
    fm_remove_entity(entity);
}

public PrecacheMonsters(){
    new valveMonsters[][] = {"monster_barnacle", "monster_headcrab", "monster_zombie", "monster_leech", "monster_ichthyosaur", "monster_apache"};
    for(new i = 0; i < sizeof valveMonsters; i++)
        PrecacheEntity(valveMonsters[i]);

    if(g_gearbox == -1)
        return;

    new gearboxMonsters[][] = {"monster_zombie_barney", "monster_zombie_soldier", "monster_gonome"};
    for(new i = 0; i < sizeof gearboxMonsters; i++)
        PrecacheEntity(gearboxMonsters[i]);
}

public OnRoundStart() {
    RemoveMonsters();

    GameContext(g_gearbox != -1 ? g_gearbox : g_valve, "SpawnMonsters");
}

RemoveMonsters() {
    for(new i = 0; i < g_numMonsters; i++) {
        if(!g_monsters[i])
            continue;
        
        if(pev_valid(g_monsters[i])) {
            engfunc(EngFunc_EmitSound, g_monsters[i], CHAN_STATIC, "apache/ap_rotor2.wav", 0, 0, SND_STOP, PITCH_NORM);

            fm_remove_entity(g_monsters[i]);
        }
        g_monsters[i] = 0;
    }
    g_numMonsters = 0;
}

public SpawnMonsters() {
    SpawnLeeches();
    SpawnIcky();

    new door = 0;
    while((door = fm_find_ent_by_class(door, "func_door_rotating"))) {
        SpawnCubicleMonster(door);
    }
}

SpawnMonster(const classname[], Float:x, Float:y, Float:z, Float:yaw, bool:dropToFloor = true) {
    if(g_numMonsters >= maxMonsters)
        return;

    new entity = fm_create_entity(classname);
    if(!entity)
        return;

    new Float:origin[3];
    origin[0] = x;
    origin[1] = y;
    origin[2] = z;
    set_pev(entity, pev_origin, origin);

    new Float:angles[3];
    angles[1] = yaw;
    set_pev(entity, pev_angles, angles);

    if(dropToFloor)
        set_pev(entity, pev_spawnflags, 0x80000000);

    fm_DispatchSpawn(entity);

    g_monsters[g_numMonsters++] = entity;
}

SpawnLeeches() {
    for(new x = 368; x <= 464; x += 24) {
        for(new y = 560; y <= 656; y += 24) {
            if(random(3))
                continue;

            SpawnMonster("monster_leech", 
                float(x) + random_float(-16.0, 16.0),
                float(y) + random_float(-16.0, 16.0),
                0.0 + random_float(-16.0, 16.0),
                random_float(-180.0, 180.0), false);
        }
    }
}

SpawnIcky() {
    if(random(5))
        return;

    SpawnMonster("monster_ichthyosaur",
        -128 + random_float(-64.0, 64.0),
        515 + random_float(-64.0, 64.0),
        -32 + random_float(-32.0, 32.0),
        random_float(-180.0, 180.0), false);
}

SpawnCubicleMonster(door) {
    new Float:doorOrigin[3];
    pev(door, pev_origin, doorOrigin);
    new Float:x = doorOrigin[0] + 48.0;
    new Float:y = doorOrigin[1] - 30.0;

    if(random(2)) {
        SpawnMonster("monster_headcrab", x + 32.0, y, 32.0, 180.0);
        return;
    }

    if(random(2)) {
        SpawnMonster("monster_barnacle", x + 32.0, y, 160.0, random_float(-180.0, 180.0 ), false);
        return;
    }

    if(random(2)) {
        if(g_gearbox == -1) {
            SpawnMonster("monster_zombie", x, y, 64.0, 180.0);
            return;
        }
        new type = random(3);
        if(type == 0) {
            SpawnMonster("monster_zombie", x, y, 64.0, 180.0);
        } else if(type == 1) {
            SpawnMonster("monster_zombie_barney", x, y, 64.0, 180.0);
        } else {
            SpawnMonster("monster_zombie_soldier", x, y, 64.0, 180.0);
        }
        return;
    }

    if(g_gearbox == -1)
        return;

    if(random(2)) {
        SpawnMonster("monster_gonome", x, y, 64.0, 180.0);
        return;
    }
}

public OutOfBoundsCheck() {
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!pev_valid(player_id) || !is_user_alive(player_id))
            continue;

        new Float:origin[3];
        pev(player_id, pev_origin, origin);
        if(origin[2] > -72.0 && origin[2] < 192.0)
            continue;
        
        for(new i = 0; i < g_numMonsters; i++) {
            if(!pev_valid(g_monsters[i]))
                continue;
                
            if(pev(g_monsters[i], pev_deadflag))
                continue;
            
            new classname[32];
            pev(g_monsters[i], pev_classname, classname, 32)
            if(equal(classname, "monster_apache"))
                return;
        }

        GameContext(g_gearbox != -1 ? g_gearbox : g_valve, "SpawnApache");
    }
}

public SpawnApache() {
    new Float:x = random(2) ? -768.0 : 512.0;
    new Float:y = random(2) ? -448.0 : 1408.0;
    SpawnMonster("monster_apache", x, y, 256.0, random_float(-180.0, 180.0), false);
}