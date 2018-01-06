require 'spec_helper'
require Rails.root.join 'app/services/woobox_votes_locator'

describe WooboxVotesLocator, type: :model do
  subject { described_class.new file }
  let(:file) { Rack::Test::UploadedFile.new Rails.root.join("spec/fixtures/data.csv") }
  before { subject.run }

  context '#run' do
    it 'generates a finished_file' do
      expect(File.read(subject.finished_file_path)).to_not be_blank
    end

    it 'adds a location column to the finished file' do
      expect(CSV.read(subject.finished_file_path).first).to include *%w(location location_data)
    end
  end
end
