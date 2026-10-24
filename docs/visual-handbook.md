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

**五階，不要新增階級。**

| Token | 值 | 用途 | 由哪些舊值收斂而來 |
|---|---|---|---|
| `.overlay` | 28 | 覆蓋全畫面的浮動面板：表單 Sheet、Poke 覆蓋層 | 28、30 |
| `.card` | 22 | 主要內容卡與對話框 | 20、22、24 |
| `.panel` | 18 | 區塊卡，即 `comicCard()` | 16、17、18 |
| `.control` | 14 | 輸入欄位、按鈕、列內控制項 | 12、14、15 |
| `.inner` | 8 | 卡片內小區塊、標籤、縮圖、徽章底板 | 6、8、9、10、11 |

收斂前散落 17 種圓角，同一個角色常有兩三種值並存。合併時每一處位移
都 ≤3pt、絕大多數 ≤2pt —— 肉眼不可辨，但往後只剩五個選擇。階與階
之間刻意拉開，讓「這是哪一層」在程式碼裡就讀得出來。

`16→18`、`20→22` 是往上收的決定，為的是讓階數更分明。

**PDF 匯出的繪圖碼不套這組 token。** 個人與團隊戰報用 `UIBezierPath`
畫進 PDF，那是另一種媒介，與畫面上的層級無關。

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

**陰影＝浮起的高度，不是裝飾。** 沒有浮起語意的表面不加 —— 區塊內的
次級卡片就不該有。四個具名修飾子，不要再手寫 `.shadow(...)`：

| 修飾子 | 值 | 用途 |
|---|---|---|
| `bombCardShadow()` | `radius: 0, x: 5, y: 5` | 卡片。漫畫風實心偏移，`comicCard()` 已內含 |
| `bombControlShadow()` | `radius: 6, y: 3` | 小型浮動控制項，如聊天室的回到底部圓鈕 |
| `bombPanelShadow()` | `radius: 14, y: 4` | 表單 Sheet 與行內浮動面板 |
| `bombModalShadow()` | `radius: 18, y: 10` | 蓋住整個畫面的 modal |

硬陰影已統一成一個值（原本的 6×6 併入 5×5，−1pt 看不出來）。

### 更正：柔陰影**不該**收成單一值

手冊初版提過「柔陰影統一為 `radius: 14, y: 4`」。讀過呼叫端之後這個提案
作廢：**模糊半徑必須隨元件尺寸走**。聊天室那顆是 44pt 圓鈕、Poke 是 340pt
寬的 modal，同一個半徑不是把按鈕糊成一團，就是讓 modal 看不出浮起。

三個柔陰影是三種刻意的高度，不是三個漏網之魚。

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

### 裝飾圖示也跟著縮放

壓在會縮放文字上方的圖示（空狀態卡、placeholder 卡）要一起縮放，否則
大字級下比例會失衡。**優先用語意字級而不是 `@ScaledMetric`** ——
SF Symbol 吃語意字級就會自動跟著 Dynamic Type，而且剛好等值：
`34pt = .largeTitle`、`28pt = .title`。只有找不到對應階級時（例如 42pt）
才宣告 `@ScaledMetric`。

例外：新手教學的指示箭頭維持固定尺寸。它指向一個量測出來的座標，
放大會讓箭尖偏離所指的目標。

### 內容層不封頂，要改的是版面

封頂只適用於固定幾何的外框。**內容本來就該完整縮放**，擠不下時正解是
改排列方式：

- 並排的選項塞不下 → 大字級時改縱向（`AnyLayout`），每項獨佔整個寬度。
- 標題被旁邊的固定寬元素擠扁 → 讓標題獨佔一列，其餘退到下一列。

**單純放寬 `lineLimit` 不夠，而且可能更糟。** 任務卡試過這條路：標題
只分到一條縫，允許換行之後變成一個字一行直向堆疊，比截斷還難讀。
寬度不足時要改的是結構，不是行數上限。

---

## 6. 觸控範圍

**規則：任何可點擊元素的命中範圍不得小於 44×44pt。**

視覺尺寸可以小，命中範圍不行。兩個工具：

- `bombHitTarget(_ minimum: CGFloat = 44)` —— 保持視覺尺寸，只把命中範圍撐到 44。
  外層 frame 會讓版面多佔幾點，這是刻意取捨。
- `BombCloseButton(action:)` —— 圓形關閉鈕，視覺 36pt、命中 44pt，
  已內建 `accessibilityLabel`。**不要再手寫 xmark 圓鈕。** 全專案原本
  有 10 處各自手寫，三個軸（尺寸、構造、前景色）都不一致。

**不需要處理的情況**：純裝飾圖示（狀態圓點、列首圖示、頭像）不是按鈕，不要套。
整列都是按鈕時（例如 `AttachmentActionButton` 包住整個 HStack），列高本身已足夠。

**`BombCloseButton` 的圓圈用 `@ScaledMetric` 跟著符號一起縮放。**
初版把圓圈寫死 36pt、符號用 `.headline`，結果 AX5 下叉號撐出圓外 ——
正是這份手冊要防的固定幾何問題，而且就犯在共用元件本身。寫共用元件時
特別容易漏掉自己定的規則。

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

原本的八項已全數處理完畢（見下一節）。剩下兩項：

1. **間距 4pt 尺度** —— 目前 `spacing:` 用了 19 種值、`padding` 用了 28 種。
   建議收斂成 4／8／12／16／24／32，但**不要順手改**：三百多處、每處位移
   只有 1–2pt，看不出好壞，而只要有一處其實是刻意微調就會被破壞，且沒有
   任何自動化手段能發現。適合單獨一支分支、逐頁截圖比對。
2. **62 處 `.white` 是否收成語意 token** —— 鎖定淺色模式下不會出錯，不急。
   將來若要做深色模式，這是第一個要處理的。

### 已刪除：舊任務看板與特工頁

`MissionBoardView`（184 行）全專案零引用，`AgentsView`（312 行）只能從
它的 toolbar 進入，兩者都是使用者到不了的畫面。它們是已上線功能的原型：
任務看板的檔頭寫著「等著變成 GroupDetailView」，而那早就做完了；特工頁
原型的戳人流程，現在由 `MemberProgressCard` ＋ `PokeRepository` ＋
`PokeNotificationService` ＋ `PokeReceptionOverlay` 真正實作。

連同背後的 `MissionTask`、`Agent`、`tasks`／`agents`／`radar` 屬性與
`claim`／`shield`／`poke(agentID:)`，共移除約 600 行。

**刪除的真正理由不是行數，是三組會被誤用的同名 API**：`model.tasks`
（舊）對 `model.projectTasks`（正式）、`poke(agentID:style:)` 對
`poke(memberID:in:style:)`（overload，打錯會編譯成功）、`Agent` 對
`Member`。死碼不會害人，會被誤用的死 API 會。

---

## 12. 本輪已套用 / 刻意未套用

分支 `fix/agenda-dynamic-type`，每個 commit 都通過 Debug build。

| Commit | 內容 |
|---|---|
| `a373fcd` | 圓形關閉鈕統一成 `BombCloseButton`（10 處手寫 → 1 個元件），補齊 44pt 命中範圍 |
| `cde004a` | 會議倒數與我的任務百分比改用 `@ScaledMetric` |
| `648ee97` | 建立 `BombRadius` / `BombBorder` |
| `c2be1db` | 分頁列與進度儀表在輔助使用字級下封頂 |
| `a7fa3c3` | 圓角收斂成五階（17 種 → 5 種，每處位移 ≤3pt） |
| `9c631a1` | 標題字體統一（51 處加 `design: .rounded`，排除 14 處圖示） |
| `e5f8934` | 陰影改為四個具名修飾子，硬陰影統一 |
| `e12fdee` | 裝飾圖示改語意字級；梗圖關閉鈕併入共用元件 |
| `555dde9` | 任務頁在輔助使用字級下改版面；修正 `BombCloseButton` 的縮放 bug |

**模擬器驗證**（iPhone 17 / iOS 27.0，非僅 build 通過）

- 44pt 命中範圍實測有效：點在距圓心 20pt（視覺圓圈外、面板內）仍觸發關閉。
- Dynamic Type 以**改動前的 build 做了對照**，確認 AX 破版多數屬既有問題。
- 圓角收斂後，表單 Sheet、群組卡、徽章、進度條外觀無變化。
- 字體統一後，設定頁的「Sofia」轉為圓體、中文標題不變 —— 證實 SF Rounded
  只涵蓋拉丁與數字，中文落到 PingFang（無圓體變體）。
- 封頂後 AX5 的分頁列與儀表恢復正常；切換器與任務卡標題在 AX5 下可讀。
- 預設字級逐頁確認無回歸。

**未驗證**：會議倒數（需組長開始會議才會出現），寫法與儀表相同但不宣稱已驗。

**刻意未套用**：間距尺度（理由見上一節）、`SmartAgendaStyle`（DEBUG 專用
對照稿，不應併入主題）。

**先前文件的更正**：`UI_UX_REVIEW_2026-09-27.md` 第 4 點（議程使用 Arial
`fixedSize`、不跟隨系統字級）**已經不成立** —— 正式的 `SmartAgendaSection.swift`
全程使用 `BombTheme` 與語意字級，Arial 與 `fixedSize:` 各 0 處。那份描述指的是
DEBUG 預覽檔。
