--[[
	Bagnon Consolidator - Localization (ptBR)
	Portuguese (Brazil) Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "ptBR")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "Consolidar no Banco"
L["Consolidate to Bank Tooltip"] = "Encontra itens duplicados em suas bolsas e os move para o banco aberto, consolidando pilhas para economizar espaço."
L["Options / Mappings"] = "Opções / Mapeamentos"
L["Open Mappings Viewer..."] = "Abrir Visualizador de Mapeamentos..."
L["Take Snapshot"] = "Criar Instantâneo"
L["Reset Mappings..."] = "Redefinir Mapeamentos..."
L["Enable Debug Logs"] = "Ativar Registros de Depuração"
L["All Addon Data"] = "Todos os Dados do Addon"
L["Current Character"] = "Personagem Atual"
L["Personal Bank"] = "Banco Pessoal"
L["Guild Bank"] = "Banco da Guilda"
L["Unknown Item"] = "Item Desconhecido"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "Tem certeza de que deseja redefinir todos os mapeamentos salvos para %s?"
L["Yes"] = "Sim"
L["No"] = "Não"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "Todos os mapeamentos do banco da guilda foram redefinidos para %s"
L["You are not currently in a guild."] = "Você não está em uma guilda no momento."
L["Reset all personal bank mappings for %s"] = "Todos os mapeamentos do banco pessoal foram redefinidos para %s"
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "Todos os mapeamentos e listas de ignorados foram redefinidos."
L["Bank or Guild Bank must be open to take a snapshot."] = "O banco ou banco da guilda precisa estar aberto para criar um instantâneo."
L["Unable to determine character name and realm."] = "Não foi possível determinar o nome do personagem e o reino."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "Instantâneo concluído para o Banco da Guilda: %s (%d itens mapeados, %d conflitos, %d ignorados)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "Instantâneo concluído para o Banco Pessoal: %s (%d itens mapeados, %d ignorados)."
L["Cannot consolidate in combat."] = "Não é possível consolidar em combate."
L["Bank or Guild Bank must be open and active."] = "O banco ou banco da guilda precisa estar aberto e ativo."
L["Consolidation is already in progress."] = "A consolidação já está em andamento."
L["Consolidation complete."] = "Consolidação concluída."
L["Consolidation stopped: %s"] = "Consolidação interrompida: %s"
L["No items need consolidation."] = "Nenhum item precisa de consolidação."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "Presente no Banco Pessoal e no Banco da Guilda"
L["Present on multiple Guild Bank tabs"] = "Presente em várias abas do Banco da Guilda"
L["Present in personal bank of %s"] = "Presente no banco pessoal de %s"
L["Item has conflicting destinations."] = "O item possui destinos conflitantes."
L["Multiple destinations"] = "Múltiplos destinos"
L["Conflict (Go Nowhere)"] = "Conflito (Não mover)"
L["Ignored (Never Deposit)"] = "Ignorado (Nunca depositar)"
L["%s: %s (Skipped)."] = "%s: %s (Ignorado)."
L["%s has conflicting destinations (Skipped)."] = "%s possui destinos conflitantes (Ignorado)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator: Mapeamentos"
L["Personal"] = "Pessoal"
L["Guild Bank >"] = "Banco da Guilda >"
L["Select Guild Bank Tab"] = "Selecionar Aba do Banco da Guilda"
L["Tab %d"] = "Aba %d"
L["Tab %d >"] = "Aba %d >"
L["Tab %d: %s"] = "Aba %d: %s"
L["Tab %d:"] = "Aba %d:"
L["Personal (%d)"] = "Pessoal (%d)"
L["Conflicts (%d)"] = "Conflitos (%d)"
L["Ignored (%d)"] = "Ignorados (%d)"
L["Conflicts"] = "Conflitos"
L["Ignored"] = "Ignorados"
L["Personal Bank Header"] = "|cff82c5ffBanco Pessoal:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffBanco da Guilda:|r Aba %d: %s"
L["Guild Bank Header"] = "|cff82c5ffBanco da Guilda:|r Aba %d"
L["Conflicts Header"] = "|cffffcc00Conflitos:|r Itens com múltiplos destinos (Não mover)"
L["Ignored Header"] = "|cffff8888Ignorados:|r Itens excluídos da consolidação"
L["Filter by name/ID"] = "Filtrar por nome/ID"
L["Showing %d items"] = "Mostrando %d itens"
L["Showing 0 items"] = "Mostrando 0 itens"
L["Ignored - will not consolidate"] = "Ignorado - não será consolidado"
L["Conflict: %s"] = "Conflito: %s"
L["Restore"] = "Restaurar"
L["Clear"] = "Limpar"
L["Ignore [X]"] = "Ignorar [X]"
L["Remove"] = "Remover"
L["Item ID: %d"] = "ID do Item: %d"
L["Item %d"] = "Item %d"
L["%s moved to Ignored list."] = "%s movido para a lista de ignorados."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s removido da lista de ignorados (será reaprendido no próximo instantâneo)."
L["%s conflict cleared."] = "Conflito de %s resolvido."

-- Options Panel
L["Options Description"] = "Deposita e consolida automaticamente pilhas de itens das suas bolsas para o banco ou banco da guilda com base no seu instantâneo."
