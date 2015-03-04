require 'vanagon/utilities'
require 'vanagon/errors'

class Vanagon
  class Engine
    class Base
      attr_accessor :target, :target_user

      def initialize(platform, target = nil)
        @platform = platform
        @required_attributes = ["ssh_port"]
        @target = target if target
        @target_user = "root"
      end

      # This method is used to obtain a vm to build upon
      # For the base class we just return the target that was passed in
      def select_target
        @target or raise Vanagon::Error.new('#select_target has not been implemented for your engine.')
      end

      # Steps needed to tear down or clean up the system after the build is
      # complete
      def teardown
      end

      # Applies the steps needed to extend the system to build packages against
      # the target system
      def setup
        script = @platform.provisioning.join(' ; ')
        Vanagon::Utilities.remote_ssh_command("#{@target_user}@#{@target}", script, @platform.ssh_port)
      end

      # This method will take care of validation and target selection all at
      # once as an easy shorthand to call from the driver
      def startup
        validate_platform
        select_target
        setup
      end

      # Ensures that the platform defines the attributes that the engine needs to function.
      #
      # @raise [Vanagon::Error] an error is raised if a needed attribute is not defined
      def validate_platform
        missing_attrs = []
        @required_attributes.each do |attr|
          if (not @platform.instance_variables.include?("@#{attr}".to_sym)) or @platform.instance_variable_get("@#{attr}".to_sym).nil?
            missing_attrs << attr
          end
        end

        if missing_attrs.empty?
          return true
        else
          raise Vanagon::Error.new("The following required attributes were not set in '#{@platform.name}': #{missing_attrs.join(', ')}.")
        end
      end
    end
  end
end