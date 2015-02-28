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

      @header.msg_type = (head & 0xffffffff) >> 28
      @header.table    = (head & 0xfffffff)  >> 15
      @header.stream   = (head & 0x7fff)     >> 4
      @header.offset   = (head & 0xe)        >> 1
      @header.size     = (head & 0x1)        << 16

      @header.size    += pkt.shift(2).join.to_i(16) if @header.msg_type == PACKET_HEAD
      @header.port     = pkt.shift.to_i(16)
      @header.type     = pkt.shift.to_i(16)

      pop, push = get_pop_push pkt, @header.type, @header.port
      popped_and_packet pkt, pop, push
    end

    PACKET = 0
    PACKET_HEAD = 1
  end
end
