require 'flexmock'

class Configuration

  def self.parse(data)

    configuration = Configuration.new

    if !data.__xmlele.empty?
      
      if data.__xmlele[0].first.name != "Configuration"
        data = data.__xmlele[0][1]
      end

      data_config = data["Configuration"]
      if data_config
        configuration.id = data_config["id"]
        configuration.name = data_config["name"]
        configuration.deployed = data_config["isDeployed"] == "true" ? true : false
      end
    end

    configuration
  end

  attr_accessor :id
  attr_accessor :name
  attr_accessor :deployed
end
