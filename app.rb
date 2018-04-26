class App < Sinatra::Base
	enable :sessions

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
		user = db.execute("SELECT username FROM users WHERE id=?", [params[:id]])
		slim(:login, locals:{session:session, user:user[0][0]})
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
		byebug
		db.execute("INSERT INTO friends (user1, user2, value) VALUES(?,?,?)", [session[:id][0][0],adding_id[0][0],0])
		redirect ('/users/'+adding_id)
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
end