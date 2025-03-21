# frozen_string_literal: true

# This file contains the authorization rake tasks
# These tasks will interact with the AuthorizationService when it becomes available

namespace :authorization do
  desc "Refresh the permission system by discovering new controllers and actions"
  task refresh: :environment do
    puts "Starting permission refresh process..."
    
    # Ensure Rails is properly loaded
    Rails.application.eager_load! if Rails.env.development?
    
    puts "Scanning controllers for new actions..."
    
    begin
      # Check if the service is available
      if defined?(AuthorizationService) && AuthorizationService.respond_to?(:refresh_permissions)
        permission_count = AuthorizationService.refresh_permissions
        puts "Permission refresh completed: #{permission_count} active permissions"
      else
        puts "WARNING: AuthorizationService not defined or missing refresh_permissions method."
        puts "This would normally scan controllers and update the permissions database."
      end
    rescue => e
      puts "Error during permission refresh: #{e.message}"
    end
    
    puts "\nNext steps:"
    puts "1. Review the permissions in Hub Admin > Permissions"
    puts "2. Assign permissions to roles as needed"
    puts "3. Check for any archived permissions that might need to be reactivated"
  end
  
  desc "Generate a report of all permissions and their usage statistics"
  task :report, [:format, :detailed, :output] => :environment do |_t, args|
    format = args[:format] || 'text'
    detailed = args[:detailed] == 'true'
    output_path = args[:output]
    
    puts "Generating authorization system report..."
    
    # Ensure Rails is properly loaded
    Rails.application.eager_load! if Rails.env.development?
    
    begin
      # Prepare report data
      permissions = {}
      statistics = {}
      
      # Try to use AuthorizationService if available
      if defined?(AuthorizationService) && AuthorizationService.respond_to?(:grouped_permissions)
        # Get all active permissions grouped by namespace/controller
        permissions = AuthorizationService.grouped_permissions
        
        # Get usage statistics if requested
        if detailed
          puts "Collecting detailed usage statistics (this may take a while)..."
          
          # Try to use the Permission model if available
          if defined?(Hub::Admin::Permission)
            Hub::Admin::Permission.where(status: 'active').find_each do |permission|
              key = "#{permission.namespace}/#{permission.controller}##{permission.action}"
              
              # Get role count
              role_count = 0
              if defined?(Hub::Admin::PermissionAssignment)
                role_count = Hub::Admin::PermissionAssignment.where(permission_id: permission.id).count
              end
              
              # Get failure count
              failure_count = 0
              if defined?(Hub::Admin::AuthorizationAudit)
                failure_count = Hub::Admin::AuthorizationAudit
                  .where(controller_action: "#{permission.controller}##{permission.action}")
                  .count
              end
              
              # Add to statistics
              statistics[key] = {
                roles: role_count,
                failures: failure_count,
                last_discovered: permission.discovered_at,
                discovery_method: permission.discovery_method || 'manual'
              }
            end
          else
            puts "WARNING: Hub::Admin::Permission model not available for detailed statistics."
          end
        end
      else
        puts "WARNING: AuthorizationService not defined or missing grouped_permissions method."
        puts "Using sample data for report generation."
        # Sample data for testing
        permissions = { 'admin' => { 'users' => ['index', 'show', 'edit'] } }
      end
    rescue => e
      puts "Error preparing report data: #{e.message}"
      permissions = {}
      statistics = {}
    end
    
    # Generate report based on format
    report_content = case format.downcase
                     when 'json'
                       generate_json_report(permissions, statistics, detailed)
                     when 'csv'
                       generate_csv_report(permissions, statistics, detailed)
                     else
                       generate_text_report(permissions, statistics, detailed)
                     end
    
    # Output the report
    if output_path.present?
      File.write(output_path, report_content)
      puts "Report written to #{output_path}"
    else
      puts "\n#{report_content}"
    end
  end
  
  private
  
  # Generate a text report
  def generate_text_report(permissions, statistics, detailed)
    content = []
    content << "AUTHORIZATION SYSTEM REPORT"
    content << "============================"
    content << "Generated on: #{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}\n"
    
    content << "PERMISSIONS BY NAMESPACE/CONTROLLER"
    content << "-----------------------------------"
    
    if permissions.empty?
      content << "\nNo permissions found."
    else
      permissions.each do |namespace, controllers|
        namespace_name = namespace.present? ? namespace : '[ROOT]'
        content << "\n#{namespace_name}"
        
        controllers.each do |controller, actions|
          content << "  #{controller}"
          
          actions.each do |action|
            permission_key = "#{namespace}/#{controller}##{action}"
            stats_info = ''
            
            if detailed && statistics[permission_key]
              stats = statistics[permission_key]
              stats_info = " (Roles: #{stats[:roles]}, Failures: #{stats[:failures]})"
            end
            
            content << "    - #{action}#{stats_info}"
          end
        end
      end
    end
    
    if detailed
      content << "\nPERMISSION STATISTICS"
      content << "---------------------"
      
      # Include these statistics only if the models are defined
      if defined?(Hub::Admin::Permission)
        content << "Total active permissions: #{Hub::Admin::Permission.where(status: 'active').count}"
        content << "Total archived permissions: #{Hub::Admin::Permission.where(status: 'archived').count}"
      else
        content << "Total permissions: Model not available"
      end
      
      if defined?(Hub::Admin::Role)
        content << "Total roles: #{Hub::Admin::Role.count}"
      else
        content << "Total roles: Model not available"
      end
      
      if defined?(Hub::Admin::PermissionAssignment)
        content << "Total permission assignments: #{Hub::Admin::PermissionAssignment.count}"
      else
        content << "Total permission assignments: Model not available"
      end
      
      if defined?(Hub::Admin::AuthorizationAudit)
        content << "Total authorization failures: #{Hub::Admin::AuthorizationAudit.count}"
        content << "Recent failures (last 7 days): #{Hub::Admin::AuthorizationAudit.where('created_at > ?', 7.days.ago).count}"
      end
    end
    
    content.join("\n")
  end
  
  # Generate a JSON report
  def generate_json_report(permissions, statistics, detailed)
    report = {
      generated_at: Time.zone.now,
      permissions: permissions
    }
    
    report[:statistics] = statistics if detailed
    
    report.to_json(pretty: true)
  end
  
  # Generate a CSV report
  def generate_csv_report(permissions, statistics, detailed)
    require 'csv'
    
    csv_content = CSV.generate do |csv|
      # Header row
      header = ['Namespace', 'Controller', 'Action']
      header += ['Roles Count', 'Failures Count', 'Last Discovered', 'Discovery Method'] if detailed
      csv << header
      
      # Data rows
      permissions.each do |namespace, controllers|
        controllers.each do |controller, actions|
          actions.each do |action|
            row = [namespace.presence || '[ROOT]', controller, action]
            
            if detailed
              permission_key = "#{namespace}/#{controller}##{action}"
              stats = statistics[permission_key] || { roles: 0, failures: 0, last_discovered: nil, discovery_method: 'unknown' }
              row += [stats[:roles], stats[:failures], stats[:last_discovered], stats[:discovery_method]]
            end
            
            csv << row
          end
        end
      end
    end
    
    csv_content
  end
end
