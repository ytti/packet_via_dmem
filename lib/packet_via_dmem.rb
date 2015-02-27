require 'strscan'

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
    @received = opts.delete :received
    @sent     = opts.delete :sent
    @received ||= HEADER_SIZE[:received]
    @sc = StringScanner.new ''
  end

  def parse str
    packets = []
    headers = []
    originals = []
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
      pop, push = get_pop_push(type, pkt)
      header  = pkt[0..pop-1]
      payload = pkt[pop..-1]
      if payload
        packets << '000000 ' + [header, pkt].flatten.join(' ')
        headers << header.join(' ')
        originals << pkt
      end
    end
    [packets, headers, originals]
  end

  private

  def get_pop_push type, pkt
    if type == :sent
      get_pop_push_sent pkt
    else
      get_pop_push_received pkt
    end
  end

  def get_pop_push_sent pkt
    pop, push = nil, []
    case pkt.first.to_i(16)
    when 0x00 # we're sending to fabric
      # we may send MAC to fabric,byte 6, 7, 9, 11, 21?
      if pkt[5].to_i(16) == 0xf0 # we don't send MAC to fabric
        push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_mpls]
        pop = 24
      else # we send MAC to fabric
        pop = 33
      end
    when 0x08 then pop = 13
    else pop = @sent
    end
    [pop, push]
  end

  def get_pop_push_received pkt
    pop, push = 6, []
    offset = 0
    case pkt.first.to_i(16)
    when 0x00 then offset = 0 #1,2,3,4,5,6
    when 0x10 then offset = 2 #1,2,3,4,7,8,5,6
    else pop = @received
    end
    pop += offset
    case pkt[4+offset..5+offset].join.to_i(16)
    when 0x8000 then pop+=14
    when 0x4220 # ae/802.1AX is special, no L2 received, but something extra
      pop+=18
      push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4]
    when 0x2000 # these were BFD packets from control-plane
      pop+=5
      push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4]
    # some BGP packets like this
    # also SMB2 TCP Seq1 (maybe post ARP from control-plane?)
    # they are misssing all of ipv4 headers before TTL
    when 0x1f00
      pop+=7
      push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4] + FAKE[:ipv4]
    end
    [pop, push]
  end

  def parse_packet pkt
    pkt = pkt.gsub(/0x/, '')
    pkt = pkt.gsub(/\s+/, '')
    pkt = pkt.scan(/../)
    pkt
  end
end
