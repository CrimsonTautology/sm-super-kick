/**
 * vim: set ts=4 :
 * =============================================================================
 * Super kick
 *
 *
 * =============================================================================
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_NAME "Super Kick"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "CrimsonTautology",
    version = PLUGIN_VERSION,
    description = "Kick people very far",
    url = "https://github.com/CrimsonTautology/sm_super_kick_fof"
};

#define SOUND_HIT "ambient/explosions/explode_9.wav"

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Force = INVALID_HANDLE;

public OnPluginStart()
{
    CreateConVar("sm_super_friendlyfire_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_Cvar_Enabled = CreateConVar("sm_super_kick", "1", "Enabled");
    g_Cvar_Force = CreateConVar("sm_super_kick_force", "800.0", "Force applied by a kick");

    for(new i=1; i<=MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public OnMapStart()
{
    PrecacheSound(SOUND_HIT, true);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

bool:IsSuperKickEnabled()
{
    return GetConVarBool(g_Cvar_Enabled);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
    if(!IsSuperKickEnabled()) return Plugin_Continue;

    LogMessage("Event_PlayerHurt: %d -> %d inflictor=%d for %f(%d) damage with %d", attacker, victim, inflictor, damage, damagetype, weapon);//TODO
    if(weapon == -2)
    {
        LogMessage("----Kick force applied (%s)",  weapon);//TODO
        decl Float:vPos[3];
        GetClientAbsOrigin(attacker, vPos);
        PushPlayer(victim, vPos, GetConVarFloat(g_Cvar_Force), true);
        //EmitSoundToAll(SOUND_MELEE, attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);
        //EmitSoundToAll(SOUND_SWOOP, victim, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);

    }

    return Plugin_Continue;
}

stock PushPlayer(victim, Float:fromOrigin[3], Float:force, bool:flying)
{
    new Float:vector[3];
    new Float:victimOrigin[3], Float:victimVelocity[3];

    Entity_GetAbsVelocity(victim, victimVelocity);

    //Build push vector
    GetClientAbsOrigin(victim, victimOrigin);
    MakeVectorFromPoints(fromOrigin, victimOrigin, vector);
    NormalizeVector(vector, vector);
    ScaleVector(vector, force);

    AddVectors(vector, victimVelocity, victimVelocity);
    if(flying){
        //Avoid friction
        victimVelocity[2] = 900.0;
    }

    Entity_SetAbsVelocity(victim, victimVelocity);
    //TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vector);
}

/**
 * Gets the Absolute velocity of an entity.
 * The absolute velocity is the sum of the local
 * and base velocities. It's the actual value used to move.
 *
 * @param entity		Entity index.
 * @param vel			An 3 dim array
 * @noreturn
 */
stock Entity_GetAbsVelocity(entity, Float:vec[3])
{
    GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vec);
}

/**
 * Sets the Absolute velocity of an entity.
 * The absolute velocity is the sum of the local
 * and base velocities. It's the actual value used to move.
 *
 * @param entity		Entity index.
 * @param vel			An 3 dim array
 * @noreturn
 */
stock Entity_SetAbsVelocity(entity, const Float:vec[3])
{
    // We use TeleportEntity to set the velocity more safely
    // Todo: Replace this with a call to CBaseEntity::SetAbsVelocity()
    TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vec);
}
