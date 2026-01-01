module log

import venyowong.file

/*
path: /path/to/log-{dt:YYYYMMDDHH}.txt
*/
pub fn add_file(path string, level LogLevel) {
	$for lvl in LogLevel.values {
		l1 := int(lvl.value)
		l2 := int(level)
		if l1 >= l2 {
			files[l1] = path
		}
	}
}

fn log_to_file (ev &LogEvent) {
	level := unsafe{LogLevel(ev.level)}
	t := convert_time(ev.time)
	mut f := files[ev.level] or {return}
	s, _ := dt_re.match_string(f)
	if s >= 0 {
		dt := dt_re.get_group_by_name(f, "dt")
		fmt := dt_re.get_group_by_name(f, "fmt")
		if fmt.len > 0 {
			f = f.replace(dt, t.custom_format(fmt))
		} else {
			f = f.replace(dt, t.custom_format("YYYYMMDD"))
		}
	}
	t_str := t.custom_format("YYYY-MM-DD HH:mm:ss")
	file.append_by_chan(f, "[${t_str}] [${level}] ${unsafe{cstring_to_vstring(ev.fmt)}}")
}