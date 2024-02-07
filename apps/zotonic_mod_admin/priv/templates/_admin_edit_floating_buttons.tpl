<div class="navbar admin-navbar-fixed-save">
	{% button type="submit" id="save_stay_float" class="btn btn-primary" text=_"Save" title=_"Save this page." disabled=not id.is_editable %}

	{% if id.page_url %}
		{% if id.is_editable %}
			{% button type="submit" id="save_view_float" class="btn btn-outline-secondary" text=_"Save and View" title=_"Save and view the page." %}
		{% else %}
			{% button id="save_view" class="btn btn-primary" text=_"View" title=_"View this page." action={redirect id=id} %}
		{% endif %}
	{% endif %}
</div>
