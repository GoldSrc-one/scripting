#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

#include "crossplay"

new g_valve;
new g_gearbox;
new g_dmc;
new g_cstrike;

#include "pickups_gen"
#include "pickups_ammo_gen"
#include "pickups_items"

const maxEntities = 2048;

new bool:g_entity_pickups[maxEntities];
new g_pickup_modelindex[MAX_GAMES][maxEntities];
new g_pickup_classname[MAX_GAMES][maxEntities][32];
new Float:g_pickup_ignore[maxEntities][33];

const maxWeaponsInCategory = 16;
new g_modelindices[MAX_GAMES][MAX_CATEGORIES][maxWeaponsInCategory];
new g_ammo_modelindices[MAX_GAMES][MAX_AMMO];
new g_item_modelindices[MAX_GAMES][MAX_ITEMS];

new g_tripmine_modelindex[MAX_GAMES];
new g_snark_modelindex[MAX_GAMES];
new g_dmc_invisibility_mi;
new g_dmc_super_damage_mi;
new g_dmc_invulnerability_mi;

const g_cstrike_pistol_mask  = 0x04030C06; //0000 0100 0000 0011 0000 1100 0000 0110
const g_cstrike_primary_mask = 0x59FCF1A8; //0101 1001 1111 1100 1111 0001 1010 1000

new g_cstrike_armoury_classname[][32] = {
    "weapon_mp5navy", "weapon_tmp", "weapon_p90", "weapon_mac10", "weapon_ak47", "weapon_sg552", "weapon_m4a1", "weapon_aug", "weapon_scout", "weapon_g3sg1", "weapon_awp", "weapon_m3", "weapon_xm1014", "weapon_m249", "weapon_flashbang", "weapon_hegrenade", "item_kevlar", "item_assaultsuit", "weapon_smokegrenade",
    "weapon_shield", "weapon_famas", "weapon_sg550", "weapon_galil", "weapon_ump45", "weapon_glock18", "weapon_usp", "weapon_elite", "weapon_fiveseven", "weapon_p228", "weapon_deagle"
};

new g_ammo_offsets[MAX_GAMES];

public plugin_precache() {
    register_plugin("Pickups", "0.0", "GoldSrc.one");
    register_forward(FM_Spawn, "SpawnPost", 1);
}

new g_game;
public plugin_init() {
    register_forward(FM_AddToFullPack, "AddToFullPackPost", 1);
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPost", 1);
    register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateDataPost", 1);
    register_forward(FM_EmitSound, "EmitSoundPost", 1);

    g_valve = GetGameIndex("valve");
    if(g_valve != -1)
        g_ammo_offsets[g_valve] = 310;

    g_gearbox = GetGameIndex("gearbox");
    if(g_gearbox != -1)
        g_ammo_offsets[g_gearbox] = 354;

    g_dmc = GetGameIndex("dmc");
    if(g_dmc != -1)
        g_ammo_offsets[g_dmc] = 387; //m_pCurrentAmmo and following members instead of m_rgAmmo

    g_cstrike = GetGameIndex("cstrike");
    if(g_cstrike != -1)
        g_ammo_offsets[g_cstrike] = 376;

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_game = iGame;
        GameContext(iGame, "PrecacheItems");
    }

    if(GetEntityOwner(0) == g_cstrike)
        register_logevent("logevent_round_start", 2, "1=Round_Start");
    
    
    set_task(0.0, "LoadWeaponModelIndices");
}

PrecacheItem(const classname[]) {
    new item = fm_create_entity(classname);
    if(!item)
        return;
    
    fm_DispatchSpawn(item);
    fm_remove_entity(item);
}

public PrecacheItems() {
    if(g_game == g_dmc) {
        for(new iCategory = 0; iCategory < get_game_categories(g_game); iCategory++)
            for(new iItem = 0; iItem < get_game_category_items(g_game, iCategory); iItem++)
                PrecacheItem(get_game_category_item(g_game, iCategory, iItem));
    
        for(new iAmmo = 0; iAmmo < get_num_ammo(g_game); iAmmo++)
            PrecacheItem(get_ammo_classname(g_game, iAmmo));
    }
        
    for(new iItem = 0; iItem < get_num_items(g_game); iItem++)
        PrecacheItem(get_item(g_game, iItem));
}

new bool:g_weapon_models_loaded = false;
public LoadWeaponModelIndices() {
    if(g_weapon_models_loaded)
        return;

    g_weapon_models_loaded = true;

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_game = iGame;
        GameContext(iGame, "LoadGameWeaponModelIndices");
    }
}

GetModelIndexFromClassname(const classname[]) {
    new entity = fm_create_entity(classname);
    if(!entity)
        return 0;

    fm_DispatchSpawn(entity);
    new model[64];
    pev(entity, pev_model, model, 64);

    fm_remove_entity(entity);

    return GetGameModelIndex(g_game, model);
}

public LoadGameWeaponModelIndices() {
    for(new iCategory = 0; iCategory < get_game_categories(g_game); iCategory++) {
        for(new iItem = 0; iItem < get_game_category_items(g_game, iCategory); iItem++) {
            new classname[32];
            copy(classname, 32, get_game_category_item(g_game, iCategory, iItem));

            new modelIndex = GetModelIndexFromClassname(classname);
            g_modelindices[g_game][iCategory][iItem] = modelIndex;

            if(equal(classname, "weapon_tripmine"))
                g_tripmine_modelindex[g_game] = modelIndex;
            if(equal(classname, "weapon_snark"))
                g_snark_modelindex[g_game] = modelIndex;
        }
    }
    for(new iAmmo = 0; iAmmo < get_num_ammo(g_game); iAmmo++) {
        g_ammo_modelindices[g_game][iAmmo] = GetModelIndexFromClassname(get_ammo_classname(g_game, iAmmo));
        //server_print("%d %d %s %d", g_game, iAmmo, get_ammo_classname(g_game, iAmmo), g_ammo_modelindices[g_game][iAmmo]);
    }
    for(new iItem = 0; iItem < get_num_items(g_game); iItem++){
        new classname[32];
        copy(classname, 32, get_item(g_game, iItem));
        new modelIndex = GetModelIndexFromClassname(classname);
        g_item_modelindices[g_game][iItem] = modelIndex;

        if(g_game == g_dmc) {
            if(equal(classname, "item_artifact_invisibility"))
                g_dmc_invisibility_mi = modelIndex;
            if(equal(classname, "item_artifact_super_damage"))
                g_dmc_super_damage_mi = modelIndex;
            if(equal(classname, "item_artifact_invulnerability"))
                g_dmc_invulnerability_mi = modelIndex;
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
    new model = g_pickup_modelindex[hostOwner][ent];
    set_es(es_handle, ES_ModelIndex, model);
    set_es(es_handle, ES_Body, 0);
    set_es(es_handle, ES_Sequence, 0);
    set_es(es_handle, ES_AnimTime, 0.0);
    set_es(es_handle, ES_FrameRate, 0.0);
    set_es(es_handle, ES_RenderMode, 0);
    set_es(es_handle, ES_RenderFx, 0);
    if(model) {
        if(model == g_tripmine_modelindex[hostOwner]) {
            set_es(es_handle, ES_Body, 3);
            set_es(es_handle, ES_Sequence, 8);
        } else if(model == g_snark_modelindex[hostOwner]) {
            set_es(es_handle, ES_Sequence, 1);
            set_es(es_handle, ES_FrameRate, 1.0);
        } else if(hostOwner == g_dmc) {
            if(model == g_dmc_invisibility_mi) {
                set_es(es_handle, ES_RenderFx, 19);
                set_es(es_handle, ES_RenderColor, {128, 128, 128});
                set_es(es_handle, ES_RenderMode, 1);
                set_es(es_handle, ES_RenderAmt, 30);
            } else if(model == g_dmc_super_damage_mi) {
                set_es(es_handle, ES_RenderFx, 19);
                set_es(es_handle, ES_RenderColor, {128, 128, 255});
                set_es(es_handle, ES_RenderAmt, 100);
            } else if(model == g_dmc_invulnerability_mi) {
                set_es(es_handle, ES_RenderFx, 19);
                set_es(es_handle, ES_RenderColor, {255, 128, 0});
                set_es(es_handle, ES_RenderAmt, 100);
            }
        }
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

stock fm_give_item2(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save || pev(ent, pev_flags) & FL_KILLME)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

public Equip() {
    new playerOwner = GetEntityOwner(g_equip_player);
    new classname[32];
    copy(classname, 32, g_pickup_classname[playerOwner][g_equip_item]);
    if(!classname[0])
        return;

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

    new ammo[32];
    for(new i = 0; i < 32; i++)
        ammo[i] = get_pdata_int(g_equip_player, g_ammo_offsets[playerOwner] + i);
    new Float:oldHealth;
    pev(g_equip_player, pev_health, oldHealth);

    new item = fm_give_item2(g_equip_player, classname);
    g_equip_delete = item > 0;
    
    for(new i = 0; i < 32; i++)
        if(ammo[i] != get_pdata_int(g_equip_player, g_ammo_offsets[playerOwner] + i))
            g_equip_delete = true;
    new Float:newHealth;
    pev(g_equip_player, pev_health, newHealth);
    if(oldHealth != newHealth)
        g_equip_delete = true;

    if(playerOwner == g_dmc && item > 0) {
        fm_remove_entity(item);
    }
}

public DeleteWeaponbox() {
    unset_entity_pickup(g_equip_item);

    new classname[32];
    pev(g_equip_item, pev_classname, classname, 32);
    if(equal(classname, "armoury_entity")) {
        //turn armoury_entity invisible and untouchable
        set_pev(g_equip_item, pev_effects, pev(g_equip_item, pev_effects) | EF_NODRAW);
        set_pev(g_equip_item, pev_solid, SOLID_NOT);
        return;
    }

    if(contain(classname, "ammo_") == 0 || contain(classname, "item_") == 0 || contain(classname, "weapon_") == 0) {
        if(!(pev(g_equip_item, pev_spawnflags) & SF_NORESPAWN)) {
            set_pev(g_equip_item, pev_effects, pev(g_equip_item, pev_effects) | EF_NODRAW);
            set_pev(g_equip_item, pev_solid, SOLID_NOT);
            set_task(contain(classname, "item_") == 0 ? 30.0 : 20.0, "Respawn", g_equip_item);
            return;
        }
    }

    if(equal(classname, "weaponbox") || equal(classname, "weapon_shield")) {
        //delete the original weaponbox by mere thought
        fm_call_think(g_equip_item);
    }

    //still alive?
    if(pev_valid(g_equip_item)) {
        new numEntities = global_get(glb_maxEntities);
        for (new i = get_maxplayers() + 1; i < numEntities; i++) {
            if (!pev_valid(i))
                continue;

            if (pev(i, pev_owner) != g_equip_item)
                continue;

            fm_remove_entity(i);
        }
    }

    fm_remove_entity(g_equip_item);
}

public TouchPre(touched, other) {
    if(IsPickupNative(touched, other) || !is_user_alive(other) || (pev(touched, pev_effects) & EF_NODRAW))
        return FMRES_IGNORED;

    if(g_pickup_ignore[touched][other] > get_gametime())
        return FMRES_SUPERCEDE;

    g_pickup_ignore[touched][other] = get_gametime() + 5.0;

    g_equip_item = touched;
    g_equip_player = other;
    g_equip_delete = false;
    new playerOwner = GetEntityOwner(g_equip_player);
    GameContext(playerOwner, "Equip");
    if(g_equip_delete && pev_valid(g_equip_item))
        GameContext(GetEntityOwner(g_equip_item), "DeleteWeaponbox");

    return FMRES_SUPERCEDE;
}

get_analogous_category(from_game, const classname[], to_game) {
    if(!get_game_categories(to_game))
        return -1;

    new from_category, from_item;
    if(find_weapon(from_game, classname, from_category, from_item))
        for(new i = 0; i < get_game_categories(to_game); i++)
            if(equal(get_game_category(from_game, from_category), get_game_category(to_game, i)))
                return i;

    new unmatched_categories[MAX_CATEGORIES];
    new num_unmatched = 0;
    for(new i = 0; i < get_game_categories(to_game); i++) {
        new bool:matched = false;
        for(new j = 0; j < get_game_categories(from_game); j++) {
            if(equal(get_game_category(to_game, i), get_game_category(from_game, j))) {
                matched = true;
                break;
            }
        }
        if(matched)
            continue;

        unmatched_categories[num_unmatched] = i;
        num_unmatched++;
    }
    if(num_unmatched > 0)
        return unmatched_categories[random(num_unmatched)];

    return random(get_game_categories(to_game));
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
    if(!pev_valid(entity))
        return;

    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(!equal(classname, "weaponbox"))
        return;

    new numEntities = global_get(glb_maxEntities);
    for (new i = get_maxplayers() + 1; i < numEntities; i++) {
        if (!pev_valid(i))
            continue;

        if (pev(i, pev_owner) != entity)
            continue;
        
        pev(i, pev_classname, classname, 32);
    }

    //server_print("weaponbox: %s", classname);

    PreparePickup(entity, classname);
}

public OnDmcBackpackCreate(entity) {
    if(!pev_valid(entity))
        return;

    new netname[32];
    pev(entity, pev_classname, netname, 32);
    if(!equal(netname, "item_backpack"))
        return;

    pev(entity, pev_netname, netname, 32);

    if(equal(netname, "Double-barrelled Shotgun"))
        PreparePickup(entity, "weapon_supershotgun");
    else if(equal(netname, "Nailgun"))
        PreparePickup(entity, "weapon_nailgun");
    else if(equal(netname, "Super Nailgun"))
        PreparePickup(entity, "weapon_supernailgun");
    else if(equal(netname, "Grenade Launcher"))
        PreparePickup(entity, "weapon_grenadelauncher");
    else if(equal(netname, "Rocket Launcher"))
        PreparePickup(entity, "weapon_rocketlauncher");
    else if(equal(netname, "Thunderbolt"))
        PreparePickup(entity, "weapon_lightning");
    else
        PreparePickup(entity, netname);
}

public OnItemMaterialize(entity) {
    if(!pev_valid(entity) || (pev(entity, pev_effects) & EF_NODRAW))
        return;

    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(contain(classname, "ammo_") != 0 && contain(classname, "item_") != 0 && contain(classname, "weapon_") != 0)
        return;
    
    LoadWeaponModelIndices();
    PreparePickup(entity, classname);
}

bool:IsAmmo(const classname[]) {
    if(equal(classname, "ammo_ARgrenades"))
        return false;

    if(contain(classname, "ammo_") == 0)
        return true;

    if(GetEntityOwner(0) == g_dmc)
        for(new iAmmo = 0; iAmmo < get_num_ammo(g_dmc); iAmmo++)
            if(equal(classname, get_ammo_classname(g_dmc, iAmmo)))
                return true;
    
    return false;
}

const Float:maxAmmoDistance = 256.0;

PrepareAmmoPickup(entity, const classname[]) {
    new Float:entityOrigin[3];
    pev(entity, pev_origin, entityOrigin);

    new nearestWeapon = 0;
    new Float:weaponDistance = maxAmmoDistance;

    new numEntities = global_get(glb_maxEntities);
    for (new iWeapon = get_maxplayers() + 1; iWeapon < numEntities; iWeapon++) {
        if(!g_entity_pickups[iWeapon])
            continue;

        new weaponClassname[32];
        pev(iWeapon, pev_classname, weaponClassname, 32);
        if(contain(weaponClassname, "weapon_") != 0)
            continue;
        
        new Float:weaponOrigin[3];
        pev(iWeapon, pev_origin, weaponOrigin);
        new Float:distance = get_distance_f(entityOrigin, weaponOrigin);
        if(distance >= weaponDistance)
            continue;
        
        nearestWeapon = iWeapon;
        weaponDistance = distance;
    }

    //server_print("nearestWeapon: %d %f", nearestWeapon, weaponDistance);

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_pickup_classname[iGame][entity] = "";
        g_pickup_modelindex[iGame][entity] = 0;        
        new bool:exactMatch = false;
        for(new iAmmo = 0; iAmmo < get_num_ammo(iGame); iAmmo++) {
            if(equal(classname, get_ammo_classname(iGame, iAmmo))) {
                copy(g_pickup_classname[iGame][entity], 32, classname);
                g_pickup_modelindex[iGame][entity] = g_ammo_modelindices[iGame][iAmmo];
                exactMatch = true;
                break;
            }
        }
        if(exactMatch || !nearestWeapon)
            continue;

        for(new iAmmo = 0; iAmmo < get_num_ammo(iGame); iAmmo++) {
            if(!equal(g_pickup_classname[iGame][nearestWeapon], get_ammo_weapon(iGame, iAmmo)))
                continue;

            copy(g_pickup_classname[iGame][entity], 32, get_ammo_classname(iGame, iAmmo));
            g_pickup_modelindex[iGame][entity] = g_ammo_modelindices[iGame][iAmmo];
            break;
        }
        //server_print("^t%d %s %d", iGame, g_pickup_classname[iGame][entity], g_pickup_modelindex[iGame][entity]);
    }
}

bool:IsItem(const classname[]) {
    if(contain(classname, "item_") == 0)
        return true;

    return false;
}

PrepareItemPickup(entity, const classname[]) {
    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_pickup_classname[iGame][entity] = "";
        g_pickup_modelindex[iGame][entity] = 0;
        new bool:exactMatch = false;
        new numItems = get_num_items(iGame);
        for(new iItem = 0; iItem < numItems; iItem++) {
            if(equal(classname, get_item(iGame, iItem))) {
                copy(g_pickup_classname[iGame][entity], 32, classname);
                g_pickup_modelindex[iGame][entity] = g_item_modelindices[iGame][iItem];
                exactMatch = true;
                break;
            }
        }
        if(exactMatch)
            continue;

        new probSum = numItems;
        probSum = (probSum * probSum + probSum) / 2;
        new pick = random(probSum);
        for(new iItem = 0; iItem < numItems; iItem++) {
            new prob = numItems - iItem;
            if(pick >= prob) {
                pick -= prob;
                continue;
            }
            copy(g_pickup_classname[iGame][entity], 32, get_item(iGame, iItem));
            g_pickup_modelindex[iGame][entity] = g_item_modelindices[iGame][iItem];
            break;
        }
    }
}

PreparePickup(entity, const classname[]) {
    new numEntities = global_get(glb_maxEntities);
    for(new iEntity = get_maxplayers() + 1; iEntity < numEntities; iEntity++)
        for(new iPlayer = 1; iPlayer <= 32; iPlayer++)
            g_pickup_ignore[iEntity][iPlayer] = 0.0;

    new wbOwner = GetEntityOwner(entity);

    //don't eat the C4!
    if(wbOwner == g_cstrike) {
        new model[64];
        pev(entity, pev_model, model, 64);
        if(equal(model, "models/w_backpack.mdl") || equal(model, "cstrike/models/w_backpack.mdl"))
            return;
    }

    g_entity_pickups[entity] = true;

    //server_print("PreparePickup: %d %s", entity, classname);

    if(IsAmmo(classname)) {
        PrepareAmmoPickup(entity, classname);
        return;
    }

    if(IsItem(classname)) {
        PrepareItemPickup(entity, classname);
        return;
    }

    //the rest of this function is "PrepareWeaponPickup"

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        get_1to1_mappings(classname, iGame, g_pickup_classname[iGame][entity], 32);
        new newCategory, newItem;
        if(!find_weapon(iGame, g_pickup_classname[iGame][entity], newCategory, newItem)) {
            newCategory = get_analogous_category(wbOwner, g_pickup_classname[iGame][entity], iGame);
            if(newCategory == -1) {
                g_pickup_classname[iGame][entity] = "";
                g_pickup_modelindex[iGame][entity] = 0;
                continue;
            }
            
            newItem = random(get_game_category_items(iGame, newCategory));
            copy(g_pickup_classname[iGame][entity], 32, get_game_category_item(iGame, newCategory, newItem));
        }
        g_pickup_modelindex[iGame][entity] = g_modelindices[iGame][newCategory][newItem];

        //server_print("^t%d: %s %d", iGame, g_pickup_classname[iGame][entity], g_pickup_modelindex[iGame][entity]);
    }

    new Float:entityOrigin[3];
    pev(entity, pev_origin, entityOrigin);

    for(new iAmmo = get_maxplayers() + 1; iAmmo < numEntities; iAmmo++) {
        if(!g_entity_pickups[iAmmo])
            continue;

        new ammoClassname[32];
        pev(iAmmo, pev_classname, ammoClassname, 32);
        if(!IsAmmo(ammoClassname))
            continue;

        new Float:ammoOrigin[3];
        pev(iAmmo, pev_origin, ammoOrigin);
        if(get_distance_f(entityOrigin, ammoOrigin) >= maxAmmoDistance)
            continue;
        
        PrepareAmmoPickup(iAmmo, ammoClassname);
    }
}

public CreateNamedEntityPost(iClassname) {
    new entity = get_orig_retval();
    if(entity) {
        g_entity_pickups[entity] = false;

        new classname[32];
        fm_eng_get_string(iClassname, classname, 32);
        //server_print("CreateNamedEntityPost: %d %s", entity, classname);

        if(equal(classname, "weaponbox")) {
            set_task(0.0, "OnWeaponboxCreate", entity);
        }
        if(equal(classname, "weapon_shield")) {
            //server_print("weapon_shield");
            PreparePickup(entity, classname);
        }
        if(equal(classname, "item_backpack")) {
            set_task(0.0, "OnDmcBackpackCreate", entity);
        }
    }
    return FMRES_HANDLED;
}

public SpawnPost(entity) {
    if(entity && !pev_valid(entity))
        return FMRES_IGNORED;

    set_task(0.0, "OnItemMaterialize", entity);
    return FMRES_HANDLED;
}

public EmitSoundPost(entity, channel, const sample[], Float:volume, attenuation, flags, pitch) {
    if(channel != CHAN_WEAPON)
        return FMRES_IGNORED;

    if(equal(sample, "items/suitchargeok1.wav") || equal(sample, "items/itembk2.wav")) {
        set_task(0.0, "OnItemMaterialize", entity);
        return FMRES_HANDLED;
    }
    return FMRES_IGNORED;
}

public Respawn(entity) {
    if(!pev_valid(entity) || !(pev(entity, pev_effects) & EF_NODRAW))
        return;

    if(GetEntityOwner(0) == g_dmc) {
        engfunc(EngFunc_EmitSound, entity, CHAN_WEAPON, "items/itembk2.wav", 1.0, ATTN_NORM, 0, 100);
    } else {
        engfunc(EngFunc_EmitSound, entity, CHAN_WEAPON, "items/suitchargeok1.wav", 1.0, ATTN_NORM, 0, 150);
    }
    set_pev(entity, pev_effects, (pev(entity, pev_effects) & ~EF_NODRAW) | EF_MUZZLEFLASH);
    set_pev(entity, pev_solid, SOLID_TRIGGER);
    OnItemMaterialize(entity);
}

public logevent_round_start() {
    new classname[32];
    new numEntities = global_get(glb_maxEntities);
    for (new entity = get_maxplayers() + 1; entity < numEntities; entity++) {
        unset_entity_pickup(entity);

        if (!pev_valid(entity))
            continue;
        
        pev(entity, pev_classname, classname, 32);
        if(equal(classname, "armoury_entity")) {
            new armouryIndex = get_pdata_int(entity, 34);
            //server_print("armoury_entity: %s", g_cstrike_armoury_classname[armouryIndex]);
            PreparePickup(entity, g_cstrike_armoury_classname[armouryIndex]);
        }
    }
}

unset_entity_pickup(entity) {
    if(!g_entity_pickups[entity])
        return;

    g_entity_pickups[entity] = false;
}

public OnFreeEntPrivateDataPost(entity) {
    unset_entity_pickup(entity);
    return FMRES_HANDLED;
}