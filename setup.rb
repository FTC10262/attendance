# Simple example of reading from serial port to interface with the RFID reader.
require 'rubygems'
require 'bundler/setup'

require_relative 'attendance_sheet.rb'

attendance = AttendanceSheet.new
attendance.cache


