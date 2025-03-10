class IntakesController < ApplicationController
  before_action :set_intake, only: %i[ show edit update destroy ]

  # GET /intakes or /intakes.json
  include WeekFormattable

  def index
    @intakes = Intake.includes(:operator).order(intake_at: :desc).all

    respond_to do |format|
      format.html
      format.xlsx { send_data generate_weekly_stats_excel, filename: "weekly_intakes_#{Time.zone.today}.xlsx" }
    end
  end

  # GET /intakes/1 or /intakes/1.json
  def show
  end

  # GET /intakes/new
  def new
    @intake = Intake.new(operator: Current.user)
  end

  # GET /intakes/1/edit
  def edit
  end

  # POST /intakes or /intakes.json
  def create
    @intake = Intake.new(intake_params)

    if @intake.save
      redirect_to @intake, notice: "Intake was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /intakes/1 or /intakes/1.json
  def update
    if @intake.update(intake_params)
      redirect_to @intake, notice: "Intake was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /intakes/1 or /intakes/1.json
  def destroy
    @intake.destroy
    redirect_to intakes_url, notice: "Intake was successfully destroyed."
  end

  private

  def generate_weekly_stats_excel
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = 'Weekly Intakes'

    # Headers
    headers = [
      'Semaine',
      'Nombre brut',
      'Poids brut',
      'Nombre net',
      'Poids net',
      'Nombre consommable',
      'Poids consommable',
      'Nombre déchets',
      'Poids déchets'
    ]
    headers.each_with_index { |header, col| worksheet.add_cell(0, col, header) }

    # Group intakes by week using ISO week format
    weekly_stats = @intakes.group_by { |intake| format_week(intake.intake_at) }

    # Calculate stats for each week
    all_data = weekly_stats.map do |week, intakes|
      raw_number = intakes.sum { |i| i.raw_number || 0 }
      raw_weight = intakes.sum { |i| i.raw_weight || 0 }
      net_number = intakes.sum { |i| i.net_number || 0 }
      net_weight = intakes.sum { |i| i.net_weight || 0 }
      edible_number = intakes.sum { |i| i.edible_number || 0 }
      edible_weight = intakes.sum { |i| i.edible_weight || 0 }
      waste_number = intakes.sum { |i| i.non_edible_number || 0 }
      waste_weight = intakes.sum { |i| i.non_edible_weight || 0 }

      {
        week: week,
        raw_number: raw_number,
        raw_weight: raw_weight,
        net_number: net_number,
        net_weight: net_weight,
        edible_number: edible_number,
        edible_weight: edible_weight,
        waste_number: waste_number,
        waste_weight: waste_weight
      }
    end

    # Sort by week (chronologically)
    sorted_data = all_data.sort_by do |data|
      parse_week_string(data[:week])
    end

    # Write data to worksheet
    sorted_data.each_with_index do |data, index|
      row = index + 1  # +1 because row 0 has headers
      worksheet.add_cell(row, 0, data[:week])
      worksheet.add_cell(row, 1, data[:raw_number])
      worksheet.add_cell(row, 2, data[:raw_weight])
      worksheet.add_cell(row, 3, data[:net_number])
      worksheet.add_cell(row, 4, data[:net_weight])
      worksheet.add_cell(row, 5, data[:edible_number])
      worksheet.add_cell(row, 6, data[:edible_weight])
      worksheet.add_cell(row, 7, data[:waste_number])
      worksheet.add_cell(row, 8, data[:waste_weight])
    end

    # Add aggregates - totals and averages
    begin
      # Add a blank row before aggregates
      total_row = sorted_data.size + 2
      
      # Add totals row
      worksheet.add_cell(total_row, 0, 'TOTAL')
      
      # Calculate and add column totals
      total_raw_number = sorted_data.sum { |d| d[:raw_number] || 0 }
      total_raw_weight = sorted_data.sum { |d| d[:raw_weight] || 0 }
      total_net_number = sorted_data.sum { |d| d[:net_number] || 0 }
      total_net_weight = sorted_data.sum { |d| d[:net_weight] || 0 }
      total_edible_number = sorted_data.sum { |d| d[:edible_number] || 0 }
      total_edible_weight = sorted_data.sum { |d| d[:edible_weight] || 0 }
      total_waste_number = sorted_data.sum { |d| d[:waste_number] || 0 }
      total_waste_weight = sorted_data.sum { |d| d[:waste_weight] || 0 }
      
      worksheet.add_cell(total_row, 1, total_raw_number)
      worksheet.add_cell(total_row, 2, total_raw_weight)
      worksheet.add_cell(total_row, 3, total_net_number)
      worksheet.add_cell(total_row, 4, total_net_weight)
      worksheet.add_cell(total_row, 5, total_edible_number)
      worksheet.add_cell(total_row, 6, total_edible_weight)
      worksheet.add_cell(total_row, 7, total_waste_number)
      worksheet.add_cell(total_row, 8, total_waste_weight)
      
      # Style the totals row to be bold
      (0..8).each do |col|
        worksheet.sheet_data[total_row][col].change_font_bold(true)
      end
      
      # Add averages row
      avg_row = total_row + 1
      weeks_count = sorted_data.size
      
      worksheet.add_cell(avg_row, 0, 'MOYENNE')
      
      if weeks_count > 0
        avg_raw_number = (total_raw_number.to_f / weeks_count).round(2)
        avg_raw_weight = (total_raw_weight.to_f / weeks_count).round(2)
        avg_net_number = (total_net_number.to_f / weeks_count).round(2)
        avg_net_weight = (total_net_weight.to_f / weeks_count).round(2)
        avg_edible_number = (total_edible_number.to_f / weeks_count).round(2)
        avg_edible_weight = (total_edible_weight.to_f / weeks_count).round(2)
        avg_waste_number = (total_waste_number.to_f / weeks_count).round(2)
        avg_waste_weight = (total_waste_weight.to_f / weeks_count).round(2)
        
        worksheet.add_cell(avg_row, 1, avg_raw_number)
        worksheet.add_cell(avg_row, 2, avg_raw_weight)
        worksheet.add_cell(avg_row, 3, avg_net_number)
        worksheet.add_cell(avg_row, 4, avg_net_weight)
        worksheet.add_cell(avg_row, 5, avg_edible_number)
        worksheet.add_cell(avg_row, 6, avg_edible_weight)
        worksheet.add_cell(avg_row, 7, avg_waste_number)
        worksheet.add_cell(avg_row, 8, avg_waste_weight)
        
        # Style the averages row to be bold and italic
        (0..8).each do |col|
          worksheet.sheet_data[avg_row][col].change_font_bold(true)
          worksheet.sheet_data[avg_row][col].change_font_italic(true)
        end
        
        # Add conversion metrics section
        metrics_row = avg_row + 2
        
        # Add yield/conversion metrics header
        worksheet.add_cell(metrics_row, 0, 'RATIOS DE RENDEMENT')
        worksheet.sheet_data[metrics_row][0].change_font_bold(true)
        
        # Raw to Net Yield
        raw_to_net_row = metrics_row + 1
        raw_to_net_yield = total_raw_weight > 0 ? (total_net_weight.to_f / total_raw_weight * 100).round(2) : 0
        worksheet.add_cell(raw_to_net_row, 0, 'Rendement Brut → Net (%)')
        worksheet.add_cell(raw_to_net_row, 1, "#{raw_to_net_yield}%")
        
        # Net to Edible Yield
        net_to_edible_row = raw_to_net_row + 1
        net_to_edible_yield = total_net_weight > 0 ? (total_edible_weight.to_f / total_net_weight * 100).round(2) : 0
        worksheet.add_cell(net_to_edible_row, 0, 'Rendement Net → Consommable (%)')
        worksheet.add_cell(net_to_edible_row, 1, "#{net_to_edible_yield}%")
        
        # Raw to Edible Yield (total conversion)
        raw_to_edible_row = net_to_edible_row + 1
        raw_to_edible_yield = total_raw_weight > 0 ? (total_edible_weight.to_f / total_raw_weight * 100).round(2) : 0
        worksheet.add_cell(raw_to_edible_row, 0, 'Rendement Total Brut → Consommable (%)')
        worksheet.add_cell(raw_to_edible_row, 1, "#{raw_to_edible_yield}%")
        
        # Waste percentage
        waste_row = raw_to_edible_row + 1
        waste_percentage = total_raw_weight > 0 ? (total_waste_weight.to_f / total_raw_weight * 100).round(2) : 0
        worksheet.add_cell(waste_row, 0, 'Pourcentage de déchets (%)')
        worksheet.add_cell(waste_row, 1, "#{waste_percentage}%")
      end
    rescue => e
      Rails.logger.error("Error in generate_weekly_stats_excel aggregates: #{e.message}")
    end

    workbook.stream.string
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_intake
      @intake = Intake.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def intake_params
      params.require(:intake).permit(:intake_at, :operator_id, :comment,
                                   :raw_number, :raw_weight,
                                   :net_number, :net_weight,
                                   :edible_number, :edible_weight,
                                   :non_edible_number, :non_edible_weight)
    end
end
