require "spec/spec_helper"

module RR
  describe Double do
    attr_reader :space, :object, :double_insertion, :double
    before do
      @space = Space.new
      @object = Object.new
      def object.foobar(a, b)
        [b, a]
      end
      @double_insertion = space.double_insertion(object, :foobar)
      @double = space.double(double_insertion)
    end

    describe "#with" do
      it "returns DoubleDefinition" do
        double.with(1).should === double.definition
      end

      it "sets an ArgumentEqualityExpectation" do
        double.with(1)
        double.should be_exact_match(1)
        double.should_not be_exact_match(2)
      end

      it "sets return value when block passed in" do
        double.with(1) {:return_value}
        object.foobar(1).should == :return_value
      end
    end

    describe "#with_any_args" do
      before do
        double.with_any_args {:return_value}
      end

      it "returns DoubleDefinition" do
        double.with_no_args.should === double.definition
      end

      it "sets an AnyArgumentExpectation" do
        double.should_not be_exact_match(1)
        double.should be_wildcard_match(1)
      end

      it "sets return value when block passed in" do
        object.foobar(:anything).should == :return_value
      end
    end

    describe "#with_no_args" do
      before do
        double.with_no_args {:return_value}
      end

      it "returns DoubleDefinition" do
        double.with_no_args.should === double.definition
      end

      it "sets an ArgumentEqualityExpectation with no arguments" do
        double.argument_expectation.should == Expectations::ArgumentEqualityExpectation.new()
      end

      it "sets return value when block passed in" do
        object.foobar().should == :return_value
      end
    end

    describe "#never" do
      it "returns DoubleDefinition" do
        double.never.should === double.definition
      end

      it "sets up a Times Called Expectation with 0" do
        double.never
        proc {double.call(double_insertion)}.should raise_error(Errors::TimesCalledError)
      end

      it "sets return value when block passed in" do
        double.with_any_args.never
        proc {double.call(double_insertion)}.should raise_error(Errors::TimesCalledError)
      end
    end

    describe "#once" do
      it "returns DoubleDefinition" do
        double.once.should === double.definition
      end

      it "sets up a Times Called Expectation with 1" do
        double.once
        double.call(double_insertion)
        proc {double.call(double_insertion)}.should raise_error(Errors::TimesCalledError)
      end

      it "sets return value when block passed in" do
        double.with_any_args.once {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#twice" do
      it "returns DoubleDefinition" do
        double.twice.should === double.definition
      end

      it "sets up a Times Called Expectation with 2" do
        double.twice
        double.call(double_insertion)
        double.call(double_insertion)
        proc {double.call(double_insertion)}.should raise_error(Errors::TimesCalledError)
      end

      it "sets return value when block passed in" do
        double.with_any_args.twice {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#at_least" do
      it "returns DoubleDefinition" do
        double.with_any_args.at_least(2).should === double.definition
      end

      it "sets up a AtLeastMatcher with 2" do
        double.at_least(2)
        double.definition.times_matcher.should == TimesCalledMatchers::AtLeastMatcher.new(2)
      end

      it "sets return value when block passed in" do
        double.with_any_args.at_least(2) {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#at_most" do
      it "returns DoubleDefinition" do
        double.with_any_args.at_most(2).should === double.definition
      end

      it "sets up a Times Called Expectation with 1" do
        double.at_most(2)
        double.call(double_insertion)
        double.call(double_insertion)
        proc do
          double.call(double_insertion)
        end.should raise_error(
        Errors::TimesCalledError,
        "foobar()\nCalled 3 times.\nExpected at most 2 times."
        )
      end

      it "sets return value when block passed in" do
        double.with_any_args.at_most(2) {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#times" do
      it "returns DoubleDefinition" do
        double.times(3).should === double.definition
      end

      it "sets up a Times Called Expectation with passed in times" do
        double.times(3)
        double.call(double_insertion)
        double.call(double_insertion)
        double.call(double_insertion)
        proc {double.call(double_insertion)}.should raise_error(Errors::TimesCalledError)
      end

      it "sets return value when block passed in" do
        double.with_any_args.times(3) {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#any_number_of_times" do
      it "returns DoubleDefinition" do
        double.any_number_of_times.should === double.definition
      end

      it "sets up a Times Called Expectation with AnyTimes matcher" do
        double.any_number_of_times
        double.times_matcher.should == TimesCalledMatchers::AnyTimesMatcher.new
      end

      it "sets return value when block passed in" do
        double.with_any_args.any_number_of_times {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#ordered" do
      it "adds itself to the ordered doubles list" do
        double.ordered
        space.ordered_doubles.should include(double)
      end

      it "does not double_insertion add itself" do
        double.ordered
        double.ordered
        space.ordered_doubles.should == [double ]
      end

      it "sets ordered? to true" do
        double.ordered
        double.should be_ordered
      end

      it "sets return value when block passed in" do
        double.with_any_args.once.ordered {:return_value}
        object.foobar.should == :return_value
      end
    end

    describe "#ordered?" do
      it "defaults to false" do
        double.should_not be_ordered
      end
    end
    
    describe "#yields" do
      it "returns DoubleDefinition" do
        double.yields(:baz).should === double.definition
      end

      it "yields the passed in argument to the call block when there is no returns value set" do
        double.with_any_args.yields(:baz)
        passed_in_block_arg = nil
        object.foobar {|arg| passed_in_block_arg = arg}.should == nil
        passed_in_block_arg.should == :baz
      end

      it "yields the passed in argument to the call block when there is a no returns value set" do
        double.with_any_args.yields(:baz).returns(:return_value)

        passed_in_block_arg = nil
        object.foobar {|arg| passed_in_block_arg = arg}.should == :return_value
        passed_in_block_arg.should == :baz
      end

      it "sets return value when block passed in" do
        double.with_any_args.yields {:return_value}
        object.foobar {}.should == :return_value
      end
    end

    describe "#after_call" do
      it "returns DoubleDefinition" do
        double.after_call {}.should === double.definition
      end

      it "sends return value of Double implementation to after_call" do
        return_value = {}
        double.returns(return_value).after_call do |value|
          value[:foo] = :bar
          value
        end

        actual_value = double.call(double_insertion)
        actual_value.should === return_value
        actual_value.should == {:foo => :bar}
      end

      it "receives the return value in the after_call callback" do
        return_value = :returns_value
        double.returns(return_value).after_call do |value|
          :after_call_value
        end

        actual_value = double.call(double_insertion)
        actual_value.should == :after_call_value
      end

      it "allows after_call to mock the return value" do
        return_value = Object.new
        double.with_any_args.returns(return_value).after_call do |value|
          mock(value).inner_method(1) {:baz}
          value
        end

        object.foobar.inner_method(1).should == :baz
      end

      it "raises an error when not passed a block" do
        proc do
          double.after_call
        end.should raise_error(ArgumentError, "after_call expects a block")
      end
    end

    describe "#returns" do
      it "returns DoubleDefinition" do
        double.returns {:baz}.should === double.definition
        double.returns(:baz).should === double.definition
      end

      it "sets the value of the method when passed a block" do
        double.returns {:baz}
        double.call(double_insertion).should == :baz
      end

      it "sets the value of the method when passed an argument" do
        double.returns(:baz)
        double.call(double_insertion).should == :baz
      end

      it "returns false when passed false" do
        double.returns(false)
        double.call(double_insertion).should == false
      end

      it "raises an error when both argument and block is passed in" do
        proc do
          double.returns(:baz) {:another}
        end.should raise_error(ArgumentError, "returns cannot accept both an argument and a block")
      end
    end

    describe "#implemented_by" do
      it "returns the DoubleDefinition" do
        double.implemented_by(proc{:baz}).should === double.definition
      end

      it "sets the implementation to the passed in proc" do
        double.implemented_by(proc{:baz})
        double.call(double_insertion).should == :baz
      end

      it "sets the implementation to the passed in method" do
        def object.foobar(a, b)
          [b, a]
        end
        double.implemented_by(object.method(:foobar))
        double.call(double_insertion, 1, 2).should == [2, 1]
      end
    end

    describe "#implemented_by_original_method" do
      it "returns the DoubleDefinition object" do
        double.implemented_by_original_method.should === double.definition
      end

      it "sets the implementation to the original method" do
        double.implemented_by_original_method
        double.call(double_insertion, 1, 2).should == [2, 1]
      end

      it "calls methods when respond_to? is true and methods does not contain original method" do
        method_name = nil
        class << object
          def methods
            []
          end
          def method(name)
            raise "We should not be here"
          end
          def respond_to?(name)
            true
          end
          def method_missing(method_name, *args, &block)
            raise "We should not be here"
          end
        end

        double_insertion = space.double_insertion(object, :foobar)
        double = space.double(double_insertion)
        double.with_any_args
        double.implemented_by_original_method

        object.foobar(1, 2).should == [2, 1]
      end

      it "calls method when original_method does not exist" do
        class << object
          def method_missing(method_name, *args, &block)
            "method_missing for #{method_name}(#{args.inspect})"
          end
        end
        double_insertion = space.double_insertion(object, :does_not_exist)
        double = space.double(double_insertion)
        double.with_any_args
        double.implemented_by_original_method

        return_value = object.does_not_exist(1, 2)
        return_value.should == "method_missing for does_not_exist([1, 2])"
      end
    end

    describe "#call implemented by a proc" do
      it "calls the return proc when implemented by a proc" do
        double.returns {|arg| "returning #{arg}"}
        double.call(double_insertion, :foobar).should == "returning foobar"
      end

      it "calls and returns the after_call when after_call is set" do
        double.returns {|arg| "returning #{arg}"}.after_call do |value|
          "#{value} after call"
        end
        double.call(double_insertion, :foobar).should == "returning foobar after call"
      end

      it "returns nil when to returns is not set" do
        double.call(double_insertion).should be_nil
      end

      it "works when times_called is not set" do
        double.returns {:value}
        double.call(double_insertion)
      end

      it "verifes the times_called does not exceed the TimesCalledExpectation" do
        double.times(2).returns {:value}

        double.call(double_insertion, :foobar)
        double.call(double_insertion, :foobar)
        proc {double.call(double_insertion, :foobar)}.should raise_error(Errors::TimesCalledError)
      end

      it "raises DoubleOrderError when ordered and called out of order" do
        double1 = double
        double2 = space.double(double_insertion)

        double1.with(1).returns {:return_1}.ordered.once
        double2.with(2).returns {:return_2}.ordered.once

        proc do
          object.foobar(2)
        end.should raise_error(
        Errors::DoubleOrderError,
        "foobar(2) called out of order in list\n" <<
        "- foobar(1)\n" <<
        "- foobar(2)"
        )
      end

      it "dispatches to Space#verify_ordered_double when ordered" do
        verify_ordered_double_called = false
        passed_in_double = nil
        space.method(:verify_ordered_double).arity.should == 1
        (
        class << space;
          self;
        end).class_eval do
          define_method :verify_ordered_double do |double|
            passed_in_double = double
            verify_ordered_double_called = true
          end
        end

        double.returns {:value}.ordered
        double.call(double_insertion, :foobar)
        verify_ordered_double_called.should be_true
        passed_in_double.should === double
      end

      it "does not dispatche to Space#verify_ordered_double when not ordered" do
        verify_ordered_double_called = false
        space.method(:verify_ordered_double).arity.should == 1
        (
        class << space;
          self;
        end).class_eval do
          define_method :verify_ordered_double do |double|
            verify_ordered_double_called = true
          end
        end

        double.returns {:value}
        double.call(double_insertion, :foobar)
        verify_ordered_double_called.should be_false
      end

      it "does not add block argument if no block passed in" do
        double.with(1, 2).returns {|*args| args}

        args = object.foobar(1, 2)
        args.should == [1, 2]
      end

      it "makes the block the last argument" do
        double.with(1, 2).returns {|a, b, blk| blk}

        block = object.foobar(1, 2) {|a, b| [b, a]}
        block.call(3, 4).should == [4, 3]
      end

      it "raises ArgumentError when yields was called and no block passed in" do
        double.with(1, 2).yields(55)

        proc do
          object.foobar(1, 2)
        end.should raise_error(ArgumentError, "A Block must be passed into the method call when using yields")
      end
    end

    describe "#call implemented by a method" do
      it "sends block to the method" do
        def object.foobar(a, b)
          yield(a, b)
        end

        double.with(1, 2).implemented_by(object.method(:foobar))

        object.foobar(1, 2) {|a, b| [b, a]}.should == [2, 1]
      end
    end
    
    describe "#exact_match?" do
      it "returns false when no expectation set" do
        double.should_not be_exact_match()
        double.should_not be_exact_match(nil)
        double.should_not be_exact_match(Object.new)
        double.should_not be_exact_match(1, 2, 3)
      end

      it "returns false when arguments are not an exact match" do
        double.with(1, 2, 3)
        double.should_not be_exact_match(1, 2)
        double.should_not be_exact_match(1)
        double.should_not be_exact_match()
        double.should_not be_exact_match("does not match")
      end

      it "returns true when arguments are an exact match" do
        double.with(1, 2, 3)
        double.should be_exact_match(1, 2, 3)
      end
    end

    describe "#wildcard_match?" do
      it "returns false when no expectation set" do
        double.should_not be_wildcard_match()
        double.should_not be_wildcard_match(nil)
        double.should_not be_wildcard_match(Object.new)
        double.should_not be_wildcard_match(1, 2, 3)
      end

      it "returns true when arguments are an exact match" do
        double.with(1, 2, 3)
        double.should be_wildcard_match(1, 2, 3)
        double.should_not be_wildcard_match(1, 2)
        double.should_not be_wildcard_match(1)
        double.should_not be_wildcard_match()
        double.should_not be_wildcard_match("does not match")
      end

      it "returns true when with_any_args" do
        double.with_any_args

        double.should be_wildcard_match(1, 2, 3)
        double.should be_wildcard_match(1, 2)
        double.should be_wildcard_match(1)
        double.should be_wildcard_match()
        double.should be_wildcard_match("does not match")
      end
    end

    describe "#attempt?" do
      it "returns true when TimesCalledExpectation#attempt? is true" do
        double.with(1, 2, 3).twice
        double.call(double_insertion, 1, 2, 3)
        double.times_called_expectation.should be_attempt
        double.should be_attempt
      end

      it "returns false when TimesCalledExpectation#attempt? is true" do
        double.with(1, 2, 3).twice
        double.call(double_insertion, 1, 2, 3)
        double.call(double_insertion, 1, 2, 3)
        double.times_called_expectation.should_not be_attempt
        double.should_not be_attempt
      end

      it "returns true when there is no Times Called expectation" do
        double.with(1, 2, 3)
        double.definition.times_matcher.should be_nil
        double.should be_attempt
      end
    end

    describe "#verify" do
      it "verifies that times called expectation was met" do
        double.twice.returns {:return_value}

        proc {double.verify}.should raise_error(Errors::TimesCalledError)
        double.call(double_insertion)
        proc {double.verify}.should raise_error(Errors::TimesCalledError)
        double.call(double_insertion)

        proc {double.verify}.should_not raise_error
      end

      it "does not raise an error when there is no times called expectation" do
        proc {double.verify}.should_not raise_error
        double.call(double_insertion)
        proc {double.verify}.should_not raise_error
        double.call(double_insertion)
        proc {double.verify}.should_not raise_error
      end
    end

    describe "#terminal?" do
      it "returns true when times_called_expectation's terminal? is true" do
        double.once
        double.times_called_expectation.should be_terminal
        double.should be_terminal
      end

      it "returns false when times_called_expectation's terminal? is false" do
        double.any_number_of_times
        double.times_called_expectation.should_not be_terminal
        double.should_not be_terminal
      end

      it "returns false when there is no times_matcher" do
        double.definition.times_matcher.should be_nil
        double.should_not be_terminal
      end
    end

    describe "#method_name" do
      it "returns the DoubleInjection's method_name" do
        double_insertion.method_name.should == :foobar
        double.method_name.should == :foobar
      end
    end

    describe "#expected_arguments" do
      it "returns argument expectation's expected_arguments when there is a argument expectation" do
        double.with(1, 2)
        double.expected_arguments.should == [1, 2]
      end

      it "returns an empty array when there is no argument expectation" do
        double.argument_expectation.should be_nil
        double.expected_arguments.should == []
      end
    end

    describe "#formatted_name" do
      it "renders the formatted name of the Double with no arguments" do
        double.formatted_name.should == "foobar()"
      end

      it "renders the formatted name of the Double with arguments" do
        double.with(1, 2)
        double.formatted_name.should == "foobar(1, 2)"
      end
    end
  end
end