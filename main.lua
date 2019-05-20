local assistant = {}

local awful = require('awful')
local naughty = require('naughty')
local gears = require('gears')
local json = require('json')

local pathToNode
local pathToIndex
local keyFilePath

local isRunning = false
local assistantPID = 0
local notObj = nil
local isTextResponse = false

local function stop()
    if not isRunning or assistantPID == 0 then return end
    awful.spawn.easy_async(
        "kill -9 " .. assistantPID,
        function()
            isRunning = false
        end)
end

local function assistantLineCB(line)
    local action
    if line:sub(1,1) ~= "{" then
        action = { type = "needsAuth" }
    else
        action = json.decode(line)
    end
    if not notObj then
        notObj = naughty.notify({
            title = "Google Assistant",
            text = "Initializing...",
            icon = pathToIndex .. "/assistant-logo.png",
            icon_size = 48,
            timeout = 0,
            position = "top_middle",
            destroy = function()
                notObj = nil
                stop()
            end,
            ignore_suspend = true
        })
    end
    if action.type == "needsAuth" then
        naughty.replace_text(notObj, "Not signed in", "Please sign in to use Awesome Assistant.")
    elseif action.type == "ready" then
        naughty.replace_text(notObj, "Listening...", "")
    elseif action.type == "transcription" then
        naughty.replace_text(notObj, (action.done and "Thinking..." or "Listening..."), action.script)
    elseif action.type == "textResponse" then
        if action.text ~= "" then 
            naughty.replace_text(notObj, "The Assistant says:", action.text)
            isTextResponse = true
        end
    elseif action.type == "asstSpeaking" then
        if action.speaking and not isTextResponse then naughty.replace_text(notObj, "The Assistant is speaking.", "") end
        if not action.speaking then isTextResponse = false end
    elseif action.type == "volumeChange" then
        naughty.replace_text(notObj, "Volume", "Volume changed to " .. action.percent .. "%")
        awful.spawn("amixer -D pulse set Master " .. action.percent .. "%")
    elseif action.type == "devAction" then
        naughty.notify {
            text = "Dev action " .. action.action
        }
    elseif action.type == "error" then
        naughty.destroy(notObj, 3)
        naughty.notify {
            title = "Google Assistant Error",
            text = action.error,
            bg = "#ff0000"
        }
        stop()
    end
    if notObj then notObj.timeout = 0 end
end

local function start(tokensPath)
    if isRunning then return end
    isRunning = true
    assistantPID = awful.spawn.with_line_callback(
        pathToNode .. " " .. pathToIndex .. "/index.js " .. keyFilePath .. " " .. tokensPath,
        {
            stdout = assistantLineCB,
            exit = function()
                isRunning = false
                gears.timer.start_new(2, function()
                    if not isRunning then naughty.destroy(notObj, 3) end
                end)
            end
        }
    )
end

--- Start the Google Assistant.
-- Acts like a push-to-talk trigger.
-- Does nothing if not initialized.
-- @param tokens_path Filename to store OAuth tokens. You can change this to use multiple accounts.
assistant.start = function(tokens_path)
    if pathToIndex and pathToNode then
        start(tokens_path)
    end
end



--- Stop the Google Assistant if it is running.
-- Does nothing if the Assistant is already stopped.
assistant.stop = function()
    stop()
end

--- Returns the status of a running Node subprocess.
-- @return Whether the Assistant is running.
-- @return The PID of the Node subprocess or nil.
assistant.is_running = function()
    return isRunning, (isRunning and assistantPID or nil)
end

--- Initializes the assistant.
-- @param node_path Path to the Node.js executable. Can be absolute or relative.
-- @param index_path Path that this repo was cloned to. Must be absolute.
-- @param key_file_path Name of the OAuth secret key file.
assistant.init = function(node_path, index_path, key_file_path)
    pathToNode = node_path
    pathToIndex = index_path
    keyFilePath = key_file_path
end

return assistant