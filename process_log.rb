# Simple example of reading from serial port to interface with the RFID reader.
require 'rubygems'
require 'bundler/setup'

require_relative 'rfid.rb'
require_relative 'attendance_sheet.rb'

while true
  begin
    attendance = AttendanceSheet.new
    while true
      attendance.process_log_file
      sleep 1
    end
  rescue Faraday::ConnectionFailed
    puts "Unable to connect"
    sleep 10
  rescue 
    puts "Unexpected error, waiting #{$!}"
    sleep 10
  end
end
