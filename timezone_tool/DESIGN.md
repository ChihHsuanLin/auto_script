# 時區工具設計紀錄（Timezone Board）

## 目標

提供可部署於 GitHub Pages 的手機友善靜態網頁，用於：

1. 即時顯示各辦公室當地時間（含夏令／標準時間標註）
2. 選擇「我目前所在辦公室」後，對全球常用城市做相對分析：
   - **D+1**：該地日曆日比「我」晚一天
   - **D-1**：該地日曆日比「我」早一天
   - **03:00–04:00**：該地本地時間落在 `[03:00, 04:00)`

## 語言約定

| 文件／產物 | 語言 |
|------------|------|
| 本設計紀錄 `DESIGN.md` | 中文 |
| 網頁 UI | 英文 |
| `README.md`（給使用者） | 英文 |

## 技術

- 路徑：`timezone_tool/`
- 靜態：`index.html` + `style.css` + `app.js`（無 build）
- 時區：瀏覽器 IANA + `Intl.DateTimeFormat`
- 更新：每秒刷新

## 辦公室（主看板）

| 代碼 | 顯示名稱 | IANA |
|------|----------|------|
| TW | Taiwan | `Asia/Taipei` |
| GDL | Guadalajara | `America/Mexico_City` |
| HOU | Houston | `America/Chicago` |
| SJ / LA | San Jose / Los Angeles | `America/Los_Angeles` |

- SJ 與 LA 合併為一列，並標註 same zone。
- 選擇器四選一；若瀏覽器時區對得上某辦公室 IANA 則自動選取，否則預設 TW。
- 選中的辦公室卡片高亮。

## 世界常用城市（相對分析）

| 顯示名稱 | IANA |
|----------|------|
| UTC | `Etc/UTC` |
| London | `Europe/London` |
| Paris | `Europe/Paris` |
| Berlin | `Europe/Berlin` |
| Dubai | `Asia/Dubai` |
| Mumbai | `Asia/Kolkata` |
| Singapore | `Asia/Singapore` |
| Hong Kong | `Asia/Hong_Kong` |
| Tokyo | `Asia/Tokyo` |
| Seoul | `Asia/Seoul` |
| Sydney | `Australia/Sydney` |
| Auckland | `Pacific/Auckland` |
| Sao Paulo | `America/Sao_Paulo` |
| New York | `America/New_York` |
| Chicago | `America/Chicago` |
| Denver | `America/Denver` |
| Vancouver | `America/Vancouver` |
| Mexico City | `America/Mexico_City` |
| Taipei | `Asia/Taipei` |
| Los Angeles | `America/Los_Angeles` |

相對分析可比對到與辦公室重疊的城市（例如 Taipei），以便在美洲看出亞太 D+1。

## 時間顯示格式

```
2026-11-14 (Sat) 10:50:32
```

- 英文星期縮寫
- 含秒
- 另顯示 UTC offset（如 `UTC+8`、`UTC-7`）與 DST 標籤

## DST 標籤規則

對某 IANA 時區：

1. 取當年 1 月與 7 月中旬的 UTC offset（分鐘）
2. 若兩者相同 → 該區無夏令 → 標 **No DST**
3. 若不同：
   - 「夏令」一側定義為 offset 較大（對 UTC 較東／較正）者（DST 通常比標準時間多 1 小時）
   - 當下 offset 等於夏令一側 → **DST**
   - 否則 → **Standard**

此規則同時適用北半球與南半球（如 Sydney）。

## 相對分析規則

以「我」所選辦公室的本地 `yyyy-MM-dd` 為基準：

| 區塊 | 條件 |
|------|------|
| D+1 | 城市本地日期 = 我的日期 + 1 天 |
| D-1 | 城市本地日期 = 我的日期 − 1 天 |
| 03:00–04:00 | 城市本地小時 `h` 滿足 `3 <= h < 4` |

排除規則：

- D±1：排除與「我」**相同 IANA** 的城市（避免自己出現在列表）
- 03:00–04:00：列出所有符合的世界城市（含與「我」同區者，若剛好落在該時段）

無結果時顯示：`None right now`

跨月／跨年：以本地日期字串換算為 UTC 正午再加減一天後比較，避免字串拼接錯誤。

## 版面（手機優先）

1. Header + 更新提示
2. Where am I（TW / GDL / HOU / SJ-LA 大按鈕）
3. Office times（卡片列表）
4. Relative analysis
   - D+1
   - D-1
   - Currently 03:00–04:00

寬螢幕可將辦公室卡片橫向排列；分析區維持清楚區塊。

## GitHub Pages

建議將 Pages source 設為倉庫根目錄，網址路徑為：

```
https://<user>.github.io/<repo>/timezone_tool/
```

或將 Pages 根目錄指到 `/timezone_tool`（若平台支援）。

本地預覽：以靜態伺服器開啟本資料夾，或直接開啟 `index.html`（部分瀏覽器對 `file://` 無特殊限制，本工具不依賴模組載入）。
