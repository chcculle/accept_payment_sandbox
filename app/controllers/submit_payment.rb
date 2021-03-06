$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sinatra'
require 'dotenv'
require 'json'
require 'data_mapper'
require 'yaml'
require './credit_card'
require './cc_date_helper'
#require './initialize'
include CCDateHelper
require './payment_details'
#require './coach_old'

  
# automatically create the payment table
PaymentDetails.auto_upgrade!

configure do
end

helpers do
  def categories
    @categories ||= Category.all.order('id')
  end

  def logged_in?
    if session[:user_id].nil?
      puts "false"
      return false
    else
      puts "true"
      return true
    end
  end

  def login?
    if session[:user_id].nil?
      return false
    else
      return true
    end
  end

  def coaches
    @coaches ||= Coach.all.order('id')
  end

  def url_root
    if ENV['RACK_ENV'] == 'development' then
      @url_root = "localhost:9393"
    else
      @url_root = "https://"+APP_NAME+".herokuapp.com"
    end
  end
end


get '/xxxx' do
  begin 
    categories
    coaches
    url_root
    @callback_method = "/send_payment_email"
    erb :send_jma_payment_form
    rescue Exception => e
      puts e.backtrace
      puts "rescue caught in / #{e.message}"
    end
end

get '/send_payment_email' do
  redirect "/login" unless session[:user_id]
    categories
    coaches
    url_root
    @callback_method = "/send_payment_email"
    erb :send_jma_payment_form
end

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
    @payment_details.category=Category.find_by_name(params[:category])
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
  @amount = 0
  if !@payment_details.amount.nil?
    @amount = @payment_details.amount
  end
  Log.new_entry "Payment email sent to #{@payment_details.name} #{@payment_details.email} amount: $#{@amount}"
  @on_complete_msg = "Payment Email Sent."
  @on_complete_redirect=  "/done"
  @on_complete_method=  "post"
  erb :done
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

get '/deposit_check_form' do
  redirect "/login" unless session[:user_id]
  @errors = []
  @submit_callback = '/submit_deposit_check'
  erb :deposit_check_form
end

post '/submit_deposit_check' do
  @errors = []
  puts "/submit_deposit_check"
  @payment_details = PaymentDetails.new
  @payment_details.name=params[:name].strip()

  if params[:amount] != nil 
    @payment_details.amount=params[:amount]
  else 
    @payment_details.amount=0
  end
  if params[:category_name] != nil
    @payment_details.category=Category.find_by_name(params[:category_name])
  end
  if !params[:coach_name].nil?
    @payment_details.coach=Coach.find_by_name(params[:coach_name])
  end
   client = Client.find_by_name(@payment_details.name)
  if client.nil?
    client = Client.new
    client.name = @payment_details.name
    client.coach = @payment_details.coach
    client.category = @payment_details.category
    client.save
  end
  payment = Payment.new
  payment.populate(@payment_details.name,
  @payment_details.amount,
  @payment_details.coach,
  @payment_details.category)
  payment.transaction_type = CHECK
  payment[:status] = PAID
  payment.save

  Log.new_entry "Check Deposit from: #{@payment_details.name} amount: $#{@payment_details.amount} for: #{@payment_details.category.name} coach: #{@payment_details.coach.name}"
  erb :deposit_check_form
end

get '/arrow_payment_form' do
  redirect "/login" unless session[:user_id]
  @errors = []
  @submit_callback = '/submit_arrow_payment'
  erb :arrow_payment_form
end

post '/submit_arrow_payment' do

  @errors = []
  puts "/submit_arrow_payment "
  @payment_details = PaymentDetails.new
  @payment_details.name=params[:name].strip()

  if params[:amount] != nil 
    @payment_details.amount=params[:amount]
  else 
    @payment_details.amount=0
  end
  if params[:category_name] != nil
    @payment_details.category=Category.find_by_name(params[:category_name])
  end
  if !params[:coach_name].nil?
    @payment_details.coach=Coach.find_by_name(params[:coach_name])
  end

   if !@payment_details.valid_for_quick_pay?
    @submit_callback = '/submit_arrow_payment'
    erb :payment_form, :layout => :jma_layout
  else
    arrow_payment = ArrowPayment.new()
    description = @payment_details.name + "-" + @payment_details.category.name+"-"+@payment_details.amount.to_s

    payment_error = arrow_payment.submit_recurring_payment(
      @payment_details.name,
      @payment_details.amount,
      description
    )
    if payment_error.nil?
      puts "Payment info submitted successfully for #{@payment_details.name} amount: #{@payment_details.amount} "

       client = Client.find_by_name(@payment_details.name)
      if client.nil?
        client = Client.new
        client.name = @payment_details.name
        client.coach = @payment_details.coach
        client.category = @payment_details.category
        client.client_type = "New"
        client.save
      end
      payment = Payment.new
      payment.populate(@payment_details.name,
      @payment_details.amount,
      @payment_details.coach,
      @payment_details.category)
      payment.transaction_type = CREDIT_CARD
      payment[:status] = PAID
      payment.save

    Log.new_entry "Submit Arrow Payment from: #{@payment_details.name} amount: $#{@payment_details.amount} for: #{@payment_details.category.name} coach: #{@payment_details.coach.name}"
  
    else
      @errors = [payment_error]
      puts "Error Encountered #{payment_error}  error_count:  #{@errors.count}"
    end
  end
  if @errors
    puts "calling arrow_payment_form"
      erb :arrow_payment_form
  else
    erb :arrow_payment_form
  end
end
                                     
get '/jma_payment_form' do

  #spinner = Spinner.new

# Add a task block
#spinner.task("Number 1") do
  #sleep(5) # simulate taking a while to do something awesome

  
  #fill in default values for testing
  @payment_details = PaymentDetails.jma_template_payment
  @submit_callback = '/jma_submit_payment'
  if  params[:amount] != nil
    @payment_details.amount = params[:amount].to_f
  else @payment_details.amount = 0
  end

  puts "coach: #{params[:coach_id]}  category: #{params[:category_id]}  "
  if  params[:category_id] != nil
    @payment_details.category = Category.find_by_id(params[:category_id] )
    puts "category: #{@payment_details.category}"
  end
  puts "coach #{params[:coach_id]} "
  puts "@payment_details.category.nil? #{@payment_details.category.nil?}"
  puts "payment_details.category #{@payment_details.category}"
  if  params[:coach_id] != nil
    @payment_details.coach = Coach.find_by_id(params[:coach_id])
    puts "@payment_details.coach #{@payment_details.coach}"
  end
  erb :payment_form2, :layout => :min_layout
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

  if @payment_details.exp_month.size == 1
    @payment_details.exp_month = "0"+ @payment_details.exp_month
  end

 if params[:amount] != nil 
    @payment_details.amount=params[:amount]
  else 
    @payment_details.amount=0
  end

  if params[:category_id] != nil
    @payment_details.category=Category.find_by_id(params[:category_id])
  else
    if params[:category_name] != nil
      @payment_details.category=Category.find_by_name(params[:category_name])
    end
  end
  if !params[:coach_id].nil?
    @payment_details.coach=Coach.find_by_id(params[:coach_id])
  else
    if !params[:coach_name].nil?
      @payment_details.coach=Coach.find_by_name(params[:coach_name])
    end
  end

   if !@payment_details.valid?
    @submit_callback = '/jma_submit_payment'
    erb :payment_form2, :layout => :min_layout
  else
    description='Jody Michael Associates'
    puts "call ArrowPayment.new"
    arrow_payment = ArrowPayment.new()
    

    payment_error = arrow_payment.submit_new_client_payment(
      @payment_details,
      description
    )

    if payment_error.nil?
      puts "Payment info submitted successfully for #{@payment_details.name} amount: #{@payment_details.amount}  coach: #{@payment_details.coach} category: #{@payment_details.category}"
      # send confirmation email
      email = Mailer.send_jma_email_confirm(
      @payment_details.name,
      @payment_details.amount,
      @payment_details.email
      )
      email.deliver
      if @payment_details.amount > 0
        payment = Payment.new
        payment.transaction_type = CREDIT_CARD
        payment.populate(@payment_details.name,
          @payment_details.amount,
          @payment_details.coach,
          @payment_details.category)
        payment[:status] = PAID        
        puts "Attempt to add to Payment  #{payment}"
        payment.save
        puts "call submit_online_payment payment: #{payment.name}, #{payment.amount} #{payment.transaction_type}"
      end
      @payment_details.created_at = Time.now
      @payment_details.save!

      @amount = 0
      if !@payment_details.amount.nil?
        @amount = @payment_details.amount
      end
      Log.new_entry "New client credit card payment submitted: #{@payment_details.name} amount: $#{@amount} for: #{@payment_details.category.name} coach: #{@payment_details.coach.name}"
  
      
       #create client
      client = Client.find_by_name(@payment_details.name)
      if client.nil?
        puts "Client #{@payment_details.name} not found.  Create new client"
        client = Client.new
        client.name = @payment_details.name
        client.coach = @payment_details.coach
        client.category = @payment_details.category
        client.email = @payment_details.email
        client.address = @payment_details.address
        client.city = @payment_details.city
        client.state = @payment_details.state
        client.zip = @payment_details.zip
        client.phone = @payment_details.phone
        client.client_type = "New"
        puts "Client created #{client.coach}, #{client.category}"
        client.save
      end
      
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
      erb :payment_form2, :layout => :min_layout
    end
  end
end

  post '/done' do
  puts "/done called done:  #{params[:done]}   params: #{params}"
  erb :send_jma_payment_form
  end
  

def production
  puts "production?  called "
  ENV['RACK_ENV'] == 'production'
end

def development
  puts "development?  called "
  ENV['RACK_ENV'] == 'development'
end


