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
    packets = []
    headers = []
    @sc.string = str
    while @sc.scan_until PACKET
      match = @sc.matched.split(/\s+/)
      type = match.first.downcase.to_sym
      next if type == :received and (not @received or @received < 1)
      next if type == :sent     and (not @sent     or @sent < 1)
      @sc.scan_until(/\n/) if type == :received
      pkt = ''
      while @sc.match?(/^0x/)
        pkt << @sc.scan_until(/\n/).strip
      end
      pkt = parse_packet pkt
      pop = get_pop(type, pkt)
      header = pkt[0..pop-1]
      pkt = pkt[pop..-1]
      if pkt
        packets << '000000 ' + pkt.join(' ')
        headers << header.join(' ')
      end
    end
    [packets, headers]
  end

  private

  def get_pop type, pkt
    if type == :sent
      @sent
    else
      case pkt.first.to_i(16)
      when 0x0  then 6 #1,2,3,4,5,6
      when 0x10 then 8 #1,2,3,4,7,8,5,6
      else @received
      end
    end
  end

  def parse_packet pkt
    pkt = pkt.gsub(/0x/, '')
    pkt = pkt.gsub(/\s+/, '')
    pkt = pkt.scan(/../)
    pkt
  end
end
