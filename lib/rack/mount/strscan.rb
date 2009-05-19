require 'strscan'
# 1.9 bug: Causes infinite loop unless it finds StringScanner
# constant under Rack::Mount namespace
Rack::Mount::StringScanner = StringScanner
