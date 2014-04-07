require 'spec_helper'

describe CleanApiDefenderStatisticsJob do

  it 'ensures that not raises error' do
    lambda do
      CleanApiDefenderStatisticsJob.perform
    end.should_not raise_exception
  end

  it 'ensures that cleans only old statistics' do
    today = Date.today
    Timecop.freeze(today) do
      key1 = "throttle:key1:#{today.strftime('%Y-%m-%d')}"
      key2 = "throttle:key2:#{today.strftime('%Y-%m-%d')}T01"
      key3 = "throttle:key1:#{(today - 32.days).strftime('%Y-%m-%d')}"
      key4 = "throttle:key2:#{(today - 32.days).strftime('%Y-%m-%d')}T01"
      key5 = "other:throttle:key:#{(today - 32.days).strftime('%Y-%m-%d')}"
      @redis_instance.set key1, 1
      @redis_instance.set key2, 1
      @redis_instance.set key3, 1
      @redis_instance.set key4, 1
      @redis_instance.set key5, 1

      CleanApiDefenderStatisticsJob.perform
      @redis_instance.keys.should include(key1, key2, key5)
      @redis_instance.keys.should_not include(key3, key4)
    end
  end

end
