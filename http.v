module log

import net.http
import sync
import time
import x.json2

@[heap]
pub struct HttpSink {
	ev_chan chan LogEvent
pub:
	app string
	data_adaptor fn (events []LogEvent) string @[required]
	header http.Header
	index string
	level LogLevel = .info
	max_bulk int = 1
	method http.Method = .post
	url string
	user_agent string = 'v.http'
}

pub fn add_http(mut sink HttpSink) {
	spawn sink.loop()
	http_sinks << sink
}

pub fn add_talog(url string, app string, index string, level LogLevel, max_bulk int) {
	format_data := fn [app, index] (events []LogEvent) string {
		mut list := []json2.Any{}
		mut tags := []json2.Any{}
		app_tag := {
			"label": json2.Any("app")
			"value": json2.Any(app)
		}
		tags << app_tag
		for ev in events {
			level := unsafe{LogLevel(ev.level)}
			t := convert_time(ev.time)
			l := {
				"name": json2.Any(index)
				"log_type": json2.Any("json")
				"log": json2.Any(json2.encode({
					"time": t.custom_format("YYYY-MM-DD HH:mm:ss")
					"level": level.str()
					"msg": unsafe{cstring_to_vstring(ev.fmt)}
				}))
				"parse_log": json2.Any(true)
				"tags": json2.Any(tags)
			}
			list << l
		}
		return json2.encode(list)
	}
	mut sink := HttpSink {
		app: app
		data_adaptor: format_data
		header: http.new_header(key: .content_type, value: 'application/json')
		index: index
		level: level
		max_bulk: max_bulk
		url: "${url}/index/logs2"
	}
	add_http(mut sink)
}

fn (mut s HttpSink) log(ev LogEvent) {
	l := int(s.level)
	if ev.level < l {return}

	s.ev_chan <- ev
}

fn (mut s HttpSink) loop() {
	mut events := []LogEvent{}
	for {
		select {
			ev := <-s.ev_chan {
				events << ev
				if events.len >= s.max_bulk {
					data := s.data_adaptor(events)
					events.clear()
					s.send(data)
				}
			}
			5 * time.second {
				if events.len > 0 {
					data := s.data_adaptor(events)
					events.clear()
					s.send(data)
				}
			}
		}
	}
}

fn log_to_http (ev &LogEvent) {
	for mut sink in http_sinks {
		sink.log(ev)
	}
}

fn (s HttpSink) send(data string) {
	http.fetch(
		data: data
		header: s.header
		method: s.method
		url: s.url
		user_agent: s.user_agent
	) or {
		println(err)
		return
	}
}