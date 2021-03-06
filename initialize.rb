require 'sinatra'
require 'dotenv'
require 'data_mapper'
#require './payment_details'


puts "initialize.rb called"
Dotenv.load

configure do
  set :environment =>  ENV['RACK_ENV']
  enable :sessions
end

set :protection, :except => [:http_origin]

use Rack::Protection::HttpOrigin, :origin_whitelist => ['http://jodymichael.com',
                                                        'http://www.jodymichael.com',
                                                        'http://www.careercheetah.net',
                                                        'http://careercheetah.net',
                                                        'http://localhost:8000']

