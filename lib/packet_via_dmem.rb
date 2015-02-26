require 'strscan'

class PacketViaDMEM
  PACKET = /^(Received|Sent) \d+ byte parcel:.*\n/
  HEADER_SIZE = {
    :received => 6,
    :sent     => 33,  # FIXME: it's variable, we're dumb
  }
  class Error < StandardError; end

  def initialize opts={}
    @received = opts.delete :received
    @sent     = opts.delete :sent
    @received ||= HEADER_SIZE[:received]
    @sc = StringScanner.new ''
  end

  def parse str
    pkts = []
    @sc.string = str
    while @sc.scan_until PACKET
      match = @sc.matched.split(/\s+/)
      type = match.first.downcase.to_sym
      next if type == :received and (not @received or @received < 1)
      next if type == :sent     and (not @sent     or @sent < 1)
      @sc.scan_until(/\n/) if type == :received
      type = type == :received ? @received : @sent
      pkt = ''
      while @sc.match?(/^0x/)
        pkt << @sc.scan_until(/\n/).strip
      end
      pkt = parse_packet(pkt, type)
      pkts << pkt if pkt
    end
    pkts
  end

  private

  def parse_packet pkt, pop
    pkt = pkt.gsub(/0x/, '')
    pkt = pkt.gsub(/\s+/, '')
    pkt = pkt.scan(/../)
    '000000 ' + pkt[pop..-1].join(' ')
  rescue
    nil
  end
end
