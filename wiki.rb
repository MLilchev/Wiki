=begin
Based on the exercises from CS1525 'WAD Practicals(for intermediate programmers) '
=end


require 'sinatra'                      #requires the framework;
require 'pp'						   #requires the 'pp' gem for debuggind purposes;
require 'sinatra/activerecord'		   #requires the ActiveRecords ORM;
set :logging, :true

ActiveRecord::Base.establish_connection(  					#directs ActiveRecords to use the 'wiki.db' file as a database and to use the sqlite3 gem; 
	:adapter =>'sqlite3',
	:database => 'wiki.db'
)

class User < ActiveRecord::Base  							#defines a class with properties that will be looked for in the database file;
	validates :username, presence: true, uniqueness: true
	validates :password, presence: true 
	#validates :gender, presence: true						#an example of the attempts to connect additional columns with the database;
	#validates :dob, presence: true
	#validates :email, presence: true #uniqueness: true
end

helpers do  												#combines methods that are going to be used in authentification processes;
	def protected!											#defines the protected! method with a condition which is the method authorised? which if fulfilled allows you to access the URL ; 
		if authorised?										
			return											
		end
		redirect '/denied'									#if the condition is not satisfied you are redirected to the '/denied' page;
	end
	def authorised?											#defiens the authorised? method which checks if the boolean value in the edit column of the db file is set to 'true' for the logged in user;
		if $credentials != nil
		@Userz = User.where(:username => $credentials[0]).to_a.first 
			if @Userz
				if @Userz.edit==true
					return true
				else
				return false
			end
		else
	return false
end
end
end
end

before '/admincontrols' do 				 					# uses the before filter to ensure that the /admincontrols URL cannot be accessed by any user rahter than the Admin. Source: #http://sinatrarb.com/intro.html
	unless params[:username] = " Admin"
		redirect '/notfound'		
	end
end

def readFile(filename)										#defines the readFile method which is used to display the wiki contents from a text file onto the Main Page;
	info = " "
	file = File.open(filename)
	file.each do |line|
		info += line
	end
	file.close
	$myinfo = info
end

def writeFile(filename)	 									#defines the writeFile method which is used to add additional information into the log.txt file;
	file = File.open(filename, "a")
	file.puts @log
	file.close
end

def replaceFile(filename)									#defines the replaceFile method which is used to alter the contents of .txt files;
	file = File.open(filename, "w")
	file.puts @log
	file.close
end

@info = " "													
$myinfo = readFile("wiki.txt")
$creators = "Maksim and Tamarah"

get '/' do 
	@words = $myinfo.split.count 							#defines a class variable which is used to display the word count of the displayed text;
	@characters = $myinfo.gsub(/\s+/, "").gsub(" ","").gsub(/[^0-9A-Za-z]/, '').length    #defines a variable which is uded to display the characters count without counting special characters and blank spaces; Source: #https://teamtreehouse.com/community/extra-credit-how-to-properly-count-number-of-characters-in-a-string  												   
 	erb :home
end




get '/profile' do 
	puts "-- get profile" 									#used for debugging purposes
	pp $credentials
    @u = User.find_by(:username => $credentials[0])			#used to display the name of the user when accessing profile.erb file. Not working;
	erb :profile
end

get '/edit' do 												#opens the edit page
	protected!												#endures that it is only available to users with priviliges;
	readFile("wiki.txt")									#uses the readFile in order to gain $myinfo to fill the form in the edit.erb
	erb :edit
end
	
put '/edit' do  											#updates the content of the wiki.txt
	puts "--get message"									#used for debugging
	pp params[:message]										#used for debugging
   	
   	@log =$myinfo											#adds the contents of the wiki.txt to the class variable 
   	replaceFile("rollback.txt")								#uses the replaceFile method to create a Rollback file which can be used to return the database to its prior content;
    $myinfo = "#{params[:message]}"							#takes the content from the form in the edit.erb file
	@log = $myinfo													
	replaceFile("wiki.txt")									#uses the replaceFile method change the content of the wiki.txt
	@user = $credentials[0]
	@log = "User #{@user} altered the contents of the main page at: #{Time.now.strftime("%d/%m/%Y %H:%M")}. The new contents are: #{params[:message]}"  #a string that is later used to add a line in a log.
	redirect '/'		
end

get '/login' do 											#displays the login page
	erb :login
end

post '/login' do											#sends the information from the login forms to be comapred with the contents of the database
	$credentials = [params[:username],params[:password]]	#creates a global variable from the information contained in the array;
	puts "--login"											#debugging;
	pp $credentials		
	@user = User.where(:username => $credentials[0]).to_a.first
	if @user.password == $credentials[1]					#condition for successful login
		@log = "User #{params[:username]} accessed the page at #{Time.now.strftime("%d/%m/%Y %H:%M")}"	
		writeFile("log.txt")                               #adds the login informaion to the log.txt;
		puts "login success"							   #debugging;
		redirect '/profile'								 
	else
		puts "login fail"								   #debugging
		$credentials = ["",""]							   #in case the credentials are not correct a log is created and the user is redirected	
		@log = "User #{params[:username]} attempted to access the page at: #{Time.now.strftime("%d/%m/%Y %H:%M")}."
		writeFile("log.txt")
		redirect '/wrongaccount'
	end
	erb :login
end

get '/createaccount' do 									#displays the createaccount page;
	erb :createaccount
end

post '/createaccount' do 									#posts the information from the forms to the .db file;
 n = User.new												#defines the n variable as a new user;
	n.username = params[:username]							
	n.password = params[:password]
	if n.username == "Admin" and n.password =="Password"    #ensures that the Admin has priviliges to edit content and users;
		n.edit = true										
	end
	n.save
	redirect "/login"
end


get '/user/:uzer' do 										#displays a logged in user user-page or redirects to /noaccount;
	@u = User.find_by(:username => $credentials[0])
	if @u != nil
		erb :profile
	else
		redirect '/noaccount'
	end
end


put '/user/:uzer' do 										#makes it possible to edit a user's permissions to edit the page;
	n=User.where(:username => params[:uzer]).to_a.first
	n.edit = params[:edit] ? 1 : 0
	n.save
	redirect '/'
end


get '/user/delete/:uzer' do 								#makes it possible for the Admin to delete users from the .db;
	protected!
    n = User.where(:username => params[:uzer]).to_a.first
	if n.username == "Admin"
		erb :denied
	else
		n.destroy
		@list2 = User.all.sort_by {|u| [u.id]}
		erb :admincontrols
	end
end


get '/user/edit/:uzer' do  									#allows for an edit username page to be displayed and does not allow for the "Admin" username to be changed
	protected!
	@usr = User.where(:username => params[:uzer]).to_a.first
	puts "--edit username"
	pp params[:uzer]
	if @usr.username == "Admin"
		erb :denied
	else
		erb :edit_user
	end
end

put '/user/update/:uzer' do 								 #supposed to change the username of a user through the admin controls screen, does not work
	protected!

	@usr = User.where(:username => credentials[0]).to_a.first
	puts "--update"
	pp credentials
	if @usr.username == "Admin"
		erb :denied
	else
		@usr.username = params[:n_username]
		@usr.save
		@list2 = User.all.sort_by {|u| [u.id]}
		erb :admincontrols
	end
end


get '/admincreate' do 										#directs to the admincreate page;
	erb :admincreate
end

post '/admincreate' do 										#posts the information from the page to the database and creates a user.
	protected!
	n = User.new 
	n.username = params[:username]
	n.password = params[:password]
	n.created_at = Time.now
	n.save
	redirect '/admincontrols'
end


get '/admincontrols' do 									#dislays the admincontrols page ;
	protected!
	pp "---username"										#debugging;
	puts params[:username]

	@list2 = User.all.sort_by {|u| [u.id]}
	erb :admincontrols
end

get '/rollback' do  										#initiates the rollback process and creates a line in the log.txt;
	protected!
	readFile("rollback.txt")
	@log = $myinfo
	replaceFile("wiki.txt")
	@user = $credentials[0]
	@log = "User #{@user} rolled back the contents of the main page at: #{Time.now.strftime("%d/%m/%Y %H:%M")}. The new contents are: #{$myinfo}" #https://stackoverflow.com/questions/7415982/how-do-i-get-the-current-date-time-in-dd-mm-yyyy-hhmm-format
	writeFile("log.txt") 
	redirect '/'
end

get '/reset' do 											#resets the contents of the main page to its original state;
	protected!
	readFile("reset.txt")
	erb :edit
end

get '/backup' do  											#creates a backup of the the current version of the wiki.txt;
	protected!
	@log = $myinfo
	replaceFile("backup.txt")
	redirect '/'
end

get '/usebackup' do  										#uses the backup.txt to change the wiki.txt and creates a log line;
	protected!
	readFile("backup.txt")
	@log = $myinfo
	replaceFile("wiki.txt")
	@user = $credentials[0]
	@log = "User #{@user} used to backup file to alter teh contents of the main page at: #{Time.now.strftime("%d/%m/%Y %H:%M")}. The new contents are: #{$myinfo}" #https://stackoverflow.com/questions/7415982/how-do-i-get-the-current-date-time-in-dd-mm-yyyy-hhmm-format
	writeFile("log.txt")                           
	redirect '/'
end

get '/logout' do  											#logs out and creates a line in the log.txt;
	@user = $credentials[0]
	@log = "User #{@user} logged out at: #{Time.now.strftime("%d/%m/%Y %H:%M")}"	
	writeFile("log.txt")
	$credentials = ["",""]
	redirect '/'
end

get '/wrongaccount' do 										#displays the wrongaccount page;
	erb :wrongaccount
end

get '/noaccount' do 										#displays the noaccount page;
	erb :noaccount
end

get '/denied' do  											#displays the denied page;
	erb :denied
end

get '/map' do  											    #displays the map page;
	erb :map
end

get '/gallery' do 											#displays the gallery page;
	erb :gallery
end

get '/video' do 											#displays the video page;
	erb :video
end

get '/about' do 											#displays the about page;
	erb :about
end

get '/notfound' do 										    #displays the notfound page;
	erb :notfound
end

not_found do
        status 404
        redirect '/notfound'
end



