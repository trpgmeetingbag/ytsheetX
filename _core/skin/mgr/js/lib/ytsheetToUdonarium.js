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

output.generateUdonariumXmlDetailOfArianrhod2PC = (json, opt_url, defaultPalette, resources)=>{

// 1. Perl側(resources)から「(弾数)」が含まれる項目を除外（重複防止）
  const filteredResources = resources.filter(res => !res.includes('(弾数)'));

  // 2. 基礎リソースを「リソース」カテゴリとして定義
  const dataDetails = {'リソース': filteredResources};
  
  // 3. 弾数専用のカテゴリ「武装：弾数」を個別に作成
  const ammoData = [];
  for (let i = 1; i <= (json.armamentsNum || 0); i++) {
    const name = json[`armament${i}Name`];
    const val  = json[`armament${i}Danzuu`];
    
    // ★修正：名前が存在し、かつ弾数が未定義(undefined/null)でも空文字でもない場合のみ追加
    if (name && val != null && val !== '') {
      ammoData.push(`        <data type="numberResource" currentValue="${val}" name="${name}">${val}</data>`);
    }
  }
  
  // 弾数データが存在する場合のみ、新しいカテゴリとして追加
  if (ammoData.length > 0) {
    dataDetails['武装：弾数'] = ammoData;
  }

  
  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="年齢">${json.age || ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data name="カバー">${json.cover || ''}</data>`,
    `        <data name="キャラクターレベル">${json.level || ''}</data>`,
    `        <data name="クラス">${json.classMain || ''}${json.classSupport ? ' / '+json.classSupport : ''}</data>`,
    `        <data name="機体名">${json.mechaName || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

  let addedParam = {};
  // ★MGRの能力値を追加
  dataDetails['能力値'] = output.consts.MGR_STATUS.map((s)=>{
    addedParam[s.name] = 1;
    return `        <data name="${s.name}">${json['sttBonus' + s.column] || 0}</data>`
  });
  
  // ★MGRの戦闘値を追加
  dataDetails['戦闘値'] = [
    `        <data name="命中値">${json.battleTotalMeichu || 0}</data>`,
    `        <data name="回避値">${json.battleTotalKaihi || 0}</data>`,
    `        <data name="砲撃値">${json.battleTotalHougeki || 0}</data>`,
    `        <data name="防壁値">${json.battleTotalBouheki || 0}</data>`,
    `        <data name="攻撃力">${json.battleTotalKougeki || 0}</data>`,
    `        <data name="行動値">${json.battleTotalKoudou || 0}</data>`,
    `        <data name="移動力">${json.battleTotalIdou || 0}</data>`
  ];
  addedParam['命中値'] = addedParam['回避値'] = addedParam['砲撃値'] = addedParam['防壁値'] = addedParam['攻撃力'] = addedParam['行動値'] = addedParam['移動力'] = 1;

  dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return `` }
    return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
  });

  return dataDetails
};