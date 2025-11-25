require File.expand_path(File.dirname(__FILE__)) + "/spec_helper"

describe "Retry Demo" do
  it "demonstrates retry (will fail twice, then pass)" do
    @attempt_count ||= 0
    @attempt_count += 1

    puts "\n*** Attempt ##{@attempt_count} ***"
    expect(@attempt_count).to be >= 3
  end
end
