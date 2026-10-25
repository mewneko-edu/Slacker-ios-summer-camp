# 夜間 UX 改善報告（night/ux）

- 起點：`night/bugfix` @ 3e9d508（本機與 `fork/night/bugfix` 相同，最新 commit 含 `NIGHT_BUGFIX_REPORT.md`）
- 執行日期：2026-10-26（04:30 排程）
- Worktree：`/Users/Sofia/Documents/GitHub/Slacker-ios-summer-camp-night-ux`
- 7 項全部完成，每項各一個 commit。

## 各項內容

### 1. 恢復左緣滑動返回 — `e6cea3f`
- 新增 `group/Shared/UI/InteractivePopGesture.swift`：在 `UINavigationController` 的 extension 中，於 `viewDidLoad` 把 `interactivePopGestureRecognizer` 的 delegate 設為自己。`gestureRecognizerShouldBegin` 只在 `viewControllers.count > 1` 時回傳 true，避免在根畫面滑動造成卡住。
- 12 個使用 `navigationBarBackButtonHidden(true)` 的畫面都不用改，自訂返回鍵外觀維持原樣。
- 注意：這個寫法會影響 App 內所有 `UINavigationController`，包含系統元件（例如分享面板內的導覽）。理論上只是讓它們多了滑動返回，不會有負面影響。

### 2. 子任務樂觀更新與連點排隊 — `a95471b`
- `group/Store/AppStore.swift`
  - 新增 `sendSubtaskUpdate(taskID:subtaskID:isComplete:)`：先在本機打勾，再把後端請求接在同一任務前一筆請求後面（`subtaskUpdateQueues`），依序送出，點擊不會再被丟掉。
  - `pendingSubtaskUpdates` 改成 `[subtaskID: Bool]`（正在送出的子任務 → 畫面上顯示的狀態）。另外用 `subtaskUpdateCounts` 計算每個子任務還有幾筆沒送完。
  - 失敗時：該子任務「最後一筆」請求失敗才還原成點擊前的狀態，並沿用 `cloudErrorMessage` 顯示錯誤。中間某筆失敗也會顯示錯誤，但不還原，因為後面還有更新的請求會覆蓋。
  - 即時監聽收到快照時，會把還在送出中的子任務套回樂觀狀態，避免打勾後又閃回去。
  - `sendTaskUpdate` 只剩 `confirm` 在用，拿掉其中處理 `setSubtask` 的程式。`pendingTaskUpdates` 仍只用於成果確認。
  - **沿用 3 點任務的修法**：`toggleSubtask` 一樣會等後端回應才 return。小工具補送（`applyPendingWidgetTodoActions`）改呼叫 `sendSubtaskUpdate(... isComplete: true)`，同樣逐筆等待，成功後立刻移出佇列。
  - 後端 `functions/task-progress.js` 用 transaction 更新子任務。這裡為了保險，還是讓同一任務的請求依序送出。
- `MyTasksView.swift`、`MemberProgressCard.swift`：轉圈指示改成看 `pendingSubtaskUpdates[subtask.id] != nil`，只出現在送出中的那一列。`MemberProgressCard` 拿掉 `.allowsHitTesting(!pendingTaskUpdates.contains(task.id))`，送出中也能繼續點其他子任務。3 點報告提到「`MyTaskDetailView` 送出中點別的子任務會被吞掉」，這次一併解決了。

### 3. 聊天室未讀圓點 — `8a0d7fb`
- `AppStore`：新增只存在記憶體的 `lastSeenChatDateByGroupID`，以及 `markChatSeen(in:)`、`beginTrackingUnreadChat(in:)`、`hasUnreadChat(in:)`。只要有別人送出（不是自己的 `.message`）、而且時間晚於最後看過時間的內容，就算未讀。換帳號時會清空。
- `ChatRoomView`：進入（`onAppear`）和離開（`onDisappear`）時都會更新最後看過的時間。
- `GroupDetailView.topBar`：聊天室按鈕右上角加上紅色小圓點（黃色描邊，參考鈴鐺徽章的風格），並加上 `accessibilityValue`「有新訊息」。第一次看到群組頁時，以當下的聊天內容作為基準。因為沒有持久化，App 重開後之前的訊息不會被當成未讀。
- 新增字串「有新訊息」（en：New messages / zh-Hant）。
- **限制（需要產品決定）**：live 模式下，Firebase 聊天訊息只在 `ChatRoomView` 內監聽（`startChatSync`／`stopChatSync`）。人在聊天室外時，別人的新訊息不會進到 App，所以 live 模式下圓點幾乎只會因為「離開聊天室後才回來的內容」或本機／示範資料而出現。要讓圓點真的反映別人的新訊息，需要在群組頁也監聽最新訊息。這會增加 Firestore 讀取量，今晚沒有自行加入。

### 4. 「退出群組」移到編輯選單 — `cafb3e8`
- `GroupDetailView`：拿掉頁面底部 52pt 的紅色大按鈕。在 `editGroupOptionsOverlay` 最下方加一個紅框紅字、沒有填色的「退出群組」選項，所有成員都看得到（編輯按鈕本來就不限組長）。
- 點了會先關閉選單，再打開原本的 `showsLeaveConfirmation` 確認視窗。`isLeaving` 時顯示「退出中…」並停用。

### 5. 再點一次目前分頁回到根畫面 — `15c326e`
- `AppTab.swift`：`BombTabBar` 新增 `onReselect`，點到已選取的分頁時會呼叫它。
- `AppRootView.swift`：用 `navigationResetIDs: [AppTab: UUID]` 取代 `settingsNavigationID`，三個 NavigationStack 都加上 `.id(navigationResetIDs[tab])`。`popToRoot` 會換掉該分頁的 ID，重建它的 NavigationStack；群組分頁另外清空 `reviewNotificationPath`。
- 為什麼重建堆疊、不只清 path：群組列表用 `navigationDestination(item:)` 的內部狀態進入群組，其他頁面也多半用 view-based `NavigationLink`，只清 path 回不到根畫面。這個做法和原本設定頁的重置方式一樣。
- 副作用：在根畫面再點一次也會重建根畫面，捲動位置、展開狀態等 `@State` 會重設，效果接近「捲回頂端」。

### 6. 移除設定頁切換分頁時的重置 — `c170e42`
- `AppRootView.swift`：刪除 `.onChange(of: tab)` 中「離開設定分頁就重設」的邏輯。現在設定分頁和其他分頁一樣會保留位置，要回根畫面就用第 5 項。

### 7. 減少動態效果 — `7668aa4`
- `GroupDetailView`：`TaskEditorSheet` 的 transition 改成 `reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)`，和 `PublishTaskSheet` 一致。

## 修改的檔案
- `group/Shared/UI/InteractivePopGesture.swift`（新增）
- `group/Store/AppStore.swift`
- `group/Features/MyTasks/MyTasksView.swift`
- `group/Features/Groups/GroupDetail/MemberProgressCard.swift`
- `group/Features/Groups/GroupDetail/GroupDetailView.swift`
- `group/Features/Groups/GroupDetail/ChatRoomView.swift`
- `group/Resources/en.lproj/Localizable.strings`、`group/Resources/zh-Hant.lproj/Localizable.strings`
- `group/App/AppTab.swift`
- `group/App/AppRootView.swift`

## 建置結果
- 開工前先確認起點能建置。之後每個 commit 之前都在 worktree 根目錄執行下面的指令，7 次都是 `** BUILD SUCCEEDED **`、exit 0：
  `xcodebuild -project group.xcodeproj -scheme group -destination 'generic/platform=iOS Simulator' build`
- `swift test`（`Package.swift` 的 `GroupCloudDataTests`）**沒有跑成**：編譯到資源 bundle 的 codesign 時失敗，訊息是 `resource fork, Finder information, or similar detritus not allowed`（檔案帶有延伸屬性），清掉 build 產物的 xattr 後仍然失敗。這是本機環境問題。這個測試 target 不包含這次改的 Swift 檔，只會處理到兩個 `Localizable.strings`。建議早上在一般終端機重跑一次。

## 未驗證之處
- **未做畫面驗證**：本機沒有 serve-sim，依規定也沒有開 Chrome、Playwright 或其他瀏覽器，沒有用模擬器截圖。
- 沒有實際測試 Firebase 上的子任務排隊、失敗還原、快照覆蓋等情境。
- 沒有測試滑動返回和各畫面自訂手勢（例如橫向捲動、拖曳）會不會衝突。

## 需要人工在畫面確認的步驟
1. **滑動返回**：從群組 → 群組詳情 → 聊天室，以及設定 → 各子頁、我的任務 → 任務詳情，從左緣往右滑，應該能返回。在各分頁根畫面滑動不應卡住。自訂返回鍵外觀不變。
2. **子任務**：在「我的任務」任務詳情與群組詳情的成員卡中，快速連點同一任務的 2～3 個子任務。每一個都應該立刻打勾，只有送出中的那幾列會轉圈，最後全部都保留。關掉網路再點，應該跳出雲端同步錯誤，該子任務恢復成原本的狀態。
3. **聊天未讀**：進群組詳情 → 進聊天室 → 讓別人（或機器人回覆）在你離開後新增內容 → 回到群組詳情，聊天按鈕應該有紅點；VoiceOver 會唸「聊天室，有新訊息」。再進聊天室後紅點消失。（live 模式限制見第 3 項。）
4. **退出群組**：群組詳情底部不再有紅色大按鈕。點邀請碼旁的鉛筆 → 選單最下方有紅框的「退出群組」→ 跳出原本的確認視窗 → 確認後退出並返回列表。
5. **重點分頁**：在任一分頁往下點進兩層，再點一次該分頁的 tab，應該回到根畫面。切到別的分頁再切回來，位置應該保留（包含設定分頁）。從審查通知開啟的群組詳情，也能用重點群組分頁回到列表。
6. **減少動態效果**：開啟「設定 → 輔助使用 → 動態效果 → 減少動態效果」，在群組詳情編輯任務，編輯面板應該淡入，不是從下方滑入。

## 沒做或留給後續的
- 聊天未讀在 live 模式需要群組頁層級的訊息監聽才會真正有用（見第 3 項），需要產品決定。
- 重點分頁目前用重建 NavigationStack 的方式實作。之後如果各分頁改用 path-based 導覽，可以換成只清 path，保留根畫面狀態。
