class PacketViaDMEM
  class Received < Packet

    def initialize packet, debug
      @debug           = debug
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
      type = pkt[4+offset..5+offset].join.to_i(16)
      macs = pkt[6+offset].to_i(16) > 0 # macs, maybe...
      case type
      # these were self originated
      when 0x8000
        pop+=14
      # ae/802.1AX is special, I seem to have 2 bytes I don't know
      # and ethertype missing, and MAC is weird, mpls labels are present
      # i'd need example carrying IPv4/IPv6 instead of MPLS to decide those two bytes
      when *MAGIC::MPLS
        pop, push = get_pop_push(pkt, pop, offset, macs, FAKE[:etype_mpls])
      when *MAGIC::IPV4 # these were BFD packets from control-plane
        pop, push = get_pop_push(pkt, pop, offset, macs, FAKE[:etype_ipv4])
      # some BGP packets were like this
      # also SMB2 TCP Seq1 (maybe post ARP from control-plane?)
      # they are misssing all of ipv4 headers before TTL
      when 0x1f00
        pop+=7
        push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4] + FAKE[:ipv4]
      when *MAGIC::NOPOP
        # no-op, DMAC follows immedately
      else
        $stderr.puts "unknown type: 0x#{type.to_s(16)}" if @debug
      end
      header_and_packet pkt, pop, push
    end

    def get_pop_push pkt, pop, offset, macs, ether_type
      if macs
        pop+=14 #pop macs and weird two bytes (return macs in push)
        push = pkt[8+offset..19+offset] + ether_type
        [pop, push]
      else
        pop+=5
        push = FAKE[:dmac] + FAKE[:smac] + ether_type
        [pop, push]
      end
    end

    module MAGIC
      MPLS = [ 0x4220 ]
      IPV4 = [ 0x2000 ]
      # 4008, 8008, 8108 were ETH, MPLS, IPV4
      # 9208 was ETH, IPv4, UDP, IPSEC/ESP
      # 4108 was ETH, IPv4, UDP, BFD
      # b080 was unknown just 9 bytes after header (c013c6752759644ae0)
      NOPOP = [ 0x4008, 0x4108, 0x8008, 0x8108, 0x9208, 0xb080 ]
    end
  end
end
