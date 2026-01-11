# log

vlang 日志库

## 为什么

另外开发一个日志库，最主要的原因就是官方的日志库功能较为简陋，不够灵活

## log.c 底层库

`venyowong.log` 基于 [log.c](https://github.com/rxi/log.c) 的基础上进行开发，继承了简洁、够用的风格

## stdout

`venyowong.log` 继续沿用了 `log.c` 的 stdout

### log.disable_stdout

禁用 stdout

### log.enable_stdout(level LogLevel)

启用 stdout，并且只有大于等于指定等级的日志才会被输出

## file

`venyowong.log` 并未直接使用 `log.c` 的 `log_add_fp` 来添加日志文件，而是基于 `venyowong.file` 将日志输出到文件中

### log.add_file(path string, level LogLevel)

大于等于指定等级的日志将会被输出到指定文件中，path 支持随时间滚动，格式为：`/path/to/log-{dt:YYYYMMDDHH}.txt`

## http

`venyowong.log` 支持通过 http 请求将日志储存到服务端

### log.add_http(mut sink HttpSink)

只需要构建 `HttpSink` 调用 `log.add_http` 函数，`venyowong.log` 就会按照配置的方式将日志批量发送到服务端

```
pub struct HttpSink {
pub:
	data_adaptor fn (events []LogEvent) string @[required] // convert LogEvent array to request data
	header http.Header // custom http request header
	level LogLevel = .info // lowest log level
	max_bulk int = 1 // how many logs can be uploaded in bulk at once
	method http.Method = .post // http request method
	url string // host url
	user_agent string = 'v.http' // custom http request user_agent
}
```

### log.add_talog(url string, app string, index string, level LogLevel, max_bulk int)

`venyowong.log` 支持将日志发送到 talog 服务端

1. 创建索引映射关系

    ```
    POST http://127.0.0.1:26382/index/mapping
    content-type: application/json

    {
        "name": "json_log",
        "log_type": "json",
        "fields": [
            {
                "name": "app",
                "tag_name": "app",
                "type": "string"
            },
            {
                "name": "time",
                "tag_name": "time",
                "type": "time",
                "index_format": "YYYYMMDD",
                "parse_format": "YYYY-MM-DD HH:mm:ss"
            },
            {
                "name": "level",
                "tag_name": "level",
                "type": "string"
            },
            {
                "name": "msg",
                "type": "string"
            }
        ]
    }
    ```
2. 在代码中注册

    ```
    log.add_talog(
        "http://127.0.0.1:26382",
        "application name",
        "json_log",
        .warn,
        50
    )
    ```

## 配置

`venyowong.log` 支持读取 json 配置文件，调用 `log.load_config("log_config.json")`

```
{
	"stdout": {
		"enabled": true,
		"level": "trace"
	},
	"file": [
		{
			"path": "logs/info-{dt:YYYYMMDDHH}.txt",
			"level": "info"
		},
		{
			"path": "logs/error-{dt:YYYYMMDD}.txt",
			"level": "error"
		}
	],
	"talog": {
		"url": "http://127.0.0.1:26382",
		"app": "test",
		"index": "json_log",
		"level": "warn",
		"max_bulk": 50
	}
}
```