local cjson = require "cjson";
local ups = ngx.shared.upstreams;
local servers = {}
for _,v in pairs(ups:get_keys(0)) do
   servers[v] = ups:get(v)
end
ngx.say(cjson.encode({code="A00001", msg="OK", data=servers}))
