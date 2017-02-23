require "env_settings/version"
require "env_settings/middleware"
require 'yaml'

module EnvSettings
  class << self
    
    @@logged = false
    
    def logged
      @@logged = true
    end
    
    def logged?
      @@logged
    end
    
    # Create default options
    @@options = {
      "enabled" => false,
      "always" => false,
      "log" => true
    }
    
    def options
      @@options
    end
    
    def set_option(option_name, value)
      @@options[option_name] = value
    end
    
    @@settings = {
      "required" => {},
      "optional" => {}
    }
    
    def settings
      @@settings
    end
    
    def set(setting_name, value)
      @@settings[setting_name] = value
    end
      
    # loads config file and sets new settings
    def load_config(file_path)
      file = File.read(File.expand_path(file_path, __FILE__))
      yaml = YAML.load(file)
      
      # set new options
      options.keys.each do |option|
        set_option(option, yaml[option]) if !yaml[option].nil?
      end
      
      # set new settings
      settings.keys.each do |setting|
        set(setting, yaml[setting]) if !yaml[setting].nil?
      end
    end

    
    # required variables
    def required_vars
      @@settings["required"].keys
    end
    
    # required variable descriptions
    def description(var)
      @@settings["required"][var]
    end
    
    # missing required variables
    def missing_vars
      required_vars.select{|var| ENV[var].nil?}.sort
    end
    
    # optional variables
    def optional_vars
      @@settings["optional"].keys
    end
    
    # optional variable defaults
    def optional_default(var)
      @@settings["optional"][var]
    end
    
    # Returns message to print in the console for missing environment variables
    def console_output_msg
      return "EnvSettings: No missing required environment variables." if missing_vars.empty?
      msg = "\nEnvSettings: Missing Required Environment Variables! \n\n"
      vars = missing_vars.each do |var|
        msg += "   #{var} (#{description(var)}) \n"
      end
      msg += "\n"
    end
    
    #Returns true if required environment variables are all present, false otherwise
    #Also returns true if Rails.env is test as all variables are tested separately where used
    def environment_configured?
      Rails.env.test? || required_vars.empty? || required_vars.all?{|var_name| !ENV[var_name].nil? && !ENV[var_name].empty?}
    end

    #Get an environment variable by string which must match exactly from the environment
    # i.e. EnvSettings['API_PAGE_SIZE']
    #Returns the value from the environment or optional value if it's an optional variable
    def [](var)
      raise ArgumentError, "Environment variable '#{var}' (#{description(var) || 'optional'}) not configured in EnvSettings class. It must be added to 'config/env_settings.yml' to be tracked. Called from #{caller[0].gsub(/#{Pathname(__FILE__).parent.parent}\/(.*):in.*/, '\1')}" if (options["enabled"] && !required_vars.include?(var) && !optional_vars.include?(var))
      ENV[var] || optional_default(var)
    end

    # Checks to see if the variable is present in the Rails ENV
    def var_present?(var)
      !ENV[var].nil? && !ENV[var].empty?
    end
    
  end
end

if defined?(Rails)
  
  module EnvSettings
    class Railtie < Rails::Railtie
      
      initializer "env_settings.middleware" do
        yaml_path = Rails.root.join('config', 'env_settings.yml') || ""

        if File.exist?(File.expand_path(yaml_path, __FILE__))
          EnvSettings.load_config(yaml_path)
        end
        
        if EnvSettings.options["enabled"]
          Rails.application.middleware.insert_before 0, "EnvSettings::Middleware"
        end
      end

    end
  end

end