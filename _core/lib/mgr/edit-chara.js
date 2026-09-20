"use strict";
const gameSystem = 'mgr';

let exps = {};
let status = {};
let syndromes = [];
// ----------------------------------------
window.onload = function() {
  console.log('=====START=====');
  
  setName();
  // レベルの取得（エラー防止のため存在チェックを入れます）
  if(form.level){ level = Number(form.level.value); }
  
  // システム共通のUI構築処理（絶対に呼ばれないといけない処理）
  imagePosition();
  changeColor();
  
  initArmamentParts();
  calcJoubika();
  calcConnections();
  calcSkills();

  // これを追加（ページ読み込み時に自由記入欄の表示状態をセットする）
  changeSkillSource();
  calcClasses(); // （初期表示からCL経験点を-30にするため）
  calcStt();     // （能力値経験点を初期計算するため）
  
  changeColor();
  deleteLoadingArea();
  console.log('=====LOADED=====');
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名かコードネームのいずれかを入力してください。');
    form.characterName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}



function changeRegu(){
  const form = document.forms['sheet'];
  const exp = form.history0Exp?.value || 0;
  
  // 履歴0行目（キャラクター作成）の経験点テキストを更新
  const elExp = document.getElementById('history0-exp');
  if(elExp) elExp.textContent = exp;

  // 経験点全体の再計算を呼び出す
  calcExp();
}

// =========================================================
// SRSシステム切り替え時の動的UI変更
// =========================================================
function changeSrsSystem() {
  const sysInput = document.getElementsByName('srsSystem')[0];
  let sysName = sysInput ? sysInput.value : '';
  
  // データライブラリからシステムを取得（未定義なら「自由記入」にフォールバック）
  let sysData = srsData[sysName] || srsData['その他（自由記入）'];
  
  const sttKeys    = ['Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou'];
  const battleKeys = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou'];
  const defKeys    = ['Zan', 'Totsu', 'Ou', 'En', 'Hyou', 'Rai', 'Kou', 'Yami', 'Attr9'];
  
  // ③・⑥ 見出しの書き換えと、「なし」列の完全非表示化を実行
  updateTableHeaders('.stt-name', sysData.stt_names, 'sttName', sttKeys);
  updateTableHeaders('.battle-name', sysData.battle_names, 'battleName', battleKeys);
  updateTableHeaders('.def-name', sysData.defense_names, 'defName', defKeys);
  updateEquipHeaders('.equip-battle-name', sysData.battle_names, 'battleName');
  
  // ④ クラスリストの更新
  updateClassOptions(sysData.class_data);

  // =========================================================
  // ★ ⑤・⑦ 既存関数の参照元データをすり替え、再計算を走らせる
  // =========================================================
  
  // 既存の計算関数が参照しているグローバル変数を、選ばれたシステムのデータで上書きする
  if (sysData.class_data) {
    mgrClasses = sysData.class_data;
  } else {
    mgrClasses = {}; // 自由記入の際などは空にする
  }

  // ステータス（能力値）の初期クラスを再反映
  if (typeof changeBaseClass === 'function') {
    changeBaseClass(1);
    changeBaseClass(2);
    changeBaseClass(3);
  }
  
  // 戦闘値を再計算
  if (typeof calcClasses === 'function') {
    calcClasses();
  }
}

// 見出し（th）の中の span と input の表示を切り替える汎用関数
function updateTableHeaders(selector, nameArray, inputNamePrefix) {
  const headers = document.querySelectorAll(selector);
  
  headers.forEach((th, index) => {
    let name = (nameArray && nameArray.length > index) ? nameArray[index] : '任意';
    let span = th.querySelector('.disp-name');
    let input = th.querySelector(`input[name="${inputNamePrefix}${index+1}"]`);
    
    // システム側で「任意」に指定されている、または名前が空（未定義）の場合は入力欄を開放
    if (name === '任意' || name === '') {
      if(span) span.style.display = 'none';
      if(input) input.style.display = 'inline-block';
    } else {
      // システム側で名称が定義されている場合は span に表示
      if(span) {
        span.style.display = 'inline';
        span.textContent = name;
      }
      if(input) input.style.display = 'none';
    }
  });
}

// ★ 装備用ヘッダー（単なるテキスト）を書き換える専用関数
function updateEquipHeaders(selector, nameArray, inputNamePrefix) {
  const equipHeaders = document.querySelectorAll(selector);
  
  equipHeaders.forEach((th, index) => {
    let name = (nameArray && nameArray.length > index) ? nameArray[index] : '任意';
    
    if (name === '任意' || name === '') {
      // 自由記入の場合、サブヘッダーの input に入力されている現在値を引っ張ってくる
      let input = document.querySelector(`input[name="${inputNamePrefix}${index+1}"]`);
      th.textContent = (input && input.value) ? input.value : '任意';
      
      // さらに、input に入力されるたびに装備ヘッダーもリアルタイムで書き換えるイベントをセット
      if (input && !input.hasAttribute('data-sync-event')) {
        input.addEventListener('input', (e) => {
          th.textContent = e.target.value || '任意';
        });
        input.setAttribute('data-sync-event', 'true');
      }
    } else {
      // システム指定の名前がある場合はそのまま表示
      th.textContent = name;
    }
  });
}

// ---------------------------------------------------------
// クラスリストのプルダウンをシステムに合わせて構築・再生成する関数
// ---------------------------------------------------------
function updateClassOptions(classData) {
  // 1. クラスデータを type ごとに分類・ソートする
  let groups = {};
  if (classData) {
    for (let className in classData) {
      let type = classData[className].type || 'クラス';
      if (!groups[type]) groups[type] = [];
      groups[type].push({ name: className, sort: classData[className].sort });
    }
    // ソート順（sortキー）に従って並べ替え
    for (let type in groups) {
      groups[type].sort((a, b) => a.sort.localeCompare(b.sort));
    }
  }

  // 2. 画面上の全 select と、行追加用 template 内の select をすべてかき集める
  let selects = Array.from(document.querySelectorAll('.system-class-select'));
  const templates = document.querySelectorAll('template');
  templates.forEach(t => {
    let tSelects = t.content.querySelectorAll('.system-class-select');
    selects = selects.concat(Array.from(tSelects));
  });

  // 3. すべての select に選択肢を流し込む
  selects.forEach(select => {
    let currentVal = select.getAttribute('data-current') || ''; 
    let optionsHtml = '<option value=""></option>';
    let isFree = true;

    for (let type in groups) {
      optionsHtml += `<optgroup label="${type}">`;
      groups[type].forEach(c => {
        let isSelected = (c.name === currentVal) ? 'selected' : '';
        if (isSelected) isFree = false; // 存在するクラスなら自由記入ではない
        optionsHtml += `<option value="${c.name}" ${isSelected}>${c.name}</option>`;
      });
      optionsHtml += `</optgroup>`;
    }
    
    if (currentVal === '') isFree = false;
    
    optionsHtml += `<option value="free" ${isFree ? 'selected' : ''}>その他（自由記入）</option>`;
    
    // HTMLを流し込み
    select.innerHTML = optionsHtml;
    
    // ▼ 横に隠れている input 要素を取得して表示を切り替える
    let input = select.nextElementSibling;
    if (input && input.tagName === 'INPUT') {
      if (isFree) {
        select.value = 'free';
        input.style.display = 'inline-block';
      } else {
        input.style.display = 'none';
      }
    }
  });
}

// レベル変更 ----------------------------------------
let level = 1;
function changeLv() {
  const newLevel = Number(form.level.value);
  if(newLevel <= 0){
    alert('キャラクターレベルを0以下にはできません');
    form.level.value = level;
    return;
  }
  if(newLevel - level > 0){
    for(let i = level+1; i <= newLevel; i++){ addLvUp(i); }
  }
  else if(newLevel - level < 0) {
    for(let i = level; i > newLevel; i--){ delLvUp(i); }
  }
  level = newLevel;
  checkClass();
  calcStt();
}
// 追加
function addLvUp(num){
  const classesOption = (num >= 20) ? lvupClasses20 : (num >= 15) ? lvupClasses15 : (num >= 10) ? lvupClasses10 : lvupClasses1;
  let line = document.createElement('tr');
  line.setAttribute('id',idNumSet('lvup'));
  line.innerHTML = `
    <th>${num}</th>
    <td><input type="checkbox" name="lvUp${num}SttStr" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttDex" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttAgi" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttInt" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttSen" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttMnd" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttLuk" onchange="checkGrow(${num})" value="1"></td>
    <td class="select-or-input">
      <select name="lvUp${num}Class" onchange="changeClass();calcLvUpSkills();">${classesOption}</select>
      <input type="text" name="lvUp${num}ClassFree" onchange="changeClass()">
    </td>
    <td class="skill"><input type="text" name="lvUp${num}Skill1" oninput="calcLvUpSkills()"></td>
    <td class="skill"><input type="text" name="lvUp${num}Skill2" oninput="calcLvUpSkills()"></td>
    <td class="skill"><input type="text" name="lvUp${num}Skill3" oninput="calcLvUpSkills()"></td>
  `;
  document.querySelector("#levelup-lines").prepend(line);
}
// 削除
function delLvUp(num){
  if(
    form[`lvUp${num}SttStr`].checked || 
    form[`lvUp${num}SttDex`].checked || 
    form[`lvUp${num}SttAgi`].checked || 
    form[`lvUp${num}SttInt`].checked || 
    form[`lvUp${num}SttSen`].checked || 
    form[`lvUp${num}SttMnd`].checked || 
    form[`lvUp${num}SttLuk`].checked || 
    form[`lvUp${num}Class`].value
  ){
    if (!confirm(delConfirmText)) return false;
  }
  document.getElementById("lvup"+num).remove();
}

// 種族変更 ----------------------------------------
let race;
function changeRace(){
  race = form.race.value;
  calcStt();
}
// 種族チェック ----------------------------------------
function checkRace(){
  document.getElementById('race').classList.toggle('free', form.race.value === 'free');
  sttNames.forEach(s => {
    if(races[race]?.['stt'][s]){
      form[`stt${s}Race`].value = races[race]['stt'][s];
      form[`stt${s}Race`].readOnly = true;
    }
    else if(race){
      form[`stt${s}Race`].readOnly = false;
    }
    else {
      form[`stt${s}Race`].value = '';
      form[`stt${s}Race`].readOnly = true;
    }
  });
  document.getElementById('lifepath-earthian').style.display = race === 'アーシアン' ? '' : 'none';
  const eLifepath = (race === 'アーシアン' && form.lifepathEarthian.checked) ? 1 : 0;
  document.querySelector(`#lifepath-origin th`    ).textContent = eLifepath ? '特異' : '出自';
  document.querySelector(`#lifepath-experience th`).textContent = eLifepath ? '転移' : '境遇';
}

// クラス変更 ----------------------------------------
let classMain;
let classMainLv1;
let classSupport;
let classSupportLv1;
let classTitle;
function changeClass(type){
  classMainLv1 = form.classMainLv1.value;
  classSupportLv1 = form.classSupportLv1.value;

  checkClass();
  calcStt();
}
// クラスチェック ----------------------------------------
let hpGrow = 0;
let mpGrow = 0;
function checkClass(){
  classMain = classMainLv1;
  classSupport = classSupportLv1;
  classTitle = '';
  hpGrow = 0;
  mpGrow = 0;
  if(classSupport === 'free'){
    classSupport = form.classSupportLv1Free.value || ' ';
  }
  document.getElementById('lvup1-class').innerHTML = classMain+'<hr>'+classSupport;
  let experienced = [classMain,classSupport];
  for(let lv = 2; lv <= level; lv++){
    const name = form[`lvUp${lv}Class`].value;
    if     (classes[name]?.base){
      classMain = name;
      experienced.push(classMain);
    }
    else if(classes[name]){
      classSupport = name;
      experienced.push(classSupport);
    }
    else if(name === 'free'){
      classSupport = form[`lvUp${lv}ClassFree`].value || ' ';
      experienced.push(classSupport);
    }
    else if(name === 'title'){
      classTitle = form[`lvUp${lv}ClassFree`].value || ' ';
      experienced.push(classTitle);
    }

    if(classes[classMain]){
      hpGrow += classes[classMain]['stt']['HpGrow'];
      mpGrow += classes[classMain]['stt']['MpGrow'];
    }

    form[`lvUp${lv}Class`].parentNode.classList.toggle('free', name.match(/^(free|title)$/));
  }
  document.getElementById('class-main-value'   ).textContent = classMain;
  document.getElementById('class-support-value').textContent = classSupport;
  document.getElementById('class-title-value'  ).textContent = classTitle;
  document.getElementById('hp-grow').textContent = hpGrow;
  document.getElementById('mp-grow').textContent = mpGrow;

  document.getElementById('class-support-lv1').classList.toggle('free', form.classSupportLv1.value === 'free');

  sttNames.forEach(s => {
    if(classes[classMain]){
      if(classes[classMain]['type'] === 'fate'){
        form[`stt${s}Main`].readOnly = false;
      }
      else {
        form[`stt${s}Main`].value    = classes[classMain]['stt'][s] || '';
        form[`stt${s}Main`].readOnly = true;
      }
    }
    else if(classMain) {
      form[`stt${s}Main`].readOnly = false;
    }
    else {
      form[`stt${s}Main`].value    = '';
      form[`stt${s}Main`].readOnly = true;
    }
    if(classes[classSupport]){
      form[`stt${s}Support`].value    = classes[classSupport]['stt'][s] || '';
      form[`stt${s}Support`].readOnly = true;
    }
    else if(classSupport) {
      form[`stt${s}Support`].readOnly = false;
    }
    else {
      form[`stt${s}Support`].value    = '';
      form[`stt${s}Support`].readOnly = true;
    }
  });
  if(classes[classMain]){
    const baseClass = classes[classMain]['base'] || classMain;
    form[`hpMain`].value = classes[baseClass]['stt']['Hp'] || '';
    form[`mpMain`].value = classes[baseClass]['stt']['Mp'] || '';
    form[`hpMain`].readOnly = true;
    form[`mpMain`].readOnly = true;
  }
  else if(classMain) {
    form[`hpMain`].readOnly = false;
    form[`mpMain`].readOnly = false;
  }
  else {
    form[`hpMain`].value = '';
    form[`mpMain`].value = '';
    form[`hpMain`].readOnly = true;
    form[`mpMain`].readOnly = true;
  }
  if(classes[classSupportLv1]){
    form[`hpSupport`].value    = classes[classSupportLv1]['stt']['Hp'] || '';
    form[`mpSupport`].value    = classes[classSupportLv1]['stt']['Mp'] || '';
    form[`hpSupport`].readOnly = true;
    form[`mpSupport`].readOnly = true;
  }
  else if(classSupportLv1) {
    form[`hpSupport`].readOnly = false;
    form[`mpSupport`].readOnly = false;
  }
  else {
    form[`hpSupport`].value = '';
    form[`mpSupport`].value = '';
    form[`hpSupport`].readOnly = true;
    form[`mpSupport`].readOnly = true;
  }

  document.querySelectorAll(`#levelup select[name$="Class"] option, select[name="classSupportLv1"] option`).forEach(opt => {
    const name = opt.value;
    if(classes[name]?.base || classes[name]?.limited){
      opt.style.display = (classes[name].base === classMainLv1 || classes[name].limited === classMainLv1 ? '' : 'none');
    }
  });
  for(let num = 1; num <= form['skillsNum'].value; num++){
    const select = form[`skill${num}Type`];
    const selected = select.value;
    for(let i = select.options.length - 1; i > 0; i--) {
      if(!select.options[i].value.match(/^(race|add|general|style|faith|geis)$/)){ select.options[i].remove(); }
    }
    if(classes[classMain]?.type === 'fate'){
      Array.from(new Set([
        {'value':'power'  ,'text' : 'パワー（共通）'},
        {'value':'another','text' : '異才'},
      ])).forEach(op => {
        const option = document.createElement('option');
        option.value = op.value;
        option.text = op.text;
        select.appendChild(option);
      });
    }
    let array = experienced.concat();
    if(selected && !selected.match(/^(race|add|general|style|faith|geis|power|another)$/)){ array.push(selected); }
    Array.from(new Set(array)).forEach(name => {
      const option = document.createElement('option');
      option.value = name;
      option.text = name;
      select.appendChild(option);
    });
    select.value = selected;
  }
  document.querySelector(`#lifepath-motive th`).textContent = (classes[classMain]?.type === 'fate') ? '運命' : '目的';
}
// 成長チェック ----------------------------------------
function checkGrow(num) {
  let total = 0;
  sttNames.forEach(s => {
    total += form[`lvUp${num}Stt${s}`].checked ? 1 : 0;
    form[`lvUp${num}Stt${s}`].disabled = false;
  });
  if(total >= 3){
    sttNames.forEach(s => {
      if(!form[`lvUp${num}Stt${s}`].checked){ form[`lvUp${num}Stt${s}`].disabled = true; }
    });
  }
  calcStt();
}

function calcStt() {
  let totalSttExp = 0; 

  mgrSttNames.forEach(stt => {
    let baseTotal = 0;
    for (let i = 1; i <= 3; i++) {
      baseTotal += Number(form[`sttBase${i}${stt}`]?.value) || 0;
    }

    let point = form[`sttPoint${stt}`]?.checked ? 1 : 0; 
    let grow  = Number(form[`sttGrow${stt}`]?.value) || 0;
    let skill = Number(form[`sttSkill${stt}`]?.value) || 0;
    let other = Number(form[`sttOther${stt}`]?.value) || 0;

    let initialValue = baseTotal + point;
    let targetValue  = initialValue + grow;
    
    let sttExp = 0;
    if (grow > 0) {
      sttExp = getSttExp(targetValue) - getSttExp(initialValue);
    } else if (grow < 0) {
      sttExp = -(getSttExp(initialValue) - getSttExp(targetValue));
    }
    
    totalSttExp += sttExp;

    let total = baseTotal + point + grow + skill + other;
    if (form[`sttTotal${stt}`]) form[`sttTotal${stt}`].value = total;

    let bonusBase = Math.floor(total / 3);
    let bonusAdd  = Number(form[`sttBonusAdd${stt}`]?.value) || 0;
    
    if (form[`sttBonus${stt}`]) form[`sttBonus${stt}`].value = bonusBase + bonusAdd;
  });

  expUse['stt'] = totalSttExp;
  calcExp();
  calcBattle();
}

// 武器の合計切り替え ----------------------------------------
function changeHandedness(){
  const hand = String(form.handedness.value || 1);
  document.getElementById('battle-total-acc-right').classList.toggle('hide', hand.match(/2|3/) || (hand == 1 && form.armamentHandRType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-acc-left' ).classList.toggle('hide', hand.match(/2|3/) || (hand == 1 && form.armamentHandLType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-atk-right').classList.toggle('hide', hand.match(/2/) || (hand == 1 && form.armamentHandRType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-atk-left' ).classList.toggle('hide', hand.match(/2/) || (hand == 1 && form.armamentHandLType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-acc' ).classList.toggle('hide', hand.match(/1/));
  document.getElementById('battle-total-atk' ).classList.toggle('hide', hand.match(/1|3/));
}

// 武器・戦闘判定計算 ----------------------------------------
function calcBattle() {
  const form = document.forms['sheet'];

  const baseTai  = Number(form['sttTotalTai']?.value) || 0;
  const baseIshi = Number(form['sttTotalIshi']?.value) || 0;

  const bonTai = Number(form['sttBonusTai']?.value) || 0;

  const bonHan = Number(form['sttBonusHan']?.value) || 0;
  const bonChi = Number(form['sttBonusChi']?.value) || 0;
  const bonKou = Number(form['sttBonusKou']?.value) || 0;
  const bonRi  = Number(form['sttBonusRi']?.value) || 0;

  const baseMeichu  = Math.floor((bonHan + bonChi) / 2);
  const baseKaihi   = Math.floor((bonHan + bonKou) / 2);
  const baseHougeki = Math.floor((bonRi + bonChi) / 2);
  const baseBouheki = Math.floor((bonRi + bonKou) / 2); 
  const baseKoudou  = bonHan + bonRi;
  const baseRikiba  = 0;
  const baseTaikyu  = baseTai;
  const baseKannou  = baseIshi;
  const baseIdou    = Math.floor(bonTai / 3); 

  if(form.battleBaseMeichu)  form.battleBaseMeichu.value  = baseMeichu;
  if(form.battleBaseKaihi)   form.battleBaseKaihi.value   = baseKaihi;
  if(form.battleBaseHougeki) form.battleBaseHougeki.value = baseHougeki;
  if(form.battleBaseBouheki) form.battleBaseBouheki.value = baseBouheki;
  if(form.battleBaseKoudou)  form.battleBaseKoudou.value  = baseKoudou;
  if(form.battleBaseRikiba)  form.battleBaseRikiba.value  = baseRikiba;
  if(form.battleBaseTaikyu)  form.battleBaseTaikyu.value  = baseTaikyu;
  if(form.battleBaseKannou)  form.battleBaseKannou.value  = baseKannou;
  if(form.battleBaseIdou)    form.battleBaseIdou.value    = baseIdou; 

  const battleStts = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou', 'Idou'];
  const classesNum = Number(form.classesNum.value) || 1;

  battleStts.forEach(stt => {
    let subtotal = Number(form[`battleBase${stt}`]?.value) || 0;
    subtotal += Number(form[`battleBaseAdd${stt}`]?.value) || 0;
    for (let i = 1; i <= classesNum; i++) {
      subtotal += Number(form[`battleClass${i}${stt}`]?.value) || 0;
    }
    if(form[`battleSubtotal${stt}`]) form[`battleSubtotal${stt}`].value = subtotal;
  });

  let kougekiSubtotal = Number(form[`battleBaseAddKougeki`]?.value) || 0;
  for (let i = 1; i <= classesNum; i++) {
    kougekiSubtotal += Number(form[`battleClass${i}Kougeki`]?.value) || 0;
  }
  if(form.battleSubtotalKougeki) form.battleSubtotalKougeki.value = kougekiSubtotal;

  const armamentsNum = Number(form.armamentsNum.value) || 1;
  const battleSttsAll = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou', 'Idou', 'Joubi', 'Kougeki'];
  
  let total = {};
  battleSttsAll.forEach(stt => {
    total[stt] = Number(form[`battleSubtotal${stt}`]?.value) || 0;
  });
  total['Joubi'] = 0;
  total['Kougeki'] = Number(form.battleSubtotalKougeki?.value) || 0;

  for (let i = 1; i <= armamentsNum; i++) {
    const isEquipped = form[`armament${i}Equip`]?.checked;
    const partVal = form[`armament${i}Part`]?.value || '';
    
    total['Joubi'] += Number(form[`armament${i}Joubi`]?.value) || 0;

    if (isEquipped) {
      battleSttsAll.forEach(stt => {
        if (stt === 'Joubi') return;
        
        let val = Number(form[`armament${i}${stt}`]?.value) || 0;
        if (stt === 'Kougeki' && /[主副近遠武]/.test(partVal)) {
          val = 0; 
        }
        total[stt] += val;
      });
    }
  }

  battleSttsAll.forEach(stt => {
    if(form[`battleTotal${stt}`]) form[`battleTotal${stt}`].value = total[stt];
  });
  calcJoubika();
}

function calcPrice() {
  calcBattle();
}

function calcRolls(){
  document.getElementById('roll-trapdetect-total'  ).textContent = sttRoll['Sen'] + Number(form.rollTrapDetectSkill.value   )+ Number(form.rollTrapDetectOther.value  );
  document.getElementById('roll-traprelease-total' ).textContent = sttRoll['Dex'] + Number(form.rollTrapReleaseSkill.value  )+ Number(form.rollTrapReleaseOther.value );
  document.getElementById('roll-dengerdetect-total').textContent = sttRoll['Sen'] + Number(form.rollDangerDetectSkill.value )+ Number(form.rollDangerDetectOther.value);
  document.getElementById('roll-enemylore-total'   ).textContent = sttRoll['Int'] + Number(form.rollEnemyLoreSkill.value    )+ Number(form.rollEnemyLoreOther.value   );
  document.getElementById('roll-appraisal-total'   ).textContent = sttRoll['Int'] + Number(form.rollAppraisalSkill.value    )+ Number(form.rollAppraisalOther.value   );
  document.getElementById('roll-magic-total'       ).textContent = sttRoll['Int'] + Number(form.rollMagicSkill.value        )+ Number(form.rollMagicOther.value       );
  document.getElementById('roll-song-total'        ).textContent = sttRoll['Mnd'] + Number(form.rollSongSkill.value         )+ Number(form.rollSongOther.value        );
  document.getElementById('roll-alchemy-total'     ).textContent = sttRoll['Dex'] + Number(form.rollAlchemySkill.value      )+ Number(form.rollAlchemyOther.value     );

  document.getElementById('roll-trapdetect-total-dice'  ).textContent = Number(form.rollSenDice.value)+ Number(form.rollTrapDetectDiceAdd.value  );
  document.getElementById('roll-traprelease-total-dice' ).textContent = Number(form.rollDexDice.value)+ Number(form.rollTrapReleaseDiceAdd.value );
  document.getElementById('roll-dengerdetect-total-dice').textContent = Number(form.rollSenDice.value)+ Number(form.rollDangerDetectDiceAdd.value);
  document.getElementById('roll-enemylore-total-dice'   ).textContent = Number(form.rollIntDice.value)+ Number(form.rollEnemyLoreDiceAdd.value   );
  document.getElementById('roll-appraisal-total-dice'   ).textContent = Number(form.rollIntDice.value)+ Number(form.rollAppraisalDiceAdd.value   );
  document.getElementById('roll-magic-total-dice'       ).textContent = Number(form.rollIntDice.value)+ Number(form.rollMagicDiceAdd.value       );
  document.getElementById('roll-song-total-dice'        ).textContent = Number(form.rollMndDice.value)+ Number(form.rollSongDiceAdd.value        );
  document.getElementById('roll-alchemy-total-dice'     ).textContent = Number(form.rollDexDice.value)+ Number(form.rollAlchemyDiceAdd.value     );
}

function calcWeight(){
  let weight = 0;
  let w = form.items.value;
  w.replace(
    /[@＠]\[\s*?([\+\-\*\/]?[0-9]+)+\s*?\]/g,
    function (num, idx, old) {
      weight += safeEval(num.slice(2,-1)) || 0;
    }
  );
  document.getElementById('items-weight-total').textContent = weight;
}


function calcConnections(){
  expUse['connections'] = 0;
  for(let i = 1; i <= Number(form.connectionsNum.value); i++){
    // .checked の前に「?.」を追加し、要素が存在しない場合のエラーを回避します
    if(form[`connection${i}Joubika`]?.checked) expUse['connections']++;
  }
  calcExp();
}

function calcGeises(){
  expUse['geises'] = 0;
  for(let i = 1; i <= Number(form.geisesNum.value); i++){
    expUse['geises'] += Number(form[`geis${i}Cost`].value);
  }
  calcExp();
}

function addSkill(){
  document.querySelector("#skills-table tbody:last-of-type").after(createRow('skill','skillsNum'));
  updateSkillSourceOptions();
}
function delSkill(){
  if(delRow('skillsNum', '#skills-table tbody:last-of-type')){
    calcSkills();
  }
}

(() => {
  let sortable = Sortable.create(document.getElementById('skills-table'), {
    group: "skills",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ skillsSortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('skills-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!skillTrashNum) { document.getElementById('skills-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('skills-trash-table'), {
    group: "skills",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let skillTrashNum = 0;
  function skillsSortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(skill)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    const form = document.forms['sheet'];
    if(form.skillsNum) form.skillsNum.value = num-1;
    
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(skill)(?:Trash)?[0-9]+(.+)$/);
    }
    skillTrashNum = del;
    if(!del){ document.getElementById('skills-trash').style.display = 'none' }
    calcSkills();
  }
})();

function addConnection(){
  document.querySelector("#connections-table tbody").append(createRow('connection','connectionsNum'));
}
function delConnection(){
  if(delRow('connectionsNum', '#connections-table tbody tr:last-of-type')){
    calcConnections();
  }
}
setSortable('connection','#connections-table tbody','tr');

function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcExp(); 
  }
}
setSortable('history','#history-table','tbody');

const dummyBattle = {
  "1": { "Meichu":1, "Kaihi":1, "Hougeki":1, "Bouheki":1, "Koudou":1, "Rikiba":1, "Taikyu":1, "Kannou":1, "Kougeki":1 },
  "2": { "Meichu":2, "Kaihi":2, "Hougeki":2, "Bouheki":2, "Koudou":2, "Rikiba":2, "Taikyu":2, "Kannou":2, "Kougeki":2 },
  "3": { "Meichu":4, "Kaihi":4, "Hougeki":4, "Bouheki":4, "Koudou":4, "Rikiba":4, "Taikyu":4, "Kannou":4, "Kougeki":4 }
};

const mgrSttNames = ['Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou'];

function changeBaseClass(num) {
  const form = document.forms['sheet'];
  const name = form[`sttBase${num}Class`].value;
  const data = mgrClasses[name];
  const typeInput = form[`sttBase${num}Type`];
  
  if (data) {
    typeInput.value = (data.type === 'linkage' ? 'リンケージ' : 'ガーディアン');
    typeInput.readOnly = true;
    typeInput.tabIndex = -1;

    if (data.stt) {
      mgrSttNames.forEach(s => {
        if (form[`sttBase${num}${s}`]) {
          form[`sttBase${num}${s}`].value = data.stt[s];
        }
      });
    }
  } else {
    typeInput.readOnly = false;
    typeInput.tabIndex = 0;
    typeInput.value = '';
    
    mgrSttNames.forEach(s => {
      if (form[`sttBase${num}${s}`]) {
        form[`sttBase${num}${s}`].value = '';
      }
    });
  }
  calcStt();
  calcClasses();
}

function addClass() {
  const num = Number(form.classesNum.value) + 1;
  document.querySelector("#classes-table tbody").append(createRow('class','classesNum'));

  const tr = document.createElement('tr');
  tr.id = `battle-class-row${num}`;
  tr.innerHTML = `
    <th colspan="3" class="class-name right" id="battle-class-name${num}">クラス名</th>
    <th class="class-lv" id="battle-class-lv${num}">Lv</th>
    <td><input type="number" name="battleClass${num}Meichu" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Kaihi" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Hougeki" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Bouheki" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Koudou" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Rikiba" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Taikyu" readonly tabindex="-1"></td>
    <td><input type="number" name="battleClass${num}Kannou" readonly tabindex="-1"></td>
    <td class="dead-space"></td>
    <td class="dead-space"></td>
    <td><input type="number" name="battleClass${num}Kougeki" readonly tabindex="-1"></td>
    <td colspan="5" class="dead-space"></td>
  `;
  document.getElementById('battle-classes-area').append(tr);
}

function delClass() {
  const num = Number(form.classesNum.value);
  if (delRow('classesNum', '#classes-table tbody tr:last-of-type')) {
    const battleRow = document.getElementById(`battle-class-row${num}`);
    if (battleRow) battleRow.remove();
    calcClasses();
  }
}

document.addEventListener('change', function(e) {
  if (e.target && e.target.name && e.target.name.startsWith('sttPoint')) {
    if (e.target.checked) {
      const form = document.forms['sheet'];
      const clickedStt = e.target.name.replace('sttPoint', '');
      mgrSttNames.forEach(stt => {
        if (stt !== clickedStt) {
          const otherBox = form[`sttPoint${stt}`];
          if (otherBox) otherBox.checked = false;
        }
      });
      calcStt();
    }
  }

  if (e.target && e.target.name && e.target.name.match(/^armament(\d+)Equip$/)) {
    if (e.target.checked) {
      const num = RegExp.$1;
      const partVal = form[`armament${num}Part`]?.value || '';
      
      if (/乗機/.test(partVal)) {
        const armamentsNum = Number(form.armamentsNum.value) || 1;
        for (let i = 1; i <= armamentsNum; i++) {
          if (i !== Number(num)) {
            const otherPart = form[`armament${i}Part`]?.value || '';
            const otherCheck = form[`armament${i}Equip`];
            if (/乗機/.test(otherPart) && otherCheck && otherCheck.checked) {
              otherCheck.checked = false;
            }
          }
        }
      }
    }
    calcBattle();
  }
});

function calcClasses() {
  const form = document.forms['sheet'];
  const classesNum = Number(form.classesNum.value) || 1;
  let totalClassLv = 0; 

  for (let i = 1; i <= classesNum; i++) {
    const className = form[`class${i}Name`]?.value || '';
    const classLv = Number(form[`class${i}Lv`]?.value) || 0;
    
    totalClassLv += classLv;

    const nameCell = document.getElementById(`battle-class-name${i}`);
    const lvCell = document.getElementById(`battle-class-lv${i}`);
    if (nameCell) nameCell.textContent = className || '―';
    if (lvCell) lvCell.textContent = classLv || 0;

    const classData = mgrClasses[className];
    const battleStts = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou', 'Kougeki'];

    battleStts.forEach(stt => {
      const inputField = form[`battleClass${i}${stt}`];
      if (inputField) {
        let val = 0;
        if (classData && classData.battle && classData.battle[classLv]) {
          val = classData.battle[classLv][stt] || 0;
        }
        inputField.value = val;
      }
    });
  }

  let clExp = 0;
  if      (totalClassLv === 0) clExp = -30;
  else if (totalClassLv === 1) clExp = -20;
  else if (totalClassLv === 2) clExp = -10;
  else if (totalClassLv === 3) clExp = 0;
  else if (totalClassLv === 4) clExp = 10;
  else if (totalClassLv === 5) clExp = 25;
  else if (totalClassLv === 6) clExp = 50;
  else if (totalClassLv === 7) clExp = 90;
  else if (totalClassLv === 8) clExp = 150;
  else if (totalClassLv === 9) clExp = 235;
  else if (totalClassLv === 10) clExp = 345;
  else if (totalClassLv === 11) clExp = 485;
  else if (totalClassLv >= 12) clExp = 485 + (totalClassLv - 11) * 200;
  
  expUse['level'] = clExp;

  updateSkillSourceOptions();
  updateClassBattleValues();
  
  calcBattle();
  calcExp();
  updateSkillHistoryTable();
}

function updateClassBattleValues() {
  const form = document.forms['sheet'];
  const num = Number(form.classesNum.value) || 0;
  const stats = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou', 'Kougeki'];

  for (let i = 1; i <= num; i++) {
    const name = form[`class${i}Name`].value;
    const lv   = Number(form[`class${i}Lv`].value) || 0;
    const classData = mgrClasses[name];

    stats.forEach(s => {
      const input = form[`battleClass${i}${s}`];
      if (input) {
        if (classData && classData.battle && classData.battle[lv]) {
          input.value = classData.battle[lv][s] || 0;
          input.readOnly = true;
          input.tabIndex = -1;
        } else {
          input.readOnly = false;
          input.tabIndex = 0;
        }
      }
    });
    
    const nameDisp = document.getElementById(`battle-class-name${i}`);
    const lvDisp   = document.getElementById(`battle-class-lv${i}`);
    if (nameDisp) nameDisp.textContent = name || 'クラス名';
    if (lvDisp)   lvDisp.textContent   = lv   || 'Lv';
  }
  calcBattle();
}

document.addEventListener('input', function(e) {
  if (e.target && e.target.name) {
    const m = e.target.name.match(/^armament(\d+)(Part|Name)$/);
    if (m) {
      const num = m[1];
      const type = m[2]; 

      if (type === 'Part') {
        const zokuseiInput = document.forms['sheet'][`armament${num}Zokusei`];
        const shateiInput  = document.forms['sheet'][`armament${num}Shatei`];
        const daishouInput = document.forms['sheet'][`armament${num}Daishou`];
        const danzuuInput  = document.forms['sheet'][`armament${num}Danzuu`];

        if (/[主副近遠武]/.test(e.target.value)) {
          if(zokuseiInput) { zokuseiInput.readOnly = false; zokuseiInput.tabIndex = 0; zokuseiInput.parentNode.classList.remove('dead-space'); }
          if(shateiInput)  { shateiInput.readOnly = false;  shateiInput.tabIndex = 0;  shateiInput.parentNode.classList.remove('dead-space'); }
          if(daishouInput) { daishouInput.readOnly = false; daishouInput.tabIndex = 0; daishouInput.parentNode.classList.remove('dead-space'); }
          if(danzuuInput)  { danzuuInput.readOnly = false;  danzuuInput.tabIndex = 0;  danzuuInput.parentNode.classList.remove('dead-space'); }
        } else {
          if(zokuseiInput) { zokuseiInput.readOnly = true; zokuseiInput.tabIndex = -1; zokuseiInput.value = ''; zokuseiInput.parentNode.classList.add('dead-space'); }
          if(shateiInput)  { shateiInput.readOnly = true;  shateiInput.tabIndex = -1;  shateiInput.value = '';  shateiInput.parentNode.classList.add('dead-space'); }
          if(daishouInput) { daishouInput.readOnly = true; daishouInput.tabIndex = -1; daishouInput.value = ''; daishouInput.parentNode.classList.add('dead-space'); }
          if(danzuuInput)  { danzuuInput.readOnly = true;  danzuuInput.tabIndex = -1;  danzuuInput.value = '';  danzuuInput.parentNode.classList.add('dead-space'); }
        }
      }
      syncArmamentToAutoRows(num);
      calcBattle(); 
    }
  }
});

function initArmamentParts() {
  const form = document.forms['sheet'];
  const armamentsNum = Number(form.armamentsNum?.value) || 1;
  
  for (let i = 1; i <= armamentsNum; i++) {
    const partInput = form[`armament${i}Part`];
    const zokuseiInput = form[`armament${i}Zokusei`];
    const shateiInput  = form[`armament${i}Shatei`];
    const daishouInput = form[`armament${i}Daishou`];
    const danzuuInput  = form[`armament${i}Danzuu`];
    
    if (partInput) {
      if (/[主副近遠武]/.test(partInput.value)) {
        if(zokuseiInput) { zokuseiInput.readOnly = false; zokuseiInput.tabIndex = 0; zokuseiInput.parentNode.classList.remove('dead-space'); }
        if(shateiInput)  { shateiInput.readOnly = false;  shateiInput.tabIndex = 0;  shateiInput.parentNode.classList.remove('dead-space'); }
        if(daishouInput) { daishouInput.readOnly = false; daishouInput.tabIndex = 0; daishouInput.parentNode.classList.remove('dead-space'); }
        if(danzuuInput)  { danzuuInput.readOnly = false;  danzuuInput.tabIndex = 0;  danzuuInput.parentNode.classList.remove('dead-space'); }
      } else {
        if(zokuseiInput) { zokuseiInput.readOnly = true; zokuseiInput.tabIndex = -1; zokuseiInput.parentNode.classList.add('dead-space'); }
        if(shateiInput)  { shateiInput.readOnly = true;  shateiInput.tabIndex = -1;  shateiInput.parentNode.classList.add('dead-space'); }
        if(daishouInput) { daishouInput.readOnly = true; daishouInput.tabIndex = -1; daishouInput.parentNode.classList.add('dead-space'); }
        if(danzuuInput)  { danzuuInput.readOnly = true;  danzuuInput.tabIndex = -1;  danzuuInput.parentNode.classList.add('dead-space'); }
      }
    }
    syncArmamentToAutoRows(i);
  }
}

function addArmament() {
  const form = document.forms['sheet'];
  const num = Number(form.armamentsNum.value) + 1;
  document.querySelector("#armaments-area").append(createRow('armament','armamentsNum'));
  
  const defTr = document.createElement('tr');
  defTr.id = `defence-auto-row${num}`;
  defTr.className = 'defence-auto-row';
  defTr.style.display = 'none';
  defTr.innerHTML = `
    <td></td>
    <td><input type="text" name="defenceAuto${num}Part" readonly tabindex="-1"></td>
    <td><input type="text" name="defenceAuto${num}Name" readonly tabindex="-1"></td>
    <td><input type="number" name="defenceAuto${num}Zan" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}Totsu" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}Ou" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}En" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}Hyou" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}Rai" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}Kou" oninput="calcBattle()"></td>
    <td><input type="number" name="defenceAuto${num}Yami" oninput="calcBattle()"></td>
    <td><input type="text" name="defenceAuto${num}Size"></td>
  `;
  document.getElementById('defences-auto-area').append(defTr);

  const noteTr = document.createElement('tr');
  noteTr.id = `armament-note-auto-row${num}`;
  noteTr.className = 'armament-note-auto-row';
  noteTr.style.display = 'none';
  noteTr.innerHTML = `
    <td><input type="text" name="armamentNoteAuto${num}Part" readonly tabindex="-1"></td>
    <td><input type="text" name="armamentNoteAuto${num}Name" readonly tabindex="-1"></td>
    <td class="left"><input type="text" name="armamentNoteAuto${num}Note" placeholder="解説"></td>
    <td><input type="text" name="armamentNoteAuto${num}Type" placeholder="種別"></td>
  `;
  document.getElementById('armament-notes-auto-area').append(noteTr);
}

function syncArmamentToAutoRows(num) {
  const form = document.forms['sheet'];
  const partVal = form[`armament${num}Part`]?.value || '';
  const nameVal = form[`armament${num}Name`]?.value || '';

  const defRow = document.getElementById(`defence-auto-row${num}`);
  const defPart = form[`defenceAuto${num}Part`];
  const defName = form[`defenceAuto${num}Name`];

  const noteRow = document.getElementById(`armament-note-auto-row${num}`);
  const notePart = form[`armamentNoteAuto${num}Part`];
  const noteName = form[`armamentNoteAuto${num}Name`];

  if (!partVal) {
    if (noteRow) noteRow.style.display = 'none';
  } else {
    if (noteRow) {
      noteRow.style.display = '';
      if (notePart) notePart.value = partVal;
      if (noteName) noteName.value = nameVal;
    }
  }

  if (!partVal || /[主副近遠武]/.test(partVal)) {
    if (defRow) defRow.style.display = 'none';
  } else {
    if (defRow) {
      defRow.style.display = '';
      if (defPart) defPart.value = partVal;
      if (defName) defName.value = nameVal;
    }
  }
}

function addDefence() {
  document.querySelector("#defences-area").append(createRow('defence','defencesNum'));
}

function delDefence() {
  if (delRow('defencesNum', '#defences-area tr:last-of-type')) {
    calcBattle();
  }
}

setSortable('class', '#classes-table tbody', 'tr');
setSortable('defence', '#defences-area', 'tr');

const armamentsArea = document.getElementById('armaments-area');
if (armamentsArea) {
  Sortable.create(armamentsArea, {
    group: "armaments",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onUpdate: function (evt) {
      const defArea = document.getElementById('defences-auto-area');
      const noteArea = document.getElementById('armament-notes-auto-area');

      Array.from(armamentsArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        
        const input = tr.querySelector('input[name^="armament"]');
        if (input) {
          const match = input.name.match(/^armament(\d+)/);
          if (match) {
            const oldNum = match[1]; 
            
            const defRow = document.getElementById(`defence-auto-row${oldNum}`);
            if (defRow && defArea) defArea.appendChild(defRow);

            const noteRow = document.getElementById(`armament-note-auto-row${oldNum}`);
            if (noteRow && noteArea) noteArea.appendChild(noteRow);
          }
        }
      });

      let num = 1;
      Array.from(armamentsArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        tr.id = `armament-row${num}`;
        replaceSortedNames(tr, num, /^(armament)\d+(.+)$/);
        num++;
      });

      num = 1;
      Array.from(defArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        tr.id = `defence-auto-row${num}`;
        replaceSortedNames(tr, num, /^(defenceAuto)\d+(.+)$/);
        num++;
      });

      num = 1;
      Array.from(noteArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        tr.id = `armament-note-auto-row${num}`;
        replaceSortedNames(tr, num, /^(armamentNoteAuto)\d+(.+)$/);
        num++;
      });

      calcBattle(); 
    }
  });
}

['mouseup', 'touchend'].forEach(eventName => {
  document.addEventListener(eventName, function(e) {
    if (e.target.closest('#classes-table .handle')) {
      setTimeout(() => { calcClasses(); calcBattle(); }, 200);
    }
  });
});

function delArmament() {
  const armamentsArea = document.querySelector('#armaments-area');
  const lastRow = armamentsArea ? armamentsArea.querySelector('tr:last-of-type') : null;
  
  if (lastRow) {
    let targetNum = null;
    const input = lastRow.querySelector('input[name^="armament"]');
    if (input) {
      const match = input.name.match(/^armament(\d+)/);
      if (match) targetNum = match[1];
    }

    if (delRow('armamentsNum', '#armaments-area tr:last-of-type')) {
      if (targetNum) {
        const defRow = document.getElementById(`defence-auto-row${targetNum}`);
        if (defRow) defRow.remove();
        
        const noteRow = document.getElementById(`armament-note-auto-row${targetNum}`);
        if (noteRow) noteRow.remove();
      }
      calcBattle(); 
    }
  }
}

function addKago(){
  document.querySelector("#kagos-table tbody").append(createRow('kago','kagosNum'));
}
function delKago(){
  delRow('kagosNum', '#kagos-table tbody tr:last-of-type');
}
setSortable('kago','#kagos-table tbody','tr');

function updateSkillSourceOptions() {
  const form = document.forms['sheet'];
  const classesNum = Number(form.classesNum?.value) || 1;
  const skillsNum = Number(form.skillsNum?.value) || 1;
  
  const currentClasses = new Set();
  for (let i = 1; i <= classesNum; i++) {
    const className = form[`class${i}Name`]?.value;
    if (className) currentClasses.add(className);
  }

  for (let i = 1; i <= skillsNum; i++) {
    const input = form[`skill${i}Type`]; 
    if (!input) continue;

    const select = input.previousElementSibling;
    if (!select || select.tagName.toLowerCase() !== 'select') continue;
    
    const selectedValue = input.value; 
    const defaultOptions = ['ガーディアン', '汎用', 'アシスト', '勲章'];

    select.innerHTML = '';
    
    select.appendChild(new Option('', ''));
    
    currentClasses.forEach(className => {
      select.appendChild(new Option(className, className));
    });
    
    defaultOptions.forEach(opt => {
      select.appendChild(new Option(opt, opt));
    });
    
    select.appendChild(new Option('その他（自由記入）', 'free'));

    let isFree = false;
    if (selectedValue && !defaultOptions.includes(selectedValue) && !currentClasses.has(selectedValue)) {
      isFree = true;
    }

    if (isFree) {
      select.value = 'free'; 
      input.style.display = 'inline-block'; 
    } else {
      select.value = selectedValue; 
      input.style.display = 'none'; 
      input.value = selectedValue; 
    }
  }
}

function changeSkillSource(selectObj) {
  if(selectObj) {
    selectObj.parentNode.classList.toggle('free', selectObj.value === 'free');
  } else {
    const form = document.forms['sheet'];
    const skillsNum = Number(form.skillsNum?.value) || 1;
    for (let i = 1; i <= skillsNum; i++) {
      const select = form[`skill${i}Type`]; 
      if(select) select.parentNode.classList.toggle('free', select.value === 'free');
    }
  }
}

function calcJoubika() {
  const form = document.forms['sheet'];
  
  const expUsed = Number(form.joubikaExpUsed?.value) || 0;
  const expAdd = expUsed * 10;
  if(form.joubikaExpAdd) form.joubikaExpAdd.value = expAdd;
  
  const skillAdd = Number(form.joubikaSkillAdd?.value) || 0;
  const max = 50 + skillAdd + expAdd;
  
  let itemsTotal = 0;
  const lifestylesNum = Number(form.lifestylesNum?.value) || 1;
  for(let i = 1; i <= lifestylesNum; i++) itemsTotal += Number(form[`lifestyle${i}Joubika`]?.value) || 0;
  
  const housesNum = Number(form.housesNum?.value) || 1;
  for(let i = 1; i <= housesNum; i++) itemsTotal += Number(form[`house${i}Joubika`]?.value) || 0;
  
  const itemsNum = Number(form.itemsNum?.value) || 1;
  for(let i = 1; i <= itemsNum; i++) itemsTotal += Number(form[`item${i}Joubika`]?.value) || 0;
  
  const armamentsTotal = Number(form.battleTotalJoubi?.value) || 0;
  
  const rest = max - itemsTotal - armamentsTotal;
  
  const elItemsTotal = document.getElementById('joubika-items-total');
  const elArmamentsTotal = document.getElementById('joubika-armaments-total');
  const elRest = document.getElementById('joubika-rest');
  const elMax = document.getElementById('joubika-max');
  
  if(elItemsTotal) elItemsTotal.textContent = itemsTotal;
  if(elArmamentsTotal) elArmamentsTotal.textContent = armamentsTotal;
  if(elRest) {
    elRest.textContent = rest;
    elRest.style.color = (rest < 0) ? 'red' : '';
  }
  if(elMax) elMax.textContent = max;

  document.getElementById('joubika-max').textContent = max;
  document.getElementById('joubika-rest').textContent = rest;

  if (form.joubikaMax)  form.joubikaMax.value  = max;
  if (form.joubikaRest) form.joubikaRest.value = rest;

  calcExp();
}

function addLifestyle() { document.querySelector("#lifestyles-table tbody").append(createRow('lifestyle', 'lifestylesNum')); }
function delLifestyle() { if(delRow('lifestylesNum', '#lifestyles-table tbody tr:last-of-type')) calcJoubika(); }
setSortable('lifestyle', '#lifestyles-table tbody', 'tr');

function addHouse() { document.querySelector("#houses-table tbody").append(createRow('house', 'housesNum')); }
function delHouse() { if(delRow('housesNum', '#houses-table tbody tr:last-of-type')) calcJoubika(); }
setSortable('house', '#houses-table tbody', 'tr');

function addItem() { document.querySelector("#items-table tbody").append(createRow('item', 'itemsNum')); }
function delItem() { if(delRow('itemsNum', '#items-table tbody tr:last-of-type')) calcJoubika(); }
setSortable('item', '#items-table tbody', 'tr');

function addMission() { 
  document.querySelector("#missions-table tbody").append(createRow('mission', 'missionsNum')); 
}
function delMission() { 
  delRow('missionsNum', '#missions-table tbody tr:last-of-type'); 
}
setSortable('mission', '#missions-table tbody', 'tr');

function calcExp() {
  const form = document.forms['sheet'];
  const historyNum = Number(form.historyNum?.value) || 0;
  
  let total = Number(form.history0Exp?.value) || 0;
  let payment = 0;

  for (let i = 1; i <= historyNum; i++) {
    const objExp = form['history' + i + 'Exp'];
    const objPay = form['history' + i + 'Payment'];
    const objCheck = form['history' + i + 'Check']; 

    let exp = safeEval(objExp?.value) || 0;
    let pay = Number(objPay?.value) || 0;

    if (objCheck && objCheck.checked) {
      total += exp;
      payment += pay;
    }
  }

  total -= payment;
  let rest = total;

  expUse['joubika'] = Number(form.joubikaExpUsed?.value) || 0;
  
  for (let key in expUse) {
    rest -= Number(expUse[key]) || 0;
  }

  const elTotal = document.getElementById("exp-total");
  const elRest  = document.getElementById("exp-rest");
  const elHExp  = document.getElementById("history-exp-total");
  const elHPay  = document.getElementById("history-payment-total");
  
  if (elTotal) elTotal.textContent = total;
  if (elRest)  elRest.textContent = rest;
  if (elHExp)  elHExp.textContent = total;
  if (elHPay)  elHPay.textContent = payment;

  const outputIds = {
    "exp-used-level": expUse['level'] || 0,
    "exp-used-general-skills": expUse['generalSkills'] || 0,
    "exp-used-connections": expUse['connections'] || 0,
    "exp-used-joubika": expUse['joubika'] || 0,
    "exp-used-stt": expUse['stt'] || 0
  };
  
  for (let id in outputIds) {
    const el = document.getElementById(id);
    if (el) {
      const val = Number(outputIds[id]);
      el.textContent = val;
      el.classList.toggle('error', val < 0);
    }
  }

  if (elRest) {
    elRest.classList.toggle('error', rest < 0);
  }
  
  const outputIdsH = document.forms['sheet'];
  if(outputIdsH.expUsedLevel) {
    outputIdsH.expUsedLevel.value         = document.getElementById('exp-used-level').textContent || 0;
    outputIdsH.expUsedGeneralSkills.value = document.getElementById('exp-used-general-skills').textContent || 0;
    outputIdsH.expUsedConnections.value   = document.getElementById('exp-used-connections').textContent || 0;
    outputIdsH.expUsedJoubika.value       = document.getElementById('exp-used-joubika').textContent || 0;
    outputIdsH.expUsedStt.value           = document.getElementById('exp-used-stt').textContent || 0;
  }
}

function calcSkills() {
  const form = document.forms['sheet'];
  const skillsNum = Number(form.skillsNum?.value) || 0;
  
  let generalCount = 0;
  
  for (let num = 1; num <= skillsNum; num++) {
    const objName = form[`skill${num}Name`];
    const objType = form[`skill${num}Type`];
    
    if (objName && objType) {
      const type = objType.value;
      
      const tr = objName.closest('tr');
      const isTrash = tr && tr.closest('#skills-trash');
      
      if (!isTrash && type === '汎用') { 
        generalCount++; 
      }
    }
  }
  
  expUse['generalSkills'] = (generalCount - 1) * 5;
  calcExp();
  updateSkillHistoryTable();
}

function getSttExp(val) {
  let exp = 0;
  for (let i = 1; i <= val; i++) {
    let before = i - 1;
    if (before <= 18) exp += 30;
    else if (before === 19) exp += 50;
    else if (before <= 22) exp += 60;
    else if (before <= 25) exp += 90;
    else if (before <= 28) exp += 120;
    else exp += 150;
  }
  return exp;
}

window.addEventListener('DOMContentLoaded', () => {
  const form = document.forms['sheet'];
  if (form) {
    let triggered = false;
    for (let i = 1; i <= 3; i++) {
      if (form[`sttBase${i}Class`] && form[`sttBase${i}Class`].value) {
        if (form[`sttBase${i}Tai`] && form[`sttBase${i}Tai`].value === '') {
           changeBaseClass(i);
           triggered = true;
        }
      }
    }
    if (triggered) {
      calcStt();
      calcBattle();
    }
  }
});

function updateSkillHistoryTable() {
  const container = document.getElementById('skill-history-table-container');
  if (!container) return;

  const form = document.forms['sheet'];
  const charaLv = Number(form.level?.value) || 1;
  const classesNum = Number(form.classesNum?.value) || 1;
  const skillsNum = Number(form.skillsNum?.value) || 1;

  const classLvMap = { 'ガーディアン': charaLv };
  for (let i = 1; i <= classesNum; i++) {
    const cName = form[`class${i}Name`]?.value;
    const cLv = Number(form[`class${i}Lv`]?.value) || 0;
    if (cName) {
      classLvMap[cName] = (classLvMap[cName] || 0) + cLv;
    }
  }

  const cols = Object.keys(classLvMap).map(name => ({ name, lv: classLvMap[name] }));
  cols.sort((a, b) => {
    if (a.name === 'ガーディアン') return -1;
    if (b.name === 'ガーディアン') return 1;
    return b.lv - a.lv; 
  });

  let maxGetLv = 1;
  const hist = {};

  for (let num = 1; num <= skillsNum; num++) {
    const objName = form[`skill${num}Name`];
    const objType = form[`skill${num}Type`];
    const objLv = form[`skill${num}Lv`];
    const objGetLv = form[`skill${num}GetLv`];
    const objCategory = form[`skill${num}Category`]; 

    if (objName && objType && objGetLv && objName.value) {
      if (objName.closest('tr')?.closest('#skills-trash')) continue;

      const getLv = Number(objGetLv.value);
      if (!getLv || getLv < 1) continue;
      if (getLv > maxGetLv) maxGetLv = getLv;

      const type = objType.value;
      let name = objName.value;
      const lv = Number(objLv?.value) || 1;
      const category = objCategory?.value || '';

      let prefix = '';
      if (category.includes('自')) prefix = '[自]';
      else if (category.includes('選')) prefix = '[選]';

      if (!hist[getLv]) hist[getLv] = {};
      if (!hist[getLv][type]) hist[getLv][type] = [];

      hist[getLv][type].push({ name: prefix + name, lv, isOver: lv > getLv });
    }
  }

  let html = '<table class="data-table line-tbody" id="skill-history-table">';
  html += '<thead><tr><th style="width: 4em;">取得Lv</th>';
  cols.forEach(col => {
    const lvText = col.name === 'ガーディアン' ? '' : `(${col.lv})`;
    html += `<th>${col.name}${lvText}</th>`;
  });
  html += '</tr></thead><tbody>';

  for (let lv = 1; lv <= maxGetLv; lv++) {
    html += `<tr><th class="center">${lv}</th>`;
    cols.forEach(col => {
      const isDisabled = (col.name !== 'ガーディアン') && (lv > col.lv);
      const bgStyle = isDisabled ? 'background-color: rgba(0,0,0,0.05); color: rgba(0,0,0,0.3);' : '';
      
      html += `<td class="left" style="vertical-align: top; ${bgStyle}">`;
      if (!isDisabled && hist[lv] && hist[lv][col.name]) {
        hist[lv][col.name].forEach((item, idx) => {
          const border = idx > 0 ? 'border-top: 1px solid rgba(0,0,0,0.1); margin-top: 2px; padding-top: 2px;' : '';
          const overStyle = item.isOver ? 'font-weight:bold; color:#ff4444;' : '';
          html += `<div class="skill-hist-item" style="${border} ${overStyle}">${item.name}(${item.lv})</div>`;
        });
      }
      html += '</td>';
    });

    html += '</tr>';
  }
  html += '</tbody></table>';

  container.innerHTML = html;
}