require 'slop'
require_relative '../packet_via_dmem/'

class PacketViaDMEM
  class CLI
    class NoFile < Error; end
    class InvalidFile < Error; end
    attr_reader :debug

    def initialize
      @opts      = opts_parse
      @debug     = @opts.debug?
      @log       = Logger.new STDERR
      @log.level = Logger::INFO unless @debug
    end

    def run
      file = get_file if not @opts.stdin?
      dmem = PacketViaDMEM.new :received=>@opts.received?,
                               :sent=>@opts.sent?,
                               :log=>@log

      count = 0
      block = Proc.new do |pkt|
        pop = false
        if pkt.type == :received
          next if @opts.sent?
          pop = @opts[:poprx]
        elsif pkt.type == :sent
          next unless (@opts.sent? or @opts.both?)
          pop = @opts[:poptx]
        end
        packet = @opts.original? ? pkt.pretty_original : pkt.pretty_packet
        packet = pkt.pretty pkt.pop(pop) if pop
        puts pkt.header.to_s count+=1
        puts packet
        $stderr.puts pkt.popped.join(' ') if @opts.popped?
        puts
      end
      packets = @opts.stdin? ? dmem.stream($stdin, &block) : dmem.parse(file).each(&block)
    end

    private

    def get_file
      file = @opts.arguments.shift
      raise NoFile, 'filename is mandatory argument' unless file
      begin
        file = File.read(file)
      rescue
        raise InvalidFile, "unable to read #{file}"
      end
    end

    def opts_parse
      Slop.parse do |o|
        o.bool '-',  '--stdin',    'stream from STDIN'
        o.bool       '--popped',   'print popped bytes to stderr'
        o.bool '-o', '--original', 'print original frames'
        o.bool '-r', '--received', 'print received frames only (DEFAULT)'
        o.bool '-s', '--sent',     'print sent frames only'
        o.bool '-b', '--both',     'print received and sent frames'
        o.int        '--poprx',    'pop N bytes from received frames'
        o.int        '--poptx',    'pop N bytes from sent frames'
        o.bool '-d', '--debug',    'turn on debugging'
        o.on   '-h', '--help' do puts o; exit; end
      end
    end
  end
end
