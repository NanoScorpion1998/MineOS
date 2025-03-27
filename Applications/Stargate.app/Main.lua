local filesystem = require("Filesystem")
local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

if not component.isAvailable("stargate") then
    GUI.alert(system.getLocalization(filesystem.path(system.getCurrentScript()) .. "Localizations/")["alert_stargate_required"])
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

local function updateButtons()
    workspace.removeContactButton.disabled = #contacts == 0
    workspace.connectContactButton.disabled = #contacts == 0
end

local function updateContacts()
    workspace.contactsComboBox:clear()
    if #contacts == 0 then
        workspace.contactsComboBox:addItem(localization["no_contacts_found"])
    else
        for i = 1, #contacts do
            workspace.contactsComboBox:addItem(contacts[i].name)
        end
    end
end

local function dial(address)
    local success, reason = stargate.dial(address)
    if success then
        workspace.fuelProgressBar.value = math.ceil(stargate.energyToDial(address) / stargate.energyAvailable() * 100)
        workspace:draw()
    else
        GUI.alert(localization["failed_to_dial"] .. " " .. tostring(reason))
    end
end

---------------------------------------------------------------------------------------------

workspace:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, localization["energy_to_dial"]))
    :setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
workspace.fuelProgressBar = workspace:addChild(GUI.progressBar(x, y, width, 0xBBBBBB, 0x0, 0xEEEEEE, 100, true, true, "", "%")); y = y + 3
workspace.exitButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, localization["exit"])); y = y + 4
workspace.exitButton.onTouch = function()
    workspace:stop()
end

workspace:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, localization["contacts"]))
    :setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
workspace.contactsComboBox = workspace:addChild(GUI.comboBox(x, y, width, 3, 0x3C3C3C, 0xBBBBBB, 0x555555, 0x888888)); y = y + 4

workspace.addContactButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, localization["add_contact"])); y = y + 3
workspace.addContactButton.onTouch = function()
    local container = GUI.addBackgroundContainer(workspace, true, true, localization["add_contact"])
    local input1 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, localization["name"]))
    local input2 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, localization["address"]))

    container.panel.eventHandler = function(workspace, object, e1)
        if e1 == "touch" then
            if input1.text and input2.text then
                local exists = false
                for i = 1, #contacts do
                    if contacts[i].address == input2.text then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(contacts, {name = input1.text, address = input2.text})
                    updateContacts()
                    saveContacts()
                    updateButtons()
                end
                container:remove()
                workspace:draw()
            end
        end
    end

    workspace:draw()
end

workspace.removeContactButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, localization["remove_contact"])); y = y + 4
workspace.removeContactButton.onTouch = function()
    if #contacts > 0 then
        table.remove(contacts, workspace.contactsComboBox.selectedItem)
        updateContacts()
        saveContacts()
        updateButtons()
        workspace:draw()
    end
end

workspace.eventHandler = function(workspace, object, e1, e2, e3, e4)
    if e1 == "sgMessageReceived" then
        GUI.alert(localization["message"] .. ": " .. e3)
    elseif e1 == "sgChevronEngaged" then
        workspace.chevrons[e3].isActivated = true
        workspace:draw()
    end
end

loadContacts()
updateContacts()
updateButtons()
workspace:draw()
workspace:start()
