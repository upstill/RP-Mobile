module AuthenticationsHelper
  
  # Offer an authentication option in the form of an icon and a title
  def auth_possible(service, options = {} )
    svc_lower = options[:svc_lower] || service.downcase
    in_iframe = options[:at_top]
    auth_url = "http://#{current_domain}/auth/"+svc_lower
    css_class = "auth_provider"
    css_class += " small" if in_iframe
    css_class += " hide" if @authentications && @authentications.any? { |authentication| authentication.provider.match(/^#{svc_lower}/) }
    content_tag :a, image_tag( (svc_lower+"_64.png"), :alt => service)+service, 
      :class => css_class,
      :size => "64x64", 
      :href => auth_url, 
      :onclick => in_iframe ? "yield_iframe(event)" : "RP.authentication.connect(event)", 
      :"data-hold_msg" => "Hang on while we check with "+service+"...",
      :"data-width" => 600, 
      :"data-height" => 300
    # link_to_submit image_tag( (svc_lower+"_64.png"), :size => "64x64", :alt => service)+service, auth_url, class: css_class
  end

end
