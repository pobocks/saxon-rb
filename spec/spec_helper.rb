require 'bundler/setup'
require 'vcr'
require 'simplecov'
SimpleCov.start

# Handle loading alternate Saxon JARs for testing
if ENV['ALTERNATE_SAXON_HOME']
  puts "Alternate Saxon requested at: #{ENV['ALTERNATE_SAXON_HOME']}"
  require 'saxon/loader'
  Saxon::Loader.load!(ENV['ALTERNATE_SAXON_HOME'])
end

require 'saxon/source'

module FixtureHelpers
  def fixture_path(path)
    File.expand_path(File.join('../fixtures', path), __FILE__)
  end

  def fixture_source(path, source_opts = {})
    Saxon::Source.from_path(fixture_path(path), source_opts)
  end

  def fixture_doc(processor, path, source_opts = {})
    doc_builder = processor.document_builder
    doc_builder.build(fixture_source(path, source_opts))
  end

  def string_doc(processor, str, source_opts = {base_uri: "http://example.org/"})
    doc_builder = processor.document_builder
    source = Saxon::Source.from_string(str, source_opts)
    doc_builder.build(source)
  end
end

module SaxonEditionHelpers
  def requires_pe(&block)
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FixtureHelpers
  config.extend SaxonEditionHelpers
end

# We need to cope with JRuby 9.1 (2.3) / 9.2 (>= 2.4) and therefore Ruby 2.4's Fixnum/Bignum unification
RSpec::Matchers.define :match_ruby_value_and_class do |expected|
  if 1.class == Integer # 2.4+
    match do |actual|
      actual == expected && actual.class == expected.class
    end
  else # 2.3
    match do |actual|
      case expected
      when Fixnum, Bignum
        actual == expected && [Fixnum, Bignum].member?(actual.class)
      else
        actual == expected && actual.class == expected.class
      end
    end
  end

  failure_message do |actual|
    "expected that #{actual.inspect} (#{actual.class}) would ==, and have the same class as, #{expected.inspect} (#{expected.class})"
  end
end
