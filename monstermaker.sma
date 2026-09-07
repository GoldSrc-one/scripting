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

    new _:fields[] = { pev_weapons, pev_skin, pev_body };
    new bool:fieldSet = false;
    for(new iField = 0; iField < sizeof(fields); iField++) {
        new _:fieldValue = pev(owner, fields[iField]);
        if(!fieldValue)
            continue;
        
        set_pev(entity, fields[iField], fieldValue);
        fieldSet = true;
    }
    if(!fieldSet)
        return;

    //respawn with the correct weapons
    fm_DispatchSpawn(entity);
}