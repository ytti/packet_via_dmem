#!/usr/bin/env ruby

Dir.glob('input-*.txt') do |file|
  name, _ext = file.split '.'
  _, name = name.split '-'
  output = "pcap-#{name}.pcap"
  system("/home/ytti/usr/git/pkt-via-dmem/bin/packet-via-dmem -b #{file}|text2pcap - #{output}")
end
