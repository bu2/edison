require File.expand_path '../../feature_helper', __FILE__

When(/^John and Tom increment the counter with id "(.+?)" by (\d+) times each at the same time$/) do |id, times|
  children = []
  N_MAX = 10
  DELAY_MIN = 0.01
  times.to_i.times do
    children << Process.fork do
      begin
        authenticate_as_john
        post "/api/counters/#{id}/lock", '{}', { 'CONTENT_TYPE' => 'application/json' }
        n = 1
        delay = DELAY_MIN
        while last_response.status != 200 and n <= N_MAX
          sleep delay
          post "/api/counters/#{id}/lock", '{}', { 'CONTENT_TYPE' => 'application/json' }
          n = n + 1
          delay = delay * 2
        end
        if last_response.status == 200
          STDERR.puts 'John succeeds to acquire lock on counter.'
        else
          raise 'John failed to acquire lock on counter!'
        end
        counter = parse(last_response.body)
        count = counter['count']
        patch "/api/counters/#{id}", { count: count+1, _lock: false }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      rescue
        STDERR.puts $!
      end
    end
    children << Process.fork do
      begin
        authenticate_as_tom
        post "/api/counters/#{id}/lock", '{}', { 'CONTENT_TYPE' => 'application/json' }
        n = 1
        delay = DELAY_MIN
        while last_response.status != 200 and n <= N_MAX
          sleep delay
          post "/api/counters/#{id}/lock", '{}', { 'CONTENT_TYPE' => 'application/json' }
          n = n + 1
          delay = delay * 2
        end
        if last_response.status == 200
          STDERR.puts 'Tom succeeds to acquire lock on counter.'
        else
          raise 'Tom failed to acquire lock on counter!'
        end
        counter = parse(last_response.body)
        count = counter['count']
        patch "/api/counters/#{id}", { count: count+1, _lock: false }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      rescue
        STDERR.puts $!
      end
    end
  end
  children.each { |child| Process.wait(child) }
end
