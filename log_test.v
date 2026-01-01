module log

import json
import os
import time

fn test_log() {
	trace("trace")
	debug("debug")
	info("info")
	warn("warn")
	error("error")
	fatal("fatal")
}

fn test_load_config() {
	load_config("log_config.json")
	trace("trace")
	debug("debug")
	info("info")
	warn("warn")
	error("error")
	fatal("fatal")
	time.sleep(5 * time.second)
}

fn test_config() {
	str := os.read_file("log_config.json") or {panic(err)}
	config :=json.decode(LogConfig, str) or {panic(err)}
	println(config)
}

struct TestStruct {
mut:
	arr []string
	m map[string]string
}

fn test_spawn() {
	mut ts := TestStruct{
		arr: ['a', 'b', 'c']
		m: {
			'k1': 'v1'
			'k2': 'v2'
		}
	}
	spawn fn [mut ts] () {
		println(ts)
		time.sleep(1 * time.second)
		println(ts)
		for i in 0 .. ts.arr.len {
			ts.arr[i] = ts.arr[i].to_upper()
		}
		for k, v in ts.m {
			ts.m[k] = v.to_upper()
		}
	}()
	ts.arr << 'd'
	ts.m['k3'] = 'v3'
	println(ts)
	time.sleep(2 * time.second)
	println(ts)
}