"use strict";

var output = output || {};
output.consts = output.consts || {};

output.consts.dicebot = 'MetallicGuardian';

output.consts.initiative = { label:'行動値', name: 'battleTotalKoudou' };

output.consts.SKILL_COLUMNS = {
  name: '名称',
  level: 'Lv',
  category: '種別',
  timing: 'タイミング',
  target: '対象',
  range: '射程',
  cost: '代償',
  reqd: '参照',
  note: '効果'
};

output.consts.CONNECTION_COLUMNS = {
  name: '名前',
  relation: '関係',
};

output.consts.GEIS_COLUMNS = {
  name: '名前',
  cost: '成長点',
  note: 'メモ'
};

output.consts.ARMAMENT_COLUMNS = {
  type: '',
  name: '名前',
  weight: '重量',
  acc: '命中',
  atk: '攻撃',
  eva: '回避',
  def: '物防',
  mdef: '魔防',
  ini: '行動',
  move: '移動',
  range: '射程',
  note: '備考'
};

// ★ここをMGR仕様に変更
output.consts.MGR_STATUS = [
  { name: '体力', column: 'Tai' },
  { name: '反射', column: 'Han' },
  { name: '知覚', column: 'Chi' },
  { name: '理知', column: 'Ri' },
  { name: '意志', column: 'Ishi' },
  { name: '幸運', column: 'Kou' },
];
