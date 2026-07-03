// "use strict";

// var output = output || {};

// output.generateCcfoliaJsonOfDoubleCross3PC = (json, character, defaultPalette) => {
//   character.name = json.namePlate || json.characterName || json.aka;
  
//   character.memo = '';
//   character.memo += json.namePlate?json.characterName+"\n":'';
//   character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
//   character.memo += json.aka ? `コードネーム: ${json.aka}` : '';
//   character.memo += json.aka && json.akaRuby ? ` (${json.akaRuby})` : '';
//   character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
//   character.memo += `${json.works || ''} / ${json.cover || ''}\n`;
//   character.memo += `${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}\n`;
//   character.memo += `\n`;
//   character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;
  
//   character.params = character.params.concat(defaultPalette.parameters || []);

//   return character;
// };


"use strict";

var output = output || {};

// VentanglePC専用のココフォリア出力処理
output.generateCcfoliaJsonOfVentanglePC = (json, character, defaultPalette) => {
  // 1. コマの名前を設定（名前、二つ名(aka)の順にフォールバック）
  character.name = json.characterName || json.aka || '名称未設定';
  
  // 2. メモ欄の構築
  character.memo = '';
  character.memo += json.characterName ? `${json.characterName}\n` : '';
  character.memo += json.aka ? `ハンターネーム: ${json.aka}\n` : '';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `------------------------\n`;
  
  // Ventangle固有情報の追加
  character.memo += `レベル: ${json.level || ''} / 属性: ${json.attribute || ''}\n`;
  character.memo += `年齢: ${json.age || ''} / 性別: ${json.gender || ''}\n`;

  // オリジンの抽出
  const origins = [];
  for(let i = 1; i <= (json.originNum || 0); i++) {
    if(json[`origin${i}Name`]) origins.push(json[`origin${i}Name`]);
  }
  if(origins.length > 0) character.memo += `オリジン: ${origins.join(' / ')}\n`;

  // アデプトの抽出
  const adepts = [];
  for(let i = 1; i <= (json.adeptNum || 0); i++) {
    if(json[`adept${i}Name`]) adepts.push(json[`adept${i}Name`]);
  }
  if(adepts.length > 0) character.memo += `アデプト: ${adepts.join(' / ')}\n`;

  // 妖精/神の抽出
  const fairys = [];
  for(let i = 1; i <= (json.fairyNum || 0); i++) {
    if(json[`fairy${i}NameText`]) fairys.push(json[`fairy${i}NameText`]);
  }
  if(fairys.length > 0) character.memo += `妖精／神／獣: ${fairys.join(' / ')}\n`;


  // 3. ▼ 追加：パワー・装備・アイテムのリスト化 ▼
  
  // パワー
  const powers = [];
  for(let i = 1; i <= (json.powerNum || 0); i++) {
    if(json[`power${i}Name`]) powers.push(`《${json[`power${i}Name`]}》`);
  }
  if (powers.length > 0) {
    character.memo += `▼パワー\n${powers.join('')}\n`;
  }

  // 武器とカスタマイズ
  let hasWeapon = false;
  let weaponText = '';
  for(let i = 1; i <= (json.weaponNum || 0); i++) {
    const wName = json[`weapon${i}Name`];
    if(wName) {
      hasWeapon = true;
      weaponText += `・${wName}\n`;
      const customs = [];
      for(let j = 1; j <= (json[`weapon${i}CustomNum`] || 0); j++) {
        const cName = json[`weapon${i}Custom${j}Name`];
        if(cName) customs.push(`【${cName}】`);
      }
      if (customs.length > 0) {
        weaponText += `${customs.join('')}\n`;
      }
    }
  }
  if (hasWeapon) {
    character.memo += `▼武器\n${weaponText}`;
  }

  // ウェア
  const wears = [];
  for(let i = 1; i <= (json.wearNum || 0); i++) {
    if(json[`wear${i}Name`]) wears.push(`【${json[`wear${i}Name`]}】`);
  }
  if (wears.length > 0) {
    character.memo += `▼ウェア\n${wears.join('')}\n`;
  }

  // アイテム
  const items = [];
  for(let i = 1; i <= (json.itemNum || 0); i++) {
    if(json[`item${i}Name`]) items.push(`【${json[`item${i}Name`]}】`);
  }
  if (items.length > 0) {
    character.memo += `▼アイテム\n${items.join('')}\n`;
  }
  // ▲ パワー・装備・アイテム追加ここまで ▲

  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;
  
  // 4. チャットパレット由来のラベル(パラメータ)を追加
  character.params = character.params.concat(defaultPalette.parameters || []);

  return character;
};