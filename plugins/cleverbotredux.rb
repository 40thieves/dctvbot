# encoding: utf-8

module Plugins

	class CleverBotRedux
		include Cinch::Plugin

		set :help, <<-HELP
!disablechatter - Disables the bot's CleverBot interface. Voiced or higher only.
!enablechatter - Re-enables the bot's CleverBot interface. Voiced or higher only.
!globaldisable - Globally disables the CleverBot interface. This command can only be used by specified users (currently set to channel ops).
!globalenable  - Globally re-enables the interface. This command contains the same permissions as globaldisable. NOTE: This will not reset any restriction that a channel operator has imposed on the bot with the previous commands.
HELP

		match lambda { |m| /^#{m.bot.nick}[:,]?\s*(.+)/i }, use_prefix: false
		match(/<c=\d{1,3},\d{1,3},\d{1,3}>.{2}: CB: (.+)/ , use_prefix: false)
		match "disablechatter", use_prefix: true, method: :disableChanChat
		match "enablechatter", use_prefix: true, method: :enableChanChat
		match "globaldisable", use_prefix: true, method: :globalDisable
		match "globalenable", use_prefix: true, method: :globalEnable
		match "chatterhelp", use_prefix: true, method: :chatterHelp
		match(/^\/me!disablechatter (.+)/, use_prefix: false, method: :disableChanChat)
		match(/^\/me!enablechatter (.+)/, use_prefix: false, method: :enableChanChat)
		match(/^\/me!globaldisable (.+)/, use_prefix: false, method: :globalDisable)
		match(/^\/me!globalenable (.+)/, use_prefix: false, method: :globalEnable)
		match(/^\/me!chatterHelp (.+)/, use_prefix: false, method: :globalEnable)


		def initialize(*args)
			super
			@admins = [ "beatmaster", "blendermf", "cheeto", "gatowag", "leon",
									"neshcom", "sebgonz", "t2t2", "tinnvec", "tomgerhrke" ]
			@enabled = true
			@pesterchum = config[:pesternetwork] || false
			@defaultnick = config[:defaultnick] || "cleverBot"
			regexp = /[A-Z]/
			matched = regexp.match(@defaultnick)
			if matched
				matched = matched[0]
			else
				matched = "?"
			end
			@abbreviation = @defaultnick[0].chr.capitalize
			@abbreviation << matched
			@abbreviation << ": "
			@prefixUse = true
			@disabledChannels = Set.new
			@cleverbot = Cleverbot::Client.new
			colour1 = rand(200).to_s
			colour1 << ','
			colour2 = rand(200).to_s
			colour2 << ','
			colour3 = rand(200).to_s
			combinedcolour = colour1
			combinedcolour << colour2
			combinedcolour << colour3
			@defaultPrefix = "<c="
			@defaultPrefix << combinedcolour
			@defaultPrefix << ">"
			@defaultPrefix << @abbreviation
			@defaultSuffix = "<\/c>"
		end

		def execute(m, message)
			return unless @enabled
			return if /flip (.+)/ =~ message || /help (.+)/ =~ message
			return if [ "whatson", "whatsnext", "schedule", "help", "flip",
									"tumbleweed", "disablechatter", "enablechatter",
									"globaldisable", "globalenable", "chatterhelp" ].include? message
			if @disabledChannels.include?(m.channel)
				return
			else
				if m.channel
					if @pesterchum == true
						#Pesterchum network compatibility
						pesterString = message
						prefix = @defaultPrefix.dup
						suffix = @defaultSuffix.dup
						pesterString.sub /<c=\d{1,3},\d{1,3},\d{1,3}>.{2}: /, ''
						pesterString.sub /<\/c>/, ''
						currentuser = m.user.to_s
						regexp = /[A-Z]/
						matched = regexp.match(currentuser)
						if matched
							matched = matched[0]
						else
							matched = "?"
						end
						prefix << currentuser[0].chr.capitalize
						prefix << matched
						prefix << ": "
						msg_back = @cleverbot.write pesterString
						tosend = prefix
						tosend << msg_back << suffix
						m.reply(tosend, false)
					else
						msg_back = @cleverbot.write message
						m.reply(msg_back, @prefixUse)
					end
				end
			end
		end

		def chatterHelp(m, message)
			prefix = @defaultPrefix.dup
			suffix = @defaultSuffix.dup
			if @pesterchum == false
				m.reply("Available commands for privileged users (voice and up): ~disablechatter, ~enablechatter", @prefixUse)
			else
				tosend = prefix
				tosend << "Available commands for privileged users (voice and up): ~disablechatter, ~enablechatter"
				tosend << suffix
				m.reply(tosend, false)
			end
		end

		def disableChanChat(m, message)
			prefix = @defaultPrefix.dup
			suffix = @defaultSuffix.dup
			if m.channel.opped?(m.user) or m.channel.half_opped?(m.user) or m.channel.voiced?(m.user)
				if @disabledChannels.add?(m.channel) == nil
					if @pesterchum == false
						m.reply("CleverBot already disabled.", @prefixUse)
						return
					else
						tosend = prefix
						tosend << "CleverBot already disabled."
						tosend << suffix
						m.reply(tosend, false)
					end
				else
					if @pesterchum == false
						m.reply("CleverBot disabled.", @prefixUse)
						@disabledChannels + ["#{m.channel}"]
						return
					else
						tosend = prefix
						tosend << "CleverBot disabled."
						tosend << suffix
						m.reply(tosend, false)
						@disabledChannels + ["#{m.channel}"]
					end
				end
			end
		end

		def enableChanChat(m, message)
			prefix = @defaultPrefix.dup
			suffix = @defaultSuffix.dup
			if m.channel.opped?(m.user) or m.channel.half_opped?(m.user) or m.channel.voiced?(m.user)
				if @disabledChannels.delete?(m.channel) == nil
					if @pesterchum == false
						m.reply("CleverBot already enabled.", @prefixUse)
						return
					else
						tosend = prefix
						tosend << "CleverBot already enabled."
						tosend << suffix
						m.reply(tosend, false)
					end
				else
					if @pesterchum == false
						m.reply("CleverBot enabled.", @prefixUse)
						@disabledChannels - ["#{m.channel}"]
						return
					else
						tosend = prefix
						tosend << "CleverBot enabled."
						tosend << suffix
						m.reply(tosend, false)
						@disabledChannels - ["#{m.channel}"]
					end
				end
			end
		end

		def globalDisable(m, message)
			prefix = @defaultPrefix.dup
			suffix = @defaultSuffix.dup
			return unless check_user(m.user)
			if @enabled == true
				@enabled = false
				if @pesterchum == false
					m.reply("CleverBot is now globally disabled.", @prefixUse)
				else
					tosend = prefix
					tosend << "CleverBot is now globally disabled."
					tosend << suffix
					m.reply(tosend, false)
				end
			else
				if @pesterchum == false
					m.reply("CleverBot is already globally disabled.", @prefixUse)
				else
					tosend = prefix
					tosend << "CleverBot is already globally disabled."
					tosend << suffix
					m.reply(tosend, false)
				end
			end
		end

		def globalEnable(m, message)
			prefix = @defaultPrefix.dup
			suffix = @defaultSuffix.dup
			return unless check_user(m.user)
			if @enabled == false
				@enabled = true
				if @pesterchum == false
					m.reply("CleverBot is now globally enabled.", @prefixUse)
				else
					tosend = prefix
					tosend << "CleverBot is now globally enabled."
					tosend << suffix
					m.reply(tosend, false)
				end
			else
				if @pesterchum == false
					m.reply("CleverBot is already globally enabled.", @prefixUse)
				else
					tosend = prefix
					tosend << "CleverBot is already globally enabled."
					tosend << suffix
					m.reply(tosend, false)
				end
			end
		end

		def check_user(user)
			user.refresh # be sure to refresh the data, or someone could steal
			# the nick
			@admins.include?(user.authname)
		end
	end

end
