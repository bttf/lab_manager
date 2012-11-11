require 'spec_helper'
require 'lab_manager'
require 'flexmock'
require 'tmpdir'

describe LabManager do

  before do
    LabManager.reset

    LabManager.DEBUG = true
  end

  context "configuration" do

    context "none" do
      it "raises an error" do
        LabManager.configPath = "INVALID FILE"
        expect {
          LabManager.new("SOME ORG", "username", "password")
        }.to raise_error
      end
    end

    context "with file" do
      before do
        LabManager.configPath = "#{Dir.tmpdir}/configFile"
        File.open(LabManager.configPath, "w+") do |fd|
          fd.write("url: some_url:1234/path?parameters=values\n")
          fd.write("username: conf_username\n")
          fd.write("password: conf_password\n")
        end
      end

      after do
        File.delete(LabManager.configPath)
      end

      it "loads a config file" do
        LabManager.new("SOME ORG")

        LabManager.url.should == "some_url:1234/path?parameters=values"
        LabManager.username.should == "conf_username"
        LabManager.password.should == "conf_password"
      end

      it "loads a config file and overrides username and password" do
        LabManager.new("SOME ORG", "arg_username", "arg_password", "arg_url")

        LabManager.url.should == "arg_url"
        LabManager.username.should == "arg_username"
        LabManager.password.should == "arg_password"
      end
    end

    context "with constructor parameter" do
      before do
        LabManager.configPath = "INVALID FILE NAME"
      end

      it "sets url using constructor url" do
        LabManager.new("SOME ORG", "username", "password", "A URL PARAMETER")

        LabManager.url.should == "A URL PARAMETER"
      end
    end

    context "with constant" do
      before do
        LabManager.url = "SOME URL"
      end

      it "allows construction with a url" do
        LabManager.new("SOME ORG", "username", "password")
      end
    end
  end

  context "configured" do
    before do
      LabManager.url = "SOME URL"
    end

    context "to bash" do

      context "present machine info to bash script" do

        let(:machines) { [ Machine.new({"name" => "a", "internalIP" => "1.1.1.1", "externalIP" => "2.2.2.2"}), 
                Machine.new({"name" => "b", "internalIP" => "3.3.3.3", "externalIP" => "4.4.4.4"}) ] }
        it "generates list of tab delimited values" do
                        
          out = capture_stdout { Machine.to_csv(machines) }
          out.should == "a,1.1.1.1,2.2.2.2\nb,3.3.3.3,4.4.4.4\n"
        end
      end

      def capture_stdout
        out = StringIO.new
        $stdout = out
        yield
        return out.string  
      ensure
        $stdout = STDOUT
      end
    end

    let(:configuration_data) {
      {
        "GetConfigurationByNameResult" =>  {
          "Configuration" => { "id" => "configurationId"}
        }
      }
    }

    let(:lab) { LabManager.new("SOME ORG", "username", "password") }
	
    context "retrieves configuration by name" do
      let(:mock_lab) {
        mock_proxy = flexmock("proxy")
        mock_proxy.should_receive(:GetConfigurationByName).and_return(configuration_data)

        mock_lab = flexmock(lab)
        mock_lab.should_receive(:proxy).and_return(mock_proxy)

        mock_lab
      }

      it "with a configuration name" do
        config = mock_lab.configuration("CONFIG NAME")

        config.should_not be_nil
      end
    end

    context "retrieves configuration by id" do
      let(:mock_lab) {
        mock_proxy = flexmock("proxy")
        mock_proxy.should_receive(:GetConfiguration).and_return(configuration_data)

        mock_lab = flexmock(lab)
        mock_lab.should_receive(:proxy).and_return(mock_proxy)

        mock_lab
      }

      it "with a configuration id" do
        config = mock_lab.configuration("12345")

        config.should_not be_nil
      end
    end

    context "converts machine raw data to data structure" do

      let(:mock_lab) {
        mock_proxy = flexmock("proxy")
        mock_proxy.should_receive(:GetConfigurationByName).and_return(configuration_data)
        mock_proxy.should_receive(:ListMachines).and_return(machineData)

        mock_lab = flexmock(lab)
        mock_lab.should_receive(:proxy).and_return(mock_proxy)

        mock_lab
      }

      context "when there is only one macine" do

        let(:machineData) {
          {
            "ListMachinesResult" => {
              "Machine" => [ 
                  {"name" => "MACHINE1", "internalIP" => "1.1.1.1", "externalIP" => "2.2.2.2" },
              ]
            }
          }
        }

        it "returns the machine name and internal ip address" do
          machines = mock_lab.machines("some configuration")

          machines[0].name.should == "MACHINE1"
          machines[0].internal_ip.should == "1.1.1.1"
          machines[0].external_ip.should == "2.2.2.2"
        end
      end

      context "when there are machines" do

        let(:machineData) {
          {
            "ListMachinesResult" => {
              "Machine" => [ 
                  {"name" => "MACHINE1", "internalIP" => "1.1.1.1", "externalIP" => "2.2.2.2" },
                  {"name" => "MACHINE2", "internalIP" => "3.3.3.3", "externalIP" => "4.4.4.4" },
              ]
            }
          }
        }

        it "returns a machine name and internal ip address" do
          machines = mock_lab.machines("some configuration")

          machines[0].name.should == "MACHINE1"
          machines[0].internal_ip.should == "1.1.1.1"
          machines[0].external_ip.should == "2.2.2.2"

          machines[1].name.should == "MACHINE2"
          machines[1].internal_ip.should == "3.3.3.3"
          machines[1].external_ip.should == "4.4.4.4"
        end

        it "returns machines excluding specific machines" do
          machines = mock_lab.machines("some configuration", :exclude => ["MACHINE1"])

          machines.size.should == 1

          machines[0].name.should == "MACHINE2"
          machines[0].internal_ip.should == "3.3.3.3"
          machines[0].external_ip.should == "4.4.4.4"
        end

        it "returns empty array if all machines are excluded" do
          machines = mock_lab.machines("some configuration", :exclude => ["MACHINE1", "MACHINE2"])

          machines.should == []
        end

        it "returns all machines if the excluded macine does not exist" do
          machines = mock_lab.machines("some configuration", :exclude => ["MISSING MACHINE"])

          machines.size == 2
        end

        it "returns a single machine configuration that matches the name" do
          machine = mock_lab.machine("some configuration", "MACHINE1")

          machine.name.should == "MACHINE1"
          machine.internal_ip.should == "1.1.1.1"
          machine.external_ip.should == "2.2.2.2"
        end

        it "returns nil of the machine requested is not found" do
          mock_lab.machine("some confuguration", "MISSING MACHINE").should be_nil
        end

        it "returns nil if nil was passed in" do
          mock_lab.machine("some confuguration", nil).should be_nil
          mock_lab.machine(nil, nil).should be_nil
        end
      end

      context "when there are no machines" do
        let(:machineData) {
          {
            "ListMachinesResult" => {
              "Machine" => [ 
              ]
            }
          }
        }

        it "returns an empty array if there are no machines" do
          mock_lab.machines("some confogiiuration").should == []
        end

        it "returns an empty array if te argymet is nil" do
          mock_proxy = flexmock("proxy")
          mock_proxy.should_receive(:GetConfigurationByName).and_return(configuration_data)
          mock_proxy.should_receive(:ListMachines).and_return(nil)

          mock_lab = flexmock(lab)
          mock_lab.should_receive(:proxy).and_return(mock_proxy)

          mock_lab.machines("some conf").should == []
        end

        it "returns an empty array if the result is nil" do
          machineData["ListMachinesResult"] = nil

          mock_lab.machines("some cofn").should == []
        end

        it "returns a machine that is nil" do
          machineData["ListMachinesResult"]["Machine"] = nil

          mock_lab.machines("some cofn").should == []
        end
      end
    end

    context "clones" do

      let(:clone_data) {
        { "ConfigurationCloneResult" => "12345" }
      }

      let(:mock_lab) {
        mock_proxy = flexmock("proxy")
        mock_proxy.should_receive(:GetConfigurationByName).and_return(configuration_data)
        mock_proxy.should_receive(:ConfigurationClone).and_return(clone_data)

        mock_lab = flexmock(lab)
        mock_lab.should_receive(:proxy).and_return(mock_proxy)

        mock_lab
      }

      it "retrurns the new configuration id" do
        conf_id = mock_lab.clone("SOME CONFIG", "NEW CONFIG")

        conf_id.should == "12345"
      end
    end

    context "delete" do
      let(:mock_lab) {
        mock_proxy = flexmock("proxy")
        mock_proxy.should_receive(:GetConfigurationByName).and_return(configuration_data)
        mock_proxy.should_receive(:ConfigurationDelete).and_return(nil)

        mock_lab = flexmock(lab)
        mock_lab.should_receive(:proxy).and_return(mock_proxy)

        mock_lab
      }

      it "returns nil for success" do
        result = mock_lab.delete("SOME CONFIG")

        result.should be_nil
      end
    end

    context "checkout" do
      let(:checkout_data) {
        { "ConfigurationCheckoutResult" => "54321" }
      }

      let(:mock_lab) {
        mock_proxy = flexmock("proxy")
        mock_proxy.should_receive(:GetConfigurationByName).and_return(configuration_data)
        mock_proxy.should_receive(:ConfigurationCheckout).and_return(checkout_data)

        mock_lab = flexmock(lab)
        mock_lab.should_receive(:proxy).and_return(mock_proxy)

        mock_lab
      }

      it "returns nil for success" do
        configuration_id = mock_lab.checkout("SOME CONFIG", "NEW CONFIG")

        configuration_id.should == "54321"
      end
    end
  end

  #
  # Integration tests. Add --tag integration to rspec run
  #
  # To inject your environments specifics use file based configuration in ~/.lab_manager
  #
  # The LabManager class uses the url, username and password values.
  # The LabManagerSpec class uses the organization, workspace and configuration values.
  #
  context "integrated" do
    before do
      @config = LabManager.send :config
    end
    let(:organization) { @config["organization"] }
    let(:workspace) { @config["workspace"] }
    let(:configuration) { @config["configuration"] }
    
    it "lists machines", :integration => true do
      lab = LabManager.new("POS")
      lab.workspace = workspace

      machines = lab.machines(configuration)

      machines.size().should > 0

      machines.each { |machine|
        machine.name.size().should > 0
        machine.internal_ip.should match /\d+\.\d+\.\d+\.\d+/
        machine.external_ip.should match /\d+\.\d+\.\d+\.\d+/
      }
    end

    it "clones and deletes a configuration", :integration => true do
      lab = LabManager.new("POS")
      lab.workspace = workspace

      result = lab.clone(configuration, "#{configuration}_new")

      result.should be_true

      lab.delete("#{configuration}_new")

      result.should be_true
    end
  end
end


