require 'rubygems'
require 'mechanize'
require 'pry'

a = Mechanize.new
a.get('http://good-times.webshots.com') do |page|
  # a.pluggable_parser["image"] = Mechanize::FileSaver
  # Click the login link
  login_page = a.click(page.link_with(:text => "Log in"))

  # Submit the login form
  my_page = login_page.form_with(:action => '/login') do |f|
    f.username  = ARGV[0]
    f.password = ARGV[1]
  end.click_button

  albums_page = a.click(my_page.link_with(:text => "My Shots"))
  randoms = albums_page.links_with(href: /good-times.webshots.com\/album/, text: /\t/)
  comments =    albums_page.links_with(href: /good-times.webshots.com\/album.*forum/)
  album_links =  albums_page.links_with(href: /good-times.webshots.com\/album/) - randoms - comments
  begin
    album_links.each do |link|
      a.pluggable_parser['image'] = Mechanize::DirectorySaver.save_to link.text
      a.transact do
        pictures_page = a.click link
        more_pics = true
        while more_pics do
          puts pictures_page.uri
          pictures_page.links_with(:class => "thumb").each do |pic_link|
            a.transact do
              pic_page = a.click pic_link
              full_size = pic_page.link_with(text: "Full size")
              unless File.exists?(link.text + '/' + full_size.href.match(/\w*\.jpg/)[0])
                a.click full_size
              end
            end
          end
          # binding.pry
          next_link = pictures_page.link_with(text: "next")
          if(next_link)
            pictures_page = a.click next_link
          else
            more_pics = false
          end
        end
      end
      # Now we're back at the original page.
    end

  rescue => e
    $stderr.puts "#{e.class}: #{e.message}"
  end
end
