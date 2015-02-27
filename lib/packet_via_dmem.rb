require 'strscan'

class PacketViaDMEM
  PACKET = /^(Received|Sent) \d+ byte parcel:.*\n/
  FAKE = {
    :dmac  => %w( 22 22 22 22 22 22 ),
    :smac  => %w( 66 66 66 66 66 66 ),
    :etype => %w( 88 47 ),
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
      header = pkt[0..pop-1]
      pkt = pkt[pop..-1]
      if pkt
        packets << '000000 ' + [push, pkt].flatten.join(' ')
        headers << header.join(' ')
      end
    end
    [packets, headers]
  end

  private

  def get_pop_push type, pkt
   push = []
   pop =  if type == :sent
      case pkt.first.to_i(16)
      when 0x00 # we're sending to fabric
        # we may send MAC to fabric,byte 6, 7, 9, 11, 21?
        if pkt[5].to_i(16) == 0xf0 # we don't send MAC to fabric
          push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype]
          24
        else # we send MAC to fabric
          33
        end
      when 0x08 then 13
      else @sent
      end
    else
      case pkt.first.to_i(16)
      when 0x00 then 6 #1,2,3,4,5,6
      when 0x10 then 8 #1,2,3,4,7,8,5,6
      else @received
      end
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
