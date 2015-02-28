require 'minitest/autorun'
require 'minitest/pride'
require_relative '../lib/packet_via_dmem'

CAPTURES = File.expand_path File.join(File.dirname(__FILE__), '..', 'capture')

describe PacketViaDMEM do

  before do
    @dmem = PacketViaDMEM.new
    @input    = {}
    @sent     = {}
    @received = {}
    @original = {}
    @header   = {}
    Dir.glob(File.join(CAPTURES, '*.txt')) do |entry|
      _directory, file = File.split entry
      file, _ext = file.split '.'
      type, name = file.split '-'
      next unless name
      case type
      when 'input'    then @input[name]    = File.read entry
      when 'received' then @received[name] = File.read(entry).split
      when 'sent'     then @sent[name]     = File.read(entry).split
      when 'original' then @original[name] = File.read(entry).split
      when 'header'   then @header[name]   = File.read(entry).split "\n"
      end
    end
  end

  describe '#parse' do
    before do
      @parsed = {}
      @input.each do |name, str|
        @parsed[name] = @dmem.parse str
      end
    end

    it 'returns as many times as called' do
      @parsed.size.must_equal @input.size
    end

    it 'produces correct headers' do
      @parsed.each do |name, packets|
        packets.each_with_index do |packet, index|
          packet.header.to_s.must_equal @header[name][index], "header #{name} at line #{index+1}"
        end
        packets.size.must_equal @header[name].size, "header #{name} has incorrect amount of packets"
      end
    end

    it 'produces correct received frames' do
      @parsed.each do |name, packets|
        index = -1
        packets.each do |packet|
          next unless packet.type == :received
          packet.packet.join.must_equal @received[name][index+=1], "received #{name} at line #{index+1}"
        end
        @received[name].size.must_equal index+1, "received #{name} has incorrect amount of packets"
      end
    end

    it 'produces correct sent frames' do
      @parsed.each do |name, packets|
        index = -1
        packets.each do |packet|
          next unless packet.type == :sent
          packet.packet.join.must_equal @sent[name][index+=1], "sent #{name} at line #{index+1}"
        end
        @sent[name].size.must_equal index+1, "sent #{name} has incorrect amount of packets"
      end
    end

    it 'produces correct original frames' do
      @parsed.each do |name, packets|
        packets.each_with_index do |packet, index|
          packet.original.join.must_equal @original[name][index], "original #{name} at line #{index+1}"
        end
        packets.size.must_equal @original[name].size, "original #{name} has incorrect amount of packets"
      end
    end

  end

end
