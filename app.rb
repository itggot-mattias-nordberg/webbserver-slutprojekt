class App < Sinatra::Base
	# enable :sessions
	use Rack::Session::Cookie,  :key => 'rack.session',
								:expire_after => 1231231,
								:secret => "canttouchthis"


	get '/' do
		"Hello, Grillkorv!"

		slim(:index, locals:{ user_infogreeting: "Hello from index!" })
	end

         

	post '/login' do
		db = SQLite3::Database.new("./db/database.sqlite") 
		username = params["username"] 
		password = params["password"]
		accounts = db.execute("SELECT * FROM users WHERE username=?", [username])
		account_password = BCrypt::Password.new(accounts[0][2])

		if account_password == password
			result = db.execute("SELECT id FROM users WHERE username=?", [username]) 
			session[:id] = db.execute("SELECT id, username FROM users WHERE username=? AND password=?", [accounts[0][1], account_password])
			session[:login] = true 
			session[:user] = accounts
			redirect("/users/#{session[:id][0][0]}")
		elsif password == nil
			redirect("/error")
		else
			session[:login] = false
		end
		
		redirect('/users/'+session[:id].to_s)
	end

	get '/users/:id' do
		db = SQLite3::Database.new('./db/database.sqlite')
		name = session[:id][0][1]
		user = db.execute("SELECT id,username FROM users WHERE id=?", [params[:id]])
		friend_status_alt1 = db.execute("SELECT value FROM friends WHERE user1=? AND user2=? ", [session[:id][0][0], user[0][0]])
		friend_status_alt2 = db.execute("SELECT value FROM friends WHERE user1=? AND user2=? ", [user[0][0], session[:id][0][0]])
		# p friend_status_alt1[0][0]
		# p friend_status_alt2[0][0]

		friend_status_1 = friend_status_alt1[0][0].to_i
		friend_status_2 = friend_status_alt2[0][0].to_i

		if friend_status_1 == nil or friend_status_2 == nil
		 	friend_status = nil
		
		elsif friend_status_1.to_i > friend_status_2.to_i 
			friend_status = friend_status_1
		
		elsif friend_status_2.to_i > friend_status_1.to_i
			friend_status = friend_status_2
		else 
			friend_status = 0
		end

		p friend_status

		slim(:login, locals:{user:user[0], friend_status:friend_status})
	end

	get '/register' do
		slim(:register) 
	end


	post '/register' do
		db = SQLite3::Database.new('./db/database.sqlite')
		username = params["username"]
		password = params["password"]
		confirm = params["password2"]
		number = params["number"] 
		if confirm == password
			password_encrypted = BCrypt::Password.create(password)
			db.execute("INSERT INTO users (username, password, number) VALUES(?,?,?)", [username, password_encrypted, number])
			redirect('/signup_successful')

			session[:message] = "Username is not available"
			redirect("/error")
		else
			session[:message] = "Password does not match"
			redirect("/error")
		end
	end

	post '/back' do 
		session[:message] = nil
		redirect('/')
	end

	post '/add-friend' do
		db = SQLite3::Database.new('./db/database.sqlite')
		adding_id = db.execute("SELECT id FROM users WHERE username=?", params[:addId])
		db.execute("INSERT INTO friends (user1, user2, value) VALUES(?,?,?)", [session[:id][0][0],adding_id[0][0],1])
		redirect('/users/'+adding_id.flatten[0].to_s)
	end

	post '/accept-friend' do
		user = params[:user]
		friend = params[:friend]
		db = SQLite3::Database.new('./db/database.sqlite')
		db.execute("UPDATE friends SET value=? WHERE user1=? AND user2=? ", [2, user, friend ])
		redirect ('/home')
	end

	post '/logout' do 
		if session[:login] == true
			session[:id] = nil
			session[:login] = false
			redirect('/')
		else 
			redirect('/')
		end
	end

	get '/signup_successful' do
		slim(:signup_successful)
	end

	get '/error' do
		slim(:error)
	end

	get '/home' do
		db = SQLite3::Database.new('./db/database.sqlite')
		pending_requests = db.execute("SELECT * FROM friends WHERE user1=?", [session[:id][0][0]])
		invitations = db.execute("SELECT * FROM friends WHERE user2=? AND value=1", [session[:id][0][0]])
		slim(:home, locals:{username:session[:id][0][1], invitations: invitations})
	end
end