"use strict";

var output = output || {};

// 関数名をネクロニカ用に変更
output.generateCcfoliaJsonOfNechronicaPC = (json, character, defaultPalette) => {
  // 名前の設定
  character.name = json.namePlate || json.characterName || json.aka;
  
  // ==========================================
  // 【メモ】の設定
  // ==========================================
  character.memo = '';
  character.memo += json.namePlate ? json.characterName + "\n" : '';
  character.memo += json.characterNameRuby ? '(' + json.characterNameRuby + ')\n' : '';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `ポジション: ${json.position || ''}\n`;
  character.memo += `メインクラス: ${json.mainClass || ''}\n`;
  character.memo += `サブクラス: ${json.subClass || ''}\n`;
  character.memo += `暗示: ${json.anji || ''}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;
  
  // ==========================================
  // 【リソース】（ステータス）の設定
  // ==========================================
  // パーツ数のカウント
  let headCount = 0;
  let armsCount = 0;
  let torsoCount = 0;
  let legsCount = 0;

  const skillNum = Number(json.skillNum) || 0;
  for (let i = 1; i <= skillNum; i++) {
    const pos = json[`skill${i}Position`];
    if (pos === 'head') headCount++;
    if (pos === 'arms') armsCount++;
    if (pos === 'torso') torsoCount++;
    if (pos === 'legs') legsCount++;
  }

  // ココフォリアのステータス（盤面でバーとして表示されるリソース）に追加
  character.status = character.status || [];
  character.status.push({ label: '頭', value: headCount, max: headCount });
  character.status.push({ label: '腕', value: armsCount, max: armsCount });
  character.status.push({ label: '胴', value: torsoCount, max: torsoCount });
  character.status.push({ label: '脚', value: legsCount, max: legsCount });

  // ==========================================
  // 【パラメータ】の設定（既存機能・バフデバフ用）
  // ==========================================
  character.params = character.params.concat(defaultPalette.parameters || []);

  return character;
};