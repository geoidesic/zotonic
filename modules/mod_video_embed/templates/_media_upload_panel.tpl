{# Panel for defining the embed code #}
{% if not tabs_enabled or "embed"|member:tabs_enabled %}

{% with id.medium as medium %}
{% with medium.mime == "text/html-video-embed" as is_video_embed %}
<div class="tab-pane" id="{{ tab }}-embed">
    <p>{_ Embed a video or other media. Here you can paste embed code from YouTube, Vimeo or other services. _}</p>

    {% wire id=#form type="submit" 
    		postback={add_video_embed predicate=predicate actions=actions id=id subject_id=subject_id callback=callback stay=stay} 
    		delegate="mod_video_embed" %}

    <form id="{{ #form }}" method="POST" action="postback" class="form-horizontal">
	{% if not id %}
    	<div class="control-group">
    	    <label class="control-label" for="{{ #title }}">{_ Media title _}</label>
                <div class="controls">
    	        <input type="text" id="{{ #title }}" name="title" value="{{ title|escape }}" class="span4" />
    	        {% validate id=#title name="title" type={presence} %}
                </div>
    	</div>
	{% endif %}

	<div class="control-group">
	    <label class="control-label" for="{{ #service }}">{_ From site _}</label>
            <div class="controls">
	        <select id="{{ #service }}" name="video_embed_service" class="span4">
		    {% include "_video_embed_service_options.tpl" service=medium.video_embed_service %}
                </select>
            </div>
	</div>
	
	<div class="control-group">
	    <label class="control-label" for="{{ #embed_code }}">{_ Embed code _}</label>
            <div class="controls">
	        <textarea id="{{ #embed_code }}" class="span4" name="video_embed_code" rows="10">{% if is_video_embed %}{{ medium.video_embed_code|escape }}{% endif %}</textarea>
	        {% validate id=#embed_code name="video_embed_code" type={presence} %}
	        <p class="help-block">{_ The embed code will be sanitized. Only whitelisted sites are allowed. _}</p>
            </div>
	</div>

    <div class="control-group">
        <label class="control-label"></label>
        <div class="controls">
            <label class="checkbox">
                <input type="checkbox" id="{{ #published }}" name="is_published" value="1" 
                     {% if subject_id or m.config.mod_admin.rsc_dialog_is_published.value %}checked="checked"{% endif %}
                />
                {_ Published _}
            </label>
            {% if in_sorter|match:"^menu" or subject_id %}
                <label class="checkbox">
                    <input type="checkbox" id="{{ #dependent }}" name="is_dependent" value="1" checked />
                    {% if subject_id %}
                        {_ Delete after disconnecting from _} {{ subject_id.title }}
                    {% else %}
                        {_ Delete after removal from menu _}
                    {% endif %}
                </label>
            {% endif %}
        </div>
    </div>
	
	<div class="modal-footer">
	    {% button class="btn" action={dialog_close} text=_"Cancel" tag="a" %}
	    <button class="btn btn-primary" type="submit">{% if id %}{_ Replace media item _}{% else %}{_ Make media item _}{% endif %}</button>
	</div>

    </form>
</div>

{% if is_video_embed %}
	{% javascript %}
		$('#{{ tab }} a[href="#{{ tab }}-embed"]').tab('show');
	{% endjavascript %}
{% endif %}

{% endwith %}
{% endwith %}

{% endif %}
