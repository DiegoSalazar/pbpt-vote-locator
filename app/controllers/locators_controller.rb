class LocatorsController < ApplicationController
  def create
    locator = WooboxVotesLocator.new params[:votes_csv]
    locator.run

    if locator.success?
      send_file locator.finished_file_path, filename: locator.finished_file_name, type: 'text/csv', disposition: 'attachment'
    else
      flash[:error] = "Could not process that file #{locator.error}"
      rediret_to visitors_path
    end
  end
end
