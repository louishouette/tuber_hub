module ExcelExport
  class WeeklySummaryService < BaseService
    include WeekFormattable
    
    def initialize
      super
    end
    
    def generate_weekly_summary_excel
      begin
        # Make sure we have a workbook ready
        @workbook ||= RubyXL::Workbook.new
        worksheet = @workbook[0]
        worksheet.sheet_name = "Weekly Summary"
        
        # Add headers
        headers = ["Semaine", "Nombre de truffes", "Production (g)", "Poids moyen (g/truffe)"]
        headers.each_with_index do |header, index|
          add_cell(worksheet, 0, index, header)
        end
        
        # Collect weekly data using Finding model with WeeklyStatistics concern
        weekly_data = Finding.weekly_stats
        
        # Sort by week (most recent first)
        sorted_weeks = weekly_data.keys.sort.reverse
        
        # Write data
        sorted_weeks.each_with_index do |week, index|
          data = weekly_data[week]
          row = index + 1
          
          # Format week for display using the correct method
          week_date = Date.parse(week)
          week_display = format_week(week_date)
          add_cell(worksheet, row, 0, week_display)
          
          # Count of findings
          findings_count = data[:count].to_i
          add_cell(worksheet, row, 1, findings_count)
          
          # Total weight
          total_weight = data[:total_weight].to_f
          formatted_total_weight = format_value(total_weight)
          add_cell(worksheet, row, 2, formatted_total_weight)
          
          # Average weight
          avg_weight = findings_count > 0 ? (total_weight / findings_count).round(2) : 0
          formatted_avg_weight = format_value(avg_weight, :decimal)
          add_cell(worksheet, row, 3, formatted_avg_weight)
        end
        
        # Add a summary row at the bottom
        summary_row = sorted_weeks.size + 1
        add_cell(worksheet, summary_row, 0, "TOTAL")
        
        total_findings = weekly_data.values.sum { |data| data[:count].to_i }
        add_cell(worksheet, summary_row, 1, total_findings)
        
        total_weight = weekly_data.values.sum { |data| data[:total_weight].to_f }
        formatted_total_weight = format_value(total_weight)
        add_cell(worksheet, summary_row, 2, formatted_total_weight)
        
        overall_avg_weight = total_findings > 0 ? (total_weight / total_findings).round(2) : 0
        formatted_overall_avg = format_value(overall_avg_weight, :decimal)
        add_cell(worksheet, summary_row, 3, formatted_overall_avg)
        
        # Return the generated Excel data
        return generate
      rescue => e
        Rails.logger.error("Error generating weekly summary excel: #{e.message}\n#{e.backtrace.join("\n")}")
        raise
      end
    end
    

  end
end
