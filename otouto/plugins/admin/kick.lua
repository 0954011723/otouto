local bindings = require('otouto.bindings')
local utilities = require('otouto.utilities')
local autils = require('otouto.autils')

local P = {}

function P:init(bot)
    self.triggers = utilities.triggers(bot.info.username, bot.config.cmd_pat)
        :t('kick', true):t('tempban', true).table
    self.command = 'kick'
    self.doc = "Removes a user or users from the group. A reason can be given \z
on a new line. Example:\
    /kick @examplus 5554321\
    Bad jokes."
    self.privilege = 2
    self.administration = true
    self.targeting = true
    self.duration = true
end

function P:action(bot, msg, _group, _user)
    local targets, reason, duration = autils.targets(bot, msg)
    if duration and (duration > 366*24*60*60 or duration < 30) then
        duration = nil
    end

    local out_str, log_str
    if duration then
        out_str = ' has been banned for ' ..utilities.tiem.format(duration)..'.'
        log_str = 'Banned for ' .. utilities.tiem.format(duration)
    else
        out_str = ' has been kicked.'
        log_str = 'Kicked'
    end

    local output = {}
    local kicked_users = {}

    if targets then
        for _, id in ipairs(targets) do
            if tonumber(id) then
                local name = utilities.lookup_name(bot, id)
                if autils.rank(bot, id, msg.chat.id) > 2 then
                    table.insert(output, name .. ' is too privileged to be kicked.')
                else
                    bindings.kickChatMember{
                        chat_id = msg.chat.id,
                        user_id = id,
                        until_date = duration and duration + os.time() or 35
                    }
                    table.insert(output, name .. out_str)
                    table.insert(kicked_users, id)
                end
            else
                table.insert(output, id)
            end
        end
    else
        table.insert(output, bot.config.errors.specify_targets)
    end

    utilities.send_reply(msg, table.concat(output, '\n'), 'html')
    if #kicked_users > 0 then
        autils.log(bot, {
            chat_id = msg.chat.id,
            targets = kicked_users,
            action = log_str,
            source_id = msg.from.id,
            reason = reason
        })
    end
end

return P