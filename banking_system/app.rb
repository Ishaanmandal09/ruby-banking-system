require 'sinatra'
require 'json'

set :public_folder, 'public'
set :views, 'views'

# In-memory data
$users = {}
$transactions = {}
ADMIN_PASSWORD = "123no"

# 🏠 Home Page
get '/' do
  erb :index
end

# 🔐 Login
post '/login' do
  role = params[:role]
  username = params[:username]
  password = params[:password]

  if role == "Admin" && password == ADMIN_PASSWORD
    @balances = $users.transform_values { |u| u[:balance] }
    @transactions = $transactions
    erb :admin
  elsif role == "User" && $users.key?(username) && $users[username][:password] == password
    @username = username
    @balance = $users[username][:balance]
    @history = $transactions[username] || []
    erb :user
  else
    @error = "Invalid credentials!"
    erb :index
  end
end

# 🧾 Sign up
post '/signup' do
  username = params[:new_username]
  password = params[:new_password]

  if $users.key?(username)
    @error = "Username already exists!"
  else
    $users[username] = { password: password, balance: 0 }
    $transactions[username] = []
    @success = "Account created successfully!"
  end

  erb :index
end

# 💸 Deposit / Withdraw
post '/transaction' do
  username = params[:username]
  type = params[:type]
  amount = params[:amount].to_f

  if $users.key?(username)
    if type == "Deposit"
      $users[username][:balance] += amount
      $transactions[username] << "Deposited $#{amount}"
    elsif type == "Withdraw" && $users[username][:balance] >= amount
      $users[username][:balance] -= amount
      $transactions[username] << "Withdrew $#{amount}"
    else
      $transactions[username] << "Failed withdrawal of $#{amount}"
    end
  end

  @username = username
  @balance = $users[username][:balance]
  @history = $transactions[username]
  erb :user
end

# ⚙️ Update name/password
post '/update' do
  username = params[:username]
  new_name = params[:new_name]
  new_password = params[:new_password]

  if $users.key?(username)
    $users[new_name] = $users.delete(username) if new_name != ""
    $users[new_name][:password] = new_password if new_password != ""
    $transactions[new_name] = $transactions.delete(username) if new_name != username
  end

  @username = new_name.empty? ? username : new_name
  @balance = $users[@username][:balance]
  @history = $transactions[@username]
  @success = "Profile updated successfully!"
  erb :user
end
