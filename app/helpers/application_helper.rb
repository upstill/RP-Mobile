module ApplicationHelper

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end
  
  # Create a popup selection list for adding a rating to the tags
  def select_to_add_rating(name, f, association, ratings, inex)
    # Derive 'fields', the information needed by the 'add_rating' javascript
    new_object = Rating.new # f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render( "shared/" + association.to_s.singularize + "_fields_" + inex.to_s, :f => builder)
    end
    new_object = {:scale_id=>2}
    fields2 = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render( "shared/" + association.to_s.singularize + "_fields_" + inex.to_s, :f => builder)
    end
    # Collect the options from the available ratings, each having
    # value equal to the scale's id, with a title from the scale's name, so 
    # that the javascript function can use it in the rating label(s)
    opcs = Scale.find(:all).collect { |s| 
      # Only allow selection of scales that are unrated thus far
      ratings.index {|r| r.scale_id == s.id } ? "" : "<option value=\"#{s.id}\" title=\"#{s.minlabel} to #{s.maxlabel} \" >#{s.name}</option>"
    }.join('')
    prompt = opcs.empty? ? "No More Ratings to Add" : "Add a Rating"
    opcs = ("<option value=\"0\" >#{prompt}</option>"+opcs).html_safe
    select_tag('Add Rating', 
	    opcs,
	    :prompt => "Pick a Rating to Add",
	    onchange: h("add_rating(this, '#{association}', '#{escape_javascript(fields)}')"))
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_fields(this, '#{association}', '#{escape_javascript(fields)}')"))
  end

  def title 
    ext = (@Title || (@recipe.title if @recipe))
    "RecipePower"+(ext.blank? ? " Home" : " | #{ext}")
  end

  # def logo
    # logo = image_tag("RPlogo.png", :alt => "Logo Goes Here" )
    # link_to logo, recipes_path
  # end
  
  def logo
    link_to image_tag("RPlogo.png", :alt=>"RecipePower", :id=>"logo_img" ), root_path
  end

  def user_status
    # Ensure a user id
    user = User.current session[:user_id]
    case user.id
    when User.guest_id
       link_to "Sign In", "/login"
    when User.super_id
       link_to "Super logout", "/logout"
    else
       uname = user.username
       ulink = link_to uname, "/users/#{user.id.to_s}/edit"
       ulogout = link_to "Sign Out", "/logout"
       "<strong>#{ulink}</strong><span class=\"welcome_user\">&nbsp|&nbsp;#{ulogout}</span>".html_safe
     end
  end
  
  def bookmarklet
      imgtag = image_tag("Small_Icon.png", :alt=>"Cookmark", :class=>"logo_icon", width: "32px", height: "24px")
      bmtag = %q{<a class="bookmarklet" title="Cookmark" href="javascript:(function(){location.href='http://www.recipepower.com/recipes/new?url='+encodeURIComponent(window.location.href)+'&title='+encodeURIComponent(document.title)+'&notes='+encodeURIComponent(''+(window.getSelection?window.getSelection():document.getSelection?document.getSelection():document.selection.createRange().text))+'&v=6&jump=yes'})()">}
      "#{bmtag}#{imgtag}</a>".html_safe
  end
      
  # Turn the last comma in a comma-separated list into ' and'
  def englishize_list(list)
     set = list.split ', '
     if(set.length > 1)
	ending = " and " + set.pop
	list = set.join(', ') + ending
     end
     list
  end

    # Return the set of navigation links for the header
    def header_navlinks(current)
    	navlinks = []
    	navlinks.push(link_to "Cookmarks", "/rcpqueries", class: (current==:cookmarks) ? "nav_link_strong" : "nav_link") 
    	navlinks.push(link_to "Add a Cookmark", "/recipes/new", class: (current==:addcookmark) ? "nav_link_strong" : "nav_link") 
    	navlinks.join('  |  ').html_safe
    end
    
    def footer_navlinks(current)
    	navlinks = []
    	navlinks << link_to("About", "/about", class: (current==:about) ? "nav_link_strong" : "nav_link") 
    	navlinks << link_to("Contact", "/contact", class: (current==:contact) ? "nav_link_strong" : "nav_link") 
    	navlinks << link_to("Home", "/", class: (current==:home) ? "nav_link_strong" : "nav_link") 
    	navlinks.join('  |  ').html_safe
    end

    def show_errors(errors)
        result = ""
        if errors.any?
          result << "<div id=\"error_explanation\"><h2>\n"
          result << "Sorry, there are "+pluralize(errors.count, "error")+" keeping that from happening:</h2>\n"
          result << "<ul>"
          errors.full_messages.each do |msg|
              result << "<li>#{msg}</li>\n"
          end
          result << "</ul>\n</div>"
        end
        result.html_safe
    end
    
    def debug_dump(params)
        "<div id=\"debug\">#{debug(params)}</div>".html_safe
	end
end
