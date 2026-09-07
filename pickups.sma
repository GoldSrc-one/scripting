#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <messages>

#include "crossplay"

new g_valve;
new g_gearbox;
new g_dmc;
new g_cstrike;
new g_tfc;
new g_dod;
new g_map_owner;

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

const maxTfcClasses = 9;
new g_tfc_modelindex[maxTfcClasses][maxEntities];
new g_tfc_classname[maxTfcClasses][maxEntities][32];

new g_ammo_offsets[MAX_GAMES];

public plugin_precache() {
    register_plugin("Pickups", __DATE__, "GoldSrc.one");
    register_forward(FM_Spawn, "SpawnPost", 1);
}

new g_game;
public plugin_init() {
    register_forward(FM_AddToFullPack, "AddToFullPackPost", 1);
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPost", 1);
    register_forward(FM_CreateEntity, "CreateEntityPost", 1);
    register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateDataPost", 1);
    register_forward(FM_EmitSound, "EmitSoundPost", 1);
    register_message(get_user_msgid("CurWeapon"), "CurWeapon");

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

    g_tfc = GetGameIndex("tfc");
    if(g_tfc != -1)
        g_ammo_offsets[g_tfc] = 574;

    g_dod = GetGameIndex("dod");
    if(g_dod != -1)
        g_ammo_offsets[g_dod] = 281;

    g_map_owner = GetEntityOwner(0);

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_game = iGame;
        GameContext(iGame, "PrecacheItems");
    }

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

GetTfcModel(const classname[]) {
    new model[64];
    
    if(equal(classname, "tf_weapon_shotgun")) copy(model, 64, "models/p_smallshotgun.mdl");
    if(equal(classname, "tf_weapon_ng")) copy(model, 64, "models/p_nailgun.mdl");
    if(equal(classname, "tf_weapon_sniperrifle")) copy(model, 64, "models/p_sniper.mdl");
    if(equal(classname, "tf_weapon_autorifle")) copy(model, 64, "models/p_sniper.mdl");
    if(equal(classname, "tf_weapon_supershotgun")) copy(model, 64, "models/p_shotgun.mdl");
    if(equal(classname, "tf_weapon_rpg")) copy(model, 64, "models/p_srpg.mdl");
    if(equal(classname, "tf_weapon_gl")) copy(model, 64, "models/p_glauncher.mdl");
    if(equal(classname, "tf_weapon_pl")) copy(model, 64, "models/p_glauncher.mdl");
    if(equal(classname, "tf_weapon_superng")) copy(model, 64, "models/p_snailgun.mdl");
    if(equal(classname, "tf_weapon_ac")) copy(model, 64, "models/p_mini.mdl");
    if(equal(classname, "tf_weapon_ic")) copy(model, 64, "models/p_rpg.mdl");
    if(equal(classname, "tf_weapon_flamethrower")) copy(model, 64, "models/p_egon.mdl");
    if(equal(classname, "tf_weapon_tranq")) copy(model, 64, "models/p_spygun.mdl");
    if(equal(classname, "tf_weapon_railgun")) copy(model, 64, "models/p_9mmhandgun.mdl");
    if(equal(classname, "tf_weapon_caltropgrenade")) copy(model, 64, "models/caltrop.mdl");
    if(equal(classname, "tf_weapon_gasgrenade")) copy(model, 64, "models/spy_grenade.mdl");
    if(equal(classname, "item_cells")) copy(model, 64, "models/w_gaussammo.mdl");
    
    return model;
}

public PrecacheItems() {
    if(g_game == g_dmc || g_game == g_tfc) {
        for(new iCategory = 0; iCategory < get_game_categories(g_game); iCategory++)
            for(new iItem = 0; iItem < get_game_category_items(g_game, iCategory); iItem++)
                PrecacheItem(get_game_category_item(g_game, iCategory, iItem));
    
        for(new iAmmo = 0; iAmmo < get_num_ammo(g_game); iAmmo++)
            PrecacheItem(get_ammo_classname(g_game, iAmmo));
    }
    if(g_game == g_tfc) {
        engfunc(EngFunc_PrecacheModel, "valve/models/w_gaussammo.mdl");
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

GetComplexModelIndex(const model[]) {
    new body, sequence;
    new index = GetGameModelIndex(g_game, model, body, sequence);
    return index | (body << 16 ) | (sequence << 24);
}

GetModelIndexFromClassname(const classname[]) {
    if(g_game == g_tfc){
        new complexIndex = GetComplexModelIndex(GetTfcModel(classname));
        if(complexIndex)
            return complexIndex;
    }

    new entity = fm_create_entity(classname);
    if(!entity)
        return 0;

    if(g_game == g_dod){
        new dod_category, dod_item;
        if(find_weapon(g_dod, classname, dod_category, dod_item) && dod_category == e_dod_snipers)
            set_pdata_int(entity, 115, get_pdata_int(entity, 115) | 1);
    }

    fm_DispatchSpawn(entity);
    new model[64];
    pev(entity, pev_model, model, 64);

    fm_remove_entity(entity);

    return GetComplexModelIndex(model);
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

GetTfcClass(player){
    new class = pev(player, pev_playerclass) - 1;
    if(class < 0)
        return -1;
    if(class >= 9)
        return -1;
    return class;
}

public AddToFullPackPost(es_handle, e, ent, host, hostflags, player, pSet[]) {
    if(IsPickupNative(ent, host))
        return FMRES_HANDLED;

    new hostOwner = GetEntityOwner(host);
    new tfcClass = hostOwner == g_tfc ? GetTfcClass(host) : -1;
    new complex = tfcClass != -1 ? g_tfc_modelindex[tfcClass][ent] : g_pickup_modelindex[hostOwner][ent];
    new model = complex & 0xFFFF;
    new body = (complex >> 16) & 0xFF;
    new sequence = (complex >> 24) & 0xFF;
    set_es(es_handle, ES_ModelIndex, model);
    set_es(es_handle, ES_Body, body);
    set_es(es_handle, ES_Sequence, sequence);
    set_es(es_handle, ES_AnimTime, 0.0);
    set_es(es_handle, ES_FrameRate, 0.0);
    set_es(es_handle, ES_RenderMode, 0);
    set_es(es_handle, ES_RenderFx, 0);
    if(complex) {
        if(complex == g_tripmine_modelindex[hostOwner]) {
            set_es(es_handle, ES_Body, body + 3);
            set_es(es_handle, ES_Sequence, sequence + 8);
        } else if(complex == g_snark_modelindex[hostOwner]) {
            set_es(es_handle, ES_Sequence, sequence + 1);
            set_es(es_handle, ES_FrameRate, 1.0);
        } else if(hostOwner == g_dmc) {
            if(complex == g_dmc_invisibility_mi) {
                set_es(es_handle, ES_RenderFx, 19);
                set_es(es_handle, ES_RenderColor, {128, 128, 128});
                set_es(es_handle, ES_RenderMode, 1);
                set_es(es_handle, ES_RenderAmt, 30);
            } else if(complex == g_dmc_super_damage_mi) {
                set_es(es_handle, ES_RenderFx, 19);
                set_es(es_handle, ES_RenderColor, {128, 128, 255});
                set_es(es_handle, ES_RenderAmt, 100);
            } else if(complex == g_dmc_invulnerability_mi) {
                set_es(es_handle, ES_RenderFx, 19);
                set_es(es_handle, ES_RenderColor, {255, 128, 0});
                set_es(es_handle, ES_RenderAmt, 100);
            }
        }
    }
    if(tfcClass != -1 && equal(g_tfc_classname[tfcClass][ent], "tf_weapon_", 10) && !equal(g_tfc_classname[tfcClass][ent][strlen(g_tfc_classname[tfcClass][ent]) - 7], "grenade", 7)) {
        new Float:origin[3];
        new Float:angles[3];
        get_es(es_handle, ES_Origin, origin);
        get_es(es_handle, ES_Angles, angles);

        origin[0] -= 16.0;
        origin[1] -= 56.0;
        origin[2] -= 5.0;
        angles[0] = 0.0;
        angles[1] = 0.0;
        angles[2] = -80.0;

        set_es(es_handle, ES_Origin, origin);
        set_es(es_handle, ES_Angles, angles);
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

fm_give_item2(index, const item[]) {
    if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
        return 0;

    new ent = fm_create_entity(item);
    if (!pev_valid(ent))
        return 0;

    if(GetEntityOwner(g_equip_player) == g_dod) {
        new dod_category, dod_item;
        if(find_weapon(g_dod, item, dod_category, dod_item) && dod_category == e_dod_snipers)
            set_pdata_int(ent, 115, get_pdata_int(ent, 115) | 1);
    }

    new Float:origin[3];
    pev(index, pev_origin, origin);
    set_pev(ent, pev_origin, origin);
    set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
    dllfunc(DLLFunc_Spawn, ent);

    if(GetEntityOwner(g_equip_player) == g_dod)
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_ONGROUND);

    new save = pev(ent, pev_solid);
    dllfunc(DLLFunc_Touch, ent, index);
    if (pev(ent, pev_solid) != save || pev(ent, pev_flags) & FL_KILLME)
        return ent;

    engfunc(EngFunc_RemoveEntity, ent);

    return -1;
}

bool:give_item2(const classname[]) {
    new playerOwner = GetEntityOwner(g_equip_player);

    new ammo[32];
    if(g_ammo_offsets[playerOwner])
        for(new i = 0; i < 32; i++)
            ammo[i] = get_pdata_int(g_equip_player, g_ammo_offsets[playerOwner] + i);
    
    new Float:oldHealth;
    pev(g_equip_player, pev_health, oldHealth);

    new item = fm_give_item2(g_equip_player, classname);
    new bool:delete = item > 0;
    
    if(g_ammo_offsets[playerOwner])
        for(new i = 0; i < 32; i++)
            if(ammo[i] != get_pdata_int(g_equip_player, g_ammo_offsets[playerOwner] + i))
                delete = true;

    new Float:newHealth;
    pev(g_equip_player, pev_health, newHealth);
    if(oldHealth != newHealth)
        delete = true;

    if(playerOwner == g_dmc && item > 0)
        fm_remove_entity(item);

    return delete;
}

bool:give_item_times(const classname[], times) {
    new given = 0;
    for(new i = 0; i < times; i++) {
        if(!give_item2(classname))
            break;

        given++;
    }
    return given > 0;
}

public Equip() {
    new playerOwner = GetEntityOwner(g_equip_player);
    new tfcClass = playerOwner == g_tfc ? GetTfcClass(g_equip_player) : -1;
    new classname[32];
    copy(classname, 32, tfcClass != -1 ? g_tfc_classname[tfcClass][g_equip_item] :  g_pickup_classname[playerOwner][g_equip_item]);
    if(!classname[0])
        return;

    g_equip_delete = false;

    if(playerOwner == g_tfc) {
        if(equal(classname, "weaponbox")) {
            const Float:factor = 0.2;

            new Float:health; new Float:maxHealth;
            pev(g_equip_player, pev_health, health);
            pev(g_equip_player, pev_max_health, maxHealth);
            if(health < maxHealth) {
                set_pev(g_equip_player, pev_health, floatmin(maxHealth, health + factor * maxHealth));
                g_equip_delete = true;
            }

            new Float:armor; new Float:maxArmor;
            pev(g_equip_player, pev_armorvalue, armor);
            maxArmor = get_pdata_float(g_equip_player, 62);
            if(armor < maxArmor) {
                set_pev(g_equip_player, pev_armortype, get_pdata_float(g_equip_player, 61));
                set_pev(g_equip_player, pev_armorvalue, floatmin(maxArmor, armor + factor * maxArmor));
                g_equip_delete = true;
            }

            new ammoOffsets[] = {53, 55, 57, 59};
            new maxAmmoOffsets[sizeof ammoOffsets] = {50, 54, 56, 58};
            for(new iAmmo = 0; iAmmo < sizeof ammoOffsets; iAmmo++) {
                new ammo = get_pdata_int(g_equip_player, ammoOffsets[iAmmo]);
                new maxAmmo = get_pdata_int(g_equip_player, maxAmmoOffsets[iAmmo]);
                if(ammo < maxAmmo) {
                    set_pdata_int(g_equip_player, ammoOffsets[iAmmo], min(maxAmmo, ammo + floatround(factor * maxAmmo)));
                    g_equip_delete = true;
                }
            }

            if(g_equip_delete)
                engfunc(EngFunc_EmitSound, g_equip_item, CHAN_ITEM, "items/ammopickup2.wav", 1.0, ATTN_NORM, 0, 100);

            return;
        }
        for(new iGrenade = 0; iGrenade < NumTfcGrenades(tfcClass); iGrenade++) {
            if(!equal(classname, get_game_category_item(g_tfc, tfcClass, iGrenade)))
                continue;
            
            new offsets[3] = {14, 15, 51};
            new offset = offsets[iGrenade];
            set_pdata_int(g_equip_player, offset, get_pdata_int(g_equip_player, offset) + 1);
            g_equip_delete = true;
            return;
        }
        //give ammo for the gun beforehand
        for(new iWeapon = 0; iWeapon < get_num_ammo(g_tfc); iWeapon++) {
            if(!equal(classname, get_ammo_weapon(g_tfc, iWeapon)))
                continue;
            
            const tfcAmmoTimes = 4;
            g_equip_delete |= give_item_times(get_ammo_classname(g_tfc, iWeapon), tfcAmmoTimes);

            //give metal to the engineer
            if(tfcClass + 1 == 9)
                g_equip_delete |= give_item_times("item_cells", tfcAmmoTimes);
                
            break;
        }
    }

    new times = 1;
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
        
        new origClassname[32];
        pev(g_equip_item, pev_classname, origClassname, 32);
        if((is_primary || is_pistol) && !equal(origClassname, "weaponbox"))
            times = 3;
    }

    g_equip_delete |= give_item_times(classname, times);
}

public DeleteWeaponbox() {
    unset_entity_pickup(g_equip_item);

    new classname[32];
    pev(g_equip_item, pev_classname, classname, 32);
    if(equal(classname, "armoury_entity")) {
        //turn armoury_entity invisible and untouchable
        set_pev(g_equip_item, pev_effects, pev(g_equip_item, pev_effects) | EF_NODRAW);
        set_pev(g_equip_item, pev_solid, SOLID_NOT);
        //respawn armoury on deathmatch maps
        /*if(g_map_owner != g_cstrike)
            set_task(IsArmouryItem(g_equip_item) ? 30.0 : 20.0, "Respawn", g_equip_item);*/
        return;
    }

    if(contain(classname, "ammo_") == 0 || contain(classname, "item_") == 0 || contain(classname, "weapon_") == 0) {
        new bool:isDmcBackpack = g_dmc != -1 && g_dmc == GetEntityOwner(g_equip_item) && equal(classname, "item_backpack");
        if(!(pev(g_equip_item, pev_spawnflags) & SF_NORESPAWN) && GetEntityOwner(g_equip_item) == g_map_owner && !isDmcBackpack) {
            set_pev(g_equip_item, pev_effects, pev(g_equip_item, pev_effects) | EF_NODRAW);
            set_pev(g_equip_item, pev_solid, SOLID_NOT);
            set_task(contain(classname, "item_") == 0 ? 30.0 : 20.0, "Respawn", g_equip_item);
            return;
        }
    }

    if(equal(classname, "weaponbox") || equal(classname, "weapon_shield") || equal(classname, "item_backpack") || equal(classname, "tf_ammobox") || equal(classname, "ammo_generic_", 13)) {
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
        fm_remove_entity(g_equip_item);
    }
}

/*IsArmouryItem(armoury) {
    new model[32];
    pev(armoury, pev_model, model, 32);
    return equal(model, "models/w_kevlar.mdl") || equal(model, "models/w_assault.mdl");
}*/

public TouchPre(touched, other) {
    new isNative = IsPickupNative(touched, other);
    new canTouch = is_user_alive(other) && !(pev(touched, pev_effects) & EF_NODRAW);
    //respawn armoury on deathmatch maps
    /*if(isNative && canTouch && g_map_owner != g_cstrike) {
        new classname[32];
        pev(touched, pev_classname, classname, 32);
        if(equal(classname, "armoury_entity")) {
            remove_task(touched);
            set_task(IsArmouryItem(touched) ? 30.0 : 20.0, "Respawn", touched);
        }
    }*/
    if(isNative || !canTouch) {
        return FMRES_IGNORED;
    }

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
    if(!equal(classname, "weaponbox") && !equal(classname, "tf_ammobox"))
        return;

    new numEntities = global_get(glb_maxEntities);
    for (new i = get_maxplayers() + 1; i < numEntities; i++) {
        if (!pev_valid(i))
            continue;

        if (pev(i, pev_owner) != entity)
            continue;
        
        pev(i, pev_classname, classname, 32);
    }

    //server_print("weaponbox: %d %s", entity, classname);

    PreparePickup(entity, classname);
}

public OnDmcBackpackCreate(entity) {
    if(!pev_valid(entity) || g_dmc == -1 || GetEntityOwner(entity) != g_dmc)
        return;

    new netname[32];
    pev(entity, pev_classname, netname, 32);
    if(!equal(netname, "item_backpack"))
        return;

    pev(entity, pev_netname, netname, 32);
    //server_print("OnDmcBackpackCreate: %d %s", entity, netname);

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

    if(GetEntityOwner(entity) != g_map_owner)
        return;

    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(contain(classname, "ammo_") != 0 && contain(classname, "item_") != 0 && contain(classname, "weapon_") != 0)
        return;
    
    LoadWeaponModelIndices();
    //server_print("OnItemMaterialize: %d %s", entity, classname);
    PreparePickup(entity, classname);
}

bool:IsAmmo(const classname[]) {
    if(equal(classname, "ammo_ARgrenades"))
        return false;

    if(contain(classname, "ammo_") == 0)
        return true;

    if(g_map_owner == g_dmc)
        for(new iAmmo = 0; iAmmo < get_num_ammo(g_dmc); iAmmo++)
            if(equal(classname, get_ammo_classname(g_dmc, iAmmo)))
                return true;
    
    if(equal(classname, "tf_ammobox"))
        return true;
    
    return false;
}

const Float:maxAmmoDistance = 128.0;

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
        if(equal(weaponClassname, classname))
            continue; //same ammo type

        if(contain(weaponClassname, "weapon_") != 0 && !IsAmmo(weaponClassname))
            continue;
        
        new Float:weaponOrigin[3];
        pev(iWeapon, pev_origin, weaponOrigin);
        new Float:distance = get_distance_f(entityOrigin, weaponOrigin);
        if(distance >= weaponDistance)
            continue;
        
        //if the closest item is ammo of a different type, force a random ammo instead
        nearestWeapon = IsAmmo(weaponClassname) ? 0 : iWeapon;

        weaponDistance = distance;
    }

    //server_print("nearestWeapon: %d %f", nearestWeapon, weaponDistance);

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        g_pickup_classname[iGame][entity] = "";
        g_pickup_modelindex[iGame][entity] = 0;
        
        if(iGame == g_tfc) {
            for(new iTfcClass = 0; iTfcClass < maxTfcClasses; iTfcClass++) {
                g_tfc_classname[iTfcClass][entity] = "";
                g_tfc_modelindex[iTfcClass][entity] = 0;
            }
        }

        new numAmmo = get_num_ammo(iGame);
        if(!numAmmo)
            continue;

        //start with random ammo index
        new ammoIndex = random(numAmmo);

        //use ammo for nearest weapon if found
        if(nearestWeapon) {
            for(new iAmmo = 0; iAmmo < numAmmo; iAmmo++) {
                if(equal(g_pickup_classname[iGame][nearestWeapon], get_ammo_weapon(iGame, iAmmo))) {
                    ammoIndex = iAmmo;
                    break;
                }
            }
        }

        //use the exactly same ammo if available
        for(new iAmmo = 0; iAmmo < numAmmo; iAmmo++) {
            if(equal(classname, get_ammo_classname(iGame, iAmmo))) {
                ammoIndex = iAmmo;
                break;
            }
        }
        
        if(iGame == g_tfc) {
            for(new iTfcClass = 0; iTfcClass < maxTfcClasses; iTfcClass++) {
                copy(g_tfc_classname[iTfcClass][entity], 32, get_ammo_classname(iGame, ammoIndex));
                g_tfc_modelindex[iTfcClass][entity] = g_ammo_modelindices[iGame][ammoIndex];
            }
        } else {
            copy(g_pickup_classname[iGame][entity], 32, get_ammo_classname(iGame, ammoIndex));
            g_pickup_modelindex[iGame][entity] = g_ammo_modelindices[iGame][ammoIndex];
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

        if(iGame == g_tfc) {
            for(new iTfcClass = 0; iTfcClass < maxTfcClasses; iTfcClass++) {
                g_tfc_classname[iTfcClass][entity] = "weaponbox";
                g_tfc_modelindex[iTfcClass][entity] = g_item_modelindices[iGame][0];
            }
            continue;
        }

        new bool:exactMatch = false;
        new numItems = get_num_items(iGame);
        if(iGame == g_dmc && g_map_owner == g_tfc)
            numItems = 4; //do not give dmc powerups in tfc

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

NumTfcGrenades(iTfcClass) {
    switch(iTfcClass) {
        case 1: return 1;
        case 3: return 3;
    }
    return 2;
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
        if(equal(model, "models/w_backpack.mdl"))
            return;
    }
    //don't eat the flag!
    if(wbOwner == g_tfc && equal(classname, "item_tfgoal"))
        return;

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
        if(iGame == g_tfc) {
            new bool:isGrenade = false;
            new oldCategory, oldItem;
            if(find_weapon(wbOwner, classname, oldCategory, oldItem) && equal(get_game_category(wbOwner, oldCategory), "grenades"))
                isGrenade = true;

            for(new iTfcClass = 0; iTfcClass < maxTfcClasses; iTfcClass++) {
                new numGrenades = NumTfcGrenades(iTfcClass);
                new tfcWeapon = isGrenade ? random(numGrenades) : (numGrenades + random(get_game_category_items(g_tfc, iTfcClass) - numGrenades));
                copy(g_tfc_classname[iTfcClass][entity], 32, get_game_category_item(g_tfc, iTfcClass, tfcWeapon));
                g_tfc_modelindex[iTfcClass][entity] = g_tfc_classname[iTfcClass][entity][0] ? g_modelindices[g_tfc][iTfcClass][tfcWeapon] : 0;
            }
            continue;
        }

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
        else if(equal(classname, "item_backpack") && g_dmc != -1 && GetEntityOwner(entity) == g_dmc) {
            set_task(0.0, "OnDmcBackpackCreate", entity);
        }
        else if(equal(classname, "ammo_", 5) || equal(classname, "item_", 5) || equal(classname, "weapon_", 7)) {
            PreparePickup(entity, classname);
        }
    }
    return FMRES_HANDLED;
}

public CreateEntityPost() {
    new entity = get_orig_retval();
    if(entity) {
        g_entity_pickups[entity] = false;
        set_task(0.0, "OnWeaponboxCreate", entity);
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

/*new g_armoury;
public RespawnArmoury() {
    set_pdata_int(g_armoury, 35, get_pdata_int(g_armoury, 36));
    new armouryIndex = get_pdata_int(entity, 34);
    PreparePickup(entity, g_cstrike_armoury_classname[armouryIndex]);
}*/

public Respawn(entity) {
    if(!pev_valid(entity) || !(pev(entity, pev_effects) & EF_NODRAW))
        return;

    if(g_map_owner == g_dmc) {
        engfunc(EngFunc_EmitSound, entity, CHAN_WEAPON, "items/itembk2.wav", 1.0, ATTN_NORM, 0, 100);
    } else {
        engfunc(EngFunc_EmitSound, entity, CHAN_WEAPON, "items/suitchargeok1.wav", 1.0, ATTN_NORM, 0, 150);
    }
    set_pev(entity, pev_effects, (pev(entity, pev_effects) & ~EF_NODRAW) | EF_MUZZLEFLASH);
    set_pev(entity, pev_solid, SOLID_TRIGGER);
    new Float:origin[3];
    pev(entity, pev_origin, origin);
    engfunc(EngFunc_SetOrigin, entity, origin);

    /*new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(equal(classname, "armoury_entity")) {
        g_armoury = entity;
        GameContext(g_cstrike, "RespawnArmoury");
    }*/

    OnItemMaterialize(entity);
}

public logevent_round_start() {
    //server_print("logevent_round_start");
    new classname[32];
    new numEntities = global_get(glb_maxEntities);
    for (new entity = get_maxplayers() + 1; entity < numEntities; entity++) {
        if (!pev_valid(entity)) {
            unset_entity_pickup(entity);
            continue;
        }

        if(GetEntityOwner(entity) != g_cstrike)
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

new g_give_shells;
new g_give_nails;
new g_give_rockets;
new g_give_cells;
new g_give_result;
public GiveTFAmmo(playerIndex, shells, nails, rockets, cells) {
    new playerOwner = GetEntityOwner(playerIndex);
    if(playerOwner == g_tfc)
        return PLUGIN_CONTINUE;

    g_equip_player = playerIndex;
    g_give_shells = shells;
    g_give_nails = nails;
    g_give_rockets = rockets;
    g_give_cells = cells;
    GameContext(playerOwner, "GiveAmmo");
    return g_give_result;
}

public GiveAmmo(){
    new bool:given;
    new playerOwner = GetEntityOwner(g_equip_player);
    if(playerOwner == g_valve || playerOwner == g_gearbox) {
        given |= give_item_times("ammo_buckshot", (g_give_shells + 6) / 12);
        given |= give_item_times("ammo_9mmclip", (g_give_nails + 9) / 17);
        given |= give_item_times("ammo_357", (g_give_nails + 3) / 6);
        given |= give_item_times("ammo_rpgclip", (g_give_rockets + 1) / 2);
        given |= give_item_times("ammo_crossbow", (g_give_rockets + 3) / 5);
        given |= give_item_times("ammo_ARgrenades", (g_give_rockets + 1) / 2);
        given |= give_item_times("ammo_gaussclip", (g_give_cells + 10) / 20);
    }
    if(playerOwner == g_gearbox) {
        given |= give_item_times("ammo_556", (g_give_shells + 25) / 50);
        given |= give_item_times("ammo_762", (g_give_shells + 3) / 5);
        given |= give_item_times("ammo_eagle", (g_give_nails + 4) / 7);
        given |= give_item_times("ammo_spore", g_give_rockets);
    }
    if(playerOwner == g_cstrike) {
        given |= give_item_times("ammo_buckshot", (g_give_shells + 4) / 8);
        given |= give_item_times("ammo_45acp", (g_give_nails + 6) / 12);
        given |= give_item_times("ammo_57mm", (g_give_nails + 25) / 50);
        given |= give_item_times("ammo_50ae", (g_give_nails + 4) / 7);
        given |= give_item_times("ammo_357sig", (g_give_nails + 7) / 13);
        given |= give_item_times("ammo_9mm", (g_give_nails + 15) / 30);
        given |= give_item_times("ammo_338magnum", (g_give_cells + 5) / 10);
        given |= give_item_times("ammo_762nato", (g_give_cells + 15) / 30);
        given |= give_item_times("ammo_556nato", (g_give_cells + 15) / 30);
        given |= give_item_times("ammo_556natobox", (g_give_cells + 15) / 30);        
    }
    if(playerOwner == g_dmc) {
        given |= give_item_times("item_shells", (g_give_shells + 10) / 20);
        given |= give_item_times("item_nails", (g_give_nails + 13) / 25);
        given |= give_item_times("item_rockets", (g_give_rockets + 3) / 5);
        given |= give_item_times("item_cells", (g_give_cells + 3) / 6);
    }
    if(playerOwner == g_dod) {
        for(new iAmmo = 0; iAmmo < get_num_ammo(g_dod); iAmmo++)
            given |= give_item_times(get_ammo_classname(g_dod, iAmmo), 1);
        for(new iItem = 0; iItem < get_num_items(g_dod); iItem++)
            given |= give_item_times(get_item(g_dod, iItem), 1);
    }

    return given ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public PreDoResults(goalIndex, apIndex, bool:addBonuses) {
    for(new iPlayer = 1; iPlayer <= 32; iPlayer++) {
        if(!pev_valid(iPlayer) || !is_user_alive(iPlayer))
            continue;

        new playerOwner = GetEntityOwner(iPlayer);
        if(playerOwner == -1 || playerOwner == g_tfc)
            continue;
        
        set_pdata_int(iPlayer, 14, 0);
        set_pdata_int(iPlayer, 15, 0);
        set_pdata_int(iPlayer, 16, 4);
        set_pdata_int(iPlayer, 17, 4);
    }
}

new g_give_grenades1;
new g_give_grenades2;
public PostDoResults(goalIndex, apIndex, bool:addBonuses) {
    for(new iPlayer = 1; iPlayer <= 32; iPlayer++) {
        if(!pev_valid(iPlayer) || !is_user_alive(iPlayer))
            continue;

        new playerOwner = GetEntityOwner(iPlayer);
        if(playerOwner == -1 || playerOwner == g_tfc)
            continue;
        
        g_give_grenades1 = get_pdata_int(iPlayer, 14, 0);
        g_give_grenades2 = get_pdata_int(iPlayer, 15, 0);
        if(g_give_grenades1 || g_give_grenades2) {
            g_equip_player = iPlayer;
            GameContext(playerOwner, "GiveGrenades");
        }
    }
}

public GiveGrenades() {
    new playerOwner = GetEntityOwner(g_equip_player);
    if(playerOwner == g_valve || playerOwner == g_gearbox) {
        give_item_times("weapon_handgrenade", g_give_grenades1);
        give_item_times("weapon_tripmine", g_give_grenades2);
        return;
    }
    if(playerOwner == g_cstrike) {
        give_item_times("weapon_hegrenade", g_give_grenades1);
        give_item_times("weapon_flashbang", g_give_grenades2);
        return;
    }
    if(playerOwner == g_dmc)
        return;
    if(playerOwner == g_dod) {
        give_item_times(pev(g_equip_player, pev_team) == 2 ? "weapon_stickgrenade" : "weapon_handgrenade", g_give_grenades1 + g_give_grenades2);
        return;
    }
}


public CurWeapon(msg_id, msg_dest, entity) {
    if(entity < 1 || entity > get_maxplayers() || GetEntityOwner(entity) != g_dod || get_msg_arg_int(1) != 1)
        return PLUGIN_CONTINUE;
    
    set_task(0.0, "SendSleeve", entity);
    return PLUGIN_CONTINUE;
}

public SendSleeve(entity) {
    if(GetEntityOwner(entity) != g_dod)
        return;
    
    new viewmodel[64];
    pev(entity, pev_viewmodel2, viewmodel, 64);

    new bool:useBritSleeve = equal(viewmodel, "models/v_bren.mdl") ||
        equal(viewmodel, "models/v_enfield.mdl") ||
        equal(viewmodel, "models/v_enfield_scoped.mdl") ||
        equal(viewmodel, "models/v_fairbairn.mdl") ||
        equal(viewmodel, "models/v_mills.mdl") ||
        equal(viewmodel, "models/v_piat.mdl") ||
        equal(viewmodel, "models/v_sten.mdl") ||
        equal(viewmodel, "models/v_webley.mdl");

    if(!useBritSleeve) {
        new usermodel[16];
        get_user_info(entity, "model", usermodel, 16);
        if(equal(usermodel, "brit-inf"))
            useBritSleeve = !(equal(viewmodel, "models/v_30cal.mdl") ||
                equal(viewmodel, "models/v_amerk.mdl") ||
                equal(viewmodel, "models/v_bar.mdl") ||
                equal(viewmodel, "models/v_bazooka.mdl") ||
                equal(viewmodel, "models/v_colt.mdl") ||
                equal(viewmodel, "models/v_fcarb.mdl") ||
                equal(viewmodel, "models/v_garand.mdl") ||
                equal(viewmodel, "models/v_greasegun.mdl") ||
                equal(viewmodel, "models/v_grenade.mdl") ||
                equal(viewmodel, "models/v_m1carbine.mdl") ||
                equal(viewmodel, "models/v_spring.mdl") ||
                equal(viewmodel, "models/v_tommy.mdl"));
    }
    
    message_begin(MSG_ONE, get_user_msgid("GameRules"), _, entity);
    write_byte(useBritSleeve ? 6 : 2);
    write_byte(2);
    message_end();
}