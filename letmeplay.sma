#include <amxmodx>
#include <engine>

#include "crossplay"

public plugin_init() {
    register_plugin("LetMePlay", "0.0", "GoldSrc.one");
    register_clcmd("say letmeplay", "letmeplay");
    register_clcmd("say /letmeplay", "letmeplay");
    register_clcmd("say !letmeplay", "letmeplay");
    register_clcmd("say ^"letmeplay^"", "letmeplay");
    
    set_task(0.5, "show_message", _, _, _, "b");
}

can_replace_bot(player_id){
    if(!entity_get_int(player_id, EV_INT_deadflag))
        return false;

    if(!entity_get_int(player_id, EV_INT_iuser1))
        return false;
    
    new bot_id = entity_get_int(player_id, EV_INT_iuser2);

    if(bot_id < 1 || bot_id > get_maxplayers())
        return false;

    if(!(entity_get_int(bot_id, EV_INT_flags) & FL_FAKECLIENT))
        return false;

    if(entity_get_int(bot_id, EV_INT_deadflag))
        return false;

    new player_team[16];
    get_user_team(player_id, player_team, 16);

    new bot_team[16];
    get_user_team(bot_id, bot_team, 16);
    if(!(strcmp(player_team, bot_team) == 0))
        return false;

    return true;
}

new g_player_id;
public spawn_player() {
    SpawnPlayer(g_player_id);
}

public letmeplay(player_id) {
    if(!can_replace_bot(player_id))
		return PLUGIN_CONTINUE;
        
    new bot_id = entity_get_int(player_id, EV_INT_iuser2);
    
    entity_set_int(player_id, EV_INT_iuser1, 0);

    g_player_id = player_id;
    GameContext(GetEntityOwner(player_id), "spawn_player");

    new Float:origin[3];
    entity_get_vector(bot_id, EV_VEC_origin, origin);
    entity_set_vector(player_id, EV_VEC_origin, origin);

    new Float:angles[3];
    entity_get_vector(bot_id, EV_VEC_angles, angles);
    entity_set_vector(player_id, EV_VEC_angles, angles);

    new Float:velocity[3];
    entity_get_vector(bot_id, EV_VEC_velocity, velocity);
    entity_set_vector(player_id, EV_VEC_velocity, velocity);

    new flags = entity_get_int(bot_id, EV_INT_flags);
    flags &= ~FL_FAKECLIENT;
    flags &= ~(1 << 27);
    entity_set_int(player_id, EV_INT_flags, flags);

    user_kill(bot_id, 1);

    return PLUGIN_HANDLED;
}

public show_message() {
    for(new player_id = 1; player_id < get_maxplayers(); player_id++) {
        if(!can_replace_bot(player_id))
            continue;

        set_hudmessage(255, 127, 0, -1.0, 0.55, 0, 0.0, 0.5, 0.25, 0.25, -1);
        show_hudmessage(player_id, "Say ^"letmeplay^" to respawn in place of this bot."); 
    }
}