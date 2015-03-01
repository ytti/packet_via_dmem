#!/usr/bin/env ruby

require 'packet_via_dmem'

# takes 1 or more argument pointing to filename as 'input-something.txt'
# this input should be data gathered from juniper
# writes to output received-something.txt, sent-something.txt,
#  original-something.txt and header-something.txt
# This is used to generate files for testing

class PacketViaDMEM
  class CreateTestFiles
    def initialize
      @dmem = PacketViaDMEM.new
    end
    def run file
      name, ext = file.split '.'
      return unless ext == 'txt'
      direction, name  = name.split '-'
      return unless direction == 'input'
      headers, received, sent, originals = [], [], [], []
      @dmem.parse(File.read(file)).each do |packet|
        case packet.type
        when :received then received << packet.packet.join
        when :sent     then sent     << packet.packet.join
        else raise StandardError, "invalid type #{type}"
        end
        headers   << packet.header.to_s.split(/\n/).join('---')
        originals << packet.original.join
      end
      File.write('header-'   + name + '.txt', headers.join("\n"))
      File.write('sent-'     + name + '.txt', sent.join("\n"))
      File.write('received-' + name + '.txt', received.join("\n"))
      File.write('original-' + name + '.txt', originals.join("\n"))
    end
  end
end

runner = PacketViaDMEM::CreateTestFiles.new
ARGV.each do |arg|
  runner.run arg
end
