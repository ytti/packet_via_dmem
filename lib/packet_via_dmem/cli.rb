require 'slop'
require_relative '../packet_via_dmem/'

class PacketViaDMEM
  class CLI
    class NoFile < Error; end
    class InvalidFile < Error; end
    attr_reader :debug

    def initialize
      @opts   = opts_parse
      @debug  = @opts.debug?
    end
    
    def run
      file = @opts.arguments.shift
      raise NoFile, 'filename is mandatory argument' unless file
      begin
        file = File.read(file)
      rescue
        raise InvalidFile, "unable to read #{file}"
      end
      puts PacketViaDMEM.new(:received=>@opts[:received], :sent=>@opts[:sent]).parse file
    end

    private

    def opts_parse
      Slop.parse do |o|
        o.bool '-d', '--debug', 'turn on debugging'
        o.int  '-r', '--received', "pop BYTES from received frames, default #{PacketViaDMEM::HEADER_SIZE[:received]}", :default=>PacketViaDMEM::HEADER_SIZE[:received]
        o.int  '-s', '--sent',     "pop BYTES from senti frames, default is not to show sent frames"
        o.on   '-h', '--help' do puts o; exit; end
      end
    end
  end
end
