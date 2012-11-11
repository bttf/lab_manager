require 'spec_helper'
require 'flexmock'

require 'lab_manager/configuration'

describe Configuration do

  context "valid xm" do
    let(:deployed_config_data) {
      {
        "GetConfigurationByNameResult" =>  {
          "Configuration" => { 
            "id" => "12345",
            "name" => "a_config",
            "isDeployed" => "true",
            "isPublic" => "true",
            "description" => "A Nice configuration",
            "fenceMode" => "true",
            "mustBeFenced" => "NotSpecified",
            "type" => "2",
            "dateCreated" => "2012-11-07T14:24:29.01",
            "autoDeleteInMilliSeconds" => "0",
            "autoDeleteDateTime" => "9999-12-31T23:59:59.9999999",
          }
        }
      }
    }

    let(:undeployed_config_data) {
      {
        "GetConfigurationByNameResult" =>  {
          "Configuration" => { 
            "isDeployed" => "false",
          }
        }
      }
    }

    it "parses result data" do
      config = Configuration.parse(deployed_config_data)

      config.id.should == "12345"
      config.name.should == "a_config"
      config.deployed == true
    end

    it "parses config" do
      config = Configuration.parse(deployed_config_data["GetConfigurationByNameResult"])

      config.id.should == "12345"
      config.name.should == "a_config"
      config.deployed == true
    end

    it "parses config not deployed" do
      config = Configuration.parse(undeployed_config_data)

      config.deployed == false
    end

    it "returns no data i there is none" do
      config = Configuration.parse({})

      config.should_not be_nil
    end
  end

end
