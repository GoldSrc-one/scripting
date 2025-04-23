new g_valve_categories[][32] = {"pistols", "shotguns", "smgs", "snipers", "grenades", "launchers", "energy"}
new g_valve_pistols[][32] = {"weapon_9mmhandgun", "weapon_357"}
new g_valve_shotguns[][32] = {"weapon_shotgun"}
new g_valve_smgs[][32] = {"weapon_9mmAR"}
new g_valve_snipers[][32] = {"weapon_crossbow"}
new g_valve_grenades[][32] = {"ammo_ARgrenades", "weapon_tripmine", "weapon_satchel", "weapon_handgrenade", "weapon_snark"}
new g_valve_launchers[][32] = {"weapon_rpg", "weapon_hornetgun"}
new g_valve_energy[][32] = {"weapon_gauss", "weapon_egon"}
enum _:e_valve_categories {
        e_valve_pistols,
        e_valve_shotguns,
        e_valve_smgs,
        e_valve_snipers,
        e_valve_grenades,
        e_valve_launchers,
        e_valve_energy,
}

new g_cstrike_categories[][32] = {"pistols", "shotguns", "smgs", "snipers", "grenades", "rifles"}
new g_cstrike_pistols[][32] = {"weapon_usp", "weapon_fiveseven", "weapon_deagle", "weapon_p228", "weapon_glock18", "weapon_elite"}
new g_cstrike_shotguns[][32] = {"weapon_m3", "weapon_xm1014"}
new g_cstrike_smgs[][32] = {"weapon_mac10", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_tmp"}
new g_cstrike_snipers[][32] = {"weapon_awp", "weapon_g3sg1", "weapon_scout", "weapon_sg550"}
new g_cstrike_grenades[][32] = {"weapon_hegrenade", "weapon_flashbang", "weapon_shield"}
new g_cstrike_rifles[][32] = {"weapon_ak47", "weapon_m249", "weapon_m4a1", "weapon_aug", "weapon_sg552", "weapon_galil", "weapon_famas"}
enum _:e_cstrike_categories {
        e_cstrike_pistols,
        e_cstrike_shotguns,
        e_cstrike_smgs,
        e_cstrike_snipers,
        e_cstrike_grenades,
        e_cstrike_rifles,
}

new g_gearbox_categories[][32] = {"pistols", "shotguns", "smgs", "snipers", "grenades", "launchers", "energy"}
new g_gearbox_pistols[][32] = {"weapon_9mmhandgun", "weapon_357", "weapon_eagle"}
new g_gearbox_shotguns[][32] = {"weapon_shotgun"}
new g_gearbox_smgs[][32] = {"weapon_9mmAR", "weapon_m249"}
new g_gearbox_snipers[][32] = {"weapon_crossbow", "weapon_sniperrifle"}
new g_gearbox_grenades[][32] = {"ammo_ARgrenades", "weapon_tripmine", "weapon_satchel", "weapon_handgrenade", "weapon_snark", "weapon_penguin"}
new g_gearbox_launchers[][32] = {"weapon_rpg", "weapon_hornetgun", "weapon_sporelauncher", "weapon_shockrifle"}
new g_gearbox_energy[][32] = {"weapon_gauss", "weapon_egon", "weapon_displacer"}
enum _:e_gearbox_categories {
        e_gearbox_pistols,
        e_gearbox_shotguns,
        e_gearbox_smgs,
        e_gearbox_snipers,
        e_gearbox_grenades,
        e_gearbox_launchers,
        e_gearbox_energy,
}

new g_dmc_categories[][32] = {"shotguns", "smgs", "launchers", "energy"}
new g_dmc_shotguns[][32] = {"weapon_supershotgun"}
new g_dmc_smgs[][32] = {"weapon_nailgun", "weapon_supernailgun"}
new g_dmc_launchers[][32] = {"weapon_grenadelauncher", "weapon_rocketlauncher"}
new g_dmc_energy[][32] = {"weapon_lightning"}
enum _:e_dmc_categories {
        e_dmc_shotguns,
        e_dmc_smgs,
        e_dmc_launchers,
        e_dmc_energy,
}

const MAX_CATEGORIES = 7;

get_game_categories(game) {
        if (game == g_valve) return e_valve_categories;
        if (game == g_cstrike) return e_cstrike_categories;
        if (game == g_gearbox) return e_gearbox_categories;
        if (game == g_dmc) return e_dmc_categories;
        return 0;
}

get_game_category(game, category) {
        if (game == g_valve) return g_valve_categories[category];
        if (game == g_cstrike) return g_cstrike_categories[category];
        if (game == g_gearbox) return g_gearbox_categories[category];
        if (game == g_dmc) return g_dmc_categories[category];
        new emptyString[32] = "";
        return emptyString;
}

get_game_category_items(game, category) {
        if (game == g_valve && category == e_valve_pistols) return sizeof g_valve_pistols;
        if (game == g_valve && category == e_valve_shotguns) return sizeof g_valve_shotguns;
        if (game == g_valve && category == e_valve_smgs) return sizeof g_valve_smgs;
        if (game == g_valve && category == e_valve_snipers) return sizeof g_valve_snipers;
        if (game == g_valve && category == e_valve_grenades) return sizeof g_valve_grenades;
        if (game == g_valve && category == e_valve_launchers) return sizeof g_valve_launchers;
        if (game == g_valve && category == e_valve_energy) return sizeof g_valve_energy;
        if (game == g_cstrike && category == e_cstrike_pistols) return sizeof g_cstrike_pistols;
        if (game == g_cstrike && category == e_cstrike_shotguns) return sizeof g_cstrike_shotguns;
        if (game == g_cstrike && category == e_cstrike_smgs) return sizeof g_cstrike_smgs;
        if (game == g_cstrike && category == e_cstrike_snipers) return sizeof g_cstrike_snipers;
        if (game == g_cstrike && category == e_cstrike_grenades) return sizeof g_cstrike_grenades;
        if (game == g_cstrike && category == e_cstrike_rifles) return sizeof g_cstrike_rifles;
        if (game == g_gearbox && category == e_gearbox_pistols) return sizeof g_gearbox_pistols;
        if (game == g_gearbox && category == e_gearbox_shotguns) return sizeof g_gearbox_shotguns;
        if (game == g_gearbox && category == e_gearbox_smgs) return sizeof g_gearbox_smgs;
        if (game == g_gearbox && category == e_gearbox_snipers) return sizeof g_gearbox_snipers;
        if (game == g_gearbox && category == e_gearbox_grenades) return sizeof g_gearbox_grenades;
        if (game == g_gearbox && category == e_gearbox_launchers) return sizeof g_gearbox_launchers;
        if (game == g_gearbox && category == e_gearbox_energy) return sizeof g_gearbox_energy;
        if (game == g_dmc && category == e_dmc_shotguns) return sizeof g_dmc_shotguns;
        if (game == g_dmc && category == e_dmc_smgs) return sizeof g_dmc_smgs;
        if (game == g_dmc && category == e_dmc_launchers) return sizeof g_dmc_launchers;
        if (game == g_dmc && category == e_dmc_energy) return sizeof g_dmc_energy;
        return 0;
}

get_game_category_item(game, category, item) {
        if (game == g_valve && category == e_valve_pistols) return g_valve_pistols[item];
        if (game == g_valve && category == e_valve_shotguns) return g_valve_shotguns[item];
        if (game == g_valve && category == e_valve_smgs) return g_valve_smgs[item];
        if (game == g_valve && category == e_valve_snipers) return g_valve_snipers[item];
        if (game == g_valve && category == e_valve_grenades) return g_valve_grenades[item];
        if (game == g_valve && category == e_valve_launchers) return g_valve_launchers[item];
        if (game == g_valve && category == e_valve_energy) return g_valve_energy[item];
        if (game == g_cstrike && category == e_cstrike_pistols) return g_cstrike_pistols[item];
        if (game == g_cstrike && category == e_cstrike_shotguns) return g_cstrike_shotguns[item];
        if (game == g_cstrike && category == e_cstrike_smgs) return g_cstrike_smgs[item];
        if (game == g_cstrike && category == e_cstrike_snipers) return g_cstrike_snipers[item];
        if (game == g_cstrike && category == e_cstrike_grenades) return g_cstrike_grenades[item];
        if (game == g_cstrike && category == e_cstrike_rifles) return g_cstrike_rifles[item];
        if (game == g_gearbox && category == e_gearbox_pistols) return g_gearbox_pistols[item];
        if (game == g_gearbox && category == e_gearbox_shotguns) return g_gearbox_shotguns[item];
        if (game == g_gearbox && category == e_gearbox_smgs) return g_gearbox_smgs[item];
        if (game == g_gearbox && category == e_gearbox_snipers) return g_gearbox_snipers[item];
        if (game == g_gearbox && category == e_gearbox_grenades) return g_gearbox_grenades[item];
        if (game == g_gearbox && category == e_gearbox_launchers) return g_gearbox_launchers[item];
        if (game == g_gearbox && category == e_gearbox_energy) return g_gearbox_energy[item];
        if (game == g_dmc && category == e_dmc_shotguns) return g_dmc_shotguns[item];
        if (game == g_dmc && category == e_dmc_smgs) return g_dmc_smgs[item];
        if (game == g_dmc && category == e_dmc_launchers) return g_dmc_launchers[item];
        if (game == g_dmc && category == e_dmc_energy) return g_dmc_energy[item];
        new emptyString[32] = "";
        return emptyString;
}
