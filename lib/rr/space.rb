module RR
  # RR::Space is a Dependency Injection http://en.wikipedia.org/wiki/Dependency_injection
  # and global state object for the RR framework. The RR::Space.instance
  # is a singleton that holds the state.
  class Space
    class << self
      def instance
        @instance ||= new
      end
      attr_writer :instance
      
      protected
      def method_missing(method_name, *args, &block)
        instance.__send__(method_name, *args, &block)
      end
    end

    attr_reader :doubles, :ordered_scenarios
    def initialize
      @doubles = Hash.new {|hash, subject_object| hash[subject_object] = Hash.new}
      @ordered_scenarios = []
    end

    # Creates a MockCreator.
    def create_mock_creator(subject, &definition)
      MockCreator.new(self, subject, &definition)
    end

    # Creates a StubCreator.
    def create_stub_creator(subject, &definition)
      StubCreator.new(self, subject, &definition)
    end

    # Creates a ProbeCreator.
    def create_probe_creator(subject, &definition)
      ProbeCreator.new(self, subject, &definition)
    end

    # Creates a DoNotAllowCreator.
    def create_do_not_allow_creator(subject, &definition)
      DoNotAllowCreator.new(self, subject, &definition)
    end

    # Creates and registers a Scenario to be verified.
    def create_scenario(double)
      scenario = Scenario.new(self)
      double.register_scenario scenario
      scenario
    end

    # Reuses or creates, if none exists, a Double for the passed
    # in object and method_name.
    # When a Double is created, it binds the dispatcher to the
    # object.
    def create_double(object, method_name)
      double = @doubles[object][method_name.to_sym]
      return double if double

      double = Double.new(self, object, method_name.to_sym)
      @doubles[object][method_name.to_sym] = double
      double.bind
      double
    end

    # Registers the ordered Scenario to be verified.
    def register_ordered_scenario(scenario)
      @ordered_scenarios << scenario
    end

    # Verifies that the passed in ordered Scenario is being called
    # in the correct position.
    def verify_ordered_scenario(scenario)
      raise Errors::ScenarioOrderError unless @ordered_scenarios.first == scenario
      @ordered_scenarios.shift if scenario.times_called_verified?
      scenario
    end

    # Verifies all the Double objects have met their
    # TimesCalledExpectations.
    def verify_doubles
      @doubles.each do |object, method_double_map|
        method_double_map.keys.each do |method_name|
          verify_double(object, method_name)
        end
      end
    end

    # Resets the registered Doubles for the next test run.
    def reset_doubles
      @doubles.each do |object, method_double_map|
        method_double_map.keys.each do |method_name|
          reset_double(object, method_name)
        end
      end
    end

    # Verifies the Double for the passed in object and method_name.
    def verify_double(object, method_name)
      @doubles[object][method_name].verify
    ensure
      reset_double object, method_name
    end

    # Resets the Double for the passed in object and method_name.
    def reset_double(object, method_name)
      double = @doubles[object].delete(method_name)
      @doubles.delete(object) if @doubles[object].empty?
      double.reset
    end
  end
end