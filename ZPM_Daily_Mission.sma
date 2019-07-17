#include <amxmodx>
#include <zombieplague>
#include <eG>
#include <hamsandwich>
#include <nvault>
#include <zpm>

new const is_passed[][] = {"\y未完成", "\r已完成"}
new const daily_missions[][] = {"null", "[每日签到]", "[僵尸杀手I]", "[僵尸杀手II]", "[感染大师I]", "[逃跑大师]", "[一尸当先]", "[爆菊狂魔]", "[特殊奖励]"}
new const daily_missions_info[][] = {"null", "登陆游戏", "杀死 15 只僵尸", "杀死 30 只僵尸", "感染 10 个人类", "成功逃跑 15 次", "承受伤害达到 300000 点", "爆菊次数达到 15 次", "完成所有每日任务"}

new g_vault
new mission1[33], mission2[33], mission3[33], mission4[33], mission5[33], mission6[33], mission7[33], mission8[33]
new jinduA[33], jinduB[33], jinduC[33], jinduEscape[33], jinduFlower[33]
new iLastSign[33]
new g_iDay, g_szDay[3]

public plugin_init()
{
	register_plugin("[ZPM] Daily Mission", "1.0", "EmeraldGhost")
	
	register_clcmd("say /mission", "mission_menu")
	register_clcmd("say !mission", "mission_menu")
	
	register_event("ResetHUD","Event_ResetHud","be")
	
	g_vault = nvault_open("ZMP_Daily_Mission")
	
	RegisterHam(Ham_TakeDamage, "player", "Pl_TakeDamage")
	RegisterHam(Ham_Killed, "player", "Pl_Killed")
	
	get_time("%d", g_szDay, charsmax(g_szDay))
	g_iDay = str_to_num(g_szDay)
	
	server_print("[ZPM] Daily mission loaded. Current Day: %d", g_iDay)
}

public plugin_natives()
{
	register_native("zpm_mission_escape", "Native_EscapeSuccess", 1)
	register_native("zpm_mission_flower", "Native_Flower", 1)
}

public Native_EscapeSuccess(id)
{
	new wjsl = get_playersnum(0)
	if(wjsl < 4) return PLUGIN_HANDLED

	if(mission5[id] == 0 && jinduEscape[id] < 15)
	{
		jinduEscape[id] ++
		client_printc(id, "\g[Mission]\y进度更新: %s | 进度:[%d/15]", daily_missions_info[5], jinduEscape[id])
		SaveData(id)
	}
	return PLUGIN_HANDLED;
}

public Native_Flower(id)
{
	new wjsl = get_playersnum(0)
	if(wjsl < 4) return PLUGIN_HANDLED

	if(mission7[id] == 0 && jinduFlower[id] < 15)
	{
		jinduFlower[id] ++
		client_printc(id, "\g[Mission]\y进度更新: %s | 进度:[%d/15]", daily_missions_info[7], jinduFlower[id])
		SaveData(id)
	}
	return PLUGIN_HANDLED;
}

public Event_ResetHud(id)
{
	SaveData(id)
	
	if(mission8[id] == 0) client_printc(id, "\g[Mission] \y你可以输入 \g'/mission'\y 来打开每日任务菜单.")
}

public Pl_TakeDamage(victim, inflictor, attacker, Float:damage, DmgType)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker) || !zp_get_user_zombie(victim)) return HAM_IGNORED
	
	new wjsl = get_playersnum(0)
	if(wjsl < 4) return HAM_IGNORED
	
	if(jinduC[victim] < 300000)
		jinduC[victim] += damage
	
	return HAM_IGNORED
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(!is_user_connected(id) || !is_user_connected(infector) || !infector) return;
	
	new wjsl = get_playersnum(0)
	if(wjsl < 4) return;
	
	if(jinduB[infector] < 10)
	{
		jinduB[infector] ++
		client_printc(infector, "\g[Mission]\y进度更新: %s | 进度:[%d/10]", daily_missions_info[4], jinduB[infector])
	}
	return;
}

public Pl_Killed(victim, attacker)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker)) return
	
	new wjsl = get_playersnum(0)
	if(wjsl < 4) return;
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker) && is_user_alive(attacker) && (jinduA[attacker] < 30))
	{
		jinduA[attacker] ++
		
		if(jinduA[attacker] <= 15)
		{
			client_printc(attacker, "\g[Mission]\y进度更新: %s | 进度:[%d/15]", daily_missions_info[2], jinduA[attacker])
		}
		else client_printc(attacker, "\g[Mission]\y进度更新: %s | 进度:[%d/30]", daily_missions_info[3], jinduA[attacker])
	}
}

public client_putinserver(id)
{
	LoadData(id);
	check_time(id);
}

public client_disconnect(id)
{
	SaveData(id)
	mission1[id] = 0
	mission2[id] = 0
	mission3[id] = 0
	mission4[id] = 0
	mission5[id] = 0
	mission6[id] = 0
	mission7[id] = 0
	mission8[id] = 0
	jinduA[id] = 0
	jinduB[id] = 0
	jinduC[id] = 0
	jinduEscape[id] = 0
	jinduFlower[id] = 0
	iLastSign[id] = 0
}

public mission_menu(id)
{
	static option[64]
	new iCoin = zpm_base_get_coin(id)
	formatex(option, charsmax(option), "\r喪屍樂園 - 每日任务^n持有金币: %d^n页数:", iCoin)
	new menu = menu_create(option, "mission_handler");

	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[1], is_passed[mission1[id]])
	menu_additem(menu, option, "1");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[2], is_passed[mission2[id]])
	menu_additem(menu, option, "2");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[3], is_passed[mission3[id]])
	menu_additem(menu, option, "3");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[4], is_passed[mission4[id]])
	menu_additem(menu, option, "4");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[5], is_passed[mission5[id]])
	menu_additem(menu, option, "5");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[6], is_passed[mission6[id]])
	menu_additem(menu, option, "6");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[7], is_passed[mission7[id]])
	menu_additem(menu, option, "7");
	formatex(option, charsmax(option), "\r%s\y - %s", daily_missions[8], is_passed[mission8[id]])
	menu_additem(menu, option, "8");
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
	menu_setprop(menu, MPROP_BACKNAME, "返回"); 
	menu_setprop(menu, MPROP_NEXTNAME, "更多..."); 
	menu_setprop(menu, MPROP_EXITNAME, "退出"); 
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public mission_handler(id, menu, item)
{
	new sz_Name[ 32 ];
	
	get_user_name( id, sz_Name, 31 );

	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);
	
	new key = str_to_num(data);

	//{"null", "[每日签到]", "[僵尸杀手I]", "[僵尸杀手II]", "[感染大师]", "[逃跑大师]", "[一尸当先]", "[爆菊狂魔]", "[特殊奖励]"}
	switch(key)
	{
		case 1:
		{
			if(mission1[id] <= 0)
			{
			get_reward(id, 1, 1)
			mission1[id] = 1
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 2:
		{
			if(mission2[id] <= 0)
			{
				if(jinduA[id] >= 15)
				{
				get_reward(id, 2, 2)
				mission2[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/15]", daily_missions_info[2], jinduA[id])
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 3:
		{
			if(mission3[id] <= 0)
			{
				if(jinduA[id] >= 30)
				{
				get_reward(id, 3, 5)
				mission3[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/30]", daily_missions_info[3], jinduA[id])
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 4:
		{
			if(mission4[id] <= 0)
			{
				if(jinduB[id] >= 10)
				{
				get_reward(id, 4, 2)
				mission4[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/10]", daily_missions_info[4], jinduB[id])
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 5: //逃跑大师
		{
			if(mission5[id] <= 0)
			{
				if(jinduEscape[id] >= 15)
				{
				get_reward(id, 5, 2)
				mission5[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/15]", daily_missions_info[5], jinduEscape[id])
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 6:
		{
			if(mission6[id] <= 0)
			{
				if(jinduC[id] >= 300000)
				{
				get_reward(id, 6, 3)
				mission6[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/300000]", daily_missions_info[6], jinduC[id])
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 7: // 爆菊狂魔
		{
			if(mission7[id] <= 0)
			{
				if(jinduFlower[id] >= 15)
				{
				get_reward(id, 7, 3)
				mission7[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/15]", daily_missions_info[7], jinduFlower[id])
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
		case 8:
		{
			if(mission8[id] <= 0)
			{
				new iAddMission = mission1[id] + mission2[id] + mission3[id] + mission4[id] + mission5[id] + mission6[id] + mission7[id]
				if(iAddMission == 7)
				{
				get_reward(id, 8, random_num(5, 10))
				mission8[id] = 1
				}
				else client_printc(id, "\g[Mission]\y 任务目标: %s | 进度:[%d/8]", daily_missions_info[8], iAddMission)
			}
			else client_printc(id, "\g[Mission]\y 年轻人别太贪婪! 你已经领取过奖励了!")
		}
	}
	
	SaveData(id)
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public get_reward(id, mission, reward)
{
	new iAmount = zpm_base_get_coin(id) + reward
	zpm_base_set_coin(id, iAmount)
	PlaySound(id, "ImomoeCn/Store/coin_sound.wav")
	client_printc(id, "\g[Mission]\y 恭喜你完成任务: %s 奖励 %d 金币! ", daily_missions[mission], reward)
}

public SaveData(id) 
{ 
  new name[35], vaultkey[64], vaultdata[256]
              
  get_user_name(id, name, 34) 
  
  format(vaultkey, 63, "%s-Info", name)

  format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#", mission1[id], mission2[id], mission3[id], mission4[id], mission5[id], mission6[id], mission7[id], mission8[id], jinduA[id], jinduB[id], jinduC[id], jinduEscape[id], jinduFlower[id], iLastSign[id])

  nvault_set(g_vault, vaultkey, vaultdata) 

  return PLUGIN_CONTINUE
}

public LoadData(id) 
{ 
  new name[35], vaultkey[64], vaultdata[256]
  get_user_name(id,name,34) 
             
  format(vaultkey, 63, "%s-Info", name) 

  format(vaultdata, 255, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#", mission1[id], mission2[id], mission3[id], mission4[id], mission5[id], mission6[id], mission7[id], mission8[id], jinduA[id], jinduB[id], jinduC[id], jinduEscape[id], jinduFlower[id], iLastSign[id])

  //目前有 13 个%i#
  
  nvault_get(g_vault, vaultkey, vaultdata, 255)

  replace_all(vaultdata, 255, "#", " ") 

  new ms1[32], ms2[32], ms3[32], ms4[32], ms5[32], ms6[32], ms7[32], ms8[32], jd1[32], jd2[32], jd3[32], jd4[32], jd5[32], au[32]
  
  parse(vaultdata, ms1, 31, ms2, 31, ms3, 31, ms4, 31, ms5, 31, ms6, 31, ms7, 31, ms8, 31, jd1, 31, jd2, 31, jd3, 31, jd4, 31, jd5, 31, au, 31)

  mission1[id] = str_to_num(ms1)
  mission2[id] = str_to_num(ms2)
  mission3[id] = str_to_num(ms3)
  mission4[id] = str_to_num(ms4)
  mission5[id] = str_to_num(ms5)
  mission6[id] = str_to_num(ms6)
  mission7[id] = str_to_num(ms7)
  mission8[id] = str_to_num(ms8)
  jinduA[id] = str_to_num(jd1)
  jinduB[id] = str_to_num(jd2)
  jinduC[id] = str_to_num(jd3)
  jinduEscape[id] = str_to_num(jd4)
  jinduFlower[id] = str_to_num(jd5)
  iLastSign[id] = str_to_num(au)

  return PLUGIN_CONTINUE
}

public check_time(id)
{
	if(!iLastSign[id] || iLastSign[id] != g_iDay)
	{
	mission1[id] = 0
	mission2[id] = 0
	mission3[id] = 0
	mission4[id] = 0
	mission5[id] = 0
	mission6[id] = 0
	mission7[id] = 0
	mission8[id] = 0
	jinduA[id] = 0
	jinduB[id] = 0
	jinduEscape[id] = 0
	jinduFlower[id] = 0
	iLastSign[id] = g_iDay
	SaveData(id)
	}
}