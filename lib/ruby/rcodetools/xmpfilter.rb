#!/usr/bin/env ruby
# Copyright (c) 2005-2007 Mauricio Fernandez <mfp@acm.org> http://eigenclass.org
#                         rubikitch <rubikitch@ruby-lang.org>
# Use and distribution subject to the terms of the Ruby license.

require 'rcodetools/fork_config'

module Rcodetools

class XMPFilter
  VERSION = "0.7.0"

  MARKER = "!XMP#{Time.new.to_i}_#{Process.pid}_#{rand(1000000)}!"
  XMP_RE = Regexp.new("^" + Regexp.escape(MARKER) + '\[([0-9]+)\] (=>|~>|==>) (.*)')
  VAR = "_xmp_#{Time.new.to_i}_#{Process.pid}_#{rand(1000000)}"
  WARNING_RE = /.*:([0-9]+): warning: (.*)/

  RuntimeData = Struct.new(:results, :exceptions, :bindings)

  INITIALIZE_OPTS = {:interpreter => "ruby", :options => [], :libs => [],
                     :include_paths => [], :warnings => true, 
                     :use_parentheses => true}

  def self.windows?
    /win|mingw/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM
  end

  Interpreter = Struct.new(:options, :execute_method, :accept_debug, :chdir_proc)
  INTERPRETER_RUBY = Interpreter.new(["-w"],
                                     windows? ? :execute_tmpfile : :execute_popen,
                                     true, nil)
  INTERPRETER_RBTEST = Interpreter.new(["-S", "rbtest"], :execute_script, false, nil)
  INTERPRETER_FORK = Interpreter.new(["-S", "rct-fork-client"], :execute_tmpfile, false,
                                     lambda { Fork::chdir_fork_directory })
                                     
  def self.detect_rbtest(code, opts)
    opts[:use_rbtest] ||= (opts[:detect_rbtest] and code =~ /^=begin test./) ? true : false
  end

  # The processor (overridable)
  def self.run(code, opts)
    new(opts).annotate(code)
  end

  def initialize(opts = {})
    options = INITIALIZE_OPTS.merge opts
    @interpreter_info = INTERPRETER_RUBY
    @interpreter = options[:interpreter]
    @options = options[:options]
    @libs = options[:libs]
    @evals = options[:evals] || []
    @include_paths = options[:include_paths]
    @output_stdout = options[:output_stdout]
    @dump = options[:dump]
    @warnings = options[:warnings]
    @parentheses = options[:use_parentheses]
    @ignore_NoMethodError = options[:ignore_NoMethodError]
    test_script = options[:test_script]
    test_method = options[:test_method]
    filename = options[:filename]
    @postfix = ""
    
    initialize_rct_fork if options[:detect_rct_fork]
    initialize_rbtest if options[:use_rbtest]
    initialize_for_test_script test_script, test_method, filename if test_script and !options[:use_rbtest]
  end

  def initialize_rct_fork
    if Fork::run?
      @interpreter_info = INTERPRETER_FORK
    end
  end

  def initialize_rbtest
    @interpreter_info = INTERPRETER_RBTEST
  end

  def initialize_for_test_script(test_script, test_method, filename)
    test_script.replace File.expand_path(test_script)
    filename.replace File.expand_path(filename)
    unless test_script == filename
      basedir = common_path(test_script, filename)
      relative_filename = filename[basedir.length+1 .. -1].sub(%r!^lib/!, '')
      @evals << %Q!$LOADED_FEATURES << #{relative_filename.dump}!
      @evals << %Q!require 'test/unit'!
      @evals << %Q!load #{test_script.dump}!
    end
    test_method = get_test_method_from_lineno(test_script, test_method.to_i) if test_method =~ /^\d/
    @evals << %Q!Test::Unit::AutoRunner.run(false, nil, ["-n", #{test_method.dump}])! if test_method
  end

  def get_test_method_from_lineno(filename, lineno)
    lines = File.readlines(filename)
    (lineno-1).downto(0) do |i|
      if lines[i] =~ /^ *def *(test_[A-Za-z0-9?!_]+)$/
        return $1
      end
    end
    nil
  end

  def common_path(a, b)
    (a.split(File::Separator) & b.split(File::Separator)).join(File::Separator)
  end

  def add_markers(code, min_codeline_size = 50)
    maxlen = code.map{|x| x.size}.max
    maxlen = [min_codeline_size, maxlen + 2].max
    ret = ""
    code.each do |l|
      l = l.chomp.gsub(/ # (=>|!>).*/, "").gsub(/\s*$/, "")
      ret << (l + " " * (maxlen - l.size) + " # =>\n")
    end
    ret
  end

  def annotate(code)
    idx = 0
    newcode = code.gsub(/^(.*) # =>.*/){|l| prepare_line($1, idx += 1) }
    if @dump
      File.open(@dump, "w"){|f| f.puts newcode}
    end
    stdout, stderr = execute(newcode)
    output = stderr.readlines
    runtime_data = extract_data(output)
    idx = 0
    annotated = code.gsub(/^(.*) # =>.*/) do |l|
      expr = $1
      if /^\s*#/ =~ l
        l 
      else
        annotated_line(l, expr, runtime_data, idx += 1)
      end
    end.gsub(/ # !>.*/, '').gsub(/# (>>|~>)[^\n]*\n/m, "");
    ret = final_decoration(annotated, output)
    if @output_stdout and (s = stdout.read) != ""
      ret << s.inject(""){|s,line| s + "# >> #{line}".chomp + "\n" }
    end
    ret
  end

  def annotated_line(line, expression, runtime_data, idx)
    "#{expression} # => " + (runtime_data.results[idx].map{|x| x[1]} || []).join(", ")
  end
  
  def prepare_line_annotation(expr, idx)
    v = "#{VAR}"
    blocal = "__#{VAR}"
    blocal2 = "___#{VAR}"
    oneline_ize(<<-EOF).chomp
#{v} = (#{expr})
$stderr.puts("#{MARKER}[#{idx}] => " + #{v}.class.to_s + " " + #{v}.inspect) || begin
  $stderr.puts local_variables
  local_variables.each{|#{blocal}|
    #{blocal2} = eval(#{blocal})
    if #{v} == #{blocal2} && #{blocal} != %#{expr}.strip
      $stderr.puts("#{MARKER}[#{idx}] ==> " + #{blocal})
    elsif [#{blocal2}] == #{v}
      $stderr.puts("#{MARKER}[#{idx}] ==> [" + #{blocal} + "]")
    end
  }
  nil
rescue Exception
  nil
end || #{v}
    EOF

  end
  alias_method :prepare_line, :prepare_line_annotation

  def execute_tmpfile(code)
    ios = %w[_ stdin stdout stderr]
    stdin, stdout, stderr = (1..3).map do |i|
      fname = if $DEBUG
                "xmpfilter.tmpfile_#{ios[i]}.rb"
              else
                "xmpfilter.tmpfile_#{Process.pid}-#{i}.rb"
              end
      f = File.open(fname, "w+")
      at_exit { f.close unless f.closed?; File.unlink fname unless $DEBUG}
      f
    end
    stdin.puts code
    stdin.close
    exe_line = <<-EOF.map{|l| l.strip}.join(";")
      $stdout.reopen('#{File.expand_path(stdout.path)}', 'w')
      $stderr.reopen('#{File.expand_path(stderr.path)}', 'w')
      $0.replace '#{File.expand_path(stdin.path)}'
      ARGV.replace(#{@options.inspect})
      load #{File.expand_path(stdin.path).inspect}
      #{@evals.join(";")}
    EOF
    debugprint "execute command = #{(interpreter_command << "-e" << exe_line).join ' '}"

    oldpwd = Dir.pwd
    @interpreter_info.chdir_proc and @interpreter_info.chdir_proc.call
    system(*(interpreter_command << "-e" << exe_line))
    Dir.chdir oldpwd
    [stdout, stderr]
  end

  def execute_popen(code)
    require 'open3'
    stdin, stdout, stderr = Open3::popen3(*interpreter_command)
    stdin.puts code
    @evals.each{|x| stdin.puts x } unless @evals.empty?
    stdin.close
    [stdout, stderr]
  end

  def execute_script(code)
    codefile = "xmpfilter.tmpfile_#{Process.pid}.rb"
    File.open(codefile, "w"){|f| f.puts code}
    path = File.expand_path(codefile)
    at_exit { File.unlink path if File.exist? path}
    stdout, stderr = (1..2).map do |i|
      fname = "xmpfilter.tmpfile_#{Process.pid}-#{i}.rb"
      fullname = File.expand_path(fname)
      at_exit { File.unlink fullname if File.exist? fullname}
      File.open(fname, "w+")
    end
    args = *(interpreter_command << %["#{codefile}"] << "2>" << 
             %["#{stderr.path}"] << ">" << %["#{stdout.path}"])
    system(args.join(" "))
    [stdout, stderr]
  end

  def execute(code)
    __send__ @interpreter_info.execute_method, code
  end

  def interpreter_command
    r = [ @interpreter ] + @interpreter_info.options
    r << "-d" if $DEBUG and @interpreter_info.accept_debug
    r << "-I#{@include_paths.join(":")}" unless @include_paths.empty?
    @libs.each{|x| r << "-r#{x}" } unless @libs.empty?
    (r << "-").concat @options unless @options.empty?
    r
  end

  def extract_data(output)
    results = Hash.new{|h,k| h[k] = []}
    exceptions = Hash.new{|h,k| h[k] = []}
    bindings = Hash.new{|h,k| h[k] = []}
    output.grep(XMP_RE).each do |line|
      result_id, op, result = XMP_RE.match(line).captures
      case op
      when "=>"
        klass, value = /(\S+)\s+(.*)/.match(result).captures
        results[result_id.to_i] << [klass, value]
      when "~>"
        exceptions[result_id.to_i] << result
      when "==>"
        bindings[result_id.to_i] << result unless result.index(VAR) 
      end
    end
    RuntimeData.new(results, exceptions, bindings)
  end

  def final_decoration(code, output)
    warnings = {}
    output.join.grep(WARNING_RE).map do |x|
      md = WARNING_RE.match(x)
      warnings[md[1].to_i] = md[2]
    end
    idx = 0
    ret = code.map do |line|
      w = warnings[idx+=1]
      if @warnings
        w ? (line.chomp + " # !> #{w}") : line
      else
        line
      end
    end
    output = output.reject{|x| /^-:[0-9]+: warning/.match(x)}
    if exception = /^-:[0-9]+:.*/m.match(output.join)
      ret << exception[0].map{|line| "# ~> " + line }
    end
    ret
  end

  def oneline_ize(code)
    "((" + code.gsub(/\r?\n|\r/, ';') + "))#{@postfix}\n"
  end

  def debugprint(*args)
    $stderr.puts(*args) if $DEBUG
  end
end # clas XMPFilter

class XMPAddMarkers < XMPFilter
  def self.run(code, opts)
    new(opts).add_markers(code, opts[:min_codeline_size])
  end
end

end
