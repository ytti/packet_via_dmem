Gem::Specification.new do |s|
  s.name              = 'packet_via_dmem'
  s.version           = '0.0.2'
  s.licenses          = %w( Apache-2.0 )
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti' ]
  s.email             = %w( saku@ytti.fi )
  s.homepage          = 'http://github.com/ytti/packet_via_dmem'
  s.summary           = 'packet_via_dmem to pcap'
  s.description       = 'finds Juniper Trio pack-via-dmem output from file and generates output which text2pcap eats, e.g. ./packet_via_dmem output.txt|text2pcap - output.pcap'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( packet-via-dmem )
  s.require_path      = 'lib'

  s.required_ruby_version =        '>= 1.9.3'
  s.add_runtime_dependency 'slop', '~> 4.0'
end
