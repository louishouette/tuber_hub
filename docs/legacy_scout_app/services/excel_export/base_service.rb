module ExcelExport
  class BaseService
    # Base class for Excel export services
    
    def initialize
      @workbook = RubyXL::Workbook.new
    end
    
    protected
    
    # Format zero values according to display preferences
    def format_value(value, format_type = nil)
      begin
        return '-' if value.nil?
        
        if value.is_a?(Numeric) || value.to_s =~ /^\d+(\.\d+)?$/
          numeric_value = value.to_f
          if numeric_value <= 0
            '-'
          elsif format_type == :percentage
            "#{numeric_value.round}%"
          elsif format_type == :decimal
            numeric_value.round(2)
          else
            numeric_value.round
          end
        else
          value
        end
      rescue => e
        Rails.logger.error("Error formatting value: #{e.message}")
        '-'
      end
    end
    
    # Format values for division operations
    def calculate_ratio(numerator, denominator, format_type = nil)
      begin
        # Handle zero and nil cases gracefully
        return '-' if numerator.nil? || denominator.nil?
        numerator = numerator.to_f
        denominator = denominator.to_f
        
        # Only calculate when there's meaningful data
        if numerator > 0 && denominator > 0
          result = numerator / denominator
          if format_type == :percentage
            "#{(result * 100).round}%"
          else
            result.round(2)
          end
        else
          '-'
        end
      rescue => e
        Rails.logger.error("Error calculating ratio: #{e.message}")
        '-'
      end
    end
    
    # Safe method to add a cell to a worksheet
    def add_cell(worksheet, row, col, value, style = nil)
      begin
        cell = worksheet.add_cell(row, col, value)
        # Apply style if provided and supported
        # Styling is commented out to prevent NoMethodError with RubyXL gem
        # cell.style = style if style && cell.respond_to?(:style=)
        cell
      rescue => e
        Rails.logger.error("Error adding cell: #{e.message}")
        nil
      end
    end
    
    # Generate the final excel data
    def generate
      @workbook.stream.string
    end
  end
end
