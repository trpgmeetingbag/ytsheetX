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

output.generateUdonariumXmlDetailOfSRSPC = (json, opt_url, defaultPalette, resources)=>{

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

// ==========================================
// ★新規追加：エネミー（魔物）用のユドナリウム出力処理
// ==========================================
output.generateUdonariumXmlDetailOfSRSEnemy = (json, opt_url, defaultPalette, resources) => {
  // ★コアシステム（ZIP生成側）で名前が消失するのを防ぐための強制補完
  json.characterName = json.namePlate || json.characterName || json.monsterName || '無名';

  // ★XML破壊エラー（Opening and ending tag mismatch: br）の修正
  // Perl側で生成したユニットステータスに <br> が混ざるとXMLが壊れるため、安全に変換する
  const sanitizedResources = [];
  let memoData = '';
  (resources || []).forEach(res => {
    if (res.includes('name="メモ"')) {
      // メモは長文になるため、type="note" に変換しつつ <br> を改行(\n)に直す
      const match = res.match(/<data name="メモ">([\s\S]*?)<\/data>/);
      if (match) {
        const text = match[1].replace(/<br\s*\/?>/gi, '\n').replace(/&lt;br&gt;/gi, '\n');
        // memoData = `        <data type="note" name="メモ">${text}</data>`;
        memoData = `        <data type="note" name="メモ"></data>`;
        //メモ欄の中身が壊れていたため無力化
      }
    } else {
      // その他のステータスに万が一 <br> が混ざっていた場合は無害化する
      sanitizedResources.push(res.replace(/<br\s*\/?>/gi, '&lt;br&gt;'));
    }
  });

  const dataDetails = {'リソース': sanitizedResources};
  
  // 1. 能力値
  dataDetails['能力値'] = [];
  for (let i = 1; i <= (json.sttNum || 15); i++) {
    const name = json[`stt${i}Name`];
    const val  = json[`stt${i}Value`];
    // NameかValueのどちらかが未入力の場合は無視
    if (name && val !== '' && val != null) {
      dataDetails['能力値'].push(`        <data name="${name}">${val}</data>`);
    }
  }

  // 2. 戦闘値
  dataDetails['戦闘値'] = [];
  for (let i = 1; i <= (json.battleNum || 15); i++) {
    const name = json[`battle${i}Name`];
    const val  = json[`battle${i}Value`];
    if (name && val !== '' && val != null) {
      // 既にステータスバーや固定リソースとして個別出力されているもの（HP, FP等）は除外
      const isResource = sanitizedResources.some(res => res.includes(`name="${name}"`));
      if (!isResource) {
        dataDetails['戦闘値'].push(`        <data name="${name}">${val}</data>`);
      }
    }
  }

  // 3. 防御修正
  dataDetails['防御修正'] = [];
  for (let i = 1; i <= (json.defenseNum || 15); i++) {
    const name = json[`defense${i}Name`];
    const val  = json[`defense${i}Value`];
    if (name && val !== '' && val != null) {
      dataDetails['防御修正'].push(`        <data name="${name}">${val}</data>`);
    }
  }

  // 4. 攻撃方法（ネスト構造）
  dataDetails['攻撃方法'] = [];
  for (let r = 1; r <= (json.attackRowNum || 15); r++) {
    const atkName = json[`attackRow${r}Col1Value`];
    if (!atkName) continue; // 名称がなければスキップ
    
    // ツリーの親（基本的には名称）を作成
    let atkData = [`        <data name="${atkName}">`];
    for (let c = 2; c <= (json.attackColNum || 15); c++) {
      const header = json[`attackCol${c}Name`];
      const val    = json[`attackRow${r}Col${c}Value`];
      // 見出しと値が両方揃っている場合のみ子要素として追加
      if (header && val !== '' && val != null) {
        atkData.push(`          <data name="${header}">${val}</data>`);
      }
    }
    atkData.push(`        </data>`);
    dataDetails['攻撃方法'].push(atkData.join('\n'));
  }

  // 5. 特技（辞書引き＆抽出処理）
  dataDetails['特技'] = [];
  let allSkillText = json.skills || '';
  
  // extraareaのテキストも合算して特技をすべて拾い上げる
  let extraCount = Number(json.extraNum) || 0;
  if (!extraCount) {
    let i = 1;
    while (json[`extra${i}Name`] || json[`extra${i}Text`]) { extraCount = i; i++; }
  }
  for (let i = 1; i <= extraCount; i++) {
    if (json[`extra${i}Text`]) {
      allSkillText += '\n' + json[`extra${i}Text`];
    }
  }

  // 表記揺れ吸収関数（Perlの normalize_skill_name に相当）
  const normalizeSkillName = (str) => {
    return (str || '').replace(/\(/g, '（').replace(/\)/g, '）').replace(/:/g, '：');
  };

  // JS側に辞書データがエクスポートされていると仮定（無い場合は空オブジェクト）
  const skillDict = (typeof SET !== 'undefined' && SET.monsSkills && SET.monsSkills[json.system]) 
                    ? SET.monsSkills[json.system] : {};

  // 辞書のキーを解析可能な正規表現に変換（%num% や %txt% のプレースホルダ対応）
  const dictRegexes = [];
  for (let key in skillDict) {
    let normKey = normalizeSkillName(key);
    // 正規表現のメタ文字をエスケープ（% 以外）
    let regexStr = normKey.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    let placeholders = [];
    
    // プレースホルダの抽出
    const phRegex = /%([a-zA-Z0-9_]+)%/g;
    let match;
    while ((match = phRegex.exec(normKey)) !== null) {
      placeholders.push(`%${match[1]}%`);
    }
    
    // %num% は (\d+) に、それ以外は (.+?) に変換
    regexStr = regexStr.replace(/%([a-zA-Z0-9_]+)%/g, (m, p1) => {
      return p1.startsWith('num') ? '(\\d+)' : '(.+?)';
    });
    
    dictRegexes.push({
      key: key,
      regex: new RegExp(`^${regexStr}$`),
      placeholders: placeholders
    });
  }

  let skillSummaryMap = {};
  let extractedSkills = [];

  // ① 独自サマリの抽出 (>>)
  const customRegex = /(?:^|<br>|\n)\s*(?:>>|&gt;&gt;|＞＞)(《[^》]+》)(.*?)(?=<br>|\n|$)/g;
  let matchCustom;
  while ((matchCustom = customRegex.exec(allSkillText)) !== null) {
    let normMatch = normalizeSkillName(matchCustom[1]);
    let desc = matchCustom[2].trim();
    if (!skillSummaryMap[normMatch]) {
      extractedSkills.push({ name: normMatch, text: desc });
      skillSummaryMap[normMatch] = true;
    }
  }

  // ② 例外判定の抽出 (◆)
  const excludeRegex = /◆(《[^》]+》)/g;
  let matchExclude;
  while ((matchExclude = excludeRegex.exec(allSkillText)) !== null) {
    let normMatch = normalizeSkillName(matchExclude[1]);
    skillSummaryMap[normMatch] = true;
    extractedSkills.push({ name: normMatch, text: '' }); // 内容は空欄
  }

  // ③ 通常の特技の抽出
  const normalRegex = /(《[^》]+》)/g;
  let matchNormal;
  while ((matchNormal = normalRegex.exec(allSkillText)) !== null) {
    let normMatch = normalizeSkillName(matchNormal[1]);
    
    if (skillSummaryMap[normMatch]) continue; // 登録済みならスキップ
    
    let summaryText = "";
    
    // 辞書マッチング（プレースホルダへの値代入）
    for (let dictEntry of dictRegexes) {
      let execRes = dictEntry.regex.exec(normMatch);
      if (execRes) {
        summaryText = skillDict[dictEntry.key];
        let captures = execRes.slice(1);
        
        for (let i = 0; i < dictEntry.placeholders.length; i++) {
          let p = dictEntry.placeholders[i];
          let v = normalizeSkillName(captures[i] || '');
          summaryText = summaryText.split(p).join(v);
        }
        break;
      }
    }
    
    // ★保険: JS側に辞書(SET.monsSkills)が渡っていなかった場合のDOMスクレイピング
    if (!summaryText && typeof document !== 'undefined') {
      const clean = (str) => (str || '').replace(/[《》【】\[\]()（）]/g, '').replace(/[：:]/g, ':').replace(/\s+/g, '');
      const searchName = clean(normMatch);
      const headings = document.querySelectorAll('dt, th, td, summary, .name, .title, b, strong, span');
      
      for (let heading of headings) {
        if (clean(heading.textContent).includes(searchName)) {
          let content = "";
          let tagName = heading.tagName.toLowerCase();
          
          if (tagName === 'dt') {
            let next = heading.nextElementSibling;
            while (next && next.tagName.toLowerCase() !== 'dd' && next.tagName.toLowerCase() !== 'dt') next = next.nextElementSibling;
            if (next && next.tagName.toLowerCase() === 'dd') content = next.innerHTML;
          } else if (tagName === 'th' || tagName === 'td') {
            let next = heading.nextElementSibling;
            if (next && next.tagName.toLowerCase() === 'td') content = next.innerHTML;
          } else if (tagName === 'summary') {
            let parent = heading.parentElement;
            if (parent) {
              let clone = parent.cloneNode(true);
              let childSummary = clone.querySelector('summary');
              if (childSummary) childSummary.remove();
              content = clone.innerHTML;
            }
          } else {
            let next = heading.nextElementSibling;
            if (next && ['dd', 'td', 'p', 'div', 'span'].includes(next.tagName.toLowerCase())) {
              content = next.innerHTML;
            } else if (heading.parentElement) {
              content = heading.parentElement.innerHTML.replace(heading.outerHTML, '');
            }
          }
          
          if (content) {
            let tempDiv = document.createElement('div');
            tempDiv.innerHTML = content.replace(/<br\s*\/?>/gi, '\n').replace(/&lt;br&gt;/gi, '\n');
            summaryText = tempDiv.textContent.trim();
            if (summaryText) break;
          }
        }
      }
    }

    extractedSkills.push({ name: normMatch, text: summaryText || '' });
    skillSummaryMap[normMatch] = true;
  }

  // ④ ユドナリウム用XMLノードとして出力
  extractedSkills.forEach(skill => {
    let cleanText = skill.text.replace(/&lt;br&gt;/gi, '\n').replace(/<br\s*\/?>/gi, '\n');
    dataDetails['特技'].push(`        <data type="note" name="${skill.name}">${cleanText}</data>`);
  });

  // 6. 情報
  dataDetails['情報'] = [];
  
  // 基礎部 (base-list)
  for (let i = 1; i <= (json.baseNum || 15); i++) {
    const name = json[`base${i}Name`];
    const val  = json[`base${i}Value`];
    if (name && val !== '' && val != null) {
      dataDetails['情報'].push(`        <data name="${name}">${val}</data>`);
    }
  }
  
  // 分類 (taxa + subTaxa)
  let taxaText = json.taxa || '';
  if (json.subTaxa) {
    taxaText += `（${json.subTaxa}）`;
  }
  if (taxaText) {
    dataDetails['情報'].push(`        <data name="分類">${taxaText}</data>`);
  }

  if (memoData) {
    dataDetails['情報'].push(memoData);
  }

  // 解説とURL
  if (json.description) {
    dataDetails['情報'].push(`        <data type="note" name="説明">${json.description.replace(/&lt;br&gt;/g, '\n').replace(/<br\s*\/?>/gi, '\n')}</data>`);
  }
  if (opt_url) {
    dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);
  }

  return dataDetails;
};