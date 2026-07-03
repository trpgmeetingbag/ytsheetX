"use strict";

var output = output || {};

// 能力値の整形（基本値 / ボーナス）
output._convertMgrStatus = (json, s) => {
  const base  = String(json[`sttTotal${s.column}`]  || '0').padStart(2, ' ');
  const bonus = String(json[`sttBonus${s.column}`] || '0').padStart(2, ' ');
  return `【${s.name}】 ${base} / ${bonus}`;
};

// 武装一覧の取得（全データ対応版）
output._getMgrArmamentsFull = (json) => {
  const data = [];
  const num = Number(json.armamentsNum) || 0;
  for (let i = 1; i <= num; i++) {
    if (!json[`armament${i}Name`]) continue;
    data.push({
      type: json[`armament${i}Part`] || '',
      name: json[`armament${i}Name`],
      acc: json[`armament${i}Meichu`] || '0',
      atk: json[`armament${i}Kougeki`] || '0',
      eva: json[`armament${i}Kaihi`] || '0',
      def: json[`armament${i}Bouheki`] || '0',
      ini: json[`armament${i}Koudou`] || '0',
      move: json[`armament${i}Idou`] || '0',
      zokusei: json[`armament${i}Zokusei`] || '',
      range: json[`armament${i}Shatei`] || '',
      cost: json[`armament${i}Daishou`] || '',
      ammo: json[`armament${i}Danzuu`] || '',
      cano: json[`armament${i}Hougeki`] || '',
      rikiba: json[`armament${i}Rikiba`] || '',
      taikyu: json[`armament${i}Taikyu`] || '',
      kannou: json[`armament${i}Kannou`] || '',
      syubetu: json[`armamentNoteAuto${i}Type`] || '',
      joubi: json[`armament${i}Joubi`] || '',


      note: (json[`armamentNoteAuto${i}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
  }
  return data;
};

output._getMgrDefenseFull = (json) => {
  const data = [];
  const num = Number(json.armamentsNum) || 0;
  for (let i = 1; i <= num; i++) {
    if (!json[`armament${i}Name`]) continue;
    data.push({
      type: json[`armament${i}Part`] || '',
      name: json[`armament${i}Name`],


      note: (json[`armament${i}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
  }
  return data;
};

// 防御修正とサイズ、種別の一覧を取得
output._getMgrDefenseFull = (json) => {
  const data = [];
  
  // 1. 自動生成の防御修正（defenceAuto～）を収集
  const armNum = Number(json.armamentsNum) || 0;
  for (let i = 1; i <= armNum; i++) {
    // 名前がない行はスキップ
    if (!json[`defenceAuto${i}Name`]) continue;

    data.push({
      type: json[`defenceAuto${i}Part`] || '',
      name: json[`defenceAuto${i}Name`] || '',
      zan: json[`defenceAuto${i}Zan`] || '0',
      totsu: json[`defenceAuto${i}Totsu`] || '0',
      ou: json[`defenceAuto${i}Ou`] || '0',
      en: json[`defenceAuto${i}En`] || '0',
      hyou: json[`defenceAuto${i}Hyou`] || '0',
      rai: json[`defenceAuto${i}Rai`] || '0',
      kou: json[`defenceAuto${i}Kou`] || '0',
      yami: json[`defenceAuto${i}Yami`] || '0',
      size: json[`defenceAuto${i}Size`] || '-', // 空欄ならハイフン
    });
  }

  // 2. 手動追加の防御修正（defence～）を収集
  const defNum = Number(json.defencesNum) || 0;
  for (let i = 1; i <= defNum; i++) {
    // 名前がない行はスキップ
    if (!json[`defence${i}Name`]) continue;

    data.push({
      type: json[`defence${i}Part`] || '',
      name: json[`defence${i}Name`] || '',
      zan: json[`defence${i}Zan`] || '0',
      totsu: json[`defence${i}Totsu`] || '0',
      ou: json[`defence${i}Ou`] || '0',
      en: json[`defence${i}En`] || '0',
      hyou: json[`defence${i}Hyou`] || '0',
      rai: json[`defence${i}Rai`] || '0',
      kou: json[`defence${i}Kou`] || '0',
      yami: json[`defence${i}Yami`] || '0',
      size: json[`defence${i}Size`] || '-',
    });
  }

  return data;
};

// 加護の一覧を取得
output._getMgrKagos = (json) => {
  const data = [];
  const num = Number(json.kagosNum) || 0;
  for (let i = 1; i <= num; i++) {
    if (!json[`kago${i}Name`]) continue;
    data.push({
      name: json[`kago${i}Name`],
      note: (json[`kago${i}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
  }
  return data;
};

// アイテム（ライフスタイル、住宅、一般アイテム）の一覧を取得
output._getMgrItems = (json) => {
  const data = [];
  
  // 1. ライフスタイル
  const lsNum = Number(json.lifestylesNum) || 0;
  for (let i = 1; i <= lsNum; i++) {
    if (!json[`lifestyle${i}Name`]) continue;
    data.push({
      type: 'ライフスタイル',
      name: json[`lifestyle${i}Name`],
      joubika: json[`lifestyle${i}Joubika`] || '0',
      property: json[`lifestyle${i}Property`] || '-', // 財産P
      timing: json[`lifestyle${i}Timing`] || '-',
      note: (json[`lifestyle${i}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
  }

  // 2. 住宅
  const hsNum = Number(json.housesNum) || 0;
  for (let i = 1; i <= hsNum; i++) {
    if (!json[`house${i}Name`]) continue;
    data.push({
      type: '住宅',
      name: json[`house${i}Name`],
      joubika: json[`house${i}Joubika`] || '0',
      property: '-', // 住宅に財産Pはない
      timing: json[`house${i}Timing`] || '-',
      note: (json[`house${i}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
  }

  // 3. 一般アイテム
  const itNum = Number(json.itemsNum) || 0;
  for (let i = 1; i <= itNum; i++) {
    if (!json[`item${i}Name`]) continue;
    data.push({
      type: 'アイテム',
      name: json[`item${i}Name`],
      joubika: json[`item${i}Joubika`] || '0',
      property: '-',
      timing: json[`item${i}Timing`] || '-',
      note: (json[`item${i}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
  }

  return data;
};

// メイン出力関数
output.generateCharacterTextOfArianrhod2PC = (json) => {
  const result = [];

  // 1. 基本情報
  result.push(`キャラクター名：${json.characterName || ''}
年齢：${json.age || ''}
性別：${json.gender || ''}
カバー：${json.cover || ''}
機体名：${json.mechaName || ''}`);
  result.push('');

  // 2. クラス情報（レベル併記）
  result.push('■クラス■');
  for (let i = 1; i <= (json.classesNum || 3); i++) {
    if (json[`class${i}Name`]) {
      result.push(`${json[`class${i}Name`]} Lv.${json[`class${i}Lv`] || 1}`);
    }
  }
  result.push('');

  // 3. 能力値（基本値 / ボーナス）
  result.push('■能力値■');
  output.consts.MGR_STATUS.forEach((s) => {
    result.push(output._convertMgrStatus(json, s));
  });
  result.push('');

  // 4. 未装備小計（命中・回避・砲撃・防壁・力場・耐久・感応・行動・移動・攻撃）
  result.push('■未装備小計■');
  result.push(`命中：${json.battleSubtotalMeichu || 0}　回避：${json.battleSubtotalKaihi || 0}　砲撃：${json.battleSubtotalHougeki || 0}　防壁：${json.battleSubtotalBouheki || 0}`);
  result.push(`力場：${json.battleSubtotalRikiba || 0}　耐久：${json.battleSubtotalTaikyu || 0}　感応：${json.battleSubtotalKannou || 0}　行動：${json.battleSubtotalKoudou || 0}`);
  result.push(`移動：${json.battleSubtotalIdou || 0}　攻撃：${json.battleSubtotalKougeki || 0}`);
  result.push('');


  // 5. 武装・装備品・機体データ
  result.push('■武装・装備品・機体データ■');
  const armData = output._getMgrArmamentsFull(json);
  const armCols = {
    type: '部位', name: '名称', acc: '命中', eva: '回避', cano: '砲撃', def: '防壁',
    ini: '行動', rikiba: '力場', taikyu: '耐久', kannou: '感応', move: '移動', 
    zokusei: '属性', atk: '攻撃', range: '射程', cost: '代償', ammo: '弾数', joubi: '常備', syubetu: '種別', note: '備考'
  };
  result.push(output._convertList(armData, armCols, ' / '));
  result.push('');

  result.push('■防御修正とサイズ■');
  const defData = output._getMgrDefenseFull(json);
  const defCols = {
    type: '部位', name: '名称',
    zan: '斬', totsu: '刺', ou: '殴', en: '炎', hyou: '氷', rai: '雷', kou: '光', yami: '闇', 
    size: 'サイズ'
  };
  result.push(output._convertList(defData, defCols, ' / '));
  result.push('');

  
  // 加護
  result.push('■加護■');
  const kagoData = output._getMgrKagos(json);
  const kagoCols = { name: '名称', note: '効果' };
  result.push(output._convertList(kagoData, kagoCols, ' / '));
  result.push('');

  // 6. 特技
  result.push('■特技■');
  let skillCursor = 1;
  const skillData = [];
  while(json[`skill${skillCursor}Name`]) {
    skillData.push({
      name: '《' + json[`skill${skillCursor}Name`] + '》',
      level: json[`skill${skillCursor}Lv`] || '1',
      timing: json[`skill${skillCursor}Timing`] || '',
      target: json[`skill${skillCursor}Target`] || '',
      range: json[`skill${skillCursor}Range`] || '',
      cost: json[`skill${skillCursor}Cost`] || '',
      note: (json[`skill${skillCursor}Note`] || '').replace(/&lt;br&gt;|<br>/g, ' ')
    });
    skillCursor++;
  }
  const skillCols = { name: '名称', level: 'Lv', timing: 'タイミング', target: '対象', range: '射程', cost: '代償', note: '効果' };
  result.push(output._convertList(skillData, skillCols, ' / '));
  result.push('');



  // アイテム・ライフスタイル・住宅
  result.push('■アイテム・所持品■');
  const itemData = output._getMgrItems(json);
  // 種別ごとに項目を整理して出力
  const itemCols = { 
    type: '種別', name: '名称', joubika: '常備化', 
    property: '財産P', timing: 'タイミング', note: '解説' 
  };
  result.push(output._convertList(itemData, itemCols, ' / '));
  
  // 常備化ポイントの計算結果も併記すると親切です
  const joubikaMax = json.joubikaMax || 0;
  const joubikaRest = json.joubikaRest || 0;
  result.push(`常備化ポイント：残り ${joubikaRest} / 最大 ${joubikaMax}`);
  result.push('');


  // 8. 経験点
  result.push('■経験点■');
  result.push(`合計経験点：${json.expTotal || 0}`);
  result.push(`消費経験点：${json.expUsed || 0}`);
  result.push(`残り経験点：${json.expRest || 0}`);
  result.push('');

  // 9. その他・メモ
  result.push('■その他・メモ■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;|<br>/gm, '\n').replace(/&quot;/gm, '"'));
  
  return result.join('\n');
};