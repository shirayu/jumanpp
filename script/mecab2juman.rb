#!/bin/ruby

# mecab 形式 の出力から juman の出力形式に変換するスクリプト
#usage: cat file | mecab2juman.rb

#output
# mecab2juman の出力 #(juman 形式)
#ぐでたまのうらない
#ぐでたま ぐでたま ぐでたま 名詞 6 普通名詞 1 * 0 * 0 "自動獲得:Wikipedia Wikipediaページ内一覧 "
#の の の 助詞 9 格助詞 1 * 0 * 0 NIL
#うらない うらない うらなう 動詞 2 * 0 子音動詞ワ行 12 基本連用形 8 "代表表記:占う/うらなう"
#EOS

#input #(mecab 形式)
#ぐでたま\t名詞,普通名詞,*,*,ぐでたま,ぐでたま,自動獲得:Wikipedia Wikipediaページ内一覧
#の\t助詞,格助詞,*,*,の,の,*
#うら\t動詞,*,子音動詞ラ行,未然形,うる,うら,代表表記:売る/うる ドメイン:ビジネス 自他動詞:自:売れる/うれる 反義:動詞:買う/かう
#ない\t接尾辞,形容詞性述語接尾辞,イ形容詞アウオ段,基本形,ない,ない,連語
#EOS

# 例外処理
# 入力が","だった場合は，", , , 特殊 1 読点 2 * 0 * 0 NIL" を出力する

POS_MAP ={ #{{{
    "*" => 0, "特殊"=>1, "動詞"=>2, "形容詞"=>3, "判定詞"=>4, "助動詞"=>5, "名詞"=>6, "指示詞"=>7,
    "副詞"=>8, "助詞"=>9, "接続詞"=>10, "連体詞"=>11, "感動詞"=>12, "接頭辞"=>13, "接尾辞"=>14, "未定義語"=>15
}
#}}}
SPOS_MAP = { #{{{
    "*"=>0, "句点"=>1, "読点"=>2, "括弧始"=>3, "括弧終"=>4, "記号"=>5, "空白"=>6, 
    "普通名詞"=>1, "サ変名詞"=>2, "固有名詞"=>3, "地名"=>4, "人名"=>5, "組織名"=>6, "数詞"=>7, "形式名詞"=>8,
    "副詞的名詞"=>9, "時相名詞"=>10, "名詞形態指示詞"=>1, "連体詞形態指示詞"=>2, "副詞形態指示詞"=>3, "格助詞"=>1, "副助詞"=>2, 
    "接続助詞"=>3, "終助詞"=>4, "名詞接頭辞"=>1, "動詞接頭辞"=>2, "イ形容詞接頭辞"=>3, "ナ形容詞接頭辞"=>4, "名詞性述語接尾辞"=>1, 
    "名詞性名詞接尾辞"=>2, "名詞性名詞助数辞"=>3, "名詞性特殊接尾辞"=>4, "形容詞性述語接尾辞"=>5, "形容詞性名詞接尾辞"=>6, 
    "動詞性接尾辞"=>7, "その他"=>1, "カタカナ"=>2, "アルファベット"=>3
}
#}}}
TYPE_MAP = { #{{{
    "*"=>0, "母音動詞"=>1, "子音動詞カ行"=>2, "子音動詞カ行促音便形"=>3, "子音動詞ガ行"=>4, "子音動詞サ行"=>5,
    "子音動詞タ行"=>6, "子音動詞ナ行"=>7, "子音動詞バ行"=>8, "子音動詞マ行"=>9, "子音動詞ラ行"=>10,
    "子音動詞ラ行イ形"=>11, "子音動詞ワ行"=>12, "子音動詞ワ行文語音便形"=>13, "カ変動詞"=>14, "カ変動詞来"=>15,
    "サ変動詞"=>16, "ザ変動詞"=>17, "イ形容詞アウオ段"=>18, "イ形容詞イ段"=>19, "イ形容詞イ段特殊"=>20,
    "ナ形容詞"=>21, "ナノ形容詞"=>22, "ナ形容詞特殊"=>23, "タル形容詞"=>24, "判定詞"=>25,
    "無活用型"=>26, "助動詞ぬ型"=>27, "助動詞だろう型"=>28, "助動詞そうだ型"=>29,
    "助動詞く型"=>30, "動詞性接尾辞ます型"=>31, "動詞性接尾辞うる型"=>32 
}
#}}}
FORM_MAP = { #{{{
"母音動詞:語幹"=>1, "*:*"=>0,
"母音動詞:基本形"=>2, "母音動詞:未然形"=>3, "母音動詞:意志形"=>4, "母音動詞:省略意志形"=>5, "母音動詞:命令形"=>6, "母音動詞:基本条件形"=>7,
"母音動詞:基本連用形"=>8, "母音動詞:タ接連用形"=>9, "母音動詞:タ形"=>10, "母音動詞:タ系推量形"=>11, "母音動詞:タ系省略推量形"=>12,
"母音動詞:タ系条件形"=>13, "母音動詞:タ系連用テ形"=>14, "母音動詞:タ系連用タリ形"=>15, "母音動詞:タ系連用チャ形"=>16, "母音動詞:音便条件形"=>17,
"母音動詞:文語命令形"=>18, "子音動詞カ行:語幹"=>1, "子音動詞カ行:基本形"=>2, "子音動詞カ行:未然形"=>3, "子音動詞カ行:意志形"=>4,
"子音動詞カ行:省略意志形"=>5, "子音動詞カ行:命令形"=>6, "子音動詞カ行:基本条件形"=>7, "子音動詞カ行:基本連用形"=>8, "子音動詞カ行:タ接連用形"=>9,
"子音動詞カ行:タ形"=>10, "子音動詞カ行:タ系推量形"=>11, "子音動詞カ行:タ系省略推量形"=>12, "子音動詞カ行:タ系条件形"=>13, "子音動詞カ行:タ系連用テ形"=>14, "子音動詞カ行:タ系連用タリ形"=>15, "子音動詞カ行:タ系連用チャ形"=>16, "子音動詞カ行:音便条件形"=>17, "子音動詞カ行促音便形:語幹"=>1,
"子音動詞カ行促音便形:基本形"=>2, "子音動詞カ行促音便形:未然形"=>3, "子音動詞カ行促音便形:意志形"=>4, "子音動詞カ行促音便形:省略意志形"=>5, "子音動詞カ行促音便形:命令形"=>6, "子音動詞カ行促音便形:基本条件形"=>7, "子音動詞カ行促音便形:基本連用形"=>8, "子音動詞カ行促音便形:タ接連用形"=>9, "子音動詞カ行促音便形:タ形"=>10, "子音動詞カ行促音便形:タ系推量形"=>11, "子音動詞カ行促音便形:タ系省略推量形"=>12, "子音動詞カ行促音便形:タ系条件形"=>13, "子音動詞カ行促音便形:タ系連用テ形"=>14,
"子音動詞カ行促音便形:タ系連用タリ形"=>15, "子音動詞カ行促音便形:タ系連用チャ形"=>16, "子音動詞カ行促音便形:音便条件形"=>17, "子音動詞ガ行:語幹"=>1, "子音動詞ガ行:基本形"=>2,
"子音動詞ガ行:未然形"=>3, "子音動詞ガ行:意志形"=>4, "子音動詞ガ行:省略意志形"=>5, "子音動詞ガ行:命令形"=>6, "子音動詞ガ行:基本条件形"=>7,
"子音動詞ガ行:基本連用形"=>8, "子音動詞ガ行:タ接連用形"=>9, "子音動詞ガ行:タ形"=>10, "子音動詞ガ行:タ系推量形"=>11, "子音動詞ガ行:タ系省略推量形"=>12, "子音動詞ガ行:タ系条件形"=>13, "子音動詞ガ行:タ系連用テ形"=>14, "子音動詞ガ行:タ系連用タリ形"=>15, "子音動詞ガ行:タ系連用チャ形"=>16,
"子音動詞ガ行:音便条件形"=>17, "子音動詞サ行:語幹"=>1, "子音動詞サ行:基本形"=>2, "子音動詞サ行:未然形"=>3, "子音動詞サ行:意志形"=>4,
"子音動詞サ行:省略意志形"=>5, "子音動詞サ行:命令形"=>6, "子音動詞サ行:基本条件形"=>7, "子音動詞サ行:基本連用形"=>8, "子音動詞サ行:タ接連用形"=>9,
"子音動詞サ行:タ形"=>10, "子音動詞サ行:タ系推量形"=>11, "子音動詞サ行:タ系省略推量形"=>12, "子音動詞サ行:タ系条件形"=>13, "子音動詞サ行:タ系連用テ形"=>14, "子音動詞サ行:タ系連用タリ形"=>15, "子音動詞サ行:タ系連用チャ形"=>16, "子音動詞サ行:音便条件形"=>17, "子音動詞タ行:語幹"=>1,
"子音動詞タ行:基本形"=>2, "子音動詞タ行:未然形"=>3, "子音動詞タ行:意志形"=>4, "子音動詞タ行:省略意志形"=>5, "子音動詞タ行:命令形"=>6,
"子音動詞タ行:基本条件形"=>7, "子音動詞タ行:基本連用形"=>8, "子音動詞タ行:タ接連用形"=>9, "子音動詞タ行:タ形"=>10, "子音動詞タ行:タ系推量形"=>11,
"子音動詞タ行:タ系省略推量形"=>12, "子音動詞タ行:タ系条件形"=>13, "子音動詞タ行:タ系連用テ形"=>14, "子音動詞タ行:タ系連用タリ形"=>15, "子音動詞タ行:タ系連用チャ形"=>16, "子音動詞タ行:音便条件形"=>17, "子音動詞ナ行:語幹"=>1, "子音動詞ナ行:基本形"=>2, "子音動詞ナ行:未然形"=>3,
"子音動詞ナ行:意志形"=>4, "子音動詞ナ行:省略意志形"=>5, "子音動詞ナ行:命令形"=>6, "子音動詞ナ行:基本条件形"=>7, "子音動詞ナ行:基本連用形"=>8,
"子音動詞ナ行:タ接連用形"=>9, "子音動詞ナ行:タ形"=>10, "子音動詞ナ行:タ系推量形"=>11, "子音動詞ナ行:タ系省略推量形"=>12, "子音動詞ナ行:タ系条件形"=>13, "子音動詞ナ行:タ系連用テ形"=>14, "子音動詞ナ行:タ系連用タリ形"=>15, "子音動詞ナ行:タ系連用チャ形"=>16, "子音動詞ナ行:音便条件形"=>17,
"子音動詞バ行:語幹"=>1, "子音動詞バ行:基本形"=>2, "子音動詞バ行:未然形"=>3, "子音動詞バ行:意志形"=>4, "子音動詞バ行:省略意志形"=>5,
"子音動詞バ行:命令形"=>6, "子音動詞バ行:基本条件形"=>7, "子音動詞バ行:基本連用形"=>8, "子音動詞バ行:タ接連用形"=>9, "子音動詞バ行:タ形"=>10,
"子音動詞バ行:タ系推量形"=>11, "子音動詞バ行:タ系省略推量形"=>12, "子音動詞バ行:タ系条件形"=>13, "子音動詞バ行:タ系連用テ形"=>14, "子音動詞バ行:タ系連用タリ形"=>15, "子音動詞バ行:タ系連用チャ形"=>16, "子音動詞バ行:音便条件形"=>17, "子音動詞マ行:語幹"=>1, "子音動詞マ行:基本形"=>2,
"子音動詞マ行:未然形"=>3, "子音動詞マ行:意志形"=>4, "子音動詞マ行:省略意志形"=>5, "子音動詞マ行:命令形"=>6, "子音動詞マ行:基本条件形"=>7,
"子音動詞マ行:基本連用形"=>8, "子音動詞マ行:タ接連用形"=>9, "子音動詞マ行:タ形"=>10, "子音動詞マ行:タ系推量形"=>11, "子音動詞マ行:タ系省略推量形"=>12, "子音動詞マ行:タ系条件形"=>13, "子音動詞マ行:タ系連用テ形"=>14, "子音動詞マ行:タ系連用タリ形"=>15, "子音動詞マ行:タ系連用チャ形"=>16,
"子音動詞マ行:音便条件形"=>17, "子音動詞ラ行:語幹"=>1, "子音動詞ラ行:基本形"=>2, "子音動詞ラ行:未然形"=>3, "子音動詞ラ行:意志形"=>4,
"子音動詞ラ行:省略意志形"=>5, "子音動詞ラ行:命令形"=>6, "子音動詞ラ行:基本条件形"=>7, "子音動詞ラ行:基本連用形"=>8, "子音動詞ラ行:タ接連用形"=>9,
"子音動詞ラ行:タ形"=>10, "子音動詞ラ行:タ系推量形"=>11, "子音動詞ラ行:タ系省略推量形"=>12, "子音動詞ラ行:タ系条件形"=>13, "子音動詞ラ行:タ系連用テ形"=>14, "子音動詞ラ行:タ系連用タリ形"=>15, "子音動詞ラ行:タ系連用チャ形"=>16, "子音動詞ラ行:音便条件形"=>17, "子音動詞ラ行イ形:語幹"=>1,
"子音動詞ラ行イ形:基本形"=>2, "子音動詞ラ行イ形:未然形"=>3, "子音動詞ラ行イ形:意志形"=>4, "子音動詞ラ行イ形:省略意志形"=>5, "子音動詞ラ行イ形:命令形"=>6, "子音動詞ラ行イ形:基本条件形"=>7, "子音動詞ラ行イ形:基本連用形"=>8, "子音動詞ラ行イ形:タ接連用形"=>9, "子音動詞ラ行イ形:タ形"=>10,
"子音動詞ラ行イ形:タ系推量形"=>11, "子音動詞ラ行イ形:タ系省略推量形"=>12, "子音動詞ラ行イ形:タ系条件形"=>13, "子音動詞ラ行イ形:タ系連用テ形"=>14, "子音動詞ラ行イ形:タ系連用タリ形"=>15, "子音動詞ラ行イ形:タ系連用チャ形"=>16, "子音動詞ラ行イ形:音便条件形"=>17, "子音動詞ワ行:語幹"=>1, "子音動詞ワ行:基本形"=>2, "子音動詞ワ行:未然形"=>3, "子音動詞ワ行:意志形"=>4, "子音動詞ワ行:省略意志形"=>5, "子音動詞ワ行:命令形"=>6,
"子音動詞ワ行:基本条件形"=>7, "子音動詞ワ行:基本連用形"=>8, "子音動詞ワ行:タ接連用形"=>9, "子音動詞ワ行:タ形"=>10, "子音動詞ワ行:タ系推量形"=>11,
"子音動詞ワ行:タ系省略推量形"=>12, "子音動詞ワ行:タ系条件形"=>13, "子音動詞ワ行:タ系連用テ形"=>14, "子音動詞ワ行:タ系連用タリ形"=>15, "子音動詞ワ行:タ系連用チャ形"=>16, "子音動詞ワ行文語音便形:語幹"=>1, "子音動詞ワ行文語音便形:基本形"=>2, "子音動詞ワ行文語音便形:未然形"=>3, "子音動詞ワ行文語音便形:意志形"=>4, "子音動詞ワ行文語音便形:省略意志形"=>5, "子音動詞ワ行文語音便形:命令形"=>6, "子音動詞ワ行文語音便形:基本条件形"=>7, "子音動詞ワ行文語音便形:基本連用形"=>8, "子音動詞ワ行文語音便形:タ接連用形"=>9, "子音動詞ワ行文語音便形:タ形"=>10, "子音動詞ワ行文語音便形:タ系推量形"=>11, "子音動詞ワ行文語音便形:タ系省略推量形"=>12, "子音動詞ワ行文語音便形:タ系条件形"=>13, "子音動詞ワ行文語音便形:タ系連用テ形"=>14, "子音動詞ワ行文語音便形:タ系連用タリ形"=>15, "子音動詞ワ行文語音便形:タ系連用チャ形"=>16,
"カ変動詞:語幹"=>1, "カ変動詞:基本形"=>2, "カ変動詞:未然形"=>3, "カ変動詞:意志形"=>4, "カ変動詞:省略意志形"=>5,
"カ変動詞:命令形"=>6, "カ変動詞:基本条件形"=>7, "カ変動詞:基本連用形"=>8, "カ変動詞:タ接連用形"=>9, "カ変動詞:タ形"=>10,
"カ変動詞:タ系推量形"=>11, "カ変動詞:タ系省略推量形"=>12, "カ変動詞:タ系条件形"=>13, "カ変動詞:タ系連用テ形"=>14, "カ変動詞:タ系連用タリ形"=>15,
"カ変動詞:タ系連用チャ形"=>16, "カ変動詞:音便条件形"=>17, "カ変動詞来:語幹"=>1, "カ変動詞来:基本形"=>2, "カ変動詞来:未然形"=>3,
"カ変動詞来:意志形"=>4, "カ変動詞来:省略意志形"=>5, "カ変動詞来:命令形"=>6, "カ変動詞来:基本条件形"=>7, "カ変動詞来:基本連用形"=>8,
"カ変動詞来:タ接連用形"=>9, "カ変動詞来:タ形"=>10, "カ変動詞来:タ系推量形"=>11, "カ変動詞来:タ系省略推量形"=>12, "カ変動詞来:タ系条件形"=>13,
"カ変動詞来:タ系連用テ形"=>14, "カ変動詞来:タ系連用タリ形"=>15, "カ変動詞来:タ系連用チャ形"=>16, "カ変動詞来:音便条件形"=>17, "サ変動詞:語幹"=>1,
"サ変動詞:基本形"=>2, "サ変動詞:未然形"=>3, "サ変動詞:意志形"=>4, "サ変動詞:省略意志形"=>5, "サ変動詞:命令形"=>6,
"サ変動詞:基本条件形"=>7, "サ変動詞:基本連用形"=>8, "サ変動詞:タ接連用形"=>9, "サ変動詞:タ形"=>10, "サ変動詞:タ系推量形"=>11,
"サ変動詞:タ系省略推量形"=>12, "サ変動詞:タ系条件形"=>13, "サ変動詞:タ系連用テ形"=>14, "サ変動詞:タ系連用タリ形"=>15, "サ変動詞:タ系連用チャ形"=>16, "サ変動詞:音便条件形"=>17, "サ変動詞:文語基本形"=>18, "サ変動詞:文語未然形"=>19, "サ変動詞:文語命令形"=>20,
"ザ変動詞:語幹"=>1, "ザ変動詞:基本形"=>2, "ザ変動詞:未然形"=>3, "ザ変動詞:意志形"=>4, "ザ変動詞:省略意志形"=>5,
"ザ変動詞:命令形"=>6, "ザ変動詞:基本条件形"=>7, "ザ変動詞:基本連用形"=>8, "ザ変動詞:タ接連用形"=>9, "ザ変動詞:タ形"=>10,
"ザ変動詞:タ系推量形"=>11, "ザ変動詞:タ系省略推量形"=>12, "ザ変動詞:タ系条件形"=>13, "ザ変動詞:タ系連用テ形"=>14, "ザ変動詞:タ系連用タリ形"=>15,
"ザ変動詞:タ系連用チャ形"=>16, "ザ変動詞:音便条件形"=>17, "ザ変動詞:文語基本形"=>18, "ザ変動詞:文語未然形"=>19, "ザ変動詞:文語命令形"=>20,
"イ形容詞アウオ段:語幹"=>1, "イ形容詞アウオ段:基本形"=>2, "イ形容詞アウオ段:命令形"=>3, "イ形容詞アウオ段:基本推量形"=>4, "イ形容詞アウオ段:基本省略推量形"=>5, "イ形容詞アウオ段:基本条件形"=>6, "イ形容詞アウオ段:基本連用形"=>7, "イ形容詞アウオ段:タ形"=>8, "イ形容詞アウオ段:タ系推量形"=>9,
"イ形容詞アウオ段:タ系省略推量形"=>10, "イ形容詞アウオ段:タ系条件形"=>11, "イ形容詞アウオ段:タ系連用テ形"=>12, "イ形容詞アウオ段:タ系連用タリ形"=>13, "イ形容詞アウオ段:タ系連用チャ形"=>14,
"イ形容詞アウオ段:タ系連用チャ形２"=>15, "イ形容詞アウオ段:音便条件形"=>16, "イ形容詞アウオ段:音便条件形２"=>17, "イ形容詞アウオ段:文語基本形"=>18, "イ形容詞アウオ段:文語未然形"=>19,
"イ形容詞アウオ段:文語連用形"=>20, "イ形容詞アウオ段:文語連体形"=>21, "イ形容詞アウオ段:文語命令形"=>22, "イ形容詞アウオ段:エ基本形"=>23, "イ形容詞イ段:語幹"=>1, "イ形容詞イ段:基本形"=>2, "イ形容詞イ段:命令形"=>3, "イ形容詞イ段:基本推量形"=>4, "イ形容詞イ段:基本省略推量形"=>5,
"イ形容詞イ段:基本条件形"=>6, "イ形容詞イ段:基本連用形"=>7, "イ形容詞イ段:タ形"=>8, "イ形容詞イ段:タ系推量形"=>9, "イ形容詞イ段:タ系省略推量形"=>10, "イ形容詞イ段:タ系条件形"=>11, "イ形容詞イ段:タ系連用テ形"=>12, "イ形容詞イ段:タ系連用タリ形"=>13, "イ形容詞イ段:タ系連用チャ形"=>14,
"イ形容詞イ段:タ系連用チャ形２"=>15, "イ形容詞イ段:音便条件形"=>16, "イ形容詞イ段:音便条件形２"=>17, "イ形容詞イ段:文語基本形"=>18, "イ形容詞イ段:文語未然形"=>19, "イ形容詞イ段:文語連用形"=>20, "イ形容詞イ段:文語連体形"=>21, "イ形容詞イ段:文語命令形"=>22, "イ形容詞イ段:エ基本形"=>23,
"イ形容詞イ段特殊:語幹"=>1, "イ形容詞イ段特殊:基本形"=>2, "イ形容詞イ段特殊:命令形"=>3, "イ形容詞イ段特殊:基本推量形"=>4, "イ形容詞イ段特殊:基本省略推量形"=>5, "イ形容詞イ段特殊:基本条件形"=>6, "イ形容詞イ段特殊:基本連用形"=>7, "イ形容詞イ段特殊:タ形"=>8, "イ形容詞イ段特殊:タ系推量形"=>9,
"イ形容詞イ段特殊:タ系省略推量形"=>10, "イ形容詞イ段特殊:タ系条件形"=>11, "イ形容詞イ段特殊:タ系連用テ形"=>12, "イ形容詞イ段特殊:タ系連用タリ形"=>13, "イ形容詞イ段特殊:タ系連用チャ形"=>14,
"イ形容詞イ段特殊:タ系連用チャ形２"=>15, "イ形容詞イ段特殊:音便条件形"=>16, "イ形容詞イ段特殊:音便条件形２"=>17, "イ形容詞イ段特殊:文語基本形"=>18, "イ形容詞イ段特殊:文語未然形"=>19,
"イ形容詞イ段特殊:文語連用形"=>20, "イ形容詞イ段特殊:文語連体形"=>21, "イ形容詞イ段特殊:文語命令形"=>22, "イ形容詞イ段特殊:エ基本形"=>23, "ナ形容詞:語幹"=>1, "ナ形容詞:基本形"=>2, "ナ形容詞:ダ列基本連体形"=>3, "ナ形容詞:ダ列基本推量形"=>4, "ナ形容詞:ダ列基本省略推量形"=>5,
"ナ形容詞:ダ列基本条件形"=>6, "ナ形容詞:ダ列基本連用形"=>7, "ナ形容詞:ダ列タ形"=>8, "ナ形容詞:ダ列タ系推量形"=>9, "ナ形容詞:ダ列タ系省略推量形"=>10, "ナ形容詞:ダ列タ系条件形"=>11, "ナ形容詞:ダ列タ系連用テ形"=>12, "ナ形容詞:ダ列タ系連用タリ形"=>13, "ナ形容詞:ダ列タ系連用ジャ形"=>14,
"ナ形容詞:ダ列文語連体形"=>15, "ナ形容詞:ダ列文語条件形"=>16, "ナ形容詞:デアル列基本形"=>17, "ナ形容詞:デアル列命令形"=>18, "ナ形容詞:デアル列基本推量形"=>19, "ナ形容詞:デアル列基本省略推量形"=>20, "ナ形容詞:デアル列基本条件形"=>21, "ナ形容詞:デアル列基本連用形"=>22, "ナ形容詞:デアル列タ形"=>23, "ナ形容詞:デアル列タ系推量形"=>24, "ナ形容詞:デアル列タ系省略推量形"=>25, "ナ形容詞:デアル列タ系条件形"=>26, "ナ形容詞:デアル列タ系連用テ形"=>27, "ナ形容詞:デアル列タ系連用タリ形"=>28, "ナ形容詞:デス列基本形"=>29, "ナ形容詞:デス列基本推量形"=>30, "ナ形容詞:デス列基本省略推量形"=>31,
"ナ形容詞:デス列タ形"=>32, "ナ形容詞:デス列タ系推量形"=>33, "ナ形容詞:デス列タ系省略推量形"=>34, "ナ形容詞:デス列タ系条件形"=>35, "ナ形容詞:デス列タ系連用テ形"=>36, "ナ形容詞:デス列タ系連用タリ形"=>37, "ナ形容詞:ヤ列基本形"=>38, "ナ形容詞:ヤ列基本推量形"=>39, "ナ形容詞:ヤ列基本省略推量形"=>40, "ナ形容詞:ヤ列タ形"=>41, "ナ形容詞:ヤ列タ系推量形"=>42, "ナ形容詞:ヤ列タ系省略推量形"=>43, "ナ形容詞:ヤ列タ系条件形"=>44,
"ナ形容詞:ヤ列タ系連用タリ形"=>45, "ナノ形容詞:語幹"=>1, "ナノ形容詞:基本形"=>2, "ナノ形容詞:ダ列基本連体形"=>3, "ナノ形容詞:ダ列特殊連体形"=>4,
"ナノ形容詞:ダ列基本推量形"=>5, "ナノ形容詞:ダ列基本省略推量形"=>6, "ナノ形容詞:ダ列基本条件形"=>7, "ナノ形容詞:ダ列基本連用形"=>8, "ナノ形容詞:ダ列タ形"=>9, "ナノ形容詞:ダ列タ系推量形"=>10, "ナノ形容詞:ダ列タ系省略推量形"=>11, "ナノ形容詞:ダ列タ系条件形"=>12, "ナノ形容詞:ダ列タ系連用テ形"=>13, "ナノ形容詞:ダ列タ系連用タリ形"=>14, "ナノ形容詞:ダ列タ系連用ジャ形"=>15, "ナノ形容詞:ダ列文語連体形"=>16, "ナノ形容詞:ダ列文語条件形"=>17,
"ナノ形容詞:デアル列基本形"=>18, "ナノ形容詞:デアル列命令形"=>19, "ナノ形容詞:デアル列基本推量形"=>20, "ナノ形容詞:デアル列基本省略推量形"=>21, "ナノ形容詞:デアル列基本条件形"=>22, "ナノ形容詞:デアル列基本連用形"=>23, "ナノ形容詞:デアル列タ形"=>24, "ナノ形容詞:デアル列タ系推量形"=>25, "ナノ形容詞:デアル列タ系省略推量形"=>26, "ナノ形容詞:デアル列タ系条件形"=>27, "ナノ形容詞:デアル列タ系連用テ形"=>28, "ナノ形容詞:デアル列タ系連用タリ形"=>29, "ナノ形容詞:デス列基本形"=>30,
"ナノ形容詞:デス列基本推量形"=>31, "ナノ形容詞:デス列基本省略推量形"=>32, "ナノ形容詞:デス列タ形"=>33, "ナノ形容詞:デス列タ系推量形"=>34, "ナノ形容詞:デス列タ系省略推量形"=>35, "ナノ形容詞:デス列タ系条件形"=>36, "ナノ形容詞:デス列タ系連用テ形"=>37, "ナノ形容詞:デス列タ系連用タリ形"=>38, "ナノ形容詞:ヤ列基本形"=>39, "ナノ形容詞:ヤ列基本推量形"=>40, "ナノ形容詞:ヤ列基本省略推量形"=>41, "ナノ形容詞:ヤ列タ形"=>42, "ナノ形容詞:ヤ列タ系推量形"=>43, "ナノ形容詞:ヤ列タ系省略推量形"=>44, "ナノ形容詞:ヤ列タ系条件形"=>45, "ナノ形容詞:ヤ列タ系連用タリ形"=>46, "ナ形容詞特殊:語幹"=>1,
"ナ形容詞特殊:基本形"=>2, "ナ形容詞特殊:ダ列基本連体形"=>3, "ナ形容詞特殊:ダ列特殊連体形"=>4, "ナ形容詞特殊:ダ列基本推量形"=>5, "ナ形容詞特殊:ダ列基本省略推量形"=>6, "ナ形容詞特殊:ダ列基本条件形"=>7, "ナ形容詞特殊:ダ列基本連用形"=>8, "ナ形容詞特殊:ダ列特殊連用形"=>9, "ナ形容詞特殊:ダ列タ形"=>10, "ナ形容詞特殊:ダ列タ系推量形"=>11, "ナ形容詞特殊:ダ列タ系省略推量形"=>12, "ナ形容詞特殊:ダ列タ系条件形"=>13, "ナ形容詞特殊:ダ列タ系連用テ形"=>14, "ナ形容詞特殊:ダ列タ系連用タリ形"=>15, "ナ形容詞特殊:ダ列タ系連用ジャ形"=>16, "ナ形容詞特殊:ダ列文語連体形"=>17, "ナ形容詞特殊:ダ列文語条件形"=>18, "ナ形容詞特殊:デアル列基本形"=>19, "ナ形容詞特殊:デアル列命令形"=>20, "ナ形容詞特殊:デアル列基本推量形"=>21, "ナ形容詞特殊:デアル列基本省略推量形"=>22, "ナ形容詞特殊:デアル列基本条件形"=>23, "ナ形容詞特殊:デアル列基本連用形"=>24, "ナ形容詞特殊:デアル列タ形"=>25, "ナ形容詞特殊:デアル列タ系推量形"=>26, "ナ形容詞特殊:デアル列タ系省略推量形"=>27, "ナ形容詞特殊:デアル列タ系条件形"=>28, "ナ形容詞特殊:デアル列タ系連用テ形"=>29, "ナ形容詞特殊:デアル列タ系連用タリ形"=>30, "ナ形容詞特殊:デス列基本形"=>31, "ナ形容詞特殊:デス列基本推量形"=>32, "ナ形容詞特殊:デス列基本省略推量形"=>33, "ナ形容詞特殊:デス列タ形"=>34, "ナ形容詞特殊:デス列タ系推量形"=>35, "ナ形容詞特殊:デス列タ系省略推量形"=>36, "ナ形容詞特殊:デス列タ系条件形"=>37, "ナ形容詞特殊:デス列タ系連用テ形"=>38, "ナ形容詞特殊:デス列タ系連用タリ形"=>39, "ナ形容詞特殊:ヤ列基本形"=>40, "ナ形容詞特殊:ヤ列基本推量形"=>41, "ナ形容詞特殊:ヤ列基本省略推量形"=>42, "ナ形容詞特殊:ヤ列タ形"=>43, "ナ形容詞特殊:ヤ列タ系推量形"=>44, "ナ形容詞特殊:ヤ列タ系省略推量形"=>45, "ナ形容詞特殊:ヤ列タ系条件形"=>46, "ナ形容詞特殊:ヤ列タ系連用タリ形"=>47, "タル形容詞:語幹"=>1, "タル形容詞:基本形"=>2, "タル形容詞:基本連用形"=>3,
"判定詞:語幹"=>1, "判定詞:基本形"=>2, "判定詞:ダ列基本連体形"=>3, "判定詞:ダ列特殊連体形"=>4, "判定詞:ダ列基本推量形"=>5,
"判定詞:ダ列基本省略推量形"=>6, "判定詞:ダ列基本条件形"=>7, "判定詞:ダ列タ形"=>8, "判定詞:ダ列タ系推量形"=>9, "判定詞:ダ列タ系省略推量形"=>10,
"判定詞:ダ列タ系条件形"=>11, "判定詞:ダ列タ系連用テ形"=>12, "判定詞:ダ列タ系連用タリ形"=>13, "判定詞:ダ列タ系連用ジャ形"=>14, "判定詞:デアル列基本形"=>15, "判定詞:デアル列命令形"=>16, "判定詞:デアル列基本推量形"=>17, "判定詞:デアル列基本省略推量形"=>18, "判定詞:デアル列基本条件形"=>19,
"判定詞:デアル列基本連用形"=>20, "判定詞:デアル列タ形"=>21, "判定詞:デアル列タ系推量形"=>22, "判定詞:デアル列タ系省略推量形"=>23, "判定詞:デアル列タ系条件形"=>24, "判定詞:デアル列タ系連用テ形"=>25, "判定詞:デアル列タ系連用タリ形"=>26, "判定詞:デス列基本形"=>27, "判定詞:デス列基本推量形"=>28,
"判定詞:デス列基本省略推量形"=>29, "判定詞:デス列タ形"=>30, "判定詞:デス列タ系推量形"=>31, "判定詞:デス列タ系省略推量形"=>32, "判定詞:デス列タ系条件形"=>33, "判定詞:デス列タ系連用テ形"=>34, "判定詞:デス列タ系連用タリ形"=>35, "無活用型:語幹"=>1, "無活用型:基本形"=>2,
"助動詞ぬ型:語幹"=>1, "助動詞ぬ型:基本形"=>2, "助動詞ぬ型:基本条件形"=>3, "助動詞ぬ型:基本連用形"=>4, "助動詞ぬ型:基本推量形"=>5,
"助動詞ぬ型:基本省略推量形"=>6, "助動詞ぬ型:タ形"=>7, "助動詞ぬ型:タ系条件形"=>8, "助動詞ぬ型:タ系連用テ形"=>9, "助動詞ぬ型:タ系推量形"=>10,
"助動詞ぬ型:タ系省略推量形"=>11, "助動詞ぬ型:音便基本形"=>12, "助動詞ぬ型:音便推量形"=>13, "助動詞ぬ型:音便省略推量形"=>14, "助動詞ぬ型:文語連体形"=>15, "助動詞ぬ型:文語条件形"=>16, "助動詞ぬ型:文語音便条件形"=>17, "助動詞だろう型:語幹"=>1, "助動詞だろう型:基本形"=>2,
"助動詞だろう型:ダ列基本省略推量形"=>3, "助動詞だろう型:ダ列基本条件形"=>4, "助動詞だろう型:デアル列基本推量形"=>5, "助動詞だろう型:デアル列基本省略推量形"=>6, "助動詞だろう型:デス列基本推量形"=>7,
"助動詞だろう型:デス列基本省略推量形"=>8, "助動詞だろう型:ヤ列基本推量形"=>9, "助動詞だろう型:ヤ列基本省略推量形"=>10, "助動詞そうだ型:語幹"=>1, "助動詞そうだ型:基本形"=>2, "助動詞そうだ型:ダ列タ系連用テ形"=>3, "助動詞そうだ型:デアル列基本形"=>4, "助動詞そうだ型:デス列基本形"=>5, "助動詞く型:語幹"=>1, "助動詞く型:基本形"=>2, "助動詞く型:基本連用形"=>3, "助動詞く型:文語連体形"=>4, "動詞性接尾辞ます型:語幹"=>1,
"動詞性接尾辞ます型:基本形"=>2, "動詞性接尾辞ます型:未然形"=>3, "動詞性接尾辞ます型:意志形"=>4, "動詞性接尾辞ます型:省略意志形"=>5, "動詞性接尾辞ます型:命令形"=>6, "動詞性接尾辞ます型:タ形"=>7, "動詞性接尾辞ます型:タ系条件形"=>8, "動詞性接尾辞ます型:タ系連用テ形"=>9, "動詞性接尾辞ます型:タ系連用タリ形"=>10, "動詞性接尾辞うる型:語幹"=>1, "動詞性接尾辞うる型:基本形"=>2, "動詞性接尾辞うる型:基本条件形"=>3,
}
#}}}



morph_str = []
while line=gets
  if(line =~ /^,.*/)
    print(", , , 特殊 1 読点 2 * 0 * 0 NIL\n")
  elsif(line =~ /^EOS/)
    print("EOS\n")
  else
    word = line.split(/[\t,\n]/)
    # 読み，原形は *(未定義語) の時は表層と同じものを使う
    word[5] = word[0] if (word[0] != "*" && word[5] == "*") 
    word[6] = word[0] if (word[0] != "*" && word[6] == "*") 
    # 意味情報が * である場合はクォーテーション無しのNILを使う
    if (word[7] == "*" || word[7] == "NIL") 
        word[7] = "NIL" 
    else
        word[7] = "\"#{word[7]}\"" 
    end
    
    print "#{word[0]} #{word[6]} #{word[5]} #{word[1]} #{POS_MAP[word[1]]||0} #{word[2]} #{SPOS_MAP[word[2]]||0} #{word[3]} #{TYPE_MAP[word[3]]||0} #{word[4]} #{FORM_MAP["#{word[3]}:#{word[4]}"]||0} #{word[7]}\n"
  end
end



