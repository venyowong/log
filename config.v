module log

pub struct FileConfig {
	path string
	level LogLevel
}

pub struct LogConfig {
	stdout StdoutConfig
	file []FileConfig
	talog TalogConfig
}

pub struct StdoutConfig {
	enabled bool
	level LogLevel
}

pub struct TalogConfig {
	url string
	app string
	index string = "json_log"
	level LogLevel = .info
	max_bulk int = 50
}