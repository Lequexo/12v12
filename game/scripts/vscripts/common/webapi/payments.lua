Payments = Payments or {}

RegisterCustomEventListener("payments:create", function(event)
	local payerId = event.PlayerID
	local steamId = tostring(PlayerResource:GetSteamID(payerId))
	local matchId = tonumber(tostring(GameRules:Script_GetMatchID()))
	local is_gift_code = event.isGiftCode or false
	
	WebApi:Send(
		"payment/create",
		{ 
			steamId = steamId, 
			matchId = matchId, 
			method = event.method, 
			paymentKind = event.paymentKind,
			isGiftCode = is_gift_code, 
			mapName = GetMapName() 
		},
		function(response)
			local player = PlayerResource:GetPlayer(payerId)
			if not player then return end

			CustomGameEventManager:Send_ServerToPlayer(player, "payments:create", {
				id = event.id,
				url = response.url,
			})
		end,
		function(error)
			local player = PlayerResource:GetPlayer(payerId)
			if not player then return end

			CustomGameEventManager:Send_ServerToPlayer(player, "payments:create", {
				id = event.id,
				error = error.message,
			})
		end
	)
end)

Payments.openPaymentWindows = Payments.openPaymentWindows or {}
local function onPaymentWindowOpenStatusChange(args)
	local playerId = args.PlayerID
	if not playerId then return end
	if args.visible == 1 then
		Payments.openPaymentWindows[playerId] = true
		MatchEvents.RequestDelay = 5
	else
		Payments.openPaymentWindows[playerId] = nil
		if not next(Payments.openPaymentWindows) then
			MatchEvents.RequestDelay = MatchEvents.DEFAULT_REQUEST_DELAY
		end
	end
end

RegisterCustomEventListener("payments:window", onPaymentWindowOpenStatusChange)
RegisterGameEventListener("player_disconnect", function(args)
	onPaymentWindowOpenStatusChange({ PlayerID = args.PlayerID, visible = 0 })
end)

MatchEvents.ResponseHandlers.paymentUpdate = function(response)
	local steamId = response.steamId
	local playerId = GetPlayerIdBySteamId(steamId)

	if playerId == -1 then return end

	local player = PlayerResource:GetPlayer(playerId)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "payments:update", response)
	end

	if not response.error then
		if response.supporterState then
			Supporters:SetPlayerState(playerId, response.supporterState)
			BP_Inventory:UpdateLocalItems(Battlepass.steamid_map[playerId])
			BP_Inventory:UpdateAvailableItems(playerId)
		end

		if response.level then
			BP_PlayerProgress.players[steamId].level = response.level
		end

		if response.exp then
			BP_PlayerProgress.players[steamId].current_exp = response.exp
			BP_PlayerProgress.players[steamId].required_exp = response.expRequired
		end

		if response.purchasedItem then
			BP_Inventory:AddItemLocal(response.purchasedItem.itemName, response.purchasedItem.steamId, response.purchasedItem.count)
		end

		if response.purchasedCodeDetails then
			GiftCodes:AddCodeForPlayer(playerId, {
				code = response.purchasedCodeDetails.Code,
				paymentKind = response.purchasedCodeDetails.PaymentKind,
				redeemerSteamId = "None",
			})
			GiftCodes:UpdateCodeDataClient(playerId)
		end

		if response.glory then
			BP_PlayerProgress:ChangeGlory(playerId, response.glory - BP_PlayerProgress:GetGlory(playerId))
		end

		if response.fortune then
			BP_PlayerProgress:SetFortune(playerId, response.fortune)
			BP_Masteries:UpdateFortune(playerId)
		end
		
		if response.newRating and response.newRating[GetMapName()] then
			local playersStats = CustomNetTables:GetTableValue("game_state", "player_stats");
			if not playersStats then return end

			local player_id_string = tostring(playerId)
			if not playersStats[player_id_string] then return end
			if not playersStats[player_id_string].rating then return end

			playersStats[player_id_string].rating = response.newRating[GetMapName()]

			CustomNetTables:SetTableValue("game_state", "player_stats", playersStats)
		end
		
		BP_PlayerProgress:UpdatePlayerInfo(playerId)
	end
end
