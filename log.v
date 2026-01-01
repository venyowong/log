@[has_globals]
module log

import json
import os
import regex
import time

#flag -I.
#flag @VMODROOT/log.c
#include "log.h"

__global (
	dt_re regex.RE
	files map[int]string
	http_sinks []HttpSink
)

@[typedef]
pub struct C.log_Event {
pub mut:
	file &char
	fmt &char
	level int
	line int
	time &C.tm
	udata voidptr
}

pub type LogEvent = C.log_Event

pub enum LogLevel as u8 {
	trace
	debug
	info
	warn
	error
	fatal
}

type LogFn = fn (ev &LogEvent)

type LockFn = fn (l bool, udata voidptr)

fn C.log_add_callback(f LogFn, udata voidptr, level int) int

fn C.log_add_fp(fp &C.FILE, level int)

fn C.log_debug(...voidptr)

fn C.log_error(...voidptr)

fn C.log_fatal(...voidptr)

fn C.log_info(...voidptr)

fn C.log_log(level int, file &char, line int, fmt &char, ...voidptr)

fn C.log_set_level(level int)

fn C.log_set_lock(f LockFn, udata voidptr)

fn C.log_set_quiet(enable bool)

fn C.log_trace(args ...voidptr)

fn C.log_warn(args ...voidptr)

fn init () {
	dt_re = regex.regex_opt(".*(?P<dt>\\{dt:{0,1}(?P<fmt>[^}]*)\\}).*") or {panic(err)}
	C.log_add_callback(log_to_file, unsafe{nil}, 0)
	C.log_add_callback(log_to_http, unsafe{nil}, 0)
}

pub fn debug(msg string) {
	C.log_debug(msg.str)
}

pub fn disable_stdout() {
	C.log_set_quiet(true)
}

pub fn enable_stdout(level LogLevel) {
	C.log_set_quiet(false)
	C.log_set_level(int(level))
}

pub fn error(msg string) {
	C.log_error(msg.str)
}

pub fn fatal(msg string) {
	C.log_fatal(msg.str)
}

pub fn info(msg string) {
	C.log_info(msg.str)
}

pub fn load_config(path string) {
	str := os.read_file(path) or {return}
	config :=json.decode(LogConfig, str) or {panic(err)}
	if config.stdout.enabled {
		enable_stdout(config.stdout.level)
	} else {
		disable_stdout()
	}
	for fc in config.file {
		add_file(fc.path, fc.level)
	}
	if config.talog.url.len > 0 && config.talog.app.len > 0 {
		add_talog(config.talog.url, config.talog.app, config.talog.index,
			config.talog.level, config.talog.max_bulk)
	}
}

pub fn trace(msg string) {
	C.log_trace(msg.str)
}

pub fn warn(msg string) {
	C.log_warn(msg.str)
}

fn convert_time(tm_ptr &C.tm) time.Time {
	if tm_ptr == C.NULL {
		return time.Time{}
	}
	return time.Time{
		year:  tm_ptr.tm_year + 1900
		month: tm_ptr.tm_mon + 1
		day:   tm_ptr.tm_mday
		hour:  tm_ptr.tm_hour
		minute:   tm_ptr.tm_min
		second:   tm_ptr.tm_sec
	}
}