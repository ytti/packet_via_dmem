require_relative 'packet'
require_relative 'received'
require_relative 'sent'

class PacketViaDMEM
  class Packets
    include Enumerable
    class InvalidType < Error; end

    def initialize debug
      @debug   = debug
      @packets = []
    end

    def add packet, type
      packet = case type
      when :received then Received.new packet, @debug
      when :sent     then Sent.new packet, @debug
      else raise InvalidType, "#{type} not valid packet type"
      end
      @packets << packet
    rescue Packet::NoPayload
    end

    def each &block
      @packets.each { |packet| block.call packet }
    end

    def size
      @packets.size
    end

  end
end
