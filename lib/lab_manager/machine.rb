class Machine

  def self.fromList(data)
    return [] if data.nil?
    return [] if data["ListMachinesResult"].nil?
    return [] if data["ListMachinesResult"]["Machine"].nil?

    data["ListMachinesResult"]["Machine"].collect { |machine| 
      Machine.new(machine)
    }
  end

  def self.to_csv(machines)
   machines.each do |machine|
     puts machine.to_csv
    end
  end

  attr_reader :name, :internal_ip, :external_ip

  def initialize(machine)
    @name = machine["name"]
    @internal_ip = machine["internalIP"]
    @external_ip = machine["externalIP"]
  end
  
  def to_csv
    "#{name},#{internal_ip},#{external_ip}"
  end
end

