# frozen_string_literal: true

# This controller implements calendar actions
class CalendarsController < ApplicationController
  before_action :set_calendar, only: %i[show update destroy]
  before_action :authenticate_user!

  # GET /calendars
  def index
    @calendars = current_user.calendars

    render json: @calendars
  end

  # GET /calendars/1
  def show
    render json: @calendar
  end

  # POST /calendars
  def create
    calendar_params_obj = verify_create(calendar_params)
    @calendar = current_user.calendars.create(calendar_params_obj)
    if @calendar.save
      render json: @calendar, status: :created, location: @calendar
    else
      render json: @calendar.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /calendars/1
  def update
    calendar_params_obj = verify_update(calendar_params)

    if @calendar.update(calendar_params_obj)
      render json: @calendar
    else
      render json: @calendar.errors, status: :unprocessable_entity
    end
  end

  # DELETE /calendars/1
  def destroy
    verify_destroy(@calendar)
    @calendar.destroy
  end

  private

  # Verify calendar destroy
  def verify_destroy(calendar_obj)
    return unless calendar_obj[:active] && !last_calendar?

    # active_calendar = Calendar.find(params[:id].to_i - 1)
    last_calendar = current_user.calendars.last
    if last_calendar[:id] != calendar_obj[:id]
      last_calendar.active = true
      last_calendar.save
    else
      first_calendar = current_user.calendars.first
      first_calendar.active = true
      first_calendar.save
    end
  end

  # Verify calendar create
  def verify_create(calendar_params_obj)
    if calendar_params_obj[:active]
      unless first_calendar?
        active_calendar = current_user.calendars.find_by active: true
        active_calendar.active = false
        active_calendar.save
      end
    elsif first_calendar?
      calendar_params_obj[:active] = true
    end
    calendar_params_obj
  end

  # Verify calendar update
  def verify_update(calendar_params_obj)
    if calendar_params_obj[:active]
      unless last_calendar?
        active_calendar = current_user.calendars.find_by active: true
        active_calendar.active = false
        active_calendar.save
      end
    elsif last_calendar?
      calendar_params_obj[:active] = true
    end
    calendar_params_obj
  end

  # Check if calendar first
  def first_calendar?
    all_calendars = current_user.calendars.all
    true if all_calendars.size.zero?
  end

  # Check if calendar last
  def last_calendar?
    all_calendars = current_user.calendars.all
    true if all_calendars.size == 1
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_calendar
    @calendar = current_user.calendars.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def calendar_params
    params.require(:calendar).permit(:name, :active)
  end
end
