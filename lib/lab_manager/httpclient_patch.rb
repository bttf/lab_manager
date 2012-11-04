#
# Monkey Patch HTTP Client
# Sets SSL verify mode to NONE so that we can connect to an SSL server
# that does not have a trusted certificate.
#
# The 1.8.7 patch adds a new constructor.
# The 1.9.3 patch intercepts the existing constructor now that the class
# name has changed.

if Kernel.const_defined? :HTTPAccess2
  class HTTPAccess2::Client
    def initialize(*args)
      super(args[0], args[1])
      @session_manager.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #@session_manager.debug_dev = STDOUT
    end
  end
elsif Kernel.const_defined? :HTTPClient
  class HTTPClient
    alias_method :original_initialize, :initialize
    def initialize(*args)
      original_initialize(args[0], args[1])
      @session_manager.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #@session_manager.debug_dev = STDOUT
    end
  end
end

