#include <amxmodx>
#include <zpm>
#include <vault>
#include <eG>
#include <zombieplague>
#include <hamsandwich>
#include <dbi>
#include <register_system>

#define COMPOSE_COST 25

// A~D出率递增
#define COMPOSE_TYPE_A 250
#define COMPOSE_TYPE_B 375
#define COMPOSE_TYPE_C 500
#define COMPOSE_TYPE_D 750

native zp_donater_get_level(id)

new const has_model[][] = { "\y", "\r" }

new const model_name[][] = { "null", "【Remilia】", "【NepGear.BW】", "【Kotori】", "【Yoshino】", "【Kurumi】", "【SnowWhite Miku】", "(SPCheer)【Cirno】", "(Limit)【Cloud】", "(Limit)【Fubuki】", "(Compose.Lv1)【Nier.2B】", "(Compose.Lv1)【ELO-Shino】", "(Compose.Lv2)【Swimsuit.Sagiri】" }
new const model_cost[] = { 0, 500, 1000, 1500, 1500, 1500, 1000, 750, 99999, 3000, 99999, 99999, 99999 } // 活动
new const model_sell[] = { 0, 250, 500, 750, 750, 750, 500, 375, 750, 1500, 800, 800, 1500 } // 活动
new const model_code[][] = { "null", "remilia", "bwgear", "kotori", "yoshino", "kurumi", "swmiku", "cirno", "cloud", "fubuki", "nier2b", "eloshino", "sagiri" }

enum
{
	MODEL_NULL, 
	MODEL_REMILIA, 
	MODEL_BWGEAR, 
	MODEL_KOTORI, 
	MODEL_YOSHINO, 
	MODEL_KURUMI, 
	MODEL_SWMIKU, 
	MODEL_CIRNO, 
	MODEL_CLOUD, 
	MODEL_FUBUKI, 
	MODEL_NIER2B, 
	MODEL_SHINO, 
	MODEL_SAGIRI
}

new pcv_debug

new iSelected[33]
new iPlayerHasSkin[33][sizeof model_code]

new const log_file[] = "ZStore_PlayerBuy.txt"

//SQL variable
new Sql:sql
new Result:result
new error[33]

public plugin_init()
{
	register_plugin("[eG] ZP Store - Skin", "v20181124", "EmeraldGhost")
	
	// SQL Initionlize
	new sql_host[64], sql_user[64], sql_pass[64], sql_db[64]
	get_cvar_string("amx_sql_host", sql_host, 63)
	get_cvar_string("amx_sql_user", sql_user, 63)
	get_cvar_string("amx_sql_pass", sql_pass, 63)
	get_cvar_string("amx_sql_db", sql_db, 63)

	sql = dbi_connect(sql_host, sql_user, sql_pass, sql_db, error, 32)

	if (sql == SQL_FAILED)
	{
		server_print("[ZStore] Could not connect to SQL database. %s", error)
	}
	
	register_clcmd("store_skin", "skin_menu")
	register_clcmd("say /store", "skin_menu")
	register_clcmd("say !store", "skin_menu")
	
	register_clcmd("store_sell", "sellskin_menu")
	register_clcmd("say /storesell", "sellskin_menu")
	register_clcmd("say !storesell", "sellskin_menu")
	
	register_clcmd("store_compose", "compose_skin")
	register_clcmd("say /compose", "compose_skin")
	register_clcmd("say !compose", "compose_skin")
}

public plugin_natives()
{
	register_native("zpm_store_get_user_skin", "Native_Get_Skin", 1)
}

public client_putinserver(id)
{
	for(new i=1;i<sizeof model_code;i++)
		iPlayerHasSkin[id][i] = 0
		
	load_data(id)
}

public client_disconnect(id)
{
	for(new i=1;i<sizeof model_code;i++)
		iPlayerHasSkin[id][i] = 0
}

public save_data(id)
{ 
	new authid[32]
	get_user_name(id, authid, 31)
	replace_all(authid, 32, "`", "\`")
	replace_all(authid, 32, "'", "\'")
	
	for(new i=1;i<sizeof model_code;i++)
	{
		dbi_query(sql, "UPDATE skinstore SET %s='%d' WHERE name = '%s'", model_code[i], iPlayerHasSkin[id][i], authid)
	}
}

public load_data(id) 
{
	new authid[32] 
	get_user_name(id,authid,31)
	replace_all(authid, 32, "`", "\`")
	replace_all(authid, 32, "'", "\'")

	result = dbi_query(sql, "SELECT remilia,bwgear,kotori,yoshino,kurumi,swmiku,cirno,cloud,fubuki,nier2b,eloshino,sagiri FROM skinstore WHERE name='%s'", authid)

	if(result == RESULT_NONE)
	{
		dbi_query(sql, "INSERT INTO skinstore(name,remilia,bwgear,kotori,yoshino,kurumi,swmiku,cirno,cloud,fubuki,nier2b,eloshino,sagiri) VALUES('%s','0','0','0','0','0','0','0','0','0','0','0','0')", authid)
	}
	else if(result <= RESULT_FAILED)
	{
		server_print("[ZStore] SQL Init error. (Skin-Load)")
	}
	else
	{
		for(new i=1;i<sizeof model_code;i++)
		{
			iPlayerHasSkin[id][i] = dbi_field(result, i)
		}
		dbi_free_result(result)
	}
}

public skin_menu(id)
{
		static option[64]
		formatex(option, charsmax(option), "\r[Zombie Paradise] - Models store^nCoin：%d", zpm_base_get_coin(id))
		new menu = menu_create(option, "store_skinmenu");
		
		new szTempid[32]
		for(new i = 1; i < sizeof model_code; i++)
		{
			new iSkin = iPlayerHasSkin[id][i]
		
			new szItems[101]
			formatex(szItems, 100, "%s\r%s \y| \d%d \yCoins", has_model[iSkin], model_name[i], model_cost[i])
			num_to_str(i, szTempid, 31)
			menu_additem(menu, szItems, szTempid, 0)
		}

		menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
		menu_setprop(menu, MPROP_BACKNAME, "Back"); 
		menu_setprop(menu, MPROP_NEXTNAME, "More..."); 
		menu_setprop(menu, MPROP_EXITNAME, "Exit"); 
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		
		menu_display(id, menu, 0);
		return PLUGIN_HANDLED;
}

public store_skinmenu(id, menu, item)
{
	new sz_Name[ 32 ];
	
	get_user_name( id, sz_Name, 31 );

	if(item==MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);
	
	new key = str_to_num(data);
	iSelected[id] = key
	sure_to_buy(id, iSelected[id])
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public sure_to_buy(id, skinid)
{
		static option[64]
		formatex(option, charsmax(option), "\rAre you sure to buy%s?", model_name[skinid])
		new menu = menu_create(option, "confirm_handler");
				
		menu_additem(menu, "\yYes！", "1");
		menu_additem(menu, "\yWait..", "2");
		
		menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
		menu_setprop(menu, MPROP_BACKNAME, "Back"); 
		menu_setprop(menu, MPROP_NEXTNAME, "More..."); 
		menu_setprop(menu, MPROP_EXITNAME, "Exit"); 
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		
		menu_display(id, menu, 0);
		return PLUGIN_HANDLED;
}

public confirm_handler(id, menu, item)
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

	switch(key)
	{
		case 1:
		{
			buy_skin(id, iSelected[id])
		}
		case 2:
		{
			return PLUGIN_HANDLED;
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public buy_skin(id, skinid)
{
	if(!is_user_logged(id))
		return PLUGIN_HANDLED;
	new IsHasModel = iPlayerHasSkin[id][skinid]
	new iCoin = zpm_base_get_coin(id)

	if(IsHasModel == 1)
	{
		client_printc(id, "\g[Store]\y You have already bought%s !", model_name[skinid]);
	}
	else if(iCoin >= model_cost[skinid])
	{
		client_printc(id, "\g[Store]\y Buy\g%s\ysuccess !", model_name[skinid]);
		PlaySound(id, "zmParadise/Store/coinlose_sound.wav")
		zpm_base_set_coin(id, iCoin - model_cost[skinid]);
		iPlayerHasSkin[id][skinid] = 1
		save_data(id)
		log_buy(id, skinid)
	}
	else client_printc(id, "\g[Store]\y No enough coin !");
	
	return PLUGIN_HANDLED;
}

public log_buy(id, skinid)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[Buy] %s -> %s .", name, model_name[skinid])
}

public sellskin_menu(id)
{
		static option[64]
		formatex(option, charsmax(option), "\r[Zombie Paradise] - Models sell^nCoin：%d", zpm_base_get_coin(id))
		new menu = menu_create(option, "store_sellskinmenu");
		
		new szTempid[32]
		for(new i = 1; i < sizeof model_code; i++)
		{
			new iSkin = iPlayerHasSkin[id][i]
		
			new szItems[101]
			formatex(szItems, 100, "\y%s\r%s - %d Coins", has_model[iSkin], model_name[i], model_sell[i])
			num_to_str(i, szTempid, 31)
			menu_additem(menu, szItems, szTempid, 0)
		}

		menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
		menu_setprop(menu, MPROP_BACKNAME, "Back"); 
		menu_setprop(menu, MPROP_NEXTNAME, "More..."); 
		menu_setprop(menu, MPROP_EXITNAME, "Exit"); 
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		
		menu_display(id, menu, 0);
		return PLUGIN_HANDLED;
}

public store_sellskinmenu(id, menu, item)
{
	new sz_Name[ 32 ];
	
	get_user_name( id, sz_Name, 31 );

	if(item==MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);
	
	new key = str_to_num(data);
	iSelected[id] = key
	sure_to_sell(id, iSelected[id])
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public sure_to_sell(id, skinid)
{
		static option[64]
		formatex(option, charsmax(option), "\rAre you sure to sell%s?", model_name[skinid])
		new menu = menu_create(option, "sell_confirm_handler");
				
		menu_additem(menu, "\yYes！", "1");
		menu_additem(menu, "\yWait..", "2");
		
		menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
		menu_setprop(menu, MPROP_BACKNAME, "Back"); 
		menu_setprop(menu, MPROP_NEXTNAME, "More..."); 
		menu_setprop(menu, MPROP_EXITNAME, "Exit"); 
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		
		menu_display(id, menu, 0);
		return PLUGIN_HANDLED;
}

public sell_confirm_handler(id, menu, item)
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

	switch(key)
	{
		case 1:
		{
			sell_skin(id, iSelected[id])
		}
		case 2:
		{
			return PLUGIN_HANDLED;
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public sell_skin(id, skinid)
{
	if(!is_user_logged(id))
		return PLUGIN_HANDLED;
	new IsHasModel = iPlayerHasSkin[id][skinid]
	new iCoin = zpm_base_get_coin(id)

	if(IsHasModel == 1)
	{
		client_printc(id, "\g[Store]\y Sell\g%s\ysuccess !", model_name[skinid]);
		PlaySound(id, "zmParadise/Store/coin_sound.wav")
		zpm_base_set_coin(id, iCoin + model_sell[skinid]);
		iPlayerHasSkin[id][skinid] = 0
		save_data(id)
		log_sell(id, skinid)
	}
	else client_printc(id, "\g[Store]\y You haven't bought this skin!");
	
	return PLUGIN_HANDLED;
}

public log_sell(id, skinid)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[Sell] %s -> %s .", name, model_name[skinid])
}

public compose_skin(id)
{
	client_printc(id, "\g[Compose] \y玄学系统正在重写算法 & 框架, 敬请期待!");
	return PLUGIN_HANDLED;
/*
	static option[64]
	formatex(option, charsmax(option), "\r[喪屍樂園] - 玄学菜单^n请选择模型：", zpm_base_get_coin(id))
	new menu = menu_create(option, "compose_handler");
			
	new szTempid[32]
	for(new i = 1; i < sizeof model_code; i++)
	{
		new iSkin = iPlayerHasSkin[id][i]
	
		new szItems[101]
		formatex(szItems, 100, "\y%s\r%s", has_model[iSkin], model_name[i])
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
	menu_setprop(menu, MPROP_BACKNAME, "返回"); 
	menu_setprop(menu, MPROP_NEXTNAME, "更多"); 
	menu_setprop(menu, MPROP_EXITNAME, "退出"); 
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
*/
}

public compose_handler(id, menu, item)
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

	new iSkin = iPlayerHasSkin[id][key]
	if(iSkin == 1)
	{
		iSelected[id] = key
		sure_to_compose(id, key)
	}
	else client_printc(id, "\g[Compose] \y你没有皮肤%s !", model_name[key])
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public sure_to_compose(id, skinid)
{
		static option[64]
		formatex(option, charsmax(option), "\r你确定要拿%s来抽奖吗？", model_name[skinid])
		new menu = menu_create(option, "confirm_compose_handler");
		
		formatex(option, charsmax(option), "\y是的，我是欧皇！(消耗 \r%d\y 金币)", COMPOSE_COST)		
		menu_additem(menu, option, "1");
		menu_additem(menu, "\y不是，我手抖了。^n^n", "2");
		menu_additem(menu, "\y提示：皮肤越贵，爆率越高哦！", "5");
		
		menu_setprop(menu, MPROP_NUMBER_COLOR, "\r"); 
		menu_setprop(menu, MPROP_BACKNAME, "返回"); 
		menu_setprop(menu, MPROP_NEXTNAME, "更多..."); 
		menu_setprop(menu, MPROP_EXITNAME, "退出"); 
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		
		menu_display(id, menu, 0);
		return PLUGIN_HANDLED;
}

public confirm_compose_handler(id, menu, item)
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

	switch(key)
	{
		case 1:
		{
			new iCoin = zpm_base_get_coin(id)
			if(iCoin >= COMPOSE_COST)
			{
			zpm_base_set_coin(id, zpm_base_get_coin(id) - COMPOSE_COST)
			try_compose_skin(id, iSelected[id])
			}
			else client_printc(id, "\g[Compose] \y没钱还想白嫖? 不可能的!")
		}
		case 2:
		{
			return PLUGIN_HANDLED;
		}
		case 5:
		{
			return PLUGIN_HANDLED;
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public try_compose_skin(id, skinid)
{
	if(!is_user_logged(id))
		return PLUGIN_HANDLED;

    new name[32]
    get_user_name(id,name,31)

	new MaxNum = 1000
	if(model_cost[skinid] == COMPOSE_TYPE_A) MaxNum = 970
	else if(model_cost[skinid] == COMPOSE_TYPE_B) MaxNum = 950
	else if(model_cost[skinid] == COMPOSE_TYPE_C) MaxNum = 920
	else if(model_cost[skinid] == COMPOSE_TYPE_D) MaxNum = 965
	else if(model_cost[skinid] == 99999) MaxNum = 600
	
	if(zp_donater_get_level(id) == 10) MaxNum -= 10
	
	new cNum = random_num(1, MaxNum)
	switch(cNum)
	{
		case 436..446:
		{
			new comNum = random_num(1, 10)
			switch(comNum)
			{
				case 1..4:
				{
					if(iPlayerHasSkin[id][MODEL_NIER2B] == 0)
					{
						iPlayerHasSkin[id][skinid] = 0
						iPlayerHasSkin[id][MODEL_NIER2B] = 1
						log_compose(id, skinid, MODEL_NIER2B)
						save_data(id)
						client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，成功置换\t【尼尔.2B】\y皮肤 !", name, model_name[skinid])
						return PLUGIN_HANDLED;
					}
					else
					{
						client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，本来可以置换\t【尼尔.2B】\y皮肤，可惜他有了！", name, model_name[skinid])
						return PLUGIN_HANDLED;
					}
				}
				case 5..8:
				{
					if(iPlayerHasSkin[id][MODEL_SHINO] == 0)
					{
						iPlayerHasSkin[id][skinid] = 0
						iPlayerHasSkin[id][MODEL_SHINO] = 1
						log_compose(id, skinid, MODEL_SHINO)
						save_data(id)
						client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，成功置换\t【ELO-诗乃】\y皮肤 !", name, model_name[skinid])
						return PLUGIN_HANDLED;
					}
					else
					{
						client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，本来可以置换\t【ELO-诗乃】\y皮肤，可惜他有了！", name, model_name[skinid])
						return PLUGIN_HANDLED;
					}
				}
				case 9..10:
				{
					if(iPlayerHasSkin[id][MODEL_SAGIRI] == 0)
					{
						iPlayerHasSkin[id][skinid] = 0
						iPlayerHasSkin[id][MODEL_SAGIRI] = 1
						log_compose(id, skinid, MODEL_SAGIRI)
						save_data(id)
						client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，成功置换\t【泳装.和泉纱雾】\y皮肤 !", name, model_name[skinid])
						return PLUGIN_HANDLED;
					}
					else
					{
						client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，本来可以置换\t【泳装.和泉纱雾】\y皮肤，可惜他有了！", name, model_name[skinid])
						return PLUGIN_HANDLED;
					}
				}
			}
		}
	}

	client_printc(0, "\g[Compose] \t%s\y 使用了\t%s\y参与置换，可惜什么都没有获得 !", name, model_name[skinid])
	return PLUGIN_HANDLED;
}

public log_compose(id, oldskin, skinid)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[Compose] %s 成功使用%s合成皮肤%s.", name, model_name[oldskin], model_name[skinid])
}

public Native_Get_Skin(id, skinid) return iPlayerHasSkin[id][skinid]
