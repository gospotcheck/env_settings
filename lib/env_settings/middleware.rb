module EnvSettings
  class Middleware
    def initialize(app)
      @app = app
    end
    
    def call(env)
      
      # retrieves options
      options = EnvSettings.options
      
      # logs summary in console
      if !EnvSettings.logged? && options["log"]
        Rails.logger.info(EnvSettings.console_output_msg)
        EnvSettings.logged
      end
      
      # continues to load app if 'enabled' option is false, or 'always' option is false and the environment is configured
      if !options["enabled"] || (!options["always"] && EnvSettings.environment_configured?) 
        @app.call(env)
      else
        respond_with_html
      end
    
    end
    
    def respond_with_html
      template = html_template

      completed = EnvSettings.environment_configured? ? "complete" : "incomplete"
      template.gsub!(/\$\{completed\}/, completed)
      
      required = ""
      EnvSettings.required_vars.sort.each do |var|
        required_row_class = EnvSettings.var_present?(var) ? "ok" : "missing"
        required += "<tr class='#{required_row_class}'>"
        required += "<td>#{var}</td>"
        required += "<td>#{EnvSettings.description(var)}</td>"
        required += "</tr>"
      end
      
      template.gsub!(/\$\{required\}/, required)

      
      optional = ""
      EnvSettings.optional_vars.sort.each do |var|
        optional_row_class = EnvSettings[var].to_s == EnvSettings.optional_default(var).to_s ? "ok" : "overridden"
        optional += "<tr class='#{optional_row_class}'>"
        optional += "<td>#{var}</td>"
        optional += "<td>#{EnvSettings[var]}</td>"
        optional += "<td>#{EnvSettings.optional_default(var)}</td>"
        optional += "</tr>"
      end
      
      template.gsub!(/\$\{optional\}/, optional)
      
      response_body = template

      headers = {
        "Content-Type" => "text/html",
        "Content-Length" => response_body.length.to_s
      }

      [200, headers, [response_body]]
      
    end
    
    def html_template
      <<-HTML
      
      <!DOCTYPE html>
      <html>
      <head>
        <style>

          body {
            font-family: Helvetica;
            text-align: left;
            padding: 0 50px;
          }

          h1.welcome {
            display: block;
            font-size: 40px;
            padding: 30px 0 0 0;
          }

          h2 {
            display: block;
            font-size:24px;
            margin: 50px 0 20px 0;
          }

          p {
          }

          /*Table of environment variables*/
          .environment-variables {
            background: white;
            border-radius: 4px;
            border: 2px solid #e9e9e9;
            /*font-size: 12px;*/
            padding: 0 40px 0 0;
            width: 100%;
          }

          th {
            border-bottom: 3px solid #e9e9e9;
            font-size: 1.5em;
            font-weight: bold;
            padding: 5px 12px;
          }

          td {
            padding: 12px;
          }  

          .example {
            font-family: Courier;
          }

          .ok {
            background-color: #a1ff58;
          }
      
          .missing {
            background-color: #ff9f8d;
          }
          .overridden {
            background-color: #5aecff;
          }

        </style>
      </head>

      <body>
        <div class="main-body-wrapper">

          <h1 class="welcome">Environment Settings</h1>

          <p>The setup of your environment is currently <strong>${completed}.</strong></p>
          
          <h2>Required Variables</h2>

          <table class="environment-variables">
            <thead>
              <th>Name</th>
              <th>Description</th>
            </thead>
            <tbody>
        
              ${required}

            </tbody>
          </table>

          <h2>Optional Variables</h2>

          <table class="environment-variables">
            <thead>
            <th>Name</th>
            <th>Value</th>
            <th>Default</th>
            </thead>
            <tbody>
        
              ${optional}
        
            </tbody>
          </table>

          <p>Rails environment variables are commonly set in '.env' with 'dotenv-rails' gem or 'heroku config' on Heroku.</p>

        </div>
      </body>
      </html>
    
      HTML
    end
  end
end