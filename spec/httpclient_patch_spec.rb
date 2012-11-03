require 'spec_helper'
require 'net/https'
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require 'soap/element'
require 'soap/netHttpClient'

require 'lab_manager'

describe "HTTP Environment" do

  context "ruby environment" do

    context "ruby 1.8.7" do
      it "fails to reference HTTPClient", :ruby18 => true do
        Object.const_get(:HTTPClient).should be_true
      end
      it "references HTTPAccess2 sucessfully", :ruby18 => true do
        Object.const_get(:HTTPAccess2).should be_true
      end
    end

    context "ruby 1.9.3" do
      it "references HTTPClient successfully", :ruby19 => true do
        Object.const_get(:HTTPClient).should be_true
      end
      it "fails to references HTTPAccess2", :ruby19 => true do
        expect {
          Object.const_get(:HTTPAccess2)
        }.to raise_error
      end
    end

    context "after patch" do
      context "verbose flag" do
        let(:client) {
          LabManager.url = "http://soap.amazon.com/schemas2/AmazonWebServices.wsdl"
          lab = LabManager.new("ORG", "USERNAME", "PASSWORD")
          lab.send(:proxy).streamhandler.client
        }

        context "ruby 1.8" do
          it "is true", :ruby18 => true do
            client.should be_instance_of HTTPAccess2::Client
            client.ssl_config.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
          end
        end

        context "ruby 1.9" do
          it "is true", :ruby19 => true do
            client.should be_instance_of HTTPClient
            client.ssl_config.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
          end
        end
      end
    end
  end
end
