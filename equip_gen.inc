new g_valve_pistols[][32] = {"weapon_9mmhandgun", "weapon_357"}
new g_valve_primaries[][32] = {"weapon_shotgun", "weapon_9mmAR", "weapon_crossbow"}
new g_valve_specials[][32] = {"weapon_gauss", "weapon_rpg", "weapon_egon", "weapon_hornetgun"}
new g_valve_grenades[][32] = {"ammo_ARgrenades", "weapon_tripmine", "weapon_satchel", "weapon_handgrenade", "weapon_snark"}
enum _:e_valve_categories {
        e_valve_pistols,
        e_valve_primaries,
        e_valve_specials,
        e_valve_grenades,
}

new g_cstrike_t_pistols[][32] = {"weapon_usp", "weapon_deagle", "weapon_p228", "weapon_glock18", "weapon_elite"}
new g_cstrike_ct_pistols[][32] = {"weapon_usp", "weapon_fiveseven", "weapon_deagle", "weapon_p228", "weapon_glock18"}
new g_cstrike_t_primaries[][32] = {"weapon_awp", "weapon_g3sg1", "weapon_ak47", "weapon_scout", "weapon_m249", "weapon_sg552", "weapon_m3", "weapon_xm1014", "weapon_mac10", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_galil"}
new g_cstrike_ct_primaries[][32] = {"weapon_awp", "weapon_scout", "weapon_m249", "weapon_m4a1", "weapon_aug", "weapon_sg550", "weapon_m3", "weapon_xm1014", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_tmp", "weapon_famas", "weapon_shield"}
enum _:e_cstrike_categories {
        e_cstrike_t_pistols,
        e_cstrike_ct_pistols,
        e_cstrike_t_primaries,
        e_cstrike_ct_primaries,
}

new g_gearbox_melees[][32] = {"weapon_pipewrench", "weapon_knife", "weapon_grapple"}
new g_gearbox_primaries[][32] = {"weapon_m249", "weapon_displacer", "weapon_sniperrifle"}
new g_gearbox_specials[][32] = {"weapon_sporelauncher", "weapon_shockrifle"}
new g_gearbox_powerups[][32] = {"item_ctfaccelerator", "item_ctfbackpack", "item_ctfregeneration"}
enum _:e_gearbox_categories {
        e_gearbox_melees,
        e_gearbox_primaries,
        e_gearbox_specials,
        e_gearbox_powerups,
}

const MAX_CATEGORIES = 4;

get_game_categories(game) {
        if (game == g_valve) return e_valve_categories;
        if (game == g_cstrike) return e_cstrike_categories;
        if (game == g_gearbox) return e_gearbox_categories;
        return 0;
}

get_game_category_items(game, category) {
        if (game == g_valve && category == e_valve_pistols) return sizeof g_valve_pistols;
        if (game == g_valve && category == e_valve_primaries) return sizeof g_valve_primaries;
        if (game == g_valve && category == e_valve_specials) return sizeof g_valve_specials;
        if (game == g_valve && category == e_valve_grenades) return sizeof g_valve_grenades;
        if (game == g_cstrike && category == e_cstrike_t_pistols) return sizeof g_cstrike_t_pistols;
        if (game == g_cstrike && category == e_cstrike_ct_pistols) return sizeof g_cstrike_ct_pistols;
        if (game == g_cstrike && category == e_cstrike_t_primaries) return sizeof g_cstrike_t_primaries;
        if (game == g_cstrike && category == e_cstrike_ct_primaries) return sizeof g_cstrike_ct_primaries;
        if (game == g_gearbox && category == e_gearbox_melees) return sizeof g_gearbox_melees;
        if (game == g_gearbox && category == e_gearbox_primaries) return sizeof g_gearbox_primaries;
        if (game == g_gearbox && category == e_gearbox_specials) return sizeof g_gearbox_specials;
        if (game == g_gearbox && category == e_gearbox_powerups) return sizeof g_gearbox_powerups;
        return 0;
}

get_game_category_item(game, category, item) {
        if (game == g_valve && category == e_valve_pistols) return g_valve_pistols[item];
        if (game == g_valve && category == e_valve_primaries) return g_valve_primaries[item];
        if (game == g_valve && category == e_valve_specials) return g_valve_specials[item];
        if (game == g_valve && category == e_valve_grenades) return g_valve_grenades[item];
        if (game == g_cstrike && category == e_cstrike_t_pistols) return g_cstrike_t_pistols[item];
        if (game == g_cstrike && category == e_cstrike_ct_pistols) return g_cstrike_ct_pistols[item];
        if (game == g_cstrike && category == e_cstrike_t_primaries) return g_cstrike_t_primaries[item];
        if (game == g_cstrike && category == e_cstrike_ct_primaries) return g_cstrike_ct_primaries[item];
        if (game == g_gearbox && category == e_gearbox_melees) return g_gearbox_melees[item];
        if (game == g_gearbox && category == e_gearbox_primaries) return g_gearbox_primaries[item];
        if (game == g_gearbox && category == e_gearbox_specials) return g_gearbox_specials[item];
        if (game == g_gearbox && category == e_gearbox_powerups) return g_gearbox_powerups[item];
        new emptyString[32] = "";
        return emptyString;
}
