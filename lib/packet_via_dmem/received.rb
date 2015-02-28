require_relative 'header/received'
class PacketViaDMEM
  class Received < Packet

    def initialize packet, debug
      @debug                    = debug
      @type                     = :received
      @original                 = packet.dup
      @header                   = Header::Received.new
      @popped, @packet          = parse_packet packet
    end

    private

    def parse_packet pkt
      head = pkt.shift(4).join.to_i(16)

      @header.msg_type = (head & 0xf0000000) >> 28
      @header.table    = (head & 0xfff8000)  >> 15
      @header.stream   = (head & 0x7ff0)     >> 4
      @header.offset   = (head & 0xe)        >> 1
      @header.size     = (head & 0x1)        << 16

      @header.size    += pkt.shift(2).join.to_i(16) if @header.msg_type == PACKET_HEAD
      @header.port     = pkt.shift.to_i(16)
      @header.type     = pkt.shift.to_i(16)

      pop, push = 0, []
      macs = pkt.first.to_i(16) > 0 # macs, maybe...
      case @header.type
      # these were self originated
      #when 0x00
      #  pop+=14
      # ae/802.1AX is special, I seem to have 2 bytes I don't know
      # and ethertype missing, and MAC is weird, mpls labels are present
      # i'd need example carrying IPv4/IPv6 instead of MPLS to decide those two bytes
      when *Type::MPLS
        pop, push = get_pop_push(pkt, pop, macs, FAKE[:etype_mpls])
      # self originated stuff?
      when *Type::SELF # these were BFD packets from control-plane
        pop, push = type_self(pkt, @header.port, macs, pop)
      # some BGP packets were like this
      # also SMB2 TCP Seq1 (maybe post ARP from control-plane?)
      # they are misssing all of ipv4 headers before TTL
      #when 0x1f00
      #  pop+=7
      #  push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4] + FAKE[:ipv4]
      when *Type::NOPOP
        # no-op, DMAC follows immedately
      else
        $stderr.puts "unknown type: 0x#{type.to_s(16)}" if @debug
      end
      popped_and_packet pkt, pop, push
    end

    def get_pop_push pkt, pop, macs, ether_type
      pop += 2 # pop two weird bytes
      if macs
        pop+=12 # pop macs, return with faux ethertype
        push = pkt[2..13] + ether_type
        [pop, push]
      else
        pop+=3
        push = FAKE[:dmac] + FAKE[:smac] + ether_type
        [pop, push]
      end
    end

    def type_self pkt, port, macs, pop
      # this is super ghetto...
      push = []
      case port
      when 0x80
        pop+=14
      when 0x1f
        pop+=7
        push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4] + FAKE[:ipv4]
      else
        pop, push = get_pop_push(pkt, pop, macs, FAKE[:etype_ipv4])
      end
      [pop, push]
    end


    PACKET = 0
    PACKET_HEAD = 1
    module Type
      SELF  = [ 0x00 ]
      # 80 was unknown just 9 bytes after header (c013c6752759644ae0)
      NOPOP = [ 0x08, 0x80 ]
      MPLS  = [ 0x20 ]
    end
  end
end
