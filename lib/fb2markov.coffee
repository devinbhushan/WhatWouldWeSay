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
		console.log "messageCount: #{parseInt(messageCount[0]["message_count"])}"
		countCB(parseInt(messageCount[0]["message_count"]))

	makeQuery("SELECT message_count FROM thread WHERE 
		thread_id = #{thread_id} LIMIT 1", parseCount)
	return
this.API_LIMIT = 4

getInbox = ->

	messageFetcher = (count) ->
		
		# Need to add a callback to end to pass complete conversation
		# elsewhere so markov can be called on it
		messageInterpretor = (lastResponse) ->
			# console.log("lastResponse #{JSON.stringify(lastResponse)}")
			for num, val of lastResponse
				if not messageContainer[val["author_id"]]
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
					console.log "Adding author to container #{val['author_id']}"
					messageContainer[val["author_id"]] = []
				messageContainer[val["author_id"]].push val["body"]
			console.log "container! #{JSON.stringify(messageContainer)}"
			return

		iterationsNeeded = count / 30
		if iterationsNeeded > 10
			segments = []
			i = 0
			while i < this.API_LIMIT
				randomSegment = Math.floor(Math.random() * iterationsNeeded)
				if randomSegment not in segments
					segments.push randomSegment
					i += 1
		messageContainer = {}
		for i, segment of segments
			if parseInt(i) is this.API_LIMIT-1
				makeQuery("SELECT thread_id, body, author_id, created_time 
					FROM message WHERE thread_id = 1162160143849 
					ORDER BY created_time ASC LIMIT #{segment * 30},#{(segment * 30) + 30}", lastMessage)
			makeQuery("SELECT thread_id, body, author_id, created_time 
				FROM message WHERE thread_id = 1162160143849 
				ORDER BY created_time ASC LIMIT #{segment * 30},#{(segment * 30) + 30}", messageInterpretor)

		return
	getMessageCount("1162160143849", messageFetcher)

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