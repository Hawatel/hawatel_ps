module HawatelPS
  ##
  # = HawatelPS Exception
  class HawatelPSException < Exception
    # Custom exception
    # @param args [Hash] the options to create a custom exception message
    # @option :exception [Exception] Native Exception object
    # @option :message [String] Custom message
    # @return [void]
    def initialize(args = {:exception => nil, :message => nil})
      super(exception_enrichment(args))
    end

    private
    def exception_enrichment(args)
      error_message = ''
      error_message += args[:message] unless args[:message].nil?
      error_message +=
          "\nNative exception from '#{args[:exception].class}':\n#{args[:exception].message}" unless args[:exception].nil?
      return error_message
    end
  end
end