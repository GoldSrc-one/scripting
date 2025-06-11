#include <amxmodx>
#include <fakemeta>

#include "crossplay"

new g_dmc = -1;

public plugin_init() {
    register_plugin("LetMePlay", "0.0", "GoldSrc.one");
    if(GetEntityOwner(0) != GetGameIndex("cstrike"))
        return;

    register_clcmd("say letmeplay", "say_letmeplay");
    register_clcmd("say /letmeplay", "say_letmeplay");
    register_clcmd("say !letmeplay", "say_letmeplay");
    register_forward(FM_CmdStart, "CmdStartPre", 0)
    
    set_task(0.5, "show_message", _, _, _, "b");

    g_dmc = GetGameIndex("dmc");
}

can_replace_bot(player_id){
    if(!is_user_connected(player_id))
        return false;

    if(is_user_alive(player_id))
        return false;

    if(!pev(player_id, pev_iuser1))
        return false;
    
    new bot_id = pev(player_id, pev_iuser2);

    if(bot_id < 1 || bot_id > get_maxplayers())
        return false;

    if(!is_user_bot(bot_id))
        return false;

    if(!is_user_alive(bot_id))
        return false;

    new player_team[16];
    get_user_team(player_id, player_team, 16);

    new bot_team[16];
    get_user_team(bot_id, bot_team, 16);
    if(!equal(player_team, bot_team))
        return false;

    if(GetEntityOwner(player_id) == g_dmc && (pev(bot_id, pev_flags) & FL_DUCKING))
        return false;

    return true;
}

new g_player_id;
public spawn_player() {
    SpawnPlayer(g_player_id);
}

public letmeplay(player_id) {
    if(!can_replace_bot(player_id))
		return PLUGIN_HANDLED;
        
    new bot_id = pev(player_id, pev_iuser2);
    
    set_pev(player_id, pev_iuser1, 0);

    g_player_id = player_id;
    GameContext(GetEntityOwner(player_id), "spawn_player");

    new Float:origin[3];
    pev(bot_id, pev_origin, origin);
    set_pev(player_id, pev_origin, origin);

    new Float:angles[3];
    pev(bot_id, pev_angles, angles);
    set_pev(player_id, pev_angles, angles);

    new Float:velocity[3];
    pev(bot_id, pev_velocity, velocity);
    set_pev(player_id, pev_velocity, velocity);

    new flags = pev(bot_id, pev_flags);
    flags &= ~FL_FAKECLIENT;
    flags &= ~(1 << 27);
    set_pev(player_id, pev_flags, flags);
    
    set_pev(player_id, pev_nextthink, -1.0);

    user_kill(bot_id, 1);

    return PLUGIN_HANDLED;
}

public say_letmeplay(player_id) {
    if(!can_replace_bot(player_id))
	    return PLUGIN_HANDLED;
    
    set_task(0.0, "letmeplay", player_id);

    return PLUGIN_HANDLED;
}

public CmdStartPre(player, cmd, random_seed)
{
    if(!(get_uc(cmd, UC_Buttons) & IN_USE))
        return FMRES_IGNORED;

    if(!can_replace_bot(player))
	    return FMRES_IGNORED;
    
    set_task(0.0, "letmeplay", player);

    return FMRES_HANDLED;
}

public show_message() {
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!can_replace_bot(player_id))
            continue;

        set_hudmessage(255, 127, 0, -1.0, 0.55, 0, 0.0, 0.5, 0.25, 0.25, -1);
        show_hudmessage(player_id, "Press E to respawn in place of this bot."); 
    }
}