class PacketViaDMEM
  class Sent < Packet

    def initialize packet
      @type            = :sent
      @original        = packet
      @header, @packet = parse_packet packet
    end

    private

    def parse_packet pkt
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
      header_and_packet pkt, pop, push
    end

  end
end
