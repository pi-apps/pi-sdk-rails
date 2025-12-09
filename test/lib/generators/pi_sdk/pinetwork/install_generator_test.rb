require "test_helper"
require "generators/pinetwork/install/install_generator"

module PiSdk
  class PiSdk::InstallGeneratorTest < Rails::Generators::TestCase
    tests PiSdk::InstallGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
