cert_path = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
ENV['SSL_CERT_FILE'] = cert_path
require "google_drive"

class AttendanceSheet
  RFID_COLUMN = 11

  def initialize
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
end

__END__

puts "Connecting to order forms"
# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
session = GoogleDrive.saved_session("config.json")

# Open our responses
ss = session.spreadsheet_by_title("2016 Spring Spirit Wear Orders")
ws = ss.worksheets[0]

puts "Scanning orders"
sent = 0
(2..ws.num_rows).each do |row|
  next if ws[row, ws.num_cols].to_s.match "TRUE"

  row_array = (1..ws.num_cols).map { |col| ws[row, col] }
  order = row_2_order(row_array)
  inv = InvoicePdf.new(order).render

  begin
    email = Mailer.receipt_email(order,inv)
    email.deliver_now
    ws[row, ws.num_cols] = true
    sent += 1
  rescue
    #STDERR.puts PP.pp(order, "Unable to process order:")
    STDERR.puts $!
  end
end

puts "Sent #{sent} emails"
ws.save
puts "Orders updated with email status" if sent > 0

__END__
# Uploads a local file.
session.upload_from_file("/path/to/hello.txt", "hello.txt", convert: false)

# Updates content of the remote file.
file.update_from_file("/path/to/hello.txt")

