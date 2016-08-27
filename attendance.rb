# Simple example of reading from serial port to interface with the RFID reader.
require 'rubygems'
require 'bundler/setup'

require_relative 'rfid.rb'
require_relative 'attendance_sheet.rb'

attendance = AttendanceSheet.new
begin
  RfidReader.open("/dev/tty.usbserial-AI03L08K") do |rfid|
  #RfidReader.open("/dev/ttyUSB0") do |rfid|
    begin
      attendance.log(rfid)
      #attendance.update(rfid)
      #attendance.save
    rescue
      puts "Unable to update attendance record: #{$!}" 
    end
  end
end


