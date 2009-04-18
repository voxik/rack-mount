require 'benchmark'
require 'ruby-prof'
require 'fixtures'

EchoApp = lambda { |env| Rack::Mount::Const::OK_RESPONSE }

def Object.const_missing(name)
  if name.to_s =~ /Controller$/
    EchoApp
  else
    super
  end
end

OUTPUT = File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'performance')

PRINTERS = {
  :flat => RubyProf::FlatPrinter,
  :graph => RubyProf::GraphHtmlPrinter,
  :tree => RubyProf::CallTreePrinter
}

PRINTER_OUTPUT = {
  :flat => 'flat.txt',
  :graph => 'graph.html',
  :tree => 'tree.txt'
}

MEASUREMENTS = {
  :process_time => RubyProf::PROCESS_TIME,
  :memory => RubyProf::MEMORY,
  :objects => RubyProf::ALLOCATIONS
}

def profile(name, measurement, printer, &block)
  FileUtils.mkdir_p(OUTPUT)

  suffix   = PRINTER_OUTPUT[printer]
  filename = "#{OUTPUT}/#{name}_#{measurement}_#{suffix}"

  RubyProf.measure_mode = MEASUREMENTS[measurement]
  printer_klass         = PRINTERS[printer]

  result  = RubyProf.profile(&block)
  printer = printer_klass.new(result)

  File.open(filename, 'wb') do |file|
    printer.print(file, :min_percent => 0.01)
  end
end

def profile_all(name, &block)
  PRINTER_OUTPUT.keys.each do |printer|
    MEASUREMENTS.keys.each do |measurement|
      profile(name, measurement, printer, &block)
    end
  end
end
