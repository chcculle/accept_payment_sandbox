$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sinatra'
require 'dotenv'
require 'json'
require 'data_mapper'
require 'yaml'
require './credit_card'
require './cc_date_helper'
require './initialize'
include CCDateHelper
require './payment_details'
require './coach_old'

  
# automatically create the payment table
PaymentDetails.auto_upgrade!

configure do
  puts "configure called"

end

helpers do
  puts "helpers called"
  def categories
    puts "is nil categories? #{@categories.nil?}"
    @categories ||= Category.all
  end

  def coaches
    @coaches ||= Coach.all
  end

  def url_root
  if ENV['RACK_ENV'] == 'development' then
    @url_root = "localhost:9393"
  else
    @url_root = "https://"+APP_NAME+".herokuapp.com"
  end
  end
end


get '/' do
  begin 
    categories
    coaches
    url_root
    erb :send_jma_payment_form
    rescue Exception => e
      puts e.backtrace
      puts "rescue caught in / #{e.message}"
    end
end


get '/send_client_welcome_email' do
    erb :send_client_welcome_email
end

get '/send_interview_email' do
    erb :send_interview_email
end

get '/send_payment_email' do
    erb :send_jma_payment_form
end

#tested
post '/send_payment_email' do
  # send payment form.   read parameters, generate html, and send email.
  puts "/send_payment_email called params:  #{params}"
  @payment_details = PaymentDetails.new
  @payment_details.name=params[:name]
  @payment_details.email=params[:email]
  if params[:amount].size > 0
    @payment_details.amount=params[:amount]
  else 
    @payment_details.amount = 0
  end

  if params[:category].size > 0
    @payment_details.category=params[:category]
  end
  if params[:coach_name].size > 0
    @payment_details.coach = Coach.find_by_name(params[:coach_name])
    end
  

  
  email = Mailer.send_jma_email_payment_link(
  @payment_details.name,
  @payment_details.email,
  @payment_details.amount,
  @payment_details.category,
  @payment_details.coach
  )
  email.deliver
  #redirect to some thank you page
  erb :payment_email_sent
end

 def format_date(a_date)
    @end_str = {'1' => 'st', '2' => 'nd', '3' => 'rd', '4' =>'th', '5' =>'th', '6' => "th", '7' => "th", '8' => "th", '9' => "th", '0' => "th" }
  
      retval = ""
      if(a_date != nil)
        date_arr = a_date.split(/\\|-/)
        rev_date = Date.parse("#{date_arr[1]}/#{date_arr[0]}/#{date_arr[2]}")
        retval = rev_date.strftime('%A, %B') + " " +rev_date.strftime('%d').to_i.to_s+ @end_str[rev_date.strftime('%d').to_i.to_s]
      end
      retval
    end
    
post '/show_send_welcome_email_format' do
 # send payment form.   read parameters, generate html, and send email.
  puts "post /test_format params #{params}"
  @name=params[:name]
  @email=params[:email]
  if params[:amount].size > 0
    @amount=params[:amount].to_f
  else 
    @amount = 0
  end
  @appt_date = params[:appt_date]
  @appt_date_s = format_date(@appt_date)
  @payment_details_date = params[:payment_date]
  @payment_details_date_s = format_date(@payment_details_date)
  
  puts "call test_send_welcome_email @amount #{@amount}"
  erb :test_send_welcome_email
end

post '/send_welcome_email' do
  # send payment form.   read parameters, generate html, and send email.
  puts "post /send_welcome_email params #{params}"
  @payment_details = PaymentDetails.new
  @payment_details.name=params[:name]
  @payment_details.email=params[:email]
  if params[:amount].size > 0
    @payment_details.amount=params[:amount]
    if params[:category].size > 0
      @payment_details.category=params[:category]
    end
  else 
    @payment_details.amount = 0
  end
  if params[:coach_name].size > 0
    @payment_details.coach = Coach.find_by_name(params[:coach_name])
    end
  
  @appt_date = params[:appt_date]
  @payment_details_date = params[:payment_date]

  @appt_start = params[:appt_start][0..-4]
  @appt_end = params[:appt_end]
  @location = params[:location]
    
  email = Mailer.send_welcome_email(
  @payment_details.name,
  @payment_details.email,
  @payment_details.amount,
  @payment_details.category,
  @appt_date,
  @payment_details_date,
  @appt_start,
  @appt_end,
  @payment_details.coach,
  @location
  )
  email.deliver
  #redirect to some thank you page
  erb :welcome_email_sent
end

post '/send_interview_email' do
  # send payment form.   read parameters, generate html, and send email.
  puts "post /send_interview_email params #{params}"
  @payment_details = PaymentDetails.new
  @payment_details.name=params[:name]
  @payment_details.email=params[:email]
  if params[:amount].size > 0
    @payment_details.amount=params[:amount]
    if params[:category].size > 0
      @payment_details.category=params[:category]
    end
  else 
    @payment_details.amount = 0
  end
  
  @appt_date = params[:appt_date]
  @payment_details_date = params[:payment_date]
  @appt_start = params[:appt_start][0..-4]
  @appt_end = params[:appt_end]
  @location = params[:location]
  puts "coach name #{coach_name} start time #{@appt_start} end time #{@appt_end}"
  @location = params[:location]
  
  @payment_details.coach = Coach.find_by_name(params[:coach])
    
  email = Mailer.send_interview_email(
  @payment_details.name,
  @payment_details.email,
  @payment_details.amount,
  @appt_date,
  @payment_details_date,
  @appt_start,
  @appt_end,
  @payment_details.coach,
  @payment_details.category,
  @location
  )
  email.deliver
  #redirect to some thank you page
  erb :welcome_email_sent
end
                                     
get '/jma_payment_form' do
  puts "hello /jma_payment_form"
  
  #fill in default values for testing
  @payment_details = PaymentDetails.jma_template_payment
  @submit_callback = '/jma_submit_payment'
  if  params[:amount] != nil
    @payment_details.amount = params[:amount].to_f
  else @payment_details.amount = 0
  end

  puts "coach #{params[:coach_id]} "
  if  params[:category] != nil
    @payment_details.category = params[:category] 
  end
  puts "coach #{params[:coach_id]} "
  puts "@payment_details.category.nil? #{@payment_details.category.nil?}"
  puts "payment_details.category #{@payment_details.category}"
  if  params[:coach_id] != nil
    @payment_details.coach = Coach.find_by_id(params[:coach_id])
    puts "@payment_details.coach #{@payment_details.coach}"
  end
  erb :payment_form, :layout => :jma_layout
end

post '/jma_submit_payment' do
  
  puts "/jma_submit_payment #{params[:coach_id]}"
  @payment_details = PaymentDetails.new
  @payment_details.name=params[:name].strip()
  @payment_details.email=params[:email].strip()
  @payment_details.phone=params[:phone].strip()
  @payment_details.cc_number=params[:cc_number].strip()
  @payment_details.exp_month= params[:cc_month]
  @payment_details.exp_year=params[:cc_year]
  @payment_details.ccv=params[:ccv].strip()
  @payment_details.address=params[:address].strip()
  @payment_details.city=params[:city].strip()
  @payment_details.state= params[:state].strip()
  @payment_details.zip=params[:zip].strip()
  if params[:amount] != nil 
    @payment_details.amount=params[:amount]
    if params[:category].size > 0
      @payment_details.category=params[:category]
    end
  else 
    @payment_details.amount=0
  end
  if !params[:coach_id].nil?
    @payment_details.coach=Coach.find_by_id(params[:coach_id])
  end
  if !params[:coach_name].nil?
    @payment_details.coach=Coach.find_by_name(params[:coach_name])
  end

   if !@payment_details.valid?
    @submit_callback = '/jma_submit_payment'
    erb :payment_form, :layout => :jma_layout
  else
   

    description='Jody Michael Associates'
    puts "call ArrowPayment.new"
    arrow_payment = ArrowPayment.new()
    

    payment_error = arrow_payment.submit_new_client_payment(
      @payment_details,
      description
    )

    if payment_error.nil?
      puts "Payment info submitted successfully for #{@payment_details.name} amount: #{@payment_details.amount} "
      # send confirmation email
      email = Mailer.send_jma_email_confirm(
      @payment_details.name,
      @payment_details.amount,
      @payment_details.email
      )
      email.deliver
      if @payment_details.amount > 0
        payment = Payment.new
        payment.populate(@payment_details.name,
          @payment_details.amount,
          @payment_details.coach,
          @payment_details.category)
        payment[:status] = PAID
        payment.save
      puts "call submit_online_payment payment: #{payment.name}, #{payment.amount}"
      end
      @payment_details.created_at = Time.now
      @payment_details.save!
      
      
       # send email to jma staff      print "$ " + @payment_details.amount.to_s
      
      #email = Mailer.credit_card_charged_email_to_jma_support(
      #  @payment_details.name,
      #  "$ " + @payment_details.amount.to_s,
      #  @payment_details.email
      # )
      #OR
      email = Mailer.credit_card_info_received_to_jma_support(
        @payment_details.name,
        @payment_details.amount,
       )
       puts "call deliver from credit_card_info_received"
      email.deliver
      
      if @payment_details.amount > 0
        redirect to("http://www.jodymichael.com/payment-processed-thank-you")
      else
        redirect to("http://www.jodymichael.com/payment-info-thank-you")
      end
    else
      @payment_details.errors = [payment_error]
      erb :payment_form
    end
  end
end

  post '/done' do
  puts "/done called done:  #{params[:done]}   params: #{params}"
    if params[:done] == 'Continue'
      erb :send_jma_payment_form
    end
  end
  

def production
  puts "production?  called "
  ENV['RACK_ENV'] == 'production'
end

def development
  puts "development?  called "
  ENV['RACK_ENV'] == 'development'
end


