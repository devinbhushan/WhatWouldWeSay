# check login status
# enable cookies to allow the server to access the session
# parse XFBML

# Here we subscribe to the auth.authResponseChange JavaScript event. This event is fired
# for any authentication related change, such as login, logout or session refresh. This means that
# whenever someone who was previously logged out tries to log in again, the correct case below 
# will be handled. 

# Here we specify what we do with the response anytime this event occurs. 

# The response object is returned with a status field that lets the app know the current
# login status of the person. In this case, we're handling the situation where they 
# have logged in to the app.

# In this case, the person is logged into Facebook, but not into the app, so we call
# FB.login() to prompt them to do so. 
# In real-life usage, you wouldn't want to immediately prompt someone to login 
# like this, for two reasons:
# (1) JavaScript created popup windows are blocked by most browsers unless they 
# result from direct interaction from people using the app (such as a mouse click)
# (2) it is a bad experience to be continually prompted to login upon page load.

# In this case, the person is not logged into Facebook, so we call the login() 
# function to prompt them to do so. Note that at this stage there is no indication
# of whether they are logged into the app. If they aren't then they'll see the Login
# dialog right after they log in to Facebook. 
# The same caveats as above apply to the FB.login() call here.

# Load the SDK asynchronously

# Here we run a very simple test of the Graph API after login is successful. 
# This testAPI() function is only called in those cases. 
testAPI = ->
  console.log "Welcome!  Fetching your information.... "
  FB.api "/me", (response) ->
    console.log "Good to see you, " + response.name + "."

makeQuery = (queryText, cb) ->
	FB.api 
		method: "fql.query"
		query: queryText
		, cb

getInbox = ->
	handleThreads = (threadList)->
		getMessages = (messageCount) ->
			lastFunc = (lastResponse) ->
				console.log("lastResponse #{lastResponse}")
				for key, val of lastResponse
					console.log "key #{key} val #{val[0]}"
					break
			for key, val of messageCount
				console.log "key #{key} val #{messageCount['error_code']}"
				break
			queryReps = messageCount[0]["message_count"] / 30
			for rep in [0..queryReps]
				makeQuery("SELECT thread_id, body, author_id, created_time 
					FROM message WHERE thread_id = #{id['thread_id']} 
					ORDER BY created_time ASC LIMIT #{rep * 30},#{(rep * 30) + 1}", lastFunc)
		for num, id of threadList
			console.log "key #{num} val #{threadList['error_code']}"
			console.log "Thread: #{id['thread_id']}"
			makeQuery("SELECT message_count FROM thread WHERE 
				thread_id = #{id['thread_id']} LIMIT 1", getMessages)
	makeQuery("SELECT thread_id FROM thread WHERE folder_id = 0", handleThreads)

window.fbAsyncInit = ->
  FB.init
    appId: "364959256980832"
    status: true
    cookie: true
    xfbml: true

  FB.Event.subscribe "auth.authResponseChange", (response) ->
    if response.status is "connected"
      getInbox()
    else if response.status is "not_authorized"
      FB.login()
    else
      FB.login()

((d) ->
  js = undefined
  id = "facebook-jssdk"
  ref = d.getElementsByTagName("script")[0]
  return  if d.getElementById(id)
  js = d.createElement("script")
  js.id = id
  js.async = true
  js.src = "https://connect.facebook.net/en_US/all.js"
  ref.parentNode.insertBefore js, ref
) document