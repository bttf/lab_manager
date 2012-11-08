require 'spec_helper'
require 'lab_manager'
require 'flexmock'
require 'tmpdir'

describe LabManager do

  before do
    LabManager.reset
  end

  context "configuration" do

    context "none" do
      it "raises an error" do
        expect {
          LabManager.new("SOME ORG", "username", "password")
        }.to raise_error
      end
    end

    context "with file" do
      before do
        LabManager.configPath = "#{Dir.tmpdir}/configFile"
        File.open(LabManager.configPath, "w+") do |fd|
          fd.write("url: some_url:1234/path?parameters=values")
        end
      end

      after do
        File.delete(LabManager.configPath)
      end

      it "loads a config file" do
        LabManager.new("SOME ORG", "username", "password")

        LabManager.url.should == "some_url:1234/path?parameters=values"
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

    context "converts raw data to data structure" do

      let(:mockLab) {
        mockProxy = flexmock("proxy")
        mockProxy.should_receive(:GetConfigurationByName).and_return(configurationData)
        mockProxy.should_receive(:ListMachines).and_return(machineData)

        mockLab = flexmock(lab)
        mockLab.should_receive(:proxy).and_return(mockProxy)

        mockLab
      }

      let(:lab) { LabManager.new("SOME ORG", "username", "password") }

      let(:configurationData) {
        {
          "GetConfigurationByNameResult" =>  {
            "Configuration" => { "id" => "configurationId"}
          }
        }
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
          machines = mockLab.machines("some configuration")

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
          machines = mockLab.machines("some configuration")

          machines[0].name.should == "MACHINE1"
          machines[0].internal_ip.should == "1.1.1.1"
          machines[0].external_ip.should == "2.2.2.2"

          machines[1].name.should == "MACHINE2"
          machines[1].internal_ip.should == "3.3.3.3"
          machines[1].external_ip.should == "4.4.4.4"
        end

        it "returns machines excluding specific machines" do
          machines = mockLab.machines("some configuration", :exclude => ["MACHINE1"])

          machines.size.should == 1

          machines[0].name.should == "MACHINE2"
          machines[0].internal_ip.should == "3.3.3.3"
          machines[0].external_ip.should == "4.4.4.4"
        end

        it "returns empty array if all machines are excluded" do
          machines = mockLab.machines("some configuration", :exclude => ["MACHINE1", "MACHINE2"])

          machines.should == []
        end

        it "returns all machines if the excluded macine does not exist" do
          machines = mockLab.machines("some configuration", :exclude => ["MISSING MACHINE"])

          machines.size == 2
        end

        it "returns a single machine configuration that matches the name" do
          machine = mockLab.machine("some configuration", "MACHINE1")

          machine.name.should == "MACHINE1"
          machine.internal_ip.should == "1.1.1.1"
          machine.external_ip.should == "2.2.2.2"
        end

        it "returns nil of the machine requested is not found" do
          mockLab.machine("some confuguration", "MISSING MACHINE").should be_nil
        end

        it "returns nil if nil was passed in" do
          mockLab.machine("some confuguration", nil).should be_nil
          mockLab.machine(nil, nil).should be_nil
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
          mockLab.machines("some confogiiuration").should == []
        end

        it "returns an empty array if te argymet is nil" do
          mockProxy = flexmock("proxy")
          mockProxy.should_receive(:GetConfigurationByName).and_return(configurationData)
          mockProxy.should_receive(:ListMachines).and_return(nil)

          mockLab = flexmock(lab)
          mockLab.should_receive(:proxy).and_return(mockProxy)

          mockLab.machines("some conf").should == []
        end

        it "returns an empty array if the result is nil" do
          machineData["ListMachinesResult"] = nil

          mockLab.machines("some cofn").should == []
        end

        it "returns a machine that is nil" do
          machineData["ListMachinesResult"]["Machine"] = nil

          mockLab.machines("some cofn").should == []
        end
      end
    end
  end
end


