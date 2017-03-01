# EnvSettings (deprecated)

A Rails gem to ensure that required environment variables are set before doing anything else.  
It can also be used to set optional environment variables with default values.  
  
This gem is to be used with [dotenv gem](https://github.com/bkeepers/dotenv).

See ```screenshot.png``` for an example startup page.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'env_settings', :git => "git://github.com/ndhays/env_settings.git"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install env_settings

## Usage

Run:

    rails g env_settings
    
This will create a settings YAML file. ('config/env_settings.yml')

Use ```EnvSettings[var]``` instead of ```ENV[var]``` to raise errors when variable is not set.

### Options

There are three options set in 'env_settings.yml':

- ```enable``` (default: true) - Enables or disables the summary page on app load
- ```always``` (default: false) - Shows summary page (even if all variables are set)
- ```log``` (default: true) - Logs summary of required variables in the console

Optional variables are shown in blue if they have been set elsewhere and differ from their default value.

### Required Variables

Required variables are set in 'env_settings.yml' with a description of the variable to help with debugging.  
  
Example:

    required:
      MAIN_SECRET_TOKEN: This token is used to open the super secret main door.
      
### Optional Variables

Optional variables are also set in 'env_settings.yml' and given default values.  
If they are set elsewhere else the default value will be overwritten.  
  
Example:

    optional:
      SAMPLE_COLOR: Blue

### Sample 'env_settings.yml' file

    # EnvSettings
    #
    # Use this file to create a list of required environment variables and set default values for optional variables.


    # Options

    # Enables or disables the summary page on app load

    enabled: true


    # Shows summary page (even if all variables are set)

    always: false


    # Logs summary of required variables in the console

    log: true


    # Required Variables (with descriptions):
    # 
    # Note: There are no defaults for required variables.
    # Each required variable is given a description which can be used for debugging.
    #
    # ie.
    # OAUTH_BASE_URL: "The base URL used to authenticate, usually https://oauthserver.com"
    #

    required:
      VARIABLE: "description"
      VARIABLE_NEXT: "something else" 


    # Optional Variables (with default values):
    #
    # Set optional variables with default values.
    # Note: Variables set in the Rails environment will overwrite these defaults.

    optional:
      OPTIONAL_VAR: "default value"
      OPTIONAL_VAR_TWO: "default value"

## Development

EnvSettings uses Rack Middleware to return an html summary page if there are any missing required variables.

## Contributing

Original design by [Chris Schenk](https://www.github.com/schenkman).

Bug fixes, new features, and suggestions are welcome.

## License

[MIT License](http://opensource.org/licenses/MIT).

