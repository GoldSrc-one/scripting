#include <amxmodx>

public plugin_init() {
    register_plugin("Client CVARs", __DATE__, "GoldSrc.one");
}

public expect_client_cvar(player_id, const cvar[], const value[]) {
    query_client_cvar(player_id, cvar, "expect_callback", strlen(value), value); 
}

public expect_callback(player_id, const cvar[], const value[], const expectedValue[]) {
    if(equal(value, "Bad CVAR request"))
        return PLUGIN_HANDLED;

    if(equal(value, expectedValue))
        return PLUGIN_HANDLED;

    server_cmd("kick #%d ^"Please set %s %s^"", get_user_userid(player_id), cvar, expectedValue);

    return PLUGIN_HANDLED;
}

public client_connect(player_id) {
    if(is_user_bot(player_id))
        return PLUGIN_CONTINUE;
    
    expect_client_cvar(player_id, "cl_allowdownload", "1");
    expect_client_cvar(player_id, "cl_minmodels", "0");
    return PLUGIN_CONTINUE;
}