require 'spec_helper'

describe EnvSettings do
  
  it 'has a version number' do
    expect(EnvSettings::VERSION).not_to be nil
  end
  
  before do
    allow(subject).to receive_message_chain(:Pathname, :parent, :parent)
  end
  
  it "should set options defaults" do
    expect(EnvSettings.options).to eq ({
      "enabled" => false,
      "always" => false,
      "log" => true
    })
  end
  
  it "should set settings defaults" do
    expect(EnvSettings.settings).to eq({
      "required" => {},
      "optional" => {}
    })
  end
  
  describe ".load_config" do
    before do
      EnvSettings.load_config("../../spec/test_config.yml")
    end
    
    it "should load settings and options from yaml file" do
      expect(EnvSettings.options).to eq({
        "enabled" => true,
        "always" => true,
        "log" => false
        })
      expect(EnvSettings.settings).to eq({
        "required" => {
          "SPEC_API_TOKEN" => "api token",
          "SPEC_PORTFOLIO_VALUE" => "value"
        },
        "optional" => {
          "SUPPORT_EMAIL" => "support@weather.com",
          "WINNING_LOTTO_NUMBERS" => [42,1,2,3,4]
        }
      })
    end
    
    after do
      EnvSettings.load_config("../../spec/test_defaults.yml")
    end
  end #end ".load_config"

  describe ".required_vars" do
    it "should return the required variables" do
      EnvSettings.set("required", {"TEST" => "description"})
      expect(EnvSettings.required_vars).to eq(["TEST"])
    end
  end #end ".required_vars"
  
  describe ".description" do
    it "should return the description for a required variable" do
      EnvSettings.set("required", {"TEST" => "description"})
      expect(EnvSettings.description("TEST")).to eq("description")
    end
  end #end ".description"
  
  describe ".missing_vars" do
    it "should return missing required variables" do
      EnvSettings.set("required", {"WOOPS" => "this one is missing"})
      allow(ENV).to receive(:[]).with("WOOPS").and_return(nil)
      expect(EnvSettings.missing_vars).to eq(["WOOPS"])
    end
  end #end ".missing_vars"
  
  describe ".optional_vars" do
    it "should return the optional variables" do
      EnvSettings.set("optional", {"ABC" => 123})
      expect(EnvSettings.optional_vars).to eq(["ABC"])
    end
  end #end ".optional_vars"
  
  describe ".optional_default" do
    it "should return the default value for an optional variable" do
      EnvSettings.set("optional", {"ABC" => 123})
      expect(EnvSettings.optional_default("ABC")).to eq(123)
    end
  end #end ".optional_default"
  
  describe ".console_output_msg" do
    it "should return the default value for an optional variable" do
      allow(subject).to receive(:missing_vars).and_return(["HOMEY"])
      allow(subject).to receive(:description).with("HOMEY").and_return("Boyz in the hood")
      expect(EnvSettings.console_output_msg).to eq("\nEnvSettings: Missing Required Environment Variables! \n\n   HOMEY (Boyz in the hood) \n\n")
    end
  end #end ".console_output_msg"
  
  describe ".environment_configured?" do
    before do
      EnvSettings.set("required", {"REQ_VAR" => "something"})
    end

    describe "when running test environment" do
      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(true)
      end
      it "should return true" do
        expect(subject.environment_configured?).to eq(true)
      end
    end
    describe "when running all other environments" do
      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
      end
      describe "when all required vars are present" do
        before do
          allow(ENV).to receive(:[]).with("REQ_VAR").and_return('value')
        end
        it "should return true" do
          expect(subject.environment_configured?).to eq(true)
        end
      end
      describe "when some required vars are not present" do
        before do
          allow(ENV).to receive(:[]).with("REQ_VAR").and_return(nil)
        end
        it "should return false" do
          expect(subject.environment_configured?).to eq(false)
        end
      end
    end
  end #end ".environment_configured?"

  describe ".[]" do
    before do
      EnvSettings.set("required", {"REQ_VAR" => "something"})
      EnvSettings.set("optional", {"OPT_VAR" => "the default!"})
    end

    describe "when variable not configured in REQUIRED_VARS or OPTIONAL_VARS" do
      it "should not raise error when 'enabled' option is disabled" do
        expect{subject['UNCONFIGURED_VAR']}.not_to raise_error
      end
      it "should raise error when 'enabled' option is enabled" do
        subject.set_option("enabled", true)
        expect{subject['UNCONFIGURED_VAR']}.to raise_error ArgumentError
      end
    end
    describe "when variable configured in REQUIRED_VARS or OPTIONAL_VARS" do
      describe "when variable is in REQUIRED_VARS" do
        before do
          allow(ENV).to receive(:[]).with('REQ_VAR').and_return('coolness')
        end
        it "should return value from environment" do
          expect(subject['REQ_VAR']).to eq('coolness')
        end
      end
      describe "when variable is in OPTIONAL_VARS" do
        describe "and variable configured in environment" do
          before do
            allow(ENV).to receive(:[]).with('OPT_VAR').and_return('sweetness')
          end
          it "should return value from environment" do
            expect(subject['OPT_VAR']).to eq('sweetness')
          end
        end
        describe "and variable not configured in environment" do
          before do
            allow(ENV).to receive(:[]).with('OPT_VAR').and_return(nil)
          end
          it "should return default" do
            expect(subject['OPT_VAR']).to eq("the default!")
          end
        end
      end
    end

  end #end ".[]"

  describe ".var_present?" do

    describe "when variable present in environment" do
      before do
        allow(ENV).to receive(:[]).with("A_VAR").and_return("a value")
      end
      it "should return true" do
        expect(subject.var_present?("A_VAR")).to eq(true)
      end
    end

    describe "when variable not present in environment" do
      before do
        allow(ENV).to receive(:[]).with("A_VAR").and_return(nil)
      end
      it "should return false" do
        expect(subject.var_present?("A_VAR")).to eq(false)
      end
    end

  end #end ".var_present?"
end
