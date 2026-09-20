"use strict";

var output = output || {};

output.generateCcfoliaJsonOfSRSPC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName || json.aka;

  character.memo = '';
  character.memo += json.namePlate ? json.characterName + "\n" : '';
  character.memo += json.characterNameRuby ? '(' + json.characterNameRuby + ')\n' : '';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.age || ''} / ${json.gender || ''} / ${json.cover || ''}\n`;
  character.memo += `クラス: ${json.classMain || ''}${json.classSupport ? ' / ' + json.classSupport : ''}${json.classTitle ? ' / ' + json.classTitle : ''}\n`;
  character.memo += `機体名: ${json.mechaName || ''}\n`;
  character.memo += `\n`;
  character.memo += json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : '';
  
  let addedParam = {};
  
  // ★MGRの能力値（ボーナス）を追加
  output.consts.MGR_STATUS.forEach((s)=>{
    character.params.push({
      label: s.name, value: json[`sttBonus${s.column}`] || 0
    });
    addedParam[s.name] = 1;
  });

  // ★MGRの戦闘値を追加
  const battleParams = [
    { label: '命中値', value: json.battleTotalMeichu || 0 },
    { label: '回避値', value: json.battleTotalKaihi || 0 },
    { label: '砲撃値', value: json.battleTotalHougeki || 0 },
    { label: '防壁値', value: json.battleTotalBouheki || 0 },
    { label: '行動値', value: json.battleTotalKoudou || 0 },
    { label: '移動力', value: json.battleTotalIdou || 0 }
  ];
  battleParams.forEach(p => {
    character.params.push(p);
    addedParam[p.label] = 1;
  });

  defaultPalette.parameters.forEach(s => {
    if(addedParam[s.label]){ return ''; }
    character.params.push(s);
  });

  return character;
};

// ==========================================
// ★新規追加：エネミー（魔物）用のココフォリア出力処理
// ==========================================
output.generateCcfoliaJsonOfSRSEnemy = (json, character, defaultPalette) => {
  // 名前と個別名のマージ
  character.name = json.namePlate || json.characterName || json.monsterName;
  
  character.memo = '';
  character.memo += json.namePlate ? (json.characterName || json.monsterName) + "\n" : '';
  character.memo += json.characterName ? "(" + json.monsterName + ")\n" : '';
  
  // 特殊能力（特技）の追加
  if (json.skills) {
    character.memo += "▽ 特殊能力\n" + json.skills.replace(/&lt;br&gt;/g, '\n') + "\n\n";
  }

  // ★新規追加：追加エリア（加護など）のループ出力
  // extraNum が定義されている場合はそれを使用し、無い場合でも存在する限り自動探索する
  let extraCount = Number(json.extraNum) || 0;
  if (!extraCount) {
    let i = 1;
    while (json[`extra${i}Name`] || json[`extra${i}Text`]) {
      extraCount = i;
      i++;
    }
  }

  for (let i = 1; i <= extraCount; i++) {
    const extraName = json[`extra${i}Name`] || '追加項目';
    const extraText = json[`extra${i}Text`] || '';
    
    // 内容が存在する場合のみメモ欄に出力
    if (extraText) {
      character.memo += `▽ ${extraName}\n` + extraText.replace(/&lt;br&gt;/g, '\n') + "\n\n";
    }
  }

  // 解説の追加
  if (json.description) {
    character.memo += "▽ 解説\n" + json.description.replace(/&lt;br&gt;/g, '\n') + "\n";
  }

  // 重複防止用のチェックリストを作成
  let addedParam = {};
  character.params.forEach(p => { addedParam[p.label] = 1; });

  // Perl側で生成されたデフォルトパレット（ステータスやボーナス等）をパラメータに追加
  defaultPalette.parameters.forEach(s => {
    if(addedParam[s.label]){ return; }
    character.params.push(s);
  });
  
  return character;
};