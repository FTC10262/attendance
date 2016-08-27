cert_path = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
ENV['SSL_CERT_FILE'] = cert_path
require "google_drive"
require 'ostruct'
require 'yaml'

class AttendanceSheet
  FNAME_COLUMN = 1
  LNAME_COLUMN = 2
  RFID_COLUMN = 11
  CACHE_FNAME = 'rfid-cache.yml'

  def initialize
    if File.exists?(CACHE_FNAME)
      # read cached data
    else
      cache
    end

    puts "Connecting to order forms"
    # Creates a session. This will prompt the credential via command line for the
    # first time and save it to config.json file for later usages.
    session = GoogleDrive.saved_session("config.json")

    # Open our responses
    @ss = session.spreadsheet_by_title("Team Roster")

    roster = @ss.worksheets[0]
    raise "Unable to find roster" unless roster.title == "Roster"

    @attendance = @ss.worksheets[1]
    raise "Unable to find attendance" unless @attendance.title == "Attendance"

    # scan roster for RFIDs
    @rfid = {}
    (2..roster.num_rows).each do |row|
      id = roster[row, RFID_COLUMN]
      next if id.to_s.strip.empty?
      @rfid[id] = row + 2
    end

    @date_columns = nil
  end

  def find_date(date)
    if @date_columns.nil?
      @date_columns = {}
      (1..@attendance.num_cols).each do |col|
        begin
          d = Date.parse(@attendance[1, col])
          @date_columns[d.to_s] = col
        rescue ArgumentError
          # ignore invalid date fields
        end
      end
      pp @date_columns
    end

    @date_columns[date.to_s]
  end

  def update(rfid, date = Date.today)
    row = @rfid[rfid]
    raise "Unable to find rfid #{rfid}" unless row.to_i > 0

    col = find_date(date)
    raise "Unable to find date #{date}" unless col.to_i > 0

    puts "Setting #{rfid} to present on #{date} in row #{row} col #{col.inspect}"
    @attendance[row,col] = "X"
  end

  def save
    @attendance.save
  end

  def self.cache
    return if File.exists?(CACHE_FNAME)

    roster = @ss.worksheets[0]
    raise "Unable to find roster" unless roster.title == "Roster"

    rfid = {}

    # collect names, RFID and columns
    (2..roster.num_rows).each do |row|
      id = roster[row, RFID_COLUMN]
      next if id.to_s.strip.empty?

      fname = roster[row, FNAME_COLUMN]
      lname = roster[row, LNAME_COLUMN]

      rfid[id] = { 
        :name => "#{lname}, #{fname}",
        :row => row + 2
      }
    end

    File.open(CACHE_FNAME, "w") do |io|
      io.puts rfid.to_yaml
    end    
  end

end

