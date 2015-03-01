# Packet Via DMEM
Finds junos packet-via-dmem packets from arbitrary output and generates text2pcap compatible output

## JunOS
To capture say packets with IP address 10.11.12.13

    % ssh test2nqe31.dk|tee output.txt
    fisakytt@test2nqe31-re1.dk> start shell pfe network afeb0

    AFEB platform (1000Mhz QorIQ P2020 processor, 2048MB memory, 512KB flash)
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem enable
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem capture 0x3 0x0a0b0c0d
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem capture 0x0
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem dump
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem disable

 * in capture the 0x3 sets flags for what type of packets we want, for 0x3 we
   set two flags on, 'Packet' and 'PacketHead' (show mqchip N lo stats). These
   two cover all real traffic.

 * after capture flags we can set up-to 8 bytes of data to match anywhere in
   32B window

 * after match trigger we have optional 3rd argument which gives the byte
   offset where our 32B window starts from, default to 0. If you're capturing
   IPv6, the DADDR won't fit in the first 32B window, so you might give offest
   of say 19B to get DADDR there too (in case of L2 MAC headers, without VLAN
   or MPLS)

## Install
    % gem install packet_via_dmem

## CLI
    % ./bin/packet-via-dmem --both ~/output.txt|grep Packet|wc -l
    55
    % ./bin/packet-via-dmem ~/output.txt|grep Packet|wc -l
    28
    % ./bin/packet-via-dmem ~/output.txt|text2pcap - output.pcap
    Input from: Standard input
    Output to: output.pcap
    Output format: PCAP
    Wrote packet of 66 bytes.
    Wrote packet of 70 bytes.
    Wrote packet of 70 bytes.
    Wrote packet of 246 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 246 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 72 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 186 bytes.
    Wrote packet of 225 bytes.
    Wrote packet of 66 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 142 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 186 bytes.
    Wrote packet of 246 bytes.
    Wrote packet of 100 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 128 bytes.
    Wrote packet of 66 bytes.
    Wrote packet of 9 bytes.
    Read 28 potential packets, wrote 28 packets (4388 bytes).
    % ./bin/packet-via-dmem --help
    usage: ./bin/packet-via-dmem [options]
        --headers       print headers to stderr
        -o, --original  print original frames
        -r, --received  print received frames only (DEFAULT)
        -s, --sent      print sent frames only
        -b, --both      print received and sent frames
        --poprx         pop N bytes from received frames
        --poptx         pop N bytes from sent frames
        -d, --debug     turn on debugging
        -h, --help
    %

## Library
    require 'packet_via_dmem'
    dmem = PacketViaDMEM.new
    packets = dmem.parse File.read(ARGF[0])
    packets.each do |capture|
      p capture.type
      p capture.packet
      p capture.header
      p capture.original
    end


## Header format
### Received header

  * first four bits is message type
    * 0 'lu packet' (i.e. whole packet was sent for lookup, i.e. small packet)
    * 1 'lu packet head' (i.e. only head of packet was sent for lookup, i.e. large packet)
  * next 13 bits is table entry (memory loc)
  * next 11 bits is stream
  * next 3 bits offset (for fabric cell sharing)
  * next bit is size (17th bit, no way to test, would need >65k packets)
  * next 16 bits is size (if message type is 1)
  * next 8 bits is port
  * next 8 bits is packet type

  * packet type
    * 0x00 real PITA, looks to be packets from control-plane, but amount of bytes that I need to pop I can't really figure out. I now rely on port# which likely isn't robust. This made me change my mind that 5th byte isn't port, but combined type, as it allowed, what seemed cleaner classification, but unfortunately it is not so.
    * 0x08 is no-op, i don't need to pop anything, DMAC follows
    * 0x20 this seems to be quite reliably mpls, i need to do some magic, as we're missing ethertype and my macs are wrong, there is also two extra bytes
    * 0x80 is some short trash (payload 0xc013c6752759644ae0) no clue what it is

Example from MX960

    00 00 c0 30 80 08
    00 03 40 30 80 08
    00 03 c0 70 81 08
    00 06 c0 30 80 08
    00 07 c0 70 81 08
    00 0a 40 30 80 08
    00 01 c0 70 81 08
    00 02 40 70 81 08
    10 01 40 70 05 c0 81 08
    00 05 40 70 81 08
    00 08 c0 30 80 08
    00 0a c0 70 81 08
    10 0b 40 20 05 28 40 08
    00 0d c0 30 80 08
    10 00 c0 30 05 8c 80 08
    00 03 c0 30 80 08
    10 03 40 30 05 8c 80 08
    10 06 40 30 05 8c 80 08
    10 06 c0 30 05 f0 80 08
    00 07 40 70 81 08
    00 07 80 40 42 20
    00 09 00 98 42 20
    00 0a 00 48 42 20
    10 09 c0 30 05 8c 80 08
    00 02 40 70 81 08
    10 0b 80 48 05 ce 42 20
    10 01 c0 30 05 8c 80 08

Example from MX480

    00 0b 40 60 41 08
    00 01 c0 70 81 08
    00 02 40 70 81 08
    00 02 c0 70 81 08
    10 03 40 70 05 40 81 08
    00 03 c0 70 81 08
    00 06 40 70 81 08
    00 07 c0 70 81 08
    00 08 47 f0 20 00
    00 09 45 f0 20 00
    00 09 c7 f0 80 00
    00 0b c0 70 81 08
    10 0c 08 00 02 00 1f 00
    00 00 c0 70 81 08
    00 01 47 f0 80 00
    00 04 40 60 41 08
    10 04 c0 70 01 50 81 08
    00 05 40 70 81 08
    00 05 c0 70 81 08
    00 06 c5 f0 20 00
    10 07 08 00 02 00 1f 00
    00 08 c0 70 81 08
    00 0a 40 70 81 08
    00 0a c0 70 81 08
    00 0b 47 f0 20 00
    00 01 c0 70 81 08
    00 02 40 60 41 08
    00 07 c7 f0 b0 80

Example from MX80

    00 08 00 f0 81 08
    10 08 80 f0 05 b4 81 08
    10 09 00 f0 05 b4 81 08
    10 09 80 f0 05 b4 81 08
    00 0a 00 f0 92 08
    10 0a 80 f0 05 b4 81 08
    10 03 00 f0 05 b4 81 08
    00 04 00 f0 81 08
    10 04 80 f0 05 b4 81 08
    10 05 00 f0 05 b4 81 08
    10 05 80 f0 05 b4 81 08
    00 06 00 f0 81 08
    10 06 80 f0 05 b4 81 08
    00 07 00 f0 80 08
    10 07 80 f0 05 b4 81 08
    10 0b 00 f0 02 28 81 08

### Sent header
  *FIXME* check the source...

Example from MX960

    00 bf e0 0d 71 f0 00 04 42 20 01 44 03 01 00 81 00 00 00 00 00 00 07 e9
    00 bf e0 0f 71 f0 00 09 42 20 01 44 03 01 01 21 00 00 00 00 00 00 16 65
    00 bf e0 14 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 0b ad
    00 bf e0 03 71 f0 00 04 42 20 01 44 03 01 00 81 00 00 00 00 00 00 04 06
    00 bf e0 04 71 f0 00 00 42 20 01 44 03 01 00 01 00 00 00 00 00 00 24 42
    00 bf e0 0a 71 f0 00 04 42 20 01 44 03 01 00 81 00 00 00 00 00 00 18 a4
    00 a0 00 02 71 f0 00 04 42 20 01 44 03 01 00 81 00 00 00 00 00 00 0a 8f
    00 bf e0 11 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 04 00
    00 bf e0 15 71 f0 00 04 42 20 01 44 03 01 00 81 00 00 00 00 00 00 1c 69
    00 bf e0 1b 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 0b ad
    00 a0 00 16 71 f0 00 04 42 20 01 44 03 01 00 81 00 00 00 00 00 00 05 ec
    00 bf e0 07 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 0b ad
    00 a0 00 01 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 08 0a
    00 a0 00 06 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 08 0a
    00 a0 00 0c 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 08 0a
    00 a0 00 0d 71 f0 00 00 42 20 01 44 03 01 00 01 00 00 00 00 00 00 24 06
    08 bf e0 0f 70 00 00 08 b0 0e 80 03 0a
    00 bf e0 0e 11 f0 00 04 42 20 01 44 00 01 00 81 00 00 00 00 00 00 06 6b
    08 bf e0 12 10 00 00 08 b0 0e 80 03 0a
    08 bf e0 14 10 00 00 08 b0 0e 80 03 0a
    00 bf e0 04 71 f0 00 09 42 20 01 44 03 01 01 21 00 00 00 00 00 00 16 65

Example from MX480

    00 bf e0 16 10 00 03 f9 20 00 20 03 02 b0 03 7a 00 0e 00 42 80 00 00 20 0e 00 00 10 00 0c 00 00 00
    00 bf e0 03 10 00 03 f8 20 40 20 00 20 10 03 7a 00 12 00 46 80 00 00 20 12 00 00 18 00 00 00 00 00
    00 bf e0 04 10 00 03 f8 20 40 20 00 20 10 03 7a 00 12 00 46 80 00 00 20 12 00 00 18 00 00 00 00 00
    08 bf e0 05 14 00 00 10 20 12 80 5a 28
    08 a0 00 06 14 00 00 10 b0 12 80 5a 28
    08 bf e0 07 14 00 00 10 20 12 80 5a 28
    08 bf e0 0c 14 00 00 10 b0 12 80 5a 28
    08 bf e0 0f 14 00 00 10 20 12 80 5a 28
    08 bf e0 10 14 00 00 0b 20 12 80 33 2a
    08 bf e0 12 14 00 00 0b 20 0e 80 33 2c
    08 bf e0 13 14 00 00 08 00 00 80 00 be
    08 bf e0 17 14 00 00 10 20 12 80 5a 28
    08 bf e0 01 14 00 00 10 b0 12 80 5a 28
    08 bf e0 02 14 00 00 08 00 00 80 00 be
    08 a0 00 09 14 00 00 10 a0 12 80 5a 28
    08 bf e0 0a 14 00 00 10 20 12 80 5a 28
    08 bf e0 0b 14 00 00 10 a0 12 80 5a 28
    08 bf e0 0d 14 00 00 0b 00 0e 80 33 2c
    08 bf e0 11 14 00 00 10 b0 12 80 5a 28
    08 bf e0 14 14 00 00 10 b0 12 80 5a 28
    08 bf e0 15 14 00 00 10 20 12 80 5a 28
    08 bf e0 16 14 00 00 0b 20 0e 80 33 2c

Example from MX80

    08 bf e0 10 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 11 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 12 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 13 11 00 00 00 10 0e 80 0a 1e
    08 bf e0 14 11 00 00 00 70 12 80 0a 1e
    08 a0 00 15 11 00 00 00 70 0e 80 0a 1e
    08 bf e0 08 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 06 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 09 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 0a 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 0b 11 00 00 00 70 0e 80 0a 1e
    08 bf e0 0c 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 0d 11 00 00 00 70 0e 80 0a 1e
    08 bf e0 0e 71 00 00 08 10 0e 80 0a 32
    08 a0 00 0f 11 00 00 00 70 0e 80 0a 1e
    08 a0 00 16 11 00 00 00 70 0e 80 0a 1e

## Todo
  1. reverse engineer sent headers (so we can pop them correctly)
  1. reverse engineer cookie
  1. more research on received headers source fabric, port, npu
