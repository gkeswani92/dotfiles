# === EDITOR ===
Pry.editor = 'code'
Pry.config.color = true
Pry.config.theme = "solarized"

# === PROMPT ===
Pry.prompt = [proc { |obj, nest_level, _| "#{RUBY_VERSION} (#{obj}):#{nest_level} > " }, proc { |obj, nest_level, _| "#{RUBY_VERSION} (#{obj}):#{nest_level} * " }]

# === COLORS ===
unless ENV['PRY_BW']
  Pry.color = true
  Pry.config.theme = "railscasts"
  Pry.config.prompt = PryRails::RAILS_PROMPT if defined?(PryRails::RAILS_PROMPT)
  Pry.config.prompt ||= Pry.prompt
end

# == CLEANER STACKTRACE
def bt
  caller.select do |line|
    line.start_with?("/home/spin/src/github.com/Shopify/shopify/components") && !line.include?("/instrumentation/")
  end
end

# === HISTORY ===
Pry.config.history.should_save = true
Pry::Commands.command /^$/, "repeat last command" do
  _pry_.run_command Pry.history.to_a.last
end

# == Pry-Nav - Using pry as a debugger ==
Pry.commands.alias_command 'c', 'continue' rescue nil
Pry.commands.alias_command 's', 'step' rescue nil
Pry.commands.alias_command 'n', 'next' rescue nil
Pry.commands.alias_command 'f', 'finish' rescue nil
Pry.commands.alias_command 'l', 'whereami' rescue nil
Pry.commands.alias_command 'r!', 'reload!' rescue nil

# === Listing config ===
# Better colors - by default the headings for methods are too
# similar to method name colors leading to a "soup"
# These colors are optimized for use with Solarized scheme
# for your terminal
Pry.config.ls.separator = "\n" # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :bright_black

# == PLUGINS ===
# awesome_print gem: great syntax colorized printing
# look at ~/.aprc for more settings for awesome_print
begin
  require 'awesome_print'
  # The following line enables awesome_print for all pry output,
  # and it also enables paging
  Pry.config.print = proc {|output, value| Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output)}

  # If you want awesome_print without automatic pagination, use the line below
  module AwesomePrint
    Formatter.prepend(Module.new do
      def awesome_self(object, type)
        if type == :string && @options[:string_limit] && object.inspect.to_s.length > @options[:string_limit]
          colorize(object.inspect.to_s[0..@options[:string_limit]] + "...", type)
        else
          super(object, type)
        end
      end
    end)
  end

  AwesomePrint.defaults = {
    :string_limit => 80,
    :indent => 2,
    :multiline => true
  }
  AwesomePrint.pry!
rescue LoadError => err
  puts "gem install awesome_print  # <-- highly recommended"
end

# === CUSTOM COMMANDS ===
default_command_set = Pry::CommandSet.new do
  command "sql", "Send sql over AR." do |query|
    if ENV['RAILS_ENV'] || defined?(Rails)
      pp ActiveRecord::Base.connection.select_all(query)
    else
      pp "No rails env defined"
    end
  end
end

Pry.config.commands.import default_command_set

# === CONVENIENCE METHODS ===
class Array
  def self.sample(n=10, &block)
    block_given? ? Array.new(n,&block) : Array.new(n) {|i| i+1}
  end
end

class Hash
  def self.sample(n=10)
    (97...97+n).map(&:chr).map(&:to_sym).zip(0...n).to_h
  end
end

# === COLOR CUSTOMIZATION ===
# Everything below this line is for customizing colors, you have to use the ugly
# color codes, but such is life.
CodeRay.scan("example", :ruby).term # just to load necessary files
# Token colors pulled from: https://github.com/rubychan/coderay/blob/master/lib/coderay/encoders/terminal.rb

$LOAD_PATH << File.dirname(File.realpath(__FILE__))

# In CodeRay >= 1.1.0 token colors are defined as pre-escaped ANSI codes
if Gem::Version.new(CodeRay::VERSION) >= Gem::Version.new('1.1.0')
  require "escaped_colors"
else
  require "unescaped_colors"
end

module CodeRay
  module Encoders
    class Terminal < Encoder
      # override old colors
      TERM_TOKEN_COLORS.each_pair do |key, value|
        TOKEN_COLORS[key] = value
      end
    end
  end
end
