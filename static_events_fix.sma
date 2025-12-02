#include <amxmodx>
#include <fakemeta>

#include "crossplay"

public plugin_precache() {
    register_plugin("static events fix", "0.0", "GoldSrc.one");

    new eventNames[][] = {
        "tfc/events/explode/tf_burn.sc",
        "tfc/events/explode/tf_nailgren.sc",
        "tfc/events/misc/gibs.sc"
    };

    for(new i = 0; i < sizeof(eventNames); i++) {
        engfunc(EngFunc_PrecacheEvent, 1, eventNames[i]);
    }
}