"use strict";
const gameSystem = 'mgr';

window.onload = function() {
  console.log('=====START=====');
  setName();

  // 初期化時にシステムのセットアップを実行
  changeSystem(true); // true を渡して初期化時であることを判別（保存済みの分類を復元するため）

  // rewriteMountLevel();
  // updatePartsAutomatically();
  // updatePartList();

  // selectInputCheck(form.taxa,'その他') は changeSystem 内で実行されるため削除しても残しても構いません
  // if(typeof form !== 'undefined' && form.taxa) {
  //   selectInputCheck(form.taxa,'その他');
  // }
  
  // checkMount();

  changeColor();
  deleteLoadingArea();

  // 基本データ類のソート機能（setSortableは ytsheet の既存関数を利用）
  if (typeof setSortable === 'function') {
    setSortable('base', '#base-list');
    setSortable('stt', '#stt-list');
    setSortable('battle', '#battle-list');
    setSortable('defense', '#defense-list');
  }

  // 攻撃方法の行ソート
  if (document.querySelector('#attack-tbody')) {
    Sortable.create(document.querySelector('#attack-tbody'), {
      dataIdAttr: 'id',
      animation: 150,
      handle: '.handle',
      onUpdate: function (evt) {
        const order = this.toArray();
        let num = 1;
        for (let id of order) {
          const row = document.querySelector(`tr#${id}`);
          if (!row) continue;
          
          // idを振り直す
          row.id = `attack-row${num}`;
          
          // name属性の中の行番号（attackRow〇〇）だけを振り直す
          row.querySelectorAll('input').forEach(inputField => {
            const beforeName = inputField.getAttribute('name');
            if (beforeName) {
              const afterName = beforeName.replace(/^attackRow\d+(Col\d+Value)$/, `attackRow${num}$1`);
              inputField.setAttribute('name', afterName);
            }
          });
          num++;
        }
      }
    });
  }

  console.log('=====LOADED=====');
}

// 保存されている分類（Perl側から出力されるか、隠しフィールドで持たせる想定）
// ※ここでは解説のため、仮の変数を置いています。
const savedTaxa = "ミーレス"; // 実際はPerl側から値を受け取る仕組みが必要です

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.monsterName.value === '' && form.characterName.value === ''){
    alert('名称か名前のいずれかを入力してください。');
    form.monsterName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}

/**
 * システムが変更されたときの処理
 * @param {boolean} isInit - 画面読み込み時かどうか
 */
function changeSystem(isInit = false) {
  // form変数に依存せず、確実にDOMから要素を取得する
  const systemSelect = document.querySelector('select[name="system"]');
  const systemFreeInput = document.querySelector('input[name="systemFree"]');
  // const taxaSelect = document.querySelector('select[name="taxa"]');
  



  

  const selectedSystem = systemSelect.value;
  
  // ① システム「その他」の判定とテキストボックス表示制御
  if (systemFreeInput) {
    if (selectedSystem === 'その他') {
      systemFreeInput.style.display = 'inline-block';
    } else {
      systemFreeInput.style.display = 'none';
    }
  }

    //④ 基本データ・戦闘値の見出し自動更新
  const systemData = (typeof srsSystemsMons !== 'undefined' && srsSystemsMons[selectedSystem]) 
                   ? srsSystemsMons[selectedSystem] 
                   : (typeof srsSystemsMons !== 'undefined' ? srsSystemsMons['その他'] : null);

  // ==========================================
  // 分類（taxa）リストの動的生成
  // ==========================================
  const taxaSelect = document.getElementById('taxa');
  if (taxaSelect) {
    const savedTaxa = taxaSelect.getAttribute('data-saved-value') || '';
    taxaSelect.innerHTML = ''; // 一旦リストをリセット

    // システムが「その他」、または辞書に分類データが存在しない場合
    if (selectedSystem === 'その他' || !systemData || !systemData.taxa) {
      const option = document.createElement('option');
      option.value = 'その他';
      option.textContent = 'その他';
      taxaSelect.appendChild(option);
      taxaSelect.value = 'その他';
    } 
    // 通常のシステムの場合
    // 通常のシステムの場合
    else {
      // 辞書から分類を追加
      systemData.taxa.forEach(taxaItem => {
        // ★データが配列 ['名前', 'ソート番号'] の場合は最初の要素を、単なる文字列ならそのまま取得
        const taxaName = Array.isArray(taxaItem) ? taxaItem[0] : taxaItem;
        
        // 辞書側に「その他」が定義されていた場合の二重登録を防止
        if (taxaName === 'その他') return;

        const option = document.createElement('option');
        option.value = taxaName;
        option.textContent = taxaName;
        taxaSelect.appendChild(option);
      });
      
      // 最後に必ず「その他」を追加
      const otherOption = document.createElement('option');
      otherOption.value = 'その他';
      otherOption.textContent = 'その他';
      taxaSelect.appendChild(otherOption);

      // 保存されていた値があれば復元する
      if (savedTaxa) {
        taxaSelect.value = savedTaxa;
      }
    }

    // 最後に selectInputCheck を強制実行し、自由記入欄(taxaFree)の表示/非表示を正しく連動させる
    if (typeof selectInputCheck === 'function') {
      selectInputCheck(taxaSelect, 'その他');
    }
  }

  
  // データ辞書（srsSystemsMons）から選ばれたシステムのデータを取得
  // if (typeof srsSystemsMons !== 'undefined' && srsSystemsMons[selectedSystem] && srsSystemsMons[selectedSystem].taxa) {
  //   let isSavedTaxaExist = false;
    
  //   srsSystemsMons[selectedSystem].taxa.forEach(taxaRow => {
  //     const optionName = taxaRow[0]; // 例: 'ガーディアン'
  //     const option = document.createElement('option');
  //     option.value = optionName;
  //     option.textContent = optionName;
      
  //     // 初期化時のみ、保存されていた分類と一致すれば選択状態にする
  //     if (isInit && optionName === savedTaxa) {
  //       option.selected = true;
  //       isSavedTaxaExist = true;
  //     }
      
  //     taxaSelect.appendChild(option);
  //   });
    
  //   // データ辞書に無い分類が保存されていた場合（手入力された値など）のフォロー
  //   if (isInit && savedTaxa && !isSavedTaxaExist) {
  //      const option = document.createElement('option');
  //      option.value = savedTaxa;
  //      option.textContent = savedTaxa;
  //      option.selected = true;
  //      taxaSelect.appendChild(option);
  //   }
  // }
  
  // ③ 分類の「その他」連動チェックを再実行
  if(typeof selectInputCheck === 'function') {
    selectInputCheck(taxaSelect, 'その他');
  }


  
  if (systemData) {
    const updateHeaders = (prefix, nameArray, placeholder) => {
      let numInput = document.querySelector(`input[name="${prefix}Num"]`);
      if (!numInput) return;
      
      let currentNum = Number(numInput.value) || 0;

      // 【追加】システムが求める項目数より現在の枠数が少ない場合、自動的に追加する
      while (currentNum < nameArray.length) {
        addStatusItem(prefix, placeholder);
        currentNum++;
      }

      // 見出しの流し込み
      for (let i = 1; i <= currentNum; i++) {
        const nameInput = document.querySelector(`input[name="${prefix}${i}Name"]`);
        if (!nameInput) continue;

        const headerText = nameArray[i - 1];
        
        if (headerText !== undefined) {
          nameInput.value = headerText;
        } else {
          // システム配列より枠が余っている（ユーザーが独自に追加した枠など）場合
          if (!isInit) {
            nameInput.value = '';
          }
        }
      }
    };

    updateHeaders('base', systemData.base_names || [], '基礎');
    updateHeaders('stt', systemData.stt_names || [], '能力');
    updateHeaders('battle', systemData.battle_names || [], '戦闘値');
    updateHeaders('defense', systemData.defense_names || [], '防御');
  }
  if (systemData && systemData.attack_names) {
    const attackNames = systemData.attack_names;
    let colNumInput = document.querySelector('input[name="attackColNum"]');
    if (colNumInput) {
      let currentColNum = Number(colNumInput.value) || 0;

      // システムが要求する列数に達するまで「列を追加」を実行
      while (currentColNum < attackNames.length) {
        addAttackCol('見出し');
        currentColNum++;
      }

      // 見出しの名前を流し込む
      for (let c = 1; c <= currentColNum; c++) {
        const nameInput = document.querySelector(`input[name="attackCol${c}Name"]`);
        if (!nameInput) continue;

        const headerText = attackNames[c - 1];
        if (headerText !== undefined) {
          nameInput.value = headerText;
        } else if (!isInit) {
          // 余った列の見出しをクリア（初期化時はユーザー設定維持のためスキップ）
          nameInput.value = '';
        }
      }
    }
  }
  const extraBox = document.getElementById('extra-textarea-box');
  if (extraBox && systemData) {
    const extraList = systemData.extra_textarea || ['加護'];
    
    // 一旦コンテナを表示
    extraBox.style.display = 'block';

    if (selectedSystem === 'その他') {
      // 「その他」の場合は、自由記入用に1枠だけ表示する
      for (let i = 1; i <= 3; i++) {
        const itemDiv = document.getElementById(`extra-textarea-${i}`);
        if (itemDiv) {
          if (i === 1) {
            itemDiv.style.display = 'block';
            // 初期化時以外はプレースホルダー的に空にする
            if (!isInit) {
              const nameInput = document.querySelector(`input[name="extra${i}Name"]`);
              if (nameInput) nameInput.value = '';
            }
          } else {
            itemDiv.style.display = 'none';
          }
        }
      }
    } 
    else if (extraList.length > 0) {
      // システムに設定された追加枠の数だけ表示し、見出しを流し込む
      for (let i = 1; i <= 3; i++) {
        const itemDiv = document.getElementById(`extra-textarea-${i}`);
        const nameInput = document.querySelector(`input[name="extra${i}Name"]`);
        
        if (itemDiv && nameInput) {
          if (i <= extraList.length) {
            itemDiv.style.display = 'block';
            if (extraList[i - 1].name !== undefined) {
              nameInput.value = extraList[i - 1].name;
            }
          } else {
            itemDiv.style.display = 'none';
          }
        }
      }
    } 
    else {
      // 追加枠がないシステムの場合はコンテナごと非表示
      extraBox.style.display = 'none';
    }
  }
}

// ====== 基本データ・戦闘値の追加・削除処理 ======
function addBase() { addStatusItem('base', '基礎'); }
function delBase() { delStatusItem('base'); }
function addStt() { addStatusItem('stt', '能力'); }
function delStt() { delStatusItem('stt'); }
function addBattle() { addStatusItem('battle', '戦闘値'); }
function delBattle() { delStatusItem('battle'); }
function addDefense() { addStatusItem('defense', '防御'); }
function delDefense() { delStatusItem('defense'); }

function addStatusItem(type, placeholderText) {
  let numInput = document.querySelector(`input[name="${type}Num"]`);
  if (!numInput) return;
  
  let num = Number(numInput.value) + 1;
  let li = document.createElement('li');
  li.id = `${type}-item${num}`;
  li.className = 'srs-status-input-row';
  
  // HTMLテンプレートの構築
  li.innerHTML = `<span class="handle"></span>` +
                 `<input type="text" name="${type}${num}Name" class="header-input" placeholder="${placeholderText}">` +
                 ` ： ` +
                 `<input type="text" name="${type}${num}Value" class="value-input" placeholder="値">`;
                 
  document.getElementById(`${type}-list`).appendChild(li);
  numInput.value = num;
}

function delStatusItem(type) {
  let numInput = document.querySelector(`input[name="${type}Num"]`);
  if (!numInput) return;
  
  let num = Number(numInput.value);
  if(num > 1) {
    let list = document.getElementById(`${type}-list`);
    let lastItem = list.lastElementChild;
    
    // 値が入力されている場合は確認ダイアログを出す
    let inputs = lastItem.querySelectorAll('input');
    let hasValue = Array.from(inputs).some(input => input.value !== '');
    if(hasValue && typeof delConfirmText !== 'undefined') {
      if (!confirm(delConfirmText)) return false;
    }
    
    lastItem.remove();
    num--;
    numInput.value = num;
  }
}

// ==========================================
// 攻撃方法：行（Row）と列（Col）の増減処理
// ==========================================

function addAttackRow() {
  let rowNumInput = document.querySelector('input[name="attackRowNum"]');
  let colNumInput = document.querySelector('input[name="attackColNum"]');
  if (!rowNumInput || !colNumInput) return;
  
  let rowNum = Number(rowNumInput.value) + 1;
  let colNum = Number(colNumInput.value);

  let tr = document.createElement('tr');
  tr.id = `attack-row${rowNum}`;
  
  // ドラッグハンドル
  let html = '<td class="handle"></td>';
  
  // 現在の列数分だけセル（td > input）を生成
  for (let c = 1; c <= colNum; c++) {
    html += `<td class="attack-cell-col${c}"><input type="text" name="attackRow${rowNum}Col${c}Value"></td>`;
  }
  
  tr.innerHTML = html;
  document.getElementById('attack-tbody').appendChild(tr);
  rowNumInput.value = rowNum;
}

function delAttackRow() {
  let rowNumInput = document.querySelector('input[name="attackRowNum"]');
  if (!rowNumInput) return;
  
  let rowNum = Number(rowNumInput.value);
  if (rowNum > 1) {
    // 削除確認（一番下の行に値が入力されているかチェック）
    let lastRow = document.getElementById(`attack-row${rowNum}`);
    let inputs = lastRow.querySelectorAll('input');
    let hasValue = Array.from(inputs).some(input => input.value !== '');
    if (hasValue && typeof delConfirmText !== 'undefined') {
      if (!confirm(delConfirmText)) return false;
    }
    
    lastRow.remove();
    rowNumInput.value = rowNum - 1;
  }
}

// ==========================================
// 攻撃方法：列（Col）の追加・削除処理
// ==========================================

function addAttackCol(placeholder = "見出し") {
  let rowNumInput = document.querySelector('input[name="attackRowNum"]');
  let colNumInput = document.querySelector('input[name="attackColNum"]');
  if (!rowNumInput || !colNumInput) return;
  
  let colNum = Number(colNumInput.value);
  
  // 制限：最大8列まで
  if (colNum >= 8) {
    // ユーザーに制限を伝える場合はアラートを出すことも可能です
    alert('列の追加は現時点では最大8列までです。増やしたい場合はご連絡ください。');
    return;
  }

  let rowNum = Number(rowNumInput.value);
  colNum++; // 追加後の列番号

  // 1. theadに見出しセル（th）を追加
  let th = document.createElement('th');
  th.id = `attack-head-col${colNum}`;
  th.innerHTML = `<input type="text" name="attackCol${colNum}Name" class="header-input" placeholder="${placeholder}">`;
  document.getElementById('attack-head-row').appendChild(th);

  // 2. tbodyの既存の各行（tr）にデータセル（td）を追加
  for (let r = 1; r <= rowNum; r++) {
    let rowTr = document.getElementById(`attack-row${r}`);
    if (rowTr) {
      let td = document.createElement('td');
      td.className = `attack-cell-col${colNum}`;
      td.innerHTML = `<input type="text" name="attackRow${r}Col${colNum}Value">`;
      rowTr.appendChild(td);
    }
  }
  
  colNumInput.value = colNum;
}

function delAttackCol() {
  let rowNumInput = document.querySelector('input[name="attackRowNum"]');
  let colNumInput = document.querySelector('input[name="attackColNum"]');
  if (!rowNumInput || !colNumInput) return;
  
  let rowNum = Number(rowNumInput.value);
  let colNum = Number(colNumInput.value);
  
  if (colNum > 1) {
    // ======== 削除確認（最後の列に値が入力されているかチェック） ========
    let hasValue = false;

    // 1. 削除対象の「見出し」に文字が入っているか
    let headInput = document.querySelector(`#attack-head-col${colNum} input`);
    if (headInput && headInput.value !== '') {
      hasValue = true;
    }

    // 2. 削除対象の「各行のセル」に文字が入っているか
    if (!hasValue) {
      for (let r = 1; r <= rowNum; r++) {
        let cellInput = document.querySelector(`input[name="attackRow${r}Col${colNum}Value"]`);
        if (cellInput && cellInput.value !== '') {
          hasValue = true;
          break; // 1つでも値があればチェック終了
        }
      }
    }

    // ゆとシート共通の削除確認ダイアログを呼び出す
    if (hasValue && typeof delConfirmText !== 'undefined') {
      if (!confirm(delConfirmText)) return false;
    }
    // ====================================================================

    // 1. theadの見出しセルを削除
    let th = document.getElementById(`attack-head-col${colNum}`);
    if (th) th.remove();
    
    // 2. tbodyの各行から最後のセルを削除
    for (let r = 1; r <= rowNum; r++) {
      let rowTr = document.getElementById(`attack-row${r}`);
      if (rowTr && rowTr.lastElementChild) {
        rowTr.lastElementChild.remove();
      }
    }
    
    colNumInput.value = colNum - 1;
  }
}



// ==========================================
// テキスト解析・自動入力処理 (改良版)
// ==========================================
function parseRawText() {
  const text = document.getElementById('import-raw-text').value.trim();
  if (!text) {
    alert('テキストが入力されていません。');
    return;
  }
  const lines = text.split(/\r?\n/);
  
  let sysData = {
    system: '', monsterName: '', characterName: '', taxa: '', subTaxa: '',
    bases: [], stts: [], battles: [], defenses: [],
    attacks: [], // [ { name: "主武装...", cells: { "攻撃力": "〈炎〉+24", ... } } ]
    skills: [], description: [], extras: [] // { name: "加護", text: [] }
  };

  let currentBlock = 'header'; 
  let hasSttOrBattle = false; 

  // ★判定用キーワードリスト（これらが行の先頭にあれば確実にステータスとして扱う）
  const statusKeys = ['レベル', 'サイズ', '属性', '体力', '反射', '知覚', '理知', '意志', '幸運', '命中', '回避', '砲撃', '防壁', '移動', '行動', 'FP', 'EN', '耐久', '力場', '感応', 'HP', 'MP'];
  const battleKeywords = ['命中', '回避', '砲撃', '防壁', '移動', '行動', 'FP', 'EN', '耐久', '力場', '感応'];
  const attackHeaders = ['攻撃力', '判定', '対象', '射程', 'C値', 'ダメージ', '効果'];

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].trim();
    if (!line) continue;

    if (line === '特技') { currentBlock = 'skills'; continue; }
    if (line === '解説') { currentBlock = 'description'; continue; }
    
    if ((currentBlock === 'skills' || currentBlock === 'extras') && 
        line.length < 20 && !line.includes('《') && !line.includes('》') && !line.match(/[：:]/) && !line.match(/[\s \xA0]/)) {
      let nextIndex = i + 1;
      while (nextIndex < lines.length && lines[nextIndex].trim() === '') nextIndex++;
      if (nextIndex < lines.length && (lines[nextIndex].trim().startsWith('《') || lines[nextIndex].trim().startsWith('>>') || lines[nextIndex].trim().startsWith('◆'))) {
         currentBlock = 'extras';
         sysData.extras.push({ name: line, text: [] });
         continue;
      }
    }

    if (currentBlock === 'skills') { sysData.skills.push(line); continue; }
    if (currentBlock === 'description') { sysData.description.push(line); continue; }
    if (currentBlock === 'extras') { sysData.extras[sysData.extras.length - 1].text.push(line); continue; }

    if (line.startsWith('システム名：')) {
      sysData.system = line.replace('システム名：', '').trim();
      continue;
    }
    if (line.startsWith('種別：')) {
      let taxaFull = line.replace('種別：', '').trim();
      let match = taxaFull.match(/^(.+?)（(.+?)）$/);
      if (match) {
        sysData.taxa = match[1].trim(); sysData.subTaxa = match[2].trim();
      } else {
        sysData.taxa = taxaFull;
      }
      continue;
    }
    // 防御修正の解析（全角スラッシュや混在にも完全対応）
    if (line.startsWith('防御修正：')) {
      let defItems = line.replace('防御修正：', '').trim().split(/[\\/／]/);
      defItems.forEach(item => {
        item = item.trim();
        if (!item) return;
        let match = item.match(/^([^0-9+-]+)([-+0-9*].*)$/); // '7*' のような記号付き数値にも対応
        if (match) {
          sysData.defenses.push({ name: match[1].trim(), value: match[2].trim() });
        } else {
          sysData.defenses.push({ name: item, value: '' });
        }
      });
      continue;
    }

    // 名前の判定（「：」を含まず、かつ既知のヘッダーでもない行）
    if (currentBlock === 'header' && !line.match(/[：:]/) && !line.startsWith('システム名') && !line.startsWith('種別') && !line.startsWith('防御修正')) {
      if (!sysData.monsterName && !sysData.characterName) {
        let match = line.match(/^(.+?)（(.+?)）$/);
        if (match) { sysData.characterName = match[1].trim(); sysData.monsterName = match[2].trim(); }
        else { sysData.monsterName = line.trim(); }
      }
      continue;
    }

    // ★修正ポイント：見えない空白（ノーブレークスペース等）を確実に分割し、空の要素を消し飛ばす
    let tokens = line.split(/[\s \xA0]+/);
    tokens = tokens.filter(tok => tok.trim() !== '');
    if (tokens.length === 0) continue;

    let firstTokenPair = tokens[0].split(/[：:]/);
    let firstKey = firstTokenPair[0].trim();
    
    let isStatusRow = false;
    let isAttackRow = false;

    // ★修正ポイント：最初のキーワードで「ステータス行」か「攻撃方法行」かを厳格に仕分け
    if (statusKeys.includes(firstKey)) {
       isStatusRow = true;
    } else {
       // 攻撃力、射程などの見出しが含まれているかチェック
       let hasAttackHeader = tokens.slice(1).some(tok => {
           let pair = tok.split(/[：:]/);
           return pair.length >= 2 && attackHeaders.includes(pair[0].trim());
       });
       if (hasAttackHeader) {
           isAttackRow = true;
       } else {
           let allSubTokensHaveColon = tokens.length > 1 && tokens.slice(1).every(tok => tok.match(/[：:]/));
           if (allSubTokensHaveColon) {
               isAttackRow = true;
           } else {
               isStatusRow = true;
           }
       }
    }

    if (isStatusRow) {
      tokens.forEach(token => {
        let pair = token.split(/[：:]/);
        if (pair.length >= 2) {
          let key = pair[0].trim();
          let val = pair.slice(1).join('：').trim();
          
          if (val.match(/[/／][-＋－+＋-][0-9０-９]+$/)) {
            // ／＋5 などがある場合は能力値。/で割って左側だけ使う
            sysData.stts.push({ name: key, value: val.split(/[/／]/)[0].trim() });
            hasSttOrBattle = true;
          } else {
            if (battleKeywords.includes(key)) hasSttOrBattle = true;
            
            if (hasSttOrBattle) {
               sysData.battles.push({ name: key, value: val });
            } else {
               sysData.bases.push({ name: key, value: val });
            }
          }
        }
      });
      continue;
    }

    if (isAttackRow) {
      let atkName = tokens[0]; // 名称（コロンがあっても丸ごと扱う）
      let cells = {};
      for (let j = 1; j < tokens.length; j++) {
        let pair = tokens[j].split(/[：:]/);
        if (pair.length >= 2) {
          cells[pair[0].trim()] = pair.slice(1).join('：').trim();
        }
      }
      sysData.attacks.push({ name: atkName, cells: cells });
      continue;
    }
  }

  // --------------------------------------------------
  // DOMへの反映処理
  // --------------------------------------------------
  const setVal = (name, val) => {
    let el = document.querySelector(`[name="${name}"]`);
    if (el) el.value = val;
  };

  const ensureRows = (listId, requiredNum, numInputName, prefix) => {
    let input = document.querySelector(`input[name="${numInputName}"]`);
    let ul = document.getElementById(listId);
    if (!input || !ul) return;
    let max = parseInt(input.value) || 1;
    
    while (max < requiredNum) {
      let lastLi = ul.lastElementChild;
      if (!lastLi) break;
      let newLi = lastLi.cloneNode(true);
      max++;
      newLi.id = `${prefix}-item${max}`;
      
      newLi.querySelectorAll('input, select, textarea').forEach(el => {
         if (el.name) el.name = el.name.replace(/\d+/, max);
         if (el.id) el.id = el.id.replace(/\d+/, max);
         el.value = '';
      });
      ul.appendChild(newLi);
      input.value = max;
    }
  };

  if (sysData.system) {
    let sel = document.querySelector('select[name="system"]');
    if (sel) {
      let opt = Array.from(sel.options).find(o => o.value === sysData.system);
      if (opt) sel.value = sysData.system;
      else {
        sel.value = 'その他';
        setVal('systemFree', sysData.system);
        let sysFree = document.getElementById('systemFree');
        if (sysFree) sysFree.style.display = 'inline-block';
      }
      if (typeof changeSystem === 'function') changeSystem();
    }
  }
  setVal('monsterName', sysData.monsterName);
  setVal('characterName', sysData.characterName);
  setVal('taxa', sysData.taxa);
  setVal('subTaxa', sysData.subTaxa);

  ensureRows('base-list', sysData.bases.length, 'baseNum', 'base');
  sysData.bases.forEach((item, i) => { setVal(`base${i+1}Name`, item.name); setVal(`base${i+1}Value`, item.value); });
  
  ensureRows('stt-list', sysData.stts.length, 'sttNum', 'stt');
  sysData.stts.forEach((item, i) => { setVal(`stt${i+1}Name`, item.name); setVal(`stt${i+1}Value`, item.value); });

  ensureRows('battle-list', sysData.battles.length, 'battleNum', 'battle');
  sysData.battles.forEach((item, i) => { setVal(`battle${i+1}Name`, item.name); setVal(`battle${i+1}Value`, item.value); });

  ensureRows('defense-list', sysData.defenses.length, 'defenseNum', 'defense');
  sysData.defenses.forEach((item, i) => { setVal(`defense${i+1}Name`, item.name); setVal(`defense${i+1}Value`, item.value); });

// ★修正ポイント：攻撃方法の見出しを既存のヘッダーに入力しつつ、足りなければ列を拡張する
  let colNames = ['名称'];
  sysData.attacks.forEach(atk => {
    Object.keys(atk.cells).forEach(cName => {
      if (!colNames.includes(cName)) colNames.push(cName);
    });
  });

  // 列の拡張（上限アラートによる無限ループ防止機能付き）
  let colNumInput = document.querySelector('input[name="attackColNum"]');
  if (colNumInput && typeof addAttackCol === 'function') {
    while (parseInt(colNumInput.value) < colNames.length) {
      let prevVal = parseInt(colNumInput.value);
      addAttackCol();
      // 上限に達して列数が増えなかった場合は無限ループを抜ける
      if (parseInt(colNumInput.value) === prevVal) {
        console.warn('攻撃方法の列数が上限に達しました。一部の項目は省略されます。');
        break;
      }
    }
  }
  
  // 実際に確保できた列数に合わせて配列を切り詰める
  let maxCol = colNumInput ? parseInt(colNumInput.value) : colNames.length;
  colNames = colNames.slice(0, maxCol);
  
  for (let c = 1; c < colNames.length; c++) {
    setVal(`attackCol${c+1}Name`, colNames[c]);
  }

  // 行の拡張（こちらも念のため無限ループ防止を入れる）
  let rowNumInput = document.querySelector('input[name="attackRowNum"]');
  if (rowNumInput && typeof addAttackRow === 'function') {
    while (parseInt(rowNumInput.value) < sysData.attacks.length) {
      let prevVal = parseInt(rowNumInput.value);
      addAttackRow();
      if (parseInt(rowNumInput.value) === prevVal) {
        console.warn('攻撃方法の行数が上限に達しました。一部の攻撃方法は省略されます。');
        break;
      }
    }
  }
  
  // 実際に確保できた行数に合わせてデータを切り詰める
  let maxRow = rowNumInput ? parseInt(rowNumInput.value) : sysData.attacks.length;
  let validAttacks = sysData.attacks.slice(0, maxRow);

  validAttacks.forEach((atk, r) => {
    setVal(`attackRow${r+1}Col1Value`, atk.name); // 1番目は必ず名称
    for (let c = 1; c < colNames.length; c++) {
       setVal(`attackRow${r+1}Col${c+1}Value`, atk.cells[colNames[c]] || ''); // 見出しに対応する値をセット
    }
  });

  setVal('skills', sysData.skills.join('\n'));
  setVal('description', sysData.description.join('\n'));
  
  if (sysData.extras.length > 0) {
    let box = document.getElementById('extra-textarea-box');
    if (box) box.style.display = 'block';
    
    sysData.extras.forEach((ex, i) => {
      let num = i + 1;
      let itemBox = document.getElementById(`extra-textarea-${num}`);
      if (itemBox) itemBox.style.display = 'block';
      setVal(`extra${num}Name`, ex.name);
      setVal(`extra${num}Text`, ex.text.join('\n'));
    });
  }

  alert('テキストの解析と自動入力が完了しました！');
}


// // 騎獣 ----------------------------------------
// let mountFlag = 0;
// function checkMount(){
//   mountFlag = form.mount.checked ? 1 : 0;
//   document.body.classList.toggle('mount', mountFlag);
// }
// function checkLevel(){
//   if(mountFlag){
//     checkMountLevel();
//   }
// }
// 各ステータス計算 ----------------------------------------
// function calcVit(){
//   const val = form.vitResist.value;
//   form.vitResistFix.value = (val == '') ? '' : Number(val) + 7;
// }
// function calcVitF(){
//   const val = form.vitResistFix.value;
//   form.vitResist.value    = (val == '') ? '' : Number(val) - 7;
// }
// function calcMnd(){
//   const val = form.mndResist.value;
//   form.mndResistFix.value = (val == '') ? '' : Number(val) + 7;
// }
// function calcMndF(){
//   const val = form.mndResistFix.value;
//   form.mndResist.value    = (val == '') ? '' : Number(val) - 7;
// }
// function calcAcc(Num){
//   const val = form['status'+Num+'Accuracy'].value;
//   form['status'+Num+'AccuracyFix'].value = (val == '') ? '' : Number(val) + 7;
// }
// function calcAccF(Num){
//   const val = form['status'+Num+'AccuracyFix'].value;
//   form['status'+Num+'Accuracy'].value    = (val == '') ? '' : Number(val) - 7;
// }
// function calcEva(Num){
//   const val = form['status'+Num+'Evasion'].value;
//   form['status'+Num+'EvasionFix'].value  = (val == '') ? '' : Number(val) + 7;
// }
// function calcEvaF(Num){
//   const val = form['status'+Num+'EvasionFix'].value;
//   form['status'+Num+'Evasion'].value     = (val == '') ? '' : Number(val) - 7;
// }

// ステータス欄 ----------------------------------------
// function checkMountLevel(){
//   let min = Number(form.lvMin.value) || 0;
//   let max = Number(form.lvMax.value) || 0;
//   if(max < min){ form.lvMax.value = max = min }
//   if(form.lv.value != ''){
//     if(form.lv.value < min){ form.lv.value = min }
//     if(form.lv.value > max){ form.lv.value = max }
//   }
//   let gap = max - min;
//   gap = gap < 0 ? 0 : gap;
//   if(gap > 0){
//     for(let lv = 2; lv <= gap+1; lv++){
//       if(!document.getElementById(`status-tbody${lv}`)){
//         let tbody = document.createElement("tbody");
//         tbody.classList.add('mount-only');
//         tbody.id = `status-tbody${lv}`;
//         tbody.dataset.lv = lv;
//         document.getElementById('status-table').append(tbody);
//         for(let num = 1; num <= form.statusNum.value; num++){
//           addStatusInsert(tbody, num);
//         }
//       }
//     }
//   }
//   for(let lv = gap+2; document.getElementById(`status-tbody${lv}`); lv++){
//     document.getElementById(`status-tbody${lv}`).remove();
//   }
//   for(let num = 1; num <= form.statusNum.value; num++){ checkStyle(num); }
//   rewriteMountLevel(min);
// }
// function rewriteMountLevel(level){
//   level ||= form.lvMin.value;
//   document.querySelectorAll("#status-table tbody tr th:first-child").forEach(obj => {
//     obj.textContent = '';
//   });
//   document.querySelectorAll("#status-table tbody tr:first-child th:first-child").forEach(obj => {
//     obj.textContent = level;
//     obj.classList.toggle('current', level == form.lv.value);
//     level++;
//   });
// }
// // 攻撃方法
// function checkStyle(num){
//   document.querySelectorAll(`#status-table .name[data-style="${num}"]`).forEach(obj => {
//     obj.textContent = form[`status${num}Style`].value;
//   });
// }
// // 追加・複製
// function addStatus(copy){
//   let num = Number(form.statusNum.value) + 1;
//   document.querySelectorAll("#status-table tbody").forEach(obj => {
//     addStatusInsert(obj, num, copy);
//   });
//   form.statusNum.value = num;
//   statusTextInputToggle();
//   updatePartsAutomatically();
// }
// function addStatusInsert(target, num, copy){
//   const lv = target.dataset.lv ? '-'+target.dataset.lv : '';
//   const ini = {
//     "style"      : copy && !lv ? form[`status${copy}${lv}Style`       ].value : '',
//     "accuracy"   : copy        ? form[`status${copy}${lv}Accuracy`    ].value : '',
//     "accuracyFix": copy && !lv ? form[`status${copy}${lv}AccuracyFix` ].value : '',
//     "damage"     : copy        ? form[`status${copy}${lv}Damage`      ].value : '2d+',
//     "evasion"    : copy        ? form[`status${copy}${lv}Evasion`     ].value : '',
//     "evasionFix" : copy && !lv ? form[`status${copy}${lv}EvasionFix`  ].value : '',
//     "defense"    : copy        ? form[`status${copy}${lv}Defense`     ].value : '',
//     "hp"         : copy        ? form[`status${copy}${lv}Hp`          ].value : '',
//     "mp"         : copy        ? form[`status${copy}${lv}Mp`          ].value : '',
//     "vit"        : copy        ? form[`status${copy}${lv}Vit`         ].value : (num == 1 ? '' : '―'),
//     "mnd"        : copy        ? form[`status${copy}${lv}Mnd`         ].value : (num == 1 ? '' : '―'),
//   };
//   let tr = document.createElement('tr');
//   tr.setAttribute('id',idNumSet('status-row',lv));
//   tr.innerHTML = `
//     <th class="mount-only"></th>
//     <td ${ lv ? '' : `class="handle"`}></td>
//     <td ${ lv ? 'class="name"' : ``} data-style="${num}">${ lv ? form[`status${num}Style`].value : `<input name="status${num}${lv}Style" type="text" value="${ini.style}" oninput="checkStyle(${num}${lv}); updatePartsAutomatically();">` }</td>
//     <td>
//       <input name="status${num}${lv}Accuracy" type="text" oninput="calcAcc('${num}${lv}')" value="${ini.accuracy}"><span class="monster-only calc-only"><br>
//       (<input name="status${num}${lv}AccuracyFix" type="text" oninput="calcAccF('${num}${lv}')" value="${ini.accuracyFix}">)</span>
//     </td>
//     <td><input name="status${num}${lv}Damage" type="text" value="${ini.damage}"></td>
//     <td>
//       <input name="status${num}${lv}Evasion" type="text" oninput="calcEva('${num}${lv}')" value="${ini.evasion}"><span class="monster-only calc-only"><br>
//       (<input name="status${num}${lv}EvasionFix" type="text" oninput="calcEvaF('${num}${lv}')" value="${ini.evasionFix}">)</span>
//     </td>
//     <td><input name="status${num}${lv}Defense" type="text" value="${ini.defense}"></td>
//     <td><input name="status${num}${lv}Hp" type="text" value="${ini.hp}"></td>
//     <td><input name="status${num}${lv}Mp" type="text" value="${ini.mp}"></td>
//     <td class="mount-only"><input name="status${num}${lv}Vit" type="text" value="${ini.vit}"></td>
//     <td class="mount-only"><input name="status${num}${lv}Mnd" type="text" value="${ini.mnd}"></td>
//     <td>${ lv ? '' : `<span class="button" onclick="addStatus('${num}${lv}');">複<br>製</span>` }</td>
//   `;
//   target.appendChild(tr, target);
// }
// // 削除
// function delStatus(){
//   let num = Number(form.statusNum.value);
//   if(num > 1){
//     let hasValue = false;
//     for (const node of document.querySelectorAll(`#status-table tbody tr:last-child input`)){
//       if(
//         node.value !== '' &&
//         !(/Damage$/.test(node.getAttribute('name')) && node.value === '2d+') &&
//         !(/Vit$/.test(node.getAttribute('name')) && node.value === '―') &&
//         !(/Mnd$/.test(node.getAttribute('name')) && node.value === '―')
//       ){
//         hasValue = true; break;
//       }
//     }
//     if(hasValue){
//       if (!confirm(delConfirmText)){ return false; }
//     }
//     document.querySelectorAll("#status-table tbody tr:last-child").forEach(target => {
//       target.remove();
//     });
//     num--;
//     form.statusNum.value = num;
//   }
//   updatePartsAutomatically();
// }
// // ソート
// (() => {
//   let sortable = Sortable.create(document.querySelector('#status-table tbody'), {
//     dataIdAttr: 'id',
//     animation: 150,
//     handle: '.handle',
//     filter: 'thead,tfoot',
//     onUpdate: function (evt) {
//       const order = sortable.toArray();
//       let num = 1;
//       for(let id of order) {
//         const row = document.querySelector(`tr#${id}`);
//         if(!row) continue;
//         row.querySelectorAll('[name]').forEach(inputField => {
//           const beforeName = inputField.getAttribute('name');
//           const afterName = beforeName.replace(/^(status)\d+(.+)$/, `$1${num}$2`);
//           inputField.setAttribute('name', afterName)
//         });
//         row.querySelectorAll('[oninput]').forEach(inputField => {
//           const beforeName = inputField.getAttribute('oninput');
//           const afterName = beforeName.replace(/\(\d+\)/, `(${num})`);
//           inputField.setAttribute('oninput', afterName)
//         });
//         row.querySelector(`span[onclick]`).setAttribute('onclick',`addStatus(${num})`);
//         num++;
//       }
//       const moved  = evt.item.id;
//       const before = evt.item.previousElementSibling ? evt.item.previousElementSibling.id : '';
//       document.querySelectorAll("#status-table tbody").forEach(obj => {
//         const lv = obj.dataset.lv;
//         if(lv){
//           if(before){
//             document.getElementById(before+'-'+lv).after(document.getElementById(moved+'-'+lv));
//           }
//           else {
//             document.getElementById(`status-tbody${lv}`).prepend(document.getElementById(moved+'-'+lv))
//           }
//           let num = 1;
//           for(let id of order) {
//             const row = document.querySelector(`tr#${id}-${lv}`);
//             if(!row) continue;
//             row.querySelectorAll('[name]').forEach(inputField => {
//               const beforeName = inputField.getAttribute('name');
//               const afterName = beforeName.replace(/^(status)\d+-(.+)$/, `$1${num}-$2`);
//               inputField.setAttribute('name', afterName)
//             });
//             row.querySelector(`.name`).dataset.style = num;
//             num++;
//           }
//         }
//       });
//       rewriteMountLevel();
//       updatePartsAutomatically();
//     }
//   });
// })();
// //
// function statusTextInputToggle(){
//   const on = form.statusTextInput.checked ? 1 : form.mount.checked ? 1 : 0;
//   form[`vitResist`].type    = on ? 'text'   : 'number';
//   form[`mndResist`].type    = on ? 'text'   : 'number';
//   for(let i = 1; i <= form.statusNum.value; i++){
//     form[`status${i}Accuracy`].type    = on ? 'text'   : 'number';
//     form[`status${i}Evasion`].type     = on ? 'text'   : 'number';
//   }
//   form.classList.toggle('not-calc', on)
// }
// // 部位数・内訳の自動入力
// function updatePartsAutomatically() {
//   const manualModeCheckbox = document.querySelector('input[type="checkbox"][name="partsManualInput"]');
//   const partsNumInput = document.querySelector('.parts input[name="partsNum"]');
//   const partsNamesInput = document.querySelector('.parts input[name="parts"]');

//   if (manualModeCheckbox.checked) {
//     partsNumInput.readOnly = false;
//     partsNamesInput.readOnly = false;
//     return;
//   }

//   let partCount = 0;
//   const partNames = [];
//   document.querySelectorAll('#status-tbody input[name$="Style"]').forEach(
//       input => {
//         partCount++;

//         const style = input.value.trim();
//         const m = style.match(/.*[(（](.+?)[）)]$/);
//         if (m == null) {
//           return;
//         }
//         partNames.push(m[1].trim());
//       }
//   );

//   partsNumInput.readOnly = true;
//   partsNumInput.value = partCount.toString();
//   partsNumInput.dispatchEvent(new Event('input'));

//   partsNamesInput.readOnly = true;
//   partsNamesInput.value = partNames.length === 0 ? '' : partNames.reduce(
//       (previous, currentPartName) => {
//         const previousPartTexts = previous.split('／');
//         const lastPartText = previousPartTexts[previousPartTexts.length - 1];
//         const m = lastPartText.match(/^(.+?)(?:×(\d+))?$/);
//         const lastPartName = m[1];
//         const lastPartCount = m[2] ? parseInt(m[2]) : 1;
//         return currentPartName === lastPartName
//             ? `${previousPartTexts.length > 1 ? `${previousPartTexts.slice(0, -1).join('／')}／` : ''}${lastPartName}×${lastPartCount + 1}`
//             : `${previous}／${currentPartName}`;
//       }
//   );
//   partsNamesInput.dispatchEvent(new Event('input'));
// }
// function updatePartList() {
//   const partsText = document.querySelector('input[name="parts"]').value.trim();

//   const items =
//       partsText
//           .split(/[/／]/)
//           .map(x => x.trim())
//           .filter(x => x !== '')
//           .map(part => part.replace(/[*×][\d０１２３４５６７８９]+$/, '（すべて）'));

//   const datalist = document.getElementById('list-of-core-part');
//   datalist.innerHTML = '';

//   if (items.length === 0) {
//     return;
//   }

//   items.unshift("なし");

//   items.forEach(
//       item => {
//         const option = document.createElement('option');
//         option.textContent = item;
//         datalist.appendChild(option);
//       }
//   );
// }
// // 戦利品欄 ----------------------------------------
// // 追加
// function addLoots(){
//   let num = Number(form.lootsNum.value) + 1;
//   let liNum = document.createElement('li');
//   let liItem = document.createElement('li');
//   liNum.id= idNumSet("loots-num");
//   liItem.id= idNumSet("loots-item");
//   liNum.innerHTML = '<span class="handle"></span><input type="text" name="loots'+num+'Num">';
//   liItem.innerHTML = '<span class="handle"></span><input type="text" name="loots'+num+'Item">';
//   document.getElementById("loots-num").appendChild(liNum);
//   document.getElementById("loots-item").appendChild(liItem);
  
//   form.lootsNum.value = num;
// }
// // 削除
// function delLoots(){
//   let num = Number(form.lootsNum.value);
//   if(num > 1){
//     if(form[`loots${num}Num`].value || form[`loots${num}Item`].value){
//       if (!confirm(delConfirmText)) return false;
//     }
//     const listNum  = document.getElementById("loots-num");
//     const listItem = document.getElementById("loots-item");
//     listNum.lastElementChild.remove();
//     listItem.lastElementChild.remove();
//     num--;
//     form.lootsNum.value = num;
//   }
// }
// ソート
// setSortable('loots','#loots-num');
// setSortable('loots','#loots-item');
