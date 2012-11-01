require 'net/https'
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require 'soap/element'
require 'xsd/datatypes'

require 'soap/netHttpClient'

require 'lab_manager/machine'

#
# Monkey Patch HTTP Client
# Sets SSL verify mode to NONE so that we can connect to an SSL server
# that does not have a trusted certificate.
#
# The 1.8.7 patch adds a new constructor.
# The 1.9.3 patch intercepts the existing constructor now that the class
# name has changed.
if RUBY_VERSION == "1.8.7"
  class HTTPAccess2::Client
    def initialize(*args)
      super(args[0], args[1])
      @session_manager.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #@session_manager.debug_dev = STDOUT
    end
  end
else # > 1.8.7
  class HTTPClient
    alias_method :original_initialize, :initialize
    def initialize(*args)
      original_initialize(args[0], args[1])
      @session_manager.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #@session_manager.debug_dev = STDOUT
    end
  end
end

#
# Lab Manager API
#
# Configure using configure method:
#
#   LabManager.url = "YOUR URL"
#
class LabManager

  @@url = nil
  def self.url
    @@url
  end
  def self.url=(value)
    @@url = value
  end

  attr_accessor :workspace

  def initialize(organization, username, password, url = nil)
    raise "Missing url" if @@url.nil?

    @organization = organization
    @username = username
    @password = password
    @@url = url
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

    machines = Machine.fromList(data)

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
    #proxy.wiredump_dev = STDOUT
    proxy.generate_explicit_type = false  # No datatype with request
    proxy.headerhandler << LabManagerHeader.new(@organization, @workspace, @username, @password)

    proxy
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
