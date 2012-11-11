class Configuration

  def self.parse(data)

    if !data.keys.empty? && data.keys.first != "Configuration"
      data = data.values[0]
    end

    configuration = Configuration.new
    data_config = data["Configuration"]
    if data_config
      configuration.id = data_config["id"]
      configuration.name = data_config["name"]
      configuration.deployed = data_config["isDeployed"] == "true" ? true : false
    end

    configuration
  end

  attr_accessor :id
  attr_accessor :name
  attr_accessor :deployed
end
