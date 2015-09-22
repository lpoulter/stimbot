Fuse = require 'fuse.js'

FACTIONS = {
	'adam': { "name": 'Adam', "color": '#b9b23a', "icon": "Adam" },
	'anarch': { "name": 'Anarch', "color": '#ff4500', "icon": ":anarch:" },
	'apex': { "name": 'Apex', "color": '#9e564e', "icon": "Apex" },
	'criminal': { "name": 'Criminal', "color": '#4169e1', "icon": ":criminal:" },
	'shaper': { "name": 'Shaper', "color": '#32cd32', "icon": ":shaper:" },
	'sunny-lebeau': { "name": 'Sunny Lebeau', "color": '#715778', "icon": "Sunny LeBeau" },
	'neutral': { "name": 'Neutral (runner)', "color": '#808080', "icon": "Neutral" },
	'haas-bioroid': { "name": 'Haas-Bioroid', "color": '#8a2be2', "icon": ":hb:" },
	'jinteki': { "name": 'Jinteki', "color": '#dc143c', "icon": ":jinteki:" },
	'nbn': { "name": 'NBN', "color": '#ff8c00', "icon": ":nbn:" },
	'weyland': { "name": 'Weyland Consortium', "color": '#326b5b', "icon": ":weyland:" },
	'neutral': { "name": 'Neutral (corp)', "color": '#808080', "icon": "Neutral" }
}

formatCard = (card) ->
	title = card.title
	if card.uniqueness
		title = "◆ " + title

	attachment = {
		'fallback': title,
		'title': title,
		'title_link': card.url,
		'mrkdwn_in': [ 'text' ]
	}

	attachment['text'] = ''

	typeline = ''
	if card.subtype? and card.subtype != ''
		typeline += "*#{card.type}*: #{card.subtype}"
	else
		typeline += "*#{card.type}*"

	switch card.type_code
		when 'agenda'
			typeline += " _(#{card.advancementcost}:rez:, #{card.agendapoints}:agenda:)_"
		when 'asset', 'upgrade'
			typeline += " _(#{card.cost}:credit:, #{card.trash}:trash:)_"
		when 'event', 'operation', 'hardware', 'resource'
			typeline += " _(#{card.cost}:credit:)_"
		when 'ice'
			typeline += " _(#{card.cost}:credit, #{card.strength} strength)_"
		when 'identity'
			if card.side_code == 'runner'
				typeline += " _(#{card.baselink}:baselink:, #{card.minimumdecksize} min deck size, #{card.influencelimit} influence)_"
			else if card.side_code == 'corp'
				typeline += " _(#{card.minimumdecksize} min deck size, #{card.influencelimit} influence)_"
		when 'program'
			if card.strength?
				typeline += " _(#{card.cost}:credit:, #{card.memoryunits}:mu:, #{card.strength} strength)_"
			else
				typeline += " _(#{card.cost}:credit:, #{card.memoryunits}:mu:)_"

	attachment['text'] += typeline + "\n\n"
	attachment['text'] += emojifyNRDBText(card.text)

	faction = FACTIONS[card.faction_code]

	if faction?
		if card.factioncost?
			influencepips = ""
			i = card.factioncost
			while i--
				influencepips += '●'
			attachment['author_name'] = "#{card.setname} / #{faction.icon}#{influencepips}"
		else
			attachment['author_name'] = "#{card.setname} / #{faction.icon}"

		attachment['color'] = faction.color

	return attachment

emojifyNRDBText = (text) ->
	text = text.replace /\[Credits\]/g, ":credit:"
	text = text.replace /\[Click\]/g, ":click:"
	text = text.replace /\[Trash\]/g, ":trash:"
	text = text.replace /\[Recurring Credits\]/g, ":recurring:"
	text = text.replace /\[Subroutine\]/g, ":subroutine:"
	text = text.replace /\[Memory Unit\]/g, ":mu:"
	text = text.replace /\[Link\]/g, ":baselink:"
	text = text.replace /<sup>/g, " "
	text = text.replace /<\/sup>/g, ""
	text = text.replace /&ndash/g, "–"
	text = text.replace /<strong>/g, "*"
	text = text.replace /<\/strong>/g, "*"

	return text

module.exports = (robot) ->
	robot.http("http://netrunnerdb.com/api/cards/")
		.get() (err, res, body) ->
			robot.brain.set 'cards', JSON.parse body

	robot.hear /\[([^\]]+)\]/, (res) ->
		query = res.match[1]
		cards = robot.brain.get('cards')

		fuseOptions =
			caseSensitive: false
			includeScore: false
			shouldSort: true
			threshold: 0.6
			location: 0
			distance: 100
			maxPatternLength: 32
			keys: ['title']

		fuse = new Fuse cards, fuseOptions
		results = fuse.search(query)

		if results.length > 0
			formattedCard = formatCard results[0]
			robot.emit 'slack.attachment',
				message: "Found card:"
				content: formattedCard

