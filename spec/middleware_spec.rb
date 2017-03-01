require 'spec_helper'

describe EnvSettings::Middleware do
  
  let!(:app) { double("app object") }
  let!(:subject) { described_class.new(app) }

  let!(:options) {
    { "enabled" => true, "always" => false, "log" => true}
  }

  before do
    allow(Rails).to receive_message_chain(:logger, :info)
    options.each do |option, value|
      EnvSettings.set_option(option, value)
    end
  end

  describe ".call" do
    it "should log the summary if it has not already been logged and set logged variable to true" do
      EnvSettings.set_option("enabled", false)
      allow(app).to receive(:call).with("env")
      expect(EnvSettings).to receive(:console_output_msg)
      subject.call("env")
      expect(EnvSettings.logged?).to eq(true)
    end
    it "should not log the summary if it has already been logged" do
      EnvSettings.set_option("enabled", false)
      allow(app).to receive(:call).with("env")
      allow(EnvSettings).to receive(:logged?).and_return(true)
      expect(EnvSettings).not_to receive(:console_output_msg)
      subject.call("env")
    end
    describe "when the 'log' option is disabled" do      
      it "should not log the summary" do
        EnvSettings.set_option("enabled", false)
        EnvSettings.set_option("log", false)
        allow(app).to receive(:call).with("env")
        expect(EnvSettings).not_to receive(:console_output_msg)
        subject.call("env")
      end
    end
    describe "when 'enabled' option is false" do
      it "should call the app without doing anything else" do
        EnvSettings.set_option("enabled", false)
        expect(app).to receive(:call).with("env")
        subject.call("env")
      end
    end
    describe "when the environment is configured" do
      it "should call the app without doing anything else" do
        allow(EnvSettings).to receive(:environment_configured?).and_return(true)
        expect(app).to receive(:call).with("env")
        subject.call("env")
      end
    end
    describe "when the environment is not configured" do
      before do
        allow(EnvSettings).to receive(:environment_configured?).and_return(false)
      end
      
      describe "when the 'always' option is enabled" do      
        it "should not call the app" do
          EnvSettings.set_option("always", true)
          allow(EnvSettings).to receive(:console_output)
          allow(subject).to receive(:respond_with_html)
          expect(app).not_to receive(:call).with("env")
          subject.call("env")
        end
      end
    end
  end #end ".call"

  describe ".respond_with_html" do
    before do
      allow(subject).to receive(:html_template).and_return("T")
    end
      
    it "should check to see if the environment is configured, run through each var, and return a response object" do
      EnvSettings.set("required", {"ONE" => "yup"})
      EnvSettings.set("optional", {"TWO" => "default"})
      expect(EnvSettings).to receive(:environment_configured?).and_return(true)
      expect(EnvSettings).to receive_message_chain(:required_vars, :sort, :each)
      expect(EnvSettings).to receive_message_chain(:optional_vars, :sort, :each)
      expect(subject.respond_with_html).to eq([200, { "Content-Type" => "text/html", "Content-Length" => "1"}, "T"])
    end
  end #end ".respond_with_html"
  
end
