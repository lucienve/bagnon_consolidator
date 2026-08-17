--[[
	Bagnon Consolidator - Localization (koKR)
	Korean Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "koKR")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "은행으로 통합"
L["Consolidate to Bank Tooltip"] = "가방에서 중복된 아이템을 찾아 열려 있는 은행으로 이동하고, 겹치기를 통합하여 공간을 절약합니다."
L["Options / Mappings"] = "옵션 / 매핑"
L["Open Mappings Viewer..."] = "매핑 뷰어 열기..."
L["Take Snapshot"] = "스냅샷 생성"
L["Reset Mappings..."] = "매핑 초기화..."
L["Enable Debug Logs"] = "디버그 로그 활성화"
L["All Addon Data"] = "모든 애드온 데이터"
L["Current Character"] = "현재 캐릭터"
L["Personal Bank"] = "개인 은행"
L["Guild Bank"] = "길드 은행"
L["Unknown Item"] = "알 수 없는 아이템"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "%s에 저장된 모든 매핑을 초기화하시겠습니까?"
L["Yes"] = "예"
L["No"] = "아니오"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "%s의 모든 길드 은행 매핑이 초기화되었습니다."
L["You are not currently in a guild."] = "현재 길드에 가입되어 있지 않습니다."
L["Reset all personal bank mappings for %s"] = "%s의 모든 개인 은행 매핑이 초기화되었습니다."
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "모든 Bagnon Consolidator 매핑 및 무시 목록이 초기화되었습니다."
L["Bank or Guild Bank must be open to take a snapshot."] = "스냅샷을 생성하려면 은행 또는 길드 은행이 열려 있어야 합니다."
L["Unable to determine character name and realm."] = "캐릭터 이름 및 서버를 확인할 수 없습니다."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "길드 은행 스냅샷 완료: %s (아이템 %d개 매핑됨, 충돌 %d개, 무시 %d개)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "개인 은행 스냅샷 완료: %s (아이템 %d개 매핑됨, 무시 %d개)."
L["Cannot consolidate in combat."] = "전투 중에는 통합할 수 없습니다."
L["Bank or Guild Bank must be open and active."] = "은행 또는 길드 은행이 열려 있고 활성화되어 있어야 합니다."
L["Consolidation is already in progress."] = "통합이 이미 진행 중입니다."
L["Consolidation complete."] = "통합이 완료되었습니다."
L["Consolidation stopped: %s"] = "통합 중단됨: %s"
L["No items need consolidation."] = "통합할 아이템이 없습니다."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "개인 은행과 길드 은행 모두에 존재함"
L["Present on multiple Guild Bank tabs"] = "여러 길드 은행 탭에 존재함"
L["Present in personal bank of %s"] = "%s의 개인 은행에 존재함"
L["Item has conflicting destinations."] = "아이템에 상충하는 목적지가 있습니다."
L["Multiple destinations"] = "여러 목적지"
L["Conflict (Go Nowhere)"] = "충돌 (이동하지 않음)"
L["Ignored (Never Deposit)"] = "무시됨 (입고 안 함)"
L["%s: %s (Skipped)."] = "%s: %s (건너뜀)."
L["%s has conflicting destinations (Skipped)."] = "%s에 상충하는 목적지가 있습니다 (건너뜀)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator: 매핑"
L["Personal"] = "개인"
L["Guild Bank >"] = "길드 은행 >"
L["Select Guild Bank Tab"] = "길드 은행 탭 선택"
L["Tab %d"] = "탭 %d"
L["Tab %d >"] = "탭 %d >"
L["Tab %d: %s"] = "탭 %d: %s"
L["Tab %d:"] = "탭 %d:"
L["Personal (%d)"] = "개인 (%d)"
L["Conflicts (%d)"] = "충돌 (%d)"
L["Ignored (%d)"] = "무시됨 (%d)"
L["Conflicts"] = "충돌"
L["Ignored"] = "무시됨"
L["Personal Bank Header"] = "|cff82c5ff개인 은행:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ff길드 은행:|r 탭 %d: %s"
L["Guild Bank Header"] = "|cff82c5ff길드 은행:|r 탭 %d"
L["Conflicts Header"] = "|cffffcc00충돌:|r 여러 목적지가 있는 아이템 (이동하지 않음)"
L["Ignored Header"] = "|cffff8888무시됨:|r 통합에서 제외된 아이템"
L["Filter by name/ID"] = "이름/ID로 필터링"
L["Showing %d items"] = "아이템 %d개 표시 중"
L["Showing 0 items"] = "아이템 0개 표시 중"
L["Ignored - will not consolidate"] = "무시됨 - 통합되지 않음"
L["Conflict: %s"] = "충돌: %s"
L["Restore"] = "복원"
L["Clear"] = "삭제"
L["Ignore [X]"] = "무시 [X]"
L["Remove"] = "제거"
L["Item ID: %d"] = "아이템 ID: %d"
L["Item %d"] = "아이템 %d"
L["%s moved to Ignored list."] = "%s|1이;가; 무시 목록으로 이동되었습니다."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s|1이;가; 무시 목록에서 제거되었습니다 (다음 스냅샷에서 다시 학습될 수 있음)."
L["%s conflict cleared."] = "%s 충돌이 해결되었습니다."

-- Options Panel
L["Options Description"] = "은행 스냅샷을 기반으로 가방에 있는 아이템 묶음을 개인 은행 또는 길드 은행으로 자동 입고하고 통합합니다."
