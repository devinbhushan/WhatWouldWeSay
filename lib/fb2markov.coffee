# append markov.js
# js = document.createElement("script")
# js.type = "text/javascript"
# js.src = "../lib/markov.js"
# document.body.appendChild(js)

# js = document.createElement("script")
# js.type = "text/javascript"
# js.src = "http://code.jquery.com/jquery-1.10.1.min.js"
# document.body.appendChild(js)

# js = document.createElement("script")
# js.type = "text/javascript"
# js.src = "../bootstrap/js/bootstrap.min.js"
# document.body.appendChild(js)

#sample regexes:
#
# /./g - every letter
# /../g - every two letter
# /[.,?"();\-!':—^\w]+ /g - every word
# /([.,?"();\-!':—^\w]+ ){2}/g - every two words 

this.API_LIMIT = 4
this.SIZE_CONVO = 2
this.GEN_SIZE = 13
this.my_name = ""
this.friend_name = ""

testAPI = ->
  console.log "Welcome!  Fetching your information.... "
  FB.api "/me", (response) ->
    console.log "Good to see you, " + response.name + "."

# Util function to make a FB api query
makeQuery = (queryText, cb) ->
	FB.api 
		method: "fql.query"
		query: queryText
		, cb

handleFriend = ->
	$('ul').empty()
	this.friend_name = $('#search').val()
	console.log "friend's name: #{this.friend_name}"
	getInbox this.name2id[$('#search').val()]

# Queries for all friends and return a list of them
getFriends = ->
	handleFriendList = (response) ->
		# console.log "Friends: #{JSON.stringify(response)}"
		this.name2id = {}
		keys = []
		for num, pair of response
			this.name2id[pair["name"]] = pair["uid"]
			keys.push pair["name"]
		# console.log "keys: #{sourceList}"
		$('#search').typeahead
			source: keys
		console.log "results: #{JSON.stringify(name2id)}"
		$('.friend_selector input').prop("disabled", false)
	makeQuery("SELECT name, uid FROM user WHERE uid IN 
		(SELECT uid1 FROM friend WHERE uid2=me())", handleFriendList)

# Queries for all threads with friends, returns list of all thread ids
getThreads = ->
	threadList = []
	handleThreads = (threadList)->
		for num, id of threadList
			threadList.push id['thread_id']
	makeQuery("SELECT thread_id FROM thread WHERE folder_id = 0", handleThreads)
	return threadList

# Returns number of messages in a given thread
getMessageCount = (thread_id, countCB) ->
	parseCount = (messageCount) ->
		console.log "messageCount: #{JSON.stringify(messageCount)}"
		countCB(parseInt(messageCount[0]["message_count"]))
	# console.log "getMessageCount: thread_id #{thread_id}"
	# console.log "SELECT message_count FROM thread WHERE 
		# thread_id = #{thread_id} LIMIT 1"
	makeQuery("SELECT message_count FROM thread WHERE 
		thread_id = #{thread_id} LIMIT 1", parseCount)
	return

getThreadID = (user_id, countCB) ->
	handleThreadID = (id_response) ->
		# console.log "called func?"
		threads = []
		for index, id_obj of id_response
			if id_obj in threads
				continue
			threads.push id_obj

		# TODO for now, I'm passing on the max length convo. Later we can pass
		# all threads and take a selection from all of them to use
		curr_max = {"thread_id":"", "message_count": 0}
		for index, temp_obj of threads
			if parseInt(temp_obj["message_count"]) > parseInt(curr_max["message_count"])
				curr_max = temp_obj

		countCB(curr_max["thread_id"], curr_max["message_count"])
		# console.log "handle thread: #{JSON.stringify(id_response)}"

	# console.log "getThreadID CALLED!"
	makeQuery("SELECT thread_id, message_count FROM thread WHERE thread_id IN 
		(SELECT thread_id, message_count FROM thread WHERE folder_id =0)
		AND '#{user_id}' IN recipients", handleThreadID)

getInbox = (targetUser) ->

	messageFetcher = (thread_id, count) ->
		authors = []
		# Need to add a callback to end to pass complete conversation
		# elsewhere so markov can be called on it
		messageInterpretor = (lastResponse) ->
			# console.log("lastResponse #{JSON.stringify(lastResponse)}")
			for num, val of lastResponse
				if not messageContainer[val["author_id"]]
					authors.push val["author_id"]
					console.log "Adding author to container #{val['author_id']}"
					messageContainer[val["author_id"]] = []
				messageContainer[val["author_id"]].push val["body"]
			return

		# UGLYYYYYYY but using a diff func for the last call, need to handle
		# concurrency better somehow later
		# Call markov at end of this one!
		lastMessage = (lastResponse) ->
			# console.log("lastResponse #{JSON.stringify(lastResponse)}")
			for num, val of lastResponse
				if not messageContainer[val["author_id"]]
					authors.push val["author_id"]
					console.log "Adding author to container #{val['author_id']}"
					messageContainer[val["author_id"]] = []
				messageContainer[val["author_id"]].push val["body"]
			# console.log "container! #{JSON.stringify(messageContainer)}"
			# markovEx = new markov(messageContainer["705360810"].join(), "string", /([.,?"();\-!':—^\w]+ )/g)
			console.log "authors: #{authors}"
			messageList = {}
			for index, author of authors
				messageList[author] = []
				console.log "text: #{messageContainer[author].join(" ")}"
				markovEx = new markov(messageContainer[author].join(" "), "string", /([.,?"();\-!':—^\w]+ )/g)
				for arrIndex in (arr = [0..this.SIZE_CONVO-1])
					newestGen = markovEx.gen(this.GEN_SIZE)
					i = newestGen.lastIndexOf('.')
					if i != -1
						newestGen = newestGen.substr(0, i+1)
					messageList[author].push newestGen
					console.log "Doing iter: #{arrIndex}, messageList: #{messageList[author].length}"

			for arrIndex in (arr = [0..this.SIZE_CONVO-1])
				for index, author of authors
					if this.name2id[this.friend_name] is author
						curr_author = this.friend_name.split(" ")[0]
						el_id = "other"
					else
						curr_author = this.my_name
						el_id = "me"
					$('.chat').append("
						<li class='#{el_id}'>
							<div class='chat_obj'>
								<span class='chat_name'>#{curr_author}:</span>
								<span class='chat_content'>#{messageList[author][arrIndex]}</span>
							</div>
						</li>
						")
			return

		iterationsNeeded = count / 30

		segments = []
		i = 0
		while i < this.API_LIMIT
			randomSegment = Math.floor(Math.random() * iterationsNeeded)
			if randomSegment not in segments
				segments.push randomSegment
				i += 1

		messageContainer = {}
		# console.log "About to query for messages: #{segments}"
		for i, segment of segments
			if parseInt(i) is this.API_LIMIT-1
				makeQuery("SELECT thread_id, body, author_id, created_time 
					FROM message WHERE thread_id = #{thread_id} 
					ORDER BY created_time ASC LIMIT #{segment * 30},#{(segment * 30) + 30}", lastMessage)
			makeQuery("SELECT thread_id, body, author_id, created_time 
				FROM message WHERE thread_id = #{thread_id} 
				ORDER BY created_time ASC LIMIT #{segment * 30},#{(segment * 30) + 30}", messageInterpretor)

		return
	# getMessageCount(targetUser, messageFetcher)
	getThreadID(targetUser, messageFetcher)

window.fbAsyncInit = ->
  FB.init
    appId: "364959256980832"
    status: true
    cookie: true
    xfbml: true

  tempCallback = ->
  	FB.api "/me/", (response) ->
  		this.my_name = response["first_name"]
  		getFriends()

  FB.Event.subscribe "auth.authResponseChange", (response) ->
    if response.status is "connected"
      tempCallback()
    else if response.status is "not_authorized"
      FB.login tempCallback
    else
      FB.login tempCallback

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