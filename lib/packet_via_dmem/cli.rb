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
      packets = PacketViaDMEM.new(:received=>@opts[:received], :sent=>@opts[:sent]).parse file
      count = 0
      packets.each do |pkt|
        next if pkt.type == :received and (not @opts[:received] or @opts[:received] < 1)
        next if pkt.type == :sent     and (not @opts[:sent]     or @opts[:sent] < 1)
        packet = @opts.original? ? pkt.pretty_original : pkt.pretty_packet
        puts '### Packet %d ###' % [count+=1]
        puts packet
        $stderr.puts pkt.header.join(' ') if @opts.headers?
        puts
      end
    end

    private

    def opts_parse
      Slop.parse do |o|
        o.bool '-d', '--debug',    'turn on debugging'
        o.bool       '--headers',  'print headers to stderr'
        o.bool '-o', '--original', 'print original frames'
        o.int  '-r', '--received', "pop BYTES from received frames, default #{PacketViaDMEM::HEADER_SIZE[:received]}", :default=>PacketViaDMEM::HEADER_SIZE[:received]
        o.int  '-s', '--sent',     "pop BYTES from senti frames, default is not to show sent frames"
        o.on   '-h', '--help' do puts o; exit; end
      end
    end
  end
end
