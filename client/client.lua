QBCore = exports['qb-core']:GetCoreObject()
local lastSelectedVehicleEntity
local startCountDown
local testDriveEntity
local lastPlayerCoords
local hashListLoadedOnMemory = {}
local vehcategory = nil
local inTheShop = false
local profileName
local profileMoney
local vehiclesTable = {}
local provisoryObject = {}
local rgbColorSelected = {255,255,255,}
local rgbSecondaryColorSelected = {255,255,255,}

local targetSpawned = false
local variables = false
local blips = {}
local showVehicles = {}
local entities = {}
local zones = {}
--------------------------------

function createVariables()
    if variables then return end
    for i,v in pairs(Config.Shops) do
        if v.blip then
            blips[i] = AddBlipForCoord(v.coord.x, v.coord.y, v.coord.z)
            SetBlipSprite(blips[i], v.blip.sprite)
            SetBlipScale(blips[i], v.blip.scale)
            SetBlipDisplay(blips[i], v.blip.display)
            SetBlipColour(blips[i], v.blip.colour)
            SetBlipAsShortRange(blips[i], v.blip.shortrange)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(v.blip.label)
            EndTextCommandSetBlipName(blips[i])
        end
        if v.showVehicles then
            for a,b in pairs(v.showVehicles) do
                local model = b.model
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
                showVehicles[i..a] = CreateVehicle(model, b.location.x, b.location.y, b.location.z, false, false)
                SetModelAsNoLongerNeeded(model)
                if b.livery then
                    SetVehicleModKit(showVehicles[i..a], 0)
                    SetVehicleMod(showVehicles[i..a], 48, b.livery)
                end
                SetVehicleOnGroundProperly(showVehicles[i..a])
                SetEntityInvincible(showVehicles[i..a], true)
                SetVehicleDirtLevel(showVehicles[i..a], 0.0)
                SetVehicleDoorsLocked(showVehicles[i..a], 3)
                SetEntityHeading(showVehicles[i..a], b.location.w)
                FreezeEntityPosition(showVehicles[i..a], true)
                SetVehicleEngineOn(showVehicles[i..a], false, true, true)
                SetVehicleNumberPlateText(showVehicles[i..a], 'BUY ME')
            end
        end
    end
    variables = true
end

function deleteVariables()
    if blips then
        for i,v in pairs(blips) do
            if Config.Debug then print(tostring(v) .. " has been deleted (blips)") end
            RemoveBlip(v)
        end
    end
    if showVehicles then
        for i,v in pairs(showVehicles) do
            if Config.Debug then print(tostring(v) .. " has been deleted (showVehicles)") end
            DeleteEntity(v)
        end
    end
    blips = {}
    showVehicles = {}
    variables = false
end

function createInteractions()
    if Config.UseTarget then
        if targetSpawned then return end
        for i,v in pairs(Config.Shops) do
            if v.target.usePed then
                CreateThread(function()
                    local model = v.target.pedModel
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                      Wait(0)
                    end
                    entities[i] = CreatePed(0, model, v.coord, false, false)
                    SetPedFleeAttributes(entities[i], 0, 0)
                    SetPedDiesWhenInjured(entities[i], false)
                    SetPedKeepTask(entities[i], true)
                    SetBlockingOfNonTemporaryEvents(entities[i], true)
                    SetEntityInvincible(entities[i], true)
                    FreezeEntityPosition(entities[i], true)
                    local animation = "WORLD_HUMAN_STAND_IMPATIENT"
                    if v.target.pedAnimation ~= nil and v.target.pedAnimation ~= '' then
                        animation = v.target.pedAnimation
                    end
                    TaskStartScenarioInPlace(entities[i], animation, 0, true)

                    local jobTarget = v.target.properties.job
                    if jobTarget == '' then
                        jobTarget = nil
                    end
                    exports['qb-target']:AddTargetEntity(entities[i], {
                      options = {
                        {
                          num = 1,
                          type = "client",
                          icon = v.target.properties.icon,
                          label = v.target.properties.label,
                          action = function()
                            vehcategory = i
                            OpenVehicleShop()
                          end,
                          job = jobTarget,
                        }
                      },
                      distance = v.target.distance,
                    })
                end)
            else
                CreateThread(function()
                    local jobTarget = v.target.properties.job
                    if jobTarget == '' then
                        jobTarget = nil
                    end
                    zones[#zones+1] = i
                    exports['qb-target']:AddBoxZone(i, vector3(v.coord.x, v.coord.y, v.coord.z), v.target.length, v.target.width, {
                        name = "name",
                        heading = v.coord.w,
                        debugPoly = v.target.debugPoly,
                        minZ = v.target.minZ,
                        maxZ = v.target.maxZ,
                      }, {
                        options = {
                            {
                              num = 1,
                              type = "client",
                              icon = v.target.properties.icon,
                              label = v.target.properties.label,
                              action = function()
                                vehcategory = i
                                OpenVehicleShop()
                              end,
                              job = jobTarget,
                            }
                          },
                          distance = v.target.distance,
                      })
                end)
            end
        end
        targetSpawned = true
    else
        CreateThread(function()
            while true do
                Citizen.Wait(3)
                local ped = PlayerPedId()
                local sleep = true
                for i,v in pairs(Config.Shops) do
                local actualShop = vector3(v.coord.x, v.coord.y, v.coord.z)
                local dist = #(actualShop - GetEntityCoords(ped))
                    if dist <= 5 then
                        sleep = false
                        DrawMarker(2, actualShop.x, actualShop.y, actualShop.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.2, 0.1, 255, 0, 0, 155, 0, 0, 0, 1, 0, 0, 0)
                        if dist <= 2.5 then
                            DrawText3Ds(actualShop.x, actualShop.y, actualShop.z + 0.2, '[~g~E~w~] - Browse Vehicle Shop')
                            if IsControlJustPressed(0, 38) then
                                vehcategory = i
                                OpenVehicleShop()
                            end
                        end
                    end
                end
                if sleep then
                    Wait(500)
                end
            end
        end)
    end
end

function deleteInteractions()
    if Config.UseTarget then
        if entities then
            for i,v in pairs(entities) do
                if Config.Debug then print(tostring(v) .. " has been deleted (peds)") end
                exports['qb-target']:RemoveTargetEntity(v, i)
            end
        end
        if zones then
            for i,v in pairs(zones) do
                if Config.Debug then print(tostring(v) .. " has been deleted (zones)") end
                exports['qb-target']:RemoveZone(v)
            end
        end
        entities = {}
        zones = {}
        targetSpawned = false
    end
end

-------------------------------

RegisterNetEvent('qb-vehicleshop.receiveInfo')
AddEventHandler('qb-vehicleshop.receiveInfo', function(bank, name)
    if name then
        profileName = name
    end
    profileMoney = bank
end)


RegisterNetEvent('qb-vehicleshop.successfulbuy')
AddEventHandler('qb-vehicleshop.successfulbuy', function(vehicleName,vehiclePlate,value)
    SendNUIMessage(
        {
            type = "successful-buy",
            vehicleName = vehicleName,
            vehiclePlate = vehiclePlate,
            value = value
        }
    )
    CloseNui()
end)

RegisterNetEvent('qb-vehicleshop.notify')
AddEventHandler('qb-vehicleshop.notify', function(type, message)
    SendNUIMessage(
        {
            type = "notify",
            typenotify = type,
            message = message,
        }
    )
end)

local limitQuanty = 5000

RegisterNetEvent('qb-vehicleshop.vehiclesInfos')
AddEventHandler('qb-vehicleshop.vehiclesInfos', function()
    if Config.Debug then print(vehcategory) end
    for k,v in pairs(QBCore.Shared.Vehicles) do
        if v.shop == vehcategory then
            vehiclesTable[v.categoryLabel] = {}
        end
    end

    for k,v in pairs(QBCore.Shared.Vehicles) do
        if v.shop == vehcategory then
            local deny = false
            local discount = 0
            if Config.BlacklistedVehicles[v.model] then
                if Config.Debug then print(v.model .. " is blacklisted") end
                deny = true
            end
            if Config.PriceDiscount[v.model] then
                discount = Config.PriceDiscount[v.model]
            end
            if not deny then
                if Config.LimitQuantityVehicles[v.model] then
                    QBCore.Functions.TriggerCallback('qb-vehicleshop:checkVehicle', function(result)
                        provisoryObject = {
                            name = v.name,
                            brand = v.brand,
                            model = v.model,
                            price = v.price,
                            category = v.category,
                            qtd = result,
                            discount = discount
                        }
                        table.insert(vehiclesTable[v.category], provisoryObject)
                    end, v.model)
                else
                    provisoryObject = {
                        name = v.name,
                        brand = v.brand,
                        model = v.model,
                        price = v.price,
                        category = v.category,
                        qtd = limitQuanty,
                        discount = discount
                    }
                    table.insert(vehiclesTable[v.category], provisoryObject)
                end
            end
        end
    end
end)

function OpenVehicleShop()
    inTheShop = true
    TriggerServerEvent("qb-vehicleshop.requestInfo")
    TriggerEvent('qb-vehicleshop.vehiclesInfos')
    Citizen.Wait(1000)
    local testDriveAllowed = false
    if Config.Shops[vehcategory].setupStore.allowTestDrive then
        testDriveAllowed = true
    end
    SendNUIMessage(
        {
            data = vehiclesTable,
            type = "display",
            playerName = profileName,
            playerMoney = profileMoney,
            testDrive = testDriveAllowed
        }
    )
    SetNuiFocus(true, true)
    RequestCollisionAtCoord(x, y, z)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.Shops[vehcategory].setupStore.shopCameraLoc[1], Config.Shops[vehcategory].setupStore.shopCameraLoc[2], Config.Shops[vehcategory].setupStore.shopCameraLoc[3], Config.Shops[vehcategory].setupStore.shopCameraLoc[4], Config.Shops[vehcategory].setupStore.shopCameraLoc[5], Config.Shops[vehcategory].setupStore.shopCameraLoc[6], 60.00, false, 0)
    PointCamAtCoord(cam, Config.Shops[vehcategory].setupStore.shopVehicleLoc.x, Config.Shops[vehcategory].setupStore.shopVehicleLoc.y, Config.Shops[vehcategory].setupStore.shopVehicleLoc.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1, true, true)
    SetFocusPosAndVel(Config.Shops[vehcategory].setupStore.shopCameraLoc[1], Config.Shops[vehcategory].setupStore.shopCameraLoc[2], Config.Shops[vehcategory].setupStore.shopCameraLoc[3], 0.0, 0.0, 0.0)
    DisplayHud(false)
    DisplayRadar(false)

    if lastSelectedVehicleEntity ~= nil then
        DeleteEntity(lastSelectedVehicleEntity)
    end
end

function updateSelectedVehicle(model)
    local name = model
    local model = GetHashKey(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    if lastSelectedVehicleEntity ~= nil then
        DeleteEntity(lastSelectedVehicleEntity)
    end
    lastSelectedVehicleEntity = CreateVehicle(model, Config.Shops[vehcategory].setupStore.shopVehicleLoc.x, Config.Shops[vehcategory].setupStore.shopVehicleLoc.y, Config.Shops[vehcategory].setupStore.shopVehicleLoc.z, false, false)
    SetEntityHeading(lastSelectedVehicleEntity, Config.Shops[vehcategory].setupStore.shopVehicleLoc.w)
    SetModelAsNoLongerNeeded(model)
    SetVehicleOnGroundProperly(lastSelectedVehicleEntity)
    SetEntityInvincible(lastSelectedVehicleEntity, true)
    SetVehicleDirtLevel(lastSelectedVehicleEntity, 0.0)
    SetVehicleDoorsLocked(lastSelectedVehicleEntity, 3)
    FreezeEntityPosition(lastSelectedVehicleEntity, true)
    SetVehicleEngineOn(lastSelectedVehicleEntity, false, true, true)
    SetVehicleNumberPlateText(lastSelectedVehicleEntity, 'BUY ME')

    local vehicleData = {}
    vehicleData.buy = true
    vehicleData.traction = GetVehicleMaxTraction(lastSelectedVehicleEntity)
    vehicleData.breaking = GetVehicleMaxBraking(lastSelectedVehicleEntity) * 0.9650553
    if vehicleData.breaking >= 1.0 then
        vehicleData.breaking = 1.0
    end

    vehicleData.maxSpeed = GetVehicleEstimatedMaxSpeed(lastSelectedVehicleEntity) * 0.9650553
    if vehicleData.maxSpeed >= 50.0 then
        vehicleData.maxSpeed = 50.0
    end

    vehicleData.acceleration = GetVehicleAcceleration(lastSelectedVehicleEntity) * 2.6
    if  vehicleData.acceleration >= 1.0 then
        vehicleData.acceleration = 1.0
    end

    if Config.LimitQuantityVehicles[name] then
        QBCore.Functions.TriggerCallback('qb-vehicleshop:checkVehicle', function(result)
            if result <= 0 then
                vehicleData.buy = false
            end
            SendNUIMessage(
                {
                    data = vehicleData,
                    type = "updateVehicleInfos",
                }
            )
        end, name)
    else
        SendNUIMessage(
            {
                data = vehicleData,
                type = "updateVehicleInfos",
            }
        )
    end

    SetVehicleCustomPrimaryColour(lastSelectedVehicleEntity,  rgbColorSelected[1], rgbColorSelected[2], rgbColorSelected[3])
    SetVehicleCustomSecondaryColour(lastSelectedVehicleEntity,  rgbSecondaryColorSelected[1], rgbSecondaryColorSelected[2], rgbSecondaryColorSelected[3])
end


function rotation(dir)
    local entityRot = GetEntityHeading(lastSelectedVehicleEntity) + dir
    SetEntityHeading(lastSelectedVehicleEntity, entityRot % 360)
end

RegisterNUICallback(
    "rotate",
    function(data, cb)
        if (data["key"] == "left") then
            rotation(2)
        else
            rotation(-2)
        end
        cb("ok")
    end
)


RegisterNUICallback(
    "SpawnVehicle",
    function(data, cb)
        updateSelectedVehicle(data.modelcar)
    end
)



RegisterNUICallback(
    "RGBVehicle",
    function(data, cb)
        if data.primary then
            rgbColorSelected = data.color
            SetVehicleCustomPrimaryColour(lastSelectedVehicleEntity, math.ceil(data.color[1]), math.ceil(data.color[2]), math.ceil(data.color[3]) )
        else
            rgbSecondaryColorSelected = data.color
            SetVehicleCustomSecondaryColour(lastSelectedVehicleEntity, math.ceil(data.color[1]), math.ceil(data.color[2]), math.ceil(data.color[3]))
        end
    end
)

RegisterNUICallback(
    "Buy",
    function(data, cb)

        local newPlate     = GeneratePlate()
        local vehicleProps = QBCore.Functions.GetVehicleProperties(lastSelectedVehicleEntity)
        vehicleProps.plate = newPlate

        TriggerServerEvent('qb-vehicleshop.CheckMoneyForVeh', data.modelcar, data.sale, data.name, vehicleProps, Config.Shops[vehcategory].garage)

        Wait(1500)
        -- SendNUIMessage(
        --     {
        --         type = "updateMoney",
        --         playerMoney = profileMoney
        --     }
        -- )
    end
)


RegisterNetEvent('qb-vehicleshop.spawnVehicle')
AddEventHandler('qb-vehicleshop.spawnVehicle', function(model, plate)
    local hash = GetHashKey(model)

    lastPlayerCoords = GetEntityCoords(PlayerPedId())

    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(10)
        end
    end

    local vehicleBuy = CreateVehicle(hash, Config.Shops[vehcategory].setupStore.spawnPurchaseLoc, 1, 1)
    vehcategory = nil
    SetPedIntoVehicle(PlayerPedId(), vehicleBuy, -1)
    SetVehicleNumberPlateText(vehicleBuy, plate)
    exports[Config.FuelSystem]:SetFuel(vehicleBuy, 100)
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicleBuy))

    SetVehicleCustomPrimaryColour(vehicleBuy,  math.ceil(rgbColorSelected[1]), math.ceil(rgbColorSelected[2]), math.ceil(rgbColorSelected[3]))
    SetVehicleCustomSecondaryColour(vehicleBuy,  math.ceil(rgbSecondaryColorSelected[1]), math.ceil(rgbSecondaryColorSelected[2]), math.ceil(rgbSecondaryColorSelected[3]))
end)




RegisterNUICallback(
    "TestDrive",
    function(data, cb)
        local testDriveAllowed = false
        if Config.Shops[vehcategory].setupStore.allowTestDrive then
            testDriveAllowed = true
        end

        if testDriveAllowed then
            startCountDown = true

            local hash = GetHashKey(data.vehicleModel)

            lastPlayerCoords = GetEntityCoords(PlayerPedId())

            if not HasModelLoaded(hash) then
                RequestModel(hash)
                while not HasModelLoaded(hash) do
                    Citizen.Wait(10)
                end
            end

            if testDriveEntity ~= nil then
                DeleteEntity(testDriveEntity)
            end

            testDriveEntity = CreateVehicle(hash, Config.Shops[vehcategory].setupStore.allowTestDrive.spawnTestLoc, 1, 1)
            SetPedIntoVehicle(PlayerPedId(), testDriveEntity, -1)
            exports[Config.FuelSystem]:SetFuel(testDriveEntity, 100)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(testDriveEntity))
            local timeGG = GetGameTimer()


            SetVehicleCustomPrimaryColour(testDriveEntity,  math.ceil(rgbColorSelected[1]), math.ceil(rgbColorSelected[2]), math.ceil(rgbColorSelected[3]))
            SetVehicleCustomSecondaryColour(testDriveEntity,  math.ceil(rgbSecondaryColorSelected[1]), math.ceil(rgbSecondaryColorSelected[2]), math.ceil(rgbSecondaryColorSelected[3]))

            CloseNui()

            while startCountDown do
                local countTime
                Citizen.Wait(1)
                if GetGameTimer() < timeGG+tonumber(1000*Config.Shops[vehcategory].setupStore.allowTestDrive.testDriveTime) then
                    local secondsLeft = GetGameTimer() - timeGG
                    drawTxt('Test Drive Time Remaining: ' .. math.ceil(Config.Shops[vehcategory].setupStore.allowTestDrive.testDriveTime - secondsLeft/1000),4,0.5,0.93,0.50,255,255,255,180)
                else
                    DeleteEntity(testDriveEntity)
                    SetEntityCoords(PlayerPedId(), lastPlayerCoords)
                    startCountDown = false
                end
            end
        end
    end
)


RegisterNUICallback(
    "menuSelected",
    function(data, cb)
        local categoryVehicles

        local playerIdx = GetPlayerFromServerId(source)
        local ped = GetPlayerPed(playerIdx)

        if data.menuId ~= 'all' then
            categoryVehicles = vehiclesTable[data.menuId]
        else
            SendNUIMessage(
                {
                    data = vehiclesTable,
                    type = "display",
                    playerName = GetPlayerName(ped)
                }
            )
            return
        end

        SendNUIMessage(
            {
                data = categoryVehicles,
                type = "menu"
            }
        )
    end
)


RegisterNUICallback(
    "Close",
    function(data, cb)
        CloseNui()
    end
)

function CloseNui()
    SendNUIMessage(
        {
            type = "hide"
        }
    )
    SetNuiFocus(false, false)
    if inTheShop then
        if lastSelectedVehicleEntity ~= nil then
            DeleteVehicle(lastSelectedVehicleEntity)
        end
        RenderScriptCams(false)
        DestroyAllCams(true)
        SetFocusEntity(GetPlayerPed(PlayerId()))
        DisplayHud(true)
        DisplayRadar(true)
    end
    inTheShop = false
    vehiclesTable = {}
    provisoryObject = {}
end


function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

----------------------------------------------------------------------

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createVariables() -- blips/showVehicles
    createInteractions()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deleteVariables()
    deleteInteractions()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createVariables() -- blips/showVehicles
    createInteractions()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    deleteVariables()
    deleteInteractions()
end)
