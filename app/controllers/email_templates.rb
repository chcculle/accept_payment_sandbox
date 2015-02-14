$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sinatra'
require 'dotenv'
require 'json'
require 'data_mapper'
require 'yaml'
require './cc_date_helper'
#require './initialize'
include CCDateHelper
require 'chronic'

configure do
end

helpers do
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

def new_format_date(a_date)
  unless  a_date.size == 0 
    rev_date = Chronic.parse(a_date)
    puts "new_format_date a_date #{a_date}  rev_date #{rev_date}"
    rev_date.strftime('%A, %B') + " " +rev_date.strftime('%d').to_i.to_s
  else
    ''
  end
end

def get_params(params)
  puts "get_params params:  #{params}, how many  #{params.count}"

  @errors = []
  @text1 = params[:text1]
  @text2 = params[:text2]
  @text3 = params[:text3]
  @text4 = params[:text4]
  @text5 = params[:text5]
  @greeting = params[:greeting]
  @greeting1 = params[:greeting1]
  @greeting2 = params[:greeting2]
  @closing_text = params[:closing_text]
  @name = params[:name]
  @email = params[:email]
  @appt_date = params[:appt_date]
  if params[:appt_date]
    @appt_date_formatted = new_format_date(@appt_date)
  end
  @payment_date = params[:payment_date]
  if params[:payment_date]
    @payment_date_formatted = new_format_date(@payment_date)
  end
  @appt_start = params[:appt_start]
  @appt_end = params[:appt_end]
  @category_name = params[:category]
  @coach_name = params[:coach_name]
  @location = params[:location]
  @coach_id = params[:coach_id]
  @category_id = params[:category_id]
  @send_callback_method = params[:send_callback_method]
  @interview_text1 = params[:interview_text1]
  @interview_text2 = params[:interview_text2]
  @interview_text3 = params[:interview_text3]
  @template = params[:template]
  @payment_text = params[:payment_text]

  if params[:amount] && params[:amount].size > 0
    @amount=params[:amount].to_f
  else 
    @amount = 0
  end
  if !@coach_name.nil?  && @coach_name.size
    @coach = Coach.find_by_name(@coach_name)
  end

  if !@category_name.nil?  && @category_name.size
    @category = Category.find_by_name(@category_name)
  end

  if !@coach_id.nil?
    @coach = Coach.find(@coach_id)
  end
  if !@category_id.nil?
    @category = Category.find(@category_id)
  end
  if @coach.nil?
    @errors << "Please Enter Coach Name"
  end

  if @category.nil?
    @errors << "Please Enter Category Name"
  end

end

def show_param_results
  puts "#{@name}"
  puts "#{@email}"
  puts "#{@appt_date}"
  puts "#{@appt_date_formatted}"
  puts "#{@payment_date}"
  puts "#{@payment_date_formatted}"
  puts "#{@amount}"
  puts "#{@appt_start}"
  puts "#{@appt_end}"
  if @coach
    puts "#{@coach.name}"
  end
  if @category
    puts "#{@category.name}"
  end
  puts "#{@location}"
  puts "#{@text1}"
  puts "interview_text1: #{@interview_text1}"
  puts "#{@template}"
  puts "greeting:  #{@greeting}"
end

def populate_template
  @errors = []
  @preview_callback_method = "/preview"
  @send_callback_method = "/send"
  @interview_text1 = ""
  @interview_text2 = ""
  @interview_text3 = ""
  @text1 = "Welcome to Jody Michael Associates. We are delighted to have the opportunity to work with you. You are scheduled for the below appointment(s)."
  @text2 = "*If we have not received your payment information in the timeframe above, we will release your time slot. "
  @text3 = "Office locations and phone session procedures (please keep this information to reference for future sessions):"
  @text4 = "Please sign in with the building's concierge and take the elevators up to the 26th floor. Please let yourself in and have a seat in the waiting area.

Parking is available for JMA clients - pull all the way up the circle drive and ask the concierge for the Jody Michael Associates garage keys. The parking instructions are in the black leather pouch. If the keys are not available, the client in the time slot before you may have parked – you can wait for the keys and may need to cut into your session time 5-10 minutes to park."
  @text5 = "Please note that this is a residential building with two main entrances. Please let yourself in the door at the top of the stairs and have a seat in the waiting area.

This is also the location of JMA's career exploration center. You will receive more information if this applies to your coaching process.

Free street parking is available most times. If you need a temporary permit, please let us know when you arrive."
  @closing_text = "We look forward to working with you."
  @payment_text = " enter your credit card information "
end

def populate_interview_template
  @errors = []
  @interview_text1 = "Please send me a copy of your résumé along with the job title(s) and a brief description of the job you are targeting (optional)"
  @interview_text2 = "This session will include a mock interview, as well as time for feedback and coaching around your performance. This will mock an initial, general interview which will include questions it is highly probable you will be asked on a first interview.

We can't guarantee that the questions you will be asked in your mock interview will be asked in an actual interview, but they are intended to hit the points in an interview."

  @interview_text3 = "Your coach will not break character as interviewer, nor should you as interview candidate until the interview portion of the session is complete. Treat this like the real thing!

Feedback from your coach will be constructive, but direct in nature. If you feel you are thin-skinned or sensitive to negative feedback you should:"
end
def populate_pre_workshop_email
  @errors = []
  @preview_callback_method = "/preview_pre_workshop_email"
  @send_callback_method = "/send_pre_workshop_email"
  @greeting = "We are delighted that you will be joining us for the | Accountability Mirror workshop.  The purpose of this email is to orient you to the workshop and to provide you with your pre-work that you should complete and bring with you.
"
  @text1 = "4860 N. Paulina

Chicago, IL 60640
Please let yourself in the middle door at the top of the stairs.  Street parking is available."
  @text2 = "To prepare for the training, we will need you to complete an online assessment in advance.   Here are the directions:"
  @text3 = "There will be Starbucks coffee and snacks available during workshop breaks, and lunch will be provided. It is advisable to eat a full breakfast before you arrive."
  @text4 = "I’d like to give you an idea of what to expect when you arrive.  We will begin by doing a quick group icebreaker exercise so that we can all get to know each other a little and become comfortable with one another right away. I believe this will make the rest of the day more enjoyable for everyone.
 
I know, I know … everyone hates these (despite their effectiveness). Therefore, I have decided to let you know ahead of time how I open the workshop so that, if you choose, you can ponder and prepare beforehand and not feel rushed or put on the spot."
  @text5 = "You will be asked to share something about yourself that meets one of the following criteria: (1) something most people don't know about you when they first meet you, (2) an interesting story about yourself, (3) a passionate interest or hobby of yours or (4) an experience that would help people quickly get to know a bit about who you are."
  @closing_text = "Finally - please complete and bring the attached pre-work with you on the day of the workshop!
 
We are looking forward to seeing you!"
end

def populate_perceptual_lens_email
  @errors = []
  @preview_callback_method = "/preview_perceptual_lens_email"
  @send_callback_method = "/send_perceptual_lens_email"
  @greeting = "We are delighted to have the opportunity to work with you at the upcoming Perceptual Lens Training on "
  @text1 = "4860 N. Paulina

Chicago, IL 60640
Please let yourself in the middle door at the top of the stairs.  Street parking is available."
  @text2 = "To prepare for the training, we will need you to complete an online assessment in advance.  Here are the directions:"
  @text3 = "1. Please check your inbox and/or spam filter for an email from “noreply@ipeccoaching.com,” with the subject line “Request to Complete an On-Line Assessment” 
  
*If you do not receive this email by the end of the day today, please let me know."
  @text4 = "2. Please open this attachment and read before you begin to take the assessment to ensure accurate results. "
  @text5 = "3. Please complete the assessment on or before this Monday, February 16th, if possible."
  @closing_text = "Any questions, please let us know."

end

get '/pay_per_session_email_template' do
  #populate default text for email template and show template
  populate_template
  @template = "pay_per_session"
  erb :email_template
end

get '/fixed_fee_email_template' do
  #populate default text for email template and show template
  populate_template
  @template = "fixed_fee"
  @payment_text = " submit your payment "
  erb :email_template
end

get '/interview_email_template' do
  #populate default text for email template and show template
  populate_template
  populate_interview_template
  @template = "interview"
  puts "@template:  #{@template}"
  erb :email_template
end

post '/preview' do
  puts "@payment_date_formatted:  #{@payment_date_formatted}"
  # read user parameters, display preview of email
 
  get_params(params)
  erb :preview
end

post '/send' do
  #read user parameters and send formatted email
  get_params(params)
  show_param_results

  email = Mailer.send_email(
    @name,
    @email,
    @amount,
    @category,
    @appt_date_formatted,
    @payment_date_formatted,
    @appt_start,
    @appt_end,
    @coach,
    @location,
    @text1,
    @text2,
    @text3,
    @text4,
    @text5,
    @interview_text1,
    @interview_text2,
    @interview_text3,
    @template,
    @payment_text,
    @greeting,
    @closing_text
  )
  email.deliver
  #redirect to some thank you page
  erb :welcome_email_sent
end

get '/accountability_mirror_pre_workshop' do

  @template = "accountability_mirror_pre_workshop"
  populate_pre_workshop_email
  erb :pre_workshop_template
end

post '/preview_pre_workshop_email' do

  puts "/preview_pre_workshop_email #{@params}"
  # read user parameters, display preview of email
 
  get_params(params)
  temp_greeting = @greeting.split("|")
  if temp_greeting.size == 2 
    @greeting1 = temp_greeting[0]
    @greeting2 = temp_greeting[1]
  end

  erb :preview_pre_workshop_email

end

post '/send_pre_workshop_email'  do
  get_params(params)
  show_param_results

  email = Mailer.send_pre_workshop_email(
    @name,
    @email,
    @amount,
    @appt_date_formatted,
    @payment_date_formatted,
    @appt_start,
    @appt_end,
    @location,
    @text1,
    @text2,
    @text3,
    @text4,
    @text5,
    @interview_text1,
    @interview_text2,
    @interview_text3,
    @template,
    @payment_text,
    @greeting1,
    @greeting2,
    @closing_text
  )
  email.deliver
  #redirect to some thank you page
  erb :welcome_email_sent
  end

get '/perceptual_lens_email_template' do

  @template = "perceptual_lens_email_template"
  populate_perceptual_lens_email
  erb :perceptual_lens_template
end

post '/preview_perceptual_lens_email' do

  puts "/preview_perceptual_lens_email #{@params}"
  # read user parameters, display preview of email
  get_params(params)
  erb :preview_perceptual_lens_email
end


post '/send_perceptual_lens_email'  do
  get_params(params)
  puts "/send_perceptual_lens_email"
  show_param_results

  email = Mailer.send_perpetual_lens_email(
    @name,
    @email,
    @amount,
    @appt_date_formatted,
    @payment_date_formatted,
    @appt_start,
    @appt_end,
    @location,
    @text1,
    @text2,
    @text3,
    @text4,
    @text5,
    @interview_text1,
    @interview_text2,
    @interview_text3,
    @template,
    @payment_text,
    @greeting, 
    @closing_text
  )
  email.deliver
  #redirect to some thank you page
  erb :welcome_email_sent

  end





