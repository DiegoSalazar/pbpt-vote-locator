require 'csv'

class WooboxVotesLocator
  IP_COL_INDEX = ENV.fetch('IP_COL_INDEX', 11).to_i
  IP_COL_NAME = ENV.fetch('IP_COL_NAME', 'ipaddress')
  IP_REGEX = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
  IP_LOCATOR = "https://tools.keycdn.com/geo.json?host=%s"

  attr_reader :finished_file_path, :finished_file_name, :success, :error
  alias_method :success?, :success

  def initialize(csv_file, delay: 0, request_builder: Typhoeus::Request)
    @csv_file, @delay = csv_file, delay
    @finished_file_name = "voteslocated-#{Time.now}-#{@csv_file.original_filename}"
    @finished_file_path = Rails.root.join "tmp/#{@finished_file_name}"
    @request_builder = request_builder
  end

  # Takes the csv_file and writes ip location data to a finished_file in parallel
  def run
    @finished_file = File.open finished_file_path, ?w do |file|
      @csv_file.tempfile.each_line do |line|
        row = line.parse_csv
        ip = row[IP_COL_INDEX]

        if ip == IP_COL_NAME
          file.puts (row + %w(location location_data)).to_csv
        elsif ip =~ IP_REGEX
          locate_and_write_row ip, row, file
        else
          Rails.logger.debug "Invalid ipaddress value [#{ip.inspect}] found for row: #{row.inspect}"
        end
      end

      @success = true
    end
  rescue => e
    msg = "#{e.class} #{e.message}"
    log "#{msg}\n#{e.backtrace}\n"
    @error = msg
  end

  private

  def locate_and_write_row(ip, row, file)
    path = IP_LOCATOR % ip
    log "Getting #{path}"
    request = @request_builder.new path

    sleep @delay
    request.run
    response = request.response

    if response.body.present?
      data = JSON.parse response.body
      log "Received response for ip #{ip}, data: #{data}"

      row += build_location_cells data
    else
      log "No response for ip #{ip} on row: #{row.inspect}"
    end

    file.puts row.to_csv.force_encoding 'UTF-8'
  end

  def build_location_cells(data)
    location = data['description']
    location_data = data['data'].try(:to_yaml).try :sub, /^---\n/, ''

    if data['status'] == 'success'
      location_data = data['data']['geo'].to_yaml.sub(/^---\n/, '')
      location = data['data']['geo'].slice('city', 'postal_code', 'country_name').to_yaml.sub(/^---\n/, '')
    end

    [location, location_data]
  end

  def log(msg)
    text = "[#{self.class}] #{msg}"
    Rails.logger ? Rails.logger.debug(text) : puts(text)
  end
end
