-- Libs
local constants = require('constants')
local timers = require('util.timers')
local errorlib = require('util.errorlib')

-- Define the gamemode
local Gamemode = {}

-- Init gamemode
function Gamemode:init(ply, hmd, hand0, hand1)
    -- Ensure we only init once
    if self.doneInit then return end
    self.doneInit = true

    -- Store references
    self.ply = ply
    self.hmd = hmd
    self.hand0 = hand0
    self.hand1 = hand1

    -- Store the teleport devices
    self.tpDevice0 = hand0:GetHandAttachment()
    self.tpDevice1 = hand1:GetHandAttachment()

    -- Init buttson
    self:initButtons()

    -- Init Inventory
    self:initInventory()

    --print(self.tpDevice0)

    --DeepPrintTable(getmetatable(self.tpDevice0))

    -- Try out a sword
    --self:swordTest()

    -- Start thinking
    timers:setTimeout('onThink', 0.1, self)

    -- All good
    errorlib:notify('Gamemode has started successfully!')
end

-- Gamemode think function
function Gamemode:onThink()
    -- Process game stuff
    self:handleButtons()

    -- Run again after a short delay
    return 0.1
end

-- Init buttons
function Gamemode:initButtons()
    -- Stored which buttons were pressed last frame
    self.buttonPressed = {}

    -- How long is considered a long hold
    self.longHold = 0.5

    -- Contains all buttons for hand0

end

-- Handles VR button presses
function Gamemode:handleButtons()
    -- Grab useful variables
    local ply = self.ply

    -- Process both hands
    for handID=0,1 do
        local gripButtonID = constants['hand'..handID..'_grip']

        local now = Time()

        -- Is the grip button pressed?
        if ply:IsVRControllerButtonPressed(gripButtonID) then
            -- Grip is currently pressed
            if not self.buttonPressed[gripButtonID] then
                self.buttonPressed[gripButtonID] = Time()
            else
                -- Check how long we were holding it
                local timeHeld = now - self.buttonPressed[gripButtonID]
                if timeHeld >= self.longHold then
                    --print('Long hold! ' .. handID)
                end
            end
        else
            -- Were we previously holding the button?
            if self.buttonPressed[gripButtonID] then
                -- Check how long we were holding it
                local timeHeld = now - self.buttonPressed[gripButtonID]
                if timeHeld < self.longHold then
                    --print('tap ' .. handID)
                    self:handGotoNextItem(handID)
                end

                -- Reset that it is no longer pressed
                self.buttonPressed[gripButtonID] = nil
            end
        end
    end
end

-- Init inventory system
function Gamemode:initInventory()
    self.hand0Item = constants.item_nothing
    self.hand1Item = constants.item_nothing

    -- Defines all items that can be gotten
    self.itemOrderList = {
        [1] = constants.item_nothing,
        [2] = constants.item_sword
    }

    -- Define the reverse lookup table
    self.reverseItemOrder = {}
    for posNum, itemID in pairs(self.itemOrderList) do
        self.reverseItemOrder[itemID] = posNum
    end

    -- Defines which items we actually own
    self.myItems = {}

    -- DEBUG: Give all items
    for posNum, itemID in pairs(self.itemOrderList) do
        self.myItems[itemID] = true
    end
end

-- Go to the next item in a hand
function Gamemode:handGotoNextItem(handID)
    local hand = self['hand' .. handID]
    if not hand then
        errorlib:error('Failed to find hand ' .. handID)
        return
    end

    -- Grab the itemID that is currently in the hand
    local currentItemID = self['hand' .. handID .. 'Item']

    -- Find it's position in the item order list
    local itemOrder = self.reverseItemOrder[currentItemID]

    -- Find the next item
    local nextItemID = itemOrder + 1
    while true do
        local tempItemID = self.itemOrderList[nextItemID]
        if tempItemID then
            if self.myItems[tempItemID] then
                -- Found the next item
                break
            else
                nextItemID = nextItemID + 1
            end
        else
            nextItemID = 1
        end
    end

    -- Put this item into our hand
    self:setHandItem(handID, nextItemID)
end

-- Sets the item that is in a hand
-- This assumes you own the item, check this elsewhere
function Gamemode:setHandItem(handID, itemID)
    local hand = self['hand' .. handID]
    if not hand then
        errorlib:error('Failed to find hand ' .. handID)
        return
    end

    -- Is this a new item?
    if self['hand' .. handID .. 'Item'] == itemID then
        -- Already got this item in this hand
        return
    end

    -- Destroy old item
    local oldItem = self['entityItem' .. handID]
    if oldItem then
        oldItem:RemoveSelf()
        self['entityItem' .. handID] = nil
    end

    -- Create the new item
    local item = self:createHandItem(itemID)

    if item then
        -- Store it
        self['entityItem' .. handID] = item

        local angles = hand:GetAnglesAsVector()

        -- Attach
        item:SetOrigin(hand:GetOrigin())
        item:SetParent(hand, '')
        item:SetAngles(angles.x, angles.y, angles.z)
    end

    -- Store the ID that is now in our hand
    self['hand' .. handID .. 'Item'] = itemID
end

-- Creates an instance of a given item
function Gamemode:createHandItem(itemID)
    if itemID == constants.item_sword then
        local ent = Entities:CreateByClassname('prop_physics')
        ent:SetModel('models/weapons/sword1/sword1.vmdl')

        return ent
    end
end

-- Sword debug function
function Gamemode:swordTest()
    -- Grab hand
    local hand0 = self.hand0
    local angles = hand0:GetAnglesAsVector()

    --self.tpDevice0:SetModel('models/weapons/sword1/sword1.vmdl')
    --self.hand0:SetModel('models/weapons/sword1/sword1.vmdl')

    -- Remove old item
    --hand0:SetHandAttachment(nil)

    -- Create the sword
    --[[local ent = Entities:CreateByClassname('prop_physics')
    ent:SetModel('models/weapons/sword1/sword1.vmdl')
    ent:SetOrigin(hand0:GetOrigin())
    ent:SetParent(hand0, '')
    ent:SetAngles(angles.x, angles.y, angles.z)]]
end

-- Export the gamemode
return Gamemode