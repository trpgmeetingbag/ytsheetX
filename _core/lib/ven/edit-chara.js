"use strict";
const gameSystem = 'ven';

let exps = {};
let status = {};
let syndromes = [];
// ----------------------------------------
window.onload = function() {
  console.log('=====START=====');
  // syndromes = [form.syndrome1.value, form.syndrome2.value, form.syndrome3.value];
  
  setName();
  // checkCreateType();
  // checkStage();
  // checkWorks();
  // checkSyndrome();
  // encroachModeChanged();
  // calcStt();
  // calcEffect();
  // calcMagic();
  // calcItem();
  // calcMemory();
  // refreshByImpulse();
  // for(let i = 1; i <= 7; i++){ changeLoisColor(i); }
  


  // 初期計算を一括実行（散らばっていた初期化処理をここに集約）
  calcRegulation();
  syncCredit();
  calcInitialValues();
  calcDebt();
  calcWeapon();
  calcWear();
  calcItem();
  

  // ロード時に全プルダウンの入力欄同期チェックを走らせる
  document.querySelectorAll('select').forEach(sel => {
    if(sel.getAttribute('onchange')?.includes('syncSelectToInput')) {
      sel.dispatchEvent(new Event('change'));
    }
  });

  changeColor();
  deleteLoadingArea();
  console.log('=====LOADED=====');
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名かハンターネームのいずれかを入力してください。');
    form.characterName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}



// ========================================
// オリジン・アデプト変更時の事情リスト動的生成
// ========================================

function updateOriginDropdown(nameSelectElement, num) {
  const reasonSelect = document.querySelector(`select[name="origin${num}Reason"]`);
  if (!reasonSelect) return;

  const selectedName = nameSelectElement.value;
  reasonSelect.innerHTML = '<option value=""></option>';

  let origin_reasons = [];
  if (selectedName && originData[selectedName]) {
    origin_reasons = originData[selectedName];
  }

  origin_reasons.forEach(reason => {
    const option = document.createElement('option');
    option.value = reason;
    option.textContent = reason;
    reasonSelect.appendChild(option);
  });

  const freeOption = document.createElement('option');
  freeOption.value = 'free'; 
  freeOption.textContent = 'その他（自由記入）';
  reasonSelect.appendChild(freeOption);
}

function updateAdeptDropdown(nameSelectElement, num) {
  const reasonSelect = document.querySelector(`select[name="adept${num}Reason"]`);
  if (!reasonSelect) return;

  const selectedName = nameSelectElement.value;
  reasonSelect.innerHTML = '<option value=""></option>';

  let adept_reasons = [];
  if (selectedName && adeptData[selectedName]) {
    adept_reasons = adeptData[selectedName];
  }

  adept_reasons.forEach(reason => {
    const option = document.createElement('option');
    option.value = reason;
    option.textContent = reason;
    reasonSelect.appendChild(option);
  });

  const freeOption = document.createElement('option');
  freeOption.value = 'free'; 
  freeOption.textContent = 'その他（自由記入）';
  reasonSelect.appendChild(freeOption);
}

// ========================================
// 各種データの行増減・ソート処理
// ========================================

function addOrigin() { document.querySelector("#origin-table").append(createRow('origin','originNum')); }
function delOrigin() { delRow('originNum', '#origin-table tbody:last-of-type'); }

function addAdept() { document.querySelector("#adept-table").append(createRow('adept','adeptNum')); }
function delAdept() { delRow('adeptNum', '#adept-table tbody:last-of-type'); }

function addFairy() { document.querySelector("#fairy-table").append(createRow('fairy','fairyNum')); }
function delFairy() { delRow('fairyNum', '#fairy-table tbody:last-of-type'); }

function addConnection() { document.querySelector("#connection-table").append(createRow('connection','connectionNum')); }
function delConnection() { delRow('connectionNum', '#connection-table tbody:last-of-type'); }

function addHistory() { document.querySelector("#history-table tfoot").before(createRow('history','historyNum')); }
function delHistory() { 
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcDebt();
    calcCredit();
  }
}
// ソート機能の初期化（ランダムIDエラーを防ぐため手動設定）
(() => {
  const initSimpleSortable = (tableId, numName) => {
    const table = document.getElementById(tableId);
    if(table){
      Sortable.create(table, {
        group: numName,
        dataIdAttr: 'id',
        animation: 150,
        handle: '.handle',
        filter: 'thead,tfoot,template',
        onSort: function(evt){
          let num = 1;
          for(let row of table.children) {
            if(row.tagName !== 'TBODY') continue;
            replaceSortedNames(row, num, new RegExp(`^(${numName.replace('Num','')})(?:Trash)?[0-9]+(.+)$`));
            num++;
          }
          const numInput = document.querySelector(`input[name="${numName}"]`);
          if(numInput) numInput.value = num - 1;
        }
      });
    }
  };

  initSimpleSortable('origin-table', 'originNum');
  initSimpleSortable('adept-table', 'adeptNum');
  initSimpleSortable('fairy-table', 'fairyNum');
  initSimpleSortable('connection-table', 'connectionNum');
  initSimpleSortable('history-table', 'historyNum');
})();
// --- 作成レギュレーション連動ギミック ---
let prevAmateur = false;
let prevNoAdept = false;

function calcRegulation() {
  const amateurCb = document.querySelector('input[name="isAmateur"]');
  const noAdeptCb = document.querySelector('input[name="noAdept"]');
  const levelInput = document.querySelector('input[name="level"]');
  const penaltyView = document.getElementById('credit-penalty-view');

  if(!amateurCb || !noAdeptCb) return;

  let levelDiff = 0;
  if (amateurCb.checked !== prevAmateur) {
    levelDiff += amateurCb.checked ? -1 : 1;
    prevAmateur = amateurCb.checked;
  }
  if (noAdeptCb.checked !== prevNoAdept) {
    levelDiff += noAdeptCb.checked ? -1 : 1;
    prevNoAdept = noAdeptCb.checked;
  }
  
  if (levelDiff !== 0 && levelInput) {
    levelInput.value = (parseInt(levelInput.value, 10) || 0) + levelDiff;
  }

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

  if (typeof syncCredit === 'function') syncCredit();
}

// --- 初期クレジットとセッション履歴(0行目)の同期ギミック ---
function syncCredit() {
  const creditInput = document.querySelector('input[name="initialCredit"]');
  const h0IncomeHidden = document.querySelector('input[name="history0Income"]');
  const h0IncomeView = document.getElementById('history0-income');

  if (creditInput) {
    const amateurCb = document.querySelector('input[name="isAmateur"]');
    const noAdeptCb = document.querySelector('input[name="noAdept"]');
    let checkCount = 0;
    if (amateurCb && amateurCb.checked) checkCount++;
    if (noAdeptCb && noAdeptCb.checked) checkCount++;
    
    let penalty = 0;
    if (checkCount === 1) penalty = -100;
    else if (checkCount === 2) penalty = -150;

    const baseCredit = parseInt(creditInput.value, 10) || 0;
    const finalCredit = baseCredit + penalty;

    if (h0IncomeHidden) h0IncomeHidden.value = finalCredit;
    if (h0IncomeView) h0IncomeView.textContent = finalCredit;
  }
  
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
  
  if (creditInput && h0IncomeHidden) {
    if (!creditInput.value && h0IncomeHidden.value) {
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
  // ※計算関数群は window.onload に移行したためここからは削除しています
});

// --- 初期数値（プライド・カルマ）連動ギミック ---
function calcInitialValues() {
  const prideCalcView = document.getElementById('pride-base-calc');
  const karmaCalcView = document.getElementById('karma-base-calc');
  const pridePenaltyInput = document.querySelector('input[name="pridePenalty"]');
  const karmaPenaltyInput = document.querySelector('input[name="karmaPenalty"]');

  if (prideCalcView && pridePenaltyInput) {
    const pridePenalty = parseInt(pridePenaltyInput.value, 10) || 0;
    prideCalcView.textContent = 8 - pridePenalty;
  }
  
  if (karmaCalcView && karmaPenaltyInput) {
    const karmaPenalty = parseInt(karmaPenaltyInput.value, 10) || 0;
    karmaCalcView.textContent = 2 + karmaPenalty;
  }
}

// ========================================================================
// 1. 各種自動計算（クレジット・装備・借金）
// ========================================================================

function calcDebt() {
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

  const totalDebt = manualDebt + historyDebt;
  const totalDebtView = document.getElementById('debt-total-view');
  if (totalDebtView) totalDebtView.textContent = totalDebt;
  
  const expDebtView = document.getElementById('credit-debt');
  if (expDebtView) expDebtView.textContent = manualDebt;

  calcCredit();
}

function calcCredit() {
  const weapon = parseInt(document.getElementById('credit-used-weapon')?.textContent || 0, 10);
  const custom = parseInt(document.getElementById('credit-used-custom')?.textContent || 0, 10);
  const wear = parseInt(document.getElementById('credit-used-wear')?.textContent || 0, 10);
  const item = parseInt(document.getElementById('credit-used-item')?.textContent || 0, 10);
  
  const totalDebt = parseInt(document.getElementById('credit-debt')?.textContent || 0, 10);

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

  const levelInput = document.querySelector('input[name="level"]');
  const level = levelInput ? parseInt(levelInput.value, 10) || 0 : 0;
  const maintBase = level * 10;
  
  let maintWeapon = 0;
  let maintCustom = 0;
  let maintWear = 0;
  
  const weaponNumInput = document.querySelector('input[name="weaponNum"]');
  const weaponNum = weaponNumInput ? parseInt(weaponNumInput.value, 10) : 0;
  for (let i = 1; i <= weaponNum; i++) {
    const wMaintInput = document.querySelector(`input[name="weapon${i}Maint"]`);
    if (wMaintInput) maintWeapon += parseInt(wMaintInput.value, 10) || 0;
    
    const cNumInput = document.querySelector(`input[name="weapon${i}CustomNum"]`);
    const customNum = cNumInput ? parseInt(cNumInput.value, 10) : 0;
    for (let j = 1; j <= customNum; j++) {
      const cMaintInput = document.querySelector(`input[name="weapon${i}Custom${j}Maint"]`);
      if (cMaintInput) maintCustom += parseInt(cMaintInput.value, 10) || 0;
    }
  }

  const wearNumInput = document.querySelector('input[name="wearNum"]');
  const wearNum = wearNumInput ? parseInt(wearNumInput.value, 10) : 0;
  for (let i = 1; i <= wearNum; i++) {
    const wearMaintInput = document.querySelector(`input[name="wear${i}Maint"]`);
    if (wearMaintInput) maintWear += parseInt(wearMaintInput.value, 10) || 0;
  }
  
  const totalMaint = maintWeapon + maintCustom + maintWear + maintBase;
  
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

  const equipmentTotal = weapon + custom + wear + item;
  const rest = totalIncome - (equipmentTotal - totalDebt + totalExpense);
  
  const restView = document.getElementById('credit-rest');
  if (restView) {
    restView.textContent = rest;
    restView.style.color = rest < 0 ? 'red' : 'inherit';
  }
}

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

  calcCredit();
}

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

function weaponSortAfter(){
  const sortableEl = document.getElementById('weapon-table');
  if(!sortableEl) return;
  
  let num = 1;
  for(let row of sortableEl.children) {
    if(row.tagName !== 'TBODY') continue;
    // 武器本体と内部のCustomの番号を更新
    replaceSortedNames(row, num, /^(weapon)[0-9]+(.+)$/); 
    num++;
  }
  document.querySelector('input[name="weaponNum"]').value = num - 1;

  /* 
   * ここにあった const trashEl = ... から始まる
   * ゴミ箱（Trash）側の採番処理と非表示処理はすべて削除しました
   */
  
  // カスタマイズ自身の番号の整列
  reindexAllWeaponCustoms();
}

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

(() => {
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



