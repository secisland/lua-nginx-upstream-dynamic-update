local cjson = require "cjson";
local upstream = require "ngx.upstream"
local ups = ngx.shared.upstreams;

local get_upstreams = upstream.get_upstreams
local all_ups = upstream.get_upstreams()

local op = ngx.req.get_uri_args()["op"];
local server = ngx.req.get_uri_args()["server"];

if op == nil or server == nil then
    ngx.say("usage: /ups?op=add&server=192.168.56.101:8080");
    return
end

function down_server(upstream_name,server)
    local ret = false
    local perrs = upstream.get_servers(upstream_name)
    local avail = #perrs

    for i = 1, #perrs do
        local peer = perrs[i]
        local isdown = ups:get(peer["name"])
        if isdown == 1 then
            avail = avail - 1
            ngx.log(ngx.ERR,"## peer.down: true  ups: "..upstream_name.." peer.name: "..peer.name.." server: "..server.." avail: "..avail)
        end
        if peer.name == server then
            ret = true
        end
    end
    if not ret then
        avail = 2
    end
    return avail
end

if op == "add" then
    ups:set(server,0)
    ngx.say(cjson.encode({code="A00001", msg="add a server success.",data={server}}))
elseif op == "del" then
    local isdown = ups:get(server)
    if isdown == 1 then
        ngx.say(cjson.encode({code="A00001", msg="del a server success.",data={server}}))
        return
    end
    for _,u in ipairs(all_ups) do
        local srvs = upstream.get_servers(u)
        for i,peer in ipairs(srvs) do
            local down_svc = down_server(u,server)
            ngx.log(ngx.ERR,"## down_svc: "..down_svc.." upstream: "..u.." server: "..server)
            if down_svc < 2 then
                ngx.log(ngx.ERR,u.." You cat not set peer down: "..peer["name"])
                ngx.say(cjson.encode({code="E00001", msg="You cat not set peer down: "..peer["name"],data={peer["name"]}}))
                return
            end
        end
    end

    ups:set(server,1)
    ngx.say(cjson.encode({code="A00001", msg="del a server success.",data={server}}))
    return
else
    ngx.say(cjson.encode({code="E00001", msg="do none.",data={}}))
    return
end
