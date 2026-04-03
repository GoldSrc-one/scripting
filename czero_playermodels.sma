#include <amxmodx>
#include <reapi>

#include "crossplay"

public plugin_init() {
    register_plugin("CZero PlayerModels", __DATE__, "GoldSrc.one");

    RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, "CBasePlayer_SetClientUserInfoModel");
}

public CBasePlayer_SetClientUserInfoModel(const this, infobuffer[], szNewModel[]) {
    new game[64];
    GetClientGame(this, game, 64);
    if(!equal(game, "czero"))
        return HC_CONTINUE;

    if(equal(szNewModel, "terror") || equal(szNewModel, "leet") || equal(szNewModel, "arctic") || equal(szNewModel, "guerilla"))
        SetHookChainArg(3, ATYPE_STRING, "militia");

    if(equal(szNewModel, "urban") || equal(szNewModel, "gsg9") || equal(szNewModel, "gign") || equal(szNewModel, "sas"))
        SetHookChainArg(3, ATYPE_STRING, "spetsnaz");

    return HC_CONTINUE;
}