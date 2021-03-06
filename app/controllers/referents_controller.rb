class ReferentsController < ApplicationController
    filter_access_to :all
    # Here's where we defer to different handlers for different types of referent
    @@HandlersByIndex = [ Referent, GenreReferent, RoleReferent, 
            ProcessReferent, IngredientReferent, UnitReferent, 
            SourceReferent, AuthorReferent, OccasionReferent, 
            PantrySectionReferent, StoreSectionReferent, ChannelReferent, ToolReferent ]
    @@HandlerClass = Referent
  # GET /referents
  # GET /referents.json
  def index
    @tabindex = session[:tabindex] || params[:tabindex] || 0
    handlerclass = @@HandlersByIndex[@tabindex]
    # We accept a query for chidren of a parent (or roots, if parentid == 0)
    if params[:key]
        parentid = params[:key].to_i
        # This is a JSON request for node data (re Dynatree)
        if parentid > 0
            @referents = [] # handlerclass.find(parentid).children
        else
            @referents = handlerclass.all # roots
        end
    else
        @referents = handlerclass.scoped
    end
    @referents = @referents.order("id").page(params[:page] || 1).per_page(50)
    # @referents.sort! { |r1, r2| r1.normalized_name <=> r2.normalized_name }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @referents.map { |r| { :title=>r.longname, :isLazy=>true, :key=>r.id, :isFolder=>false }} }
    end
  end

  # GET /referents/1
  # GET /referents/1.json
  def show
      @tabindex = (session[:tabindex] || params[:tabindex] || 0).to_i
      handlerclass = @@HandlersByIndex[@tabindex]
    @referent = handlerclass.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @referent }
    end
  end

  # Get a new referent based on the given tag id
  # GET /referents/new
  # GET /referents/new.json?tagid=1&mode={over,before,after}&parent=referentid
  def new
    @tabindex = (params[:tabindex] || session[:tabindex] || 4).to_i
    handlerclass = @@HandlersByIndex[@tabindex]
    @referent = handlerclass.new
    @referent.express (params[:tagid]) if params[:tagid]
    @typeselections = Tag.type_selections
    @typeselections.shift

    respond_to do |format|
      format.html { render (@tabindex==11 ? "new_channel.html.erb" : "new") }
      format.json { 
        if params[:tagid]
          render json: [ { :title=>@referent.longname, :isLazy=>true, :key=>@referent.id, :isFolder=>false } ]
        else
          render json: { dlog: with_format("html") { render_to_string((@tabindex==11 ? "new_channel.html.erb" : "new"), layout: false) } }
        end
      }
    end
  end

  # GET /referents/1/edit
  def edit
      @referent = Referent.find(params[:id]) # .becomes(Referent)
      # @expressions = @referent.expressions
      @referent_type = @referent.typenum
      @typeselections = Tag.type_selections
      @typeselections.shift
      dialog_boilerplate "edit", "floating" 
  end

  # POST /referents?tagid=1&mode={over,before,after}&target=referentid
  # POST /referents.json?tagid=1&mode={over,before,after}&target=referentid
  def create
    if params[:tabindex] # Obsolete: coming from the old tag-organizing page
        @tabindex = params[:tabindex].to_i || 0
        handlerclass = @@HandlersByIndex[@tabindex]
        tagid = params[:tagid].to_i # Id of expression
        targetid = params[:target] ? params[:target].to_i : 0
    else
        @tabindex = params[:referent][:typenum].to_i || 0
        tagid = params[:referent][:tag_id]
        if @tabindex == 11
            # This is a channel. It needs a referent to key off of.
            if params[:dependent] == 1 
                # We're not creating a free-standing channel, but piggy-backing
                # on an existing referent.
            else
                # This is a channel that only gets events when its tag gets 
                # applied to a recipe. In other words, it's a referent that 
                # sends to itself.
            end
        end
        handlerclass = @@HandlersByIndex[@tabindex]
        params[:referent].delete :typenum
    end
    go = 0
    keyback = 0
    
    # This code will pertain when we get some kind of hierarchy back
    case params[:mode]
    when "before"
        @referent = handlerclass.create tag: tagid
        # @referent.express tagid, form: :canonical # Ensure it has a tag
        # Make a child of this node's parent, if any
        parentid = ((targetid > 0) && handlerclass.find(targetid).parent_id) || 0
        if parentid > 0
            parent = handlerclass.find parentid
            parent.add_child @referent
            parent.save
        end
        keyback = @referent.id
    when "after"
        # Make a child of this node
        @referent = handlerclass.create tag: tagid
        # @referent.express tagid, form: :canonical
        parent = handlerclass.find targetid
        parent.add_child @referent
        parent.save
        keyback = @referent.id
    when "child"
        debugger
    when "over"
        # "over" indicates to add the tag to the referent's expressions
        @referent = handlerclass.find params[:target].to_i
        @referent.express tagid
    end

    if params[:mode] == "over"
        # "over" indicates to add the tag to the referent's expressions
        @referent = handlerclass.find params[:target].to_i
        @referent.express tagid
    elsif params[:mode]
        @referent = handlerclass.create tag: tagid
        keyback = @referent.id
    else
        # The standard New Referent return has no mode
        @referent = handlerclass.new params[:referent]
    end

    respond_to do |format|
      if @referent && @referent.save
        format.html { redirect_to @referent.becomes(Referent), notice: 'Referent was successfully created/aliased.' }
        format.json { 
          if params[:tagid]
            render json: [{ :title=>@referent.longname, :isLazy=>true, :key=>keyback, :isFolder=>false }], status: :created 
          else
            render json: { done: true, notice: "Successfully created "+@referent.longname }, status: :created 
          end
        }
      else
        @typeselections = Tag.type_selections
        @typeselections.shift
        format.html { render action: (@tabindex==11 ? "new_channel.html.erb" : "new") }
        format.json { render json: @referent.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def fix_expression_tokens tokens, tagtype
      return if !tokens
      tokens.keys.each do |key|
          attrlist = tokens[key]
          attrlist[:tag_token].sub! /^\'/, "\'#{tagtype.to_s}::"
      end
  end

  # PUT /referents/1
  # PUT /referents/1.json
  def update
    # @tabindex = session[:tabindex] || params[:tabindex] || 0
    # handlerclass = @@HandlersByIndex[@tabindex]
    @referent = Referent.find(params[:id]) # .becomes(Referent)
    # Any free tags specified as tag tokens will need a type associated with them.
    # This is prepended to the string
    fix_expression_tokens params[:referent][:expressions_attributes], @referent.typenum
    respond_to do |format|
      params[:referent].delete(:typenum)
      if @referent.update_attributes(params[:referent])
        format.html { redirect_to @referent.becomes(Referent), notice: 'Referent was successfully updated.' }
        format.json { render json: [], status: :success }
      else
        @referent.becomes(Referent)
        @referent_type = @referent.typenum
        @typeselections = Tag.type_selections
        @typeselections.shift
        format.html { render action: "edit" }
        format.json { render json: @referent.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /referents/1
  # DELETE /referents/1.json
  def destroy
    @tabindex = session[:tabindex] || params[:tabindex] || 0
    handlerclass = @@HandlersByIndex[@tabindex]
    @referent = handlerclass.find(params[:id])
    @referent.destroy

    respond_to do |format|
      format.html { redirect_to referents_url }
      format.json { head :ok }
    end
  end
  
  # /referents/connect?parent=&child=
  def add_child
      @tabindex = session[:tabindex] || params[:tabindex] || 0
      handlerclass = @@HandlersByIndex[@tabindex]
      parent = handlerclass.find params[:parentid].to_i
      child = handlerclass.find params[:childid].to_i
      parent.add_child child
  end
end
