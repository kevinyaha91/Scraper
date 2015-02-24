require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'logger'

#debug 500 buena vista street burbank

agent = Mechanize.new
#agent.log = Logger.new(STDOUT)
agent.user_agent_alias = 'Mac Safari'

page = agent.get('http://repertoire.bmi.com/writer.asp?fromrow=1&torow=25&keyname=EMINEM&querytype=WriterID&keyid=757375&page=1&blnWriter=True&blnPublisher=True&blnArtist=True&affiliation=BMI&cae=354929333')


    song_links_arry = Array.new
    song_names_arry = Array.new


#--------flipping pages except for last page ------ 

 #while page.link_with(:text => 'Next>').nil? != true do


 	last_page = page.link_with(:text => 'Last>>').click

	number = last_page.parser.xpath("//div[@class='paginator'][2]/div[@class='pages']").text.split(" ").last

	counter = number.to_i

	agent.cookie_jar.clear!


	while counter >= 1 do


	begin
 			song_links = last_page.links.find_all { |l| l.attributes.parent.name == 'td' }
 			rescue Mechanize::ResponseCodeError => responsecodeerror
 				puts 'responsecodeerror....'
 				puts "retrying----------------for-finding-song-links"
 				puts responsecodeerror.message
 				agent.cookie_jar.clear!
 				retry

 			rescue StandardError => standarderror
 				puts "standarderror....."
 				puts standarderror.message
 				puts "retrying----------------for-finding-song-links"
 				agent.cookie_jar.clear!
 				retry

 			rescue Net::HTTPInternalServerError => httperror
 				puts "httperror...."
 				puts httperror.message
 				puts "retrying----------------for-finding-song-links"
 				agent.cookie_jar.clear!	
  			retry
		
	end


	song_links.each do |song|

		song_page = ""

  		begin
 			song_page = song.click
 			agent.cookie_jar.clear!

 			rescue Mechanize::ResponseCodeError => responsecodeerror
 				puts 'responsecodeerror....'
 				puts "retrying---------------for-clicking-into-songs"
 				puts responsecodeerror.message
 				agent.cookie_jar.clear!
 				retry
 				
 			rescue StandardError => standarderror
 				puts "standarderror....."
 				puts standarderror.message
 				puts "retrying----------------for-clicking-into-songs"
 				agent.cookie_jar.clear!
 				retry
 				
 			rescue Net::HTTPInternalServerError => httperror
 				puts "httperror...."
 				puts httperror.message
 				puts "retrying----------------for-clicking-into-songs"
 				agent.cookie_jar.clear!
 				
  			retry
		
		end

  	#SONG WRITER SECTION +++++++++++++++++++++++++++++


  	songwriter_arry = Array.new

	name_arry ||= song_page.parser.xpath('//td[@class="entity"]/a[contains(@href, "writer.asp?")]').map &:text

	affiliation_arry ||= song_page.parser.xpath('//td[@class="entity"]/a[contains(@href, "writer.asp?")]/following::*[1]').map &:text 

	ipi_arry ||= song_page.parser.xpath('//td[@class="entity"]/a[contains(@href, "writer.asp?")]/following::*[2]').map &:text

	number = name_arry.length - 1

	i = 0 

	while i <= number do
		songwriter = Hash.new
		songwriter["name"] = name_arry[i]
		songwriter["affiliation"] = affiliation_arry[i]
		songwriter["ipi"] = ipi_arry[i]
		songwriter_arry.push(songwriter)
		i += 1
	end

	#puts songwriter_arry


	#PUBLISHER SECTION++++++++++++++++++++++++

	publisher_arry = Array.new
	song_page.links_with(:href => %r{^publisher.asp?}i).each do |link|

		publisher_page = link.click
		agent.cookie_jar.clear!

		nokogiri_ready = publisher_page.uri.to_s
		publisher = Hash.new
		processed_page = Nokogiri::XML(open(nokogiri_ready, 'User-agent' => 'ruby'))
	
		publisher["society"] ||= "BMI"

	# getting address
		pre_filtered_address ||= processed_page.at('td[text()="Contact:"] ~ *')
		address_filtered ||= pre_filtered_address.xpath('text()')
		publisher["address"] ||= address_filtered.to_s.gsub!(/\n/, ' ').strip

		publisher["phone"] ||= processed_page.search('td[text()="Phone: "] ~ *').map &:text
		publisher["fax"] ||= processed_page.search('td[text()="Fax: "] ~ *').map &:text
	
	# getting ipi
		pre_splited_ipi = processed_page.search("div[@id='cae_ipi']").xpath('text()').to_s
		post_splited_ipi = pre_splited_ipi.split(' ')
		publisher["ipi"] ||= post_splited_ipi[2]
	
	# getting name
		publisher["name"] ||= processed_page.search('h1').xpath('text()').to_s

	#For getting email
    	pre_filtered_contact ||= processed_page.css('td.value a').map { |link| link['href'] }
    	publisher["email"] ||= pre_filtered_contact.select { |link| link.match("mailto")}.join.split(":").last
		
		
	#For getting website
		publisher["website"] ||= pre_filtered_contact.select { |link| link.match("http://")}.join
  	
		publisher_arry.push(publisher)

		agent.cookie_jar.clear!
  end

  	#puts publisher_arry
  	#puts "PUBLISHER DONE"


#Performer Section +++++++++++++++++++++++++
	
	performer_arry = Array.new
	performer = Hash.new
	performer["name"] ||= song_page.parser.xpath('//td[@class="entity"]/a[contains(@href, "artist.asp?")]').map &:text
	performer_arry.push(performer)
  	
	end
	
  		begin
 			next_page = last_page.link_with(:text => '<Previous').click
 			rescue Mechanize::ResponseCodeError => responsecodeerror
 				puts 'responsecodeerror....'
 				puts "retrying----------------During-Flipping page"
 				puts responsecodeerror.message
 				agent.cookie_jar.clear!
 				retry
 			rescue StandardError => standarderror
 				puts "standarderror....."
 				puts standarderror.message
 				puts "retrying----------------During-Flipping page"
 				agent.cookie_jar.clear!
 				retry
 			rescue Net::HTTPInternalServerError => httperror
 				puts "httperror...."
 				puts httperror.message
 				puts "retrying----------------During-Flipping page"
 				agent.cookie_jar.clear!
  			retry
		
		end

	last_page = next_page
	puts song_links
	puts "flipping page---------------------"
	agent.cookie_jar.clear!
	counter -= 1
 end


 #begin
 #if next_page = page.link_with(:text => 'Next>').click
 #	page = next_page
 #end
#rescue Mechanize::ResponseCodeError => exception
#  if exception.response_code == '500'
# 	next_page = page.link_with(:text => 'Next>').click
# 	page = next_page
#  retry
#end
#end








=begin

 A song [0, 1, 2,]
 song[0].songwriter


 array of song writers [0, 1, 2, 3,...]

 song_writers[0].name = give the persons nanme 
 song_writers[0].affiliation = ASCAP
 song_writers[0].IPI = a number


 a song has three keys (song writers, publishers, Performers)
 1.	song writers, an array of them and each of them has (three keys, name, society, IPI)
 	a) name
	b) society
	c) IPI
 2. Publishers, an array of them 
 	a) name
	b) fax
	c) address
	e) email 
	f) website
	g) phone
	h) society
	i) IPI
 3. Performers
 	a) name

=end


 #song_links_last = page.links.find_all { |l| l.attributes.parent.name == 'td' }
 #song_links_arry.push (song_links_last)


	#song_links_arry.each do |song| 
	#song_page = agent.get(song)
	#song_writers = song_page.parser.xpath("//table/tr/td/a/text()")
	#puts song_writers
	#song_names_arry.push(song_names)
	#puts song_names_arry
	#end


# find the value within the div where class = value and its sibling has a string phone in it. 
	#//tbody/tr/td[@class='value']
	#//tbody//td[contains(text(), 'Phone')]/following-sibling::*[1]
	#following-sibling::*[1]


#---------------- OLD METHOD -------------
	#songwriter_arry = Array.new

	#songwriter_links = song_page.links_with(:href => %r{^writer.asp?}i).each do |link|
		#songwriter = Hash.new
		#songwriter_page = link.click
		#songwriter["name"] = songwriter_page.search('h1').xpath('text()').to_s.split(":").last.strip
		#songwriter["affiliation"] = songwriter_page.search('//div[@id="affiliation"]').xpath('text()').to_s.split(":").last.strip
		#songwriter["ipi"] = songwriter_page.search('//div[@id="affiliation"]/span').xpath('text()').to_s.split(":").last.strip
		#songwriter_arry.push(songwriter)
		#end

	#puts songwriter_arry
	#puts "SONG WRITER DONE"
#---------------- OLD METHOD -------------



#performer_arry = Array.new
	#song_page.links_with(:href => %r{^artist.asp?}i).each do |link|
		#performer_page = link.click
		#performer = Hash.new
		#performer["name"]= performer_page.search('h1').xpath('text()').to_s.split(":").last.strip
		#performer_arry.push(performer)
	#end


	#next_page = page.link_with(:text => 'Next>').click
	
	#page = next_page