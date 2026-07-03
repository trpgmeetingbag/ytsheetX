"use strict";
const gameSystem = 'nechronica';

let status = {};
let exps = {};

// ----------------------------------------
window.onload = function () {
  console.log('=====START=====');

  setName();

  // ネクロニカ用クラス・ステータス初期計算
  changeClass();

  initInsanity();
  
  // 未練の取得先セレクトボックスの初期化
  updateAllMirenNoteSelects();

  // すべてのスキルの取得先と背景色を初期化
  updateAllSkillSourceSelects();
  calcSkillCategory();

  changePlacement(); // 初期配置の表示切替初期化

  imagePosition();
  changeColor();
  calcExp();
  console.log('=====LOADED=====');

};

// 送信前チェック ----------------------------------------
function formCheck() {
  if (form.characterName.value === '' && form.aka.value === '') {
    alert('キャラクター名かコードネームのいずれかを入力してください。');
    return false;
  }
  return true;
}

function checkCreateType() {
  if(form.createType) {
    document.body.dataset.createType = createType = form.createType.value;
  }
}

function changeRegu() {	
const elm = document.getElementById("history0-exp");	
if (elm) elm.textContent = form.history0Exp.value;	
calcExp();	
}

// クラス変更（ネクロニカ専用処理） ----------------------------------------
function changeClass() {
  const position = form.position ? form.position.value : '';
  const mainClass = form.mainClass ? form.mainClass.value : '';
  const subClass = form.subClass ? form.subClass.value : '';

  // 自由記入のテキストボックスの表示切替
  if (form.positionFree) form.positionFree.style.display = (position === 'free') ? 'inline-block' : 'none';
  if (form.mainClassFree) form.mainClassFree.style.display = (mainClass === 'free') ? 'inline-block' : 'none';
  if (form.subClassFree) form.subClassFree.style.display = (subClass === 'free') ? 'inline-block' : 'none';

  calcStt();
  updateAllSkillSourceSelects();
}

// ステータス（武装・変異・改造）計算 ----------------------------------------
function calcStt() {
  const mainClass = form.mainClass ? form.mainClass.value : '';
  const subClass = form.subClass ? form.subClass.value : '';

  const stts = ['Buso', 'HenI', 'Kaizo'];
  const sttKeys = ['buso', 'heni', 'kaizo'];

  let totalGrow = 0;

  // メインクラスの自動入力とReadonly制御
  for (let i = 0; i < 3; i++) {
    const input = form['main' + stts[i]];
    if (!input) continue;

    if (mainClass === 'free') {
      input.readOnly = false;
    } else if (classStats[mainClass]) {
      input.value = classStats[mainClass][sttKeys[i]];
      input.readOnly = true;
    } else {
      input.value = '';
      input.readOnly = true;
    }
  }

  // サブクラスの自動入力とReadonly制御
  for (let i = 0; i < 3; i++) {
    const input = form['sub' + stts[i]];
    if (!input) continue;

    if (subClass === 'free') {
      input.readOnly = false;
    } else if (classStats[subClass]) {
      input.value = classStats[subClass][sttKeys[i]];
      input.readOnly = true;
    } else {
      input.value = '';
      input.readOnly = true;
    }
  }

  // 合計値の計算
  for (let i = 0; i < 3; i++) {
    const mainVal = Number(form['main' + stts[i]] ? form['main' + stts[i]].value : 0) || 0;
    const subVal = Number(form['sub' + stts[i]] ? form['sub' + stts[i]].value : 0) || 0;
    const growVal = Number(form['grow' + stts[i]] ? form['grow' + stts[i]].value : 0) || 0;
    const addVal = Number(form['add' + stts[i]] ? form['add' + stts[i]].value : 0) || 0;

    // ラジオボタンの選択状態を取得
    const preVal = (form.sttPre && form.sttPre.value === sttKeys[i]) ? 1 : 0;

    totalGrow += growVal;

    const total = mainVal + subVal + preVal + growVal + addVal;

    // 合計値の表示（10以上で赤文字警告）
    const totalElm = document.getElementById('stt-total-' + sttKeys[i]);
    if (totalElm) {
      totalElm.textContent = total;
      if (total >= 10) {
        totalElm.style.color = '#e33';
        totalElm.style.fontWeight = 'bold';
      } else {
        totalElm.style.color = '';
        totalElm.style.fontWeight = '';
      }
    }

    // 計算結果をグローバルに保持
    status[sttKeys[i]] = total;
  }

  // クラス・強化値成長にかかる消費寵愛点（×10）を反映
  exps['status'] = totalGrow * 10;
  const expStatusElm = document.getElementById('exp-status');
  if(expStatusElm) expStatusElm.textContent = exps['status'];

  calcSubStt();
  if (typeof calcExp === 'function') calcExp();
}

// サブステータス (行動値) & パーツ枠上限計算
function calcSubStt() {
  let skillInitiative = 0;

  // スキル（マニューバ）からの行動値加算
  const num = Number(form.skillNum ? form.skillNum.value : 0);
  for (let i = 1; i <= num; i++) {
    if (form[`skill${i}CalcOff`] && form[`skill${i}CalcOff`].checked) continue;
    if (form[`skill${i}Damage`] && form[`skill${i}Damage`].checked) continue; // 破損時は加算しない

    const val = Number(form[`skill${i}Initiative`] ? form[`skill${i}Initiative`].value : 0);
    skillInitiative += val;
  }

  let maxInitiative = 6 + skillInitiative;
  if (maxInitiative < 0) maxInitiative = 0; // マイナスにはならない

  const sumElm = document.getElementById('skill-initiative-total');
  if (sumElm) sumElm.textContent = skillInitiative;

  const maxElm = document.getElementById('initiative-total');
  if (maxElm) maxElm.textContent = maxInitiative;
  
  // パーツ上限計算へ
  calcPartsStatus();
  
  // スキル取得にかかる消費寵愛点計算へ
  calcSkillExp();
}

// スキル取得にかかる寵愛点計算 ----------------------------------------
function calcSkillExp() {
  let countClass = 0;
  let countOther = 0;

  const pos = form.position ? form.position.value : '';
  const mc = form.mainClass ? form.mainClass.value : '';
  const sc = form.subClass ? form.subClass.value : '';
  
  // 自由記入の場合の実際のクラス名を抽出
  const posVal = (pos === 'free' && form.positionFree) ? form.positionFree.value : pos;
  const mcVal = (mc === 'free' && form.mainClassFree) ? form.mainClassFree.value : mc;
  const scVal = (sc === 'free' && form.subClassFree) ? form.subClassFree.value : sc;

  // 現在のクラスとして有効な名前リストを作成
  const validClasses = [posVal, mcVal, scVal].filter(c => c);

  // 無視する取得先
  const ignoreSources = ['武装', '変異', '改造', '基本パーツ'];

  // フォームから現在のスキル・パーツの総数を取得してループ
  const num = Number(form.skillNum ? form.skillNum.value : 0);
  for (let i = 1; i <= num; i++) {
    // 所属枠が "skill" のもののみ計算対象とする
    const posInput = form[`skill${i}Position`];
    if (!posInput || posInput.value !== 'skill') continue;

    // 計算に含まない場合は除外
    if (form[`skill${i}CalcOff`] && form[`skill${i}CalcOff`].checked) continue;

    const sourceSelect = form[`skill${i}Source`];
    const sourceFree = form[`skill${i}SourceFree`];
    if (!sourceSelect) continue;

    // 実際の取得先文字列を判定
    const source = (sourceSelect.value === 'free' && sourceFree) ? sourceFree.value : sourceSelect.value;
    
    // 未選択や無視リストのものは除外
    if (!source || ignoreSources.includes(source)) continue;

    if (validClasses.includes(source)) {
      countClass++; // クラスに一致
    } else {
      countOther++; // それ以外
    }
  }

  // 寵愛点の算出（クラス一致10点、その他20点、初期獲得枠として40点マイナス）
  const expClass = countClass * 10 - 40;
  const expOther = countOther * 20;
  const totalExp = expClass + expOther;

  exps['skillClassCount'] = countClass;
  exps['skillOtherCount'] = countOther;
  exps['skillClassExp'] = expClass;
  exps['skillOtherExp'] = expOther;
  exps['skill'] = totalExp;

  const elm = document.getElementById('exp-skill');
  if (elm) elm.textContent = totalExp;
  
  if (typeof calcExp === 'function') calcExp();
}

// 強化パーツの枠と取得状況の計算 ----------------------------------------
function validateParts(acquiredLevels, availableSlots) {
  // 小さい順にソートしておく（後で大きい方から消費するため逆から回す）
  let slots = [...availableSlots].sort((a, b) => a - b);
  let acquired = [...acquiredLevels].sort((a, b) => b - a); // 取得パーツは大きい順
  
  let result = [];
  
  for (let acqLv of acquired) {
    let matchIdx = -1;
    
    // 強化パーツの場合、acqLv 以上の最小の枠を探す
    for (let i = 0; i < slots.length; i++) {
      if (slots[i] >= acqLv) {
        matchIdx = i;
        break;
      }
    }
    
    if (matchIdx !== -1) {
      slots.splice(matchIdx, 1);
      result.push({ level: acqLv, error: false }); // 収容成功
    } else {
      result.push({ level: acqLv, error: true });  // 収容失敗（赤文字）
    }
  }
  
  // 表示用に見栄え良く昇順ソートして返す
  return result.sort((a, b) => a.level - b.level);
}

function calcPartsStatus() {
  const categories = [
    { id: 'buso', name: '武装', label: 'Buso' },
    { id: 'heni', name: '変異', label: 'HenI' },
    { id: 'kaizo', name: '改造', label: 'Kaizo' }
  ];

  categories.forEach(cat => {
    // 強化値の取得
    const sttValue = status[cat.id] || 0;
    
    let availableSlots = [];
    
    // ▼ データ構造が渡ってきている場合はそれを使用し、なければ自動計算する
    if (typeof ncPartsLevel !== 'undefined' && ncPartsLevel[sttValue]) {
      const counts = ncPartsLevel[sttValue];
      for (let i = 0; i < (counts[0] || 0); i++) availableSlots.push(1);
      for (let i = 0; i < (counts[1] || 0); i++) availableSlots.push(2);
      for (let i = 0; i < (counts[2] || 0); i++) availableSlots.push(3);
    } else {
      // 枠の自動生成 (例: 強化値4なら [1, 1, 2, 3] を生成)
      for (let i = 1; i <= sttValue; i++) {
        availableSlots.push((i - 1) % 3 + 1);
      }
    }
    availableSlots.sort((a, b) => a - b);
    
    // 実際に取得しているパーツのレベルを収集
    let acquiredLevels = [];
    const num = Number(form.skillNum ? form.skillNum.value : 0);
    for (let i = 1; i <= num; i++) {
      if (form[`skill${i}CalcOff`] && form[`skill${i}CalcOff`].checked) continue;
      
      const sourceSelect = form[`skill${i}Source`];
      const sourceFree = form[`skill${i}SourceFree`];
      if (!sourceSelect) continue;
      
      // 取得先の判定
      const source = (sourceSelect.value === 'free' && sourceFree) ? sourceFree.value : sourceSelect.value;
      if (source === cat.name) {
        const lvInput = form[`skill${i}Lv`];
        let lv = 0;
        if (lvInput && lvInput.value) {
          lv = Number(lvInput.value);
        }
        // レベル未入力(0)は基本パーツ扱いとし、強化パーツの計算から除外する
        if (lv > 0) {
          acquiredLevels.push(lv);
        }
      }
    }
    
    // 上限オーバーの判定
    const result = validateParts(acquiredLevels, availableSlots);
    
    // 表示用文字列の生成
    const toCircle = (n) => {
      const c = ['⓪','①','②','③','④','⑤','⑥','⑦','⑧','⑨','⑩'];
      return c[n] || `(${n})`;
    };
    
    const availableStr = availableSlots.map(toCircle).join('');
    const acquiredHtml = result.map(r => {
      if (r.error) {
        return `<span class="part-status-error">${toCircle(r.level)}</span>`;
      }
      return toCircle(r.level);
    }).join('');
    
    // ▼ ここから変更：ゆとシート標準の data-table 構造で出力する
    const container = document.getElementById(`parts-status-${cat.id}`);
    if (container) {
      container.innerHTML = `
        <table class="data-table">
          <thead>
            <tr><th colspan="2">${cat.name}(${sttValue})</th></tr>
          </thead>
          <tbody>
            <tr><th>取得可能枠</th><td>${availableStr || 'なし'}</td></tr>
            <tr><th>取得状況</th><td>${acquiredHtml || 'なし'}</td></tr>
          </tbody>
        </table>
      `;
    }
  });
}

// 初期配置 ----------------------------------------
function changePlacement() {
  if (!form.placement) return;
  const placement = form.placement.value;
  if (form.placementFree) {
    form.placementFree.style.display = (placement === 'free') ? 'inline-block' : 'none';
  }
}

// 狂気点ゲージ ----------------------------------------
function setInsanity(elm, value) {
  const container = elm.parentNode;
  const targetName = container.dataset.target;
  const hiddenInput = form[targetName];
  if (hiddenInput) {
    hiddenInput.value = value;
  }
  updateInsanityGauge(container, value);
}

function updateInsanityGauge(container, value) {
  const dots = container.querySelectorAll('.dot:not(.reset)');
  dots.forEach((dot, index) => {
    if (index < value) {
      dot.classList.add('active');
      dot.textContent = '●';
    } else {
      dot.classList.remove('active');
      dot.textContent = ['①', '②', '③', '④'][index];
    }
  });
}

function initInsanity() {
  document.querySelectorAll('.insanity-gauge').forEach(container => {
    const targetName = container.dataset.target;
    const hiddenInput = form[targetName];
    if (hiddenInput) {
      updateInsanityGauge(container, Number(hiddenInput.value) || 0);
    }
  });
}

// 未練欄 ----------------------------------------
function updateAllMirenNoteSelects() {
  const selects = document.querySelectorAll('#miren-table select[name$="Note"]');
  selects.forEach(select => {
    updateMirenNoteOptions(select);
  });
}

function updateMirenNoteOptions(select) {
  if (!select) return;
  const numMatch = select.name.match(/\d+/);
  if (!numMatch) return;
  const num = numMatch[0];

  const row = select.closest('tr');
  if (!row) return;
  const freeInput = row.querySelector(`[name="miren${num}NoteFree"]`);

  const currentVal = select.value;
  const freeVal = freeInput ? freeInput.value : '';
  const actualVal = (currentVal === 'free' && freeVal) ? freeVal : currentVal;

  let sources = [
    { value: '', text: '未選択' }
  ];

  if (typeof ncMiren !== 'undefined') {
    for (const key in ncMiren) {
      sources.push({ value: key, text: key });
    }
  }
  sources.push({ value: 'free', text: 'その他（自由記入）' });

  select.innerHTML = '';
  sources.forEach(src => {
    const option = document.createElement('option');
    option.value = src.value;
    option.textContent = src.text;
    select.appendChild(option);
  });

  if (actualVal && !sources.some(src => src.value === actualVal)) {
    select.value = 'free';
    if (freeInput) {
      freeInput.value = actualVal;
      freeInput.style.display = 'inline-block';
    }
  } else {
    select.value = actualVal;
    if (freeInput) {
      freeInput.style.display = 'none';
    }
  }
}

function changeMirenNote(select) {
  const numMatch = select.name.match(/\d+/);
  if (!numMatch) return;
  const num = numMatch[0];

  const row = select.closest('tr');
  if (!row) return;
  const freeInput = row.querySelector(`[name="miren${num}NoteFree"]`);
  const burstInput = form[`miren${num}Burst`];

  if (freeInput) {
    freeInput.style.display = (select.value === 'free') ? 'inline-block' : 'none';
  }

  if (select.value !== 'free' && select.value !== '') {
    // ★追加：選択中の <option> に発狂内容が埋め込まれていれば、それを優先する
    const opt = select.options[select.selectedIndex];
    if (opt && opt.dataset.burst && burstInput) {
      burstInput.value = opt.dataset.burst;
    } 
    // ▼ 以下は元のコードのまま（古いデータ等のフォールバックとして安全に機能します）
    else if (typeof ncMiren !== 'undefined' && ncMiren[select.value] && burstInput) {
      burstInput.value = ncMiren[select.value];
    }
  }
}


function addMiren() {
  const t = document.querySelector("#miren-table tbody");
  if (t) t.append(createRow('miren', 'mirenNum'));
  updateAllMirenNoteSelects();
}
function delMiren() {
  delRow('mirenNum', '#miren-table tbody tr:last-of-type');
}
setSortable('miren', '#miren-table tbody', 'tr', (row, num) => {
  const container = row.querySelector('.insanity-gauge');
  if (container) {
    container.dataset.target = `miren${num}Insanity`;
    updateInsanityGauge(container, Number(form[`miren${num}Insanity`].value) || 0);
  }
});

// 記憶のカケラ欄 ----------------------------------------
function addMemory() {
  const t = document.querySelector("#memory-table tbody");
  if (t) t.append(createRow('memory', 'memoryNum'));
}
function delMemory() {
  delRow('memoryNum', '#memory-table tbody tr:last-of-type');
}
setSortable('memory', '#memory-table tbody', 'tr');

// カルマ欄 ----------------------------------------
function addKarma() {
  const tbody = document.querySelector("#karma-table");
  if (tbody) tbody.append(createRow('karma', 'karmaNum'));
}
function delKarma() {
  delRow('karmaNum', '#karma-table tbody:last-of-type');
}
setSortable('karma', '#karma-table', 'tbody');

// スキル・パーツ共通欄（マニューバ） ----------------------------------------

function updateAllSkillSourceSelects() {
  const tbodies = document.querySelectorAll('.skill-area tbody:not(template), .part-area tbody:not(template)');
  tbodies.forEach(row => {
    const select = row.querySelector('select[name$="Source"]');
    const posInput = row.querySelector('input[name$="Position"]');
    if (select && posInput) {
      updateSourceSelectOptions(select, posInput.value);
    }
  });
}

function updateSourceSelectOptions(select, containerPosition) {
  if (!select) return;
  const numMatch = select.name.match(/\d+/);
  if (!numMatch) return;
  const num = numMatch[0];

  const row = select.closest('tbody');
  if (!row) return;
  const freeInput = row.querySelector(`[name="skill${num}SourceFree"]`);

  const currentVal = select.value;
  const freeVal = freeInput ? freeInput.value : '';
  const actualVal = (currentVal === 'free' && freeVal) ? freeVal : currentVal;

  let sources = [
    { value: '', text: '未選択' }
  ];

  if (containerPosition === 'skill') {
    const pos = form.position ? form.position.value : '';
    const mc = form.mainClass ? form.mainClass.value : '';
    const sc = form.subClass ? form.subClass.value : '';
    if (pos && pos !== 'free') sources.push({ value: pos, text: pos });
    if (mc && mc !== 'free') sources.push({ value: mc, text: mc });
    if (sc && sc !== 'free') sources.push({ value: sc, text: sc });
  } else {
    sources.push({ value: '基本パーツ', text: '基本パーツ' });
    sources.push({ value: '武装', text: '武装' });
    sources.push({ value: '変異', text: '変異' });
    sources.push({ value: '改造', text: '改造' });
    sources.push({ value: 'たからもの', text: 'たからもの' });
  }
  sources.push({ value: 'free', text: 'その他（自由記入）' });

  select.innerHTML = '';
  sources.forEach(src => {
    const option = document.createElement('option');
    option.value = src.value;
    option.textContent = src.text;
    select.appendChild(option);
  });

  if (actualVal && !sources.some(src => src.value === actualVal)) {
    select.value = 'free';
    if (freeInput) {
      freeInput.value = actualVal;
      freeInput.style.display = 'inline-block';
    }
  } else {
    select.value = actualVal;
    if (freeInput) {
      freeInput.style.display = 'none';
    }
  }
}

function changeSkillSource(select) {
  const numMatch = select.name.match(/\d+/);
  if (!numMatch) return;
  const num = numMatch[0];

  const row = select.closest('tbody');
  if (!row) return;
  const freeInput = row.querySelector(`[name="skill${num}SourceFree"]`);

  if (freeInput) {
    freeInput.style.display = (select.value === 'free') ? 'inline-block' : 'none';
  }
  
  calcSubStt(); // 取得先が変わった時もパーツ再計算を走らせる
}

function calcSkillCategory() {
  const tbodies = document.querySelectorAll('.skill-area tbody:not(template), .part-area tbody:not(template)');

  tbodies.forEach(row => {
    const catSelect = row.querySelector('select[name$="Category"]');
    const catFree = row.querySelector('input[name$="CategoryFree"]');
    if (!catSelect) return;

    if (catFree) {
      catFree.style.display = (catSelect.value === 'free') ? 'inline-block' : 'none';
    }

    const cat = (catSelect.value === 'free' && catFree) ? catFree.value : catSelect.value;

    let color = '';

    if (cat === '通常技') color = 'rgba(  0, 168,   0, 0.4)'; // 暗緑
    else if (cat === '必殺技') color = 'rgba(139,   0,   0, 0.4)'; // 暗赤
    else if (cat === '行動値増加') color = 'rgba(218, 165,  32, 0.4)'; // ゴールデンロッド（オレンジ系）
    else if (cat === '補助') color = 'rgba(123, 104, 238, 0.4)'; // ミディアムスレートブルー（青紫）
    else if (cat === '妨害') color = 'rgba(240, 128, 128, 0.4)'; // ライトコーラル（赤紫系）
    else if (cat.match(/^防御.生贄$/)) color = 'rgba(186,  85, 211, 0.4)'; // ミディアムオーキッド（紫）
    else if (cat === '移動') color = 'rgba(189, 183, 107, 0.4)'; // ダークカーキ（暗い黄色）

    if (color) {
      row.style.backgroundImage = `linear-gradient(to right, ${color}, transparent)`;
      row.classList.add('is-colored'); // 色が付いた目印を追加
    } else {
      row.style.backgroundImage = '';
      row.classList.remove('is-colored'); // 目印を削除
    }
  });
}

// マニューバ（スキル・パーツ）の追加
function addManeuver(position) {
  const tableId = position === 'skill' ? 'skill-table' : `part-${position}-table`;
  const t = document.querySelector(`#${tableId}`);
  if (t) {
    const row = createRow('skill', 'skillNum');
    const posInput = row.querySelector('[name$="Position"]');
    if (posInput) posInput.value = position;
    t.append(row);
  }
  skillSortAfter();
}

// マニューバ（スキル・パーツ）の削除
function delManeuver(position) {
  const tableId = position === 'skill' ? 'skill-table' : `part-${position}-table`;
  const target = document.querySelector(`#${tableId} tbody:not(template):last-of-type`);
  if (target) {
    target.remove();
    skillSortAfter();
  }
}

// ソート（全5枠連結）
(() => {
  const skillSortGroup = "skill";
  const tables = [
    'skill-table',
    'part-head-table',
    'part-arms-table',
    'part-torso-table',
    'part-legs-table'
  ];

  let sortables = [];
  tables.forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      sortables.push(Sortable.create(el, {
        group: skillSortGroup,
        dataIdAttr: 'id',
        animation: 150,
        handle: '.handle',
        filter: 'thead,tfoot,template',
        onSort: function (evt) { skillSortAfter(); },
        onStart: function (evt) {
          document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
          document.getElementById('skill-trash').style.display = 'block';
        },
        onEnd: function (evt) {
          if (!skillTrashNum) { document.getElementById('skill-trash').style.display = 'none' }
        },
      }));
    }
  });

  const trashT = document.getElementById('skill-trash-table');
  if (trashT) {
    Sortable.create(trashT, {
      group: skillSortGroup,
      dataIdAttr: 'id',
      animation: 150,
      filter: 'thead,tfoot,template',
    });
  }
})();

let skillTrashNum = 0;

function skillSortAfter() {
  let num = 1;
  const containers = [
    document.getElementById('skill-table'),
    document.getElementById('part-head-table'),
    document.getElementById('part-arms-table'),
    document.getElementById('part-torso-table'),
    document.getElementById('part-legs-table')
  ];

  containers.forEach(container => {
    if (!container) return;
    const position = container.dataset.position;

    const tbodies = container.querySelectorAll('tbody:not(template)');
    tbodies.forEach(row => {
      if (row.id.startsWith('skill-row') || row.id.startsWith('Trash')) {
        replaceSortedNames(row, num, /^(skill)(?:Trash)?[0-9]+(.+)$/);

        const posInput = row.querySelector(`[name="skill${num}Position"]`);
        if (posInput) posInput.value = position;

        const selectSource = row.querySelector(`[name="skill${num}Source"]`);
        if (selectSource) {
          selectSource.setAttribute('onchange', 'changeSkillSource(this)');
          updateSourceSelectOptions(selectSource, position);
        }

        const selectCat = row.querySelector(`[name="skill${num}Category"]`);
        if (selectCat) selectCat.setAttribute('onchange', 'calcSkillCategory()');

        const freeCat = row.querySelector(`[name="skill${num}CategoryFree"]`);
        if (freeCat) freeCat.setAttribute('oninput', 'calcSkillCategory()');

        num++;
      }
    });
  });

  form.skillNum.value = num - 1;

  let del = 0;
  const trashtable = document.getElementById('skill-trash-table');
  if (trashtable) {
    trashtable.querySelectorAll('tbody:not(template)').forEach(row => {
      del++;
      replaceSortedNames(row, 'Trash' + del, /^(skill)(?:Trash)?[0-9]+(.+)$/);
    });
  }
  skillTrashNum = del;
  if (!del) { document.getElementById('skill-trash').style.display = 'none' }

  calcSubStt();
  calcSkillCategory();
}

// 履歴欄 ----------------------------------------
function addHistory() {
  const t = document.querySelector("#history-table tfoot");
  if (t) t.before(createRow('history', 'historyNum'));
}
function delHistory() {
  delRow('historyNum', '#history-table tbody:last-of-type');
}
setSortable('history', '#history-table', 'tbody');

// 経験点（寵愛点）の計算処理
function calcExp() {
  let total = Number(form['history0Exp'] ? form['history0Exp'].value : 0) || 0;

  let totalMiren = 0;
  let totalInsanity = 0;
  let totalBase = 0;
  let totalEnhanced = 0;

  const historyNum = Number(form.historyNum ? form.historyNum.value : 0);
  for (let num = 1; num <= historyNum; num++) {
    total += Number(form['history' + num + 'Exp'] ? form['history' + num + 'Exp'].value : 0) || 0;

    totalMiren += Number(form['history' + num + 'Miren'] ? form['history' + num + 'Miren'].value : 0) || 0;
    totalInsanity += Number(form['history' + num + 'Insanity'] ? form['history' + num + 'Insanity'].value : 0) || 0;
    totalBase += Number(form['history' + num + 'BasePart'] ? form['history' + num + 'BasePart'].value : 0) || 0;
    totalEnhanced += Number(form['history' + num + 'EnhancedPart'] ? form['history' + num + 'EnhancedPart'].value : 0) || 0;
  }

  // 消費寵愛点の計算
  const expMiren = totalMiren * 2;
  const expInsanity = totalInsanity * 4;
  const expBase = totalBase * 4;
  const expEnhanced = totalEnhanced * 6;

  // 履歴テーブルのフッター（合計行）の更新
  const hTotal = document.getElementById('history-exp-total');
  const hMiren = document.getElementById('history-miren-total');
  const hInsanity = document.getElementById('history-insanity-total');
  const hBase = document.getElementById('history-basepart-total');
  const hEnhanced = document.getElementById('history-enhancedpart-total');

  if (hTotal) hTotal.textContent = total;
  if (hMiren) hMiren.textContent = totalMiren + '回';
  if (hInsanity) hInsanity.textContent = totalInsanity + '点';
  if (hBase) hBase.textContent = totalBase + '個';
  if (hEnhanced) hEnhanced.textContent = totalEnhanced + '個';

  // クラス成長にかかる消費を合算
  const usedStatus = Number(exps['status']) || 0;
  // スキル取得にかかる消費を合算
  const usedSkillClass = Number(exps['skillClassExp']) || 0;
  const usedSkillOther = Number(exps['skillOtherExp']) || 0;

  const used = usedStatus + usedSkillClass + usedSkillOther + expMiren + expInsanity + expBase + expEnhanced;

  // 画面最下部の「寵愛点 - 消費 = 残り」の更新
  const rest = total - used;

  const eTotal = document.getElementById("exp-total");
  const eStatus = document.getElementById("exp-footer-status");
  const eSkill = document.getElementById("exp-footer-skill");
  const eSkillOther = document.getElementById("exp-footer-skill-other");
  const eMiren = document.getElementById("exp-footer-miren");
  const eInsanity = document.getElementById("exp-footer-insanity");
  const eBase = document.getElementById("exp-footer-base");
  const eEnhanced = document.getElementById("exp-footer-enhanced");
  const eRest = document.getElementById("exp-rest");

  if (eTotal) eTotal.textContent = total;
  if (eStatus) eStatus.textContent = usedStatus;
  if (eSkill) eSkill.textContent = usedSkillClass;
  if (eSkillOther) eSkillOther.textContent = usedSkillOther;
  if (eMiren) eMiren.textContent = expMiren;
  if (eInsanity) eInsanity.textContent = expInsanity;
  if (eBase) eBase.textContent = expBase;
  if (eEnhanced) eEnhanced.textContent = expEnhanced;
  if (eRest) eRest.textContent = rest;
}

// === デバッグ用コンソール出力（確認が終わったら消してOKです） ===
document.addEventListener("DOMContentLoaded", function() {
  console.log("=== 未練セレクトボックス デバッグ開始 ===");
  document.querySelectorAll('option[data-debug-name]').forEach((opt, index) => {
    const selectName = opt.closest('select') ? opt.closest('select').name : '不明';
    const searchName = opt.dataset.debugName;
    const savedVal = opt.dataset.debugVal;
    const valLen = opt.dataset.debugLen;
    
    console.log(`[${index + 1}] Selectのname: ${selectName}`);
    console.log(` ┣ Perlが受け取った検索キー: ${searchName}`);
    console.log(` ┣ 保存されていた値: "${savedVal}" (文字数: ${valLen})`);
    
    if (searchName !== selectName) {
        console.error(` ┗ 🚨警告: HTMLのname属性と、Perlに渡されたキーが一致していません！`);
    }
    if (savedVal === "") {
        console.warn(` ┗ ⚠️警告: 保存された値が空です（初期値が読み込めていません）`);
    }
  });
  console.log("=========================================");
});