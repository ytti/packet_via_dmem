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
      packets, headers, originals = PacketViaDMEM.new(:received=>@opts[:received], :sent=>@opts[:sent]).parse file
      if @opts.original?
        originals.each_with_index do |original, index|
          puts "Packet #{index+1}"
          puts pretty_packet original
          puts
        end
      else
        $stderr.puts headers if @opts.headers?
        puts packets
      end
    end

    private

    def pretty_packet packet
      offset = -16
      out    = ''
      packet.each_slice(16) do |slice|
        hex, str = [], []
        slice.each_slice(8) do |subslice|
          hex << subslice
          str << subslice.inject(' ') do |r, s|
            int = s.to_i(16)
            r + ((int > 31 and int < 127) ? int.chr : '.')
          end
        end
        hex << [] if not hex[1]
        hex.each do |h|
          (8-h.size).times { h << '  ' }
        end
        out << "%04x  %s  %s   %s \n" % [offset+=16, hex[0].join(' '), hex[1].to_a.join(' '), str.join('  ')]
      end
      out
    end

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
