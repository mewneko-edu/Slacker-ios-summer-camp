# Oops! Bomb 視覺手冊

目的：讓之後每次改動都有同一份規則可依循，不必重新猜數值。
狀態日期：2026-10-24。對應分支 `fix/agenda-dynamic-type`。

這份手冊分兩種內容，請務必區分：

- **規則** —— 已經成立、照著做就好。
- **提案** —— 需要你看過畫面裁決，**尚未套用**。文中以「提案」明確標示。

風格大方向不變：黃黑美式復古、奶油紙色卡面、粗黑外框、圓角漫畫風。手冊的目的是
收斂「同一件事有幾種寫法」，不是換風格。

---

## 1. 色彩

唯一來源是 `BombTheme`（`group/Shared/UI/Theme.swift`）。不要在畫面裡寫
`Color(red:green:blue:)`。

| Token | 值 | 用途 |
|---|---|---|
| `BombTheme.yellow` | `1, 0.79, 0.05` | 主色；標題列、強調底、主要按鈕底 |
| `BombTheme.ink` | `0.08, 0.08, 0.07` | 文字、外框、深色底 |
| `BombTheme.paper` | `0.96, 0.92, 0.79` | 卡片底（奶油紙色） |
| `BombTheme.secondaryText` | `0.35, 0.34, 0.30` | 次要文字、說明、goal |
| `BombTheme.red` | `#C43D32` | 錯誤、危險操作、逾期 |
| `BombTheme.green` | `0.16, 0.55, 0.32` | 完成、成功 |

**規則**

- 深色底上的文字用 `.white`；卡片底上的文字用 `BombTheme.ink`。
- 次要文字一律 `BombTheme.secondaryText`，不要用 `.gray` 或系統語意灰 ——
  系統灰壓在奶油紙色上會顯得褪色。
- App 鎖定淺色模式（`GroupBombApp.swift` 的 `.preferredColorScheme(.light)`）。
  這是品牌取捨，不建議做深色模式。

**已知待處理**：正式碼有 62 處直接寫 `.white`。鎖定淺色模式下不會出錯，但沒有
單一出口。若將來要調整，應先收斂成一個語意 token。

`SmartAgendaStyle`（`group/Features/Groups/SmartAgendaStyle.swift`）是另一組色票，
**這是刻意的**：它只被 `SmartAgendaPreview.swift` 使用，而那整份檔案包在 `#if DEBUG`
裡、只有帶 `-preview-smart-agenda` 旗標才會啟動，用途是對照設計稿。
不要把它併進 `BombTheme`，也不要拿它的數值推論正式畫面。

---

## 2. 圓角

唯一來源是 `BombRadius`。**不要再寫裸數字。**

| Token | 值 | 用途 |
|---|---|---|
| `.overlay` | 28 | 覆蓋全畫面的浮動面板：表單 Sheet、Poke 覆蓋層 |
| `.dialog` | 24 | 對話框 |
| `.card` | 22 | 主要內容卡：群組卡、新手教學卡 |
| `.panel` | 18 | 區塊卡，即 `comicCard()` |
| `.field` | 15 | 輸入欄位 |
| `.chip` | 10 | 卡片內小區塊、標籤 |
| `.badge` | 8 | 進度徽章一類小底板 |
| `.thumbnail` | 6 | 縮圖 |

這八個 token 記錄的是**目前實際在用的數值**，不是理想尺度。八階太多，而且
「浮動面板」這一個角色就同時存在 28／24／22 三種值。

### 提案：收斂成五階

`overlay 28` / `card 22` / `panel 18` / `control 14` / `inner 8`

需要的實際位移（全部 ≤2pt）：

| 位置 | 現值 | 提案 | 差 |
|---|---|---|---|
| `BombDialog` 對話框 | 24 | 22 | −2 |
| `BombFormSheet` 欄位 | 15 | 14 | −1 |
| `AttachmentSummaryRow` 小區塊 | 10 | 8 | −2 |
| `AttachmentSummaryRow` 縮圖 | 6 | 8 | +2 |

功能頁另有約 190 處裸數字待收斂，分佈：`14`×39、`22`×35、`16`×26、`24`×17、
`18`×16、`20`×14、`12`×13，以及 `30`/`17`/`15`/`11`/`9`/`6`/`4` 等零星值。
其中 `16`（26 處）和 `20`（14 處）**往上或往下都說得通，需要你決定**，
其餘可機械對應到最近一階。

未套用的原因：這會動到實際外觀，而這一輪沒有截圖比對的條件。

---

## 3. 外框粗細

唯一來源是 `BombBorder`。

| Token | 值 | 用途 |
|---|---|---|
| `.card` | 3 | 卡片、對話框、浮動面板主外框 |
| `.inner` | 2 | 卡片內部元素、膠囊按鈕 |
| `.emphasis` | 4 | 新手教學強調外框 |
| `.hairline` | 1 | 極淡分隔描邊 |

**規則**：粗細代表層級，不是裝飾。外層 3、內層 2，不要出現 1.25／1.3／1.8／2.5／2.8
這類中間值（目前正式碼仍有少量，屬待收斂）。

---

## 4. 陰影

專案同時存在**兩種陰影語言**，這是目前最明顯的風格混用：

| 語言 | 寫法 | 使用處 |
|---|---|---|
| 硬陰影（漫畫風） | `radius: 0, x: 5, y: 5` | `comicCard()`、個人／團隊戰報卡、賽後檢討、登入品牌區 |
| 硬陰影（較重） | `radius: 0, x: 6, y: 6` | 群組詳情某張卡、新手教學卡 |
| 柔陰影（現代風） | `radius: 14, y: 4` | 發布任務、修改任務、Agents |
| 柔陰影（其他） | `radius: 6, y: 3` / `radius: 18, y: 10` | 聊天室、Poke 覆蓋層 |

**規則（可直接遵循的部分）**

- 陰影代表**可互動／浮起**，不是每張卡都要有。區塊內的次級卡片不要加陰影。
- 新增漫畫風卡片時用 `comicCard()`，不要自己拼 `radius: 0` 陰影。

### 提案：二選一

硬陰影統一為 `x: 5, y: 5`（取消 6×6），柔陰影統一為 `radius: 14, y: 4`，
並明確規定：**卡片用硬陰影、Sheet／覆蓋層用柔陰影**。目前 6×6 與
`radius: 6` 兩種屬一次性值，建議收掉。需要你確認後再動。

---

## 5. 字級

**規則**

- 一律使用語意字級：`.title2` / `.headline` / `.subheadline` / `.footnote` / `.caption`，
  搭配 `.weight(.black)` / `.bold` / `.semibold`。
- **不要**用 `.font(.system(size:))` 寫正文。使用者調大系統字級時那些文字不會跟著放大。
- 主要數字讀數（倒數、百分比）用 `@ScaledMetric(relativeTo: .largeTitle)`，
  並加 `.lineLimit(1)` 與 `.minimumScaleFactor(0.6)` 防止溢出。
  範例見 `MyTasksView` 的 `readoutSize`、`SmartAgendaSection` 的 `countdownSize`。
- 標題列用 `BombHeader`，不要自己排。

**絕對尺寸可以保留的情況**（這些不是缺陷）

- SF Symbol 裝飾圖示
- emoji 動畫（💣💥、Poke 特效）
- 由容器尺寸推導的字級，例如 `size * 0.45`、`height * 0.43`
- 固定圖形框內的字，例如頭像縮寫、七段顯示器旁的 `%`
- 徽章數字（未讀數），其可讀性由 `accessibilityValue` 負責

### 固定幾何的外框必須封頂

**規則：把文字包在固定尺寸圖形裡的「外框」，要限制自身的縮放上限；
承載內容的區域永遠不封頂。**

判斷標準是「這個容器會不會跟著文字長大」。不會的就是固定幾何，
例如 `Canvas` 畫的儀表環、鎖住寬度的分頁列膠囊、固定 `frame(height:)`
的卡片。文字無上限放大時，這類容器撐不開，結果就是重疊、遮蔽、擠出畫面。

```swift
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)        // 外框層
.dynamicTypeSize(...DynamicTypeSize.accessibility1)  // 圖表層
```

系統分頁列也是這樣處理的（封頂，改用長按放大的 HUD），**這不等於忽略無障礙** ——
前提是任務卡、清單、說明文字等內容區完全不受影響。

**實作陷阱：`@ScaledMetric` 讀的是「父層傳進來的環境」。** 在某個 View 自己的
`body` 裡加 `.dynamicTypeSize(...)`，**不會**影響那個 View 自己宣告的
`@ScaledMetric`，只會影響它的子層。要封住某個 View 的 `@ScaledMetric`，
修飾子必須加在**呼叫端**。見 `MyTasksView:44` 的 `TaskProgressDashboard`。

實測斷裂點（iPhone 17）：一般字級到 xxxLarge 全部正常，AX1 尚可，
AX2–AX3 開始重疊，AX4–AX5 明顯破版。封頂後 AX5 恢復正常。

### 提案：裝飾圖示是否也跟著縮放

`BombEmptyState` 已經用 `@ScaledMetric` 讓圖示跟著字級縮放，理由是
「避免在大字級下圖示與文字比例失衡」。同樣情境（空狀態卡、placeholder 卡裡
圖示直接壓在會縮放的文字上方）另有 8 處仍是絕對尺寸：
戰報空卡、賽後檢討獎盃、成果提交 placeholder ×2、成果附件圖示、
互評覆蓋層圖示、群組詳情警告／完成圖示。

要不要一併套用同一條規則，等你決定。

---

## 6. 觸控範圍

**規則：任何可點擊元素的命中範圍不得小於 44×44pt。**

視覺尺寸可以小，命中範圍不行。兩個工具：

- `bombHitTarget(_ minimum: CGFloat = 44)` —— 保持視覺尺寸，只把命中範圍撐到 44。
  外層 frame 會讓版面多佔幾點，這是刻意取捨。
- `BombCloseButton(action:)` —— 圓形關閉鈕，視覺 36pt、命中 44pt，
  已內建 `accessibilityLabel`。**不要再手寫 xmark 圓鈕。**

**不需要處理的情況**：純裝飾圖示（狀態圓點、列首圖示、頭像）不是按鈕，不要套。
整列都是按鈕時（例如 `AttachmentActionButton` 包住整個 HStack），列高本身已足夠。

### 提案：梗圖關閉鈕

`GroupDetailView` 的兩個「關閉梗圖」鈕是 40pt／`BombTheme.paper`，與
`BombCloseButton` 的 36pt／`.white` 不同。這一輪只補了命中範圍、沒動外觀，
因為沒辦法確認梗圖覆蓋層的實際畫面。要不要併進同一規格，等你決定。

---

## 7. 間距

目前分佈（正式碼，已排除 DEBUG 檔）：

- `spacing:` —— 12×60、8×46、10×46、0×44、16×33、6×26、4×20、18×20、14×18、
  3×15、2×10、5×10、9×7、7×9、20×8、22×4、24×3、28×1、1×1
- `padding` 數值 —— 16×63、12×55、14×39、8×33、20×33、10×21、18×18、28×18、
  24×12、11×10、9×10、4×10、5×11、13×9、7×6

### 提案：4pt 尺度

收斂成 **4 / 8 / 12 / 16 / 24 / 32**，移除 1、2、3、5、7、9、11、13、18、22 這些
中間值。

**未套用，而且我建議不要在無法截圖比對時做。** 理由：這會動到三百多處、
每一處位移都只有 1–2pt，看不出好壞，但一旦某處其實是刻意微調就會被破壞，
而且沒有任何自動化手段能發現。這項應該配合逐頁截圖進行。

---

## 8. 共用元件：先找有沒有現成的

新畫面要用這些，不要自己拼：

| 元件 | 用途 |
|---|---|
| `comicCard()` | 區塊卡（paper 底、18 圓角、3 粗外框、5×5 硬陰影） |
| `BombHeader` | 固定頂端標題列，含漸層保留版位 |
| `BombHeaderButtonStyle` | 標題列圓形按鈕（44×44） |
| `BombFormSheet` / `BombFormActions` / `bombFormField()` | 表單 |
| `BombFormPrimaryButtonStyle` | 主要操作按鈕 |
| `bombDialog(...)` | 確認／錯誤對話框 |
| `BombEmptyState` | 空狀態 |
| `BombCloseButton` | 圓形關閉鈕 |
| `bombHitTarget()` | 擴大命中範圍 |
| `HazardStripe` | 黃黑警示斜紋 |
| `SevenSegmentDigit` | 倒數七段顯示器 |
| `MemberPhotoAvatar` / `ProfileAvatarImage` | 頭像 |

`comicCard()` 目前只有 28 處使用，而手寫 `RoundedRectangle` 有約 190 處。
新增卡片時請優先用 `comicCard()`。

---

## 9. 空狀態

一律用 `BombEmptyState`，**不要用 `ContentUnavailableView`** —— 系統語意灰壓在
奶油紙色／黃色底上會褪色且不合品牌。圖示已用 `@ScaledMetric` 跟著字級縮放。

---

## 10. 對話框與危險操作

- 用 `bombDialog(...)`，不要用系統 `.alert` / `.confirmationDialog`
  （正式碼目前已無系統 alert，保持下去）。
- `destructiveIsRed` 預設 `true`，刪除類操作會是紅色。不要關掉。
- 按鈕順序：**取消在前、危險操作在後**。共用 HStack 依宣告順序排列。
- 系統照片選擇、分享、權限這類介面保留系統原樣，不要包裝。

---

## 11. 待你裁決的開放問題

按我建議的處理順序：

1. **圓角收斂成五階** —— `16`（26 處）和 `20`（14 處）要往 14／18 還是 18／22？
   其餘可機械對應。我的建議：`16→18`、`20→22`，讓階數更分明。
2. **陰影二選一** —— 硬陰影收成 5×5、柔陰影收成 `radius: 14, y: 4`，
   卡片用硬、Sheet 用柔。我的建議：照此執行，6×6 與 `radius: 6` 收掉。
3. **裝飾圖示是否跟著字級縮放** —— 8 處。我的建議：套用，與 `BombEmptyState` 一致。
4. **梗圖關閉鈕是否併入 `BombCloseButton`** —— 需要先看畫面。
5. **間距 4pt 尺度** —— 我的建議：單獨一支分支、配截圖做，不要順手改。
6. **`MissionBoardView` 是死碼** —— 全專案無任何引用，內含寫死的 `"48:16:09"`。
   要刪還是要接上？
7. **62 處 `.white` 是否收成語意 token** —— 鎖定淺色模式下不急。
8. **AX4–AX5 仍有兩處內容層的粗糙** —— 封頂解決了外框崩壞，但這兩個是內容、
   本來就該完整縮放，所以沒有一併封頂：
   - 待完成／已完成 切換器文字折行成「待 完成」
   - 任務卡標題截斷成 `[... Fi`
   兩者都仍可讀可點，不影響操作。真要處理的話方向是大字級時改為縱向排列
   （`AnyLayout`，`SmartAgendaSection` 已有同樣寫法可參考），而不是封頂。

---

## 12. 本輪已套用 / 刻意未套用

**已套用**（四個 commit，皆通過 Debug build）

- `a373fcd` 圓形關閉鈕統一成 `BombCloseButton`（10 處手寫收成 1 個元件），
  並補齊 44pt 命中範圍：成果鉛筆／加號、取消置頂、聊天室輸入列切換。
- `cde004a` 會議倒數與我的任務百分比改用 `@ScaledMetric`，恢復 Dynamic Type。
- `648ee97` 建立 `BombRadius` / `BombBorder`，共用層改為引用 token（數值未變）。
- `c2be1db` 分頁列與進度儀表在輔助使用字級下封頂，修正 AX2 以上的破版。

**模擬器驗證**（iPhone 17 / iOS 27.0，非僅 build 通過）

- `BombCloseButton` 外觀與改動前一致。
- 44pt 命中範圍實測有效：點在距圓心 20pt（視覺圓圈外、面板內）仍觸發關閉。
- `ExplosionMemeOverlay` 的 40pt 關閉鈕外觀完好。
- Dynamic Type 以改動前的 build 做了對照，確認 AX 破版多數屬既有問題。
- 封頂後 AX5 的分頁列與儀表恢復正常。
- **未驗證**：會議倒數（需組長開始會議才會出現），寫法與儀表相同但不宣稱已驗。

**刻意未套用**

- 所有會動到實際外觀、而這一輪無法截圖驗證的改動：圓角收斂、陰影收斂、
  間距尺度、梗圖關閉鈕外觀。
- `SmartAgendaStyle`：DEBUG 專用對照稿，不應併入主題。

**先前文件的更正**：`UI_UX_REVIEW_2026-09-27.md` 第 4 點（議程使用 Arial
`fixedSize`、不跟隨系統字級）**已經不成立** —— 正式的 `SmartAgendaSection.swift`
全程使用 `BombTheme` 與語意字級，Arial 與 `fixedSize:` 各 0 處。那份描述指的是
DEBUG 預覽檔。
