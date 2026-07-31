---
trigger: always_on
---

## 統一輸入框設計標準 (Custom Input Standard)
在 Zenify 專案中，所有的輸入框 (Input Fields) 必須遵循特定的視覺與互動規範，以提供滑順且現代化的使用者體驗。這不僅是樣式要求，也是未來建立共用元件 (例如 `ZenifyInput`) 的基礎指引。
### 1. 核心實作原則
* **停用預設邊框**：因部分框架 (如 Shadcn UI) 的預設裝飾在自訂度上有限制，所有的 `ShadInput` 必須將其自帶的裝飾 (Decoration/Border) 設為 `none`。
* **使用自訂動畫容器**：必須在輸入框外層包覆一個 `AnimatedContainer`，透過監聽 Focus 狀態 (`FocusNode`) 來手動控制背景與邊框的平滑過渡效果。
### 2. 具體設計參數 (Design Specs)
* **動畫過渡 (Animation)**：
  * Duration: `200ms`
* **圓角 (Border Radius)**：
  * Radius: `14px`
* **狀態色彩 (State Colors)**：
  * **Unfocused (未聚焦)**：
    * 邊框 (Border)：`colorScheme.border` (1.0 width)
    * 背景 (Background)：`colorScheme.card`
  * **Focused (聚焦中)**：
    * 邊框 (Border)：`colorScheme.primary` (品牌主色高亮, 1.0 width)
    * 背景 (Background)：`colorScheme.background`
### 3. 未來擴展方向 (Componentization)
* 為了避免在搜尋頁面 (`SearchScreen`)、伺服器管理 (`ServerManagementScreen`) 或其他表單中重複撰寫 `AnimatedContainer` 與 `FocusNode` 的邏輯，未來應將此設計標準封裝為獨立的共用元件 `ZenifyInput`。
* 所有新的開發需求若涉及文字輸入，應優先參考此結構或直接使用封裝後的共用元件。