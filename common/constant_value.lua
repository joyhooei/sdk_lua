-- Filename      : ./win32_client/common/constant_value.lua
-- Description   : 
-- Last modified : 2016-04-20 21:10

-- 图标背景rgb
icon_bg_color = {
    { r = 143, g = 154, b = 157, }, -- 白
    { r = 147, g = 213, b = 138, }, -- 绿
    { r = 138, g = 178, b = 213, }, -- 蓝
    { r = 213, g = 138, b = 212, }, -- 紫
    { r = 210, g = 156, b = 96 , }, -- 金
    { r = 227, g = 105, b = 117, }, -- 红
    { r = 213, g = 209, b = 138, }, -- 粉
    [ 0 ] = { r = 143, g = 154, b = 157, }, -- 白
}

-- 图标边框rgb
icon_rim_color = {
    { r = 209, g = 209, b = 209, }, -- 白
    { r = 15 , g = 255, b = 60 , }, -- 绿
    { r = 30 , g = 167, b = 255, }, -- 蓝
    { r = 252, g = 29 , b = 255, }, -- 紫
    { r = 247, g = 135, b = 14 , }, -- 金
    { r = 255, g = 48 , b = 48 , }, -- 红
    { r = 249, g = 241, b = 21 , }, -- 粉
    [ 0 ] = { r = 209, g = 209, b = 209, }, -- 白
}

-- 精灵族徽
spirit_lineup_logo = {
    'icon_0004_20_5.png',
    'icon_0004_20_6.png',
    'icon_0004_20_7.png',
    'icon_0004_20_8.png',
    [0] = 'icon/icon_0000_27.png',
}

-- 精灵职业
spirit_position_icon = {
    'icon/icon_0004_20_1.png',
    'icon/icon_0004_20_2.png',
    'icon/icon_0004_20_3.png',
}

-- 精灵卡片背景
spirit_card_rarity_bg = {
    'nb_0004_21_1.png',
    'nb_0004_21_2.png',
    'nb_0004_21_3.png',
    'nb_0004_21_4.png',
    'nb_0004_21_5.png',
    'nb_0004_21_6.png',
    'nb_0004_21_7.png',
}

attr_2_chi    = {
    ['MAX_HP'     ] = _YYTEXT( '血量' ),
    ['ATK'        ] = _YYTEXT( '攻击' ),
    ['PHY_ATK'    ] = _YYTEXT( '物攻' ),
    ['SKI_ATK'    ] = _YYTEXT( '魔攻' ),
    ['PHY_DEF'    ] = _YYTEXT( '护甲' ),
    ['SKI_DEF'    ] = _YYTEXT( '魔抗' ),
    ['HIT'        ] = _YYTEXT( '命中' ),
    ['DODGE'      ] = _YYTEXT( '闪避' ),
    ['CRIT'       ] = _YYTEXT( '暴击加成' ),
    ['CRIT_RESIST'] = _YYTEXT( '抗暴加成' ),
    ['DAM_INC'    ] = _YYTEXT( '伤害加深' ),
    ['DAM_DEC'    ] = _YYTEXT( '伤害减免' ),

    -- equip
    -- ['HP']        = _YYTEXT( '血量' ),
    -- ['ATK']       = _YYTEXT( '攻击' ),
    -- ['DEF']       = _YYTEXT( '护甲' ),
    -- ['RES']       = _YYTEXT( '魔抗' ),
    -- ['HIT']       = _YYTEXT( '命中' ),
    -- ['MISS']      = _YYTEXT( '闪避' ),
    -- ['CRIT']      = _YYTEXT( '暴击加成' ),
    -- ['TOUGHNESS'] = _YYTEXT( '抗暴加成' ),
    -- ['DEEPER']    = _YYTEXT( '伤害加深' ),
    -- ['REDUCER']   = _YYTEXT( '伤害减免' ),
}

equip_attr_names = {
    'MAX_HP'            , -- 生命
    'ATK'               , -- 攻
    'PHY_DEF'           , -- 物防
    'SKI_DEF'           , -- 技防
    'HIT'               , -- 命中
    'DODGE'             , -- 闪避
    'CRIT'              , -- 暴击
    'CRIT_RESIST'       , -- 抗暴击
    'DAM_INC'           , -- 伤害加深
    'DAM_DEC'           , -- 伤害减免
}

attr_value_format_funcs = {
    -- [ 'MAX_HP'      ] = _YYTEXT( '血量' ),
    -- [ 'ATK'         ] = _YYTEXT( '攻击' ),
    -- [ 'PHY_DEF'     ] = _YYTEXT( '护甲' ),
    -- [ 'SKI_DEF'     ] = _YYTEXT( '魔抗' ),
    [ 'HIT'         ] = function( v ) return string.format( '%g%%', v ) end, -- 命中,
    [ 'DODGE'       ] = function( v ) return string.format( '%g%%', v ) end, -- 闪避,
    [ 'CRIT'        ] = function( v ) return string.format( '%g%%', v ) end, -- 暴击,
    -- [ 'CRIT_RESIST' ] = _YYTEXT( '抗暴加成' ),
    -- [ 'DAM_INC'     ] = _YYTEXT( '伤害加深' ),
    -- [ 'DAM_DEC'     ] = _YYTEXT( '伤害减免' ),
}
setmetatable( attr_value_format_funcs, {
    __index = function( t, k ) return function( v ) return string.format( '%d', v ) end end,
} )
