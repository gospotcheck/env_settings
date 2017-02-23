class EnvSettingsGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)
  
  def create_initializer_file
    template "env_settings.yml", File.join('config/', "env_settings.yml")
  end
end