class PacketViaDMEM
  class Received < Packet

    def initialize packet
      @type            = :received
      @original        = packet
      @header, @packet = parse_packet packet
    end

    private

    def parse_packet pkt
      pop, push = 6, []
      offset = 0
      case pkt.first.to_i(16)
      when 0x00 then offset = 0 #1,2,3,4,5,6
      when 0x10 then offset = 2 #1,2,3,4,7,8,5,6
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
      header_and_packet pkt, pop, push
    end
  end
end
