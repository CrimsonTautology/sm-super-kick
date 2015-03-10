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

#define HIT_SOUNDS_MAX 9
#define YELL_SOUNDS_MAX 2
new String:g_HitSounds[][] =
{
    "ambient/explosions/explode_1.wav",
    "ambient/explosions/explode_2.wav",
    "ambient/explosions/explode_3.wav",
    "ambient/explosions/explode_4.wav",
    "ambient/explosions/explode_5.wav",
    "ambient/explosions/explode_6.wav",
    "ambient/explosions/explode_7.wav",
    "ambient/explosions/explode_8.wav",
    "ambient/explosions/explode_9.wav"
};

new String:g_YellSounds[][] =
{
    "player/fallscream1.wav",
    "player/fallscream2.wav"
};

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Force = INVALID_HANDLE;

public OnPluginStart()
{
    CreateConVar("sm_super_kick_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
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
    for(new i=0; i < HIT_SOUNDS_MAX; i++)
    {
        PrecacheSound(g_HitSounds[i]);
    }

    for(new i=0; i < YELL_SOUNDS_MAX; i++)
    {
        PrecacheSound(g_YellSounds[i]);
    }
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
    if(!(attacker >= 1 && attacker <= MaxClients)) return Plugin_Continue;
    if(!(victim   >= 1 && victim   <= MaxClients)) return Plugin_Continue;
    if(attacker == victim) return Plugin_Continue;
   //IsPlayerAlive(attacker)

    //LogMessage("Event_PlayerHurt: %d -> %d inflictor=%d for %f(%d) damage with %d", attacker, victim, inflictor, damage, damagetype, weapon);//TODO
    if(weapon == -1 && damagetype == 268435456)
    {
        decl Float:vPos[3];
        GetClientAbsOrigin(attacker, vPos);
        PushPlayer(victim, vPos, GetConVarFloat(g_Cvar_Force), true);
        EmitSoundToAll(g_HitSounds[GetRandomInt(0, HIT_SOUNDS_MAX - 1)], attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);
        EmitSoundToAll(g_YellSounds[GetRandomInt(0, YELL_SOUNDS_MAX - 1)], victim, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);

    }

    return Plugin_Continue;
}

stock PushPlayer(victim, Float:fromOrigin[3], Float:force, bool:flying)
{
    new Float:vector[3];
    new Float:victimOrigin[3], Float:victimVelocity[3];

    Entity_GetBaseVelocity(victim, victimVelocity);

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

    Entity_SetBaseVelocity(victim, victimVelocity);
}

/**
 * Gets the Base velocity of an entity.
 * The base velocity is the velocity applied
 * to the entity from other sources .
 *
 * @param entity        Entity index.
 * @param vel           An 3 dim array
 * @noreturn
 */
stock Entity_GetBaseVelocity(entity, Float:vec[3])
{
    GetEntPropVector(entity, Prop_Data, "m_vecBaseVelocity", vec);
}

/**
 * Sets the Base velocity of an entity.
 * The base velocity is the velocity applied
 * to the entity from other sources .
 *
 * @param entity        Entity index.
 * @param vel           An 3 dim array
 * @noreturn
 */
stock Entity_SetBaseVelocity(entity, const Float:vec[3])
{
    SetEntPropVector(entity, Prop_Data, "m_vecBaseVelocity", vec);
}
