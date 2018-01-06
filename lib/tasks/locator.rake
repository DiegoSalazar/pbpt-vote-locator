namespace :locator do
  desc "Locate ip address geo data from a Woobox Votes Export CSV file"
  task :run, [:csv_file, :delay] do |t, args|
    require File.expand_path '../../../app/services/woobox_votes_locator', __FILE__

    file = Rack::Test::UploadedFile.new File.expand_path(args[:csv_file])
    locator = WooboxVotesLocator.new file, delay: args[:delay].to_f

    puts "Running..."
    locator.run

    if locator.success?
      puts "\aDone.\n#{locator.finished_file_path}"
    else
      puts "Error: #{locator.error}"
    end
  end
end
