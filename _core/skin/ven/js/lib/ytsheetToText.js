/* MIT License

Copyright 2020 @Shunshun94

Customize & Refactoring by @yutorize

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
"use strict";

var output = output || {};

output._getVentangleOrigins = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`origin${cursor}Name`]) {
    data.push({
      name: json[`origin${cursor}Name`] || '',
      lineage: json[`origin${cursor}PowerLineage`] || '',
      reason: (json[`origin${cursor}Reason`] || '').replace(/&lt;br&gt;/g, ' '),
      note: (json[`origin${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

output._getVentangleAdepts = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`adept${cursor}Name`]) {
    data.push({
      name: json[`adept${cursor}Name`] || '',
      lineage: json[`adept${cursor}PowerLineage`] || '',
      reason: (json[`adept${cursor}Reason`] || '').replace(/&lt;br&gt;/g, ' '),
      note: (json[`adept${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

output._getVentangleFairys = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`fairy${cursor}NameText`]) {
    data.push({
      name: json[`fairy${cursor}NameText`] || '',
      feature: (json[`fairy${cursor}Feature`] || '').replace(/&lt;br&gt;/g, ' '),
      note: (json[`fairy${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

output._getVentangleConnections = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`connection${cursor}Name`]) {
    data.push({
      name: json[`connection${cursor}Name`] || '',
      type: json[`connection${cursor}Type`] || '',
      relation: json[`connection${cursor}Relation`] || '',
      note: (json[`connection${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

output._getVentanglePowers = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`power${cursor}Name`]) {
    data.push({
      from: json[`power${cursor}From`] || '',
      name: json[`power${cursor}Name`] || '',
      type: json[`power${cursor}Type`] || '',
      ref: json[`power${cursor}Ref`] || '',
      note: (json[`power${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

output._getVentangleWeapons = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`weapon${cursor}Name`]) {
    data.push({
      name: json[`weapon${cursor}Name`] || '',
      range: json[`weapon${cursor}Range`] || '',
      damage: json[`weapon${cursor}Damage`] || '',
      maint: json[`weapon${cursor}Maint`] || '',
      ref: json[`weapon${cursor}Ref`] || '',
      note: (json[`weapon${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    
    // カスタマイズのツリー展開
    let cCursor = 1;
    while(json[`weapon${cursor}Custom${cCursor}Name`]) {
       data.push({
         name: ' └【' + (json[`weapon${cursor}Custom${cCursor}Name`] || '') + '】',
         range: json[`weapon${cursor}Custom${cCursor}Category`] ? `［${json[`weapon${cursor}Custom${cCursor}Category`]}］` : '',
         damage: '',
         maint: json[`weapon${cursor}Custom${cCursor}Maint`] || '',
         ref: json[`weapon${cursor}Custom${cCursor}Ref`] || '',
         note: (json[`weapon${cursor}Custom${cCursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
       });
       cCursor++;
    }
    cursor++;
  }
  return data;
};

output._getVentangleWears = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`wear${cursor}Name`]) {
    data.push({
      category: json[`wear${cursor}Category`] || '',
      name: json[`wear${cursor}Name`] || '',
      price: json[`wear${cursor}Price`] || '',
      maint: json[`wear${cursor}Maint`] || '',
      ref: json[`wear${cursor}Ref`] || '',
      note: (json[`wear${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

output._getVentangleItems = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`item${cursor}Name`]) {
    data.push({
      used: json[`item${cursor}Used`] ? '☑' : '☐',
      name: json[`item${cursor}Name`] || '',
      price: json[`item${cursor}Price`] || '',
      ref: json[`item${cursor}Ref`] || '',
      note: (json[`item${cursor}Note`] || '').replace(/&lt;br&gt;/g, ' ')
    });
    cursor++;
  }
  return data;
};

// =========================================================================
// テキスト本体の構築
// =========================================================================
output.generateCharacterTextOfVentanglePC = (json) => {
  const result = [];

  result.push(`キャラクター名：${json.characterName || ''}`);
  result.push(`二つ名：${json.aka || ''}`);
  result.push(`PL名：${json.playerName || ''}`);
  result.push('');

  result.push(`年齢：${json.age || ''}`);
  result.push(`性別：${json.gender || ''}`);
  result.push(`身長：${json.height || ''}`);
  result.push(`体重：${json.weight || ''}`);
  result.push('');

  result.push(`レベル：${json.level || ''}`);
  result.push(`属性：${json.attribute || ''}`);
  result.push('');

  result.push(`衣装：${json.outfit || ''}`);
  result.push(`住居：${json.housing || ''}`);
  result.push('');

  result.push(`■ステータス■`);
  result.push(`プライド：${json.prideTotal || 0} ／ ${json.prideMaxTotal || 0} ` + (json.pridePenalty ? `(適用ペナルティ: ${json.pridePenalty})` : ''));
  result.push(`カルマ：${json.karmaTotal || 0} ` + (json.karmaPenalty ? `(適用ペナルティ: ${json.karmaPenalty})` : ''));
  if (json.permanentBs) {
    result.push(`永続BS：${json.permanentBs}`);
  }
  if (json.bodyArrange) {
    result.push(`ボディアレンジ：\n${json.bodyArrange.replace(/&lt;br&gt;/g, '\n')}`);
  }
  result.push('');

  result.push(`■オリジン・アデプト・妖精／神■`);
  const origins = output._getVentangleOrigins(json);
  if (origins.length > 0) {
    result.push('【オリジン】');
    result.push(output._convertList(origins, {name:'名称', lineage:'パワー系統', reason:'事情', note:'備考'}, ' / '));
    result.push('');
  }
  const adepts = output._getVentangleAdepts(json);
  if (adepts.length > 0) {
    result.push('【アデプト】');
    result.push(output._convertList(adepts, {name:'名称', lineage:'パワー系統', reason:'経歴', note:'備考'}, ' / '));
    result.push('');
  }
  const fairys = output._getVentangleFairys(json);
  if (fairys.length > 0) {
    result.push('【妖精／神／獣】');
    result.push(output._convertList(fairys, {name:'名称', feature:'性質', note:'備考'}, ' / '));
    result.push('');
  }
  if (json.additionalPowerLineage) {
    result.push(`追加のパワー系統：${json.additionalPowerLineage}`);
    result.push('');
  }

  result.push(`■ライフスタイル■`);
  result.push(`弱点：${json.lifestyleWeakness || ''} ${json.lifestyleWeaknessNote ? '（'+json.lifestyleWeaknessNote+'）' : ''}`);
  result.push(`趣味：${json.lifestyleHobby || ''} ${json.lifestyleHobbyNote ? '（'+json.lifestyleHobbyNote+'）' : ''}`);
  result.push(`モチベ：${json.lifestyleMotivation || ''} ${json.lifestyleMotivationNote ? '（'+json.lifestyleMotivationNote+'）' : ''}`);
  result.push('');

  const connections = output._getVentangleConnections(json);
  if(connections.length > 0) {
    result.push(`■人脈■`);
    result.push(output._convertList(connections, {name:'NPC名', type:'タイプ', relation:'関係', note:'備考'}, ' / '));
    result.push('');
  }

  result.push(`■資産状況■`);
  result.push(`総収入：${json.incomeTotal || 0}`);
  result.push(`総支出：${json.expenseTotal || 0}`);
  result.push(`現在の所持金：${json.moneyTotal || 0}`);
  result.push(`借金合計：${json.debtTotal || 0}`);
  result.push('');

  const powers = output._getVentanglePowers(json);
  if (powers.length > 0) {
    result.push(`■パワー■`);
    result.push(output._convertList(powers, {from:'取得元', name:'名称', type:'タイプ', ref:'参照', note:'効果'}, ' / '));
    result.push('');
  }

  const weapons = output._getVentangleWeapons(json);
  if (weapons.length > 0) {
    result.push(`■武器■`);
    result.push(output._convertList(weapons, {name:'名称', range:'射程/カテゴリ', damage:'ダメージ', maint:'維持費', ref:'参照', note:'効果/補記'}, ' / '));
    result.push('');
  }

  const wears = output._getVentangleWears(json);
  if (wears.length > 0) {
    result.push(`■ウェア■`);
    result.push(output._convertList(wears, {category:'カテゴリ', name:'名称', price:'価格', maint:'維持費', ref:'参照', note:'効果'}, ' / '));
    result.push('');
  }

  const items = output._getVentangleItems(json);
  if (items.length > 0) {
    result.push(`■アイテム■`);
    result.push(output._convertList(items, {used:'使用済', name:'名称', price:'価格', ref:'参照', note:'効果'}, ' / '));
    result.push('');
  }

  result.push(`■その他メモ■`);
  result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
  
  return result.join('\n');
};