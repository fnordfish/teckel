# frozen_string_literal: true

if RUBY_VERSION > '2.7'
  @warning = Warning[:experimental]
  Warning[:experimental] = false
  eval(File.read(File.join(__dir__, 'pattern_matching.rb'))) # rubocop:disable Security/Eval
  Warning[:experimental] = @warning
end
