require_relative 'spec_helper'

describe String do
  it "supports snaking on strings" do
    s = "FXToolBar"
    expect(s.snake).to eq("fx_tool_bar")
  end
end

describe Symbol do
  it "supports snaking on symbols" do
    s = :FXToolBar
    expect(s.snake).to eq(:fx_tool_bar)
  end
end

describe "DSL" do
  include Fox
  it "allows creation of the FXApp and one window" do
    app = fx_app :foobase do
      fx_main_window :main do
        title "test window"
        width 500
        height 300
      end
    end
  end
end

