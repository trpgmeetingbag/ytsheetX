# ============================================================================																				
# メタリックガーディアンRPG クラスデータ定義ファイル																				
# ============================================================================																				
package data;																				
use strict;																				
use utf8;																				
																				
# %class ハッシュに全クラスのデータを格納します。																				
# これが後に encode_json によってJavaScript側の mgrClasses オブジェクトに変換されます。																				
our %class_tenka = (																				
																				
  # --------------------------------------------------------------------------																				
  # ▼ リンケージクラス																				
  # --------------------------------------------------------------------------																				
  'ストライカー' => {																			
    type => 'リンケージ', # 判定用（リンケージ または ガーディアン）																		
    sort => '01',      # プルダウン等での並び順																		
    stt  => { Tai => 4, Han => 5, Chi => 5, Ri => 4, Ishi => 2, Kou => 4 }, # 能力値基本値						
    battle => {																			
        1  => { Meichu => 1, Kaihi => 0, Hougeki => 1, Bouheki => 0, Koudou => 0, Rikiba => 6, Taikyu => 2, Kannou => 3, Kougeki => 2 },	
        2  => { Meichu => 2, Kaihi => 1, Hougeki => 2, Bouheki => 1, Koudou => 1, Rikiba => 11, Taikyu => 4, Kannou => 6, Kougeki => 3 },	
        3  => { Meichu => 2, Kaihi => 1, Hougeki => 2, Bouheki => 1, Koudou => 1, Rikiba => 16, Taikyu => 6, Kannou => 9, Kougeki => 4 },	
        4  => { Meichu => 3, Kaihi => 2, Hougeki => 3, Bouheki => 2, Koudou => 2, Rikiba => 21, Taikyu => 8, Kannou => 12, Kougeki => 5 },	
        5  => { Meichu => 3, Kaihi => 2, Hougeki => 3, Bouheki => 2, Koudou => 2, Rikiba => 27, Taikyu => 10, Kannou => 15, Kougeki => 6 },	
        6  => { Meichu => 4, Kaihi => 3, Hougeki => 4, Bouheki => 3, Koudou => 3, Rikiba => 32, Taikyu => 12, Kannou => 18, Kougeki => 7 },	
        7  => { Meichu => 4, Kaihi => 3, Hougeki => 4, Bouheki => 3, Koudou => 3, Rikiba => 37, Taikyu => 14, Kannou => 21, Kougeki => 8 },	
        8  => { Meichu => 5, Kaihi => 4, Hougeki => 5, Bouheki => 4, Koudou => 3, Rikiba => 42, Taikyu => 16, Kannou => 24, Kougeki => 9 },	
        9  => { Meichu => 5, Kaihi => 4, Hougeki => 5, Bouheki => 4, Koudou => 4, Rikiba => 47, Taikyu => 18, Kannou => 27, Kougeki => 10 },	
        10 => { Meichu => 6, Kaihi => 5, Hougeki => 6, Bouheki => 5, Koudou => 4, Rikiba => 53, Taikyu => 20, Kannou => 30, Kougeki => 12 },	
        11 => { Meichu => 7, Kaihi => 6, Hougeki => 7, Bouheki => 6, Koudou => 5, Rikiba => 59, Taikyu => 22, Kannou => 33, Kougeki => 12 },	
        12 => { Meichu => 7, Kaihi => 6, Hougeki => 7, Bouheki => 6, Koudou => 5, Rikiba => 65, Taikyu => 24, Kannou => 36, Kougeki => 13 },	
        13 => { Meichu => 8, Kaihi => 7, Hougeki => 8, Bouheki => 7, Koudou => 5, Rikiba => 71, Taikyu => 26, Kannou => 39, Kougeki => 14 },	
        14 => { Meichu => 8, Kaihi => 7, Hougeki => 8, Bouheki => 7, Koudou => 6, Rikiba => 77, Taikyu => 28, Kannou => 42, Kougeki => 15 },	
        15 => { Meichu => 9, Kaihi => 8, Hougeki => 9, Bouheki => 8, Koudou => 6, Rikiba => 83, Taikyu => 30, Kannou => 45, Kougeki => 16 },	
        16 => { Meichu => 9, Kaihi => 8, Hougeki => 9, Bouheki => 8, Koudou => 6, Rikiba => 89, Taikyu => 32, Kannou => 48, Kougeki => 17 },	
        17 => { Meichu => 10, Kaihi => 9, Hougeki => 10, Bouheki => 9, Koudou => 7, Rikiba => 95, Taikyu => 34, Kannou => 51, Kougeki => 18 },	
        18 => { Meichu => 10, Kaihi => 9, Hougeki => 10, Bouheki => 9, Koudou => 7, Rikiba => 101, Taikyu => 36, Kannou => 54, Kougeki => 19 },	
        19 => { Meichu => 11, Kaihi => 10, Hougeki => 11, Bouheki => 10, Koudou => 7, Rikiba => 107, Taikyu => 38, Kannou => 57, Kougeki => 20 },	
        20 => { Meichu => 12, Kaihi => 10, Hougeki => 12, Bouheki => 10, Koudou => 8, Rikiba => 113, Taikyu => 40, Kannou => 60, Kougeki => 21 },	
    },																			
  },																			
															
																				
  # --------------------------------------------------------------------------																				
  # ▼ ガーディアンスタイル																				
  # --------------------------------------------------------------------------																				
  'カバリエ' => {																			
    type => 'ガーディアン',																			
    sort => '10',																			
    stt  => { Tai => 4, Han => 5, Chi => 5, Ri => 3, Ishi => 3, Kou => 4 },							
    battle => {																			
        1  => { Meichu => 2, Kaihi => 1, Hougeki => 1, Bouheki => 0, Koudou => 2, Rikiba => 6, Taikyu => 3, Kannou => 3, Kougeki => 1 },	
        2  => { Meichu => 2, Kaihi => 2, Hougeki => 2, Bouheki => 1, Koudou => 2, Rikiba => 12, Taikyu => 6, Kannou => 6, Kougeki => 2 },	
        3  => { Meichu => 3, Kaihi => 2, Hougeki => 2, Bouheki => 1, Koudou => 3, Rikiba => 19, Taikyu => 9, Kannou => 9, Kougeki => 2 },	
        4  => { Meichu => 3, Kaihi => 3, Hougeki => 3, Bouheki => 2, Koudou => 3, Rikiba => 26, Taikyu => 12, Kannou => 12, Kougeki => 3 },	
        5  => { Meichu => 4, Kaihi => 3, Hougeki => 3, Bouheki => 2, Koudou => 4, Rikiba => 32, Taikyu => 15, Kannou => 16, Kougeki => 4 },	
        6  => { Meichu => 4, Kaihi => 4, Hougeki => 4, Bouheki => 3, Koudou => 5, Rikiba => 39, Taikyu => 18, Kannou => 19, Kougeki => 4 },	
        7  => { Meichu => 5, Kaihi => 4, Hougeki => 4, Bouheki => 3, Koudou => 6, Rikiba => 46, Taikyu => 21, Kannou => 22, Kougeki => 5 },	
        8  => { Meichu => 6, Kaihi => 5, Hougeki => 5, Bouheki => 4, Koudou => 7, Rikiba => 53, Taikyu => 24, Kannou => 25, Kougeki => 6 },	
        9  => { Meichu => 6, Kaihi => 5, Hougeki => 5, Bouheki => 4, Koudou => 7, Rikiba => 60, Taikyu => 27, Kannou => 29, Kougeki => 6 },	
        10 => { Meichu => 7, Kaihi => 6, Hougeki => 6, Bouheki => 5, Koudou => 8, Rikiba => 67, Taikyu => 30, Kannou => 33, Kougeki => 7 },	
        11 => { Meichu => 8, Kaihi => 7, Hougeki => 6, Bouheki => 6, Koudou => 9, Rikiba => 74, Taikyu => 34, Kannou => 36, Kougeki => 8 },	
        12 => { Meichu => 8, Kaihi => 7, Hougeki => 7, Bouheki => 6, Koudou => 9, Rikiba => 81, Taikyu => 37, Kannou => 40, Kougeki => 9 },	
        13 => { Meichu => 9, Kaihi => 8, Hougeki => 7, Bouheki => 7, Koudou => 10, Rikiba => 88, Taikyu => 41, Kannou => 43, Kougeki => 9 },	
        14 => { Meichu => 10, Kaihi => 8, Hougeki => 8, Bouheki => 7, Koudou => 11, Rikiba => 95, Taikyu => 43, Kannou => 48, Kougeki => 10 },	
        15 => { Meichu => 11, Kaihi => 9, Hougeki => 8, Bouheki => 8, Koudou => 12, Rikiba => 102, Taikyu => 47, Kannou => 51, Kougeki => 11 },	
        16 => { Meichu => 11, Kaihi => 9, Hougeki => 9, Bouheki => 8, Koudou => 12, Rikiba => 108, Taikyu => 50, Kannou => 55, Kougeki => 12 },	
        17 => { Meichu => 12, Kaihi => 10, Hougeki => 10, Bouheki => 9, Koudou => 13, Rikiba => 115, Taikyu => 54, Kannou => 58, Kougeki => 12 },	
        18 => { Meichu => 12, Kaihi => 10, Hougeki => 11, Bouheki => 10, Koudou => 14, Rikiba => 122, Taikyu => 58, Kannou => 61, Kougeki => 13 },	
        19 => { Meichu => 13, Kaihi => 11, Hougeki => 12, Bouheki => 11, Koudou => 14, Rikiba => 129, Taikyu => 61, Kannou => 65, Kougeki => 14 },	
        20 => { Meichu => 14, Kaihi => 12, Hougeki => 13, Bouheki => 12, Koudou => 15, Rikiba => 136, Taikyu => 64, Kannou => 69, Kougeki => 15 },	
    },																			
  },																			
																				
  'クラッシャー' => {																			
    type => 'ガーディアン',																			
    sort => '11',																			
    stt  => { Tai => 6, Han => 5, Chi => 5, Ri => 2, Ishi => 3, Kou => 3 },							
    battle => {																			
        1  => { Meichu => 2, Kaihi => 1, Hougeki => 0, Bouheki => 0, Koudou => 1, Rikiba => 7, Taikyu => 4, Kannou => 2, Kougeki => 1 },	
        2  => { Meichu => 2, Kaihi => 1, Hougeki => 0, Bouheki => 1, Koudou => 2, Rikiba => 14, Taikyu => 8, Kannou => 4, Kougeki => 2 },	
        3  => { Meichu => 3, Kaihi => 2, Hougeki => 1, Bouheki => 1, Koudou => 3, Rikiba => 21, Taikyu => 12, Kannou => 6, Kougeki => 3 },	
        4  => { Meichu => 3, Kaihi => 2, Hougeki => 1, Bouheki => 2, Koudou => 4, Rikiba => 28, Taikyu => 16, Kannou => 8, Kougeki => 3 },	
        5  => { Meichu => 4, Kaihi => 3, Hougeki => 1, Bouheki => 2, Koudou => 5, Rikiba => 35, Taikyu => 20, Kannou => 10, Kougeki => 4 },	
        6  => { Meichu => 4, Kaihi => 3, Hougeki => 2, Bouheki => 3, Koudou => 6, Rikiba => 42, Taikyu => 24, Kannou => 12, Kougeki => 5 },	
        7  => { Meichu => 5, Kaihi => 4, Hougeki => 2, Bouheki => 3, Koudou => 7, Rikiba => 49, Taikyu => 28, Kannou => 14, Kougeki => 6 },	
        8  => { Meichu => 6, Kaihi => 4, Hougeki => 2, Bouheki => 4, Koudou => 8, Rikiba => 56, Taikyu => 32, Kannou => 16, Kougeki => 6 },	
        9  => { Meichu => 6, Kaihi => 5, Hougeki => 3, Bouheki => 4, Koudou => 9, Rikiba => 63, Taikyu => 36, Kannou => 18, Kougeki => 7 },	
        10 => { Meichu => 7, Kaihi => 5, Hougeki => 3, Bouheki => 5, Koudou => 10, Rikiba => 70, Taikyu => 40, Kannou => 20, Kougeki => 8 },	
        11 => { Meichu => 8, Kaihi => 6, Hougeki => 4, Bouheki => 5, Koudou => 11, Rikiba => 77, Taikyu => 44, Kannou => 22, Kougeki => 9 },	
        12 => { Meichu => 8, Kaihi => 6, Hougeki => 4, Bouheki => 6, Koudou => 12, Rikiba => 84, Taikyu => 48, Kannou => 24, Kougeki => 9 },	
        13 => { Meichu => 9, Kaihi => 7, Hougeki => 5, Bouheki => 6, Koudou => 13, Rikiba => 91, Taikyu => 52, Kannou => 26, Kougeki => 10 },	
        14 => { Meichu => 10, Kaihi => 7, Hougeki => 5, Bouheki => 7, Koudou => 14, Rikiba => 98, Taikyu => 56, Kannou => 28, Kougeki => 11 },	
        15 => { Meichu => 11, Kaihi => 8, Hougeki => 5, Bouheki => 7, Koudou => 15, Rikiba => 105, Taikyu => 60, Kannou => 30, Kougeki => 12 },	
        16 => { Meichu => 11, Kaihi => 8, Hougeki => 6, Bouheki => 8, Koudou => 16, Rikiba => 112, Taikyu => 64, Kannou => 32, Kougeki => 12 },	
        17 => { Meichu => 12, Kaihi => 9, Hougeki => 6, Bouheki => 8, Koudou => 17, Rikiba => 119, Taikyu => 68, Kannou => 34, Kougeki => 13 },	
        18 => { Meichu => 12, Kaihi => 9, Hougeki => 7, Bouheki => 9, Koudou => 18, Rikiba => 126, Taikyu => 72, Kannou => 36, Kougeki => 14 },	
        19 => { Meichu => 13, Kaihi => 10, Hougeki => 7, Bouheki => 9, Koudou => 19, Rikiba => 133, Taikyu => 76, Kannou => 38, Kougeki => 14 },	
        20 => { Meichu => 14, Kaihi => 11, Hougeki => 8, Bouheki => 10, Koudou => 20, Rikiba => 140, Taikyu => 80, Kannou => 40, Kougeki => 15 },	
    },																			
  },
  'AS(パッチワーク)' => {																			
    type => 'ガーディアン',																			
    sort => '52',																			
    stt  => { Tai => 4, Han => 4, Chi => 4, Ri => 4, Ishi => 4, Kou => 4 },							
    battle => {																			
        1  => { Meichu => 0, Kaihi => 0, Hougeki => 1, Bouheki => 0, Koudou => 1, Rikiba => 6, Taikyu => 3, Kannou => 3, Kougeki => 1 },	
        2  => { Meichu => 1, Kaihi => 1, Hougeki => 1, Bouheki => 1, Koudou => 2, Rikiba => 10, Taikyu => 4, Kannou => 4, Kougeki => 1 },	
        3  => { Meichu => 1, Kaihi => 1, Hougeki => 2, Bouheki => 1, Koudou => 4, Rikiba => 16, Taikyu => 15, Kannou => 16, Kougeki => 2 },	
        4  => { Meichu => 2, Kaihi => 2, Hougeki => 2, Bouheki => 2, Koudou => 5, Rikiba => 22, Taikyu => 18, Kannou => 19, Kougeki => 2 },	
        5  => { Meichu => 2, Kaihi => 2, Hougeki => 3, Bouheki => 2, Koudou => 6, Rikiba => 31, Taikyu => 21, Kannou => 22, Kougeki => 3 },	
        6  => { Meichu => 3, Kaihi => 3, Hougeki => 3, Bouheki => 3, Koudou => 7, Rikiba => 37, Taikyu => 24, Kannou => 25, Kougeki => 3 },	
        7  => { Meichu => 3, Kaihi => 3, Hougeki => 4, Bouheki => 3, Koudou => 8, Rikiba => 43, Taikyu => 27, Kannou => 29, Kougeki => 4 },	
        8  => { Meichu => 4, Kaihi => 4, Hougeki => 4, Bouheki => 4, Koudou => 9, Rikiba => 49, Taikyu => 30, Kannou => 33, Kougeki => 4 },	
        9  => { Meichu => 4, Kaihi => 4, Hougeki => 5, Bouheki => 4, Koudou => 10, Rikiba => 55, Taikyu => 33, Kannou => 36, Kougeki => 5 },	
        10 => { Meichu => 5, Kaihi => 5, Hougeki => 5, Bouheki => 5, Koudou => 11, Rikiba => 61, Taikyu => 36, Kannou => 39, Kougeki => 6 },	
    },																			
  },																			
);																				
																				
																				
our %tmp = (																				
  # クラスデータテンプレート　オリジナル等追加データを入れる場合これを使うこと																				
  'tmp' => {																			
    type => 'ガーディアン',																			
    sort => '0',																			
    stt  => { Tai => 0, Han => 0, Chi => 0, Ri => 0, Ishi => 0, Kou => 0 },							
    battle => {																			
      1  => { Meichu => 1, Kaihi => 1, Hougeki => 1, Bouheki => 1, Koudou => 1, Rikiba => 1, Taikyu => 1, Kannou => 1, Kougeki => 1 },	
      # ... (各レベルのデータを追記) ...																				
      20 => { Meichu => 0, Kaihi => 0, Hougeki => 0, Bouheki => 0, Koudou => 0, Rikiba => 0, Taikyu => 0, Kannou => 0, Kougeki => 0 },	
   	 } 																			
  },																			
);																				
1; # Perlモジュールの末尾に必須																				
