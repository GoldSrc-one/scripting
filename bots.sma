#include <amxmodx>
#include <fakemeta>

#include "crossplay"

new g_bots_max;
new g_bots_melee;
new g_bot_difficulty;
new g_valve = -1;
new g_gearbox = -1;
new g_cstrike = -1;
new g_difficulties[][] = {"Easy", "Normal", "Hard", "Expert"}
new Float:g_factors[MAX_GAMES];

const g_bots_think_task = 1;
const g_vote_menu_task = 100;
const g_vote_action_task = 200;

public plugin_init() {
    register_plugin("Bots", "0.0", "GoldSrc.one");
    register_clcmd("say bots", "bots_menu");
    register_clcmd("say /bots", "bots_menu");
    register_clcmd("say !bots", "bots_menu");
    register_forward(FM_CreateFakeClient, "CreateFakeClientPre", 0);
    g_bots_max = register_cvar("bots_max", "8");
    g_bots_melee = register_cvar("bots_melee", "0");
    g_bot_difficulty = get_cvar_pointer("bot_difficulty");    
    
    set_task(1.0, "bots_think", g_bots_think_task, _, _, "b");
    register_clcmd("say", "bots_advertise");

    g_valve = GetGameIndex("valve");
    if(g_valve != -1)
        g_factors[g_valve] = 0.35 + random_float(-0.01, 0.01);

    g_cstrike = GetGameIndex("cstrike");
    if(g_cstrike != -1)
        g_factors[g_cstrike] = 0.20 + random_float(-0.01, 0.01);

    g_gearbox = GetGameIndex("gearbox");
    if(g_gearbox != -1)
        g_factors[g_gearbox] = 0.45 + random_float(-0.01, 0.01);
}

public CreateFakeClientPre(netname[]) {
    new botname[64];
    format(botname, 64, "[BOT] %s", netname);
    new client = engfunc(EngFunc_CreateFakeClient, botname);
    forward_return(FMV_CELL, client);
    return FMRES_SUPERCEDE;
}

stock bool:FALSE = false;
#define ANNOUNCE(%0,%1,%2) \
do { \
    new player_name[64];\
    get_user_name(%0, player_name, 64);\
    log_message(%1, player_name, %2);\
    client_print(0, print_chat, %1, player_name, %2);\
} while(FALSE)

new g_voting = false;
new g_voters = 0;
new g_voteYes = 0;
new g_voteNo = 0;
new g_voteMenu = 0;
new g_voteAction[32];
new g_votePlayerId = 0;
new g_voteValue = 0;

const maxBans = 32;
new g_voteBanIDs[maxBans];
new Float:g_voteBanTimes[maxBans];

public vote_menu(player_id, menuTitle[], action[32]) {
    if(g_voting) {
        client_print(player_id, print_chat, "Cannot vote right now!");
        return;
    }

    new userid =  get_user_userid(player_id);
    new Float:time = get_gametime();
    for(new i = 0; i < maxBans; i++) {
        if(g_voteBanTimes[i] < time)
            break;

        if(g_voteBanIDs[i] == userid) {
            client_print(player_id, print_chat, "You cannot vote in next %.0f seconds!", g_voteBanTimes[i] - time);
            return;
        }
    }

    new menu = menu_create(menuTitle, "vote_menu_handler");
    menu_additem(menu, "Yes do it!");
    menu_additem(menu, "No don't do it!");

    g_voting = true;
    g_voters = 0;
    g_voteNo = 0;
    g_voteYes = 0;
    g_voteMenu = menu;
    g_voteAction = action;
    g_votePlayerId = player_id;

    for(new i = 1; i <= get_maxplayers(); i++) {
        if(!is_user_connected(i) || is_user_bot(i))
            continue;
        
        if(i != player_id) {
            menu_display(i, menu);
            set_task(10.0, "vote_menu_cancel", g_vote_menu_task + i);
        }        
        
        g_voters++;
    }

    if(g_voters > 1) {
        client_print(player_id, print_chat, "You have started a vote.");
    }

    vote_menu_handler(player_id, menu, 0);
}

public vote_menu_handler(player_id, menu, item) {
    remove_task(g_vote_menu_task + player_id);

    if(item == 0) {
        g_voteYes++;
    }
    if(item == 1) {
        g_voteNo++;
    }
    g_voters--;

    if(g_voters != 0)
        return PLUGIN_HANDLED;
        
    g_voting = false;
    menu_destroy(menu);

    if(g_voteYes <= g_voteNo) {
        client_print(g_votePlayerId, print_chat, "The vote failed, you will not be able to vote again for the next 5 minutes.");
        for(new i = 1; i < maxBans; i++) {
            g_voteBanIDs[i] = g_voteBanIDs[i - 1];
            g_voteBanTimes[i] = g_voteBanTimes[i - 1];
        }
        g_voteBanIDs[0] = get_user_userid(g_votePlayerId);
        g_voteBanTimes[0] = get_gametime() + 300.0;
        return PLUGIN_HANDLED;
    }

    set_task(0.0, g_voteAction, g_vote_action_task);
    return PLUGIN_HANDLED;
}

public vote_menu_cancel(task_id) {
    show_menu(task_id - g_vote_menu_task, 0, "^n", 1 );
    vote_menu_handler(task_id - g_vote_menu_task, g_voteMenu, MENU_EXIT);
}

public bots_menu(player_id) {
    new menu = menu_create("Bots menu", "bots_menu_handler");
    menu_additem(menu, "Kill all bots");
    new changeBotCount[64];
    format(changeBotCount, 64, "Change max bot count (now: %d)", get_pcvar_num(g_bots_max));
    menu_additem(menu, changeBotCount);
    new changeBotDifficulty[64];
    format(changeBotDifficulty, 64, "Change bot difficulty (now: %s)", g_difficulties[get_pcvar_num(g_bot_difficulty)]);
    menu_additem(menu, changeBotDifficulty);
    new melee[64];
    format(melee, 64, "Crowbars vs knives (now: %s)", get_pcvar_num(g_bots_melee) ? "On" : "Off");
    menu_additem(menu, melee);
    menu_display(player_id, menu);    
    return PLUGIN_HANDLED;
}

public bots_menu_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item == 0) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "%s wants to kill all the bots.", playerName);
        vote_menu(player_id, menuTitle, "kill_all_bots");
    }
    if(item == 1) {
        new changeBotCount[64];
        format(changeBotCount, 64, "Change max bot count (%d)", get_pcvar_num(g_bots_max));
        menu = menu_create(changeBotCount, "bot_count_handler");
        for(new i = 0; i <= (get_maxplayers()/4)*3; i += 4) {
            new botCount[4];
            format(botCount, 4, "%d", i);
            menu_additem(menu, botCount);
        }
        menu_display(player_id, menu);
    }
    if(item == 2) {
        new changeBotDifficulty[64];
        format(changeBotDifficulty, 64, "Change bot difficulty (%s)", g_difficulties[get_pcvar_num(g_bot_difficulty)]);
        menu = menu_create(changeBotDifficulty, "bot_difficulty_handler");
        for(new i = 0; i < 4; i++) {
            menu_additem(menu, g_difficulties[i]);
        }
        menu_display(player_id, menu);
    }
    if(item == 3) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "%s wants to %s ^"crowbars vs knives^".", playerName, get_pcvar_num(g_bots_melee) ? "disable" : "enable");
        vote_menu(player_id, menuTitle, "toggle_melee");
    }
    return PLUGIN_HANDLED;
}

/*new g_bot_id;
public kill_bot(){
    new hurt = create_entity("game_player_hurt");
    entity_set_float(hurt, EV_FL_dmg, 9000.1);
    force_use(g_bot_id, hurt);
    remove_entity(hurt);
}*/

public kill_all_bots() {
    ANNOUNCE(g_votePlayerId, "%s has killed all the bots", 0);
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id) || !is_user_alive(player_id))
            continue;

        user_kill(player_id, 1);
        /*g_bot_id = player_id;
        GameContext(GetEntityOwner(player_id), "kill_bot");*/
    }
}

public bot_count_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        new newCount = item * 4;

        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "%s wants to change the max bot count to %d (now %d).", playerName, newCount, get_pcvar_num(g_bots_max));
        g_voteValue = newCount;
        vote_menu(player_id, menuTitle, "change_bots_max");

    }
    return PLUGIN_HANDLED;
}

public bot_difficulty_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "%s wants to change the bot difficulty to %s (now %s).", playerName, g_difficulties[item], g_difficulties[get_pcvar_num(g_bot_difficulty)]);
        g_voteValue = item;
        vote_menu(player_id, menuTitle, "change_bot_difficulty");

    }
    return PLUGIN_HANDLED;
}

public change_bots_max() {
    ANNOUNCE(g_votePlayerId, "%s has changed the max bot count to %d", g_voteValue);
    set_pcvar_num(g_bots_max, g_voteValue);
}

public change_bot_difficulty() {
    ANNOUNCE(g_votePlayerId, "%s has changed the bot difficulty to %s, the bots will now reconnect", g_difficulties[g_voteValue]);
    set_pcvar_num(g_bot_difficulty, g_voteValue);
}

public toggle_melee() {
    new newMelee = 1 - get_pcvar_num(g_bots_melee);
    ANNOUNCE(g_votePlayerId, "%s has %s ^"crowbars vs knives^"", newMelee ? "enabled" : "disabled");
    set_pcvar_num(g_bots_melee, newMelee);
}

pick_a_game(game_counts[], sign) {
    new minGame = -1;
    new Float:minCount;
    for(new i = 0; i < MAX_GAMES; i++) {
        if(!g_factors[i])
            continue;

        new Float:gameCount = (sign * game_counts[i]) / g_factors[i];
        
        if(gameCount < minCount || minGame == -1) {
            minGame = i;
            minCount = gameCount;
        }
    }

    return minGame;
}

new g_last_difficulty = -1;
new g_evict = false;
new g_last_melee = -1;

all_jk_botti_cmd(cmd[]) {
    if(g_valve != -1)
        jk_botti_cmd(g_valve, cmd);

    if(g_gearbox != -1)
        jk_botti_cmd(g_gearbox, cmd);
}

jk_botti_cmd(iGameDll, cmd[]) {
    server_cmd("jk_botti#%d %s", iGameDll, cmd);
}

public bots_think() {
    new jk_buffer[256];

    new difficulty = get_pcvar_num(g_bot_difficulty);
    if(difficulty != g_last_difficulty) {
        format(jk_buffer, 256, "botskill %d", 4 - difficulty);
        all_jk_botti_cmd(jk_buffer);
        g_last_difficulty = difficulty;
        g_evict = true;
    }
    new melee = get_pcvar_num(g_bots_melee);
    if(melee != g_last_melee) {
        if(melee) {
            server_cmd("bot_knives_only");
            new weapons[][] = {"weapon_handgrenade", "weapon_snark", "weapon_egon", "weapon_gauss", "weapon_shotgun", "weapon_357", "weapon_hornetgun", "weapon_9mmAR", "weapon_crossbow", "weapon_rpg", "weapon_9mmhandgun",
                "weapon_eagle", "weapon_m249", "weapon_displacer", "weapon_shockrifle", "weapon_sporelauncher", "weapon_sniperrifle"};
            
            for(new i = 0; i < sizeof weapons; i++) {
                format(jk_buffer, 256, "botweapon %s avoid_this_gun 1", weapons[i]);
                all_jk_botti_cmd(jk_buffer);
            }
            for(new i = 1; i <= 5; i++) {
                format(jk_buffer, 256, "bot_skill_setup %d keep_optimal_dist 100", i);
                all_jk_botti_cmd(jk_buffer);
                format(jk_buffer, 256, "bot_skill_setup %d battle_strafe 0", i);
                all_jk_botti_cmd(jk_buffer);
            }
        } else {
            server_cmd("bot_all_weapons");
            all_jk_botti_cmd("botweapon reset");
            all_jk_botti_cmd("bot_skill_setup reset");
        }
        g_last_melee = melee;
    }

    new total_players;
    new total_bots;
    new game_counts[MAX_GAMES];
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id))
            continue;

        if(is_user_bot(player_id)) {
            total_bots++;
        } else {
            total_players++;
        }
        
        game_counts[GetEntityOwner(player_id)]++;
    }

    new max_bots = get_pcvar_num(g_bots_max);

    new want_bots = max_bots - total_players;
    if(want_bots < 0) {
        want_bots = 0;
    }

    if(total_bots == 0)
        g_evict = false;

    //add
    if(want_bots > total_bots && !g_evict) {
        new game = pick_a_game(game_counts, 1);
        if(game != -1) {
            new gameName[16];
            GetGameName(game, gameName, 16);
            server_print("Adding a %s bot... (%d < %d)", gameName, total_bots, want_bots);

            if(game == g_cstrike) {
                server_cmd("bot_add");
            } else {
                jk_botti_cmd(game, "addbot UNASSIGNED");
            }
        }
    }

    //kick
    if(want_bots < total_bots || g_evict) {
        new game = pick_a_game(game_counts, -1);
        if(game != -1) {
            new gameName[16];
            GetGameName(game, gameName, 16);
            if(g_evict)
                server_print("Kicking a %s bot... (evict)", gameName);
            else
                server_print("Kicking a %s bot... (%d > %d)", gameName, total_bots, want_bots);

            new bot_id;
            new bot_game;

            for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
                if(!is_user_connected(player_id) || !is_user_bot(player_id))
                    continue;

                bot_id = player_id;
                bot_game = GetEntityOwner(player_id);
                if(bot_game == game)
                    break;
            }

            if(bot_game == g_cstrike) {
                new name[16];
                get_user_name(bot_id, name, 16);
                server_cmd("bot_kick ^"%s^"", name);
            } else {
                new userid = get_user_userid(bot_id);
                server_cmd("kick #%d", userid);
            }
        }
    }
}

const Float:advert_interval = 300.0;
new Float:g_last_advert = -advert_interval;

public bots_advertise(player_id) {
    if(g_last_advert + advert_interval > get_gametime())
        return PLUGIN_CONTINUE;

    new saytext[256];
    read_args(saytext, 255);
    if(strfind(saytext, "bot", 1) == -1)
        return PLUGIN_CONTINUE;

    g_last_advert = get_gametime();
    client_print(0, print_chat, "If you wish to change the bot count or difficulty, say /bots to open the bots menu.");
    return PLUGIN_CONTINUE;
}