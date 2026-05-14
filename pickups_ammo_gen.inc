new g_valve_weapon[][32] = {"weapon_9mmhandgun", "weapon_357", "weapon_shotgun", "weapon_9mmAR", "weapon_crossbow", "weapon_rpg", "weapon_gauss", "weapon_egon"};
new g_valve_ammo[][32] = {"ammo_9mmclip", "ammo_357", "ammo_buckshot", "ammo_9mmAR", "ammo_crossbow", "ammo_rpgclip", "ammo_gaussclip", "ammo_gaussclip"};

new g_cstrike_weapon[][32] = {"weapon_usp", "weapon_fiveseven", "weapon_deagle", "weapon_p228", "weapon_glock18", "weapon_elite", "weapon_m3", "weapon_xm1014", "weapon_mac10", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_tmp", "weapon_awp", "weapon_g3sg1", "weapon_scout", "weapon_sg550", "weapon_ak47", "weapon_m249", "weapon_m4a1", "weapon_aug", "weapon_sg552", "weapon_galil", "weapon_famas"};
new g_cstrike_ammo[][32] = {"ammo_45acp", "ammo_57mm", "ammo_50ae", "ammo_357sig", "ammo_9mm", "ammo_9mm", "ammo_buckshot", "ammo_buckshot", "ammo_9mm", "ammo_45acp", "ammo_57mm", "ammo_9mm", "ammo_9mm", "ammo_338magnum", "ammo_762nato", "ammo_762nato", "ammo_556nato", "ammo_762nato", "ammo_556natobox", "ammo_556nato", "ammo_556nato", "ammo_556nato", "ammo_556nato", "ammo_556nato"};

new g_gearbox_weapon[][32] = {"weapon_9mmhandgun", "weapon_357", "weapon_shotgun", "weapon_9mmAR", "weapon_crossbow", "weapon_rpg", "weapon_gauss", "weapon_egon", "weapon_displacer", "weapon_eagle", "weapon_m249", "weapon_sniperrifle", "weapon_sporelauncher"};
new g_gearbox_ammo[][32] = {"ammo_9mmclip", "ammo_357", "ammo_buckshot", "ammo_9mmAR", "ammo_crossbow", "ammo_rpgclip", "ammo_gaussclip", "ammo_gaussclip", "ammo_gaussclip", "ammo_eagleclip", "ammo_556", "ammo_762", "ammo_spore"};

new g_dmc_weapon[][32] = {"weapon_grenadelauncher", "weapon_lightning", "weapon_nailgun", "weapon_quakegun", "weapon_rocketlauncher", "weapon_supernailgun", "weapon_supershotgun"};
new g_dmc_ammo[][32] = {"item_rockets", "item_cells", "item_spikes", "item_shells", "item_rockets", "item_spikes", "item_shells"};

new g_tfc_weapon[][32] = {"tf_weapon_shotgun", "tf_weapon_ng", "tf_weapon_sniperrifle", "tf_weapon_autorifle", "tf_weapon_supershotgun", "tf_weapon_rpg", "tf_weapon_gl", "tf_weapon_pl", "tf_weapon_superng", "tf_weapon_ac", "tf_weapon_ic", "tf_weapon_flamethrower", "tf_weapon_tranq", "tf_weapon_railgun"};
new g_tfc_ammo[][32] = {"item_shells", "item_spikes", "item_shells", "item_shells", "item_shells", "item_rockets", "item_rockets", "item_rockets", "item_spikes", "item_rockets", "item_rockets", "item_cells", "item_shells", "item_nails"};

new g_dod_weapon[][32] = {"weapon_30cal", "weapon_bar", "weapon_bazooka", "weapon_bren", "weapon_enfield", "weapon_fg42", "weapon_garand", "weapon_greasegun", "weapon_k43", "weapon_kar", "weapon_m1carbine", "weapon_mg34", "weapon_mg42", "weapon_mp40", "weapon_mp44", "weapon_piat", "weapon_pschreck", "weapon_scopedenfield", "weapon_scopedfg42", "weapon_scopedkar", "weapon_spring", "weapon_sten", "weapon_thompson"};
new g_dod_ammo[][32] = {"ammo_30cal", "ammo_bar", "ammo_bazooka", "ammo_bren", "ammo_enfield", "ammo_fg42", "ammo_garand", "ammo_greasegun", "ammo_k43", "ammo_kar", "ammo_m1carbine", "ammo_mg34", "ammo_mg42", "ammo_mp40", "ammo_mp44", "ammo_piat", "ammo_pschreck", "ammo_enfield", "ammo_fg42", "ammo_scopedkar", "ammo_spring", "ammo_sten", "ammo_thompson"};

get_num_ammo(game) {
        if (game == g_valve) return 8;
        if (game == g_cstrike) return 24;
        if (game == g_gearbox) return 13;
        if (game == g_dmc) return 7;
        if (game == g_tfc) return 14;
        if (game == g_dod) return 23;
        return 0;
}

get_ammo_weapon(game, ammo) {
        if (game == g_valve) return g_valve_weapon[ammo];
        if (game == g_cstrike) return g_cstrike_weapon[ammo];
        if (game == g_gearbox) return g_gearbox_weapon[ammo];
        if (game == g_dmc) return g_dmc_weapon[ammo];
        if (game == g_tfc) return g_tfc_weapon[ammo];
        if (game == g_dod) return g_dod_weapon[ammo];
        new emptyString[32] = "";
        return emptyString;
}

get_ammo_classname(game, ammo) {
        if (game == g_valve) return g_valve_ammo[ammo];
        if (game == g_cstrike) return g_cstrike_ammo[ammo];
        if (game == g_gearbox) return g_gearbox_ammo[ammo];
        if (game == g_dmc) return g_dmc_ammo[ammo];
        if (game == g_tfc) return g_tfc_ammo[ammo];
        if (game == g_dod) return g_dod_ammo[ammo];
        new emptyString[32] = "";
        return emptyString;
}

const MAX_AMMO = 24;
