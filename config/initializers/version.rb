module TuberHub
  VERSION = File.read(Rails.root.join('VERSION')).strip

  def self.version
    VERSION
  end
end

Rails.logger.info("[TuberHub] Loaded application version: #{TuberHub.version}")
