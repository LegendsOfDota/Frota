-- Defense of Rune Hill
-- Tower Denfese Addon of Frota
-- By Xavier@2014.02

local currentRound
local round_have_started
local nEnemyAlive
local timeRoundEnd
local prepareEnded
local finalBossSpawned

local unit_per_round = 20
local prePrepareTime = 60
local timeBetweenRound = 30
local timeUnitSpawnInterval = 0.5

local waypoint1 = Vec3(-1120,-1120,0)
local waypoint2 = Vec3(40,940,0)
local waypoint3 = Vec3(690,260,0)
local waypoint4 = Vec3(490,-1360,0)
local waypoint5 = Vec3(2450,-1400,0)
local waypoint6 = Vec3(2400,630,0)
local waypoint7 = Vec3(1450,500,0)
local waypoint8 = Vec3(1550,-500,0)
local waypoint9 = Vec3(2190,2030,0)

local unitRound = {									
                  "npc_dorh_enemy_gycrophter",  	-- 1  	--Round Start 
                  "npc_dorh_enemy_legion",  		-- 2
                  "npc_dorh_enemy_tinker",  		-- 3
                  "npc_dorh_enemy_bounty_hunter",  	-- 4
                  "npc_dorh_enemy_alchemist",  		-- 5  	--Round 1 Boss
                  "npc_dorh_enemy_beast_master",  -- 6
                  "npc_dorh_enemy_furion",  -- 7
                  "npc_dorh_enemy_enchant",  -- 8
                  "npc_dorh_enemy_brood_mother",  -- 9  	--Round 2 Boss
                  "npc_dorh_enemy_slardar",  -- 10
                  "npc_dorh_enemy_tide_hunter",  -- 11
                  "npc_dorh_enemy_nage_siren",  -- 12
                  "npc_dorh_enemy_slark",  -- 13	--Round 3 Boss
                  "npc_dorh_enemy_ember_spirit",  -- 14  
                  "npc_dorh_enemy_lina",  -- 15
                  "npc_dorh_enemy_batridder",  -- 16
                  "npc_dorh_enemy_doom",  -- 17	--Round 4 Boss
                  "npc_dorh_enemy_tiny",  -- 18
                  "npc_dorh_enemy_sandking",  -- 19  
                  "npc_dorh_enemy_eldertitan",  -- 20	
                  "npc_dorh_enemy_earth_spirit",  -- 21	--Round 5 Boss
                  "npc_dorh_enemy_roshan"  --  22		--Round Final BOSS 
				}

local unitCountRound = {20,20,20,20,1, 	-- start,2-5 
						20,20,20,1,		-- 6-9
						20,20,20,1,		-- 10-13
						20,20,20,1,		-- 14-17
						20,20,20,1,1		-- 18-22		
						}
	
local function spawnWaypointMarkers(frota)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint1, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint2, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint3, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint4, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint5, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint6, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint7, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint8, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local unit = CreateUnitByName("npc_dorh_waypoint_marker", waypoint9, false, nil, nil, DOTA_TEAM_GOODGUYS)
end

local function dorhOrdertoMove(frota,thisPoint,nextPoint)
    local uOnPoint = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, thisPoint, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER, 0, FIND_ANY_ORDER, false )
    for _,unit in ipairs(uOnPoint) do
    ExecuteOrderFromTable({
      UnitIndex = unit:entindex(),
      OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
      Position = nextPoint,
      Queue = false
      })
    end
end

function _spawnWaves_test(frota,round)
	local unitSpawned = CreateUnitByName(unitRound[round], waypoint1 + RandomVector( 150 ), false, nil, nil, DOTA_TEAM_BADGUYS)
	if unitSpawned then
		unitSpawned:AddNewModifier( unitSpawned, nil, "modifier_phased", {} )
	end
end

RegisterGamemode('dorh', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- A list of options for fast gameplay stuff
    options = {
        killsScore = false,
        useScores = true,
        respawnDelay = 15
    },
    
    voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 20,

            -- Maximal possible value
            max = 20,

            -- Default vaule (if no one votes)
            def = 20,

            -- Slider tick interval
            tick = 1,

            -- Slider step interval
            step = 1
        }
    },

    -- List of maps this plugin works with
    whiteList = {
        runehill = true
    },

    -- List of maps this plugin wont work with
    blackList = {
        dota = true
    },

	
	assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change heroes
        local hero = PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_wisp', 120, 0)
		
		-- Make invulnerable
		hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
        frota:SetActiveHero(hero)

        -- Apply custom invoker skills
        frota:ApplyBuild(hero, {
            [1] = 'dorh_wisp_passive',
            [2] = 'dorh_summon_minion_zuus',
            [3] = 'dorh_wisp_slow',
            [4] = 'dorh_wisp_stun',
            [5] = 'dorh_wisp_destroy',
            [6] = 'dorh_wisp_collect',
            [7] = 'attribute_bonus'
        })
		
		-- Level wisp skills
		local ab = hero:FindAbilityByName('dorh_wisp_passive')
		if ab then
		ab:SetLevel(1)
		end
		local ab = hero:FindAbilityByName('dorh_summon_minion_zuus')
		if ab then
			ab:SetLevel(1)
		end
		local ab = hero:FindAbilityByName('dorh_wisp_slow')
		if ab then
			ab:SetLevel(1)
		end
		local ab = hero:FindAbilityByName('dorh_wisp_stun')
		if ab then
			ab:SetLevel(1)
		end
		local ab = hero:FindAbilityByName('dorh_wisp_destroy')
		if ab then
			ab:SetLevel(1)
		end
		local ab = hero:FindAbilityByName('dorh_wisp_collect')
		if ab then
			ab:SetLevel(1)
		end
    end,
	
    onGameStart = function(frota)
    
		local options = frota:GetOptions()
        frota:SetScoreLimit(options.scoreLimit)
		
		--[[local cply = frota:GetPlayerList()
		if #cply > 1 then
			print("DoRH is a solo gamemode")
			frota:EndGamemode()
		end]]

		--spawn way point markers 1-8 on the ground 
		spawnWaypointMarkers(frota)
		    
		--set init values
		currentRound = 1
		nEnemyAlive = 0
		--for test below	--change current round here to start from this round
		--currentRound = 22
		prePrepareTime = 10
		timeBetweenRound = 10
		--for test above
		
		unittoSpawnThisRound = unitCountRound[currentRound]
		round_have_started = false
		prepareEnded = false
		finalBossSpawned = nil
		finalBossAppeared =  false
		
		--store start time
		preGameStartTime = GameRules:GetGameTime()
		--console: get prepared
		Say(nil,COLOR_LGREEN..'the first wave comes in '.. COLOR_RED..tostring(prePrepareTime)..COLOR_LGREEN..' seconds , GET PREPARED !', false)
    
    end,
	
	onThink = function(frota, dt)
	
		local now = GameRules:GetGameTime()
		
		-- just in case of bugs
		if currentRound > 22 then
			frota:EndGamemode()
		end
		
		--end prepare
		if now - preGameStartTime >= prePrepareTime and prepareEnded == false then
			prepareEnded = true 
			round_have_started = true
			lastUnitSpawnedTime = now
			Say(nil,'Round Started Prepared finished', false)
		end
		
		--end rest between round
		if timeRoundEnd ~= nil then
			if now - timeRoundEnd >= timeBetweenRound and round_have_started == false then
				round_have_started = true
				lastUnitSpawnedTime = now
				currentRound = currentRound + 1
				unittoSpawnThisRound = unitCountRound[currentRound]
				Say(nil,COLOR_LGREEN..'Round '..COLOR_RED..tostring(currentRound)..COLOR_LGREEN..' Started', false)
			end
		end
		
		--round # cleared
		if nEnemyAlive == 0  and round_have_started and unittoSpawnThisRound <= 0 then
			timeRoundEnd = GameRules:GetGameTime()
			round_have_started = false
			Say(nil,COLOR_LGREEN..'Round '..COLOR_RED..tostring(currentRound)..COLOR_LGREEN..' Finished', false)
		end
		
		--spawn wave units
		if unittoSpawnThisRound > 0 and round_have_started and currentRound <= 24 then
			if now - lastUnitSpawnedTime >= timeUnitSpawnInterval then
				_spawnWaves_test(frota,currentRound)
				unittoSpawnThisRound = unittoSpawnThisRound - 1
				nEnemyAlive = nEnemyAlive + 1
				lastUnitSpawnedTime = now
			end
		end
		
		--spawn final boss
		if unittoSpawnThisRound > 0 and round_have_started and currentRound == 25 and not finalBossAppeared then
			finalBossAppeared = true
			
			finalBossSpawned = CreateUnitByName("npc_dorh_enemy_roshan" , waypoint1 , false, nil, nil , DOTA_TEAM_BADGUYS)
			finalBossSpawned:AddNewModifier( finalBossSpawned , nil, "modifier_phased" , {} )
			Say(nil,COLOR_RED..'HERE COMES THE BOSS!!!', false)
		end
		
		--TD AIs
		dorhOrdertoMove( frota , waypoint1 , waypoint4 )
		dorhOrdertoMove( frota , waypoint4 , waypoint5 )
		dorhOrdertoMove( frota , waypoint5 , waypoint6 )
		dorhOrdertoMove( frota , waypoint6 , waypoint9 )
		dorhOrdertoMove( frota , waypoint9 , waypoint2 )
		dorhOrdertoMove( frota , waypoint2 , waypoint3 )
		dorhOrdertoMove( frota , waypoint3 , waypoint7 )
		dorhOrdertoMove( frota , waypoint7 , waypoint8 )
		
		--record and remove escaped units
		local uOnPoint = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, waypoint8, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER, 0, FIND_ANY_ORDER, false )
		for _,unit in ipairs(uOnPoint) do
			frota.scoreDire = frota.scoreDire + 1
			UTIL_RemoveImmediate(unit)
			nEnemyAlive = nEnemyAlive -1
			--Say(nil, COLOR_RED..tostring(nEnemyAlive)..COLOR_LGREEN..' Enemy Left!( Enemy Goal Achieved)', false)
			Say(nil, COLOR_RED..tostring(20- frota.scoreDire)..COLOR_LGREEN..' Lives Left!', false)
			frota:UpdateScoreData()
		end
	end,
	
	entity_killed = function(frota, keys)
		-- Grab the unit that was killed
		local killedUnit = EntIndexToHScript( keys.entindex_killed )

        -- Make sure something was killed
		if killedUnit then

		local team = killedUnit:GetTeam()
			--if an enemy unit killed
			if team == DOTA_TEAM_BADGUYS then
				nEnemyAlive = nEnemyAlive - 1
				--Say(nil, COLOR_RED..tostring(nEnemyAlive)..COLOR_LGREEN..' Enemy Left!(Entity Killed)', false)
				--if the only final boss killed then end game mode
				if currentRound == 22 then
					print("Final Boss Killed Fires Game End")
					frota:EndGamemode()
				end
			end
		end	
	end
})
