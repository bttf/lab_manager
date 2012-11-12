require 'spec_helper'
require 'flexmock'
require 'ostruct'

require 'lab_manager/configuration'

describe Configuration do

  context "valid xm" do
    let(:deployed_config_data) {
      data = {
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

      config = [[OpenStruct.new(:name => "SOME_ROOT_ELEMENT"), data.values[0]]]

      mock_response = flexmock("config")
      mock_response.should_receive(:keys).and_throw "METHOD NOT FOUND"
      mock_response.should_receive(:[]).and_return(data.values[0])
      mock_response.should_receive(:__xmlele).and_return(config)
      
      mock_response
    }

    let(:deployed_config_data_as_root) {
      data = {
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

      config = [[OpenStruct.new(:name => "Configuration"), data.values[0]]]

      mock_response = flexmock("config")
      mock_response.should_receive(:keys).and_throw "METHOD NOT FOUND"
      mock_response.should_receive(:[]).and_return(data.values[0])
      mock_response.should_receive(:__xmlele).and_return(config)
      
      mock_response
    }

    let(:undeployed_config_data) {
      data = {
        "GetConfigurationByNameResult" =>  {
          "Configuration" => { 
            "isDeployed" => "false",
          }
        }
      }

      config = [[OpenStruct.new(:name => "SOME_ROOT_ELEMENT"), data.values[0]]]

      mock_response = flexmock("config")
      mock_response.should_receive(:keys).and_throw "METHOD NOT FOUND"
      mock_response.should_receive(:[]).and_return(data.values[0])
      mock_response.should_receive(:__xmlele).and_return(config)
      
      mock_response
    }

    it "parses result data" do
      config = Configuration.parse(deployed_config_data)

      config.id.should == "12345"
      config.name.should == "a_config"
      config.deployed == true
    end

    it "parses config" do
      config = Configuration.parse(deployed_config_data_as_root)

      config.id.should == "12345"
      config.name.should == "a_config"
      config.deployed == true
    end

    it "parses config not deployed" do
      config = Configuration.parse(undeployed_config_data)

      config.deployed == false
    end

    it "returns no data i there is none" do
      data = flexmock("no data")
      data.should_receive(:__xmlele).and_return([])
      data.should_receive(:[]).and_return([])

      config = Configuration.parse(data)

      config.should_not be_nil
    end
  end

end
