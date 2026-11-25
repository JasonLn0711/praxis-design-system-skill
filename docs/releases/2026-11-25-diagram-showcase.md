# 2026-11-25｜Praxis 圖解與圖示發布回執

圖庫讓評估 Praxis 的讀者快速辨認適用的圖型，再點開原圖查看資料如何轉成圖形。Jason 提出八種較少見的例圖，並指定 README 以讀者需要的資訊為主。Praxis 保存原創 SVG、中英文入口和驗收證據。 [繁體中文圖庫](../../README.zh-TW.md#圖解範例) · [English showcase](../../README.md#diagram-showcase) · [圖解選型指引](../../skills/praxis-design-system/references/design-decisions.md#diagrams)

## 初版圖庫

| 原圖 | 讀者可核對的內容 |
| --- | --- |
| [感測器軸測爆炸圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/exploded-sensor.svg) | 四層組件沿同一軸對齊，讀者可循組裝順序理解裝置。 |
| [博物館服務藍圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/service-blueprint-museum.svg) | 訪客、前台、後台和支援角色對齊四個階段。可見線標出訪客看得到的工作範圍。 |
| [維修咖啡館桑基圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/sankey-repair-cafe.svg) | 100 件物品分到 48 件修好、27 件待零件、17 件轉介及 8 件回收。流帶寬度與件數成正比。 |
| [典藏平台 Wardley 地圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/wardley-archive.svg) | 沿使用者可見性和供應成熟度排列能力，指出可自建與可沿用的部分。 |
| [雙語文章事件建模圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/event-modeling-publishing.svg) | 把送審、核准及發布分成三階段，逐一連結命令、事件和讀取介面。 |
| [電子展覽需求追溯圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/traceability-accessibility.svg) | 字幕和鍵盤操作有測試入口，逐字稿清楚標為缺少驗證。 |
| [巡迴展排程網路圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/schedule-touring-exhibit.svg) | 關鍵路徑 A → B → D → F 為 10 天，標籤作業鏈有 3 天餘裕。 |
| [圖書館入館極座標圖](https://github.com/JasonLn0711/praxis-design-system-skill/blob/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5/docs/examples/polar-library.svg) | 六個連續四小時窗口共用線性半徑，12:00–16:00 的 112 人次為尖峰。 |

## 發布與驗收

- [圖庫提交 `a7b5ee5`](https://github.com/JasonLn0711/praxis-design-system-skill/commit/a7b5ee5643036c8d4e33cc6ef9b99be70d6545c5) 已推送至公開 `main`。兩份 README 和八份 SVG 的匿名讀取均回應 HTTP 200，位元組與提交內容一致。
- GitHub Markdown 渲染保留兩個語言版本的八張圖及原圖連結。Chromium 預覽中，375px 呈單欄、860px 呈雙欄，兩個寬度均載入八張圖。原尺寸文字的邊界與重疊檢查通過。
- 12 份上游來源快照完整性檢查及 6 項 Skill 測試通過。原圖使用示意情境，圖內標示使用英文，README 各有對應語言的替代文字。 [來源與查詢路徑](../../skills/praxis-design-system/references/sources.md)

## 圖示集

16 個可重用 SVG 隨 Skill 提供，涵蓋導覽、操作、狀態回饋與設計。雙語圖示頁可逐一開啟原檔，也連到 Praxis 品牌圖示與既有雲端、IT 圖示。 [雙語圖示集](../icons.md)

- [圖示提交 `97d39ad`](https://github.com/JasonLn0711/praxis-design-system-skill/commit/97d39ad7dc6820ad912ece35e88ea49531d73c3f) 的雙語入口、技能檔案、SVG 與徽章共 28 檔匿名回讀相符。
- GitHub Markdown 渲染保留 16 個有雙語標籤的預覽連結。以渲染結果做 Chromium 預覽，375px 與 860px 的明暗版均完整載入。從公開 GitHub 安裝到乾淨的 Codex 專案後，17 個 SVG（含品牌圖示）與技能的兩個入口檔案皆與原始檔相符。 [GitHub Actions](https://github.com/JasonLn0711/praxis-design-system-skill/actions/runs/45548717273)

## 重用與下一關

首次重用時，從實際讀者要回答的問題選定圖型，換上可發布的專案資料，再請讀者解讀一個關係或數值。已有編輯索引的專案可對照 CS Kairos 主站的閱讀入口與證據定位；主站的設計與發布由網站 repo 管理。 [主站雙語索引設計](https://github.com/JasonLn0711/JasonLn0711.github.io/blob/af00179da03a2bcea06d2683c346c5d6eeda3d2b/docs/site-v3-editorial-index.zh-tw.md) · [主站發布回執](https://github.com/JasonLn0711/JasonLn0711.github.io/blob/e48d910425b7b16cbe363d501884579dd982e3b6/docs/releases/2026-11-25-editorial-index.md)
