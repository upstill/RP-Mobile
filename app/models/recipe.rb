require 'open-uri'
require './lib/Domain.rb'
require './lib/RPDOM.rb'
require 'Nokogiri'
require 'htmlentities'

class GettableURLValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if(attribute == :url) 
      begin
        # ou = open(value)
	# ou.close
	true
      rescue
	record.errors[:url] << "\'#{value}\' doesn't seem to be a working URL"
	nil
      end
    end
  end
end

class Recipe < ActiveRecord::Base
  attr_accessible :tag_tokens, :title, :url, :alias, :ratings_attributes, :comment, :current_user, :status, :privacy, :picurl, :tagpane
  # before_validation :crackURL
  after_save :save_ref

  validates :title,:presence=>true 
  validates :url,  :presence=>true, 
		   :gettableURL => true

  has_many :tagrefs
  has_many :tags, :through=>:tagrefs, :autosave=>true
  attr_reader :tag_tokens
  
  @@coder = HTMLEntities.new

  has_many :ratings
  has_many :scales, :through=>:ratings, :autosave=>true, :dependent=>:destroy
  # attr_reader :ratings_attributes
  accepts_nested_attributes_for :ratings, :reject_if => lambda { |a| a[:scale_val].nil? }, :allow_destroy=>true

  validates_uniqueness_of :url

  has_many :rcprefs
  has_many :users, :through=>:rcprefs, :autosave=>true
  attr_reader :comment
  attr_reader :privacy
  attr_reader :status

  # Get the cached rcpref for the recipe and its current user
  def current_ref
      if(@current_user.nil?) # No user => no ref
         @current_ref = nil 
      elsif(@current_ref.nil? || 
      	    @current_ref.user_id != @current_user)
	 @current_ref = self.rcprefs.where("user_id = ?", @current_user)[0]
      end
      @current_ref
  end

  # The comment for a recipe comes from its rcprefs for a 
  # given user_id 
  # Get THIS USER's comment on a recipe
  def comment
    current_ref() ? @current_ref.comment : ""
  end

  # Get another user's comment on a recipe
  def comment_of_user(uid)
    unless (refs = self.rcprefs.where(:user_id=>uid)).empty? 
    	refs.first.comment 
    end
  end

  # Record THIS USER's comment in the reciperefs join table
  def comment=(str)
    @current_ref.comment = str if current_ref()
  end

  # Casual setting of privacy for the recipe: immediate save for 
  # this recipe/user combo.
  # Presented as an integer related to @@privacies
  def privacy=(val)
     @current_ref.privacy = val.to_i if current_ref()
  end

  def privacy
    current_ref() ? @current_ref.privacy : MyConstants::Rcppermission_public
  end

  # Casual setting of status for the recipe: immediate save for 
  # this recipe/user combo.
  # Presented as an integer related to @@statuses
  def status=(val)
     @current_ref.status = val.to_i if current_ref()
  end

  def status
    current_ref() ? @current_ref.status : MyConstants::Rcpstatus_misc
  end

  # An after_save method for a recipe which saves the 
  # recipe/user info cache for the current user
  def save_ref
      if(@current_ref && (@current_ref.user_id == @current_user))
          refs = self.rcprefs.where(:user_id=>@current_user)
         if(ref = refs.first)
            ref.comment = @current_ref.comment
            ref.status = @current_ref.status
            ref.privacy = @current_ref.privacy
	    ref.save
         end
      end
  end

  @@statuses = [[:Rotation, MyConstants::Rcpstatus_rotation], 
  		[:Favorites, MyConstants::Rcpstatus_favorites],
		[:Interesting, MyConstants::Rcpstatus_interesting],
		[:Misc, MyConstants::Rcpstatus_misc]]

  @@privacies = [[:Private, MyConstants::Rcppermission_private], 
  		["Friends Only", MyConstants::Rcppermission_friends],
		[:Circles, MyConstants::Rcppermission_circles],
		[:Public, MyConstants::Rcppermission_public]]

  # return an array of status/value pairs for passing to select()
  def self.status_select
      @@statuses
  end

  # return an array of status/value pairs for passing to select()
  def self.privacy_select
      @@privacies
  end

  # Write the virtual attribute tag_tokens (a list of ids) to
  # update the real attribute tag_ids
  def tag_tokens=(ids)
	# The list may contain new terms
	arr = ids.split(",").map { |e| 
	  if(e=~/^\d*$/) # numbers (sans quotes) represent existing tags
	     e.to_i
	  else
	     e.gsub!('\'','') # Strip out enclosing quotes
	     # We want to ignore capitalization in tag matches
    	     thetags = Tag.where "name like ?", e
    	     if(thetags.length > 0)
	        thetags[0].id # Each token is a string
	     else
		# No such match => it's a new tag
	   	self.tags.create(:name=>e).id
	     end
	  end
	}
	self.tag_ids= arr
  end

  # Make a recipe title nice for display:
  #   -- remove the internal site reference
  #   -- capitalize as necessary
  #   -- remove leading and trailing punctuation and whitespace
  #   -- remove trailing "Recipe"
  def cleanup_title
    ttl = self.title
    url = self.url

    if ttl.nil? || ttl.empty?
    	ttl = "<no title>" 
    else
        ttl = @@coder.decode ttl
        # The mappings remember how each site inserts its name into the recipe
        mappings = {"nytimes.com"=>"The New York Times", 
        	"smittenkitchen.com"=>'smitten kitchen',
        	"chow.com"=>'Chow'}
        subout = mappings[domain_from_url(url)] unless url.nil?
        ttl.sub!(/#{subout}/i, '') unless subout.nil?

        # Capitalize
        nocaps = {"and"=>1, "the"=>1, "in"=>1, "of"=>1, "with"=>1}
        ttl = ttl.split(' ').each {|w| w.capitalize! if(!nocaps[w])}.join(' ')

        # Remove leading punctuation and whitespace
        ttl.sub!(/^[-|,:\s]*/,'')

        # Remove trailing punctuation and whitespace
        ttl.sub!(/[-|,:\s]*$/,'')

        # Remove terminating "Recipe"
        ttl.sub!(/\srecipe\s*$/i,'')
    end

    self.title = ttl
  end

  public

  def current_user
      @current_user
  end

  def current_user=(id)
      @current_user = id
  end

  # Return the number of times a recipe's been marked
  def num_cookmarks
     Rcpref.where(["recipe_id = ?", self.id]).count
  end

  # Is the recipe cookmarked by the given user?
  def marked?(uid)
      self.rcprefs.where("user_id = ?", uid).exists?
  end

  # For a new recipe, go out to the Web and get its title and picture
  # epicurious: for photo, get page from "a#photo_tab", then "div#recipe_full_photo".img
  #     ...title is <title> minus "at Epicurious.com"
  # allrecipes: photo, who knows? Title: <title> - "Recipe - Allrecipes.com"
  def crackURL
     # Find the site for this url
     # Get the site to crack the page for this recipe
     @site = @site || Site.by_link(url)
     findings = @site.crack_page url, :Recipe
     # Pull title, picture and canonical URL from the result
     debugger
     if (self.title = findings.result :Title)
         titledata = self.title.split('\t')
         self.title = titledata.first
         self.url = self.url || titledata.last
     end
     if (self.picurl = findings.result :Image)
         # Make picture path absolute if it's not already
         self.picurl = @site.site+self.picurl unless self.picurl =~ /^\w*:/
     else
         self.picurl = ""
     end
     
     if (betterURI = findings.result :URI)
         self.url = betterURI # Replace w. canonical link if such found
     end
     self.errors.empty?
end

# Return the human-readable name for the recipe's source
def sourcename
    @site = @site || Site.by_link(self.url)
    @site.name
end

# Return the URL for the recipe's source's home page
def sourcehome
    @site = @site || Site.by_link(self.url)
    @site.home
end

   # Make sure this recipe is in the collection of the current user
def ensureUser(uid)
    unless self.users.exists?(uid)
        user = User.find(uid)
        self.users << user
        if self.save
            # Provide defaults for status and privacy
            @current_user = uid
            ref = self.current_ref
            ref.status = MyConstants::Rcpstatus_misc
            ref.privacy = MyConstants::Rcppermission_friends
            ref.save
        end
    end
end

   # This stores the edited tagpane for the recipe--or maybe not. The main
   # purpose is to parse the HTML to extract any tags embedded therein, 
   # particularly those available from the hRecipe format. These become
   # the 'robo-tags' for the recipe.
   def tagpane=(str)
       ou = Nokogiri::HTML str
       newtags = []
       oldtags = self.tag_ids
       ou.css(".name").each { |child|
            str = child.content.to_s
            # Look up the tag and/or create it
            tag = Tag.strmatch(str, self.current_user || User.guest_id, :Food, true)
            newtags << tag.id unless oldtags.include? tag.id
            x=2
       }
       if newtags.length
          self.tag_ids= oldtags + newtags
          self.save
       end
       super
   end


@@DoSpans

   # Parse the given html for tags and other keys,
   # guided by the specified class. Return a modified tree,
   # marked with that class and <possibly> with embedded subclasses.
   # NB: this is the entry point for turning HTML into a tagified 
   # form, at all levels of the tree.
   def self.parse(html, kind)
        # We use Nokogiri to get the DOM tree
        ou = Nokogiri::HTML html
        # Possible symbols taken from Google's microformats spec.
        if kind.to_sym == :hrecipe 
            # Try to parse the whole thing. Right now, we just:
            # 1) look for the 'hrecipe' tag, returning that tree if it exists
            # 2) clean up the tree, i.e., remove all tags 
            # except those which declare one of the parsing entities
            html = RPDOM.DOMstrip (ou.css(".hrecipe").first || ou), 0
            # Declare it preformatted to preserve EOLs
            html = "<pre>#{html}</pre>"
        elsif RPDOM.allowable kind.to_sym
            html = RPDOM.DOMstrip ou, 0
            html = "<span class=\"#{kind.to_s.html_safe}\">#{html}</span>"
       		# when :fn # Recipe title
       		# when :photo
       		# when :ingredients
           		# when :ingredient
	       		# when :amount
                  		# when :quantity
                  		# when :unit
               		# when :conditions
           	  		# when :condition
               		# when :name
       		# else
	       # when :recipeType  e.g., appetizer, entree, dessert
	       # when :published  ISO Date Format: http://www.w3.org/QA/Tips/iso-date
	       # when :summary
	       # when :review  Can include nested review information http://support.google.com/webmasters/bin/answer.py?answer=146645
	       
	       # See http://en.wikipedia.org/wiki/ISO_8601#Durations for ISO Duration Format
	       # when :prepTime
	       # when :cookTime
	       # when :totalTime

	       # when :nutrition
		   # "These elements are not explicitly part of the hRecipe microformat,
		   # but Google will recognize them."
		   # when :servingSize
		   # when :calories
		   # when :fat
		   # when :saturatedFat
		   # when :unsaturatedFat
		   # when :carbohydrates
		   # when :sugar
		   # when :fiber
		   # when :protein
		   # when :cholesterol 
	       # when :instructions
		   # when :instruction
	       # when :yield
	       # when :author # Can include nested Person information
       end
       # Having modified the tree, we spell it out as HTML (assuming it's not 
       # already been so expressed)
       html || ou.to_s
   end
end
