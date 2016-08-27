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
  LOG_FNAME = 'attendance.dat'
  SET_POINT_FNAME = 'attendance.pos'

  def initialize
    if File.exists?(CACHE_FNAME)
      # read cached data
      puts "Loading cache"
      @rfid = YAML.load_file(CACHE_FNAME)
    else
      cache
    end
  end

  def attendance 
    if @attendance.nil?
      @attendance = spreadsheet.worksheets[1]
      raise "Unable to find attendance" unless @attendance.title == "Attendance"
    end

    @attendance
  end

  def session
    if @session.nil?
      @session = GoogleDrive.saved_session("config.json")
    end
    @session
  end

  def spreadsheet
    if @ss.nil?
      @ss = session.spreadsheet_by_title("Team Roster")
    end

    @ss
  end

  def find_date(date)
    if @date_columns.nil?
      @date_columns = {}
      (1..attendance.num_cols).each do |col|
        begin
          d = Date.parse(attendance[1, col])
          @date_columns[d.to_s] = col
        rescue ArgumentError
          # ignore invalid date fields
        end
      end
    end

    @date_columns[date.to_s]
  end

  def log(rfid)
    File.open(LOG_FNAME, "a+") do |io|
      io.puts "#{Time.now.utc.iso8601} #{rfid} #{@rfid[rfid][:name] rescue "Not found"}"
    end
  end

  def process_log_file
    pos = IO.read(SET_POINT_FNAME).to_i rescue 0
    count = 0

    File.open(LOG_FNAME, "r") do |io|
      io.seek(pos)

      lines = io.read
      lines.each_line do |line|
        if line.match(/(\S+)\s+(\S+)\s+(.*)/)
          time, rfid, name = $1, $2, $3
          time = Time.parse(time).localtime
          date = Date.parse(time.to_s).to_s

          puts "Process: #{time}: #{rfid} - #{name}"

          row = @rfid[rfid][:row]
          raise "Unable to find rfid #{rfid}" unless row.to_i > 0

          col = find_date(date)
          raise "Unable to find date #{date}" unless col.to_i > 0

          #puts "Setting #{rfid} to present on #{date} in row #{row} col #{col.inspect}"
          attendance[row,col] = "X"
          count += 1
        end
      end

      if count > 0
        save
      end

      File.open(SET_POINT_FNAME, "w") { |sp| sp.puts io.tell }
    end
  end

  def update(rfid, date = Date.today)
    row = @rfid[rfid][:row]
    raise "Unable to find rfid #{rfid}" unless row.to_i > 0

    col = find_date(date)
    raise "Unable to find date #{date}" unless col.to_i > 0

    puts "Setting #{rfid} to present on #{date} in row #{row} col #{col.inspect}"
    @attendance[row,col] = "X"
  end

  def save
    attendance.save
  end

  def cache
    roster = spreadsheet.worksheets[0]
    raise "Unable to find roster" unless roster.title == "Roster"

    @rfid = {}
    # collect names, RFID and columns
    (2..roster.num_rows).each do |row|
      id = roster[row, RFID_COLUMN]
      next if id.to_s.strip.empty?

      fname = roster[row, FNAME_COLUMN]
      lname = roster[row, LNAME_COLUMN]

      @rfid[id] = { 
        :name => "#{lname}, #{fname}",
        :row => row + 2
      }
    end

    File.open(CACHE_FNAME, "w") do |io|
      io.puts @rfid.to_yaml
    end    
  end

end

