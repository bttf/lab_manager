require 'spec_helper'
require 'flexmock'

require 'lab_manager/machine'

describe Machine do

  context "from list" do
    it "constructs a list of machines" do
      data = {
        "ListMachinesResult" => {
          "Machine" => [
            {"name" => "machine1", "internalIP" => "1.1.1.1", "externalIP" => "2.2.2.2"},
            {"name" => "machine2", "internalIP" => "3.3.3.3", "externalIP" => "4.4.4.4"},
          ]
        }
      }

      machines = Machine.from_list(data)

      machines.size().should == 2
      machines[0].name.should == "machine1"
      machines[0].internal_ip.should == "1.1.1.1"
      machines[0].external_ip.should == "2.2.2.2"
      
      machines[1].name.should == "machine2"
      machines[1].internal_ip.should == "3.3.3.3"
      machines[1].external_ip.should == "4.4.4.4"
    end
    
    it "constructs a list of machine even if there is only one machine in the XML" do
      data = {
        "ListMachinesResult" => {
          "Machine" => {"name" => "machine1", "internalIP" => "1.1.1.1", "externalIP" => "2.2.2.2"},
        }
      }

      machines = Machine.from_list(data)

      machines.size().should == 1
      machines[0].name.should == "machine1"
      machines[0].internal_ip.should == "1.1.1.1"
      machines[0].external_ip.should == "2.2.2.2"
    end
  end
end

