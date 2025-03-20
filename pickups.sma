#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_valve;
new g_gearbox;
new g_cstrike;

#include "pickups_gen"

const maxEntities = 2048;

new g_entity_pickups[maxEntities];

const maxPickups = 64;
new g_pickup_modelindex[MAX_GAMES][maxPickups];
new g_pickup_classname[MAX_GAMES][maxPickups][32];
new g_pickup_pos;

const maxWeaponsInCategory = 16;
new g_modelindices[MAX_GAMES][MAX_CATEGORIES][maxWeaponsInCategory];

new g_valve_tripmine_modelindex = -1;

const g_cstrike_pistol_mask  = 0x04030C06; //0000 0100 0000 0011 0000 1100 0000 0110
const g_cstrike_primary_mask = 0x59FCF1A8; //0101 1001 1111 1100 1111 0001 1010 1000

public plugin_init() {
    register_forward(FM_AddToFullPack, "AddToFullPackPost", 1);
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPost", 1);
    register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateDataPost", 1);

    g_valve = GetGameIndex("valve");
    g_gearbox = GetGameIndex("gearbox");
    g_cstrike = GetGameIndex("cstrike");

    set_task(0.0, "LoadWeaponModelIndices");
}

new g_game;
public LoadWeaponModelIndices(){
    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_game = iGame;
        GameContext(iGame, "LoadGameWeaponModelIndices");
    }
}

public LoadGameWeaponModelIndices() {
    for(new iCategory = 0; iCategory < get_game_categories(g_game); iCategory++) {
        for(new iItem = 0; iItem < get_game_category_items(g_game, iCategory); iItem++) {
            new classname[32];
            copy(classname, 32, get_game_category_item(g_game, iCategory, iItem));
            new entity = fm_create_entity(classname);
            if(!entity)
                continue;

            fm_DispatchSpawn(entity);
            new model[64];
            pev(entity, pev_model, model, 64);

            new modelIndex = GetGameModelIndex(g_game, model);
            g_modelindices[g_game][iCategory][iItem] = modelIndex;

            if(equal(classname, "weapon_tripmine")) {
                if(g_valve_tripmine_modelindex != -1 && g_valve_tripmine_modelindex != modelIndex)
                    server_print("Multiple weapon_tripmines with different models?");
                g_valve_tripmine_modelindex = modelIndex;
            }

            //server_print("%d %d %d %s %d", g_game, iCategory, iItem, model, modelIndex);

            fm_remove_entity(entity);
        }
    }
}

bool:IsPickupNative(ent, host) {
    if(!g_entity_pickups[ent])
        return true;

    if(GetEntityOwner(ent) == GetEntityOwner(host))
        return true;
    
    return false;
}

public AddToFullPackPost(es_handle, e, ent, host, hostflags, player, pSet[]) {
    if(IsPickupNative(ent, host))
        return FMRES_HANDLED;

    new hostOwner = GetEntityOwner(host);
    new pos = g_entity_pickups[ent];
    new model = g_pickup_modelindex[hostOwner][pos];
    set_es(es_handle, ES_ModelIndex, model);
    if(model == g_valve_tripmine_modelindex) {
        set_es(es_handle, ES_Body, 3);
        set_es(es_handle, ES_Sequence, 8);
    }
    
    return FMRES_HANDLED;
}

new g_equip_item;
new g_equip_player;
new bool:g_equip_delete;

#define CHECK_CATEGORY(%0,%1) \
    for(new i = 0; i < sizeof %1; i++) \
        if(equal(classname, %1[i])) \
            %0 = true


public Equip() {
    new playerOwner = GetEntityOwner(g_equip_player);
    new pos = g_entity_pickups[g_equip_item];
    new classname[32];
    copy(classname, 32, g_pickup_classname[playerOwner][pos]);

    if(playerOwner == g_cstrike) {
        new bool:is_pistol = false;
        CHECK_CATEGORY(is_pistol, g_cstrike_pistols);

        new weapons = pev(g_equip_player, pev_weapons);
        if(is_pistol && (weapons & g_cstrike_pistol_mask) != 0)
            return;

        new bool:is_primary = false;
        CHECK_CATEGORY(is_primary, g_cstrike_shotguns);
        CHECK_CATEGORY(is_primary, g_cstrike_smgs);
        CHECK_CATEGORY(is_primary, g_cstrike_snipers);
        CHECK_CATEGORY(is_primary, g_cstrike_rifles);
        if(equal(classname, "weapon_shield"))
            is_primary = true;

        new bool:has_shield = (get_pdata_int(g_equip_player, 510) & 0xFF000000) != 0;
        new bool:has_primary = (weapons & g_cstrike_primary_mask) != 0 || has_shield;
        if(is_primary && has_primary)
            return;

        //don't pick up shield if he has elites
        if(equal(classname, "weapon_shield") && (weapons & (1 << 11)) != 0)
            return;

        //don't pick up elites if he has shield
        if(equal(classname, "weapon_elite") && has_shield)
            return;
    }

    new item = fm_give_item(g_equip_player, classname);
    g_equip_delete = item > 0;
}

public DeleteWeaponbox() {
    //delete the original weaponbox by mere thought
    fm_call_think(g_equip_item);
}

public TouchPre(touched, other) {
    if(IsPickupNative(touched, other))
        return FMRES_HANDLED;

    g_equip_item = touched;
    g_equip_player = other;
    new playerOwner = GetEntityOwner(other);
    GameContext(playerOwner, "Equip");
    if(g_equip_delete)
        GameContext(GetEntityOwner(g_equip_item), "DeleteWeaponbox");

    return FMRES_SUPERCEDE;
}

get_analogous_category(from_game, from_category, to_game) {
    if(from_game == to_game)
        return from_category;

    new bool:from_valve = from_game == g_valve || from_game == g_gearbox;
    new bool:to_valve = to_game == g_valve || to_game == g_gearbox;
    if(from_valve && to_valve)
        return from_category;

    if((from_valve || to_valve) && from_category <= e_valve_grenades)
        return from_category;

    if(from_valve) {
        if(to_game == g_cstrike)
            return e_cstrike_rifles;
    }

    if(from_game == g_cstrike) {
        if(to_valve)
            return random(2) ? e_valve_launchers : e_valve_energy;
    }

    return -1;
}

get_1to1_mappings(const from_classname[], to_game, to_classname[], to_classname_len) {
    copy(to_classname, to_classname_len, from_classname);

    if(to_game == g_cstrike) {
        if(equal(from_classname, "weapon_9mmhandgun"))
            copy(to_classname, to_classname_len, "weapon_glock18");
        if(equal(from_classname, "weapon_9mmAR"))
            copy(to_classname, to_classname_len, "weapon_mp5navy");
        if(equal(from_classname, "weapon_handgrenade"))
            copy(to_classname, to_classname_len, "weapon_hegrenade");
        if(equal(from_classname, "weapon_eagle"))
            copy(to_classname, to_classname_len, "weapon_deagle");
    }
    if(to_game == g_valve || to_game == g_gearbox) {
        if(equal(from_classname, "weapon_glock18"))
            copy(to_classname, to_classname_len, "weapon_9mmhandgun");
        if(equal(from_classname, "weapon_mp5navy"))
            copy(to_classname, to_classname_len, "weapon_9mmAR");
        if(equal(from_classname, "weapon_hegrenade"))
            copy(to_classname, to_classname_len, "weapon_handgrenade");
    }
    if(to_game == g_gearbox) {
        if(equal(from_classname, "weapon_deagle"))
            copy(to_classname, to_classname_len, "weapon_eagle");
    }
}

bool:find_weapon(iGame, const classname[], &found_category, &found_item) {
    found_category = -1;
    found_item = -1;
    for(new iCategory = 0; iCategory < get_game_categories(iGame); iCategory++) {
        for(new iItem = 0; iItem < get_game_category_items(iGame, iCategory); iItem++) {
            if(equal(classname, get_game_category_item(iGame, iCategory, iItem))) {
                found_category = iCategory;
                found_item = iItem;
                return true;
            }
        }
    }
    return false;
}

public OnWeaponboxCreate(entity) {
    new classname[32];
    for (new i = get_maxplayers() + 1; i < maxEntities; i++) {
        if (!pev_valid(i))
            continue;

        if (pev(i, pev_owner) != entity)
            continue;
        
        pev(i, pev_classname, classname, 32);
    }

    server_print("weaponbox: %s", classname);

    if(!classname[0])
        return;

    PreparePickup(entity, classname);
}

PreparePickup(entity, const classname[]) {
    new wbOwner = GetEntityOwner(entity);
    new wbCategory, wbItem;
    if(!find_weapon(wbOwner, classname, wbCategory, wbItem))
        return;

    //+1 to be truthy
    if(++g_pickup_pos >= maxPickups)
        g_pickup_pos = 1;
    
    new pos = g_pickup_pos;
    g_entity_pickups[entity] = pos;

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        get_1to1_mappings(classname, iGame, g_pickup_classname[iGame][pos], 32);
        new newCategory, newItem;
        if(!find_weapon(iGame, g_pickup_classname[iGame][pos], newCategory, newItem)) {
            newCategory = get_analogous_category(wbOwner, wbCategory, iGame);
            if(newCategory == -1) {
                g_pickup_classname[iGame][pos] = "";
                g_pickup_modelindex[iGame][pos] = 0;
                continue;
            }
            
            newItem = random(get_game_category_items(iGame, newCategory));
            copy(g_pickup_classname[iGame][pos], 32, get_game_category_item(iGame, newCategory, newItem));
        }
        g_pickup_modelindex[iGame][pos] = g_modelindices[iGame][newCategory][newItem];

        server_print("^t%d: %s %d", iGame, g_pickup_classname[iGame][pos], g_pickup_modelindex[iGame][pos]);
    }
}

public CreateNamedEntityPost(iClassname) {
    new entity = get_orig_retval();
    if(entity) {
        g_entity_pickups[entity] = 0;

        new classname[32];
        fm_eng_get_string(iClassname, classname, 32);
        if(equal(classname, "weaponbox")) {
            set_task(0.0, "OnWeaponboxCreate", entity);
        }
        if(equal(classname, "weapon_shield")) {
            server_print("weapon_shield");
            PreparePickup(entity, classname);
        }
        
        //TODO armoury_entity
        //TODO hl weapon_...
    }
    return FMRES_HANDLED;
}

public OnFreeEntPrivateDataPost(entity) {
    if(!g_entity_pickups[entity])
        return FMRES_HANDLED;

    server_print("OnFreeEntPrivateDataPost %d", entity);
    if(g_entity_pickups[entity] == g_pickup_pos) {
        g_pickup_pos--;
    }
    g_entity_pickups[entity] = 0;
    return FMRES_HANDLED;
}