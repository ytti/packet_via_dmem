require_relative 'header/sent'
class PacketViaDMEM
  class Sent < Packet

    def initialize packet, debug
      @debug           = debug
      @type            = :sent
      @original        = packet.dup
      @header          = Header::Sent.new
      @popped, @packet = parse_packet packet
    end

    private

    def parse_packet pkt
      head = pkt.shift(4).join.to_i(16)
      @header.msg_type            = (head & 0xffffffff) >> 28
      @header.statistics          = head[27] == 1
      @header.increment_reference = head[26] == 1
      @header.fragment_info       = head[25] == 1
      @header.drop_hash           = head[24] == 1
      @header.decrement_reference = head[23] == 1
      @header.prequeue_priority   = head[22] == 1
      @header.offset              = (head & 0x3fffff) >> 13
      @header.table               = (head & 0x1fff)

      head = pkt.shift(4).join.to_i(16)
      raise Packet::NoPayload, "#{@original.join(' ')} had no payload" unless pkt[0]
      @header.color               = (head & 0x7fffffff) >> 29
      @header.queue_drop_opcode   = (head & 0xcffffff)  >> 27
      @header.queue_system        = (head & 0x3ffffff)  >> 24
      @header.life                = (head & 0x7fffff)   >> 21
      @header.queue_number        = (head & 0x1fffff)

      pop, push = 0, []
      @header.port = pkt.shift.to_i(16)
      @header.type = pkt.shift.to_i(16)
      macs = pkt.first.to_i(16) > 0 # macs, maybe..
      # uuhhohh, msg_type is always 
      if not @header.statistics
        pop, push = get_pop_push pkt, @header.type, @header.port, macs
      else
        pop = 3
      end
      popped_and_packet pkt, pop, push
    end

    FABRIC = 0
    WAN    = 8

  end
end
