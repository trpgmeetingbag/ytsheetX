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

// VentanglePC専用のユドナリウムXML生成処理
output.generateUdonariumXmlDetailOfVentanglePC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};
  
  // ----------------------------------------
  // 1. 情報タブ
  // ----------------------------------------
  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || 'PL情報なし'}</data>`,
    `        <data name="レベル">${json.level || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(json.bodyArrange) {
    dataDetails['情報'].push(`        <data type="note" name="ボディアレンジ">${(json.bodyArrange || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
  }
  if(opt_url) { 
    dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);
  }

  // オリジンの入れ子展開
  const origins = [];
  for(let i = 1; i <= (json.originNum || 0); i++){
    if(json[`origin${i}Name`]){
      origins.push(`          <data name="${json[`origin${i}Name`]}">${(json[`origin${i}Reason`] || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
    }
  }
  if (origins.length > 0) dataDetails['情報'].push(`        <data name="オリジン">\n${origins.join('\n')}\n        </data>`);

  // アデプトの入れ子展開
  const adepts = [];
  for(let i = 1; i <= (json.adeptNum || 0); i++){
    if(json[`adept${i}Name`]){
      adepts.push(`          <data name="${json[`adept${i}Name`]}">${(json[`adept${i}Reason`] || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
    }
  }
  if (adepts.length > 0) dataDetails['情報'].push(`        <data name="アデプト">\n${adepts.join('\n')}\n        </data>`);

  // 妖精/神の入れ子展開
  const fairys = [];
  for(let i = 1; i <= (json.fairyNum || 0); i++){
    if(json[`fairy${i}NameText`]){
      fairys.push(`          <data name="${json[`fairy${i}NameText`]}">${(json[`fairy${i}Feature`] || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
    }
  }
  if (fairys.length > 0) dataDetails['情報'].push(`        <data name="妖精／神／獣">\n${fairys.join('\n')}\n        </data>`);

  // 人脈の入れ子展開（属性が項目名、名前が中身になります）
  const connections = [];
  for(let i = 1; i <= (json.connectionNum || 0); i++){
    if(json[`connection${i}Name`]){
      const cType = json[`connection${i}Type`] || 'タイプ不明';
      connections.push(`          <data name="${cType}">${(json[`connection${i}Name`] || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
    }
  }
  if (connections.length > 0) dataDetails['情報'].push(`        <data name="人脈">\n${connections.join('\n')}\n        </data>`);


  // ----------------------------------------
  // 2. パワータブ
  // ----------------------------------------
  const powers = [];
  for(let i = 1; i <= (json.powerNum || 0); i++){
    if(json[`power${i}Name`]){
      const type = json[`power${i}Type`] ? `（${json[`power${i}Type`]}）` : '';
      const effect = (json[`power${i}Note`] || '').replace(/&lt;br&gt;/g, '\n');
      powers.push(`        <data name="${json[`power${i}Name`]}">${type}${effect}</data>`);
    }
  }
  if (powers.length > 0) dataDetails['パワー'] = powers;


  // ----------------------------------------
  // 3. 武器タブ（ツリー構造展開）
  // ----------------------------------------
  const weapons = [];
  for(let i = 1; i <= (json.weaponNum || 0); i++){
    if(json[`weapon${i}Name`]){
      let wStr = `        <data name="${json[`weapon${i}Name`]}">`;
      wStr += `\n          <data name="射程">${json[`weapon${i}Range`] || ''}</data>`;
      wStr += `\n          <data name="ダメージ">${json[`weapon${i}Damage`] || ''}</data>`;
      wStr += `\n          <data name="補記">${(json[`weapon${i}Note`] || '').replace(/&lt;br&gt;/g, '\n')}</data>`;
      
      const customs = [];
      for(let j = 1; j <= (json[`weapon${i}CustomNum`] || 0); j++){
        if(json[`weapon${i}Custom${j}Name`]){
          const cat = json[`weapon${i}Custom${j}Category`] ? `［${json[`weapon${i}Custom${j}Category`]}］ ` : "";
          const note = (json[`weapon${i}Custom${j}Note`] || "").replace(/&lt;br&gt;/g, '\n');
          customs.push(`            <data name="${json[`weapon${i}Custom${j}Name`]}">${cat}${note}</data>`);
        }
      }
      if(customs.length > 0){
        wStr += `\n          <data name="カスタマイズ">\n${customs.join('\n')}\n          </data>`;
      }
      wStr += `\n        </data>`;
      weapons.push(wStr);
    }
  }
  if (weapons.length > 0) dataDetails['武器'] = weapons;


  // ----------------------------------------
  // 4. ウェアタブ
  // ----------------------------------------
  const wears = [];
  for(let i = 1; i <= (json.wearNum || 0); i++){
    if(json[`wear${i}Name`]){
      wears.push(`        <data name="${json[`wear${i}Name`]}">${(json[`wear${i}Note`] || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
    }
  }
  if (wears.length > 0) dataDetails['ウェア'] = wears;


  // ----------------------------------------
  // 5. アイテムタブ（数値リソースとしての展開）
  // ----------------------------------------
  const items = [];
  for(let i = 1; i <= (json.itemNum || 0); i++){
    if(json[`item${i}Name`]){
      // 『使用済』にチェックが入っている（USEDがオン）場合は現在値を0にする
      const val = json[`item${i}Used`] ? "0" : "1";
      items.push(`        <data name="${json[`item${i}Name`]}" type="numberResource" currentValue="${val}">1</data>`);
    }
  }
  if (items.length > 0) dataDetails['アイテム'] = items;


  dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return `` }
    return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
  });

  return dataDetails;
};