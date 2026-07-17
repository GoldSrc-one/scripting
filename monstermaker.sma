#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>

public plugin_init() {
    register_plugin("MonsterMaker", __DATE__, "GoldSrc.one");
    register_forward(FM_CreateNamedEntity, "CreateNamedEntityPost", 1);
}

public CreateNamedEntityPost(iClassname) {
    new entity = get_orig_retval();
    if(!entity)
        return FMRES_IGNORED;

    new classname[32];
    fm_eng_get_string(iClassname, classname, 32);

    if(!equal(classname, "monster_", 8))
        return FMRES_IGNORED;

    set_task(0.0, "CreateMonsterPost", entity);    
    return FMRES_HANDLED;
}

public CreateMonsterPost(entity) {
    if(!pev_valid(entity))
        return;

    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(!equal(classname, "monster_", 8))
        return;

    new owner = pev(entity, pev_owner);
    if(!owner || !pev_valid(owner))
        return;

    pev(owner, pev_classname, classname, 32);
    if(!equal(classname, "monstermaker"))
        return;

    new weapons = pev(owner, pev_weapons);
    if(!weapons)
        return;

    //respawn with the correct weapons
    set_pev(entity, pev_weapons, weapons);
    fm_DispatchSpawn(entity);
}