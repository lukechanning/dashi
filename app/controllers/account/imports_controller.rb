module Account
  class ImportsController < ApplicationController
    def new
    end

    def create
      file = import_params[:file]

      unless file.present?
        flash.now[:alert] = "Please select a file to import."
        return render :new, status: :unprocessable_entity
      end

      if file.size > 10.megabytes
        flash.now[:alert] = "The export file is larger than 10 MB."
        return render :new, status: :unprocessable_entity
      end

      raw = file.read
      data = JSON.parse(raw)

      result = ImportService.new(current_user, data).call

      if result.errors.any?
        flash.now[:alert] = "Import failed: #{result.errors.join(', ')}"
        render :new, status: :unprocessable_entity
      else
        flash[:notice] = "Import complete. #{result.created} records added, #{result.skipped} already existed."
        redirect_to account_path
      end
    rescue ActionController::ParameterMissing
      flash.now[:alert] = "Please select a file to import."
      render :new, status: :unprocessable_entity
    rescue JSON::ParserError
      flash.now[:alert] = "The file could not be read. Please upload a valid export file."
      render :new, status: :unprocessable_entity
    end

    private

    def import_params
      params.require(:import).permit(:file)
    end
  end
end
