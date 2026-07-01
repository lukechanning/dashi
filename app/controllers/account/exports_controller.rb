module Account
  class ExportsController < ApplicationController
    def show
      data = ExportService.new(current_user).call
      filename = "dashi-export-#{Date.current.iso8601}.json"
      send_data data.to_json, filename: filename, type: "application/json", disposition: "attachment"
    end
  end
end
