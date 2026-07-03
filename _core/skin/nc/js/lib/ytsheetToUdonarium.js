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

// 関数名をネクロニカ用に変更
output.generateUdonariumXmlDetailOfNechronicaPC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};
  let addedParam = {}; // バフ・デバフの重複除外用
  
  // ==========================================
  // 【情報】タブ
  // ==========================================
  dataDetails['情報'] = [];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL" type="note">${opt_url}</data>`); }
  dataDetails['情報'].push(`        <data name="初期配置">${json.placement || ''}</data>`); // ※初期配置を変数history0Exp等に入れている場合。適宜変数名は合わせてください。
  dataDetails['情報'].push(`        <data name="ポジション">${json.position || ''}</data>`);
  dataDetails['情報'].push(`        <data name="メインクラス">${json.mainClass || ''}</data>`);
  dataDetails['情報'].push(`        <data name="サブクラス">${json.subClass || ''}</data>`);
  dataDetails['情報'].push(`        <data name="暗示">${json.anji || ''}</data>`);
  dataDetails['情報'].push(`        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`);
  dataDetails['情報'].push(`        <data type="note" name="メモ"></data>`);

  // ==========================================
  // 【データ】タブ（スキルとパーツのノート化）
  // 【パーツ】タブ（部位ごとの個数集計）
  // 【使用回数】タブ（特定のタイミングの抽出）
  // ==========================================
  const dataTab = [];
  const usageCountTab = [];
  
  let headCount = 0;
  let armsCount = 0;
  let torsoCount = 0;
  let legsCount = 0;

  // 部位ごとの配列を準備
  const partsData = {
    'skill': [],
    'head': [],
    'arms': [],
    'torso': [],
    'legs': []
  };

  // skillNum分のループを回してデータを仕分け
  const skillNum = Number(json.skillNum) || 0;
  for (let i = 1; i <= skillNum; i++) {
    const name = json[`skill${i}Name`];
    const pos = json[`skill${i}Position`]; // skill, head, arms, torso, legs
    if (!name || !pos) continue;

    const timing = json[`skill${i}Timing`] || '';
    const cost = json[`skill${i}Cost`] || '';
    const range = json[`skill${i}Range`] || '';
    // <br> を （改行）＋全角スペース に変換
    const note = (json[`skill${i}Note`] || '').replace(/&lt;br&gt;/g, '\n ');

    // ノート形式の文字列を作成
    const noteContent = `タイミング：${timing}　　　コスト：${cost}　　　射程：${range}\n効果：${note}`;
    
    // 部位ごとのリストに追加
    if (partsData[pos]) {
      partsData[pos].push(`          <data name="${name}" type="note">${noteContent}</data>`);
    }

    // パーツの個数集計
    if (pos === 'head') headCount++;
    if (pos === 'arms') armsCount++;
    if (pos === 'torso') torsoCount++;
    if (pos === 'legs') legsCount++;

    // 使用回数タブへの追加判定（ジャッジ、ダメージ、ラピッドが含まれているか）
    if (timing.includes('ジャッジ') || timing.includes('ダメージ') || timing.includes('ラピッド')) {
      usageCountTab.push(`        <data name="${name}" type="numberResource" currentValue="1">1</data>`);
      addedParam[name] = 1; // バフデバフとの重複を防ぐ
    }
  }

  // データタブの組み立て
  if (partsData['skill'].length > 0) {
    dataTab.push(`        <data name="スキル">\n${partsData['skill'].join('\n')}\n        </data>`);
  }
  if (partsData['head'].length > 0) {
    dataTab.push(`        <data name="パーツ：頭">\n${partsData['head'].join('\n')}\n        </data>`);
  }
  if (partsData['arms'].length > 0) {
    dataTab.push(`        <data name="パーツ：腕">\n${partsData['arms'].join('\n')}\n        </data>`);
  }
  if (partsData['torso'].length > 0) {
    dataTab.push(`        <data name="パーツ：胴">\n${partsData['torso'].join('\n')}\n        </data>`);
  }
  if (partsData['legs'].length > 0) {
    dataTab.push(`        <data name="パーツ：脚">\n${partsData['legs'].join('\n')}\n        </data>`);
  }
  dataDetails['データ'] = dataTab;

  // パーツ（個数）タブの組み立て
  dataDetails['パーツ'] = [
    `        <data name="頭" type="numberResource" currentValue="${headCount}">${headCount}</data>`,
    `        <data name="腕" type="numberResource" currentValue="${armsCount}">${armsCount}</data>`,
    `        <data name="胴" type="numberResource" currentValue="${torsoCount}">${torsoCount}</data>`,
    `        <data name="脚" type="numberResource" currentValue="${legsCount}">${legsCount}</data>`
  ];

  // 使用回数タブの組み立て
  if (usageCountTab.length > 0) {
    dataDetails['使用回数'] = usageCountTab;
  }

  // ==========================================
  // 【記憶のカケラ】タブ
  // ==========================================
  const memoryTab = [];
  const memoryNum = Number(json.memoryNum) || 0;
  for (let i = 1; i <= memoryNum; i++) {
    const name = json[`memory${i}Name`];
    const note = (json[`memory${i}Note`] || '').replace(/&lt;br&gt;/g, '\n');
    if (name) {
      memoryTab.push(`        <data name="${name}">${note}</data>`);
    }
  }
  if (memoryTab.length > 0) {
    dataDetails['記憶のカケラ'] = memoryTab;
  }

  // ==========================================
  // 【未練】タブ
  // ==========================================
  const mirenTab = [];
  const mirenNum = Number(json.mirenNum) || 0;
  for (let i = 1; i <= mirenNum; i++) {
    const name = json[`miren${i}Name`]; // 対象
    const emo = json[`miren${i}Note`] || '感情'; // 取得する感情の変数名は適宜合わせます
    // ※未練の形式が「【対象】への【感情】」となるように構築します。
    // jsonの変数がどのように格納されているかによって調整が必要です。
    // 例として Name に対象、Plus に感情が入っていると仮定します。
    let mirenTitle = name;
    if (!name.startsWith('【')) mirenTitle = `【${name}】`;
    let mirenEmo = json[`miren${i}Note`] || '未練';
    if (!mirenEmo.startsWith('【')) mirenEmo = `【${mirenEmo}】`;
    
    const title = `${mirenTitle}への${mirenEmo}`;
    const val = json[`miren${i}Insanity`] || 0; // 狂気点など

    if (name) {
      mirenTab.push(`        <data name="${title}" type="numberResource" currentValue="${val}">4</data>`);
    }
  }
  if (mirenTab.length > 0) {
    dataDetails['未練'] = mirenTab;
  }

  dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return `` }
    return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
  });


  return dataDetails
};
