#include <amxmodx>
#include <zombieplague>
#include <eG>
#include <hamsandwich>
#include <nvault>
#include <zpm>

native zp_donater_get_level(id)

new g_vault
new iLastSign[33]
new g_iDay, g_szDay[3]

public plugin_init()
{
	register_plugin("[ZPM] Daily Sign", "1.0", "EmeraldGhost")
	
	register_clcmd("say /sign", "sign_in")
	register_clcmd("say !sign", "sign_in")

	register_clcmd("say /qd", "sign_in")
	register_clcmd("say !qd", "sign_in")
	
	register_event("ResetHUD","Event_ResetHud","be")
	
	g_vault = nvault_open("ZP_Daily_Sign")
	
	get_time("%d", g_szDay, charsmax(g_szDay))
	g_iDay = str_to_num(g_szDay)
	
	server_print("[ZPM] Daily Sign loaded. Current Day: %d", g_iDay)
}

public Event_ResetHud(id)
{
	if(iLastSign[id] != g_iDay)
		client_printc(id, "\g[DailySign] \yYou have not signed today! Type \g'/sign'\y to sign.")
}

public client_putinserver(id)
{
	iLastSign[id] = 0
	LoadData(id);
}

public client_disconnect(id)
{
	SaveData(id)
	iLastSign[id] = 0
}

public SaveData(id) 
{ 
  new name[35], vaultkey[64], vaultdata[256]
              
  get_user_name(id, name, 34) 
  
  format(vaultkey, 63, "%s-Sign", name)

  format(vaultdata, 255, "%i#", iLastSign[id])

  nvault_set(g_vault, vaultkey, vaultdata) 

  return PLUGIN_CONTINUE
}

public LoadData(id) 
{ 
  new name[35], vaultkey[64], vaultdata[256]
  get_user_name(id,name,34) 
             
  format(vaultkey, 63, "%s-Sign", name) 

  format(vaultdata, 255, "%i#", iLastSign[id])

  //目前有 13 个%i#
  
  nvault_get(g_vault, vaultkey, vaultdata, 255)

  replace_all(vaultdata, 255, "#", " ") 

  new au[32]
  
  parse(vaultdata, au, 31)

  iLastSign[id] = str_to_num(au)

  return PLUGIN_CONTINUE
}

public sign_in(id)
{
	if(!iLastSign[id] || iLastSign[id] != g_iDay)
	{
	new iCoin = zpm_base_get_coin(id)
	new Award
	if(zp_donater_get_level(id) > 0) Award = random_num(1, zp_donater_get_level(id) * 3)
	else Award = random_num(1, 3)
	
	iLastSign[id] = g_iDay
	zpm_base_set_coin(id, iCoin + Award)
	PlaySound(id, "zmParadise/Store/coin_sound.wav")
	client_printc(id, "\g[DailySign] \ySuccess! You earned \t%d \ycoin(s).", Award)
	}
	else client_printc(id, "\g[DailySign] \yYou have already signed today!")
}
