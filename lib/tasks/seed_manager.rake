# lib/tasks/seed_manager.rake
# Enables running individual seed files via 'bin/rails db:seed:entity_name'

namespace :db do
  namespace :seed do
    # Create a task for each seed file in db/seeds
    Dir[Rails.root.join('db/seeds/*.rb')].each do |filename|
      entity_name = File.basename(filename, '.rb').to_sym
      desc "Loads the seed data from db/seeds/#{entity_name}.rb"
      task entity_name => :environment do
        puts "Loading seed file: db/seeds/#{entity_name}.rb"
        # Instead of requiring the file which could cause redefinition warnings,
        # we load it in a clean context
        load(filename) if File.exist?(filename)
        puts "Completed seeding #{entity_name}"
      end
    end

    # Task to list all available seed tasks
    desc "List all available seed tasks"
    task :list => :environment do
      seed_files = Dir[Rails.root.join('db/seeds/*.rb')].map do |file|
        File.basename(file, '.rb')
      end
      puts "Available seed tasks:"
      seed_files.each do |seed_file|
        puts "  db:seed:#{seed_file}"
      end
      puts "\nRun them using 'bin/rails db:seed:entity_name'"
      puts "Note: These files are also loaded when running 'bin/rails db:seed'"
    end
  end
end
