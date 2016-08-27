# Simple example of reading from serial port to interface with the RFID reader.
require 'serialport'

class RfidReader
 attr_accessor :key

 def initialize(port)
   port_str = port
   baud_rate = 9600
   data_bits = 8
   stop_bits = 1
   parity = SerialPort::NONE
   @sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
   @key_parts = []
   @key_limit = 16 # number of slots in the RFID card.
 end

 def close
   @sp.close
 end

 def key_detected?
   @key_parts << @sp.getc
   if @key_parts.size >= @key_limit
     self.key = @key_parts.join().chomp
     @key_parts = []
     true
   else
     false
   end
 end

 def get_next_id
   id = ""
   while true
     case ch = @sp.getc
     when "\u0002"
       id = ""
     when "\u0003"
       return id
     when /\s/
       # do nothing
     else
       id += ch
     end
   end
 end

 def main
   if key_detected?
     puts self.key
   end
 end

 def self.open(port)
   rfid = RfidReader.new(port)

   while true do
     yield rfid.get_next_id
   end
 ensure
   rfid.close if rfid
 end
end

