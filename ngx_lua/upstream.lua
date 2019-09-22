local ups = ngx.shared.upstreams;
local upstream = require "ngx.upstream"
local get_servers = upstream.get_servers
local set_peer_down = upstream.set_peer_down

local curr_ups = upstream.current_upstream_name()
local srvs = get_servers(curr_ups)

-- 摘除主节点的服务节点，传入的addr对应于主节点的name属性
function set_primary_server_down(addr)
    local peers = upstream.get_primary_peers(curr_ups)
    for i = 1, #peers do
        local peer = peers[i]
        if peer.name == addr then
            local ok, err = set_peer_down(curr_ups,false,peer.id,true)
            if not ok then
                ngx.log(ngx.ERR,curr_ups.." failed to set peer down: "..err)
                return false
            end
            return true
        end
    end
    return false
end

-- 摘除备份节点的服务节点，传入的addr对应于备份节点的name属性
function set_backup_server_down(addr)
    local peers = upstream.get_backup_peers(curr_ups)
    for i = 1, #peers do
        local peer = peers[i]
        if peer.name == addr then
            local ok, err = set_peer_down(curr_ups,true,peer.id,true)
            if not ok then
                ngx.log(ngx.ERR,curr_ups.." failed to set peer down: "..err)
                return false
            end
            return true
        end
    end
    return false
end

-- 恢复主节点的服务节点，传入的addr对应于主节点的name属性
function set_primary_server_up(addr)
    local peers = upstream.get_primary_peers(curr_ups)
    for i = 1, #peers do
        local peer = peers[i]
        if peer.name == addr then
            local ok, err = set_peer_down(curr_ups,false,peer.id,false)
            if not ok then
                ngx.log(ngx.ERR,curr_ups.." failed to set peer down: "..err)
                return false
            end
            return true
        end
    end
    return false
end

-- 恢复备份节点的服务节点，传入的addr对应于备份节点的name属性
function set_backup_server_up(addr)
    local peers = upstream.get_backup_peers(curr_ups)
    for i = 1, #peers do
        local peer = peers[i]
        if peer.name == addr then
            local ok, err = set_peer_down(curr_ups,true,peer.id,false)
            if not ok then
                ngx.log(ngx.ERR,curr_ups.." failed to set peer down: "..err)
                return false
            end
            return true
        end
    end
    return false
end

for i,peer in ipairs(srvs) do
    local isdown = ups:get(peer["name"])
    -- 摘除服务节点
    if isdown == 1 then
        if peer.backup == nil then
            -- peer.addr: socket 地址，可能是Lua字符串或lua字符串的数组.
            local addr = peer.addr
            if type(addr) == "table" then
                for _,v in ipairs(addr) do
                    if set_primary_server_down(v) == true then
                        ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set down success.")
                    else
                        ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set down failed.")
                    end
                end
            else
                if set_primary_server_down(addr) == true then
                    ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set down success.")
                else
                    ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set down failed.")
                end
            end
        elseif peer.backup == true then
            local addr = peer.addr
            if type(addr) == "table" then
                for _,v in ipairs(addr) do
                    if set_backup_server_down(v) == true then
                        ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set down success.")
                    else
                        ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set down failed.")
                    end
                end
            else
                if set_backup_server_down(addr) == true then
                    ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set down success.")
                else
                    ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set down failed.")
                end
            end
        end
    -- 恢复服务节点
    elseif isdown == 0 then
        if peer.backup == nil then
            local addr = peer.addr
            if type(addr) == "table" then
                for _,v in ipairs(addr) do
                    if set_primary_server_up(v) == true then
                        ups:delete(peer["name"])
                        ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set up success.")
                    else
                        ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set up failed.")
                    end
                end
            else
                if set_primary_server_up(addr) == true then
                    ups:delete(peer["name"])
                    ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set up success.")
                else
                    ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set up failed.")
                end
            end
        elseif peer.backup == true then
            local addr = peer.addr
            if type(addr) == "table" then
                for _,v in ipairs(addr) do
                    if set_backup_server_up(v) == true then
                        ups:delete(peer["name"])
                        ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set up success.")
                    else
                        ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set up failed.")
                    end
                end
            else
                if set_backup_server_up(addr) == true then
                    ups:delete(peer["name"])
                    ngx.log(ngx.INFO,curr_ups.." "..peer["name"].." set up success.")
                else
                    ngx.log(ngx.ERR,curr_ups.." "..peer["name"].." set up failed.")
                end
            end
        end
    end
end
