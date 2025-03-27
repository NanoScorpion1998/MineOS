local filesystem = require("Filesystem")
local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

if not component.isAvailable("stargate") then
    GUI.alert("This program requires Stargate from mod \"SGCraft\"")
    return
end

local stargate = component.get("stargate")

---------------------------------------------------------------------------------------------

local resources = filesystem.path(system.getCurrentScript())
local localization = system.getLocalization(resources .. "Localizations/")
local pathToContacts = paths.user.applicationData .. "Stargate/Contacts.cfg"
local contacts = {}
local Ch1Image = image.load(resources .. "Ch1.pic")
local Ch2Image = image.load(resources .. "Ch2.pic")

local workspace = GUI.workspace()

---------------------------------------------------------------------------------------------

local function loadContacts()
    if filesystem.exists(pathToContacts) then
        contacts = filesystem.readTable(pathToContacts)
    end
end

local function saveContacts()
    filesystem.writeTable(pathToContacts, contacts)
end

local function chevronDraw(object)
    screen.drawImage(object.x, object.y, object.isActivated and Ch1Image or Ch2Image)
    return object
end

local function newChevronObject(x, y)
    local object = GUI.object(x, y, 5, 3)

    object.draw = chevronDraw
    object.isActivated = false
    object.text = " "

    return object
end

local function addChevron(x, y)
    table.insert(workspace.chevrons, workspace.chevronsContainer:addChild(newChevronObject(x, y)))
end

local function updateChevrons(state)
    for i = 1, #workspace.chevrons do
        workspace.chevrons[i].isActivated = state
        if not state then workspace.chevrons[i].text = " " end
    end
end

local function updateButtons()
    workspace.removeContactButton.disabled = #contacts == 0
    workspace.connectContactButton.disabled = #contacts == 0
end

local function update()
    local stargateState, irisState, imagePath = stargate.stargateState(), stargate.irisState()
    workspace.irisButton.text = irisState == "Closed" and localization.open_iris or localization.close_iris
    workspace.connectionButton.text = stargateState == "Connected" and localization.disconnect or localization.connect
    workspace.connectedToLabel.text = stargateState == "Connected" and "(Connected to " .. stargate.remoteAddress() .. ")" or "(Not connected)"
    
    if stargateState == "Connected" then
        workspace.connectContactButton.disabled = true
        workspace.messageContactButton.disabled = false

        if irisState == "Closed" then
            imagePath = "OnOn.pic"
        else
            imagePath = "OnOff.pic"
        end
    else
        workspace.connectContactButton.disabled = false
        workspace.messageContactButton.disabled = true

        if irisState == "Closed" then
            imagePath = "OffOn.pic"
        else
            imagePath = "OffOff.pic"
        end
    end

    updateButtons()
    workspace.SGImage.image = image.load(resources .. imagePath)
end

local function updateContacts()
    workspace.contactsComboBox:clear()
    if #contacts == 0 then
        workspace.contactsComboBox:addItem(localization.no_contacts_found)
    else
        for i = 1, #contacts do
            workspace.contactsComboBox:addItem(contacts[i].name)
        end
    end
end

-- Додатковий функціонал, події та UI
loadContacts()
updateContacts()
update()
updateChevrons(stargate.stargateState() == "Connected")

workspace:draw()
workspace:start()
