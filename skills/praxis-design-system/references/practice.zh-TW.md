# Praxis 選型與實作指南

使用者以繁體中文描述需求即可。Codex 負責把情境對應到上游的英文名稱，回到使用者的語言解釋選擇。先認清這次要決定的是整體風格、局部操作、圖解語法，還是既有畫面的修整。只有整體視覺方向仍開放時，才需要產生風格候選。

## 從需求縮小範圍

| 使用情境 | 第一個決定 | 接著查什麼 |
| --- | --- | --- |
| 已有品牌，修表格、表單或對話框 | 保留既有元件與語意 token，確認改動範圍 | 用 Google Modern Web Guidance 查該操作，讀相關 UX 規則，再以 Impeccable 檢查排版或狀態 |
| 新網站、方向尚未決定 | 以主要訪客的任務找出最接近的產品情境 | 用 shortlist 讀取原始產品規則，再用 Design Pro 或 Taste 比較能承載現有素材的構圖 |
| 使用者點名某種風格 | 直接開啟該風格全文，辨識使用者想保留的特徵 | 查明暗模式、字體、互動、適用條件；有衝突時說明具體影響 |
| 審查既有網站或參考案例 | 先在指定網址、截圖或元件上記錄所見 | Frontend Codex 拆解結構與互動，Refero 補足可查證的參考，Impeccable 用於說明缺陷和修正方式 |
| 資料、流程或架構圖 | 先寫下讀者要辨認的關係 | 查 Diagram Design 的型別與範例。責任交接優先看泳道，跨時間訊息優先看序列，共同階段中的前後台服務優先看服務藍圖 |

從已安裝 Praxis 的專案根目錄執行。透過 `-g` 安裝時，將第一行改成使用者的技能目錄。

```bash
PRAXIS_DIR="$PWD/.agents/skills/praxis-design-system"
python3 "$PRAXIS_DIR/scripts/catalog.py" -c ui-products "research lab"
python3 "$PRAXIS_DIR/scripts/shortlist.py" research-lab-university-department --intent content_focused --intent trust_needed
python3 "$PRAXIS_DIR/scripts/catalog.py" --show ui-styles/editorial-grid-magazine
python3 "$PRAXIS_DIR/scripts/catalog.py" --show design-pro-composition/reading-column-with-references
```

`--intent` 接受明確的正向需求，可以重複指定。`--mode light` 或 `--mode dark` 只保留上游明確標示支援該模式的候選。`--low-cost` 只保留上游標示低渲染成本的候選。這兩種篩選適合當作硬性條件使用。執行結果同時列出來源規則、符合者、排除理由與無法對應的上游名稱。「低成本」是資料庫的分類，實際裝置表現仍須量測。上游規則中的建議功能只有在符合委託範圍時才採用。

若候選都是空的，保留原始限制，回到專案既有系統或用其他資料庫探索。當兩案都符合條件，先比較哪一案能用現有文字、照片或真實資料完成主要任務，再比較哪一案在窄螢幕上最能保留資訊層級。兩者表現相近就沿用專案既有元件。將選擇連到一個可觀察的行為，後續修改時才有依據。

## 三個實作情境

**雙語研究網站。** 假設訪客的問題是「這項研究有什麼證據？」。先用研究標題、主要發現、來源和限制，排出可閱讀的段落。可由「Editorial Grid / Magazine」取得篇章節奏，由「Reading column with references」安排主張與引文的距離。如果只改既有研究頁，就沿用既有字階與連結色。驗收時放入一個長中文題名與一個長英文題名，從窄螢幕開啟證據來源，再返回原閱讀位置。個人研究頁的功能以實際內容為準，實驗室資料庫裡的徵才或團隊需求只屬於對應情境。 [產品規則](.upstream/ui-ux-pro-max-skill/src/ui-ux-pro-max/data/ui-reasoning.csv) · [構圖決策](.upstream/design-pro/skills/design-pro/references/creative-library.md)

**行動裝置上的館藏瀏覽。** 如果簡報明定淺色模式、低渲染成本，而且只有平面作品照片，執行 `shortlist.py museum-gallery --mode light --low-cost`。這個快照會排除「3D & Hyperrealism」，理由包含高渲染成本與淺色模式需額外處理。從留下的方案選擇「Minimalism & Swiss Style」，用照片、作者與作品名稱建立主次。以真實橫幅、直幅及長標題測試裁切，確認手機上能進入作品、讀取說明並返回原瀏覽位置。若使用者提供可旋轉模型並要求看清側面細節，才重新評估 3D 成本和替代呈現。 [風格規格](.upstream/ui-ux-pro-max-skill/src/ui-ux-pro-max/data/styles.csv) · [RCS 3D 指引](.upstream/rcs-frontend-skill/references/3d-and-graphics.md)

**跨組交接圖。** 要解釋「誰在何時把案件交給下一組」，執行 `catalog.py --show diagrams/swimlane`。讓每一列代表一個負責角色，將跨列的箭頭留給真正的交接。若原始紀錄沒有說明負責人，圖上就保留待確認。將專案的行動色用於需要讀者注意的那次交接。打開實際輸出的 HTML/SVG，沿箭頭從頭讀到尾，確認讀者可以指出交出者、接手者與順序，並檢查小螢幕的標籤和文字替代。 [泳道型別規格](.upstream/diagram-design/skills/diagram-design/references/type-swimlane.md)

## 將選定的風格落到畫面

依畫面需要挑選下表的檢查。若設計決定已存在，直接記錄沿用的元件、token 或路徑。能在交付說明中講清楚的單次調整，可直接在交付說明留下證據。

| 面向 | 需要做出的決定 | 能觀察到的驗收結果 |
| --- | --- | --- |
| 字體與閱讀 | 指定標題、正文、數值與註解的角色。用真實中英文、長數字和缺字情境檢查備援字型 | 標題換行後仍與摘要相連。數值欄位可逐列比較。字型載入前後，主要操作仍在可見範圍 |
| 語意色與狀態 | 將文字對背景、按鈕對標籤、焦點對鄰近表面成對檢查。狀態同時有文字或形狀可辨識 | 在實際配色與主題檢查對比。以鍵盤移動焦點時，看得出目前可操作項目 |
| 版面與密度 | 指定主要內容、次要證據及操作的閱讀順序。窄版先決定哪些資訊必須同時可見 | 在單欄與寬版都能完成相同任務。長標題、錯誤訊息、翻譯與放大文字可自然增加高度 |
| 表單與資料 | 定義無資料、篩選無結果、載入、儲存、可重試錯誤，以及重試時應保留的輸入 | 用鍵盤重現失敗並恢復。核對焦點、錯誤說明、已輸入資料與儲存後的真實狀態 |
| 媒體、動態與 3D | 寫明動態揭示了什麼資訊、使用者如何控制、減少動態時如何表達相同關係 | 用觸控與鍵盤完成同一操作。關閉動態或讓媒體載入失敗時仍能讀到主要內容 |
| 瀏覽器能力 | 先用具體英文動作查 Google 指引，再對照專案目標瀏覽器、功能偵測與備援 | 例如在實際頁面測試對話框開啟、關閉、點選背景及焦點返回。記錄測到的引擎與未涵蓋的範圍 |

交付時，把主要決定寫成一句可以驗證的話。例如「手機版把來源放在研究摘要下方，訪客讀完主張就能開啟證據」。附上觀察位置、實際檢查方式，以及仍需實機、資料或帳號才能確認的部分。 [驗收指引](acceptance.md) · [完整來源](sources.md)
