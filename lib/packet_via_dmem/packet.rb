class PacketViaDMEM

  class Packet
    class NoPayload < Error; end
    attr_reader :type, :packet, :header, :popped, :original

    def pop bytes
      @original[bytes..-1]
    end

    def popped_and_packet packet, pop_bytes, push_bytes
      popped  = packet[0..pop_bytes-1]
      payload = packet[pop_bytes..-1]
      raise NoPayload, "no payload for #{packet}" unless payload
      payload = push_bytes + payload
      [popped, payload]
    end

    def to_s
      pretty_packet
    end

    def pretty_packet
      pretty @packet
    end

    def pretty_original
      pretty @original
    end

    def pretty packet
      offset = -16
      out    = ''
      packet.each_slice(16) do |slice|
        hex, str = [], []
        slice.each_slice(8) do |subslice|
          hex << subslice
          str << subslice.inject(' ') do |r, s|
            int = s.to_i(16)
            r + ((int > 31 and int < 127) ? int.chr : '.')
          end
        end
        hex << [] if not hex[1]
        hex.each do |h|
          (8-h.size).times { h << '  ' }
        end
        out << "%04x  %s  %s   %s \n" % [offset+=16, hex[0].join(' '), hex[1].to_a.join(' '), str.join('  ')]
      end
      out
    end

    private

    def get_pop_push pkt, type, port, macs
      pop, push = 0, []
      case type
      when *Type::MPLS
        pop, push = general_pop_push(pkt, pop, macs, FAKE[:etype_mpls])
      when *Type::SELF
        pop, push = self_pop_push(pkt, port, macs, pop)
      when *Type::NOPOP
        # no op, DMAC follows
      end
      [pop, push]
    end

    def general_pop_push pkt, pop, macs, ether_type
      pop += 2
      if macs
        pop+=12
        push = pkt[2..13] + ether_type
        [pop, push]
      else
        pop+=3
        push = FAKE[:dmac] + FAKE[:smac] + ether_type
        [pop, push]
      end
    end

    def self_pop_push pkt, port, macs, pop
      push = []
      case port
      when 0x80
        pop+=14
      when 0x1f
        pop+=7
        push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4] + FAKE[:ipv4]
      else
        if macs and port == 0x20
          pop+=23
        else
          pop, push = general_pop_push(pkt, pop, macs, FAKE[:etype_ipv4])
        end
      end
      [pop, push]
    end



    module Type
      SELF  = [ 0x00, 0x40 ]
      NOPOP = [ 0x08, 0x80 ]
      MPLS  = [ 0x20 ]
    end


  end
end
