# 夜間架構整理報告（night/refactor）

- 起點：`night/ux` @ 5654320（本機與 `fork/night/ux` 相同，最新 commit 含 `NIGHT_UX_REPORT.md`）
- 執行時間：2026-10-26 06:00 – 06:10（CST）
- Worktree：`/Users/Sofia/Documents/GitHub/Slacker-ios-summer-camp-night-refactor`
- 原則：只搬移、不改寫。程式內容逐字保留，只把 `private` 放寬成 internal，讓搬到其他檔案的程式還能存取。
- Xcode 專案用的是資料夾同步群組（`PBXFileSystemSynchronizedRootGroup`），`group/` 底下新增的檔案會自動編進 `group` target，`project.pbxproj` 不用改。`Package.swift` 沒有列出這次動到的檔案。

## 各步驟

### 1. 把 GroupDetailView 底部的子 View 搬到獨立檔案 — `d0cddd1`
同一個資料夾（`group/Features/Groups/GroupDetail/`）：
| 檔案 | 內容 | 行數 |
|---|---|---|
| `GroupDetailView.swift` | 主畫面 | 2,406 → 1,955 |
| `GroupDetailEditorSheets.swift`（新增） | `DeadlineEditorSheet`、`GroupNameEditorSheet` | 53 |
| `ProjectOutcomeMemes.swift`（新增） | `ExplosionMemeOverlay`、`FailureMemeImage`、`SuccessMemeOverlay`、`SuccessMemeImage`、`MemeCaption` | 328 |
| `PokeButtonFeedback.swift`（新增） | `PokeButtonFeedback` | 74 |

- 只把 `private struct` 改成 `struct`。先確認過整個專案沒有同名型別。
- `CountdownTimeComponents`、`GroupDeadlineSchedule`、`GroupDetailPreview` 只有主畫面用到，留在原檔。
- UX 任務在這個檔案改的部分（聊天未讀圓點、退出群組選單、`TaskEditorSheet` transition）都在主畫面裡，這次沒有動到。

### 2. 把 AppStore 的聊天室同步搬到 `AppStore+Chat.swift` — `e69ec0a`
| 檔案 | 行數 |
|---|---|
| `group/Store/AppStore.swift` | 2,694 → 2,238 |
| `group/Store/AppStore+Chat.swift`（新增，`extension AppStore`） | 463 |

- 原本從 `chatItems(for:)` 到 `normalizedChatDisplayName` 的整段（訊息、在線狀態、heartbeat、已讀、釘選、未讀判斷）照順序原封不動搬過去。
- 為了讓另一個檔案能存取，以下成員從 `private` 放寬成 internal，語意不變：
  - 屬性：`chatMessageListeners`、`chatPresenceListeners`、`chatReadListeners`、`chatPinListeners`、`chatHeartbeatTasks`、`chatRepository`、`lastMarkedChatMessageIDByGroupID`、`lastSeenChatDateByGroupID`
  - `chatSenderIDsByGroupID`：`private(set)` 改成 `var`，因為 extension 在另一個檔案裡會寫入它
  - 方法：`saveChatItems()`、`cloudGroupDocumentID(for:)`（兩個都留在 `AppStore.swift`）、`normalizedChatDisplayName(_:)`（`AppStore.swift` 裡的資料載入流程也會呼叫）
- `applyChatMessages`、`applyChatPresence`、`startChatHeartbeat` 只在 extension 內使用，維持 `private`。
- 狀態仍然只存在 `AppStore` 裡，沒有新增子 Store，資料來源還是只有一個。extension 會沿用類別的 `@MainActor`。
- UX 任務新增的 `markChatSeen`、`beginTrackingUnreadChat`、`hasUnreadChat` 只有跟著搬過去，內容沒改。

### 3. 移除 `typealias GroupBombModel = AppStore` — `7776525`
- 18 個 View 檔把 `GroupBombModel` 換成 `AppStore`，並刪除 `AppStore.swift` 結尾的別名。這是純粹的名稱替換，共 18 個檔案、+32/−35 行。

### 4. 刪除沒有用到的 `MockServices.swift` — `ff996d7`
- 整個 repo 找不到任何 `MockServices` 的引用，所以直接刪除這個檔案。
- 它原本用到的兩個字串（「成果檔案已暫存」、「AI 分析報告準備中」）還留在兩份 `Localizable.strings` 裡，沒有其他地方使用。這次沒有刪，以免動到 swift test 會處理的資源，之後可以順手清掉。

## 建置結果
開工前先建置起點一次，之後每次 commit 之前都在 worktree 根目錄執行下面的指令。5 次都是 exit 0、`** BUILD SUCCEEDED **`：
`xcodebuild -project group.xcodeproj -scheme group -destination 'generic/platform=iOS Simulator' build`

`swift test` 沒有跑：這次改的檔案都不在 `Package.swift` 的 `sources` 清單裡（`Localizable.strings` 也沒改）。UX 報告也提到本機跑 swift test 會遇到 codesign 環境問題。

## 放棄的步驟
- 沒有。我刻意只做了上面四個風險最低的步驟。

## 未驗證之處
- **沒有做畫面驗證**：本機沒有 serve-sim，依規定也沒有開瀏覽器或模擬器截圖。這次只搬移程式碼、沒有改內容，理論上畫面和行為都不會變，但沒有實際確認過。
- 沒有單元測試涵蓋這次動到的 View 和 AppStore 聊天室程式碼。能證明正確的只有編譯通過。

## 建議之後再做
- **AppStore 繼續拆檔**：依同樣的 `extension AppStore` 做法，可以再拆出互評（peer review 監聽與摘要）、戳人、附件、Widget 快照/補送等區塊。Widget 補送與子任務排隊是今晚修 bug、改 UX 動過的地方，建議等那兩個分支 merge、穩定之後再搬。
- **GroupDetailView 主體**：還剩 1,955 行、約 50 個 `@State`。下一步可以把頂部欄、倒數卡片、編輯選單 overlay 拆成子 View，但這牽涉到狀態傳遞（Binding），風險比搬移高，需要畫面驗證。
- 把 `MemberPhotoAvatar`、`SmartAgendaCollectionStore` 裡直接呼叫 Firebase 的程式移進 Repository。
- 收斂 demo/live 的分支判斷。
- `PokeDeliveryState.shared` 和 `AppStore` 各存了一份戳人設定狀態，應該合併成單一來源。
- 清掉 `Localizable.strings` 裡 `MockServices` 遺留的兩個字串。
