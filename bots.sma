#include <amxmodx>
#include <fakemeta>

#include "crossplay"

new g_bots_max;
new g_bot_difficulty;
new g_valve = -1;
new g_gearbox = -1;
new g_dmc = -1;
new g_cstrike = -1;
new g_tfc = -1;
new g_dod = -1;
new g_difficulties[][] = {"Easy", "Normal", "Hard", "Expert"}
new Float:g_ratios[MAX_GAMES];
new g_teams[MAX_GAMES];
new bool:g_nogoal = false;
new bool:g_deathmatch = true;

const g_bots_think_task = 1;
const g_vote_menu_task = 100;
const g_vote_action_task = 200;
const g_notarget_think_task = 1;

new g_teamNames[3][8] = {"ANY", "BLUE", "RED"};

public plugin_precache() {
    register_plugin("Bots", __DATE__, "GoldSrc.one");

    g_bots_max = register_cvar("bots_max", "8");
    g_bot_difficulty = get_cvar_pointer("bot_difficulty");
    if(!g_bot_difficulty)
        g_bot_difficulty = register_cvar("bot_difficulty", "Normal");
}

public plugin_init() {
    register_clcmd("say bots", "bots_menu");
    register_clcmd("say /bots", "bots_menu");
    register_clcmd("say !bots", "bots_menu");
    register_clcmd("bots_ratio", "bots_ratio");
    register_forward(FM_CreateFakeClient, "CreateFakeClientPre", 0);
    register_forward(FM_SetClientKeyValue, "SetClientKeyValuePre", 0);
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_SetModel, "SetModelPost", 1);
    
    set_task(1.0, "bots_think", g_bots_think_task, _, _, "b");
    register_clcmd("say", "bots_advertise");

    g_valve = GetGameIndex("valve");
    if(g_valve != -1)
        g_ratios[g_valve] = random_float(10.0, 20.0);

    g_cstrike = GetGameIndex("cstrike");
    if(g_cstrike != -1)
        g_ratios[g_cstrike] = random_float(35.0, 45.0);

    g_gearbox = GetGameIndex("gearbox");
    if(g_gearbox != -1)
        g_ratios[g_gearbox] = random_float(10.0, 20.0);
        
    g_dmc = GetGameIndex("dmc");
    if(g_dmc != -1)
        g_ratios[g_dmc] = random_float(5.0, 15.0);

    g_tfc = GetGameIndex("tfc");
    if(g_tfc != -1)
        g_ratios[g_tfc] = random_float(30.0, 40.0);

    g_dod = GetGameIndex("dod");
    if(g_dod != -1)
        g_ratios[g_dod] = random_float(30.0, 40.0);

    new Float:ratioSum = 0.0;
    for(new iGame = 0; iGame < MAX_GAMES; iGame++)
        ratioSum += (g_ratios[iGame]) / 100.0;
    for(new iGame = 0; iGame < MAX_GAMES; iGame++)
        g_ratios[iGame] /= ratioSum;

    set_task(0.1, "notarget_think", g_notarget_think_task, _, _, "b");

    g_deathmatch = IsMapDeathmatch();

    if(GetEntityOwner(0) == g_cstrike) {
        g_teamNames[1] = "CT";
        g_teamNames[2] = "T";
    }
    if(GetEntityOwner(0) == g_dod) {
        g_teamNames[1] = "Allies";
        g_teamNames[2] = "Axis";
    }
}

public CreateFakeClientPre(const netname[]) {
    if(equal(netname, "[BOT] ", 6))
        return FMRES_IGNORED;

    new botname[64];
    format(botname, 64, "[BOT] %s", netname);
    new client = engfunc(EngFunc_CreateFakeClient, botname);
    forward_return(FMV_CELL, client);
    return FMRES_SUPERCEDE;
}

public SetClientKeyValue(clientIndex, const infobuffer[], const key[], const value[]) {
    if(!(pev(clientIndex, pev_flags) & FL_FAKECLIENT) || !equal(key, "name") || equal(value, "[BOT] ", 6))
        return FMRES_IGNORED;
    
    new botname[64];
    format(botname, 64, "[BOT] %s", value);
    engfunc(EngFunc_SetClientKeyValue, infobuffer, key, botname);
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
        if(!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i))
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

bool:getGameAbbr(iGame, gameAbbr[16]) {
    GetGameName(iGame, gameAbbr, 16);
    return GetGameAbbr(gameAbbr, gameAbbr, 16);
}

getRatiosString(const Float:ratios[]) {
    new ratiosString[64];
    new pos = 0;

    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr))
            pos += format(ratiosString[pos], 64, "%s:%.0f%% ", gameAbbr, ratios[iGame]);
    }

    return ratiosString;
}

getTeamsString(const teams[]) {
    new teamsString[64];
    new pos = 0;

    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr))
            pos += format(teamsString[pos], 64, "%s:%s ", gameAbbr, g_teamNames[teams[iGame]]);
    }

    return teamsString;
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
    new changeBotRatios[64];
    format(changeBotRatios, 64, "Change bot ratios (now: %s)", getRatiosString(g_ratios));
    menu_additem(menu, changeBotRatios);
    new changeBotTeams[64];
    format(changeBotTeams, 64, "Change bot teams (now: %s)", getTeamsString(g_teams));
    menu_additem(menu, changeBotTeams);
    new changeBotNoGoal[64];
    format(changeBotNoGoal, 64, "%s bots picking up bombs and flags", g_nogoal ? "Allow" : "Prevent");
    menu_additem(menu, changeBotNoGoal);
    menu_display(player_id, menu);    
    return PLUGIN_HANDLED;
}

new Float:g_player_ratios[33][MAX_GAMES];
new g_player_teams[33][MAX_GAMES];
public bots_menu_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item == 0) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256];
        format(menuTitle, 256, "Kill all the bots? %s has started the vote.", playerName);
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
        for(new iGame = 0; iGame < MAX_GAMES; iGame++)
            g_player_ratios[player_id][iGame] = g_ratios[iGame];

        ratios_menu(player_id);
    }
    if(item == 4) {
        if(g_deathmatch) {
            bots_menu(player_id);
            return PLUGIN_HANDLED;
        }

        for(new iGame = 0; iGame < MAX_GAMES; iGame++)
            g_player_teams[player_id][iGame] = g_teams[iGame];

        teams_menu(player_id);
    }
    if(item == 5) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256];
        format(menuTitle, 256, "%s bots picking up bombs and flags? %s has started the vote.", g_nogoal ? "Allow" : "Prevent", playerName);
        vote_menu(player_id, menuTitle, "toggle_nogoal");
    }
    return PLUGIN_HANDLED;
}

public kill_all_bots() {
    ANNOUNCE(g_votePlayerId, "%s has killed all the bots", 0);
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id) || !is_user_alive(player_id))
            continue;

        user_kill(player_id, 1);
    }
}

public bot_count_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        new newCount = item * 4;

        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "Set the max bot count to %d (now %d)? %s has started the vote.", newCount, get_pcvar_num(g_bots_max), playerName);
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
        format(menuTitle, 256, "Set the bot difficulty to %s (now %s)? %s has started the vote.", g_difficulties[item], g_difficulties[get_pcvar_num(g_bot_difficulty)], playerName);
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

ratios_menu(player_id) {
    new menu = menu_create("Change bot ratios", "bot_ratio_handler");
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr)) {
            new gameRatio[32];
            format(gameRatio, 32, "%s (%.0f %%)", gameAbbr, g_player_ratios[player_id][iGame]);
            menu_additem(menu, gameRatio);
        }
    }
    menu_additem(menu, "Save");
    menu_display(player_id, menu);
}

new g_ratio_game[33];
public bot_ratio_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item < 0)
        return PLUGIN_HANDLED;
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(!getGameAbbr(iGame, gameAbbr))
            continue;

        item--;
        if(item < 0) {
            g_ratio_game[player_id] = iGame;
            client_cmd(player_id, "messagemode bots_ratio");
            return PLUGIN_HANDLED;
        }
    }

    new playerName[64];
    get_user_name(player_id, playerName, 64);
    new menuTitle[256]
    format(menuTitle, 256, "Change the bot ratios to: %s (now: %s)? %s has started the vote.", getRatiosString(g_player_ratios[player_id]), getRatiosString(g_ratios), playerName);
    vote_menu(player_id, menuTitle, "change_bot_ratios");
    return PLUGIN_HANDLED;
}

public bots_ratio(player_id) {
    if(read_argc() > 1 && g_ratio_game[player_id] != -1) {
        new ratioText[16];
        read_argv(1, ratioText, 16);
        new Float:newRatio = floatclamp(str_to_float(ratioText), 0.0, 100.0);
        
        new Float:sumOthers = 0.0;
        for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
            if(iGame != g_ratio_game[player_id])
                sumOthers += g_player_ratios[player_id][iGame] / 100.0;
        }
        
        if(sumOthers == 0.0) {
            newRatio = 100.0;
        } else {
            new Float:factor = (1.0 - (newRatio / 100.0)) / sumOthers;
            for(new iGame = 0; iGame < MAX_GAMES; iGame++)
                g_player_ratios[player_id][iGame] *= factor;
        }
        g_player_ratios[player_id][g_ratio_game[player_id]] = newRatio;
        ratios_menu(player_id);
    }
    g_ratio_game[player_id] = -1;
}

public change_bot_ratios() {
    for(new iGame = 0; iGame < MAX_GAMES; iGame++)
        g_ratios[iGame] = g_player_ratios[g_votePlayerId][iGame];

    ANNOUNCE(g_votePlayerId, "%s has changed the bot ratios to: %s", getRatiosString(g_ratios));    
}

teams_menu(player_id) {
    new menu = menu_create("Change bot teams", "bot_teams_handler");
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr)) {
            new gameRatio[32];
            format(gameRatio, 32, "%s (%s)", gameAbbr, g_teamNames[g_player_teams[player_id][iGame]]);
            menu_additem(menu, gameRatio);
        }
    }
    menu_additem(menu, "Save");
    menu_display(player_id, menu);
}

public bot_teams_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item < 0)
        return PLUGIN_HANDLED;
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(!getGameAbbr(iGame, gameAbbr))
            continue;

        item--;
        if(item < 0) {
            g_player_teams[player_id][iGame] = (g_player_teams[player_id][iGame] + 1) % sizeof(g_teamNames);
            teams_menu(player_id);
            return PLUGIN_HANDLED;
        }
    }

    new playerName[64];
    get_user_name(player_id, playerName, 64);
    new menuTitle[256]
    format(menuTitle, 256, "Change the bot teams to: %s (now: %s)? %s has started the vote.", getTeamsString(g_player_teams[player_id]), getTeamsString(g_teams), playerName);
    vote_menu(player_id, menuTitle, "change_bot_teams");
    return PLUGIN_HANDLED;
}

public change_bot_teams() {
    for(new iGame = 0; iGame < MAX_GAMES; iGame++)
        g_teams[iGame] = g_player_teams[g_votePlayerId][iGame];

    ANNOUNCE(g_votePlayerId, "%s has changed the bot teams to: %s", getTeamsString(g_teams));
}

public toggle_nogoal() {
    ANNOUNCE(g_votePlayerId, "%s has %s bots picking up bombs and flags.", g_nogoal ? "allowed" : "prevented");
    g_nogoal = !g_nogoal;
}

pick_a_game(game_counts[], sign) {
    new minGame = -1;
    new Float:minCount;
    for(new i = 0; i < MAX_GAMES; i++) {
        if(!g_ratios[i])
            continue;

        new Float:gameCount = (sign * game_counts[i]) / (g_ratios[i] / 100.0);
        
        if(gameCount < minCount || minGame == -1) {
            minGame = i;
            minCount = gameCount;
        }
    }

    return minGame;
}

new g_last_difficulty = -1;
new bool:g_evict = false;

kick_bot(bot_id, bot_game, const reason[]) {
    server_print("Kicking a bot... (%s)", reason);

    if(bot_game == g_cstrike) {
        new name[16];
        get_user_name(bot_id, name, 16);
        server_cmd("bot_kick ^"%s^"", name);
    } else {
        new userid = get_user_userid(bot_id);
        server_cmd("kick #%d", userid);
    }
}

set_parabot_difficulty(difficulty) {
    new min = difficulty * 3;
    new max = (difficulty + 1) * 3;
    if(min <= 0)
        min = 1;
    if(max > 10)
        max = 10;
    
    set_cvar_num("bot_minaimskill", min);
    set_cvar_num("bot_maxaimskill", max);
}

public bots_think() {
    new difficulty = get_pcvar_num(g_bot_difficulty);
    if(difficulty != g_last_difficulty) {
        set_parabot_difficulty(difficulty);

        server_cmd("bot ^"botskill_lower %d^"", 5 - difficulty);
        server_cmd("bot ^"botskill_upper %d^"", 4 - difficulty);

        server_cmd("m_bot set_botskill %d", 4 - difficulty);
        server_cmd("m_bot set_aimskill %d", 4 - difficulty);

        g_last_difficulty = difficulty;
        g_evict = true;
    }

    new total_players;
    new total_bots;
    new game_counts[MAX_GAMES];
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || is_user_hltv(player_id))
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
        new addGame = pick_a_game(game_counts, 1);
        if(addGame != -1) {
            new gameName[16];
            GetGameName(addGame, gameName, 16);
            server_print("Adding a %s %s bot... (%d < %d)", gameName, g_teamNames[g_teams[addGame]], total_bots, want_bots);

            if(addGame == g_cstrike) {
                new csTeamAdd[][] = {"bot_add", "bot_add_ct", "bot_add_t"};
                server_cmd(csTeamAdd[g_teams[addGame]]);
            }
            if(addGame == g_valve || addGame == g_gearbox || addGame == g_dmc) {
                server_cmd("add_bot#%d", addGame);
            }
            if(addGame == g_tfc) {
                server_cmd("bot ^"addbot %d^"", g_teams[addGame]);
            }
            if(addGame == g_dod) {
                server_cmd("m_bot addmarine %d", g_teams[addGame]);
            }
        }
    }

    //kick
    new bool:kickAnyone = want_bots < total_bots || g_evict;
    new bool:kicked = false;
    if(kickAnyone) {
        new kickGame = pick_a_game(game_counts, -1);
        if(kickGame != -1) {
            new bot_game;
            for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
                if(!is_user_connected(player_id) || !is_user_bot(player_id))
                    continue;

                bot_game = GetEntityOwner(player_id);
                if(bot_game == kickGame) {
                    kick_bot(player_id, bot_game, g_evict ? "evict" : "quota");
                    kicked = true;
                    break;
                }
            }
        }
    }
    if(!kicked) {
        //kick bad team
        for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
            if(!is_user_connected(player_id) || !is_user_bot(player_id))
                continue;

            new bot_game = GetEntityOwner(player_id);
            new bot_team = pev(player_id, pev_team);
            if(kickAnyone || (g_teams[bot_game] && bot_team && bot_team != g_teams[bot_game])) {
                kick_bot(player_id, bot_game, kickAnyone ? "anyone" : "team");
                kicked = true;
                break;
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
    if(strfind(saytext, "bot", true) == -1)
        return PLUGIN_CONTINUE;

    g_last_advert = get_gametime();
    client_print(0, print_chat, "If you wish to change the bot count or difficulty, say /bots to open the bots menu.");
    return PLUGIN_CONTINUE;
}

new g_player_id;
new bool:g_spy_notarget;
public SpyNoTarget() {
    g_spy_notarget = (pev(g_player_id, pev_deadflag) == 5 || get_pdata_int(g_player_id, 22) == 1);
}

public notarget_think() {
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!pev_valid(player_id) || (!is_user_alive(player_id) && pev(g_player_id, pev_deadflag) != 5))
            continue;
        
        new bool:notarget = false;
        if(GetEntityOwner(player_id) == g_dmc && pev(player_id, pev_renderfx) == kRenderFxGlowShell) {
            new Float:renderamt;
            pev(player_id, pev_renderamt, renderamt);
            if(renderamt == 5.0 || pev(player_id, pev_rendermode) == kRenderTransColor)
                notarget = true;
        } else if(GetEntityOwner(player_id) == g_tfc && pev(player_id, pev_playerclass) == 8) {
            g_player_id = player_id;
            GameContext(g_tfc, "SpyNoTarget");
            notarget = g_spy_notarget;
        }
        
        if(notarget)
            set_pev(player_id, pev_flags, pev(player_id, pev_flags) | FL_NOTARGET);
        else
            set_pev(player_id, pev_flags, pev(player_id, pev_flags) & ~FL_NOTARGET);
    }
}

public TouchPre(touched, other) {
    if(!g_nogoal)
        return FMRES_IGNORED;

    if(!is_user_bot(other))
        return FMRES_IGNORED;

    new classname[32];
    pev(touched, pev_classname, classname, 32);
    if(equal(classname, "weapon_c4") || equal(classname, "item_tfgoal")) {
        //server_print("Prevented bot touching %s.", classname);
        return FMRES_SUPERCEDE;
    }

    new model[32];
    pev(touched, pev_model, model, 32);
    if(equal(model, "models/w_backpack.mdl") || equal(model, "models/flag.mdl") || equal(model, "models/keycard.mdl") || equal(model, "models/ball.mdl")) {
        //server_print("Prevented bot touching %s.", model);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

public SetModelPost(entity, const model[]) {
    if(!g_nogoal)
        return FMRES_IGNORED;

    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(!equal(classname, "weapon_c4")) {
        return FMRES_SUPERCEDE;
    }

    new Float:bombOrigin[3];
    pev(entity, pev_origin, bombOrigin);

    for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
        if(!is_user_bot(iPlayer))
            continue;
        
        new Float:botOrigin[3];
        pev(iPlayer, pev_origin, botOrigin);
        if(bombOrigin[0] != botOrigin[0] || bombOrigin[1] != botOrigin[1] || bombOrigin[2] != botOrigin[2])
            continue;
        
        set_pev(entity, pev_flags, pev(entity, pev_flags) | FL_KILLME);
        //server_print("Prevented %s touching bot.", model);
        return FMRES_HANDLED;
    }
    return FMRES_IGNORED;
}