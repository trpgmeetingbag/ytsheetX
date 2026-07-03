"use strict";
const gameSystem = 'mgr';


window.onload = function() {
  setName();

  // レベルの取得（エラー防止のため存在チェックを入れます）
  if(form.level){ level = Number(form.level.value); }

  // level = Number(form.level.value);
  // race = form.race.value;
  // classMainLv1    = form.classMainLv1.value;
  // classSupportLv1 = form.classSupportLv1.value;
  // [...Array(Number(form.level.value-1))].map((_, i) => checkGrow(i+2));
  // checkLv();
  // checkRace();
  // checkClass();
  // 
  // calcLvUpSkills();
  // calcBattle();
  // calcWeight();
  // calcCash();
  // changeHandedness();
  
  // システム共通のUI構築処理（絶対に呼ばれないといけない処理）
  imagePosition();
  changeColor();
  

  initArmamentParts();  // ←★これを追記
  calcJoubika(); // ←これを追加
  calcConnections();
  calcSkills();

  // これを追加（ページ読み込み時に自由記入欄の表示状態をセットする）
  changeSkillSource();
  calcClasses(); // （初期表示からCL経験点を-30にするため）
  calcStt();     // （能力値経験点を初期計算するため）
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名か二つ名のいずれかを入力してください。');
    form.characterName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}

// 【変更後】54行目付近の changeRegu() を丸ごと上書き
function changeRegu(){
  const form = document.forms['sheet'];
  const exp = form.history0Exp?.value || 0;
  
  // 履歴0行目（キャラクター作成）の経験点テキストを更新
  const elExp = document.getElementById('history0-exp');
  if(elExp) elExp.textContent = exp;

  // 経験点全体の再計算を呼び出す
  calcExp();
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
  
  // checkRace();
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
  //アーシアン専用ライフパス
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

  // クラス修正
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
  // 初期クラス修正
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

  // サポートクラス欄から条件に合わない選択肢を削除
  // レベルアップ履歴のクラスチェンジ欄から条件に合わない選択肢を削除
  document.querySelectorAll(`#levelup select[name$="Class"] option, select[name="classSupportLv1"] option`).forEach(opt => {
    const name = opt.value;
    if(classes[name]?.base || classes[name]?.limited){
      opt.style.display = (classes[name].base === classMainLv1 || classes[name].limited === classMainLv1 ? '' : 'none');
    }
  });
  // スキルの種別選択肢のクラス部分を書き換え
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
  //ライフパスの見出し
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

// ② 能力値の自動計算と経験点消費の算出
function calcStt() {
  let totalSttExp = 0; // 全能力値の消費経験点合計

  mgrSttNames.forEach(stt => {
    // 初期クラス1〜3の合計
    let baseTotal = 0;
    for (let i = 1; i <= 3; i++) {
      baseTotal += Number(form[`sttBase${i}${stt}`].value) || 0;
    }

    // 割り振り・成長などの取得
    let point = form[`sttPoint${stt}`].checked ? 1 : 0; 
    let grow  = Number(form[`sttGrow${stt}`].value) || 0;
    let skill = Number(form[`sttSkill${stt}`].value) || 0;
    let other = Number(form[`sttOther${stt}`].value) || 0;

    // ★能力値の経験点計算（累積値の差分）
    let initialValue = baseTotal + point;    // 成長前の値
    let targetValue  = initialValue + grow;  // 成長後の値
    
    // マイナス成長や0以下の入力を考慮した安全な差分計算
    if (grow > 0) {
      totalSttExp += getSttExp(targetValue) - getSttExp(initialValue);
    } else if (grow < 0) {
      totalSttExp -= (getSttExp(initialValue) - getSttExp(targetValue));
    }

    // 【合計】の算出と出力
    let total = baseTotal + point + grow + skill + other;
    form[`sttTotal${stt}`].value = total;

    // 【能力値ボーナス】の算出
    let bonusBase = Math.floor(total / 3);
    let bonusAdd  = Number(form[`sttBonusAdd${stt}`].value) || 0;
    
    form[`sttBonus${stt}`].value = bonusBase + bonusAdd;
  });

  // フッター用の変数に合算して経験点を再計算
  expUse['stt'] = totalSttExp;
  calcExp();

  // 戦闘値にも影響するため連鎖
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



// スキル計算 ----------------------------------------
// let skillType = {};
// let skillNum = {};
// let skillsLvLimitAddType = 0;
// let autoCalcSkill = {};
// function calcSkills(){
//   skillNum = {};
//   skillsLvLimitAddType = 0;
//   autoCalcSkill = {};
//   let total   = 0;
//   let general = 0;
//   let generalCount = 0; // ←★これを追加
//   for(let num = 1; num <= form['skillsNum'].value; num++){
//     const name = form[`skill${num}Name`].value;
//     const lv   = Number(form[`skill${num}Lv`].value);
//     let type = form[`skill${num}Type`].value;
//     if(classes[type]?.type === 'fate'){ type = 'power'; }
//     if(type === '汎用' && name) { generalCount++; } // ←★これを追加
//     if(lv){
//       if     (type === 'general'){ general += lv; }
//       else if(type === 'add'    ){ total += lv; skillsLvLimitAddType += 1 }
//       else if(type === 'geis'   ){ total += lv; skillsLvLimitAddType += 1 }
//       else if(type === 'power'  ){ total += lv; skillsLvLimitAddType -= lv }
//       else if(type === 'another'){ total += lv; skillsLvLimitAddType += lv }
//       else                       { total += lv; }
//     }
//     if(name){ skillType[name] = type; skillNum[name] = num; }
//     const bg = form['skill'+num+'Name'].parentNode.parentNode.parentNode.classList;
//     bg.toggle('race',    type === 'race'   );
//     bg.toggle('general', type === 'general');
//     bg.toggle('style',   type === 'style'  );
//     bg.toggle('faith',   type === 'faith'  );
//     bg.toggle('add',     type === 'add'    );
//     bg.toggle('geis',    type === 'geis'   );
//     bg.toggle('power',   type === 'power'  );
//     bg.toggle('another', type === 'another');
    
//     let markFlag = 0; //自動計算マーク

//     form[`skill${num}Name`].parentNode.classList.toggle('calc', markFlag);
//   }
//   expUse['generalSkills'] = Math.max(0, (generalCount - 1) * 5);

//   calcStt();
//   calcExp();
// }



// 武器・戦闘判定計算 ----------------------------------------
function calcBattle(){
  let weightW = 0;
  let weightA = 0;
  let acc  = 0;
  let atk  = 0;
  let eva  = 0;
  let def  = 0;
  let ini  = 0;
  let mdef = 0;
  let move = 0;
  ['HandR','HandL','Head','Body','Sub','Other'].forEach(id => {
    if(id.match(/Hand/)){ weightW += Number(form[`armament${id}Weight`].value) }
    else { weightA += Number(form[`armament${id}Weight`].value) }
    acc  += Number(form[`armament${id}Acc`].value);
    atk  += Number(form[`armament${id}Atk`].value);
    eva  += Number(form[`armament${id}Eva`].value);
    def  += Number(form[`armament${id}Def`].value);
    mdef += Number(form[`armament${id}MDef`].value);
    ini  += Number(form[`armament${id}Ini`].value);
    move += Number(form[`armament${id}Move`].value);
  });
  let accR = Number(form[`armamentHandRAcc`].value);
  let accL = Number(form[`armamentHandLAcc`].value);
  let atkR = Number(form[`armamentHandRAtk`].value);
  let atkL = Number(form[`armamentHandLAtk`].value);
  document.getElementById('armament-total-weight-weapon').textContent = weightW;
  document.getElementById('armament-total-weight-armour').textContent = weightA;
  document.getElementById('armament-total-acc-right').textContent = acc - accL;
  document.getElementById('armament-total-acc-left' ).textContent = acc - accR;
  document.getElementById('armament-total-atk-right').textContent = atk - atkL;
  document.getElementById('armament-total-atk-left' ).textContent = atk - atkR;
  document.getElementById('armament-total-eva'   ).textContent = eva ;
  document.getElementById('armament-total-def'   ).textContent = def ;
  document.getElementById('armament-total-mdef'  ).textContent = mdef;
  document.getElementById('armament-total-ini'   ).textContent = ini ;
  document.getElementById('armament-total-move'  ).textContent = move;

  acc  += sttRoll['Dex'];
  atk  += 0;
  eva  += sttRoll['Agi'];
  def  += 0;
  
  mdef += sttTotal['Mnd'];
  ini  += sttTotal['Agi'] + sttTotal['Sen'];
  move += sttTotal['Str'] + 5;
  
  let accDice = Number(form.rollDexDice.value);
  let atkDice = Number(form.rollStrDice.value);
  let evaDice = Number(form.rollAgiDice.value);

  ['Skill','Other'].forEach(id => {
    acc  += Number(form[`battle${id}Acc`].value);
    atk  += Number(form[`battle${id}Atk`].value);
    eva  += Number(form[`battle${id}Eva`].value);
    def  += Number(form[`battle${id}Def`].value);
    mdef += Number(form[`battle${id}MDef`].value);
    ini  += Number(form[`battle${id}Ini`].value);
    move += Number(form[`battle${id}Move`].value);
    
    accDice += Number(form[`battle${id}AccDice`].value);
    atkDice += Number(form[`battle${id}AtkDice`].value);
    evaDice += Number(form[`battle${id}EvaDice`].value);
  });
  if( def < 0){  def = 0; }
  if(mdef < 0){ mdef = 0; }
  ['HandR','HandL','Head','Body','Sub','Other'].forEach(id => {
    const obj = form[`armament${id}Move`];
    obj.classList.toggle('error', Number(obj.value) < 0 && move <= 0);
  });
  document.getElementById('battle-total-acc' ).textContent = acc ;
  document.getElementById('battle-total-acc-right').textContent = acc - accL;
  document.getElementById('battle-total-acc-left' ).textContent = acc - accR;
  document.getElementById('battle-total-atk' ).textContent = atk ;
  document.getElementById('battle-total-atk-right').textContent = atk - atkL;
  document.getElementById('battle-total-atk-left' ).textContent = atk - atkR;
  document.getElementById('battle-total-eva' ).textContent = eva ;
  document.getElementById('battle-total-def' ).textContent = def ;
  document.getElementById('battle-total-mdef').textContent = mdef;
  document.getElementById('battle-total-ini' ).textContent = ini ;
  document.getElementById('battle-total-move').textContent = move;
  document.getElementById('battle-dice-acc').textContent = accDice;
  document.getElementById('battle-dice-atk').textContent = atkDice;
  document.getElementById('battle-dice-eva').textContent = evaDice;
}

// 特殊な判定計算 ----------------------------------------
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

// 携行重量計算 ----------------------------------------
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

// 収支履歴計算 ----------------------------------------
function calcCash(){
  let cash = 0;
  //let deposit = 0;
  //let debt = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Money'];
    let hCash = safeEval(obj.value);
    if(isNaN(hCash)){
      obj.classList.add('error');
    }
    else {
      cash += hCash;
      obj.classList.remove('error');
    }
    if(isNaN(hCash)){
      obj
    }
  }
  document.getElementById("history-money-total").textContent = cash;
  let s = form.cashbook.value;
  s.replace(
    /::([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      cash += safeEval(num.slice(2)) || 0;
    }
  );
  s.replace(
    /:>([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      deposit += safeEval(num.slice(2)) || 0;
    }
  );
  s.replace(
    /:<([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      debt += safeEval(num.slice(2)) || 0;
    }
  );
  cash = cash //- deposit + debt;
  document.getElementById('cashbook-total-value').textContent = cash;
  //document.getElementById('cashbook-deposit-value').textContent = deposit;
  //document.getElementById('cashbook-debt-value').textContent = debt;
  if(form.moneyAuto.checked){
    form.money.value = commify(cash);
    form.money.readOnly = true;
  }
  else {
    form.money.readOnly = false;
  }
}

// コネクション計算 ----------------------------------------
function calcConnections(){
  expUse['connections'] = 0;
  for(let i = 1; i <= Number(form.connectionsNum.value); i++){
    if(form[`connection${i}Joubika`].checked) expUse['connections']++;
  }
  calcExp();
}

// 誓約計算 ----------------------------------------
function calcGeises(){
  expUse['geises'] = 0;
  for(let i = 1; i <= Number(form.geisesNum.value); i++){
    expUse['geises'] += Number(form[`geis${i}Cost`].value);
  }
  calcExp();
}



// ==========================================
// 特技（スキル）欄（増減・ゴミ箱機能 復活版）
// ==========================================
// 追加
function addSkill(){
  document.querySelector("#skills-table tfoot").before(createRow('skill','skillsNum'));
  updateSkillSourceOptions(); // MGR固有処理：クラスリストの同期
}
// 削除
function delSkill(){
  if(delRow('skillsNum', '#skills-table tbody:last-of-type')){
    calcSkills();
  }
}
// ソートとゴミ箱機能（ゆとシートAR2Eの標準機能を完全復元）
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

// コネクション欄 ----------------------------------------
// 追加
function addConnection(){
  document.querySelector("#connections-table tbody").append(createRow('connection','connectionsNum'));
}
// 削除
function delConnection(){
  if(delRow('connectionsNum', '#connections-table tbody tr:last-of-type')){
    calcConnections();
  }
}
// ソート
setSortable('connection','#connections-table tbody','tr');



// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcExp(); calcCash();
  }
}
// ソート
setSortable('history','#history-table','tbody');


// ==========================================
// MGR用 データ定義（※将来的にPerl出力へ移行）
// ==========================================
const dummyBattle = {
  "1": { "Meichu":1, "Kaihi":1, "Hougeki":1, "Bouheki":1, "Koudou":1, "Rikiba":1, "Taikyu":1, "Kannou":1, "Kougeki":1 },
  "2": { "Meichu":2, "Kaihi":2, "Hougeki":2, "Bouheki":2, "Koudou":2, "Rikiba":2, "Taikyu":2, "Kannou":2, "Kougeki":2 },
  "3": { "Meichu":4, "Kaihi":4, "Hougeki":4, "Bouheki":4, "Koudou":4, "Rikiba":4, "Taikyu":4, "Kannou":4, "Kougeki":4 }
};

// // HTML側の古い定義を上書き
// const mgrClasses = {
//   "ストライカー": { "type": "リンケージ",   "stt": { "Tai":1, "Han":1, "Chi":1, "Ri":1, "Ishi":1, "Kou":1 }, "battle": dummyBattle },
//   "コンダクター": { "type": "リンケージ",   "stt": { "Tai":2, "Han":2, "Chi":2, "Ri":2, "Ishi":2, "Kou":2 }, "battle": dummyBattle },
//   "カバリエ":     { "type": "ガーディアン", "stt": { "Tai":4, "Han":4, "Chi":4, "Ri":4, "Ishi":4, "Kou":4 }, "battle": dummyBattle },
//   "ディザスター": { "type": "ガーディアン", "stt": { "Tai":8, "Han":8, "Chi":8, "Ri":8, "Ishi":8, "Kou":8 }, "battle": dummyBattle }
// };

// MGRの能力値配列
const mgrSttNames = ['Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou'];






// ==========================================
// MGR用 自動計算ロジック
// ==========================================

// ① 初期クラスの基本値取得
// function changeBaseClass(num) {

//   const name = document.forms['sheet'][`sttBase${num}Class`].value;
//   const data = mgrClasses[name];
//   const typeInput = document.forms['sheet'][`sttBase${num}Type`]; // 種別入力欄
  
//   if (data) {
//     // 種別の自動判定
//     document.forms['sheet'][`sttBase${num}Type`].value = (data.type === 'linkage' ? 'リンケージ' : 'ガーディアン');

    
//     // 各能力値の基本値を自動入力
//     if (data.stt) {
//       for (let s in data.stt) {
//         if (document.forms['sheet'][`sttBase${num}${s}`]) {
//           document.forms['sheet'][`sttBase${num}${s}`].value = data.stt[s];
//         }
//       }
//     }
//   }
//   else {
//     // 空欄、または知らないクラスならリセット
//     form[`sttBase${num}Type`].value = '';
//     mgrSttNames.forEach(stt => {
//       form[`sttBase${num}${stt}`].value = '';
      
//     });

//   }
  
//   // 値が変わったので、能力値の再計算へ連鎖させる
//   calcStt();
//   calcClasses();
// }

function changeBaseClass(num) {
  const form = document.forms['sheet'];
  const name = form[`sttBase${num}Class`].value;
  const data = mgrClasses[name];
  const typeInput = form[`sttBase${num}Type`];
  const mgrSttNames = ['Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou'];
  
  if (data) {
    // データがある場合は自動入力し、編集不可にする
    typeInput.value = (data.type === 'linkage' ? 'リンケージ' : 'ガーディアン');
    typeInput.readOnly = true;
    typeInput.tabIndex = -1; // Tabキーで飛ばす

    if (data.stt) {
      mgrSttNames.forEach(s => {
        if (form[`sttBase${num}${s}`]) {
          form[`sttBase${num}${s}`].value = data.stt[s];
        }
      });
    }
  } else {
    // データがない（未知のクラス）場合は、ロックを解除し、値を空にリセットする
    typeInput.readOnly = false;
    typeInput.tabIndex = 0; // Tabキーで移動可能にする
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


// クラス欄の追加（▼ボタン）
function addClass() {
  const num = Number(form.classesNum.value) + 1; // これから追加される行番号
  document.querySelector("#classes-table tbody").append(createRow('class','classesNum'));

  // MGR専用：戦闘値表のクラス行も連動して追加（JSで動的に生成）
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

// クラス欄の削除（▲ボタン）
function delClass() {
  const num = Number(form.classesNum.value);
  if (delRow('classesNum', '#classes-table tbody tr:last-of-type')) {
    // MGR専用：戦闘値表のクラス行も連動して削除
    const battleRow = document.getElementById(`battle-class-row${num}`);
    if (battleRow) battleRow.remove();
    calcClasses(); // 削除後に戦闘値などを再計算
  }
}

// ② 能力値の自動計算と経験点消費の算出（デバッグログ付き）
function calcStt() {
  console.log("=== calcStt 処理開始 ===");
  let totalSttExp = 0; // 全能力値の消費経験点合計

  mgrSttNames.forEach(stt => {
    // 初期クラス1〜3の合計
    let baseTotal = 0;
    for (let i = 1; i <= 3; i++) {
      baseTotal += Number(form[`sttBase${i}${stt}`]?.value) || 0;
    }

    // 割り振り・成長などの取得
    let point = form[`sttPoint${stt}`]?.checked ? 1 : 0; 
    let grow  = Number(form[`sttGrow${stt}`]?.value) || 0;
    let skill = Number(form[`sttSkill${stt}`]?.value) || 0;
    let other = Number(form[`sttOther${stt}`]?.value) || 0;

    // ★能力値の経験点計算（累積値の差分）
    let initialValue = baseTotal + point;    // 成長前の値
    let targetValue  = initialValue + grow;  // 成長後の値
    
    let sttExp = 0;
    if (grow > 0) {
      sttExp = getSttExp(targetValue) - getSttExp(initialValue);
    } else if (grow < 0) {
      sttExp = -(getSttExp(initialValue) - getSttExp(targetValue));
    }
    
    // デバッグログ：成長が入力されている能力値のみ出力
    if (grow !== 0) {
      console.log(`[${stt}] 成長前:${initialValue} -> 成長後:${targetValue} | 消費経験点: ${sttExp}`);
    }

    totalSttExp += sttExp;

    // 【合計】の算出と出力
    let total = baseTotal + point + grow + skill + other;
    if (form[`sttTotal${stt}`]) form[`sttTotal${stt}`].value = total;

    // 【能力値ボーナス】の算出
    let bonusBase = Math.floor(total / 3);
    let bonusAdd  = Number(form[`sttBonusAdd${stt}`]?.value) || 0;
    
    if (form[`sttBonus${stt}`]) form[`sttBonus${stt}`].value = bonusBase + bonusAdd;
  });

  console.log(`=== 全能力値の消費経験点合計: ${totalSttExp} ===`);

  // フッター用の変数に合算して経験点を再計算
  expUse['stt'] = totalSttExp;
  calcExp();

  // 戦闘値にも影響するため連鎖
  calcBattle();
}

// ==========================================
// MGR用 UI制御・イベントバインド
// ==========================================

// 割り振りチェックボックスの排他処理（イベントデリゲーション）
document.addEventListener('change', function(e) {
  // 変更されたのが「sttPoint」から始まる名前のチェックボックスなら
  if (e.target && e.target.name && e.target.name.startsWith('sttPoint')) {
    if (e.target.checked) {
      const form = document.forms['sheet'];
      const clickedStt = e.target.name.replace('sttPoint', ''); // クリックされた能力値を取得
      
      // 他のチェックボックスを外す
      mgrSttNames.forEach(stt => {
        if (stt !== clickedStt) {
          const otherBox = form[`sttPoint${stt}`];
          if (otherBox) otherBox.checked = false;
        }
      });
      calcStt(); // 再計算をトリガー
    }
  }

  // 2. 装備の「乗機」排他処理
  if (e.target && e.target.name && e.target.name.match(/^armament(\d+)Equip$/)) {
    if (e.target.checked) {
      const num = RegExp.$1;
      const partVal = form[`armament${num}Part`]?.value || '';
      
      // チェックした装備が「乗機」を含む場合
      if (/乗機/.test(partVal)) {
        const armamentsNum = Number(form.armamentsNum.value) || 1;
        for (let i = 1; i <= armamentsNum; i++) {
          if (i !== Number(num)) {
            const otherPart = form[`armament${i}Part`]?.value || '';
            const otherCheck = form[`armament${i}Equip`];
            // 他の「乗機」装備のチェックを外す
            if (/乗機/.test(otherPart) && otherCheck && otherCheck.checked) {
              otherCheck.checked = false;
            }
          }
        }
      }
    }
    calcBattle(); // 変更後に戦闘値を再計算
  }
});

// ③ クラス修正の表への反映
// ③ クラス修正の表への反映とCL消費経験点の計算
function calcClasses() {
  const form = document.forms['sheet'];
  const classesNum = Number(form.classesNum.value) || 1;
  let totalClassLv = 0; // ★CL（すべてのクラスレベルの合計）

  for (let i = 1; i <= classesNum; i++) {
    const className = form[`class${i}Name`]?.value || '';
    const classLv = Number(form[`class${i}Lv`]?.value) || 0;
    
    totalClassLv += classLv; // ★クラスレベルを合算

    // 1. 戦闘値表のクラス名とLv欄のテキストを更新
    const nameCell = document.getElementById(`battle-class-name${i}`);
    const lvCell = document.getElementById(`battle-class-lv${i}`);
    if (nameCell) nameCell.textContent = className || '―';
    if (lvCell) lvCell.textContent = classLv || 0;

    // 2. クラスデータに基づく戦闘値修正の入力を更新
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

  // ★CLに基づく消費経験点の算出（テーブルの適用）
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

  // これを追加（クラスが書き換えられたら取得元のリストも更新する）
  updateSkillSourceOptions();
  updateClassBattleValues();
  
  // クラスの修正値が変わったので、戦闘値の合計も再計算へ連鎖
  calcBattle();
  
  // ★経験点の再計算を呼び出し
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
          // 定義済みクラスかつ定義済みレベルなら、自動入力してロック
          input.value = classData.battle[lv][s] || 0;
          input.readOnly = true;
          input.tabIndex = -1;
        } else {
          // 未知のクラス、または定義外のレベルなら、ロックを解除して手入力を許可（値はリセットせず手入力を維持）
          input.readOnly = false;
          input.tabIndex = 0;
        }
      }
    });
    
    // 見出しの更新
    const nameDisp = document.getElementById(`battle-class-name${i}`);
    const lvDisp   = document.getElementById(`battle-class-lv${i}`);
    if (nameDisp) nameDisp.textContent = name || 'クラス名';
    if (lvDisp)   lvDisp.textContent   = lv   || 'Lv';
  }
  calcBattle();
}


// ④ 戦闘値と未装備小計の自動計算
function calcBattle() {
  const form = document.forms['sheet'];

  // --- Step 1: ベース値の算出 ---
  // 体力と意志は基本値(Total)を、その他はボーナスを参照
  const baseTai  = Number(form['sttTotalTai']?.value) || 0;
  const baseIshi = Number(form['sttTotalIshi']?.value) || 0;

  const bonTai = Number(form['sttBonusTai']?.value) || 0; // ←★これを追加

  const bonHan = Number(form['sttBonusHan']?.value) || 0;
  const bonChi = Number(form['sttBonusChi']?.value) || 0;
  const bonKou = Number(form['sttBonusKou']?.value) || 0;
  const bonRi  = Number(form['sttBonusRi']?.value) || 0;

  // 各種数式（端数切り捨て）
  const baseMeichu  = Math.floor((bonHan + bonChi) / 2);
  const baseKaihi   = Math.floor((bonHan + bonKou) / 2);
  const baseHougeki = Math.floor((bonRi + bonChi) / 2);
  const baseBouheki = Math.floor((bonRi + bonKou) / 2); // 遠隔＝防壁
  const baseKoudou  = bonHan + bonRi;
  const baseRikiba  = 0;
  const baseTaikyu  = baseTai;
  const baseKannou  = baseIshi;
  const baseIdou    = Math.floor(bonTai / 3); // ←★これを追加

  // HTMLのベース枠へ出力
  if(form.battleBaseMeichu)  form.battleBaseMeichu.value  = baseMeichu;
  if(form.battleBaseKaihi)   form.battleBaseKaihi.value   = baseKaihi;
  if(form.battleBaseHougeki) form.battleBaseHougeki.value = baseHougeki;
  if(form.battleBaseBouheki) form.battleBaseBouheki.value = baseBouheki;
  if(form.battleBaseKoudou)  form.battleBaseKoudou.value  = baseKoudou;
  if(form.battleBaseRikiba)  form.battleBaseRikiba.value  = baseRikiba;
  if(form.battleBaseTaikyu)  form.battleBaseTaikyu.value  = baseTaikyu;
  if(form.battleBaseKannou)  form.battleBaseKannou.value  = baseKannou;
  if(form.battleBaseIdou)    form.battleBaseIdou.value    = baseIdou; // ←★これを追加

  // --- Step 2: 未装備小計の算出 ---
  const battleStts = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou', 'Idou']; // ← Idou を追加
  const classesNum = Number(form.classesNum.value) || 1;

  battleStts.forEach(stt => {
    // ベース値 ＋ 手動ベース修正値
    let subtotal = Number(form[`battleBase${stt}`]?.value) || 0;
    subtotal += Number(form[`battleBaseAdd${stt}`]?.value) || 0;

    // クラス行の合算
    for (let i = 1; i <= classesNum; i++) {
      subtotal += Number(form[`battleClass${i}${stt}`]?.value) || 0;
    }

    // 小計枠へ出力
    if(form[`battleSubtotal${stt}`]) form[`battleSubtotal${stt}`].value = subtotal;
  });

  // 攻撃はベース枠がないため特別扱い
  let kougekiSubtotal = Number(form[`battleBaseAddKougeki`]?.value) || 0;
  for (let i = 1; i <= classesNum; i++) {
    kougekiSubtotal += Number(form[`battleClass${i}Kougeki`]?.value) || 0;
  }
  if(form.battleSubtotalKougeki) form.battleSubtotalKougeki.value = kougekiSubtotal;

// --- Step 3: 装備品の合算 ---
  const armamentsNum = Number(form.armamentsNum.value) || 1;
  const battleSttsAll = ['Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou', 'Idou', 'Joubi', 'Kougeki'];
  
  let total = {};
  // 小計を初期値としてセット
  battleSttsAll.forEach(stt => {
    total[stt] = Number(form[`battleSubtotal${stt}`]?.value) || 0;
  });
  // 常備化は小計欄がないため0スタート
  total['Joubi'] = 0;
  // 攻撃は独立しているので取得
  total['Kougeki'] = Number(form.battleSubtotalKougeki?.value) || 0;

  for (let i = 1; i <= armamentsNum; i++) {
    const isEquipped = form[`armament${i}Equip`]?.checked;
    const partVal = form[`armament${i}Part`]?.value || '';
    
    // TRPGのセオリーに従い、常備化点は「装備（チェック）の有無に関わらず所持しているだけで合算」としています
    total['Joubi'] += Number(form[`armament${i}Joubi`]?.value) || 0;

    // チェックが入っている装備のみ合算
    if (isEquipped) {
      battleSttsAll.forEach(stt => {
        if (stt === 'Joubi') return; // 常備化は計算済なのでスキップ
        
        let val = Number(form[`armament${i}${stt}`]?.value) || 0;
        
        // 攻撃の例外処理：「属性」が入力可能な部位（武器）の場合は合算しない
        if (stt === 'Kougeki' && /[主副近遠武]/.test(partVal)) {
          val = 0; 
        }
        
        total[stt] += val;
      });
    }
  }

  // --- Step 4: HTMLの合計枠へ出力 ---
  battleSttsAll.forEach(stt => {
    if(form[`battleTotal${stt}`]) form[`battleTotal${stt}`].value = total[stt];
  });
  calcJoubika(); // ←これを追加（装備の常備化を武具小計に反映させるため）

}

// 1. エラー回避：HTML側に残っているcalcPriceをcalcBattleに流す
function calcPrice() {
  calcBattle();
}

// 属性入力欄の動的制御 ＋ 防御・解説の自動同期（input イベント）
// 属性・射程・代償・弾数入力欄の動的制御 ＋ 防御・解説の自動同期（input イベント）
document.addEventListener('input', function(e) {
  if (e.target && e.target.name) {
    // armament(数字)Part または armament(数字)Name が書き換えられたかチェック
    const m = e.target.name.match(/^armament(\d+)(Part|Name)$/);
    if (m) {
      const num = m[1];
      const type = m[2]; // 'Part' または 'Name'

      if (type === 'Part') {
        const zokuseiInput = document.forms['sheet'][`armament${num}Zokusei`];
        const shateiInput  = document.forms['sheet'][`armament${num}Shatei`];
        const daishouInput = document.forms['sheet'][`armament${num}Daishou`];
        const danzuuInput  = document.forms['sheet'][`armament${num}Danzuu`];

        if (/[主副近遠武]/.test(e.target.value)) {
          // 武装の場合：ロック解除＆デッドスペース解除
          if(zokuseiInput) { zokuseiInput.readOnly = false; zokuseiInput.tabIndex = 0; zokuseiInput.parentNode.classList.remove('dead-space'); }
          if(shateiInput)  { shateiInput.readOnly = false;  shateiInput.tabIndex = 0;  shateiInput.parentNode.classList.remove('dead-space'); }
          if(daishouInput) { daishouInput.readOnly = false; daishouInput.tabIndex = 0; daishouInput.parentNode.classList.remove('dead-space'); }
          if(danzuuInput)  { danzuuInput.readOnly = false;  danzuuInput.tabIndex = 0;  danzuuInput.parentNode.classList.remove('dead-space'); }
        } else {
          // 武装以外の場合：ロック＆値クリア＆デッドスペース付与
          if(zokuseiInput) { zokuseiInput.readOnly = true; zokuseiInput.tabIndex = -1; zokuseiInput.value = ''; zokuseiInput.parentNode.classList.add('dead-space'); }
          if(shateiInput)  { shateiInput.readOnly = true;  shateiInput.tabIndex = -1;  shateiInput.value = '';  shateiInput.parentNode.classList.add('dead-space'); }
          if(daishouInput) { daishouInput.readOnly = true; daishouInput.tabIndex = -1; daishouInput.value = ''; daishouInput.parentNode.classList.add('dead-space'); }
          if(danzuuInput)  { danzuuInput.readOnly = true;  danzuuInput.tabIndex = -1;  danzuuInput.value = '';  danzuuInput.parentNode.classList.add('dead-space'); }
        }
      }
      
      // 部位か名前が変わったら同期処理を走らせる
      syncArmamentToAutoRows(num);
      calcBattle(); // 属性の有効化等による戦闘値の再計算
    }
  }
});

// 3. ページ読み込み時に、既存の装備データの入力可否を判定する初期化関数
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
    // ★ページ表示時にも同期と振り分けを実行
    syncArmamentToAutoRows(i);
  }
}

// 装備欄の追加（▼ボタン）と、連動する自動行の生成
function addArmament() {
  const form = document.forms['sheet'];
  const num = Number(form.armamentsNum.value) + 1;
  document.querySelector("#armaments-area").append(createRow('armament','armamentsNum'));
  
  // 防御修正の自動行を生成
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
  `; // ←★ここにあった ${num}Type を削除
  document.getElementById('defences-auto-area').append(defTr);

  // 装備解説の自動行を生成
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


// 装備欄の「部位」「名前」を、防御修正と装備解説の自動行に同期・表示切り替えする関数
// 装備欄の「部位」「名前」を、防御修正と装備解説の自動行に同期・表示切り替えする関数
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

  // 1. 装備解説：部位が入力されていれば【すべての装備】を表示
  if (!partVal) {
    if (noteRow) noteRow.style.display = 'none';
  } else {
    if (noteRow) {
      noteRow.style.display = '';
      if (notePart) notePart.value = partVal;
      if (noteName) noteName.value = nameVal;
    }
  }

  // 2. 防御修正：【武装以外】（主副近遠が含まれない装備）のみ表示
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

// 手動・防御修正欄の追加（▼ボタン）
function addDefence() {
  document.querySelector("#defences-area").append(createRow('defence','defencesNum'));
}

// 手動・防御修正欄の削除（▲ボタン）
function delDefence() {
  if (delRow('defencesNum', '#defences-area tr:last-of-type')) {
    calcBattle();
  }
}

// ==========================================
// MGR用 ソート（ドラッグ移動）機能と完全同期
// ==========================================

// 1. クラスと手動防御修正は、従来通り標準の setSortable を使う
setSortable('class', '#classes-table tbody', 'tr');
setSortable('defence', '#defences-area', 'tr');

// 2. 装備エリアは独自にソートを定義し、自動行の移動と全IDの振り直しを完全同期する
const armamentsArea = document.getElementById('armaments-area');
if (armamentsArea) {
  Sortable.create(armamentsArea, {
    group: "armaments",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template', // 見出しやテンプレートをドラッグから除外
    onUpdate: function (evt) {
      const defArea = document.getElementById('defences-auto-area');
      const noteArea = document.getElementById('armament-notes-auto-area');

      // ① まず、並べ替えられた装備エリアの「変更前のID」に従って、自動行を物理的に並べ替える
      Array.from(armamentsArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        
        const input = tr.querySelector('input[name^="armament"]');
        if (input) {
          const match = input.name.match(/^armament(\d+)/);
          if (match) {
            const oldNum = match[1]; // 変更前のID番号
            
            // 対応する自動行を新しい位置（末尾）へ移動
            const defRow = document.getElementById(`defence-auto-row${oldNum}`);
            if (defRow && defArea) defArea.appendChild(defRow);

            const noteRow = document.getElementById(`armament-note-auto-row${oldNum}`);
            if (noteRow && noteArea) noteArea.appendChild(noteRow);
          }
        }
      });

      // ② 装備行のID（name属性）を上から順番に 1, 2, 3... と綺麗に振り直す
      let num = 1;
      Array.from(armamentsArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        tr.id = `armament-row${num}`;
        replaceSortedNames(tr, num, /^(armament)\d+(.+)$/);
        num++;
      });

      // ③ 防御修正の自動行のIDも 1, 2, 3... と振り直す
      num = 1;
      Array.from(defArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        tr.id = `defence-auto-row${num}`;
        replaceSortedNames(tr, num, /^(defenceAuto)\d+(.+)$/);
        num++;
      });

      // ④ 装備解説の自動行のIDも 1, 2, 3... と振り直す
      num = 1;
      Array.from(noteArea.children).forEach(tr => {
        if (tr.tagName !== 'TR' || tr.id.match(/TMPL/)) return;
        tr.id = `armament-note-auto-row${num}`;
        replaceSortedNames(tr, num, /^(armamentNoteAuto)\d+(.+)$/);
        num++;
      });

      calcBattle(); // 全ての同期が終わったら戦闘値を再計算
    }
  });
}

// 3. クラス行のソート後処理（マウスアップ・タッチエンド時の再計算バックアップ）
['mouseup', 'touchend'].forEach(eventName => {
  document.addEventListener(eventName, function(e) {
    if (e.target.closest('#classes-table .handle')) {
      setTimeout(() => { calcClasses(); calcBattle(); }, 200);
    }
  });
});


// ==========================================
// MGR用 装備・防御・解説の増減
// ==========================================

// 装備欄の追加（▼ボタン）と、連動する自動行の生成
function addArmament() {
  const form = document.forms['sheet'];
  const num = Number(form.armamentsNum.value) + 1; // これから追加される番号
  document.querySelector("#armaments-area").append(createRow('armament','armamentsNum'));
  
  // 防御修正の自動行を生成
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

  // 装備解説の自動行を生成
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

// 装備欄の削除（▲ボタン）と、連動する自動行の削除
// 装備欄の削除（▲ボタン）と、連動する自動行の確実な削除
function delArmament() {
  const armamentsArea = document.querySelector('#armaments-area');
  const lastRow = armamentsArea ? armamentsArea.querySelector('tr:last-of-type') : null;
  
  if (lastRow) {
    // 1. 消去される直前の装備行から「実際のデータ番号（ID）」を正確に読み取る
    let targetNum = null;
    const input = lastRow.querySelector('input[name^="armament"]');
    if (input) {
      const match = input.name.match(/^armament(\d+)/);
      if (match) targetNum = match[1];
    }

    // 2. 装備行を削除（ゆとシートの標準機能）
    if (delRow('armamentsNum', '#armaments-area tr:last-of-type')) {
      
      // 3. 読み取ったデータ番号と完全に一致する自動行だけをピンポイントで削除
      if (targetNum) {
        const defRow = document.getElementById(`defence-auto-row${targetNum}`);
        if (defRow) defRow.remove();
        
        const noteRow = document.getElementById(`armament-note-auto-row${targetNum}`);
        if (noteRow) noteRow.remove();
      }
      calcBattle(); // 削除完了後に戦闘値を再計算
    }
  }
}


// ==========================================
// 加護欄
// ==========================================
// 追加
function addKago(){
  document.querySelector("#kagos-table tbody").append(createRow('kago','kagosNum'));
}
// 削除
function delKago(){
  delRow('kagosNum', '#kagos-table tbody tr:last-of-type');
}
// ソート（ドラッグ＆ドロップ）
setSortable('kago','#kagos-table tbody','tr');

// ==========================================
// MGR用 特技（スキル）欄の動的制御
// ==========================================

// 特技の「取得元」プルダウンに、現在のクラス欄の内容を動的に反映させる
// 特技の「取得元」プルダウンに、現在のクラス欄の内容を動的に反映させる
// 特技の「取得元」プルダウンに、現在のクラス欄の内容を動的に反映させる
function updateSkillSourceOptions() {
  const form = document.forms['sheet'];
  const classesNum = Number(form.classesNum?.value) || 1;
  const skillsNum = Number(form.skillsNum?.value) || 1;
  
  // 1. 現在画面に入力されているクラス名を【上から順に】集める
  const currentClasses = new Set();
  for (let i = 1; i <= classesNum; i++) {
    const className = form[`class${i}Name`]?.value;
    if (className) currentClasses.add(className);
  }

  for (let i = 1; i <= skillsNum; i++) {
    // 2. 実データを持っている <input>（テキストボックス）を取得
    const input = form[`skill${i}Type`]; 
    if (!input) continue;

    // 3. その直前にあるダミーの <select> を取得
    const select = input.previousElementSibling;
    if (!select || select.tagName.toLowerCase() !== 'select') continue;
    
    // 現在保存されている実データを退避
    const selectedValue = input.value; 
    const defaultOptions = ['ガーディアン', '汎用', 'アシスト', '勲章'];

    // ★重要：プルダウンの中身を一旦「完全リセット」して、確実な順番で作り直す
    select.innerHTML = '';
    
    // ① 先頭の空欄を追加
    select.appendChild(new Option('', ''));
    
    // ② クラス／レベルの順番通りにクラスを追加
    currentClasses.forEach(className => {
      select.appendChild(new Option(className, className));
    });
    
    // ③ ガーディアン・汎用などの基本枠を追加
    defaultOptions.forEach(opt => {
      select.appendChild(new Option(opt, opt));
    });
    
    // ④ 最後に「その他（自由記入）」を追加
    select.appendChild(new Option('その他（自由記入）', 'free'));

    // 現在のデータが「基本枠」でも「現在のクラス」でもない完全な自由記入かの判定
    let isFree = false;
    if (selectedValue && !defaultOptions.includes(selectedValue) && !currentClasses.has(selectedValue)) {
      isFree = true;
    }

    // 4. セレクトボックスとテキストボックスの表示を正しく同期させる
    if (isFree) {
      select.value = 'free'; // プルダウンは「その他（自由記入）」に合わせる
      input.style.display = 'inline-block'; // テキストボックスを表示
    } else {
      select.value = selectedValue; // プルダウンを該当のクラス名などに合わせる
      input.style.display = 'none'; // テキストボックスを隠す
      input.value = selectedValue; // 念のため実データをプルダウンに同期
    }
  }
}

// 取得元で「その他（自由記入）」を選んだときの入力欄切り替え
function changeSkillSource(selectObj) {
  if(selectObj) {
    selectObj.parentNode.classList.toggle('free', selectObj.value === 'free');
  } else {
    const form = document.forms['sheet'];
    const skillsNum = Number(form.skillsNum?.value) || 1;
    for (let i = 1; i <= skillsNum; i++) {
      const select = form[`skill${i}Type`]; // ★Typeに変更
      if(select) select.parentNode.classList.toggle('free', select.value === 'free');
    }
  }
}

// ==========================================
// MGR用 常備化・アイテム欄の処理
// ==========================================
function calcJoubika() {
  const form = document.forms['sheet'];
  
  // 経験点変換分の計算（消費経験点 × 10）
  const expUsed = Number(form.joubikaExpUsed?.value) || 0;
  const expAdd = expUsed * 10;
  if(form.joubikaExpAdd) form.joubikaExpAdd.value = expAdd;
  
  // 最大値の計算（基本50 ＋ 特技追加 ＋ 経験点変換分）
  const skillAdd = Number(form.joubikaSkillAdd?.value) || 0;
  const max = 50 + skillAdd + expAdd;
  
  // アイテム欄の常備化小計の計算
  let itemsTotal = 0;
  const lifestylesNum = Number(form.lifestylesNum?.value) || 1;
  for(let i = 1; i <= lifestylesNum; i++) itemsTotal += Number(form[`lifestyle${i}Joubika`]?.value) || 0;
  
  const housesNum = Number(form.housesNum?.value) || 1;
  for(let i = 1; i <= housesNum; i++) itemsTotal += Number(form[`house${i}Joubika`]?.value) || 0;
  
  const itemsNum = Number(form.itemsNum?.value) || 1;
  for(let i = 1; i <= itemsNum; i++) itemsTotal += Number(form[`item${i}Joubika`]?.value) || 0;
  
  // 武具小計の取得（calcBattleで計算済みの値）
  const armamentsTotal = Number(form.battleTotalJoubi?.value) || 0;
  
  // 残りポイントの計算
  const rest = max - itemsTotal - armamentsTotal;
  
  // 画面への出力
  const elItemsTotal = document.getElementById('joubika-items-total');
  const elArmamentsTotal = document.getElementById('joubika-armaments-total');
  const elRest = document.getElementById('joubika-rest');
  const elMax = document.getElementById('joubika-max');
  
  if(elItemsTotal) elItemsTotal.textContent = itemsTotal;
  if(elArmamentsTotal) elArmamentsTotal.textContent = armamentsTotal;
  if(elRest) {
    elRest.textContent = rest;
    elRest.style.color = (rest < 0) ? 'red' : ''; // マイナスなら赤字で警告
  }
  if(elMax) elMax.textContent = max;

// ① 画面の表示（span）を更新する（ID指定：ハイフンあり）
  document.getElementById('joubika-max').textContent = max;
  document.getElementById('joubika-rest').textContent = rest;

  // ② 保存用の隠しフィールド（input）に値をセットする（name指定：キャメルケース）
  if (form.joubikaMax)  form.joubikaMax.value  = max;
  if (form.joubikaRest) form.joubikaRest.value = rest;

  // 経験点計算へ連動
  calcExp();
}

// 増減ボタンとソート機能の設定
function addLifestyle() { document.querySelector("#lifestyles-table tbody").append(createRow('lifestyle', 'lifestylesNum')); }
function delLifestyle() { if(delRow('lifestylesNum', '#lifestyles-table tbody tr:last-of-type')) calcJoubika(); }
setSortable('lifestyle', '#lifestyles-table tbody', 'tr');

function addHouse() { document.querySelector("#houses-table tbody").append(createRow('house', 'housesNum')); }
function delHouse() { if(delRow('housesNum', '#houses-table tbody tr:last-of-type')) calcJoubika(); }
setSortable('house', '#houses-table tbody', 'tr');

function addItem() { document.querySelector("#items-table tbody").append(createRow('item', 'itemsNum')); }
function delItem() { if(delRow('itemsNum', '#items-table tbody tr:last-of-type')) calcJoubika(); }
setSortable('item', '#items-table tbody', 'tr');

// ==========================================
// ミッション欄の制御
// ==========================================
function addMission() { 
  document.querySelector("#missions-table tbody").append(createRow('mission', 'missionsNum')); 
}
function delMission() { 
  delRow('missionsNum', '#missions-table tbody tr:last-of-type'); 
}
setSortable('mission', '#missions-table tbody', 'tr');


// ==========================================
// セッション履歴と経験点の計算（ncスタイル・MGR対応統合版）
// ==========================================
function calcExp() {
// 0（数値）ではなく、{}（空のオブジェクト）として初期化します

  const form = document.forms['sheet'];
  const historyNum = Number(form.historyNum?.value) || 0;
  
  // 初期成長点
  let total = Number(form.history0Exp?.value) || 0;
  let payment = 0;

  for (let i = 1; i <= historyNum; i++) {
    const objExp = form['history' + i + 'Exp'];
    const objPay = form['history' + i + 'Payment'];
    const objCheck = form['history' + i + 'Check']; // 適用チェック

    let exp = safeEval(objExp?.value) || 0;
    let pay = Number(objPay?.value) || 0;

    // チェックが入っている場合のみ合算
    if (objCheck && objCheck.checked) {
      total += exp;
      payment += pay;
    }
  }

  total -= payment;
  let rest = total;

  // 常備化ポイントの経験点変換を取得
  expUse['joubika'] = Number(form.joubikaExpUsed?.value) || 0;
  // ★ ここに存在していた expUse['stt'] = 0; という諸悪の根源を排除しました
  
  // 各種内訳（レベル、汎用スキル、コネ、常備化、能力値）を減算
  for (let key in expUse) {
    rest -= Number(expUse[key]) || 0;
  }

  // 表示更新（上部や履歴欄フッターの合計と残り）
  const elTotal = document.getElementById("exp-total");
  const elRest  = document.getElementById("exp-rest");
  const elHExp  = document.getElementById("history-exp-total");
  const elHPay  = document.getElementById("history-payment-total");
  
  if (elTotal) elTotal.textContent = total;
  if (elRest)  elRest.textContent = rest;
  if (elHExp)  elHExp.textContent = total;
  if (elHPay)  elHPay.textContent = payment;

 // ★フッターの各内訳への出力（JSはクラスの付け外しのみを担当）
  const outputIds = {
    "exp-used-level": expUse['level'] || 0,
    "exp-used-general-skills": expUse['generalSkills'] || 0,
    "exp-used-connections": expUse['connections'] || 0,
    "exp-used-joubika": expUse['joubika'] || 0,
    "exp-used-stt": expUse['stt'] || 0
  };
  // ▼ 経験点計算関数の最後（画面への出力が終わった後）に追記します ▼
  


  for (let id in outputIds) {
    const el = document.getElementById(id);
    if (el) {
      const val = Number(outputIds[id]);
      el.textContent = val;
      el.classList.toggle('error', val < 0);
    }
  }

  // 残り経験点がマイナスならエラークラスを付与
  if (elRest) {
    elRest.classList.toggle('error', rest < 0);
  }
    // 画面の <b> タグに表示された計算結果（テキスト）を、そのまま隠しフィールドにコピーする
  const outputIdsH = document.forms['sheet'];
  if(outputIdsH.expUsedLevel) {
    outputIdsH.expUsedLevel.value         = document.getElementById('exp-used-level').textContent || 0;
    outputIdsH.expUsedGeneralSkills.value = document.getElementById('exp-used-general-skills').textContent || 0;
    outputIdsH.expUsedConnections.value   = document.getElementById('exp-used-connections').textContent || 0;
    outputIdsH.expUsedJoubika.value       = document.getElementById('exp-used-joubika').textContent || 0;
    outputIdsH.expUsedStt.value           = document.getElementById('exp-used-stt').textContent || 0;
  }
}


// 履歴の増減ボタン
function addHistory() { 
  document.querySelector("#history-table tfoot").before(createRow('history', 'historyNum')); 
}
function delHistory() { 
  if (delRow('historyNum', '#history-table tbody:last-of-type')) calcExp(); 
}
setSortable('history', '#history-table', 'tbody');


// ==========================================
// 特技の計算（MGR専用）
// ==========================================
function calcSkills() {
  const form = document.forms['sheet'];
  const skillsNum = Number(form.skillsNum?.value) || 0;
  
  let generalCount = 0;
  
  for (let num = 1; num <= skillsNum; num++) {
    const objName = form[`skill${num}Name`];
    const objType = form[`skill${num}Type`];
    
    // 入力欄が存在するかチェック
    if (objName && objType) {
      const type = objType.value;
      
      // ゴミ箱（削除済み）に入っている特技は計算から除外する判定
      const tr = objName.closest('tr');
      const isTrash = tr && tr.closest('#skills-trash');
      
      // ゴミ箱に入っておらず、種別が「汎用」ならカウント（名称未入力でもカウント）
      if (!isTrash && type === '汎用') { 
        generalCount++; 
      }
    }


  }
  
  // (汎用特技の数 - 1) × 5 （マイナスもそのまま出力）
  expUse['generalSkills'] = (generalCount - 1) * 5;
  
  // フッターの経験点計算を連動させる
  calcExp();

  updateSkillHistoryTable();
}

// ② ファイルの末尾など、どこでもいいので累積経験点関数を追加
// 能力値を0から指定値まで成長させた場合の累計経験点を算出する関数
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
    // 一箇所でも自動入力されたら、全体の再計算を強制実行
    if (triggered) {
      calcStt();
      calcBattle();
    }
  }
});

// ==========================================
// MGR用 特技取得履歴表の動的生成
// ==========================================
function updateSkillHistoryTable() {
  const container = document.getElementById('skill-history-table-container');
  if (!container) return;

  const form = document.forms['sheet'];
  const charaLv = Number(form.level?.value) || 1;
  const classesNum = Number(form.classesNum?.value) || 1;
  const skillsNum = Number(form.skillsNum?.value) || 1;

  // 1. 各クラスの合計レベルを計算
  const classLvMap = { 'ガーディアン': charaLv }; // ガーディアンはキャラレベル参照
  for (let i = 1; i <= classesNum; i++) {
    const cName = form[`class${i}Name`]?.value;
    const cLv = Number(form[`class${i}Lv`]?.value) || 0;
    if (cName) {
      classLvMap[cName] = (classLvMap[cName] || 0) + cLv;
    }
  }

  // 2. 列の定義
  const cols = Object.keys(classLvMap).map(name => ({ name, lv: classLvMap[name] }));
  // ガーディアンを先頭にする
  // ガーディアンを先頭に固定し、他をレベル降順でソート
  cols.sort((a, b) => {
    if (a.name === 'ガーディアン') return -1;
    if (b.name === 'ガーディアン') return 1;
    return b.lv - a.lv; // レベルの高い順
  });

  // 3. データの収集
  let maxGetLv = 1;
  const hist = {};

  for (let num = 1; num <= skillsNum; num++) {
    const objName = form[`skill${num}Name`];
    const objType = form[`skill${num}Type`];
    const objLv = form[`skill${num}Lv`];
    const objGetLv = form[`skill${num}GetLv`];
    const objCategory = form[`skill${num}Category`]; // 種別

    if (objName && objType && objGetLv && objName.value) {
      if (objName.closest('tr')?.closest('#skills-trash')) continue;

      const getLv = Number(objGetLv.value);
      if (!getLv || getLv < 1) continue;
      if (getLv > maxGetLv) maxGetLv = getLv;

      const type = objType.value;
      let name = objName.value;
      const lv = Number(objLv?.value) || 1;
      const category = objCategory?.value || '';

      // [自][選] プレフィックスの追加
      let prefix = '';
      if (category.includes('自')) prefix = '[自]';
      else if (category.includes('選')) prefix = '[選]';

      if (!hist[getLv]) hist[getLv] = {};
      if (!hist[getLv][type]) hist[getLv][type] = [];

      hist[getLv][type].push({ name: prefix + name, lv, isOver: lv > getLv });
    }
  }

// 4. HTMLテーブルの組み立て
  let html = '<table class="data-table line-tbody" id="skill-history-table">';
  html += '<thead><tr><th style="width: 4em;">取得Lv</th>';
  cols.forEach(col => {
    // ガーディアンの場合は(Lv)を表示しない
    const lvText = col.name === 'ガーディアン' ? '' : `(${col.lv})`;
    html += `<th>${col.name}${lvText}</th>`;
  });
  html += '</tr></thead><tbody>';

  for (let lv = 1; lv <= maxGetLv; lv++) {
    html += `<tr><th class="center">${lv}</th>`;
    cols.forEach(col => {
      // ★修正：ガーディアン列はレベル上限によるグレーアウトを除外する
      const isDisabled = (col.name !== 'ガーディアン') && (lv > col.lv);
      const bgStyle = isDisabled ? 'background-color: rgba(0,0,0,0.05); color: rgba(0,0,0,0.3);' : '';
      
      html += `<td class="left" style="vertical-align: top; ${bgStyle}">`;
      if (!isDisabled && hist[lv] && hist[lv][col.name]) {
        hist[lv][col.name].forEach((item, idx) => {
          const border = idx > 0 ? 'border-top: 1px solid rgba(0,0,0,0.1); margin-top: 2px; padding-top: 2px;' : '';
          const overStyle = item.isOver ? 'font-weight:bold; color:#ff4444;' : '';
          // ★修正：CSSで一括制御できるように class="skill-hist-item" を付与
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



