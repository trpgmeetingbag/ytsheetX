"use strict";
const gameSystem = 'ven';

window.onload = function() {
  console.log('=====START=====');
  setName();
  imagePosition();
  changeColor();
  console.log('=====LOADED=====');
  
  // ロード時に全プルダウンの入力欄同期チェックを走らせる
  document.querySelectorAll('select').forEach(sel => {
    if(sel.getAttribute('onchange')?.includes('syncSelectToInput')) {
      sel.dispatchEvent(new Event('change'));
    }
  });
};

function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名かコードネームのいずれかを入力してください。');
    form.characterName.focus();
    return false;
  }
  return true;
}

// ========================================
// リストとテキストボックスの同期制御
// ========================================

function updateDependentDropdown(parentSelect, childSelectName, dataSource) {
  const childSelect = document.querySelector(`select[name="${childSelectName}Select"]`);
  if (!childSelect) return;
  
  // ★重要：一度リストの中身を完全に空にする（これで「その他」の二重化を防ぎます）
  childSelect.innerHTML = '<option value=""></option>';
  
  const parentVal = parentSelect.value;
  
  // Perlから受け取ったデータ（dataSource）をもとに、選ばれたオリジンの事情を追加する
  if (parentVal && parentVal !== 'free' && dataSource[parentVal]) {
    dataSource[parentVal].forEach(item => {
      const option = document.createElement('option');
      option.value = item;
      option.textContent = item;
      childSelect.appendChild(option);
    });
  }
  
  // 最後に、ゆとシート標準の「free」を一つだけ付け足す
  const freeOption = document.createElement('option');
  freeOption.value = 'free';
  freeOption.textContent = 'その他（自由記入）';
  childSelect.appendChild(freeOption);

  // ゆとシート標準の再計算関数を呼び出し、隠しテキストボックスの表示を更新
  if (typeof selectInputCheck === 'function') {
    selectInputCheck(childSelect);
  }
}

// ドロップダウン変更時に呼ばれる中継ぎ関数
// function updateOriginDropdown(selectElement, num) {
//   if (typeof originData !== 'undefined') {
//     updateDependentDropdown(selectElement, `origin${num}Reason`, originData);
//   }
// }

// function updateAdeptDropdown(selectElement, num) {
//   if (typeof adeptData !== 'undefined') {
//     updateDependentDropdown(selectElement, `adept${num}Reason`, adeptData);
//   }
// }

// ========================================
// オリジン・アデプト変更時の事情リスト動的生成
// ========================================

function updateOriginDropdown(nameSelectElement, num) {
  // 変更対象となる「事情」のドロップダウンを取得する
  const reasonSelect = document.querySelector(`select[name="origin${num}Reason"]`);
  // ※もしゆとシート標準の機能に任せていて、語尾に「Select」が付いている場合は以下にしてください：
  // const reasonSelect = document.querySelector(`select[name="origin${num}ReasonSelect"]`);
  
  if (!reasonSelect) return;

  // 1. 保存されている（現在選択されている）「オリジン名」を見る
  const selectedName = nameSelectElement.value;

  // 書き換える前に、現在の事情リストの中身をリセットする
  reasonSelect.innerHTML = '<option value=""></option>';

  // 2. 一致する事情リストを取り出す（Perlの @origin_reasons の代わり）
  let origin_reasons = [];
  if (selectedName && originData[selectedName]) {
    origin_reasons = originData[selectedName]; // 該当する事情の配列をセット
  }

  // 取り出した事情リスト（origin_reasons）を <option> に変換して追加する
  origin_reasons.forEach(reason => {
    const option = document.createElement('option');
    option.value = reason;
    option.textContent = reason;
    reasonSelect.appendChild(option);
  });

  // （Perl側でも追加しているはずの）その他の選択肢を末尾に付与する
  const freeOption = document.createElement('option');
  freeOption.value = 'free'; // または 'その他'（現在採用している仕様に合わせてください）
  freeOption.textContent = 'その他（自由記入）';
  reasonSelect.appendChild(freeOption);
}


function updateAdeptDropdown(nameSelectElement, num) {
  const reasonSelect = document.querySelector(`select[name="adept${num}Reason"]`);
  // ※語尾にSelectが付いている場合は `select[name="adept${num}ReasonSelect"]` に変更してください
  if (!reasonSelect) return;

  // 1. 選択されている「アデプト名」を見る
  const selectedName = nameSelectElement.value;

  // リセット
  reasonSelect.innerHTML = '<option value=""></option>';

  // 2. 一致する事情リストを取り出す
  let adept_reasons = [];
  if (selectedName && adeptData[selectedName]) {
    adept_reasons = adeptData[selectedName];
  }

  // 追加
  adept_reasons.forEach(reason => {
    const option = document.createElement('option');
    option.value = reason;
    option.textContent = reason;
    reasonSelect.appendChild(option);
  });

  // 末尾にその他の選択肢を付与
  const freeOption = document.createElement('option');
  freeOption.value = 'free'; 
  freeOption.textContent = 'その他（自由記入）';
  reasonSelect.appendChild(freeOption);
}



// ========================================
// 各種データの行増減・ソート処理
// ========================================

function addOrigin() { document.querySelector("#origin-table tbody").append(createRow('origin','originNum')); }
function delOrigin() { delRow('originNum', '#origin-table tbody tr:last-of-type'); }
setSortable('origin', '#origin-table tbody', 'tr');

function addAdept() { document.querySelector("#adept-table tbody").append(createRow('adept','adeptNum')); }
function delAdept() { delRow('adeptNum', '#adept-table tbody tr:last-of-type'); }
setSortable('adept', '#adept-table tbody', 'tr');

function addFairy() { document.querySelector("#fairy-table tbody").append(createRow('fairy','fairyNum')); }
function delFairy() { delRow('fairyNum', '#fairy-table tbody tr:last-of-type'); }
setSortable('fairy', '#fairy-table tbody', 'tr');


function addConnection() { document.querySelector("#connection-table tbody").append(createRow('connection','connectionNum')); }
function delConnection() { delRow('connectionNum', '#connection-table tbody tr:last-of-type'); }
setSortable('connection', '#connection-table tbody', 'tr');



function addHistory() { document.querySelector("#history-table tfoot").before(createRow('history','historyNum')); }
function delHistory() { delRow('historyNum', '#history-table tbody:last-of-type'); }
setSortable('history', '#history-table', 'tbody');


// --- 作成レギュレーション連動ギミック ---
let prevAmateur = false;
let prevNoAdept = false;

function calcRegulation() {
  const amateurCb = document.querySelector('input[name="isAmateur"]');
  const noAdeptCb = document.querySelector('input[name="noAdept"]');
  const levelInput = document.querySelector('input[name="level"]');
  const penaltyView = document.getElementById('credit-penalty-view');

  if(!amateurCb || !noAdeptCb) return;

  // レベルの増減
  let levelDiff = 0;
  if (amateurCb.checked !== prevAmateur) {
    levelDiff += amateurCb.checked ? -1 : 1;
    prevAmateur = amateurCb.checked;
  }
  if (noAdeptCb.checked !== prevNoAdept) {
    levelDiff += noAdeptCb.checked ? -1 : 1;
    prevNoAdept = noAdeptCb.checked;
  }
  
  // レベル欄に反映
  if (levelDiff !== 0 && levelInput) {
    levelInput.value = (parseInt(levelInput.value, 10) || 0) + levelDiff;
  }

  // クレジットのペナルティ表示の更新
  let checkCount = 0;
  if (amateurCb.checked) checkCount++;
  if (noAdeptCb.checked) checkCount++;

  let currentCreditPenalty = 0;
  if (checkCount === 1) currentCreditPenalty = -100;
  else if (checkCount === 2) currentCreditPenalty = -150;

  if (currentCreditPenalty !== 0) {
    penaltyView.textContent = `（${currentCreditPenalty}）`;
  } else {
    penaltyView.textContent = "";
  }

  // ペナルティ状態が変わったので、裏側のデータ同期を呼び出す
  if (typeof syncCredit === 'function') syncCredit();
}

// --- 初期クレジットとセッション履歴(0行目)の同期ギミック ---
function syncCredit() {
  const creditInput = document.querySelector('input[name="initialCredit"]');
  const h0IncomeHidden = document.querySelector('input[name="history0Income"]');
  const h0IncomeView = document.getElementById('history0-income');

  if (creditInput) {
    // 現在のペナルティを計算
    const amateurCb = document.querySelector('input[name="isAmateur"]');
    const noAdeptCb = document.querySelector('input[name="noAdept"]');
    let checkCount = 0;
    if (amateurCb && amateurCb.checked) checkCount++;
    if (noAdeptCb && noAdeptCb.checked) checkCount++;
    
    let penalty = 0;
    if (checkCount === 1) penalty = -100;
    else if (checkCount === 2) penalty = -150;

    // ユーザーが入力した基本値(initialCredit)にペナルティを適用
    const baseCredit = parseInt(creditInput.value, 10) || 0;
    const finalCredit = baseCredit + penalty;

    // ★隠しフィールドと、画面最下部の表示「だけ」を更新する（入力欄の数値は維持）
    if (h0IncomeHidden) h0IncomeHidden.value = finalCredit;
    if (h0IncomeView) h0IncomeView.textContent = finalCredit;
  }
  
  // ゆとシート標準の再計算処理を安全に呼び出す
  if (typeof changeRegu === 'function') changeRegu();
  calcCredit();
}

// ページ読み込み時に初期状態を記憶・同期
window.addEventListener('DOMContentLoaded', () => {
  const amateurCb = document.querySelector('input[name="isAmateur"]');
  const noAdeptCb = document.querySelector('input[name="noAdept"]');
  if(amateurCb) prevAmateur = amateurCb.checked;
  if(noAdeptCb) prevNoAdept = noAdeptCb.checked;
  
  const creditInput = document.querySelector('input[name="initialCredit"]');
  const h0IncomeHidden = document.querySelector('input[name="history0Income"]');
  
  // セーブデータから読み込んだ際の救済処理
  if (creditInput && h0IncomeHidden) {
    if (!creditInput.value && h0IncomeHidden.value) {
      // 履歴側にしか値がない場合、ペナルティを「逆算」して初期クレジット入力欄を復元する
      let checkCount = 0;
      if(prevAmateur) checkCount++;
      if(prevNoAdept) checkCount++;
      let penalty = 0;
      if (checkCount === 1) penalty = -100;
      else if (checkCount === 2) penalty = -150;
      
      creditInput.value = (parseInt(h0IncomeHidden.value, 10) || 0) - penalty;
    } else if (creditInput.value && !h0IncomeHidden.value) {
      h0IncomeHidden.value = creditInput.value;
    }
  }
  
  calcRegulation(); 
  syncCredit();
});

// --- 初期数値（プライド・カルマ）連動ギミック ---
function calcInitialValues() {
  const prideCalcView = document.getElementById('pride-base-calc');
  const karmaCalcView = document.getElementById('karma-base-calc');
  const pridePenaltyInput = document.querySelector('input[name="pridePenalty"]');
  const karmaPenaltyInput = document.querySelector('input[name="karmaPenalty"]');

  // プライドの計算（8 - ペナルティ）
  if (prideCalcView && pridePenaltyInput) {
    const pridePenalty = parseInt(pridePenaltyInput.value, 10) || 0;
    prideCalcView.textContent = 8 - pridePenalty;
  }
  
  // カルマの計算（2 + ペナルティ）
  if (karmaCalcView && karmaPenaltyInput) {
    const karmaPenalty = parseInt(karmaPenaltyInput.value, 10) || 0;
    karmaCalcView.textContent = 2 + karmaPenalty;
  }
}

// ページ読み込み時に保存されたペナルティ値で初期計算を行う
window.addEventListener('DOMContentLoaded', () => {
  calcInitialValues();
});


// ========================================================================
// 1. 各種自動計算（クレジット・装備・借金）
// ========================================================================

// ▼ 借金専用の計算関数（四則演算対応版） ▼
function calcDebt() {
  // 1. 履歴からの「金策による増減」を合算
  let historyDebt = 0;
  const historyNumInput = document.querySelector('input[name="historyNum"]');
  const historyNum = historyNumInput ? parseInt(historyNumInput.value, 10) || 0 : 0;
  
  for (let i = 0; i <= historyNum; i++) { 
    const hDebtInput = document.querySelector(`input[name="history${i}Debt"]`);
    if (hDebtInput) {
      let val = safeEval(hDebtInput.value);
      if (isNaN(val)) {
        hDebtInput.classList.add('error');
      } else {
        historyDebt += val;
        hDebtInput.classList.remove('error');
      }
    }
  }
  
  const historyDebtView = document.getElementById('debt-history-view');
  if (historyDebtView) historyDebtView.textContent = historyDebt;

  // 2. 「自主的な借金」の取得
  const manualDebtInput = document.querySelector('input[name="debt"]');
  let manualDebt = 0;
  if (manualDebtInput) {
    let val = safeEval(manualDebtInput.value);
    if (isNaN(val)) {
      manualDebtInput.classList.add('error');
    } else {
      manualDebt = val;
      manualDebtInput.classList.remove('error');
    }
  }

  // 3. 「借金合計」の計算と各所への反映
  const totalDebt = manualDebt + historyDebt;
  const totalDebtView = document.getElementById('debt-total-view');
  if (totalDebtView) totalDebtView.textContent = totalDebt;
  
  // フッター（計算用）には「自主的な借金(manualDebt)」のみを渡す
  const expDebtView = document.getElementById('credit-debt');
  if (expDebtView) expDebtView.textContent = manualDebt;

  // 計算が終わったら総クレジット計算にバトンタッチ
  calcCredit();
}

// ▼ 総クレジット計算（四則演算対応版） ▼
// ▼ 総クレジット計算（四則演算対応版） ▼
function calcCredit() {
  const weapon = parseInt(document.getElementById('credit-used-weapon')?.textContent || 0, 10);
  const custom = parseInt(document.getElementById('credit-used-custom')?.textContent || 0, 10);
  const wear = parseInt(document.getElementById('credit-used-wear')?.textContent || 0, 10);
  const item = parseInt(document.getElementById('credit-used-item')?.textContent || 0, 10);
  
  const totalDebt = parseInt(document.getElementById('credit-debt')?.textContent || 0, 10);

  // 履歴からの収入(Income)・支出(Expense)の合計
  let totalIncome = 0;
  let totalExpense = 0;
  const historyNumInput = document.querySelector('input[name="historyNum"]');
  const historyNum = historyNumInput ? parseInt(historyNumInput.value, 10) || 0 : 0;
  
  for (let i = 0; i <= historyNum; i++) { 
    const incomeInput = document.querySelector(`input[name="history${i}Income"]`);
    const expenseInput = document.querySelector(`input[name="history${i}Expense"]`);
    
    if (incomeInput) {
      let val = safeEval(incomeInput.value);
      if (isNaN(val)) {
        incomeInput.classList.add('error');
      } else {
        totalIncome += val;
        incomeInput.classList.remove('error');
      }
    }
    if (expenseInput) {
      let val = safeEval(expenseInput.value);
      if (isNaN(val)) {
        expenseInput.classList.add('error');
      } else {
        totalExpense += val;
        expenseInput.classList.remove('error');
      }
    }
  }
  
  const incomeView = document.getElementById('credit-total');
  if (incomeView) incomeView.textContent = totalIncome;
  
  const expenseView = document.getElementById('credit-expense');
  if (expenseView) expenseView.textContent = totalExpense;

  // ▼維持費の内訳計算と表示（価格からの割り出しではなく、入力欄から直接取得する）▼
  const levelInput = document.querySelector('input[name="level"]');
  const level = levelInput ? parseInt(levelInput.value, 10) || 0 : 0;
  const maintBase = level * 10;
  
  let maintWeapon = 0;
  let maintCustom = 0;
  let maintWear = 0;
  
  // 武器本体とカスタマイズの維持費を取得
  const weaponNumInput = document.querySelector('input[name="weaponNum"]');
  const weaponNum = weaponNumInput ? parseInt(weaponNumInput.value, 10) : 0;
  for (let i = 1; i <= weaponNum; i++) {
    // 武器本体の維持費
    const wMaintInput = document.querySelector(`input[name="weapon${i}Maint"]`);
    if (wMaintInput) maintWeapon += parseInt(wMaintInput.value, 10) || 0;
    
    // カスタマイズの維持費
    const cNumInput = document.querySelector(`input[name="weapon${i}CustomNum"]`);
    const customNum = cNumInput ? parseInt(cNumInput.value, 10) : 0;
    for (let j = 1; j <= customNum; j++) {
      const cMaintInput = document.querySelector(`input[name="weapon${i}Custom${j}Maint"]`);
      if (cMaintInput) maintCustom += parseInt(cMaintInput.value, 10) || 0;
    }
  }

  // ウェアの維持費を取得
  const wearNumInput = document.querySelector('input[name="wearNum"]');
  const wearNum = wearNumInput ? parseInt(wearNumInput.value, 10) : 0;
  for (let i = 1; i <= wearNum; i++) {
    const wearMaintInput = document.querySelector(`input[name="wear${i}Maint"]`);
    if (wearMaintInput) maintWear += parseInt(wearMaintInput.value, 10) || 0;
  }
  
  const totalMaint = maintWeapon + maintCustom + maintWear + maintBase;
  
  // HTML側（内訳と合計）への出力
  const maintBaseView = document.getElementById('level-maint');
  if (maintBaseView) maintBaseView.textContent = maintBase;

  const maintWeaponView = document.getElementById('weapon-maint');
  if (maintWeaponView) maintWeaponView.textContent = maintWeapon;

  const maintCustomView = document.getElementById('custom-maint');
  if (maintCustomView) maintCustomView.textContent = maintCustom;

  const maintWearView = document.getElementById('wear-maint');
  if (maintWearView) maintWearView.textContent = maintWear;

  const maintView = document.getElementById('credit-maint');
  if (maintView) maintView.textContent = totalMaint;
  // ▲維持費の処理ここまで

  // 残りクレジットの計算
  const equipmentTotal = weapon + custom + wear + item;
  const rest = totalIncome - (equipmentTotal - totalDebt + totalExpense);
  
  const restView = document.getElementById('credit-rest');
  if (restView) {
    restView.textContent = rest;
    restView.style.color = rest < 0 ? 'red' : 'inherit';
  }
}


// ▼ 武器・カスタマイズの計算 ▼
function calcWeapon() {
  let namedWeaponCount = 0;
  let totalCustomPrice = 0;
  const weaponNumInput = document.querySelector('input[name="weaponNum"]');
  const weaponNum = weaponNumInput ? parseInt(weaponNumInput.value, 10) : 0;

  for (let i = 1; i <= weaponNum; i++) {
    const nameInput = document.querySelector(`input[name="weapon${i}Name"]`);
    if (nameInput && nameInput.value.trim() !== '') namedWeaponCount++;

    const cNumInput = document.querySelector(`input[name="weapon${i}CustomNum"]`);
    const customNum = cNumInput ? parseInt(cNumInput.value, 10) : 0;

    for (let j = 1; j <= customNum; j++) {
      const priceInput = document.querySelector(`input[name="weapon${i}Custom${j}Price"]`);
      const maintInput = document.querySelector(`input[name="weapon${i}Custom${j}Maint"]`);
      if (priceInput) {
        const price = parseInt(priceInput.value, 10) || 0;
        totalCustomPrice += price;
        if (maintInput) maintInput.value = Math.ceil(price / 10);
      }
    }
  }
  const weaponBasePrice = Math.max(0, namedWeaponCount) * 50;
  
  const expWeaponView = document.getElementById('credit-used-weapon');
  if (expWeaponView) expWeaponView.textContent = weaponBasePrice;
  
  const expCustomView = document.getElementById('credit-used-custom');
  if (expCustomView) expCustomView.textContent = totalCustomPrice;

  const grandTotal = weaponBasePrice + totalCustomPrice;
  const oldExpWeaponView = document.getElementById('exp-weapon');
  if (oldExpWeaponView) oldExpWeaponView.textContent = grandTotal;

  calcCredit(); // 変更されたらクレジット全体も再計算
}

// ▼ ウェアの計算 ▼
function calcWear() {
  let totalPrice = 0;
  const wearNumInput = document.querySelector('input[name="wearNum"]');
  const wearNum = wearNumInput ? parseInt(wearNumInput.value, 10) : 0;
  for (let i = 1; i <= wearNum; i++) {
    const priceInput = document.querySelector(`input[name="wear${i}Price"]`);
    const maintInput = document.querySelector(`input[name="wear${i}Maint"]`);
    if (priceInput) {
      const price = parseInt(priceInput.value, 10) || 0;
      totalPrice += price;
      if (maintInput) maintInput.value = Math.ceil(price / 10);
    }
  }
  const expWearView = document.getElementById('credit-used-wear');
  if (expWearView) expWearView.textContent = totalPrice;

  const oldExpWearView = document.getElementById('exp-wear');
  if (oldExpWearView) oldExpWearView.textContent = totalPrice;

  calcCredit();
}

// ▼ アイテムの計算 ▼
function calcItem() {
  let totalPrice = 0;
  const itemNumInput = document.querySelector('input[name="itemNum"]');
  const itemNum = itemNumInput ? parseInt(itemNumInput.value, 10) : 0;
  for (let i = 1; i <= itemNum; i++) {
    const priceInput = document.querySelector(`input[name="item${i}Price"]`);
    if (priceInput) totalPrice += parseInt(priceInput.value, 10) || 0;
  }
  const expItemView = document.getElementById('credit-used-item');
  if (expItemView) expItemView.textContent = totalPrice;

  const oldExpItemView = document.getElementById('exp-item');
  if (oldExpItemView) oldExpItemView.textContent = totalPrice;

  calcCredit();
}
// function calcWeapon() {
//   let namedWeaponCount = 0;
//   let totalCustomPrice = 0;
//   const weaponNumInput = document.querySelector('input[name="weaponNum"]');
//   const weaponNum = weaponNumInput ? parseInt(weaponNumInput.value, 10) : 0;

//   for (let i = 1; i <= weaponNum; i++) {
//     const nameInput = document.querySelector(`input[name="weapon${i}Name"]`);
//     if (nameInput && nameInput.value.trim() !== '') namedWeaponCount++;

//     const cNumInput = document.querySelector(`input[name="weapon${i}CustomNum"]`);
//     const customNum = cNumInput ? parseInt(cNumInput.value, 10) : 0;

//     for (let j = 1; j <= customNum; j++) {
//       const priceInput = document.querySelector(`input[name="weapon${i}Custom${j}Price"]`);
//       const maintInput = document.querySelector(`input[name="weapon${i}Custom${j}Maint"]`);
//       if (priceInput) {
//         const price = parseInt(priceInput.value, 10) || 0;
//         totalCustomPrice += price;
//         if (maintInput) maintInput.value = Math.ceil(price / 10);
//       }
//     }
//   }
//   const weaponBasePrice = Math.max(0, namedWeaponCount - 1) * 50;
//   const grandTotal = weaponBasePrice + totalCustomPrice;
//   const expWeaponView = document.getElementById('exp-weapon');
//   if (expWeaponView) expWeaponView.textContent = grandTotal;
// }

// function calcWear() {
//   let totalPrice = 0;
//   const wearNumInput = document.querySelector('input[name="wearNum"]');
//   const wearNum = wearNumInput ? parseInt(wearNumInput.value, 10) : 0;
//   for (let i = 1; i <= wearNum; i++) {
//     const priceInput = document.querySelector(`input[name="wear${i}Price"]`);
//     const maintInput = document.querySelector(`input[name="wear${i}Maint"]`);
//     if (priceInput) {
//       const price = parseInt(priceInput.value, 10) || 0;
//       totalPrice += price;
//       if (maintInput) maintInput.value = Math.ceil(price / 10);
//     }
//   }
//   const expWearView = document.getElementById('exp-wear');
//   if (expWearView) expWearView.textContent = totalPrice;
// }

// function calcItem() {
//   let totalPrice = 0;
//   const itemNumInput = document.querySelector('input[name="itemNum"]');
//   const itemNum = itemNumInput ? parseInt(itemNumInput.value, 10) : 0;
//   for (let i = 1; i <= itemNum; i++) {
//     const priceInput = document.querySelector(`input[name="item${i}Price"]`);
//     if (priceInput) totalPrice += parseInt(priceInput.value, 10) || 0;
//   }
//   const expItemView = document.getElementById('exp-item');
//   if (expItemView) expItemView.textContent = totalPrice;
// }

// ========================================================================
// 2. 武器本体 ＆ カスタマイズの専用処理（ID書き換え・増減）
// ========================================================================
function renameCustomization(tbody, newPrefix, num) {
  const elements = tbody.querySelectorAll('*');
  const idRegex = /weapon(?:\d+Custom|CustomTrash)(?:TMPL|\d+)/g; 
  const rowIdRegex = /weapon(?:\d+Custom|CustomTrash)-row(?:TMPL|\d+)/g;

  if (tbody.id.match(rowIdRegex)) tbody.id = `${newPrefix}-row${num}`;
  elements.forEach(el => {
    ['name', 'id', 'oninput', 'onchange', 'onclick'].forEach(attr => {
      if (el.hasAttribute(attr)) {
        let val = el.getAttribute(attr);
        val = val.replace(idRegex, `${newPrefix}${num}`);
        val = val.replace(rowIdRegex, `${newPrefix}-row${num}`);
        el.setAttribute(attr, val);
      }
    });
  });
}

function reindexAllWeaponCustoms() {
  const weaponNum = parseInt(document.querySelector('input[name="weaponNum"]').value, 10) || 0;
  for (let i = 1; i <= weaponNum; i++) {
    const table = document.getElementById(`weapon${i}-custom-table`);
    if (!table) continue;
    let cNum = 1;
    for (let row of table.children) {
      if (row.tagName !== 'TBODY') continue;
      renameCustomization(row, `weapon${i}Custom`, cNum);
      cNum++;
    }
    const customNumInput = document.querySelector(`input[name="weapon${i}CustomNum"]`);
    if (customNumInput) customNumInput.value = cNum - 1;
  }
  calcWeapon();
}

// 武器本体の増減
function addWeapon(){
  document.querySelector("#weapon-table").append(createRow('weapon','weaponNum'));
  setTimeout(() => {
    const num = document.querySelector('input[name="weaponNum"]').value;
    initWeaponCustomSortable(num);
  }, 10);
}
function delWeapon(){
  if(delRow('weaponNum', '#weapon-table > tbody:last-of-type')){ calcWeapon(); }
}

// 武器本体のソート後処理
function weaponSortAfter(){
  const sortableEl = document.getElementById('weapon-table');
  if(!sortableEl) return;
  let num = 1;
  for(let row of sortableEl.children) {
    if(row.tagName !== 'TBODY') continue;
    replaceSortedNames(row, num, /^(weapon)(?:Trash)?[0-9]+(.+)$/);
    renameCustomization(row, `weapon${num}Custom`, ""); // 中のカスタムも追従させる
    num++;
  }
  document.querySelector('input[name="weaponNum"]').value = num - 1;

  const trashEl = document.getElementById('weapon-trash-table');
  let del = 0;
  if(trashEl) {
    for(let row of trashEl.children) {
      if(row.tagName !== 'TBODY') continue;
      del++;
      replaceSortedNames(row, 'Trash'+del, /^(weapon)(?:Trash)?[0-9]+(.+)$/);
    }
  }
  if(!del){ document.getElementById('weapon-trash').style.display = 'none' }
  reindexAllWeaponCustoms();
}

// カスタマイズの追加（削除は共通ゴミ箱へ）
function addWeaponCustom(btn) {
  const container = btn.closest('tbody[id^="weapon-row"]');
  if (!container) return;
  const wNum = container.id.match(/weapon-row(\d+)/)[1];
  const template = document.getElementById(`weapon${wNum}-custom-template`);
  if (!template) return;
  
  const clone = template.content.cloneNode(true);
  const elements = clone.querySelectorAll('*');
  elements.forEach(el => {
    ['name', 'id', 'oninput', 'onchange', 'onclick'].forEach(attr => {
      if (el.hasAttribute(attr)) el.setAttribute(attr, el.getAttribute(attr).replace(/TMPL/g, '999')); 
    });
  });

  document.getElementById(`weapon${wNum}-custom-table`).appendChild(clone);
  reindexAllWeaponCustoms();
}

// ========================================================================
// 3. 共通ゴミ箱 ＆ パワー・ウェア・アイテムの制御
// ========================================================================
function moveToSharedTrash(numInputName, tableSelector) {
  const table = document.querySelector(tableSelector);
  if (!table) return false;
  
  const tbodys = Array.from(table.children).filter(el => el.tagName === 'TBODY');
  if (tbodys.length === 0) return false;
  const targetTbody = tbodys[tbodys.length - 1];
  
  const trashTable = document.getElementById('shared-trash-table');
  if (trashTable) {
    trashTable.appendChild(targetTbody);
    const numInput = document.querySelector(`input[name="${numInputName}"]`);
    if(numInput) numInput.value = Math.max(0, parseInt(numInput.value, 10) - 1);
    reindexSharedTrash();
    return true;
  }
  return false;
}

function addPower(){ document.querySelector("#power-table").append(createRow('power','powerNum')); }
function delPower(){ if(moveToSharedTrash('powerNum', '#power-table')) powerSortAfter(); }

function addWear(){ document.querySelector("#wear-table").append(createRow('wear','wearNum')); }
function delWear(){ if(moveToSharedTrash('wearNum', '#wear-table')) wearSortAfter(); }

function addItem(){ document.querySelector("#item-table").append(createRow('item','itemNum')); }
function delItem(){ if(moveToSharedTrash('itemNum', '#item-table')) itemSortAfter(); }

function delWeaponCustom(btn) {
  const container = btn.closest('tbody[id^="weapon-row"]');
  if (!container) return;
  const wNum = container.id.match(/weapon-row(\d+)/)[1];
  const listTable = document.getElementById(`weapon${wNum}-custom-table`);
  
  const tbodys = Array.from(listTable.children).filter(el => el.tagName === 'TBODY');
  if (tbodys.length > 0) {
    const lastRow = tbodys[tbodys.length - 1];
    const trashTable = document.getElementById('shared-trash-table');
    if(trashTable) trashTable.appendChild(lastRow); 
    
    const numInput = document.querySelector(`input[name="weapon${wNum}CustomNum"]`);
    if(numInput) numInput.value = Math.max(0, parseInt(numInput.value, 10) - 1);
    
    reindexAllWeaponCustoms();
    reindexSharedTrash();
  }
}

function reindexSharedTrash() {
  let counts = { power: 1, wear: 1, item: 1, weaponCustom: 1 };
  const trashTable = document.getElementById('shared-trash-table');
  if (!trashTable) return;

  for (let row of trashTable.children) {
    if (row.tagName !== 'TBODY') continue;
    const origin = row.dataset.origin;
    
    if (origin === 'power') {
      replaceSortedNames(row, 'powerTrash' + counts.power, /^(power)(?:Trash)?[0-9]+(.+)$/);
      counts.power++;
    } else if (origin === 'wear') {
      replaceSortedNames(row, 'wearTrash' + counts.wear, /^(wear)(?:Trash)?[0-9]+(.+)$/);
      counts.wear++;
    } else if (origin === 'item') {
      replaceSortedNames(row, 'itemTrash' + counts.item, /^(item)(?:Trash)?[0-9]+(.+)$/);
      counts.item++;
    } else if (origin === 'weaponCustom') {
      renameCustomization(row, 'weaponCustomTrash', counts.weaponCustom);
      counts.weaponCustom++;
    }
  }

  const total = counts.power + counts.wear + counts.item + counts.weaponCustom - 4;
  const trashBox = document.getElementById('shared-trash');
  if(trashBox) trashBox.style.display = total > 0 ? 'block' : 'none';
  
  calcWear(); calcItem(); calcWeapon();
}

function powerSortAfter(){
  const sortableEl = document.getElementById('power-table');
  if(!sortableEl) return;
  let num = 1;
  for(let row of sortableEl.children) {
    if(row.tagName !== 'TBODY') continue;
    replaceSortedNames(row, num, /^(power)(?:Trash)?[0-9]+(.+)$/);
    num++;
  }
  document.querySelector('input[name="powerNum"]').value = num - 1;
}

function wearSortAfter(){
  const sortableEl = document.getElementById('wear-table');
  if(!sortableEl) return;
  let num = 1;
  for(let row of sortableEl.children) {
    if(row.tagName !== 'TBODY') continue;
    replaceSortedNames(row, num, /^(wear)(?:Trash)?[0-9]+(.+)$/);
    num++;
  }
  document.querySelector('input[name="wearNum"]').value = num - 1;
  calcWear();
}

function itemSortAfter(){
  const sortableEl = document.getElementById('item-table');
  if(!sortableEl) return;
  let num = 1;
  for(let row of sortableEl.children) {
    if(row.tagName !== 'TBODY') continue;
    replaceSortedNames(row, num, /^(item)(?:Trash)?[0-9]+(.+)$/);
    num++;
  }
  document.querySelector('input[name="itemNum"]').value = num - 1;
  calcItem();
}

// ========================================================================
// 4. ドラッグ＆ドロップ（Sortable）の初期化群
// ========================================================================
function createRestrictedSortable(tableId, originName, groupName, sortAfterFunc) {
  const table = document.getElementById(tableId);
  if (!table) return;
  if (table.sortableInstance) table.sortableInstance.destroy();

  table.sortableInstance = Sortable.create(table, {
    group: {
      name: groupName,
      put: function (to, from, dragEl) { return dragEl.dataset.origin === originName; }
    },
    draggable: 'tbody',
    animation: 150,
    handle: '.handle:not(.custom-handle)',
    filter: 'template, thead, tfoot',
    onSort: function(evt) { sortAfterFunc(); reindexSharedTrash(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      const tb = document.getElementById('shared-trash');
      if(tb) tb.style.display = 'block';
    }
  });
}

function initWeaponCustomSortable(wNum) {
  const tableEl = document.getElementById(`weapon${wNum}-custom-table`);
  if (!tableEl) return;
  if (tableEl.sortableInstance) tableEl.sortableInstance.destroy();

  tableEl.sortableInstance = Sortable.create(tableEl, {
    group: {
      name: 'weaponCustom',
      put: function (to, from, dragEl) { return dragEl.dataset.origin === 'weaponCustom'; }
    },
    draggable: 'tbody',
    animation: 150,
    handle: '.custom-handle',
    filter: 'template, thead, tfoot',
    onSort: function(evt){ reindexAllWeaponCustoms(); reindexSharedTrash(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      const tb = document.getElementById('shared-trash');
      if(tb) tb.style.display = 'block';
    }
  });
}
// ========================================================================
// 4. ドラッグ＆ドロップ（Sortable）の初期化群（即時実行に修正）
// ========================================================================

(() => {
  // ① 各種計算を即時実行
  if(typeof calcDebt === 'function') calcDebt();
  if(typeof calcWeapon === 'function') calcWeapon();
  if(typeof calcWear === 'function') calcWear();
  if(typeof calcItem === 'function') calcItem();
  
  // ② 武器本体のSortable（専用ゴミ箱連動）
  const weaponTable = document.getElementById('weapon-table');
  if (weaponTable) {
    Sortable.create(weaponTable, {
      group: "weapon",
      dataIdAttr: 'id',
      animation: 150,
      handle: '.handle:not(.custom-handle)',
      filter: 'thead,tfoot,template',
      onSort: function(evt){ weaponSortAfter(); },
      onStart: function(evt){
        document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
        const tb = document.getElementById('weapon-trash');
        if(tb) tb.style.display = 'block';
      }
    });
  }
  const weaponTrashTable = document.getElementById('weapon-trash-table');
  if (weaponTrashTable) {
    Sortable.create(weaponTrashTable, {
      group: "weapon",
      dataIdAttr: 'id',
      animation: 150,
      filter: 'thead,tfoot,template',
      onSort: function(evt){ weaponSortAfter(); }
    });
  }

  // ③ 共通ゴミ箱のSortable
  const trashTable = document.getElementById('shared-trash-table');
  if (trashTable) {
    Sortable.create(trashTable, {
      group: {
        name: 'sharedTrash',
        put: ['power', 'wear', 'item', 'weaponCustom'],
        pull: true
      },
      draggable: 'tbody',
      animation: 150,
      filter: 'template, thead, tfoot',
      onSort: function(evt) { reindexSharedTrash(); }
    });
  }

  // ④ 各種制限付きSortableの初期化
  if(typeof createRestrictedSortable === 'function'){
    createRestrictedSortable('power-table', 'power', 'power', powerSortAfter);
    createRestrictedSortable('wear-table', 'wear', 'wear', wearSortAfter);
    createRestrictedSortable('item-table', 'item', 'item', itemSortAfter);
  }

  // ⑤ 武器カスタマイズ用Sortableの初期化
  const weaponNumInput = document.querySelector('input[name="weaponNum"]');
  const weaponNum = weaponNumInput ? parseInt(weaponNumInput.value, 10) : 0;
  for (let i = 1; i <= weaponNum; i++) {
    if(typeof initWeaponCustomSortable === 'function') {
      initWeaponCustomSortable(i);
    }
  }
})();




// ========================================
// 自動計算系
// ========================================
function calcMaint(priceInput, targetMaintName) {
  const maintInput = form[targetMaintName];
  if (!maintInput) return;
  
  const price = parseInt(priceInput.value, 10);
  if (isNaN(price)) {
    maintInput.value = '';
  } else {
    maintInput.value = Math.floor(price / 10);
  }
}