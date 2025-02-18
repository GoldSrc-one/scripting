#include <amxmodx>

#include "crossplay"

public plugin_init() {
    register_plugin("Equip", "0.0", "GoldSrc.one");
    register_clcmd("say equip", "equip_test");
}

public equip_test(player_id) {

}