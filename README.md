# lua-nginx-upstream-dynamic-update
动态更新nginx upstream服务节点

# 运行环境
本脚本可运行于 openresty-1.13.6.2。其他版本未测试，请检查是否存在 cjson, ngx.upstream 模块。

# 快速开始

本脚本主要用于动态更新 nginx upstream 中的 server，删除或添加 server 时立即生效，不需要 reload nginx。（限制条件：server 必须是 nginx.conf 配置文件中已经配置到 upstream 中的 server，不支持新增 server 到 upstream.）


以下是一个nginx.conf配置的例子：

    http {
        ... ...

        lua_shared_dict upstreams 10m;

        upstream local {
            server 192.168.56.101:8080;
            server 192.168.56.101:8081 backup;
            server 192.168.56.101:8082;
            balancer_by_lua_file "./ngx_lua/upstream.lua";
            check interval=3000 rise=2 fall=5 timeout=1000;
        }

        # 在配置server backup及健康检查时，也一样支持
        # upstream local {
        #     server 192.168.56.101:8080;
        #     server 192.168.56.101:8081 backup;
        #     server 192.168.56.101:8082;
        #     balancer_by_lua_file "./ngx_lua/upstream.lua";
        #     check interval=3000 rise=2 fall=5 timeout=1000;
        # }

        server {
            ... ...

            location /local{
                proxy_pass http://local;
            }

            location = /ups {
                default_type  text/plain;
                content_by_lua_file "./ngx_lua/upsops.lua";
            }

            location = /ups/check {
                default_type  text/plain;
                content_by_lua_file "./ngx_lua/srvcheck.lua";
            }
        }
    }


## 1、删除一个server节点 

如果upstream中只有一个节点，或者通过本脚本删除upstream中的server节点只剩下一个节点时，本脚本会拒绝对此节点进行删除操作，保证 upstream 必须有可用的服务节点。

    PUT请求：http://192.168.56.101/ups?op=del&server=192.168.56.101:8080

    请求返回：
        {"msg":"del a server success.","data":["192.168.56.101:8080"],"code":"A00001"}

    data 为此次操作的目标 server。


## 2、添加一个服务节点

    PUT请求：http://192.168.56.101/ups?op=add&server=192.168.56.101:8080

    请求返回：
        {"msg":"add a server success.","data":["192.168.56.101:8080"],"code":"A00001"}

    data 为此次操作的目标 server。


## 3、检查服务节点状态
如果返回json的数据中 data 为空，说明 add server 或 del server请求已经生效，upstream已处理正常状态；如果 data 不为空，说明还没有客户端请求对应的 upstream ，只要有客户端请求到 upstream 就会生效，这不影响upstream保证只少有一个服务节点高可用。

    PUT请求：http://192.168.56.101/ups/check

    请求返回：
        {"msg":"OK","data":{"192.168.56.101:8080":1},"code":"A00001"}

    data 中 server 的值为1表示要删除的节点，值为0表示要恢复的节点；data 为空表示 upstream 处理正常状态。
