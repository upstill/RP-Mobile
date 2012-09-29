# Use 'with_format' when a controller needs to render one format for another.
# Canonical use is to render HTML to a string for passing as part of a JSON response.

def with_format(format, &block)
    old_formats = formats
    self.formats = [format]
    result = block.call
    self.formats = old_formats
    result
end

def dialog_boilerplate(action, default_area=nil)
    respond_to do |format|
        format.html {
            @area ||= "page"  
            if @area == "page" # Not partial at all => whole page
                render action
            else
                render action, :layout => false
            end
         }
         format.json { 
           @partial = true
           @area = @area || default_area || "floating"
           hresult = with_format("html") do
             # Blithely assuming that we want a modal-dialog element if we're getting JSON
             render_to_string action, :layout => false
           end
           render json: { code: hresult, area: @area }
         }
    end
end