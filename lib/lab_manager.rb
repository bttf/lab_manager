require 'net/https'
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require 'soap/element'
require 'soap/netHttpClient'
require 'xsd/datatypes'
require 'yaml'

require 'lab_manager/machine'

require 'lab_manager/httpclient_patch'

#
# Lab Manager API
#
# Configure using configure method:
#
#   LabManager.url = "YOUR URL"
#
class LabManager

  @@DEBUG = false

  def self.DEBUG=(value)
    @@DEBUG = value
  end

  def self.configPath
    @@configPath
  end
  def self.configPath=(value)
    @@configPath = value
  end

  def self.url
    @@url
  end
  def self.url=(value)
    @@url = value
  end
  def self.username
    @@username
  end
  def self.password
    @@password
  end

  def self.reset
    @@configPath = File.expand_path("~/.lab_manager")

    @@url = nil
    @@username = nil
    @@password = nil
  end
  reset

  attr_accessor :workspace

  def initialize(organization, username = nil, password = nil, url = nil)
    load_config(url, username, password)
    raise "Missing url" if @@url.nil?
    raise "Missing username" if @@username.nil?
    raise "Missing password" if @@password.nil?

    @organization = organization
  end

  #<GetConfigurationByName xmlns="http://vmware.com/labmanager">
  #  <name>string</name>
  #</GetConfigurationByName>
  #
  #<GetConfigurationByNameResponse xmlns="http://vmware.com/labmanager">
  #  <GetConfigurationByNameResult>
  #    <Configuration>
  #      <id>int</id>
  #      <name>string</name>
  #      <description>string</description>
  #      <isPublic>boolean</isPublic>
  #      <isDeployed>boolean</isDeployed>
  #      <fenceMode>int</fenceMode>
  #      <type>int</type>
  #      <owner>string</owner>
  #      <dateCreated>dateTime</dateCreated>
  #      <autoDeleteInMilliSeconds>double</autoDeleteInMilliSeconds>
  #      <bucketName>string</bucketName>
  #      <mustBeFenced>NotSpecified or True or False</mustBeFenced>
  #      <autoDeleteDateTime>dateTime</autoDeleteDateTime>
  #    </Configuration>
  #
  def configuration(name)
    proxy.GetConfigurationByName(:name => name)
  end

  #  <ListMachines xmlns="http://vmware.com/labmanager">
  #    <configurationId>int</configurationId>
  #  </ListMachines>
  #
  #  <ListMachinesResponse xmlns="http://vmware.com/labmanager">
  #    <ListMachinesResult>
  #      <Machine>
  #        <id>int</id>
  #        <name>string</name>
  #        <description>string</description>
  #        <internalIP>string</internalIP>
  #        <externalIP>string</externalIP>
  #        <macAddress>string</macAddress>
  #        <memory>int</memory>
  #        <status>int</status>
  #        <isDeployed>boolean</isDeployed>
  #        <configID>int</configID>
  #        <DatastoreNameResidesOn>string</DatastoreNameResidesOn>
  #        <HostNameDeployedOn>string</HostNameDeployedOn>
  #        <OwnerFullName>string</OwnerFullName>
  #      </Machine>
  #
  #   lab_manager.machines("CONFIG NAME")
  #   lab_manager.machines("CONFIG NAME", :exclude => ["machine name"])
  #
  def machines(configurationName, options = {})
    configuration = proxy.GetConfigurationByName(:name => configurationName)
    configurationId = configuration["GetConfigurationByNameResult"]["Configuration"]["id"]

    data = proxy.ListMachines(:configurationId => configurationId)

    machines = Machine.from_list(data)

    if (!options[:exclude].nil?)
      machines = machines.find_all { |machine| 
        !options[:exclude].include?(machine.name)
      } 
    end

    machines
  end

  def machine(configurationName, machineName)
    machines(configurationName).find { |machine|
      machine.name == machineName
    }
  end

  private
  def proxy
    factory = SOAP::WSDLDriverFactory.new("#{@@url}?WSDL")
    proxy = factory.create_rpc_driver
    proxy.wiredump_dev = STDOUT if @@DEBUG
    proxy.generate_explicit_type = false  # No datatype with request
    proxy.headerhandler << LabManagerHeader.new(@organization, @workspace, @@username, @@password)

    #proxy.streamhandler.client.ssl_config.verify_mode = false

    proxy
  end

  def load_config(url, username, password)
    if File.exists? @@configPath
      config = YAML::load_file(@@configPath)
      @@url = config["url"]
      @@username = config["username"]
      @@password = config["password"]
    end
    
    @@url = url if !url.nil?
    @@username = username if !username.nil?
    @@password = password if !password.nil?
  end
end

#  <soap:Header>
#    <AuthenticationHeader xmlns="http://vmware.com/labmanager">
#      <username>string</username>
#      <password>string</password>
#      <organizationname>string</organizationname>
#      <workspacename>string</workspacename>
#    </AuthenticationHeader>
#  </soap:Header>
class LabManagerHeader < SOAP::Header::Handler

  def initialize(organization, workspace, username, password)
    super(XSD::QName.new("http://vmware.com/labmanager", ""))
    @organization = organization
    @workspace = workspace
    @username = username
    @password = password
  end

  def on_outbound
    authentication = SOAP::SOAPElement.new('AuthenticationHeader')
    authentication.extraattr['xmlns'] = 'http://vmware.com/labmanager'
    
    authentication.add(SOAP::SOAPElement.new('username', @username))
    authentication.add(SOAP::SOAPElement.new('password', @password))
    authentication.add(SOAP::SOAPElement.new('organizationname', @organization))
    authentication.add(SOAP::SOAPElement.new('workspacename', @workspace)) if @workspace
    
    SOAP::SOAPHeaderItem.new(authentication, true)
  end
end
