require 'sinatra'
require 'http'

counter = 0

set :environment, :production

get '/' do
  status_codes = [200, 201, 202, 301, 302, 400, 401, 403, 404, 500, 502, 503]
  status status_codes.sample
  <<~HTML
    <h1>flaky app</h1>
    <p>endpoints to simulate backend issues:</p>
    
    <ul>
      <li><code>/</code> - random status code</li>
      <li><code>/status/404</code> - specific status code</li>
      <li><code>/flaky/50</code> - fails 50% of the time</li>
      <li><code>/delay/5</code> - 5 second delay</li>
      <li><code>/memory/10</code> - allocate 10mb</li>
      <li><code>/cpu/2</code> - cpu spike for 2s</li>
      <li><code>/chain/3</code> - 3 chained requests</li>
      <li><code>/size/1024</code> - 1mb response</li>
      <li><code>/stream/10</code> - stream for 10s</li>
      <li><code>/headers</code> - show request headers</li>
    </ul>
  HTML
end

get '/headers' do
  content_type 'text/plain'
  request.env.map { |k,v| "#{k.sub(/^HTTP_/, '')}: #{v}" }
         .join("\n")
end

get '/status/:code' do |code|
  code = code.to_i
  if code < 100 || code > 599
    status 400
    "Status code must be between 100-599"
  else
    status code
    "Returned status code #{code}"
  end
end

get '/flaky/:failure_rate' do |failure_rate|
  rate = failure_rate.to_i
  if rate < 0 || rate > 100
    status 400
    "Failure rate must be between 0 and 100"
  else
    if rand(100) < rate
      status 500
      "Simulated failure"
    else
      "Success!"
    end
  end
end

get '/delay/:seconds' do |seconds|
  seconds = seconds.to_f
  if seconds < 0 || seconds > 30
    status 400
    "Delay must be between 0 and 30 seconds"
  else
    sleep seconds
    "Waited #{seconds} seconds"
  end
end

# Simulate memory leak
get '/memory/:mb' do |mb|
  mb = mb.to_i
  if mb < 0 || mb > 100
    status 400
    "Memory allocation must be between 0-100 MB"
  else
    @data ||= []
    @data << ' ' * (mb * 1_000_000)  # Allocate MB of memory
    "Allocated #{mb}MB. Total allocations: #{@data.length}"
  end
end

# Simulate CPU intensive task
get '/cpu/:seconds' do |seconds|
  seconds = seconds.to_f
  if seconds < 0 || seconds > 10
    status 400
    "CPU time must be between 0-10 seconds"
  else
    end_time = Time.now + seconds
    counter = 0
    while Time.now < end_time
      counter += 1
    end
    "Performed #{counter} iterations in #{seconds} seconds"
  end
end

# Chain of dependent requests
get '/chain/:depth' do |depth|
  depth = depth.to_i
  if depth < 0 || depth > 5
    status 400
    "Chain depth must be between 0-5"
  else
    response = "Chain #{depth}: "
    if depth > 0
      sleep 0.1  # Simulate some work
      next_response = HTTP.get("http://localhost:#{request.port}/chain/#{depth - 1}").to_s
      response += next_response
    end
    response
  end
end

# Random response size
get '/size/:kb' do |kb|
  kb = kb.to_i
  if kb < 0 || kb > 25600  # 25MB = 25600KB
    status 400
    "Size must be between 0-25600 KB (0-25MB)"
  else
    'x' * (kb * 1024)
  end
end

# Simulate slow response with chunks
get '/stream/:seconds' do |seconds|
  seconds = seconds.to_f
  if seconds < 0 || seconds > 30
    status 400
    "Stream time must be between 0-30 seconds"
  else
    stream do |out|
      (seconds * 2).to_i.times do |i|
        out << "Chunk #{i + 1}\n"
        sleep 0.5
      end
    end
  end
end

