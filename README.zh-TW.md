# Praxis Design System Skill

[English](README.md) · [完整來源](skills/praxis-design-system/references/sources.md)

Praxis 讓 Codex 從需求、品牌和現有素材選出設計方向，再把選擇落到畫面與驗收。可用於新介面、既有網站精修，以及配合專案風格的 HTML/SVG 圖解。

## 安裝

在要使用 Codex 的專案裡執行：

```bash
npx skills add JasonLn0711/praxis-design-system-skill --skill praxis-design-system -a codex
```

在 Codex 輸入 `$praxis-design-system`。想跨專案使用，可在安裝指令加上 `-g`。若已複製這個 repo，也可以把[整個技能資料夾](skills/praxis-design-system/)放進專案的 `.agents/skills/`。

## 可以怎麼問

- **雙語研究網站**：「用 `$praxis-design-system` 比較兩種雙語研究網站的設計方向，並說明手機版如何讓讀者找到證據。」
- **既有儀表板**：「用 `$praxis-design-system` 改善表格密度和鍵盤操作，沿用現有設計 token，並在瀏覽器驗收。」
- **審核流程**：「用 `$praxis-design-system` 做一張 HTML/SVG 泳道圖，讓讀者能指出每次交接由誰接手。」

## 查詢設計資料

離線索引收錄 **34 個資料集、5,227 筆紀錄**，可查產品選型、字體與配色、構圖、動態、無障礙、瀏覽器指引，以及 **52 種圖解**的規格和範例。

若要直接查詢，在 repo 根目錄用 Python 3 執行：

```bash
python3 skills/praxis-design-system/scripts/shortlist.py museum-gallery --mode light --low-cost
python3 skills/praxis-design-system/scripts/catalog.py --show diagrams/swimlane
```

[繁體中文選型與實作指南](skills/praxis-design-system/references/practice.zh-TW.md) · [完整來源與查詢指令](skills/praxis-design-system/references/sources.md)

## 授權

Praxis 原創內容採用 [MIT 授權](LICENSE)。各上游資料沿用原始授權與署名。 [第三方授權及署名](THIRD_PARTY_NOTICES.md)
