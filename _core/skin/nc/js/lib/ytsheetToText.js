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

output.generateCharacterTextOfNechronicaPC = (json) => {
  const result = [];

  // ==========================================
  // 【ヘッダ】
  // ==========================================
  result.push(`================================`);
  result.push(`キャラクター名：${json.characterName || '無名'}`);
  result.push(`プレイヤー名 ：${json.playerName || 'PL情報無し'}`);
  result.push(`================================`);
  result.push('');

  // ==========================================
  // 【基本情報】
  // ==========================================
  result.push('■基本情報■');
  result.push(`享年    ：${json.age || ''}`);
  result.push(`身長    ：${json.height || ''}`);
  result.push(`体重    ：${json.weight || ''}`);
  result.push(`ポジション ：${json.position || ''}`);
  result.push(`メインクラス：${json.mainClass || ''}`);
  result.push(`サブクラス ：${json.subClass || ''}`);
  result.push(`暗示    ：${json.anji || ''}`);
  result.push(`初期配置  ：${json.placement || ''}`);
  result.push('');

  // ==========================================
  // 【ステータス】
  // ==========================================
  result.push('■ステータス■');
  result.push(`最大行動値：${json.initiativeTotal || 0}`);
  result.push(`武装：${json.sttTotalBuso || 0} / 変異：${json.sttTotalHenI || 0} / 改造：${json.sttTotalKaizo || 0}`);
  
  let memoryCount = 0;
  const memoryNum = Number(json.memoryNum) || 0;
  for (let i = 1; i <= memoryNum; i++) {
    if (json[`memory${i}Name`]) memoryCount++;
  }

  result.push(`消費寵愛点 ：${json.expUsed || 0} / ${json.expTotal || 0}`);
  result.push('');

  // ==========================================
  // 【カルマ】
  // ==========================================
  const karmaLines = [];
  const karmaNum = Number(json.karmaNum) || 0;
  for (let i = 1; i <= karmaNum; i++) {
    const name = json[`karma${i}Name`];
    if (name) karmaLines.push(`・${name}`);
  }
  if (karmaLines.length > 0) {
    result.push('■カルマ■');
    result.push(karmaLines.join('\n'));
    result.push('');
  }

  // ==========================================
  // 【記憶のカケラ】
  // ==========================================
  const memoryLines = [];
  for (let i = 1; i <= memoryNum; i++) {
    const name = json[`memory${i}Name`];
    if (!name) continue;
    const note = (json[`memory${i}Note`] || '').replace(/&lt;br&gt;/g, ' ');
    memoryLines.push(`・【${name}】\n ${note}`);
  }
  if (memoryLines.length > 0) {
    result.push('■記憶のカケラ■');
    result.push(memoryLines.join('\n\n'));
    result.push('');
  }

  // ==========================================
  // 【未練】
  // ==========================================
  const mirenNum = Number(json.mirenNum) || 0;
  const mirenLines = [];
  for (let i = 1; i <= mirenNum; i++) {
    const name = json[`miren${i}Name`];
    if (!name) continue;
    
    let mirenTitle = name.startsWith('【') ? name : `【${name}】`;
    let mirenEmo = json[`miren${i}Note`] || '未練'; // ゆとシートのJSON仕様に従いNoteから感情を取得
    mirenEmo = mirenEmo.startsWith('【') ? mirenEmo : `【${mirenEmo}】`;
    
    const insanity = json[`miren${i}Insanity`] || 0;
    const burst = (json[`miren${i}Burst`] || '').replace(/&lt;br&gt;/g, ' ');
    
    mirenLines.push(`・${mirenTitle}への${mirenEmo}（狂気点：${insanity}）${burst}`);
  }
  if (mirenLines.length > 0) {
    result.push('■未練■');
    result.push(mirenLines.join('\n'));
    result.push('');
  }

  // ==========================================
  // 【マニューバ（スキル・パーツ）】
  // ==========================================
  // 全角文字を考慮した文字幅計算関数
  const getStrWidth = (str) => {
    let count = 0;
    for (let i = 0, len = str.length; i < len; i++) {
      const c = str.charCodeAt(i);
      if (c >= 0x0 && c <= 0x7f) count += 1; // 半角英数記号
      else if (c >= 0xff61 && c <= 0xff9f) count += 1; // 半角カナ
      else count += 2; // 全角
    }
    return count;
  };

  // 指定した幅になるように後ろにスペースを埋める関数
  const padRight = (str, width) => {
    str = String(str);
    const padLen = width - getStrWidth(str);
    return str + (padLen > 0 ? ' '.repeat(padLen) : '');
  };

  const partsData = { 'skill': [], 'head': [], 'arms': [], 'torso': [], 'legs': [] };
  const skillNum = Number(json.skillNum) || 0;
  
  const maneuvers = [];
  for (let i = 1; i <= skillNum; i++) {
    const name = json[`skill${i}Name`];
    const pos = json[`skill${i}Position`];
    if (!name || !pos) continue;

    const damage = json[`skill${i}Damage`] ? '【損】' : '';
    const nameStr = `《${name}》${damage}`;
    const timing = json[`skill${i}Timing`] || '未設定';
    const cost = json[`skill${i}Cost`] || '0';
    const range = json[`skill${i}Range`] || 'なし';
    
    // 取得先、カテゴリ、レベルを連結
    const cat = json[`skill${i}Category`] || '';
    const src = json[`skill${i}Source`] || '';
    const lv  = json[`skill${i}Lv`] ? `LV${json[`skill${i}Lv`]}` : '';
    const typeStr = [src, cat, lv].filter(e => e).join('/');

    const note = (json[`skill${i}Note`] || '').replace(/&lt;br&gt;/g, ' ');

    // 揃えたい列の配列を保持しておく
    maneuvers.push({ pos, cols: [nameStr, timing, cost, range, typeStr, note] });
  }

  // 1. 各列ごとの最大文字幅を計算する（効果文は一番後ろなので揃える必要なし）
  const maxW = [0, 0, 0, 0, 0];
  maneuvers.forEach(m => {
    m.cols.forEach((c, idx) => {
      if (idx < 5) maxW[idx] = Math.max(maxW[idx], getStrWidth(c));
    });
  });

  // 2. 最大幅に合わせてパディングし、部位ごとの配列に格納する
  maneuvers.forEach(m => {
    const formatted = m.cols.map((c, idx) => idx < 5 ? padRight(c, maxW[idx]) : c).join(' / ');
    if (partsData[m.pos]) {
      partsData[m.pos].push(formatted);
    }
  });

  result.push('■マニューバ■');
  if (partsData['skill'].length > 0) {
    result.push('【スキル】');
    result.push(partsData['skill'].join('\n'));
    result.push('');
  }
  if (partsData['head'].length > 0) {
    result.push('【パーツ：頭】');
    result.push(partsData['head'].join('\n'));
    result.push('');
  }
  if (partsData['arms'].length > 0) {
    result.push('【パーツ：腕】');
    result.push(partsData['arms'].join('\n'));
    result.push('');
  }
  if (partsData['torso'].length > 0) {
    result.push('【パーツ：胴】');
    result.push(partsData['torso'].join('\n'));
    result.push('');
  }
  if (partsData['legs'].length > 0) {
    result.push('【パーツ：脚】');
    result.push(partsData['legs'].join('\n'));
    result.push('');
  }

  // ==========================================
  // 【その他】
  // ==========================================
  result.push('■メモ■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;/g, '\n').replace(/&quot;/g, '"'));

  return result.join('\n');
};