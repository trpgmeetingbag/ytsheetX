"use strict";

var output = output || {};

output.generateCcfoliaJsonOfArianrhod2PC = (json, character, defaultPalette) => {
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