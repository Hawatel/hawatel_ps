require 'spec_helper'

describe HawatelPS::HawatelPSException do
  it 'catch exception' do
    expect {
      begin
        100 / 0
      rescue => ex
        raise HawatelPS::HawatelPSException.new({:exception => ex})
      end
    }.to raise_error(HawatelPS::HawatelPSException)
  end
end