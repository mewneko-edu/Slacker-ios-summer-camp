# 夜間修 bug 報告（night/bugfix）

- 起點：`attachments-widget` @ 6836172
- 執行時間：2026-10-26 03:00 – 03:10（CST）
- Worktree：`/Users/Sofia/Documents/GitHub/Slacker-ios-summer-camp-night-bugfix`

## 修好的 bug

### 1. 超過 15 分鐘才打開 App，小工具上的勾選會遺失 — `72011c6`
- **原因**：`applyPendingWidgetTodoActions()` 用 `WidgetTodoAction.expiry`（15 分鐘）判斷是否丟棄。這個值原本只用來決定小工具要隱藏該列多久，卻同時讓補送失效。
- **修法**：新增 `WidgetTodoAction.replayExpiry`（7 天），`isStale(at:after:)` 多一個參數。小工具隱藏仍用 15 分鐘，App 補送改用 7 天。

### 2. 同一任務勾了多個子任務，補送時只送出第一個 — `b02c3e8`
- **原因**：`sendTaskUpdate` 只要該任務已有更新在送（`pendingTaskUpdates.contains(taskID)`）就直接 return。補送迴圈不會等待，所以第二筆以後都被擋掉。
- **修法**：`sendTaskUpdate` 改成回傳 `Task<Bool, Never>?`（`@discardableResult`），值代表後端是否接受，沒送出時回傳 nil。`toggleSubtask` 會等這個 Task 完成才 return，補送因此變成逐筆依序進行。畫面上的呼叫端本來就包在 `Task {}` 裡，行為不變。

### 3. 補送成功後沒有移出佇列，App 裡改回未完成後又被自動完成 — `625180d`
- **原因**：補送呼叫的是「切換」用的 `toggleSubtask`，成功後也沒有移出佇列，要等下一輪看到已完成才清掉。
- **修法**：雲端任務改為直接 `sendTaskUpdate(... isComplete: true)`，固定設成完成、不再切換。後端成功後立刻 `WidgetTodoActionQueue.remove`。本機任務（沒有 `firestoreDocumentID`）仍呼叫 `toggleSubtask`，因為前面已確認子任務未完成，切換就等於完成；呼叫後直接移出佇列。失敗或沒送出的會留在佇列，下次再試。

### 4. （小風險）App 與小工具同時改佇列，可能吃掉一筆勾選 — `38c3cc3`
- **原因**：整個佇列存成同一個 key 的 JSON 陣列，用「讀取 → 修改 → 寫回」更新，兩個程序之間沒有鎖。
- **修法**：每筆勾選存在自己的 key（`widgetTodoActionQueue.<subtaskID>`）。`enqueue` 和 `remove` 只動自己那個 key，`pending()` 用 `dictionaryRepresentation()` 依前綴讀出全部。兩個程序不會再覆寫對方的資料。
- **注意**：舊格式（單一 key 的陣列）不做遷移。升級當下還沒補送的勾選會被忽略（依 AGENTS.md，可以不做 migration）。

### 5. 補送期限拉長後，不屬於目前使用者的勾選會重試 7 天 — `6e5046a`
- **原因**：這是第 1 項修法帶出的問題。如果期間換了帳號，或任務改派給別人，佇列裡的勾選會一直被送到後端、一直被拒絕，每次回到前景都跳錯誤。原本最多 15 分鐘就失效，現在會持續 7 天。
- **修法**：補送時如果任務的 `ownerMemberID != currentUserID`，就直接移出佇列。小工具只會列出自己的任務，所以這種勾選不可能是有效的。

### 6. `settleGroup` 在 await 之後用舊的 index 寫回 — `afeeaee`
- **原因**：呼叫結算 Callable 之前取得的 `index`，等結算完成後直接拿來寫 `groups[index].settledAt`。等待期間如果快照重新載入，或群組被重新排序、移除，就會寫到錯的群組，甚至超出範圍而 crash。`publishTask` 和 `updateOwnedTask` 已經有處理這種情況，`settleGroup` 漏掉了。
- **修法**：await 之後重新用 `groupID` 查 index，查不到就拋出 `groupNotFound`。

## 修改的檔案
- `WidgetShared/WidgetTodoActionQueue.swift`
- `group/Store/AppStore.swift`

## 建置結果
每個 commit 之前都在 worktree 根目錄執行過下面的指令，6 次都是 exit 0、`** BUILD SUCCEEDED **`：
`xcodebuild -project group.xcodeproj -scheme group -destination 'generic/platform=iOS Simulator' build`

## 未驗證之處
- 沒有做任何畫面、模擬器或實機驗證（本機沒有 serve-sim，依規定也不開其他瀏覽器）。
- 沒有實際測試小工具勾選 → App 補送 → Firebase 這整段流程，也沒有測試離線和換帳號的情境。
- 專案沒有單元測試可以跑，只確認了能建置。
- `dictionaryRepresentation()` 在 App Group 的 UserDefaults 上，理論上能讀到另一個程序剛寫入的 key，但沒有在實機上確認同步延遲。

## 沒修的問題（不確定是不是 bug，或屬於後續任務的範圍）
- **`MyTaskDetailView` 的子任務按鈕**：同一任務有更新在送時沒有停用，此時點別的子任務會被 `sendTaskUpdate` 的 guard 靜靜擋掉、沒有任何回饋。`MemberProgressCard` 有用 `.disabled(model.pendingTaskUpdates.contains(task.id))` 處理這個情況。這牽涉到畫面行為，留給 04:30 的 UX 任務。
- **補送失敗會顯示錯誤**：離線時每次回到前景補送失敗，都會設定 `cloudErrorMessage`，使用者可能反覆看到錯誤訊息（修改前也會這樣，只是最多持續 15 分鐘）。要不要改成補送失敗時不顯示錯誤，需要產品決定。
- **群組名稱和期限只改本機**：`updateGroupDeadline`、`updateGroupName` 在 live 模式下只改本機狀態，沒有送到後端，下次重新載入就會被覆蓋。不確定是不是刻意保留的原型行為，所以沒有改。
- **退出群組後的佇列**：`leaveGroup` 之後，佇列裡屬於該群組任務的勾選會因為找不到任務而保留，直到 7 天後過期。這些勾選 15 分鐘後就不再隱藏小工具的列，只會留下無害的殘留資料，沒有處理。
