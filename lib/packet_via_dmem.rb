require 'strscan'
require 'logger'

class PacketViaDMEM
  PACKET = /^(Received|Sent) \d+ byte parcel:.*\n/
  FAKE = {
    :dmac  => %w( 22 22 22 22 22 22 ),
    :smac  => %w( 66 66 66 66 66 66 ),
    :etype_mpls  => %w( 88 47 ),
    :etype_ipv4  => %w( 08 00 ),
    :ipv4        => %w( 45 ),
  }
  HEADER_SIZE = {
    :received => 6,
    :sent     => 13,
  }
  class Error < StandardError; end

  def initialize opts={}
    @received   = opts.delete :received
    @sent       = opts.delete :sent
    @log        = opts.delete :log
    if not @log
      @log = Logger.new STDERR
      @log.level = Logger::FATAL
    end
    @received ||= HEADER_SIZE[:received]
    @sc         = StringScanner.new ''
  end

  def stream io
    packet = ''
    while not io.eof?
      line = io.readline
      if line.match PACKET
        packet = parse(packet).first
        yield packet if packet
        packet = line
      else
        packet << line
      end
    end
  end

  def parse str
    packets = Packets.new @log
    @sc.string = str
    while @sc.scan_until PACKET
      match = @sc.matched.split(/\s+/)
      type = match.first.downcase.to_sym
      @sc.scan_until(/\n/) if type == :received
      pkt = ''
      while @sc.match?(/^0x/)
        pkt << @sc.scan_until(/\n/).strip
      end
      pkt = parse_packet pkt
      packets.add pkt, type
    end
    @sc.string = ''
    packets
  end

  private

  def parse_packet pkt
    pkt = pkt.gsub(/0x/, '')
    pkt = pkt.gsub(/\s+/, '')
    pkt = pkt.scan(/../)
    pkt
  end
end

require_relative 'packet_via_dmem/packets'
